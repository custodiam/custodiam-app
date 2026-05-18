import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/splash/presentation/pages/splash_page.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({required bool authenticated})
      : _authenticated = authenticated;

  final bool _authenticated;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => _authenticated;
}

GoRouter _testRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashPage()),
        GoRoute(
          path: '/login',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('LOGIN_PAGE'))),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('HOME_PAGE'))),
        ),
      ],
    );

Future<void> _pumpSplash(
  WidgetTester tester, {
  required bool authenticated,
}) async {
  final router = _testRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWith(
          (ref) => _FakeAuthService(authenticated: authenticated),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SplashPage', () {
    testWidgets('renders shield icon over the primary background', (tester) async {
      // Pumps a single frame so we can observe the splash before routing.
      final router = _testRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith(
              (ref) => _FakeAuthService(authenticated: false),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.shield), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashPage),
          matching: find.byType(Scaffold),
        ),
      );
      final BuildContext context = tester.element(find.byIcon(Icons.shield));
      expect(scaffold.backgroundColor, Theme.of(context).colorScheme.primary);

      await tester.pumpAndSettle();
    });

    testWidgets('navigates to /login when AuthService is unauthenticated',
        (tester) async {
      await _pumpSplash(tester, authenticated: false);

      expect(find.text('LOGIN_PAGE'), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('navigates to /home when AuthService reports a session',
        (tester) async {
      await _pumpSplash(tester, authenticated: true);

      expect(find.text('HOME_PAGE'), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });
  });
}
