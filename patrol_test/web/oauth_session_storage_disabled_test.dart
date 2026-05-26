// Patrol web test for the sessionStorage-disabled scenario (EN-08-34
// DoD scenario 3; EN-08-35 step 4).
//
// What this test asserts:
//
//   - When the user taps "Iniciar sesión" with sessionStorage
//     unavailable (private browsing modes, corporate policies, the
//     synthetic DevTools snippet documented in the EN-08-34 lesson
//     §6.3), the flow MUST:
//       1. Fail the probe inside KeycloakWebAuthService.login() before
//          generating the PKCE pair.
//       2. NOT invoke the URL launcher (no half-open redirect).
//       3. Surface AppFailure.sessionStorageUnavailable to the
//          AuthViewModel, which the LoginPage translates into the
//          AppSnackbar copy below.
//
// Implementation note on platform parity:
//
//   The original EN-08-35 plan suggested injecting
//   `Storage.prototype.setItem = function() { throw … }` via Patrol's
//   "runJsInBrowser". Patrol 4.6's WebAutomator does NOT expose a JS
//   eval primitive — its surface is tap, enterText, cookies, dialogs,
//   permissions, etc. (see patrol-4.6.0/lib/src/platform/web/
//   web_automator.dart). The equivalent observable behaviour is
//   produced more reliably by overriding the SessionStorageGateway in
//   the test scope: the same `Fail(AuthFailure.sessionStorageUnavailable)`
//   path runs end-to-end, the LoginPage hits the same code branch,
//   and the AppSnackbar copy is asserted on the real
//   `ScaffoldMessenger`. The decision is recorded in ADR-024 and the
//   guide 36 v0.2.0 §troubleshooting.
//
// Run requirements:
//
//   - Local widget-test mode (no browser required):
//       flutter test patrol_test/web/oauth_session_storage_disabled_test.dart
//   - Real browser mode (after EN-08-35 step 6 wires CI):
//       patrol test --target patrol_test/web/oauth_session_storage_disabled_test.dart \
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
import 'package:patrol/patrol.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _LauncherSpy {
  int calls = 0;
  Future<bool> call(Uri url, {String? webOnlyWindowName}) async {
    calls++;
    return true;
  }
}

void main() {
  late InMemorySessionStorageGateway sessionStorage;
  late _LauncherSpy launcher;
  late AuthService authService;

  setUp(() {
    // sessionStorage explicitly disabled — simulates either a private
    // browsing tab that blocks Storage APIs or the synthetic
    // `Storage.prototype.setItem = function() { throw … }` snippet
    // used in manual verification.
    sessionStorage = InMemorySessionStorageGateway(available: false);
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

  patrolTest(
    'tapping "Iniciar sesión" with sessionStorage disabled surfaces '
    'the accionable snackbar and does NOT launch Keycloak',
    ($) async {
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const CustodiamApp(),
        ),
      );

      await $.pumpAndSettle();

      await $('Iniciar sesión').tap();
      // Two pumpAndSettle passes: the first drives the AsyncNotifier
      // through Loading -> Error; the second lets `ref.listen` fire and
      // ScaffoldMessenger schedule the SnackBar animation.
      await $.pumpAndSettle();
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.pumpAndSettle();

      // Negative side-effect: the launcher was NOT invoked. No
      // half-open redirect to Keycloak.
      expect(launcher.calls, 0,
          reason: 'When sessionStorage is unavailable the probe must '
              'short-circuit BEFORE launching Keycloak — otherwise the '
              'user would be sent to a login page that can never '
              'complete the round-trip.');

      // Positive side-effect: the AppSnackbar shows the documented
      // copy. Match a substring rather than the full string to keep
      // the test resilient to minor copy edits.
      expect(
        find.textContaining('almacenamiento de sesión deshabilitado'),
        findsOneWidget,
        reason: 'AuthFailureFeedback must render the '
            'SessionStorageUnavailable variant of AppSnackbar so the '
            'user understands why the login button did nothing.',
      );
    },
  );
}
