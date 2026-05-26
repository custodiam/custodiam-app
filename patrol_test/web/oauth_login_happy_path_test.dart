// Patrol web test for the first leg of the OAuth login happy path
// (EN-08-34 DoD scenario 1; EN-08-35 step 4 / verification).
//
// What this test asserts:
//
//   - Tapping "Iniciar sesión" on the real LoginPage triggers
//     KeycloakWebAuthService.login() against the real
//     authServiceProvider (overridden here with a launcher spy and an
//     in-memory SessionStorageGateway so we can observe the side
//     effects without actually leaving the browser tab).
//   - A PKCE code_verifier (>= 43 chars, RFC 7636) is persisted in the
//     session storage BEFORE the redirect, so a future /callback
//     re-instantiation of the service can still complete the token
//     exchange.
//   - The launcher is invoked with `webOnlyWindowName: '_self'` so the
//     redirect replaces the tab (the only mode under which the
//     ADR-023 contract holds; opening in a new window would orphan
//     sessionStorage on the wrong origin).
//   - The launched URL is a valid Keycloak authorization endpoint and
//     carries `code_challenge` + `code_challenge_method=S256`.
//
// What this test deliberately DOES NOT assert (out of Patrol Web's
// reach by design):
//
//   - The cross-origin round-trip through Keycloak. Patrol Web 4.6
//     runs a Flutter widget under Playwright/Chromium and exposes a
//     `WebAutomator` for in-document interactions (tap, enterText,
//     cookies, dialogs) but it does NOT control top-level browser
//     navigation. The `_self` redirect would tear the test harness
//     down. The cross-origin half of the happy path therefore remains
//     manual verification — documented in guide 36 §troubleshooting
//     and in the EN-08-34 lesson §6.3.
//   - The /callback re-entry after Keycloak. The /callback handler is
//     exercised in isolation by oauth_orphan_callback_test.dart for
//     the failure path and by keycloak_web_auth_service_test.dart for
//     the success path with a stubbed grant.
//
// Run requirements:
//
//   - Local widget-test mode (no browser required):
//       flutter test patrol_test/web/oauth_login_happy_path_test.dart
//   - Real browser mode (after EN-08-35 step 6 wires CI):
//       patrol test --target patrol_test/web/oauth_login_happy_path_test.dart \
//                   --device chrome --web-headless=true

import 'package:custodiam/app/app.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/keycloak_web_auth_service.dart';
import 'package:custodiam/infrastructure/auth/session_storage_gateway.dart';
import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _LauncherSpy {
  Uri? lastUrl;
  String? lastWindowName;
  int calls = 0;

  Future<bool> call(Uri url, {String? webOnlyWindowName}) async {
    calls++;
    lastUrl = url;
    lastWindowName = webOnlyWindowName;
    return true;
  }
}

void main() {
  late InMemorySessionStorageGateway sessionStorage;
  late _LauncherSpy launcher;
  late AuthService authService;

  setUp(() {
    sessionStorage = InMemorySessionStorageGateway();
    launcher = _LauncherSpy();

    final secureStorage = _MockSecureStorage();
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    authService = KeycloakWebAuthService(
      tokenStore: TokenStore(storage: secureStorage),
      sessionStorage: sessionStorage,
      launcher: launcher.call,
    );
  });

  patrolWidgetTest(
    'tapping "Iniciar sesión" persists the PKCE verifier and launches '
    'Keycloak with _self',
    ($) async {
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const CustodiamApp(),
        ),
      );

      // Splash -> AppStartupUseCase decides "no session" -> /login.
      await $.pumpAndSettle();

      // The real AppPrimaryButton uses Text('Iniciar sesión') inside.
      // patrol_finders matches descendants too.
      await $('Iniciar sesión').tap();
      await $.pumpAndSettle();

      // Side-effect 1: the PKCE code_verifier was persisted BEFORE the
      // redirect, so a future /callback can rebuild the grant.
      final stored =
          sessionStorage.read(KeycloakWebAuthService.codeVerifierKey);
      expect(stored, isNotNull,
          reason: 'code_verifier must be persisted before launching '
              'Keycloak (ADR-023 capa 1)');
      expect(stored!.length, greaterThanOrEqualTo(43),
          reason: 'RFC 7636 §4.1 mandates 43-128 chars for the '
              'code_verifier');
      expect(stored, isNot(contains('=')),
          reason: 'RFC 7636 §4.1 forbids base64 padding');

      // Side-effect 2: the launcher was invoked once with _self so the
      // redirect REPLACES the tab. Anything else (_blank, popup) would
      // break the sessionStorage contract.
      expect(launcher.calls, 1);
      expect(launcher.lastWindowName, '_self');

      // Side-effect 3: the launched URL is a Keycloak authorize
      // endpoint with PKCE params.
      final url = launcher.lastUrl!.toString();
      expect(url, contains('/protocol/openid-connect/auth'));
      expect(url, contains('code_challenge='));
      expect(url, contains('code_challenge_method=S256'));
    },
  );
}
