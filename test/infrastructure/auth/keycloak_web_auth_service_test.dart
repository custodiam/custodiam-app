// Pure-Dart tests for KeycloakWebAuthService.
//
// Covers the four DoD scenarios of EN-08-34 (guide 25 v0.4.0 §12.A):
//
//   1. login() persists the PKCE code_verifier in sessionStorage and
//      launches Keycloak with webOnlyWindowName: '_self'.
//   2. handleWebCallback() returns Fail(refreshFailed) when
//      sessionStorage has no persisted verifier (orphan landing on
//      /callback — manual refresh, paste, or stale state).
//   3. handleWebCallback() returns Fail(userCancelled) when the
//      callback carries error=access_denied AND wipes the persisted
//      verifier so a retry starts clean.
//   4. login() returns Fail(sessionStorageUnavailable) when
//      sessionStorage is disabled — the launcher is NOT invoked.
//
// The "happy path token exchange" half of scenario 2 (Keycloak returns
// a real code and the grant exchanges it for tokens) lives in the
// manual end-to-end verification, since wiring an oauth2 mock server
// for this single flow would not pay for itself. See guide 25 v0.4.0
// §13 web checklist.

import 'package:custodiam/infrastructure/auth/keycloak_web_auth_service.dart';
import 'package:custodiam/infrastructure/auth/session_storage_gateway.dart';
import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockTokenStore extends Mock implements TokenStore {}

class _MockHttpClient extends Mock implements http.Client {}

class _LauncherSpy {
  Uri? lastUrl;
  String? lastWindowName;
  bool result = true;
  int calls = 0;

  Future<bool> call(Uri url, {String? webOnlyWindowName}) async {
    calls++;
    lastUrl = url;
    lastWindowName = webOnlyWindowName;
    return result;
  }
}

void main() {
  late _MockTokenStore tokenStore;
  late _MockHttpClient httpClient;
  late InMemorySessionStorageGateway sessionStorage;
  late _LauncherSpy launcher;
  late KeycloakWebAuthService service;

  setUp(() {
    tokenStore = _MockTokenStore();
    httpClient = _MockHttpClient();
    sessionStorage = InMemorySessionStorageGateway();
    launcher = _LauncherSpy();
    service = KeycloakWebAuthService(
      tokenStore: tokenStore,
      sessionStorage: sessionStorage,
      httpClient: httpClient,
      launcher: launcher.call,
    );

    when(() => tokenStore.read()).thenAnswer((_) async => null);
    when(() => tokenStore.save(any())).thenAnswer((_) async {});
    when(() => tokenStore.clear()).thenAnswer((_) async {});
  });

  group('login (DoD 1 + 4)', () {
    test('persists a 43+ char code_verifier and launches Keycloak with '
        '_self', () async {
      final result = await service.login();

      expect(result, isA<Success<void>>());
      final stored = sessionStorage.read(KeycloakWebAuthService.codeVerifierKey);
      expect(stored, isNotNull);
      expect(stored!.length, greaterThanOrEqualTo(43));
      // RFC 7636: unreserved characters only (no padding '=').
      expect(stored, isNot(contains('=')));
      expect(launcher.calls, 1);
      expect(launcher.lastWindowName, '_self');
      expect(
        launcher.lastUrl?.toString(),
        contains('/protocol/openid-connect/auth'),
      );
    });

    test('returns sessionStorageUnavailable when probe fails and does '
        'NOT invoke the launcher', () async {
      sessionStorage.available = false;

      final result = await service.login();

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<SessionStorageUnavailable>());
      expect(launcher.calls, 0);
    });

    test('returns browserError and clears the verifier when launcher '
        'reports the URL was rejected', () async {
      launcher.result = false;

      final result = await service.login();

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<BrowserError>());
      expect(
        sessionStorage.read(KeycloakWebAuthService.codeVerifierKey),
        isNull,
      );
    });
  });

  group('handleWebCallback (DoD 2 + 3)', () {
    final callbackUri = Uri.parse(
      'https://app.custodiam.es/callback?code=abc&state=x',
    );

    test('returns refreshFailed when sessionStorage has no verifier '
        '(orphan landing)', () async {
      // Don't seed the verifier — simulate a refresh or paste.
      final result = await service.handleWebCallback(callbackUri);

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<RefreshFailed>());
      verifyNever(() => tokenStore.save(any()));
    });

    test('returns userCancelled and wipes the verifier when callback '
        'carries error=access_denied', () async {
      sessionStorage.write(
        KeycloakWebAuthService.codeVerifierKey,
        'previously-persisted-verifier',
      );
      final cancelledUri = Uri.parse(
        'https://app.custodiam.es/callback?error=access_denied'
        '&error_description=user+aborted',
      );

      final result = await service.handleWebCallback(cancelledUri);

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<UserCancelled>());
      expect(
        sessionStorage.read(KeycloakWebAuthService.codeVerifierKey),
        isNull,
        reason: 'verifier must be cleared so a retry starts clean',
      );
      verifyNever(() => tokenStore.save(any()));
    });
  });

  group('default state', () {
    test('isAuthenticated is false before init', () {
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken is null before init', () {
      expect(service.accessToken, isNull);
    });

    test('consumeExpiredFlag returns false on a fresh service', () {
      expect(service.consumeExpiredFlag(), isFalse);
    });
  });

  group('dispose', () {
    test('can be called safely after construction', () {
      expect(service.dispose, returnsNormally);
    });
  });
}
