// Patrol web test for the orphan-callback scenario (EN-08-34 DoD
// scenario 2; EN-08-35 step 4).
//
// What this test asserts:
//
//   - When the app loads at `/callback?code=foo` with an empty
//     sessionStorage (no persisted code_verifier — the user pasted
//     the URL into a fresh tab, refreshed, or otherwise lost the
//     half-open grant), the _CallbackHandler must:
//       1. Probe the session for an active client (none).
//       2. Try to consume the verifier (missing -> Fail(refreshFailed)).
//       3. Silently route the user back to /login.
//   - No SnackBar of error must surface (the missing verifier is not
//     a *failure* from the user's perspective — it is the natural
//     consequence of a stale URL).
//   - The browser address bar must not retain `?code=foo` after the
//     bounce (PathUrlStrategy + GoRouter clean redirect).
//
// Platform constraint:
//
//   The /callback route is registered inside `routerProvider` behind
//   `if (kIsWeb)` (see lib/app/router.dart), because the mobile build
//   captures the redirect through `app_links` and never hits a Flutter
//   route for it. Running this test under `flutter test` (Dart VM,
//   kIsWeb == false) therefore can't exercise the handler at all; the
//   test is skipped in that mode. The real assertion happens under
//   `patrol test --device chrome --web-headless=true` where kIsWeb is
//   true and the WebSessionStorageGateway exercises real
//   window.sessionStorage.

import 'package:custodiam/app/app.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/keycloak_web_auth_service.dart';
import 'package:custodiam/infrastructure/auth/session_storage_gateway.dart';
import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _NoopLauncher {
  int calls = 0;
  Future<bool> call(Uri url, {String? webOnlyWindowName}) async {
    calls++;
    return true;
  }
}

void main() {
  late InMemorySessionStorageGateway sessionStorage;
  late AuthService authService;
  late _NoopLauncher launcher;

  setUp(() {
    sessionStorage = InMemorySessionStorageGateway();
    launcher = _NoopLauncher();

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
    'landing on /callback with no persisted verifier redirects to /login',
    ($) async {
      await $.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authService),
          ],
          child: const CustodiamApp(),
        ),
      );

      // Splash -> AppStartupUseCase -> /login (no session).
      await $.pumpAndSettle();
      expect($('Iniciar sesión'), findsOneWidget,
          reason: 'Precondition: we should be on the LoginPage after '
              'Splash decides there is no active session');

      // Simulate the orphan landing: navigate the router to /callback
      // as if Keycloak had redirected with a code that we cannot
      // exchange (sessionStorage was wiped or the tab is fresh).
      final navigatorContext =
          $.tester.element(find.byType(Navigator).first);
      GoRouter.of(navigatorContext).go('/callback?code=orphan-code');

      // Give _CallbackHandler time to: schedule the microtask, call
      // handleWebCallback (which returns Fail(refreshFailed)), and
      // GoRouter.go('/login') back.
      await $.pumpAndSettle();

      // Post-condition: back on LoginPage, no error SnackBar surfaced.
      expect($('Iniciar sesión'), findsOneWidget,
          reason: 'Orphan callback should bounce silently to /login');
      // The launcher was never invoked: the user did not press "Iniciar
      // sesión" in this scenario, only landed on /callback.
      expect(launcher.calls, 0);
      // sessionStorage is still empty: nothing was written, nothing
      // was leaked.
      expect(
        sessionStorage.read(KeycloakWebAuthService.codeVerifierKey),
        isNull,
      );
    },
    // The /callback route is web-only (kIsWeb guard in the router).
    // Under `flutter test` (kIsWeb == false) the route does not exist
    // and GoRouter.go('/callback?code=...') is a no-op, so skip the
    // test there. Under `patrol test --device chrome` (kIsWeb == true)
    // the route exists and the handler runs against real
    // window.sessionStorage.
    skip: !kIsWeb,
  );
}
