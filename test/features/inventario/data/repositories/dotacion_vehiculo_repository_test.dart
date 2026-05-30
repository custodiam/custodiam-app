import 'package:custodiam/features/inventario/data/datasources/inventario_api.dart';
import 'package:custodiam/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:custodiam/features/inventario/domain/entities/dotacion_vehiculo.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements InventarioApi {}

Map<String, dynamic> _dotacionRow({String id = 'a-1'}) => {
      'id': id,
      'material_id': 'm-1',
      'material_nombre': 'Casco rojo',
      'cantidad': 2,
      'fecha_asignacion': '2026-05-27T10:00:00',
    };

void main() {
  late _MockApi api;
  late InventarioRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = InventarioRepositoryImpl(api);
  });

  group('listarDotacionVehiculo', () {
    test('maps the dotación list', () async {
      when(() => api.listarDotacionVehiculo('v-1')).thenAnswer(
        (_) async => [_dotacionRow(id: 'a'), _dotacionRow(id: 'b')],
      );

      final result = await repo.listarDotacionVehiculo('v-1');

      switch (result) {
        case Success(:final value):
          expect(value, hasLength(2));
          expect(value.first.materialNombre, 'Casco rojo');
          expect(value.first.id, 'a');
        case Fail(:final failure):
          fail('Expected Success, got $failure');
      }
    });

    test('maps 404 to notFound', () async {
      when(() => api.listarDotacionVehiculo('v-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'vehiculo'));

      final result = await repo.listarDotacionVehiculo('v-1');

      expectFailure<List<DotacionVehiculo>>(result, InventarioNotFound);
    });
  });

  group('asignarDotacionVehiculo', () {
    test('forwards body and parses response', () async {
      when(() => api.asignarDotacionVehiculo('v-1', any()))
          .thenAnswer((_) async => _dotacionRow());

      final result = await repo.asignarDotacionVehiculo(
        'v-1',
        materialId: 'm-1',
        cantidad: 2,
      );

      switch (result) {
        case Success(:final value):
          expect(value.id, 'a-1');
          expect(value.cantidad, 2);
        case Fail(:final failure):
          fail('Expected Success, got $failure');
      }
    });

    test('maps 409 "no operativo" to materialNoOperativo', () async {
      when(() => api.asignarDotacionVehiculo('v-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"El material no está operativo"}',
        ),
      );

      final result =
          await repo.asignarDotacionVehiculo('v-1', materialId: 'm-1');

      expectFailure<DotacionVehiculo>(result, MaterialNoOperativo);
    });
  });

  group('liberarDotacionVehiculo', () {
    test('returns Success on a 204 (void) delete', () async {
      when(() => api.liberarDotacionVehiculo('v-1', 'a-1'))
          .thenAnswer((_) async {});

      final result =
          await repo.liberarDotacionVehiculo('v-1', asignacionId: 'a-1');

      switch (result) {
        case Success():
          break;
        case Fail(:final failure):
          fail('Expected Success, got $failure');
      }
    });

    test('maps 404 to notFound', () async {
      when(() => api.liberarDotacionVehiculo('v-1', 'a-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'asignacion'));

      final result =
          await repo.liberarDotacionVehiculo('v-1', asignacionId: 'a-1');

      expectFailure<void>(result, InventarioNotFound);
    });
  });
}
