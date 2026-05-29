import 'package:custodiam/features/auth/presentation/pages/login_page.dart';
import 'package:custodiam/features/auth/presentation/viewmodels/auth_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginPage', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
    });

    testWidgets(
      'renders shield icon, branding and the primary login button',
      (tester) async {
        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        expect(find.byIcon(Symbols.shield), findsOneWidget);
        expect(find.text('Custodiam'), findsOneWidget);
        expect(find.text('Protección Civil'), findsOneWidget);
        expect(find.text('Iniciar sesión'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the button calls AuthService.login()',
      (tester) async {
        when(() => auth.login())
            .thenAnswer((_) async => const Fail(AuthFailure.userCancelled()));

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        verify(() => auth.login()).called(1);
      },
    );

    testWidgets(
      'shows the typed network-error snackbar when login fails by network',
      (tester) async {
        when(() => auth.login())
            .thenAnswer((_) async => const Fail(AuthFailure.networkError()));

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Error de red durante la autenticación'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows an info snackbar with cancellation copy when user cancels',
      (tester) async {
        when(() => auth.login())
            .thenAnswer((_) async => const Fail(AuthFailure.userCancelled()));

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Has cancelado el inicio de sesión'),
          findsOneWidget,
        );
        // Cancellation is not an error — the info icon distinguishes it
        // from the danger variants visually.
        expect(find.byIcon(Symbols.info), findsOneWidget);
      },
    );

    testWidgets(
      'shows a danger snackbar carrying the status code on server error',
      (tester) async {
        when(() => auth.login()).thenAnswer(
          (_) async => const Fail(AuthFailure.serverError(503)),
        );

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('(503)'), findsOneWidget);
        expect(find.byIcon(Symbols.error), findsOneWidget);
      },
    );

    testWidgets(
      'shows the "sesión expirada" snackbar when AuthService.consumeExpiredFlag '
      'returns true on mount (US-01-03)',
      (tester) async {
        final expiredAuth = _MockAuthService();
        when(() => expiredAuth.consumeExpiredFlag()).thenReturn(true);
        when(() => expiredAuth.authStateListenable)
            .thenReturn(ValueNotifier(false));

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
            authServiceProvider.overrideWithValue(expiredAuth),
          ],
        );

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Tu sesión ha expirado'),
          findsOneWidget,
        );
        // Warning variant uses the warning_amber_outlined icon.
        expect(find.byIcon(Symbols.warning_amber), findsOneWidget);
        verify(() => expiredAuth.consumeExpiredFlag()).called(1);
      },
    );

    testWidgets(
      'does NOT show the expired snackbar when consumeExpiredFlag returns false',
      (tester) async {
        final freshAuth = _MockAuthService();
        when(() => freshAuth.consumeExpiredFlag()).thenReturn(false);
        when(() => freshAuth.authStateListenable)
            .thenReturn(ValueNotifier(false));

        await pumpRiverpod(
          tester,
          const LoginPage(),
          wrapInScaffold: false,
          overrides: [
            authServiceForViewModelProvider.overrideWithValue(auth),
            authServiceProvider.overrideWithValue(freshAuth),
          ],
        );

        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}
