import 'package:custodiam/features/inventario/data/datasources/inventario_api.dart';
import 'package:custodiam/features/inventario/data/repositories/inventario_repository_impl.dart';
import 'package:custodiam/features/inventario/domain/entities/asignacion_material.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/material_create.dart';
import 'package:custodiam/features/inventario/domain/entities/material_item.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_create.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_item.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements InventarioApi {}

Map<String, dynamic> _materialSummary({
  String id = 'm-1',
  String estado = 'operativo',
}) {
  return {
    'id': id,
    'nombre': 'Casco rojo',
    'codigo': 'CAS-001',
    'tipo': 'personal',
    'categoria': 'EPI',
    'estado': estado,
    'cantidad': 1,
    'ubicacion_base': 'Almacén 1',
  };
}

Map<String, dynamic> _materialRow({
  String id = 'm-1',
  String estado = 'operativo',
}) {
  return {
    'id': id,
    'nombre': 'Casco rojo',
    'descripcion': null,
    'codigo': 'CAS-001',
    'numero_serie': null,
    'tipo': 'personal',
    'categoria': 'EPI',
    'cantidad': 1,
    'ubicacion_base': 'Almacén 1',
    'fecha_adquisicion': null,
    'fecha_proxima_revision': null,
    'foto_url': null,
    'estado': estado,
    'observaciones_incidencia': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

Map<String, dynamic> _vehiculoRow({String id = 'v-1'}) {
  return {
    'id': id,
    'codigo_interno': 'VH-01',
    'matricula': '1234ABC',
    'tipo': 'furgoneta',
    'marca_modelo': 'Renault Trafic',
    'fecha_itv': '2027-03-01',
    'foto_url': null,
    'observaciones': null,
    'ubicacion_base': 'Almacén 1',
    'estado': 'operativo',
    'observaciones_incidencia': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

Map<String, dynamic> _asignacionRow() {
  return {
    'id': 'a-1',
    'material_id': 'm-1',
    'voluntario_id': 'v-1',
    'servicio_id': null,
    'tipo': 'personal',
    'cantidad': 1,
    'fecha_asignacion': '2026-05-27T10:00:00',
    'fecha_devolucion': null,
    'observaciones_devolucion': null,
    'activa': true,
  };
}

void main() {
  late _MockApi api;
  late InventarioRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = InventarioRepositoryImpl(api);
  });

  setUpAll(() {
    registerFallbackValue(EstadoInventario.operativo);
    registerFallbackValue(TipoMaterial.personal);
    registerFallbackValue(TipoVehiculo.furgoneta);
    registerFallbackValue(TipoAsignacion.personal);
  });

  group('listMaterial', () {
    test('maps items + X-Total-Count', () async {
      when(() => api.listMaterial(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            categoria: any(named: 'categoria'),
          )).thenAnswer((_) async => ApiResponse(
            body: [_materialSummary(id: 'a'), _materialSummary(id: 'b')],
            headers: const {'x-total-count': '15'},
          ));

      final result = await repo.listMaterial();

      switch (result) {
        case Success(:final value):
          expect(value.items, hasLength(2));
          expect(value.total, 15);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<MaterialesPage>>());
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.listMaterial(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            categoria: any(named: 'categoria'),
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.listMaterial();

      expectFailure<MaterialesPage>(result, SessionExpired);
    });
  });

  group('createMaterial', () {
    test('forwards body and parses response', () async {
      when(() => api.createMaterial(any()))
          .thenAnswer((_) async => _materialRow());

      final result = await repo.createMaterial(const MaterialCreate(
        nombre: 'Casco rojo',
        tipo: TipoMaterial.personal,
        ubicacionBase: 'Almacén 1',
      ));

      switch (result) {
        case Success(:final value):
          expect(value.id, 'm-1');
          expect(value.estado, EstadoInventario.operativo);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<MaterialItem>>());
    });
  });

  group('updateMaterial', () {
    test('forwards body and parses response', () async {
      when(() => api.updateMaterial('m-1', any()))
          .thenAnswer((_) async => _materialRow());

      final result =
          await repo.updateMaterial('m-1', {'nombre': 'Casco azul'});

      switch (result) {
        case Success(:final value):
          expect(value.id, 'm-1');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<MaterialItem>>());
      verify(() => api.updateMaterial('m-1', {'nombre': 'Casco azul'}))
          .called(1);
    });

    test('maps 404 to notFound', () async {
      when(() => api.updateMaterial('m-1', any()))
          .thenThrow(ApiException(statusCode: 404, message: 'gone'));

      final result = await repo.updateMaterial('m-1', const {});

      expectFailure<MaterialItem>(result, InventarioNotFound);
    });

    test('maps 409 to conflicto with backend detail', () async {
      when(() => api.updateMaterial('m-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Código duplicado"}',
        ),
      );

      final result = await repo.updateMaterial('m-1', const {});

      expectFailure<MaterialItem>(result, InventarioConflicto);
      switch (result) {
        case Fail(:final failure):
          expect(failure.message, 'Código duplicado');
        case Success():
          fail('Expected Fail');
      }
    });
  });

  group('deleteMaterial', () {
    test('returns Success on void', () async {
      when(() => api.deleteMaterial('m-1')).thenAnswer((_) async {});

      final result = await repo.deleteMaterial('m-1');

      expect(result, isA<Success<void>>());
      verify(() => api.deleteMaterial('m-1')).called(1);
    });

    test('maps 409 to enUso with backend detail', () async {
      when(() => api.deleteMaterial('m-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Tiene asignaciones activas"}',
        ),
      );

      final result = await repo.deleteMaterial('m-1');

      expectFailure<void>(result, RecursoEnUso);
      switch (result) {
        case Fail(:final failure):
          expect(failure.message, 'Tiene asignaciones activas');
        case Success():
          fail('Expected Fail');
      }
    });

    test('maps 401 to sessionExpired', () async {
      when(() => api.deleteMaterial('m-1'))
          .thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.deleteMaterial('m-1');

      expectFailure<void>(result, SessionExpired);
    });
  });

  group('updateVehiculo + deleteVehiculo', () {
    test('updateVehiculo parses response', () async {
      when(() => api.updateVehiculo('v-1', any()))
          .thenAnswer((_) async => _vehiculoRow());

      final result =
          await repo.updateVehiculo('v-1', {'matricula': '9999ZZZ'});

      switch (result) {
        case Success(:final value):
          expect(value.id, 'v-1');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<VehiculoItem>>());
    });

    test('updateVehiculo maps 409 to conflicto with detail', () async {
      when(() => api.updateVehiculo('v-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Matrícula duplicada"}',
        ),
      );

      final result = await repo.updateVehiculo('v-1', const {});

      expectFailure<VehiculoItem>(result, InventarioConflicto);
      switch (result) {
        case Fail(:final failure):
          expect(failure.message, 'Matrícula duplicada');
        case Success():
          fail('Expected Fail');
      }
    });

    test('deleteVehiculo returns Success on void', () async {
      when(() => api.deleteVehiculo('v-1')).thenAnswer((_) async {});

      final result = await repo.deleteVehiculo('v-1');

      expect(result, isA<Success<void>>());
    });

    test('deleteVehiculo maps 409 to enUso', () async {
      when(() => api.deleteVehiculo('v-1')).thenThrow(
        ApiException(statusCode: 409, message: 'en uso'),
      );

      final result = await repo.deleteVehiculo('v-1');

      expectFailure<void>(result, RecursoEnUso);
    });
  });

  group('reportarIncidenciaMaterial', () {
    test('maps 409 to estadoFinal', () async {
      when(() => api.reportarIncidenciaMaterial('m-1', any()))
          .thenThrow(ApiException(statusCode: 409, message: 'final'));

      final result = await repo.reportarIncidenciaMaterial(
        'm-1',
        nuevoEstado: EstadoInventario.averiado,
        descripcion: 'rota',
      );

      expectFailure<MaterialItem>(result, EstadoFinal);
    });

    test('maps 422 to estadoIncidenciaInvalido', () async {
      when(() => api.reportarIncidenciaMaterial('m-1', any()))
          .thenThrow(ApiException(statusCode: 422, message: 'bad'));

      final result = await repo.reportarIncidenciaMaterial(
        'm-1',
        nuevoEstado: EstadoInventario.operativo,
        descripcion: 'x',
      );

      expectFailure<MaterialItem>(result, EstadoIncidenciaInvalido);
    });
  });

  group('asignarMaterialAVoluntario', () {
    test('returns Success and forwards body', () async {
      when(() => api.asignarMaterialAVoluntario('m-1', any()))
          .thenAnswer((_) async => _asignacionRow());

      final result = await repo.asignarMaterialAVoluntario(
        'm-1',
        voluntarioId: 'v-1',
        tipo: TipoAsignacion.personal,
      );

      switch (result) {
        case Success(:final value):
          expect(value.activa, isTrue);
          expect(value.tipo, TipoAsignacion.personal);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<AsignacionMaterial>>());
    });

    test('maps 409 "no operativo" to materialNoOperativo', () async {
      when(() => api.asignarMaterialAVoluntario('m-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"El material no está operativo"}',
        ),
      );

      final result = await repo.asignarMaterialAVoluntario(
        'm-1',
        voluntarioId: 'v-1',
        tipo: TipoAsignacion.personal,
      );

      expectFailure<AsignacionMaterial>(result, MaterialNoOperativo);
    });

    test('maps 409 "ya asignado" to yaAsignado', () async {
      when(() => api.asignarMaterialAVoluntario('m-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Material ya asignado a otro voluntario"}',
        ),
      );

      final result = await repo.asignarMaterialAVoluntario(
        'm-1',
        voluntarioId: 'v-1',
        tipo: TipoAsignacion.personal,
      );

      expectFailure<AsignacionMaterial>(result, YaAsignado);
    });

    test('maps 409 "cantidad" to cantidadInsuficiente', () async {
      when(() => api.asignarMaterialAVoluntario('m-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"cantidad insuficiente para asignar"}',
        ),
      );

      final result = await repo.asignarMaterialAVoluntario(
        'm-1',
        voluntarioId: 'v-1',
        tipo: TipoAsignacion.prestamo,
      );

      expectFailure<AsignacionMaterial>(result, CantidadInsuficiente);
    });

    test('maps 409 overlap (conflictos payload) to recursoSolapado', () async {
      // El dispatcher compartido _mapAsignacion409 reconoce el 409 de solape
      // temporal (PR6 / Política A), que el backend devuelve como
      // {"mensaje": ..., "conflictos": [...]}. La superficie que lo dispara
      // (asignar un recurso a un servicio) aún no existe en cliente; este
      // test fija el contrato del mapeo para cuando llegue.
      when(() => api.asignarMaterialAVoluntario('m-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":{"mensaje":"El recurso ya está reservado en ese '
              'intervalo","conflictos":[{"servicio_id":"s-1"}]}}',
        ),
      );

      final result = await repo.asignarMaterialAVoluntario(
        'm-1',
        voluntarioId: 'v-1',
        tipo: TipoAsignacion.personal,
      );

      expectFailure<AsignacionMaterial>(result, RecursoSolapado);
    });
  });

  group('devolverMaterial', () {
    test('maps 404 with "asignación" detail to asignacionNoEncontrada',
        () async {
      when(() => api.devolverMaterial('m-1', any())).thenThrow(
        ApiException(
          statusCode: 404,
          message: '{"detail":"No hay asignación activa"}',
        ),
      );

      final result = await repo.devolverMaterial(
        'm-1',
        voluntarioId: 'v-1',
      );

      expectFailure<AsignacionMaterial>(result, AsignacionNoEncontrada);
    });

    test('maps 404 with "material" detail to notFound', () async {
      when(() => api.devolverMaterial('m-1', any())).thenThrow(
        ApiException(
          statusCode: 404,
          message: '{"detail":"Material no encontrado"}',
        ),
      );

      final result = await repo.devolverMaterial(
        'm-1',
        voluntarioId: 'v-1',
      );

      expectFailure<AsignacionMaterial>(result, InventarioNotFound);
    });
  });

  group('listVehiculos + createVehiculo', () {
    test('maps vehículos page', () async {
      when(() => api.listVehiculos(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => const ApiResponse(
            body: [
              {
                'id': 'a',
                'codigo_interno': 'VH-01',
                'matricula': '1111ABC',
                'tipo': 'furgoneta',
                'estado': 'operativo',
                'ubicacion_base': 'Almacén 1',
              },
            ],
            headers: {'x-total-count': '1'},
          ));

      final result = await repo.listVehiculos();

      switch (result) {
        case Success(:final value):
          expect(value.items.first.matricula, '1111ABC');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<VehiculosPage>>());
    });

    test('createVehiculo parses response', () async {
      when(() => api.createVehiculo(any()))
          .thenAnswer((_) async => _vehiculoRow());

      final result = await repo.createVehiculo(const VehiculoCreate(
        codigoInterno: 'VH-01',
        matricula: '1234ABC',
        tipo: TipoVehiculo.furgoneta,
        ubicacionBase: 'Almacén 1',
      ));

      switch (result) {
        case Success(:final value):
          expect(value.matricula, '1234ABC');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<VehiculoItem>>());
    });
  });
}
