import 'package:custodiam/features/servicios/data/datasources/servicios_api.dart';
import 'package:custodiam/features/servicios/data/repositories/servicios_repository_impl.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements ServiciosApi {}

void main() {
  late _MockApi api;
  late ServiciosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = ServiciosRepositoryImpl(api);
  });

  group('getInventario', () {
    test('maps the material and vehiculos of a servicio', () async {
      when(() => api.getInventario('s-1')).thenAnswer(
        (_) async => {
          'material': [
            {
              'id': 'a-1',
              'material_id': 'm-1',
              'material_nombre': 'Conos',
              'cantidad': 4,
              'fecha_asignacion': '2026-05-27T10:00:00',
            },
          ],
          'vehiculos': [
            {
              'id': 'a-2',
              'vehiculo_id': 'v-1',
              'codigo_interno': 'VEH-1',
              'matricula': '1234ABC',
              'fecha_asignacion': '2026-05-27T11:00:00',
            },
          ],
        },
      );

      final result = await repo.getInventario('s-1');

      switch (result) {
        case Success(:final value):
          expect(value.material, hasLength(1));
          expect(value.material.first.materialNombre, 'Conos');
          expect(value.vehiculos, hasLength(1));
          expect(value.vehiculos.first.codigoInterno, 'VEH-1');
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 404 to ServiciosFailure.notFound', () async {
      when(() => api.getInventario('s-1')).thenThrow(
        ApiException(statusCode: 404, message: 'not found'),
      );

      final result = await repo.getInventario('s-1');

      expectFailure<ServicioInventario>(result, ServicioNotFound);
    });
  });

  group('asignarMaterial', () {
    test('returns Success on a clean assignment', () async {
      when(() => api.asignarMaterial('s-1', any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final result =
          await repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 2);

      expect(result, isA<Success<void>>());
    });

    test('maps the 409 overlap (conflictos payload) to recursoSolapado',
        () async {
      when(() => api.asignarMaterial('s-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":{"mensaje":"El recurso ya está reservado en ese '
              'intervalo","conflictos":[{"servicio_id":"x"}]}}',
        ),
      );

      final result = await repo.asignarMaterial('s-1', materialId: 'm-1');

      expectFailure<void>(result, RecursoSolapado);
    });

    test('maps the 409 "no operativo" to materialNoOperativo', () async {
      when(() => api.asignarMaterial('s-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"El material no está operativo"}',
        ),
      );

      final result = await repo.asignarMaterial('s-1', materialId: 'm-1');

      expectFailure<void>(result, MaterialNoOperativo);
    });
  });

  group('asignarVehiculo', () {
    test('returns Success on a clean assignment', () async {
      when(() => api.asignarVehiculo('s-1', any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await repo.asignarVehiculo('s-1', vehiculoId: 'v-1');

      expect(result, isA<Success<void>>());
    });

    test('maps the 409 overlap to recursoSolapado', () async {
      when(() => api.asignarVehiculo('s-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":{"mensaje":"El vehículo ya está ocupado",'
              '"conflictos":[{"servicio_id":"x"}]}}',
        ),
      );

      final result = await repo.asignarVehiculo('s-1', vehiculoId: 'v-1');

      expectFailure<void>(result, RecursoSolapado);
    });
  });
}
