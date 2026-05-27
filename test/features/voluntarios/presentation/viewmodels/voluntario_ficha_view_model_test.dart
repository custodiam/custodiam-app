import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/rol.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_rol_asignacion.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_update_admin.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/roles_repository.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/anonimizar_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/asignar_rol.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/dar_de_baja_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_voluntario_by_id.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_catalogo.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_roles_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/quitar_rol.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/update_voluntario_admin.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntario_ficha_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVolRepo extends Mock implements VoluntariosRepository {}

class _MockRolesRepo extends Mock implements RolesRepository {}

class _FakePatch extends Fake implements VoluntarioUpdateAdmin {}

Voluntario _voluntario({String nombre = 'Ana'}) => Voluntario(
      id: 'vol-1',
      nombre: nombre,
      telefono: '600',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2024, 1, 15),
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

ProviderContainer _container(_MockVolRepo vol, _MockRolesRepo roles) {
  final container = ProviderContainer(
    overrides: [
      getVoluntarioByIdProvider.overrideWithValue(GetVoluntarioById(vol)),
      updateVoluntarioAdminProvider
          .overrideWithValue(UpdateVoluntarioAdmin(vol)),
      listRolesVoluntarioProvider.overrideWithValue(ListRolesVoluntario(vol)),
      asignarRolProvider.overrideWithValue(AsignarRol(vol)),
      quitarRolProvider.overrideWithValue(QuitarRol(vol)),
      listRolesCatalogoProvider.overrideWithValue(ListRolesCatalogo(roles)),
      darDeBajaVoluntarioProvider
          .overrideWithValue(DarDeBajaVoluntario(vol)),
      anonimizarVoluntarioProvider
          .overrideWithValue(AnonimizarVoluntario(vol)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatch());
  });

  late _MockVolRepo vol;
  late _MockRolesRepo roles;

  setUp(() {
    vol = _MockVolRepo();
    roles = _MockRolesRepo();
  });

  void stubHappyBuild() {
    when(() => vol.getById('vol-1'))
        .thenAnswer((_) async => Success(_voluntario()));
    when(() => vol.listRolesAsignados('vol-1'))
        .thenAnswer((_) async => Success([_asignacion()]));
    when(() => roles.listCatalogo()).thenAnswer(
      (_) async => Success([_rol('rol-1', 'voluntario', 1)]),
    );
  }

  test('build loads voluntario, roles asignados and catálogo in parallel',
      () async {
    stubHappyBuild();
    final container = _container(vol, roles);

    final state = await container
        .read(voluntarioFichaViewModelProvider('vol-1').future);

    expect(state.voluntario.nombre, 'Ana');
    expect(state.rolesAsignados, hasLength(1));
    expect(state.catalogoRoles, hasLength(1));
  });

  test('build resolves to AsyncError when getById fails', () async {
    when(() => vol.getById('vol-1')).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.notFound()),
    );
    when(() => vol.listRolesAsignados('vol-1'))
        .thenAnswer((_) async => const Success([]));
    when(() => roles.listCatalogo())
        .thenAnswer((_) async => const Success([]));
    final container = _container(vol, roles);

    try {
      await container.read(voluntarioFichaViewModelProvider('vol-1').future);
    } catch (_) {/* expected — the test asserts on state below */}

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state, isA<AsyncError<VoluntarioFichaState>>());
    expect(state.error, isA<VoluntarioNotFound>());
  });

  test('saveAdmin Success updates voluntario in state', () async {
    stubHappyBuild();
    when(() => vol.updateAdmin('vol-1', any()))
        .thenAnswer((_) async => Success(_voluntario(nombre: 'Ana Updated')));
    final container = _container(vol, roles);
    await container.read(voluntarioFichaViewModelProvider('vol-1').future);

    await container
        .read(voluntarioFichaViewModelProvider('vol-1').notifier)
        .saveAdmin(const VoluntarioUpdateAdmin(nombre: 'Ana Updated'));

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state.value!.voluntario.nombre, 'Ana Updated');
    expect(state.value!.isMutating, isFalse);
  });

  test('saveAdmin Fail resolves to AsyncError carrying the Failure',
      () async {
    stubHappyBuild();
    when(() => vol.updateAdmin('vol-1', any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.dniOrEmailDuplicado()),
    );
    final container = _container(vol, roles);
    await container.read(voluntarioFichaViewModelProvider('vol-1').future);

    await container
        .read(voluntarioFichaViewModelProvider('vol-1').notifier)
        .saveAdmin(const VoluntarioUpdateAdmin(email: 'taken@example.com'));

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state, isA<AsyncError<VoluntarioFichaState>>());
    expect(state.error, isA<DniOrEmailDuplicado>());
  });

  test('asignarRol Success appends the new assignment', () async {
    stubHappyBuild();
    when(() => vol.asignarRol('vol-1', 'rol-2')).thenAnswer(
      (_) async =>
          Success(_asignacion(rolId: 'rol-2', rolNombre: 'jefe_equipo')),
    );
    final container = _container(vol, roles);
    await container.read(voluntarioFichaViewModelProvider('vol-1').future);

    await container
        .read(voluntarioFichaViewModelProvider('vol-1').notifier)
        .asignarRol('rol-2');

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state.value!.rolesAsignados, hasLength(2));
    expect(
      state.value!.rolesAsignados.map((a) => a.rolNombre),
      containsAll(['voluntario', 'jefe_equipo']),
    );
  });

  test('quitarRol Success removes the assignment from state', () async {
    stubHappyBuild();
    when(() => vol.quitarRol('vol-1', 'rol-1')).thenAnswer(
      (_) async => Success(_asignacion()),
    );
    final container = _container(vol, roles);
    await container.read(voluntarioFichaViewModelProvider('vol-1').future);

    await container
        .read(voluntarioFichaViewModelProvider('vol-1').notifier)
        .quitarRol('rol-1');

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state.value!.rolesAsignados, isEmpty);
  });

  test('asignarRol Fail propagates RolYaAsignado as AsyncError', () async {
    stubHappyBuild();
    when(() => vol.asignarRol('vol-1', 'rol-1')).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.rolYaAsignado()),
    );
    final container = _container(vol, roles);
    await container.read(voluntarioFichaViewModelProvider('vol-1').future);

    await container
        .read(voluntarioFichaViewModelProvider('vol-1').notifier)
        .asignarRol('rol-1');

    final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
    expect(state, isA<AsyncError<VoluntarioFichaState>>());
    expect(state.error, isA<RolYaAsignado>());
  });

  group('US-02-08 — darDeBaja', () {
    test('returns true and updates voluntario on Success', () async {
      when(() => vol.getById('vol-1'))
          .thenAnswer((_) async => Success(_voluntario()));
      when(() => vol.listRolesAsignados('vol-1'))
          .thenAnswer((_) async => const Success(<VoluntarioRolAsignacion>[]));
      when(() => roles.listCatalogo())
          .thenAnswer((_) async => Success([_rol('rol-1', 'voluntario', 0)]));
      when(() => vol.darDeBaja('vol-1')).thenAnswer((_) async => Success(
            Voluntario(
              id: 'vol-1',
              nombre: 'Ana',
              telefono: '600',
              municipio: 'Zuera',
              fechaNacimiento: DateTime(1990, 5, 10),
              estado: EstadoVoluntario.baja,
              fechaAlta: DateTime(2024, 1, 15),
            ),
          ));
      final container = _container(vol, roles);
      await container.read(voluntarioFichaViewModelProvider('vol-1').future);

      final ok = await container
          .read(voluntarioFichaViewModelProvider('vol-1').notifier)
          .darDeBaja();

      expect(ok, isTrue);
      verify(() => vol.darDeBaja('vol-1')).called(1);
      final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
      expect(state.value!.voluntario.estado, EstadoVoluntario.baja);
    });

    test('returns false and surfaces AsyncError on Fail', () async {
      when(() => vol.getById('vol-1'))
          .thenAnswer((_) async => Success(_voluntario()));
      when(() => vol.listRolesAsignados('vol-1'))
          .thenAnswer((_) async => const Success(<VoluntarioRolAsignacion>[]));
      when(() => roles.listCatalogo())
          .thenAnswer((_) async => Success([_rol('rol-1', 'voluntario', 0)]));
      when(() => vol.darDeBaja('vol-1')).thenAnswer(
        (_) async => const Fail(VoluntariosFailure.keycloakSyncFailed()),
      );
      final container = _container(vol, roles);
      await container.read(voluntarioFichaViewModelProvider('vol-1').future);

      final ok = await container
          .read(voluntarioFichaViewModelProvider('vol-1').notifier)
          .darDeBaja();

      expect(ok, isFalse);
      final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
      expect(state, isA<AsyncError<VoluntarioFichaState>>());
      expect(state.error, isA<KeycloakSyncFailed>());
    });
  });

  group('US-02-08 — anonimizar', () {
    test('returns true and updates voluntario on Success', () async {
      when(() => vol.getById('vol-1'))
          .thenAnswer((_) async => Success(_voluntario()));
      when(() => vol.listRolesAsignados('vol-1'))
          .thenAnswer((_) async => const Success(<VoluntarioRolAsignacion>[]));
      when(() => roles.listCatalogo())
          .thenAnswer((_) async => Success([_rol('rol-1', 'voluntario', 0)]));
      when(() => vol.anonimizar('vol-1')).thenAnswer(
        (_) async => Success(_voluntario(nombre: 'Anonimizado')),
      );
      final container = _container(vol, roles);
      await container.read(voluntarioFichaViewModelProvider('vol-1').future);

      final ok = await container
          .read(voluntarioFichaViewModelProvider('vol-1').notifier)
          .anonimizar();

      expect(ok, isTrue);
      verify(() => vol.anonimizar('vol-1')).called(1);
      final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
      expect(state.value!.voluntario.nombre, 'Anonimizado');
    });

    test('returns false and surfaces AsyncError on Fail', () async {
      when(() => vol.getById('vol-1'))
          .thenAnswer((_) async => Success(_voluntario()));
      when(() => vol.listRolesAsignados('vol-1'))
          .thenAnswer((_) async => const Success(<VoluntarioRolAsignacion>[]));
      when(() => roles.listCatalogo())
          .thenAnswer((_) async => Success([_rol('rol-1', 'voluntario', 0)]));
      when(() => vol.anonimizar('vol-1')).thenAnswer(
        (_) async => const Fail(VoluntariosFailure.keycloakSyncFailed()),
      );
      final container = _container(vol, roles);
      await container.read(voluntarioFichaViewModelProvider('vol-1').future);

      final ok = await container
          .read(voluntarioFichaViewModelProvider('vol-1').notifier)
          .anonimizar();

      expect(ok, isFalse);
      final state = container.read(voluntarioFichaViewModelProvider('vol-1'));
      expect(state, isA<AsyncError<VoluntarioFichaState>>());
      expect(state.error, isA<KeycloakSyncFailed>());
    });
  });
}
