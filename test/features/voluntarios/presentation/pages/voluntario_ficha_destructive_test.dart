// Widget tests for the destructive section of VoluntarioFichaPage
// (US-02-08). Covers the two RGPD-sensitive branches at the bottom of
// the ficha:
//   - Dar de baja: single AppConfirmDialog, reversible soft delete.
//   - Anonimizar: double AppConfirmDialog, irreversible (Art. 17 RGPD).
//
// The RBAC gate (voluntarios.dar_baja) hides the whole _BajaSection for
// roles that lack it. We mock VoluntariosRepository and override the
// use-case providers the ficha view model reads, including the soft
// delete / anonimizar use cases that the page-level helper in
// voluntario_ficha_page_test does NOT override. The list view model
// refresh() that fires after success calls repo.list(); we stub it so it
// never reaches the network. Navigation to /voluntarios is verified
// through a router with a stub destination, mirroring
// alta_voluntario_page_test.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:custodiam/core/ui/feedback/app_confirm_dialog.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/rol.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_rol_asignacion.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntarios_page.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/roles_repository.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/anonimizar_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/dar_de_baja_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_voluntario_by_id.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_catalogo.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_voluntarios.dart';
import 'package:custodiam/features/voluntarios/presentation/pages/voluntario_ficha_page.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockVolRepo extends Mock implements VoluntariosRepository {}

class _MockRolesRepo extends Mock implements RolesRepository {}

class _MockAuth extends Mock implements AuthService {}

Voluntario _voluntario({
  EstadoVoluntario estado = EstadoVoluntario.activo,
}) =>
    Voluntario(
      id: 'vol-1',
      nombre: 'Ana Pérez',
      telefono: '600000000',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: estado,
      fechaAlta: DateTime(2024, 1, 15),
      email: 'ana@example.com',
    );

VoluntarioRolAsignacion _asignacion() => const VoluntarioRolAsignacion(
      id: 'asig-rol-1',
      voluntarioId: 'vol-1',
      rolId: 'rol-1',
      rolNombre: 'voluntario',
    );

Rol _rol(String id, String nombre, int nivel) =>
    Rol(id: id, nombre: nombre, nivel: nivel);

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser).thenReturn(
    CurrentUser(sub: 's', email: 'e@e', roles: roles),
  );
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

// Loads the ficha happily: the voluntario, its roles and the catalog.
// [estado] lets a test load a voluntario that is already de baja so the
// section renders the info container instead of the button.
void stubHappy(
  VoluntariosRepository vol,
  RolesRepository rolesRepo, {
  EstadoVoluntario estado = EstadoVoluntario.activo,
}) {
  when(() => vol.getById('vol-1'))
      .thenAnswer((_) async => Success(_voluntario(estado: estado)));
  when(() => vol.listRolesAsignados('vol-1'))
      .thenAnswer((_) async => Success([_asignacion()]));
  when(() => rolesRepo.listCatalogo()).thenAnswer(
    (_) async => Success([
      _rol('rol-1', 'voluntario', 1),
      _rol('rol-2', 'jefe_equipo', 3),
    ]),
  );
  // refresh() of the list view model runs after a successful mutation;
  // keep it off the network with an empty page.
  when(() => vol.list(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        estado: any(named: 'estado'),
      )).thenAnswer(
    (_) async => const Success(VoluntariosPage(items: [], total: 0)),
  );
}

Future<void> pumpPage(
  WidgetTester tester,
  VoluntariosRepository vol,
  RolesRepository rolesRepo, {
  List<String> roles = const ['subjefe_agrupacion'],
  Size surfaceSize = const Size(600, 2400),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/voluntarios/vol-1',
    routes: [
      GoRoute(
        path: '/voluntarios',
        builder: (_, _) =>
            const Scaffold(body: Text('voluntarios-list-stub')),
      ),
      GoRoute(
        path: '/voluntarios/:id',
        builder: (_, state) => VoluntarioFichaPage(
          voluntarioId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getVoluntarioByIdProvider.overrideWithValue(GetVoluntarioById(vol)),
        listRolesVoluntarioProvider
            .overrideWithValue(ListRolesVoluntario(vol)),
        listRolesCatalogoProvider
            .overrideWithValue(ListRolesCatalogo(rolesRepo)),
        // The two destructive use cases the base page helper omits.
        darDeBajaVoluntarioProvider
            .overrideWithValue(DarDeBajaVoluntario(vol)),
        anonimizarVoluntarioProvider
            .overrideWithValue(AnonimizarVoluntario(vol)),
        // The list view model refresh() reaches for ListVoluntarios.
        listVoluntariosProvider.overrideWithValue(ListVoluntarios(vol)),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

// Taps the AppDestructiveButton that confirms inside the currently open
// AppConfirmDialog. The section button shares the 'Dar de baja' label,
// so we scope the finder to the AlertDialog subtree to avoid ambiguity.
Future<void> tapDialogConfirm(WidgetTester tester, String label) async {
  final confirm = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(AppDestructiveButton, label),
  );
  expect(confirm, findsOneWidget);
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

Future<void> scrollToDarBaja(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(K.voluntarioFichaDarBajaButton),
    400,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> scrollToAnonimizar(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(K.voluntarioFichaAnonimizarButton),
    400,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  late _MockVolRepo vol;
  late _MockRolesRepo rolesRepo;

  setUp(() {
    vol = _MockVolRepo();
    rolesRepo = _MockRolesRepo();
  });

  group('RBAC gate of the destructive section', () {
    testWidgets(
        'a role without voluntarios.dar_baja (jefe_equipo) does not see '
        'the section', (tester) async {
      stubHappy(vol, rolesRepo);

      // jefe_equipo has ver_ficha (so the ficha loads) but lacks
      // voluntarios.dar_baja, so the gated _BajaSection is hidden.
      await pumpPage(tester, vol, rolesRepo, roles: const ['jefe_equipo']);
      await tester.pumpAndSettle();

      expect(find.byKey(K.voluntarioFichaDarBajaButton), findsNothing);
      expect(find.byKey(K.voluntarioFichaAnonimizarButton), findsNothing);
    });

    testWidgets(
        'a role with voluntarios.dar_baja (subjefe_agrupacion) sees the '
        'section buttons', (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToDarBaja(tester);
      expect(find.byKey(K.voluntarioFichaDarBajaButton), findsOneWidget);
      expect(find.byKey(K.voluntarioFichaAnonimizarButton), findsOneWidget);
    });
  });

  group('Dar de baja', () {
    testWidgets('tapping the button opens the confirmation dialog',
        (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToDarBaja(tester);
      await tester.tap(find.byKey(K.voluntarioFichaDarBajaButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppConfirmDialog), findsOneWidget);
      expect(find.text('Dar de baja a Ana Pérez'), findsOneWidget);
      // The confirm button inside the dialog carries the confirmLabel.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppDestructiveButton, 'Dar de baja'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancelling the dialog does not call the repo nor navigate',
        (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToDarBaja(tester);
      await tester.tap(find.byKey(K.voluntarioFichaDarBajaButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => vol.darDeBaja(any()));
      expect(find.text('voluntarios-list-stub'), findsNothing);
    });

    testWidgets(
        'confirming calls darDeBaja, shows the success snackbar and '
        'navigates to /voluntarios', (tester) async {
      stubHappy(vol, rolesRepo);
      when(() => vol.darDeBaja('vol-1')).thenAnswer(
        (_) async => Success(_voluntario(estado: EstadoVoluntario.baja)),
      );

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToDarBaja(tester);
      await tester.tap(find.byKey(K.voluntarioFichaDarBajaButton));
      await tester.pumpAndSettle();

      await tapDialogConfirm(tester, 'Dar de baja');

      verify(() => vol.darDeBaja('vol-1')).called(1);
      expect(find.textContaining('dado de baja'), findsOneWidget);
      expect(find.text('voluntarios-list-stub'), findsOneWidget);
    });

    testWidgets(
        'a voluntario already de baja shows the info container, not the '
        'button', (tester) async {
      stubHappy(vol, rolesRepo, estado: EstadoVoluntario.baja);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToAnonimizar(tester);
      expect(find.byKey(K.voluntarioFichaDarBajaButton), findsNothing);
      expect(
        find.text('El voluntario ya está dado de baja.'),
        findsOneWidget,
      );
    });
  });

  group('Anonimizar (doble confirmación, irreversible)', () {
    testWidgets(
        'first tap opens the first dialog; confirming opens the final one',
        (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToAnonimizar(tester);
      await tester.tap(find.byKey(K.voluntarioFichaAnonimizarButton));
      await tester.pumpAndSettle();

      // First dialog.
      expect(find.text('Anonimizar a Ana Pérez'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppDestructiveButton, 'Continuar'),
        ),
        findsOneWidget,
      );

      await tapDialogConfirm(tester, 'Continuar');

      // Second (final) dialog.
      expect(find.text('Confirmación final'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(
            AppDestructiveButton,
            'Anonimizar definitivamente',
          ),
        ),
        findsOneWidget,
      );
      verifyNever(() => vol.anonimizar(any()));
    });

    testWidgets('cancelling the first dialog never calls anonimizar',
        (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToAnonimizar(tester);
      await tester.tap(find.byKey(K.voluntarioFichaAnonimizarButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => vol.anonimizar(any()));
      expect(find.text('voluntarios-list-stub'), findsNothing);
    });

    testWidgets('cancelling the second dialog never calls anonimizar',
        (tester) async {
      stubHappy(vol, rolesRepo);

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToAnonimizar(tester);
      await tester.tap(find.byKey(K.voluntarioFichaAnonimizarButton));
      await tester.pumpAndSettle();

      await tapDialogConfirm(tester, 'Continuar');

      // Cancel the final dialog.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => vol.anonimizar(any()));
      expect(find.text('voluntarios-list-stub'), findsNothing);
    });

    testWidgets(
        'passing both confirmations calls anonimizar, shows the success '
        'snackbar and navigates', (tester) async {
      stubHappy(vol, rolesRepo);
      when(() => vol.anonimizar('vol-1')).thenAnswer(
        (_) async => Success(_voluntario(estado: EstadoVoluntario.baja)),
      );

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToAnonimizar(tester);
      await tester.tap(find.byKey(K.voluntarioFichaAnonimizarButton));
      await tester.pumpAndSettle();

      await tapDialogConfirm(tester, 'Continuar');
      await tapDialogConfirm(tester, 'Anonimizar definitivamente');

      verify(() => vol.anonimizar('vol-1')).called(1);
      expect(find.textContaining('anonimizado correctamente'), findsOneWidget);
      expect(find.text('voluntarios-list-stub'), findsOneWidget);
    });
  });

  group('Mutation failure', () {
    testWidgets(
        'a failed darDeBaja surfaces a danger snackbar and does not navigate',
        (tester) async {
      stubHappy(vol, rolesRepo);
      when(() => vol.darDeBaja('vol-1')).thenAnswer(
        (_) async => const Fail(VoluntariosFailure.keycloakSyncFailed()),
      );

      await pumpPage(tester, vol, rolesRepo);
      await tester.pumpAndSettle();

      await scrollToDarBaja(tester);
      await tester.tap(find.byKey(K.voluntarioFichaDarBajaButton));
      await tester.pumpAndSettle();

      await tapDialogConfirm(tester, 'Dar de baja');

      verify(() => vol.darDeBaja('vol-1')).called(1);
      expect(find.byType(SnackBar), findsOneWidget);
      // El mensaje aparece en dos sitios al fallar la mutación: el
      // SnackBar danger (vía ref.listen) y el AppErrorState con que la
      // página repinta el cuerpo cuando el estado pasa a AsyncError. El
      // test verifica concretamente el SnackBar, así que se acota el
      // finder a su subárbol para no contar también el del cuerpo.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching:
              find.textContaining('No se pudo crear la cuenta en Keycloak'),
        ),
        findsOneWidget,
      );
      // Failure means no navigation: the stub destination is never shown.
      expect(find.text('voluntarios-list-stub'), findsNothing);
    });
  });
}
