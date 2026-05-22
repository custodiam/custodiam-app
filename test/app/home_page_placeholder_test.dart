// Covers the logout flow on the HomePagePlaceholder: the destructive
// confirm dialog must run before AuthService.logout() is called, and
// cancelling the dialog must NOT trigger logout. The page is mounted
// inside a minimal GoRouter so the post-logout navigation to '/login'
// resolves the same way it does in production.

import 'package:custodiam/app/router.dart';
import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/auth/presentation/viewmodels/auth_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

GoRouter _testRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomePagePlaceholder(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN_SCREEN')),
        ),
      ],
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  required AuthService auth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceForViewModelProvider.overrideWithValue(auth),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: _testRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomePagePlaceholder logout', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
      when(() => auth.logout()).thenAnswer((_) async => const Success(null));
    });

    testWidgets(
      'tapping the logout icon opens the destructive confirm dialog',
      (tester) async {
        await _pumpHome(tester, auth: auth);

        await tester.tap(find.byTooltip('Cerrar sesión'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(
          find.textContaining('Seguro que quieres cerrar sesión'),
          findsOneWidget,
        );
        // The confirm button is the destructive variant so its colour
        // matches the action's severity.
        expect(find.byType(AppDestructiveButton), findsOneWidget);
        verifyNever(() => auth.logout());
      },
    );

    testWidgets(
      'cancelling the dialog does NOT call AuthService.logout',
      (tester) async {
        await _pumpHome(tester, auth: auth);

        await tester.tap(find.byTooltip('Cerrar sesión'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('LOGIN_SCREEN'), findsNothing);
        verifyNever(() => auth.logout());
      },
    );

    testWidgets(
      'confirming the dialog calls AuthService.logout and routes to /login',
      (tester) async {
        await _pumpHome(tester, auth: auth);

        await tester.tap(find.byTooltip('Cerrar sesión'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(AppDestructiveButton),
          ),
        );
        await tester.pumpAndSettle();

        verify(() => auth.logout()).called(1);
        expect(find.text('LOGIN_SCREEN'), findsOneWidget);
      },
    );

    testWidgets(
      'shows the typed feedback snackbar and stays on /home when logout fails',
      (tester) async {
        when(() => auth.logout()).thenAnswer(
          (_) async => const Fail(AuthFailure.networkError()),
        );

        await _pumpHome(tester, auth: auth);

        await tester.tap(find.byTooltip('Cerrar sesión'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(AppDestructiveButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Error de red durante la autenticación'),
          findsOneWidget,
        );
        // Failure path keeps the user on /home so they can try again.
        expect(find.text('LOGIN_SCREEN'), findsNothing);
      },
    );
  });
}
