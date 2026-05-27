// Coverage for the admin/roles methods added in US-02-02 + EN-02-05
// integration: getById, updateAdmin, listRolesAsignados, asignarRol,
// quitarRol.

import 'package:custodiam/features/voluntarios/data/datasources/voluntarios_api.dart';
import 'package:custodiam/features/voluntarios/data/repositories/voluntarios_repository_impl.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_rol_asignacion.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_update_admin.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements VoluntariosApi {}

Map<String, dynamic> _profileJson() => {
      'id': 'vol-1',
      'nombre': 'Carlos',
      'telefono': '600',
      'municipio': 'Zuera',
      'fecha_nacimiento': '1990-05-10',
      'estado': 'activo',
      'fecha_alta': '2024-01-15',
      'conductor_habilitado': false,
    };

Map<String, dynamic> _asignacionJson({
  String rolId = 'rol-1',
  String rolNombre = 'voluntario',
}) =>
    {
      'id': 'asig-1',
      'voluntario_id': 'vol-1',
      'rol_id': rolId,
      'rol_nombre': rolNombre,
      'fecha_desde': '2025-01-15',
      'fecha_hasta': null,
    };

void main() {
  late _MockApi api;
  late VoluntariosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = VoluntariosRepositoryImpl(api);
  });

  group('getById', () {
    test('returns Success<Voluntario> on 200', () async {
      when(() => api.getById('vol-1'))
          .thenAnswer((_) async => _profileJson());

      final result = await repo.getById('vol-1');

      expect(result, isA<Success<Voluntario>>());
    });

    test('maps 404 to VoluntariosFailure.notFound', () async {
      when(() => api.getById('vol-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'no row'));

      final result = await repo.getById('vol-1');

      expectFailure<Voluntario>(result, VoluntarioNotFound);
    });
  });

  group('updateAdmin', () {
    test('forwards the patch JSON and returns the new profile', () async {
      when(() => api.patchAdmin('vol-1', any()))
          .thenAnswer((_) async => _profileJson());

      await repo.updateAdmin(
        'vol-1',
        const VoluntarioUpdateAdmin(nombre: 'Carlos Nuevo'),
      );

      final captured =
          verify(() => api.patchAdmin('vol-1', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured, {'nombre': 'Carlos Nuevo'});
    });

    test('maps 409 to VoluntariosFailure.dniOrEmailDuplicado', () async {
      when(() => api.patchAdmin('vol-1', any()))
          .thenThrow(ApiException(statusCode: 409, message: 'dupe'));

      final result = await repo.updateAdmin(
        'vol-1',
        const VoluntarioUpdateAdmin(email: 'taken@example.com'),
      );

      expectFailure<Voluntario>(result, DniOrEmailDuplicado);
    });
  });

  group('listRolesAsignados', () {
    test('returns Success with mapped assignments', () async {
      when(() => api.listRolesAsignados('vol-1')).thenAnswer(
        (_) async => ApiResponse(body: [_asignacionJson()], headers: const {}),
      );

      final result = await repo.listRolesAsignados('vol-1');

      expect(result, isA<Success<List<VoluntarioRolAsignacion>>>());
      switch (result) {
        case Success(:final value):
          expect(value, hasLength(1));
          expect(value.single.rolNombre, 'voluntario');
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 404 to VoluntariosFailure.notFound', () async {
      when(() => api.listRolesAsignados('vol-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'no row'));

      final result = await repo.listRolesAsignados('vol-1');

      expectFailure<List<VoluntarioRolAsignacion>>(result, VoluntarioNotFound);
    });
  });

  group('asignarRol', () {
    test('forwards rol_id and returns the new assignment', () async {
      when(() => api.asignarRol('vol-1', 'rol-1'))
          .thenAnswer((_) async => _asignacionJson());

      final result = await repo.asignarRol('vol-1', 'rol-1');

      expect(result, isA<Success<VoluntarioRolAsignacion>>());
    });

    test('maps 409 to VoluntariosFailure.rolYaAsignado', () async {
      when(() => api.asignarRol('vol-1', 'rol-1'))
          .thenThrow(ApiException(statusCode: 409, message: 'already'));

      final result = await repo.asignarRol('vol-1', 'rol-1');

      expectFailure<VoluntarioRolAsignacion>(result, RolYaAsignado);
    });

    test('maps 404 to VoluntariosFailure.rolOAsignacionNoEncontrado',
        () async {
      when(() => api.asignarRol('vol-1', 'rol-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'not found'));

      final result = await repo.asignarRol('vol-1', 'rol-1');

      expectFailure<VoluntarioRolAsignacion>(
          result, RolOAsignacionNoEncontrado);
    });

    test('maps 502 to VoluntariosFailure.keycloakSyncFailed', () async {
      when(() => api.asignarRol('vol-1', 'rol-1'))
          .thenThrow(ApiException(statusCode: 502, message: 'kc down'));

      final result = await repo.asignarRol('vol-1', 'rol-1');

      expectFailure<VoluntarioRolAsignacion>(result, KeycloakSyncFailed);
    });
  });

  group('quitarRol', () {
    test('returns Success on 200 (assignment closed)', () async {
      when(() => api.quitarRol('vol-1', 'rol-1')).thenAnswer(
        (_) async => _asignacionJson()..['fecha_hasta'] = '2026-05-27',
      );

      final result = await repo.quitarRol('vol-1', 'rol-1');

      expect(result, isA<Success<VoluntarioRolAsignacion>>());
    });

    test('maps 404 to VoluntariosFailure.rolOAsignacionNoEncontrado',
        () async {
      when(() => api.quitarRol('vol-1', 'rol-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'no asig'));

      final result = await repo.quitarRol('vol-1', 'rol-1');

      expectFailure<VoluntarioRolAsignacion>(
          result, RolOAsignacionNoEncontrado);
    });

    test('maps 502 to VoluntariosFailure.keycloakSyncFailed', () async {
      when(() => api.quitarRol('vol-1', 'rol-1'))
          .thenThrow(ApiException(statusCode: 502, message: 'kc down'));

      final result = await repo.quitarRol('vol-1', 'rol-1');

      expectFailure<VoluntarioRolAsignacion>(result, KeycloakSyncFailed);
    });
  });
}
