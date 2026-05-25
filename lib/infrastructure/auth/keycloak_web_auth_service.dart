// OIDC AuthService for Flutter Web (PWA), backed by
// oauth2.AuthorizationCodeGrant against Keycloak.
//
// Unlike the mobile flow (which keeps a Completer<Uri> alive while the
// system browser is open), the web flow uses launchUrl(_self) which
// REPLACES the tab with Keycloak's URL. The original instance of this
// class dies; when the user returns to /callback a brand-new instance
// is constructed by the Riverpod provider, with no access to the
// in-memory code_verifier that PKCE requires.
//
// The fix (ADR-023): persist the code_verifier in window.sessionStorage
// before redirecting, then on /callback rebuild the
// AuthorizationCodeGrant passing the persisted verifier so the token
// exchange succeeds. sessionStorage is per-tab and self-clears on close,
// matching the lifespan we need (seconds at most).
//
// Most of the lifecycle (restore, refresh, logout, save, expired flag,
// memoized currentUser, listenable, dispose) mirrors
// KeycloakMobileAuthService one-to-one. The asymmetry is contained to
// init() (no deep-link listener), login() (write verifier + launch), and
// the new handleWebCallback() entry point used by the /callback route.
//
// See guide 25 v0.4.0 §6.B and ADR-023.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/foundation.dart' show Listenable, ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/env_config.dart';
import '../error/failure.dart';
import '../error/result.dart';
import 'auth_service.dart';
import 'current_user.dart';
import 'jwt_claims.dart';
import 'keycloak_config.dart';
import 'session_storage_gateway.dart';
import 'token_store.dart';

/// Signature compatible with the top-level `launchUrl` from
/// `package:url_launcher`. Exposed as a constructor seam so tests can
/// observe what would be launched without depending on the platform
/// channel.
typedef WebUrlLauncher = Future<bool> Function(
  Uri url, {
  String? webOnlyWindowName,
});

class KeycloakWebAuthService implements AuthService {
  /// Key under which the PKCE code_verifier is persisted in
  /// window.sessionStorage between login() and handleWebCallback().
  static const codeVerifierKey = 'custodiam.oauth.code_verifier';

  final TokenStore _tokenStore;
  final SessionStorageGateway _sessionStorage;
  final http.Client _httpClient;
  final WebUrlLauncher _launcher;
  final ValueNotifier<bool> _authNotifier = ValueNotifier(false);
  bool _expiredFlagPending = false;

  oauth2.Client? _client;

  // Memoization: parse the JWT only when the access token changes.
  // Parsing is base64 + JSON of a ~1 KB blob, so it is cheap, but
  // currentUser is read from every ConsumerWidget that gates on
  // permissions — avoiding the repeated parse keeps UI builds snappy.
  String? _memoizedToken;
  CurrentUser? _memoizedUser;

  KeycloakWebAuthService({
    required TokenStore tokenStore,
    SessionStorageGateway? sessionStorage,
    http.Client? httpClient,
    WebUrlLauncher? launcher,
  })  : _tokenStore = tokenStore,
        _sessionStorage = sessionStorage ?? const WebSessionStorageGateway(),
        _httpClient = httpClient ?? http.Client(),
        _launcher = launcher ?? _defaultLauncher;

  static Future<bool> _defaultLauncher(
    Uri url, {
    String? webOnlyWindowName,
  }) =>
      launchUrl(url, webOnlyWindowName: webOnlyWindowName);

  @override
  bool get isAuthenticated =>
      _client != null && !_client!.credentials.isExpired;

  @override
  String? get accessToken => _client?.credentials.accessToken;

  @override
  CurrentUser? get currentUser {
    final token = accessToken;
    if (token == null) {
      _memoizedToken = null;
      _memoizedUser = null;
      return null;
    }
    if (token != _memoizedToken) {
      _memoizedToken = token;
      _memoizedUser = currentUserFromToken(token);
    }
    return _memoizedUser;
  }

  @override
  Listenable get authStateListenable => _authNotifier;

  @override
  bool consumeExpiredFlag() {
    if (!_expiredFlagPending) return false;
    _expiredFlagPending = false;
    return true;
  }

  @override
  Future<void> init() async {
    await _restore();
    // No deep-link listener on web — the OAuth callback lands on
    // /callback (registered by app/router.dart) and is processed by the
    // route's _CallbackHandler, not by a stream subscription here.
  }

  Future<void> _restore() async {
    final json = await _tokenStore.read();
    if (json == null) return;

    try {
      final credentials = oauth2.Credentials.fromJson(json);

      if (credentials.isExpired && credentials.refreshToken == null) {
        _expiredFlagPending = true;
        await _clear();
        return;
      }

      _client = oauth2.Client(
        credentials,
        identifier: EnvConfig.keycloakClientId,
      );
      _publishAuthState();

      if (credentials.isExpired) {
        final refreshed = await _refresh();
        if (refreshed is Fail) {
          _expiredFlagPending = true;
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

  @override
  Future<Result<void>> login() async {
    // Probe sessionStorage before doing anything else so the error
    // surfaces with the right copy instead of a generic browser error.
    if (!_sessionStorage.isAvailable()) {
      return const Fail(AuthFailure.sessionStorageUnavailable());
    }

    // RFC 7636: code_verifier is 43-128 chars from the unreserved set.
    // 32 random bytes encoded in base64url (no padding) yields 43 chars,
    // satisfying the minimum and matching what oauth2 generates
    // internally when no verifier is supplied.
    //
    // We generate it ourselves (instead of relying on the grant's
    // private _codeVerifier field) so it can be persisted to
    // sessionStorage across the _self redirect. The reconstructed
    // grant in handleWebCallback() receives the same verifier through
    // the public `codeVerifier:` constructor parameter, satisfying PKCE.
    final verifier = _generateCodeVerifier();

    try {
      _sessionStorage.write(codeVerifierKey, verifier);
    } catch (e, stack) {
      dev.log(
        'Could not persist code_verifier to sessionStorage: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return const Fail(AuthFailure.sessionStorageUnavailable());
    }

    final grant = oauth2.AuthorizationCodeGrant(
      EnvConfig.keycloakClientId,
      KeycloakConfig.authorizationEndpoint,
      KeycloakConfig.tokenEndpoint,
      codeVerifier: verifier,
    );

    final authUrl = grant.getAuthorizationUrl(
      KeycloakConfig.redirectUri,
      scopes: KeycloakConfig.scopes,
    );

    final opened = await _launcher(authUrl, webOnlyWindowName: '_self');
    if (!opened) {
      // launchUrl rejected the URL or the browser refused — clean up
      // the verifier so a later attempt starts from a known state.
      _clearPersistedVerifier();
      return const Fail(AuthFailure.browserError());
    }

    // The tab is navigating away to Keycloak; any code after this point
    // will not run in the current instance. handleWebCallback() picks up
    // when the user returns.
    return const Success(null);
  }

  /// 32 random bytes → base64url → strip '=' padding. Yields 43 chars,
  /// the RFC 7636 minimum length for the PKCE code_verifier.
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Processes the OAuth callback after Keycloak redirects to /callback.
  /// Invoked from the route handler in app/router.dart; rebuilds the
  /// AuthorizationCodeGrant with the persisted code_verifier so the
  /// token exchange satisfies PKCE.
  Future<Result<void>> handleWebCallback(Uri callbackUri) async {
    final params = callbackUri.queryParameters;

    if (params['error'] == 'access_denied') {
      _clearPersistedVerifier();
      return const Fail(AuthFailure.userCancelled());
    }

    String? verifier;
    try {
      verifier = _sessionStorage.read(codeVerifierKey);
    } catch (e, stack) {
      dev.log(
        'sessionStorage read failed in handleWebCallback: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return const Fail(AuthFailure.sessionStorageUnavailable());
    }

    if (verifier == null) {
      // Landed on /callback without having started login() in this tab:
      // refresh, copy/pasted URL, browser back from a stale state, etc.
      return const Fail(AuthFailure.refreshFailed());
    }

    try {
      final grant = oauth2.AuthorizationCodeGrant(
        EnvConfig.keycloakClientId,
        KeycloakConfig.authorizationEndpoint,
        KeycloakConfig.tokenEndpoint,
        codeVerifier: verifier,
      );
      // The oauth2 package keeps internal state across these two calls;
      // we have to issue the authorization URL request before consuming
      // the response, even if we throw the URL away.
      grant.getAuthorizationUrl(
        KeycloakConfig.redirectUri,
        scopes: KeycloakConfig.scopes,
      );

      _client = await grant.handleAuthorizationResponse(params);
      _clearPersistedVerifier();
      await _save();
      dev.log('Web login completed', name: 'Auth');
      return const Success(null);
    } on oauth2.AuthorizationException catch (e) {
      _clearPersistedVerifier();
      dev.log(
        'Invalid OAuth callback on web: ${e.description}',
        name: 'Auth',
      );
      return const Fail(AuthFailure.invalidCredentials());
    } catch (e, stack) {
      _clearPersistedVerifier();
      dev.log(
        'Unexpected error in handleWebCallback: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return const Fail(AuthFailure.networkError());
    }
  }

  @override
  Future<Result<void>> logout() async {
    _expiredFlagPending = false;

    final refreshToken = _client?.credentials.refreshToken;

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
      dev.log(
        'Network error during backchannel logout: $e',
        name: 'Auth',
        error: e,
        stackTrace: stack,
      );
      await _clear();
      return const Fail(AuthFailure.networkError());
    }

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
      _expiredFlagPending = true;
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
      _expiredFlagPending = true;
      await _clear();
      return const Fail(AuthFailure.refreshFailed());
    }
  }

  Future<void> _save() async {
    if (_client == null) return;
    await _tokenStore.save(_client!.credentials.toJson());
    _publishAuthState();
  }

  Future<void> _clear() async {
    _client = null;
    await _tokenStore.clear();
    _publishAuthState();
  }

  void _clearPersistedVerifier() {
    try {
      _sessionStorage.remove(codeVerifierKey);
    } catch (_) {
      // sessionStorage may have been disabled between probe and cleanup;
      // nothing useful to do here, the value will be discarded on tab
      // close anyway.
    }
  }

  /// Push the current isAuthenticated value into the ValueNotifier so
  /// the GoRouter's refreshListenable (and any other observer) reacts.
  void _publishAuthState() {
    _authNotifier.value = isAuthenticated;
  }

  void dispose() {
    _httpClient.close();
    _authNotifier.dispose();
  }
}
