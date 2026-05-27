import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/splash/presentation/pages/splash_page.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({required bool authenticated})
      : _authenticated = authenticated,
        _authNotifier = ValueNotifier(authenticated);

  final bool _authenticated;
  final ValueNotifier<bool> _authNotifier;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => _authenticated;

  @override
  String? get accessToken => _authenticated ? 'fake-token' : null;

  @override
  CurrentUser? get currentUser => _authenticated
      ? const CurrentUser(sub: 'fake-sub', email: 'fake@custodiam.es')
      : null;

  @override
  Listenable get authStateListenable => _authNotifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async {
    if (!_authenticated) return const Fail(AuthFailure.sessionExpired());
    return const Success('fake-token');
  }
}

GoRouter _testRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashPage()),
        GoRoute(
          path: '/login',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('LOGIN_PAGE'))),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) =>
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
    testWidgets('renders brand logo over the primary background', (tester) async {
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

      // SplashPage muestra el logo de marca (Image.asset) sobre el
      // color brand desde el commit del branding del Sprint 5.
      expect(find.byType(Image), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashPage),
          matching: find.byType(Scaffold),
        ),
      );
      final BuildContext context = tester.element(find.byType(Image));
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
