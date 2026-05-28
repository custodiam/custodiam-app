// Widget tests for CustodiamShell + its BottomAppBar + Drawer.
//
// What we cover here (and why these were missing before — see ADR-028):
//
//   - The drawer's logout flow (destructive confirm dialog before
//     AuthService.logout(); cancel does NOT trigger logout; failure path
//     surfaces the typed feedback snackbar). These four cases used to
//     live in `test/app/home_page_placeholder_test.dart`; the placeholder
//     went away with the StatefulShellRoute migration so the logout
//     surface moved into the shell's drawer.
//
//   - Each bottom-bar branch button calls `navigationShell.goBranch(...)`
//     with the right index. We verify it through the side-effect: after
//     the tap, the active branch's stub page is rendered.
//
//   - The avatar button on the right of the bottom bar navigates to
//     `/mi-perfil` (sub-route inside the Voluntarios branch).
//
//   - Push/back stack works inside a branch: tapping into a detail
//     pushes onto the branch, and Navigator.pop returns to the list.
//
// We use the project's pumpWithRouter helper to mount a minimal router
// that wraps a StatefulShellRoute identical in shape to the production
// one but with stub pages, so the tests do not depend on the real
// pages' providers, just on the shell's own logic.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/app/widgets/custodiam_shell.dart';
import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:custodiam/features/auth/presentation/viewmodels/auth_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_utils/pump_with_router.dart';

class _MockAuthService extends Mock implements AuthService {}

/// Stub page that just renders its label, so a test can assert which
/// page is currently mounted by looking up the label text.
class _StubPage extends StatelessWidget {
  const _StubPage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label, key: ValueKey('stub_$label'))),
    );
  }
}

GoRouter _buildShellTestRouter({String initialLocation = '/home'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const _StubPage('LOGIN'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            CustodiamShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const _StubPage('HOME'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/voluntarios',
                builder: (_, _) => const _StubPage('VOLUNTARIOS'),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => _StubPage(
                      'VOLUNTARIO_${state.pathParameters['id']}',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/mi-perfil',
                builder: (_, _) => const _StubPage('MI_PERFIL'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servicios',
                builder: (_, _) => const _StubPage('SERVICIOS'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventario',
                builder: (_, _) => const _StubPage('INVENTARIO'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const _StubPage('SETTINGS'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Auth fake that grants every role in the RBAC matrix. Tests of the
/// shell focus on navigation and the logout flow, so all
/// AppPermissionGate'd icons should be visible — the simpler way to
/// guarantee that is to hand the user a "superset" role list.
CurrentUser _superuser() => const CurrentUser(
      sub: 'tk-sub',
      email: 'tester@custodiam.local',
      givenName: 'Marcos',
      familyName: 'Val',
      roles: [
        'voluntario',
        'jefe_equipo',
        'jefe_seccion',
        'jefe_unidad',
        'subjefe_agrupacion',
        'jefe_agrupacion',
        'coordinador',
        'secretario',
        'tesorero',
        'admin',
      ],
    );

void _wireSuperuser(_MockAuthService auth) {
  when(() => auth.currentUser).thenReturn(_superuser());
  when(() => auth.isAuthenticated).thenReturn(true);
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  when(() => auth.consumeExpiredFlag()).thenReturn(false);
  when(() => auth.logout()).thenAnswer((_) async => const Success(null));
}

void main() {
  setUpAll(() {
    // Mocktail needs a default value for the AuthFailure enum-like
    // sealed class so `when(() => auth.logout())` can resolve without
    // explicit fallback in every test.
    registerFallbackValue(const Success<void>(null));
  });

  group('CustodiamShell — drawer logout flow', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
      _wireSuperuser(auth);
    });

    Future<void> openDrawerAndTapLogout(WidgetTester tester) async {
      // The drawer button lives in the bottom bar.
      await tester.tap(find.byKey(K.shellDrawerButton));
      await tester.pumpAndSettle();
      // The logout tile sits at the bottom of the drawer, after the
      // destinations list. `ensureVisible` covers small viewports.
      await tester.ensureVisible(find.byKey(K.drawerLogoutTile));
      await tester.tap(find.byKey(K.drawerLogoutTile));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'tapping logout opens the destructive confirm dialog',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await openDrawerAndTapLogout(tester);

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(
          find.textContaining('Seguro que quieres cerrar sesión'),
          findsOneWidget,
        );
        // Destructive variant matches the action severity.
        expect(find.byType(AppDestructiveButton), findsOneWidget);
        verifyNever(() => auth.logout());
      },
    );

    testWidgets(
      'cancelling the dialog does NOT call AuthService.logout',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await openDrawerAndTapLogout(tester);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        verifyNever(() => auth.logout());
      },
    );

    testWidgets(
      'confirming the dialog calls AuthService.logout exactly once',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await openDrawerAndTapLogout(tester);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(AppDestructiveButton),
          ),
        );
        await tester.pumpAndSettle();

        verify(() => auth.logout()).called(1);
      },
    );

    testWidgets(
      'logout failure surfaces the typed feedback snackbar',
      (tester) async {
        when(() => auth.logout()).thenAnswer(
          (_) async => const Fail(AuthFailure.networkError()),
        );

        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await openDrawerAndTapLogout(tester);
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
      },
    );
  });

  group('CustodiamShell — branch navigation', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
      _wireSuperuser(auth);
    });

    testWidgets(
      'starting at /home renders the Home branch and the bottom bar',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(initialLocation: '/home'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        expect(find.byKey(const ValueKey('stub_HOME')), findsOneWidget);
        // Bottom-bar essentials are visible: drawer, home, servicios,
        // inventario and avatar.
        expect(find.byKey(K.shellDrawerButton), findsOneWidget);
        expect(find.byKey(K.shellHomeButton), findsOneWidget);
        expect(find.byKey(K.shellServiciosButton), findsOneWidget);
        expect(find.byKey(K.shellInventarioButton), findsOneWidget);
        expect(find.byKey(K.shellAvatarButton), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the Servicios button switches to the Servicios branch',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(initialLocation: '/home'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.byKey(K.shellServiciosButton));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('stub_SERVICIOS')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the Inventario button switches to the Inventario branch',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(initialLocation: '/home'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.byKey(K.shellInventarioButton));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('stub_INVENTARIO')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the avatar lands on /mi-perfil inside the Voluntarios branch',
      (tester) async {
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(initialLocation: '/home'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        await tester.tap(find.byKey(K.shellAvatarButton));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('stub_MI_PERFIL')), findsOneWidget);
      },
    );

    testWidgets(
      'go(/voluntarios/42) pushes a route onto the Voluntarios branch '
      'and Navigator.pop returns to the list',
      (tester) async {
        // This is the bug that triggered the F1 remediation: with flat
        // routes + context.go(...) there was no back stack to pop. With
        // anchored subroutes inside the branch, this works.
        await pumpWithRouter(
          tester,
          router: _buildShellTestRouter(initialLocation: '/voluntarios'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authServiceForViewModelProvider.overrideWithValue(auth),
          ],
        );

        expect(find.byKey(const ValueKey('stub_VOLUNTARIOS')), findsOneWidget);

        // Push onto the branch.
        final BuildContext ctx = tester.element(find.byType(_StubPage));
        ctx.go('/voluntarios/42');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('stub_VOLUNTARIO_42')),
          findsOneWidget,
        );

        // Pop returns to the list, not exit-the-app. The bug was that
        // before the refactor this pop did nothing because go() had
        // replaced /voluntarios with /voluntarios/42 instead of pushing.
        final newCtx = tester.element(find.byKey(const ValueKey('stub_VOLUNTARIO_42')));
        Navigator.of(newCtx).pop();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('stub_VOLUNTARIOS')), findsOneWidget);
      },
    );
  });
}
