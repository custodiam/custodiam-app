// Covers the routerProvider redirect (US-01-03): when the auth state
// flips to unauthenticated, any protected route bounces to /login.
// SplashPage, LoginPage and /callback are NOT protected — the splash
// drives its own navigation and the login screen has to be reachable
// while the session is empty.

import 'package:custodiam/app/router.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Programmable AuthService. The session can be flipped to expired at
/// runtime so the refreshListenable wired in routerProvider receives a
/// notification.
class _ToggleAuthService implements AuthService {
  _ToggleAuthService({bool authenticated = true})
      : _authenticated = authenticated,
        _notifier = ValueNotifier(authenticated);

  bool _authenticated;
  final ValueNotifier<bool> _notifier;
  bool _expiredFlagPending = false;

  void expire() {
    _authenticated = false;
    _expiredFlagPending = true;
    _notifier.value = false;
  }

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => _authenticated;

  @override
  String? get accessToken => _authenticated ? 'tk' : null;

  @override
  Listenable get authStateListenable => _notifier;

  @override
  bool consumeExpiredFlag() {
    if (!_expiredFlagPending) return false;
    _expiredFlagPending = false;
    return true;
  }

  @override
  Future<Result<void>> login() async {
    _authenticated = true;
    _notifier.value = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> logout() async {
    _authenticated = false;
    _expiredFlagPending = false;
    _notifier.value = false;
    return const Success(null);
  }

  @override
  Future<Result<String>> getValidAccessToken() async {
    if (!_authenticated) return const Fail(AuthFailure.sessionExpired());
    return const Success('tk');
  }
}

Future<void> _pumpAt(
  WidgetTester tester, {
  required _ToggleAuthService auth,
  required String initialLocation,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
      ],
      child: Builder(builder: (_) {
        return Consumer(builder: (_, ref, __) {
          final router = ref.watch(routerProvider);
          // Reset to the initial location each time the test wants to
          // observe a transition. `go` is synchronous-ish: the next
          // pumpAndSettle flushes the router redirect.
          router.go(initialLocation);
          return MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          );
        });
      }),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('routerProvider redirect (US-01-03)', () {
    testWidgets(
      'protected route /home bounces to /login when auth flips to false',
      (tester) async {
        final auth = _ToggleAuthService(authenticated: true);
        await _pumpAt(tester, auth: auth, initialLocation: '/home');

        // Sanity: with the user authenticated, /home is the active
        // location (the HomePagePlaceholder shows its appbar title).
        expect(find.text('Custodiam'), findsWidgets);

        auth.expire();
        await tester.pumpAndSettle();

        // Now the redirect must have kicked in and we are on /login.
        // The LoginPage shows the "Iniciar sesión" button.
        expect(find.text('Iniciar sesión'), findsOneWidget);
      },
    );

    testWidgets(
      '/login stays reachable when unauthenticated (no redirect loop)',
      (tester) async {
        final auth = _ToggleAuthService(authenticated: false);
        await _pumpAt(tester, auth: auth, initialLocation: '/login');

        expect(find.text('Iniciar sesión'), findsOneWidget);
      },
    );

    testWidgets(
      '/ (splash) is not redirected even if unauthenticated',
      (tester) async {
        final auth = _ToggleAuthService(authenticated: false);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(auth),
            ],
            child: Consumer(builder: (_, ref, __) {
              return MaterialApp.router(
                theme: AppTheme.light(),
                routerConfig: ref.watch(routerProvider),
              );
            }),
          ),
        );
        // Pump exactly one frame so we can observe the splash before
        // its own bootstrap navigates away. The redirect must NOT
        // intercept `/` even though isAuthenticated is false.
        await tester.pump();

        expect(find.byIcon(Icons.shield), findsOneWidget);
      },
    );
  });
}
