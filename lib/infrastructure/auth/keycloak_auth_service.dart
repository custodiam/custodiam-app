// OIDC AuthService backed by oauth2.AuthorizationCodeGrant against
// Keycloak. Handles PKCE automatically (no client secret), persists
// credentials via TokenStore and exposes mobile / web flows behind
// the same Result<T>-returning surface. See guide 25 §6.

import 'dart:async';
import 'dart:developer' as dev;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env_config.dart';
import '../error/failure.dart';
import '../error/result.dart';
import 'auth_service.dart';
import 'keycloak_config.dart';
import 'token_store.dart';

class KeycloakAuthService implements AuthService {
  final TokenStore _tokenStore;
  final AppLinks _appLinks;
  final http.Client _httpClient;

  oauth2.Client? _client;
  oauth2.AuthorizationCodeGrant? _pendingGrant;
  StreamSubscription<Uri>? _linkSubscription;
  Completer<Uri>? _callbackCompleter;

  KeycloakAuthService({
    required TokenStore tokenStore,
    AppLinks? appLinks,
    http.Client? httpClient,
  })  : _tokenStore = tokenStore,
        _appLinks = appLinks ?? AppLinks(),
        _httpClient = httpClient ?? http.Client();

  @override
  bool get isAuthenticated =>
      _client != null && !_client!.credentials.isExpired;

  @override
  String? get accessToken => _client?.credentials.accessToken;

  @override
  Future<void> init() async {
    await _restore();
    if (!kIsWeb) {
      _setupDeepLinkListener();
    }
  }

  Future<void> _restore() async {
    final json = await _tokenStore.read();
    if (json == null) return;

    try {
      final credentials = oauth2.Credentials.fromJson(json);

      if (credentials.isExpired && credentials.refreshToken == null) {
        await _clear();
        return;
      }

      _client = oauth2.Client(
        credentials,
        identifier: EnvConfig.keycloakClientId,
      );

      if (credentials.isExpired) {
        final refreshed = await _refresh();
        if (refreshed is Fail) {
          await _clear();
        }
      }
    } catch (e, stack) {
      dev.log(
        'Could not restore credentials: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      await _clear();
    }
  }

  void _setupDeepLinkListener() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'es.custodiam' && uri.host == 'callback') {
        _callbackCompleter?.complete(uri);
      }
    });
  }

  @override
  Future<Result<void>> login() async {
    _pendingGrant = oauth2.AuthorizationCodeGrant(
      EnvConfig.keycloakClientId,
      KeycloakConfig.authorizationEndpoint,
      KeycloakConfig.tokenEndpoint,
    );

    final authUrl = _pendingGrant!.getAuthorizationUrl(
      KeycloakConfig.redirectUri,
      scopes: KeycloakConfig.scopes,
    );

    try {
      if (kIsWeb) {
        final opened =
            await launchUrl(authUrl, webOnlyWindowName: '_self');
        if (!opened) return const Fail(AuthFailure.browserError());
        return const Success(null);
      }

      _callbackCompleter = Completer<Uri>();
      final opened =
          await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      if (!opened) return const Fail(AuthFailure.browserError());

      final callbackUri = await _callbackCompleter!.future;

      if (callbackUri.queryParameters['error'] == 'access_denied') {
        return const Fail(AuthFailure.userCancelled());
      }

      _client = await _pendingGrant!
          .handleAuthorizationResponse(callbackUri.queryParameters);
      _pendingGrant = null;

      await _save();
      dev.log('Login completed', name: 'Auth');
      return const Success(null);
    } on oauth2.AuthorizationException catch (e) {
      dev.log('OIDC authorization error: ${e.description}', name: 'Auth');
      return const Fail(AuthFailure.invalidCredentials());
    } catch (e, stack) {
      dev.log(
        'Unexpected error during login: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return const Fail(AuthFailure.networkError());
    }
  }

  /// Process the OAuth callback on web. Called from the `/callback`
  /// route handler in lib/app/router.dart.
  Future<Result<void>> handleWebCallback(Uri callbackUri) async {
    if (_pendingGrant == null) {
      return const Fail(AuthFailure.refreshFailed());
    }
    try {
      _client = await _pendingGrant!
          .handleAuthorizationResponse(callbackUri.queryParameters);
      _pendingGrant = null;
      await _save();
      return const Success(null);
    } on oauth2.AuthorizationException catch (e) {
      dev.log('Invalid callback: ${e.description}', name: 'Auth');
      return const Fail(AuthFailure.invalidCredentials());
    }
  }

  @override
  Future<Result<void>> logout() async {
    final refreshToken = _client?.credentials.refreshToken;

    // Without a live session there is nothing to invalidate. Clear any
    // stale local state defensively and report success.
    if (_client == null || refreshToken == null) {
      await _clear();
      return const Success(null);
    }

    http.Response response;
    try {
      response = await _httpClient.post(
        KeycloakConfig.endSessionEndpoint,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': EnvConfig.keycloakClientId,
          'refresh_token': refreshToken,
        },
      );
    } catch (e, stack) {
      // The session may or may not be invalidated server-side; from the
      // app's perspective we discard the credentials regardless so the
      // user is not left in a half-authenticated state.
      dev.log(
        'Network error during backchannel logout: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      await _clear();
      return const Fail(AuthFailure.networkError());
    }

    // Keycloak's RP-initiated logout returns 204 No Content on success.
    // Any 2xx means the SSO session was invalidated; we then clear local
    // state. 4xx/5xx means the token or request was rejected — local
    // state still goes, but we surface the error so the UI can show
    // something other than "logged out cleanly".
    await _clear();
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok) {
      dev.log('Logout completed (backchannel)', name: 'Auth');
      return const Success(null);
    }
    dev.log(
      'Backchannel logout returned ${response.statusCode}',
      name: 'Auth',
    );
    return Fail(AuthFailure.serverError(response.statusCode));
  }

  @override
  Future<Result<String>> getValidAccessToken() async {
    if (_client == null) return const Fail(AuthFailure.sessionExpired());

    if (_client!.credentials.isExpired) {
      final refreshed = await _refresh();
      if (refreshed case Fail(:final failure)) {
        return Fail(failure);
      }
    }

    final token = _client?.credentials.accessToken;
    if (token == null) return const Fail(AuthFailure.sessionExpired());
    return Success(token);
  }

  Future<Result<void>> _refresh() async {
    final refreshToken = _client?.credentials.refreshToken;
    if (refreshToken == null) {
      await _clear();
      return const Fail(AuthFailure.sessionExpired());
    }
    try {
      final newCredentials = await _client!.credentials.refresh(
        identifier: EnvConfig.keycloakClientId,
      );
      _client = oauth2.Client(
        newCredentials,
        identifier: EnvConfig.keycloakClientId,
      );
      await _save();
      dev.log('Token refreshed', name: 'Auth');
      return const Success(null);
    } catch (e, stack) {
      dev.log(
        'Token refresh failed: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      await _clear();
      return const Fail(AuthFailure.refreshFailed());
    }
  }

  Future<void> _save() async {
    if (_client == null) return;
    await _tokenStore.save(_client!.credentials.toJson());
  }

  Future<void> _clear() async {
    _client = null;
    await _tokenStore.clear();
  }

  void dispose() {
    _linkSubscription?.cancel();
    _httpClient.close();
  }
}
