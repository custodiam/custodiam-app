// Mock-server-backed tests for KeycloakMobileAuthService — guía 36 §5.
//
// Lives under `patrol_test/auth/` (not `test/`) by convention: this is
// the only test in the project that requires a running external service
// (the mock OIDC server). Pure unit + widget tests stay in `test/`.
// The body uses plain `flutter_test` (no `patrolTest`) because there is
// no UI to drive — it exercises the auth service against a live HTTP
// endpoint, not a browser. EN-08-35 moved it from
// `test/infrastructure/auth/` so the directory split mirrors how it is
// run (manual + integration vs. ubiquitous `flutter test`).
//
// Run requirements:
//   1. docker compose --profile test up -d mock-oidc   (custodiam-infra)
//   2. MOCK_OIDC_URL=http://localhost:8888 \
//      flutter test patrol_test/auth/
//
// Without MOCK_OIDC_URL set, every test in this file is skipped so a
// plain `flutter test patrol_test/auth/` keeps green.
//
// Trick that keeps the production code untouched: `oauth2.Credentials`
// serialises its `tokenEndpoint` inside the JSON blob persisted by
// TokenStore. By seeding the store with a JSON that points to the
// mock server, `_refresh()` hits the mock directly without any
// override surface in KeycloakMobileAuthService or KeycloakConfig.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:custodiam/infrastructure/auth/keycloak_mobile_auth_service.dart';
import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeAppLinks implements AppLinks {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Builds the JSON that `oauth2.Credentials.fromJson` accepts. The
/// `tokenEndpoint` is the seam: pointing it at the mock makes
/// `Credentials.refresh()` POST to the mock, no production override
/// required.
String _credentialsJson({
  required String mockBaseUrl,
  required Duration expiresIn,
  String accessToken = 'mock-access-token',
  String? refreshToken = 'mock-refresh-token',
  List<String> scopes = const ['openid'],
}) {
  final expiration = DateTime.now().add(expiresIn).millisecondsSinceEpoch;
  final body = <String, dynamic>{
    'accessToken': accessToken,
    'tokenEndpoint': '$mockBaseUrl/default/token',
    'scopes': scopes,
    'expiration': expiration,
  };
  if (refreshToken != null) {
    body['refreshToken'] = refreshToken;
  }
  return jsonEncode(body);
}

void main() {
  final mockUrl = Platform.environment['MOCK_OIDC_URL'];
  final skipReason = mockUrl == null
      ? 'requires mock-oauth2-server (see guía 22 §5). '
          'Start with: docker compose --profile test up -d mock-oidc'
      : null;

  group(
    'KeycloakMobileAuthService against mock OIDC server',
    skip: skipReason,
    () {
      late _MockSecureStorage storage;
      late TokenStore tokenStore;
      late KeycloakMobileAuthService service;

      setUp(() {
        storage = _MockSecureStorage();
        tokenStore = TokenStore(storage: storage);
        service = KeycloakMobileAuthService(
          tokenStore: tokenStore,
          appLinks: _FakeAppLinks(),
        );

        // Default storage stubs; individual tests override read().
        when(() => storage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async {});
        when(() => storage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});
      });

      test(
        'init() restores a valid session without touching the mock',
        () async {
          final freshJson = _credentialsJson(
            mockBaseUrl: mockUrl!,
            expiresIn: const Duration(hours: 1),
            accessToken: 'still-fresh',
          );
          when(() => storage.read(key: any(named: 'key')))
              .thenAnswer((_) async => freshJson);

          await service.init();

          expect(service.isAuthenticated, isTrue);
          expect(service.accessToken, 'still-fresh');
        },
      );

      test(
        'init() refreshes transparently against the mock when access '
        'token is expired but refresh token is alive',
        () async {
          final expiredJson = _credentialsJson(
            mockBaseUrl: mockUrl!,
            expiresIn: const Duration(hours: -1),
            accessToken: 'expired-access',
            refreshToken: 'mock-refresh-token',
          );
          when(() => storage.read(key: any(named: 'key')))
              .thenAnswer((_) async => expiredJson);

          await service.init();

          expect(service.isAuthenticated, isTrue,
              reason: 'mock server should issue a new access token via refresh');
          expect(service.accessToken, isNot(equals('expired-access')),
              reason: 'access token must rotate after refresh');
          expect(service.accessToken, isNotNull);
        },
      );

      test(
        'getValidAccessToken triggers a refresh round-trip and returns '
        'a fresh token',
        () async {
          final expiredJson = _credentialsJson(
            mockBaseUrl: mockUrl!,
            expiresIn: const Duration(hours: -2),
            accessToken: 'stale',
            refreshToken: 'mock-refresh-token',
          );
          when(() => storage.read(key: any(named: 'key')))
              .thenAnswer((_) async => expiredJson);

          await service.init();
          final result = await service.getValidAccessToken();

          expect(result, isA<Success<String>>());
          final value = (result as Success<String>).value;
          expect(value, isNot(equals('stale')));
          expect(value, isNotEmpty);
        },
      );

      test(
        'init() clears storage when tokenEndpoint is unreachable on the '
        'mock and there is no other way to refresh',
        () async {
          final brokenJson = _credentialsJson(
            mockBaseUrl: mockUrl!,
            expiresIn: const Duration(hours: -1),
            accessToken: 'expired',
            refreshToken: 'whatever',
            // Override tokenEndpoint to a 404 path on the same mock.
          );
          // Re-serialise pointing at an invalid path on the mock so the
          // refresh POST fails (cleanly, against the running server).
          final parsed = jsonDecode(brokenJson) as Map<String, dynamic>;
          parsed['tokenEndpoint'] = '$mockUrl/this-path-does-not-exist';
          final brokenWithBadEndpoint = jsonEncode(parsed);

          when(() => storage.read(key: any(named: 'key')))
              .thenAnswer((_) async => brokenWithBadEndpoint);

          await service.init();

          expect(service.isAuthenticated, isFalse);
          verify(() => storage.delete(key: any(named: 'key')))
              .called(greaterThanOrEqualTo(1));
        },
      );
    },
  );
}
