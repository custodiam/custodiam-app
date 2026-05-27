import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/rol.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_rol_asignacion.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_update_admin.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/roles_repository.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/asignar_rol.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_voluntario_by_id.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_catalogo.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/quitar_rol.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/update_voluntario_admin.dart';
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

class _FakePatch extends Fake implements VoluntarioUpdateAdmin {}

Voluntario _voluntario() => Voluntario(
      id: 'vol-1',
      nombre: 'Ana Pérez',
      telefono: '600000000',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2024, 1, 15),
      email: 'ana@example.com',
    );

VoluntarioRolAsignacion _asignacion({
  String rolId = 'rol-1',
  String rolNombre = 'voluntario',
}) =>
    VoluntarioRolAsignacion(
      id: 'asig-$rolId',
      voluntarioId: 'vol-1',
      rolId: rolId,
      rolNombre: rolNombre,
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
        updateVoluntarioAdminProvider
            .overrideWithValue(UpdateVoluntarioAdmin(vol)),
        listRolesVoluntarioProvider
            .overrideWithValue(ListRolesVoluntario(vol)),
        asignarRolProvider.overrideWithValue(AsignarRol(vol)),
        quitarRolProvider.overrideWithValue(QuitarRol(vol)),
        listRolesCatalogoProvider
            .overrideWithValue(ListRolesCatalogo(rolesRepo)),
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

void stubHappy(VoluntariosRepository vol, RolesRepository roles) {
  when(() => vol.getById('vol-1'))
      .thenAnswer((_) async => Success(_voluntario()));
  when(() => vol.listRolesAsignados('vol-1'))
      .thenAnswer((_) async => Success([_asignacion()]));
  when(() => roles.listCatalogo()).thenAnswer(
    (_) async => Success([
      _rol('rol-1', 'voluntario', 1),
      _rol('rol-2', 'jefe_equipo', 3),
    ]),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatch());
  });

  late _MockVolRepo vol;
  late _MockRolesRepo rolesRepo;

  setUp(() {
    vol = _MockVolRepo();
    rolesRepo = _MockRolesRepo();
  });

  testWidgets('forbidden screen when the user lacks voluntarios.ver_ficha',
      (tester) async {
    await pumpPage(tester, vol, rolesRepo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => vol.getById(any()));
  });

  testWidgets('prefills the form with the loaded voluntario and shows the '
      'current role chip', (tester) async {
    stubHappy(vol, rolesRepo);

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsWidgets);
    expect(find.text('600000000'), findsWidgets);
    expect(find.text('ana@example.com'), findsWidgets);
    expect(find.byKey(const ValueKey('ficha_rol_chip_rol-1')), findsOneWidget);
  });

  testWidgets('VoluntarioNotFound renders a tailored empty state',
      (tester) async {
    when(() => vol.getById('vol-1'))
        .thenAnswer((_) async => const Fail(VoluntariosFailure.notFound()));
    when(() => vol.listRolesAsignados('vol-1'))
        .thenAnswer((_) async => const Success([]));
    when(() => rolesRepo.listCatalogo())
        .thenAnswer((_) async => const Success([]));

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    expect(find.text('Voluntario no encontrado'), findsOneWidget);
  });

  testWidgets('asignarRol uses the dropdown selection and pushes onto the VM',
      (tester) async {
    stubHappy(vol, rolesRepo);
    when(() => vol.asignarRol('vol-1', 'rol-2')).thenAnswer(
      (_) async => Success(_asignacion(rolId: 'rol-2', rolNombre: 'jefe_equipo')),
    );

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ficha_rol_selector')));
    await tester.pumpAndSettle();
    // The dropdown menu opens with one DropdownMenuItem per disponible.
    await tester.tap(find.text('jefe_equipo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ficha_rol_asignar')));
    await tester.pumpAndSettle();

    verify(() => vol.asignarRol('vol-1', 'rol-2')).called(1);
    expect(find.byKey(const ValueKey('ficha_rol_chip_rol-2')), findsOneWidget);
  });

  testWidgets('quitarRol removes the chip from the state', (tester) async {
    stubHappy(vol, rolesRepo);
    when(() => vol.quitarRol('vol-1', 'rol-1')).thenAnswer(
      (_) async => Success(_asignacion()),
    );

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    // M3 InputChip uses a non-stable delete glyph; invoke onDeleted
    // directly to avoid coupling the test to icon internals.
    final chip = find.byKey(const ValueKey('ficha_rol_chip_rol-1'));
    final inputChip = tester.firstWidget<InputChip>(chip);
    inputChip.onDeleted!.call();
    await tester.pumpAndSettle();

    verify(() => vol.quitarRol('vol-1', 'rol-1')).called(1);
    expect(find.byKey(const ValueKey('ficha_rol_chip_rol-1')), findsNothing);
  });

  testWidgets('shows danger snackbar with RolYaAsignado copy on 409',
      (tester) async {
    stubHappy(vol, rolesRepo);
    when(() => vol.asignarRol('vol-1', 'rol-2')).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.rolYaAsignado()),
    );

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ficha_rol_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('jefe_equipo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ficha_rol_asignar')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('ya está asignado'), findsAtLeastNWidgets(1));
  });

  testWidgets('save without changes shows the "no has cambiado nada" snackbar',
      (tester) async {
    stubHappy(vol, rolesRepo);

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ficha_save')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('ficha_save')));
    await tester.pump();

    expect(find.textContaining('No has cambiado nada'), findsOneWidget);
    verifyNever(() => vol.updateAdmin(any(), any()));
  });

  testWidgets('save with a changed phone calls updateAdmin and surfaces '
      'success snackbar', (tester) async {
    stubHappy(vol, rolesRepo);
    when(() => vol.updateAdmin('vol-1', any()))
        .thenAnswer((_) async => Success(_voluntario()));

    await pumpPage(tester, vol, rolesRepo);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ficha_telefono')),
      '699999999',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ficha_save')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('ficha_save')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => vol.updateAdmin('vol-1', captureAny())).captured.single
            as VoluntarioUpdateAdmin;
    expect(captured.telefono, '699999999');
    expect(find.textContaining('Datos guardados'), findsOneWidget);
  });

  testWidgets('form is read-only when the user has ver_ficha but not editar',
      (tester) async {
    stubHappy(vol, rolesRepo);

    // jefe_equipo has ver_ficha but NOT voluntarios.editar per RBAC matrix.
    await pumpPage(tester, vol, rolesRepo, roles: const ['jefe_equipo']);
    await tester.pumpAndSettle();

    // The dropdown selector for new roles is hidden when canEdit is false.
    expect(find.byKey(const ValueKey('ficha_rol_selector')), findsNothing);
    expect(find.byKey(const ValueKey('ficha_rol_asignar')), findsNothing);
  });
}
