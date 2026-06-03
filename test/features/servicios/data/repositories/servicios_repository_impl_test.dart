import 'package:custodiam/features/servicios/data/datasources/servicios_api.dart';
import 'package:custodiam/features/servicios/data/repositories/servicios_repository_impl.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_create.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/voluntario_inscrito.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements ServiciosApi {}

ApiResponse<List<dynamic>> _envelope(
  List<Map<String, dynamic>> items, {
  required int total,
}) {
  return ApiResponse(
    body: items,
    headers: {'x-total-count': total.toString()},
  );
}

Map<String, dynamic> _summaryRow({
  String id = 'id-1',
  String titulo = 'Preventivo carrera',
  String tipo = 'preventivo',
  String estado = 'publicado',
}) {
  return {
    'id': id,
    'titulo': titulo,
    'tipo': tipo,
    'estado': estado,
    'fecha_inicio': '2026-06-10T08:00:00',
    'fecha_fin': '2026-06-10T14:00:00',
    'ubicacion': 'Zuera',
    'numero_voluntarios': 12,
    'inscritos_count': 0,
  };
}

Map<String, dynamic> _servicioRow({
  String id = 'id-1',
  String tipo = 'preventivo',
  String estado = 'borrador',
}) {
  return {
    'id': id,
    'titulo': 'Preventivo carrera',
    'descripcion': 'Carrera popular',
    'tipo': tipo,
    'estado': estado,
    'fecha_inicio': '2026-06-10T08:00:00',
    'fecha_fin': '2026-06-10T14:00:00',
    'ubicacion': 'Zuera',
    'numero_voluntarios': 12,
    'inscritos_count': 0,
    'notas_material': null,
    'notas_vehiculos': null,
    'observaciones_cierre': null,
    'creado_por_keycloak_id': 'kc-1',
    'fecha_cierre': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

void main() {
  late _MockApi api;
  late ServiciosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = ServiciosRepositoryImpl(api);
  });

  setUpAll(() {
    registerFallbackValue(EstadoServicio.publicado);
    registerFallbackValue(TipoServicio.preventivo);
  });

  group('ServiciosRepositoryImpl.list', () {
    test('maps body items to domain and reads X-Total-Count', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => _envelope(
            [
              _summaryRow(id: 'a', titulo: 'A'),
              _summaryRow(id: 'b', titulo: 'B', tipo: 'emergencia'),
            ],
            total: 42,
          ));

      final result = await repo.list();

      expect(result, isA<Success<ServiciosPage>>());
      switch (result) {
        case Success(:final value):
          expect(value.items, hasLength(2));
          expect(value.items.first.id, 'a');
          expect(value.items.last.tipo, TipoServicio.emergencia);
          expect(value.total, 42);
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps a non-zero inscritos_count from snake_case to camelCase',
        () async {
      // Los fixtures por defecto usan inscritos_count: 0; este caso blinda el
      // mapeo snake→camel con un valor real (3) en summary y detalle.
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => _envelope(
            [
              {..._summaryRow(id: 'a'), 'inscritos_count': 3},
            ],
            total: 1,
          ));
      when(() => api.getById('a')).thenAnswer(
          (_) async => {..._servicioRow(id: 'a'), 'inscritos_count': 3});

      final listResult = await repo.list();
      final detalleResult = await repo.getById('a');

      switch (listResult) {
        case Success(:final value):
          expect(value.items.single.inscritosCount, 3);
        case Fail():
          fail('Expected Success');
      }
      switch (detalleResult) {
        case Success(:final value):
          expect(value.inscritosCount, 3);
        case Fail():
          fail('Expected Success');
      }
    });

    test('forwards filters to the data source', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => _envelope([], total: 0));

      await repo.list(
        skip: 50,
        limit: 25,
        query: 'carrera',
        estado: EstadoServicio.publicado,
        tipo: TipoServicio.preventivo,
      );

      verify(() => api.list(
            skip: 50,
            limit: 25,
            query: 'carrera',
            estado: EstadoServicio.publicado,
            tipo: TipoServicio.preventivo,
          )).called(1);
    });

    test('forwards the date range to the data source', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          )).thenAnswer((_) async => _envelope([], total: 0));

      final desde = DateTime(2026, 6, 1);
      final hasta = DateTime(2026, 6, 30);
      await repo.list(desde: desde, hasta: hasta);

      verify(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: desde,
            hasta: hasta,
          )).called(1);
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.list();

      expectFailure<ServiciosPage>(result, SessionExpired);
    });

    test('maps 404 to ServiciosFailure.notFound', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenThrow(ApiException(statusCode: 404, message: 'nope'));

      final result = await repo.list();

      expectFailure<ServiciosPage>(result, ServicioNotFound);
    });

    test('maps unexpected errors to NetworkFailure.unknown', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenThrow(StateError('boom'));

      final result = await repo.list();

      expectFailure<ServiciosPage>(result, UnknownNetworkError);
    });
  });

  group('ServiciosRepositoryImpl.getById', () {
    test('returns Success with the Servicio on 200', () async {
      when(() => api.getById('id-1'))
          .thenAnswer((_) async => _servicioRow(id: 'id-1', estado: 'activo'));

      final result = await repo.getById('id-1');

      switch (result) {
        case Success(:final value):
          expect(value.id, 'id-1');
          expect(value.estado, EstadoServicio.activo);
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 404 to ServiciosFailure.notFound', () async {
      when(() => api.getById('missing'))
          .thenThrow(ApiException(statusCode: 404, message: 'nope'));

      final result = await repo.getById('missing');

      expectFailure<Servicio>(result, ServicioNotFound);
    });
  });

  group('ServiciosRepositoryImpl.create', () {
    test('forwards body and returns Success on 201', () async {
      when(() => api.create(any()))
          .thenAnswer((_) async => _servicioRow(id: 'new-1'));

      final data = ServicioCreate(
        titulo: 'Preventivo',
        tipo: TipoServicio.preventivo,
        fechaInicio: DateTime.utc(2026, 6, 10, 8),
        ubicacion: 'Zuera',
      );
      final result = await repo.create(data);

      switch (result) {
        case Success(:final value):
          expect(value.id, 'new-1');
        case Fail():
          fail('Expected Success');
      }
      final captured = verify(() => api.create(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured['titulo'], 'Preventivo');
      expect(captured['tipo'], 'preventivo');
      expect(captured['ubicacion'], 'Zuera');
    });
  });

  group('ServiciosRepositoryImpl.update', () {
    test('forwards partial body and parses the response (A5)', () async {
      when(() => api.update('id-1', any()))
          .thenAnswer((_) async => _servicioRow(id: 'id-1'));

      final result =
          await repo.update('id-1', {'titulo': 'Preventivo carrera 2'});

      switch (result) {
        case Success(:final value):
          expect(value.id, 'id-1');
        case Fail():
          fail('Expected Success');
      }
      verify(() => api.update('id-1', {'titulo': 'Preventivo carrera 2'}))
          .called(1);
    });

    test('maps 404 to ServiciosFailure.notFound', () async {
      when(() => api.update('id-1', any()))
          .thenThrow(ApiException(statusCode: 404, message: 'gone'));

      final result = await repo.update('id-1', const {});

      expectFailure<Servicio>(result, ServicioNotFound);
    });

    test('maps 409 to tieneActividad preserving the backend detail', () async {
      when(() => api.update('id-1', any())).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Ciérralo en lugar de borrarlo."}',
        ),
      );

      final result = await repo.update('id-1', const {});

      expectFailure<Servicio>(result, ServicioTieneActividad);
      switch (result) {
        case Fail(:final failure):
          expect(failure.message, 'Ciérralo en lugar de borrarlo.');
        case Success():
          fail('Expected Fail');
      }
    });
  });

  group('ServiciosRepositoryImpl.delete', () {
    test('returns Success on void (A7)', () async {
      when(() => api.delete('id-1')).thenAnswer((_) async {});

      final result = await repo.delete('id-1');

      expect(result, isA<Success<void>>());
      verify(() => api.delete('id-1')).called(1);
    });

    test('maps 404 to ServiciosFailure.notFound', () async {
      when(() => api.delete('id-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'gone'));

      final result = await repo.delete('id-1');

      expectFailure<void>(result, ServicioNotFound);
    });

    test('maps 409 to tieneActividad preserving the backend detail', () async {
      when(() => api.delete('id-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"El servicio tiene inscripciones; '
              'ciérralo en lugar de borrarlo."}',
        ),
      );

      final result = await repo.delete('id-1');

      expectFailure<void>(result, ServicioTieneActividad);
      switch (result) {
        case Fail(:final failure):
          expect(failure.message, contains('ciérralo en lugar de borrarlo'));
        case Success():
          fail('Expected Fail');
      }
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.delete('id-1'))
          .thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.delete('id-1');

      expectFailure<void>(result, SessionExpired);
    });
  });

  group('ServiciosRepositoryImpl.publicar', () {
    test('maps 409 to ServiciosFailure.transicionInvalida with detail',
        () async {
      when(() => api.publicar('id-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message:
              '{"detail":"Transición de estado no permitida: borrador → publicado. Faltan datos."}',
        ),
      );

      final result = await repo.publicar('id-1');

      expectFailure<Servicio>(result, TransicionInvalida);
      switch (result) {
        case Fail(:final failure):
          expect(failure, isA<TransicionInvalida>());
          expect(
            (failure as TransicionInvalida).detalle,
            contains('borrador'),
          );
        case Success():
          fail('Expected Fail');
      }
    });

    test('returns Success when publicar completes', () async {
      when(() => api.publicar('id-1'))
          .thenAnswer((_) async => _servicioRow(estado: 'publicado'));

      final result = await repo.publicar('id-1');

      switch (result) {
        case Success(:final value):
          expect(value.estado, EstadoServicio.publicado);
        case Fail():
          fail('Expected Success');
      }
    });
  });

  group('ServiciosRepositoryImpl.convocar', () {
    test('forwards empty list when voluntarioIds is null', () async {
      when(() => api.convocar('id-1',
              voluntarioIds: any(named: 'voluntarioIds')))
          .thenAnswer((_) async => _servicioRow(estado: 'activo'));

      await repo.convocar('id-1');

      verify(() => api.convocar('id-1', voluntarioIds: null)).called(1);
    });

    test('maps 409 to transicionInvalida', () async {
      when(() => api.convocar('id-1',
              voluntarioIds: any(named: 'voluntarioIds')))
          .thenThrow(ApiException(
        statusCode: 409,
        message: '{"detail":"Transición de estado no permitida"}',
      ));

      final result = await repo.convocar('id-1');

      expectFailure<Servicio>(result, TransicionInvalida);
    });
  });

  group('ServiciosRepositoryImpl.cerrar', () {
    test('forwards observaciones and returns Success', () async {
      when(() => api.cerrar('id-1', observaciones: 'todo OK'))
          .thenAnswer((_) async => _servicioRow(estado: 'cerrado'));

      final result = await repo.cerrar('id-1', observaciones: 'todo OK');

      switch (result) {
        case Success(:final value):
          expect(value.estado, EstadoServicio.cerrado);
        case Fail():
          fail('Expected Success');
      }
      verify(() => api.cerrar('id-1', observaciones: 'todo OK')).called(1);
    });
  });

  group('ServiciosRepositoryImpl.inscribirse', () {
    test('returns Success on 201', () async {
      when(() => api.inscribirse('id-1'))
          .thenAnswer((_) async => _servicioRow(estado: 'publicado'));

      final result = await repo.inscribirse('id-1');

      switch (result) {
        case Success():
          // ok
          break;
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 409 "ya inscrito" to yaInscrito', () async {
      when(() => api.inscribirse('id-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"Ya estás inscrito en este servicio"}',
        ),
      );

      final result = await repo.inscribirse('id-1');

      expectFailure<Servicio>(result, YaInscrito);
    });

    test('maps 409 "estado actual" to inscripcionNoPermitida', () async {
      when(() => api.inscribirse('id-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message:
              '{"detail":"El servicio no admite inscripciones en su estado actual"}',
        ),
      );

      final result = await repo.inscribirse('id-1');

      expectFailure<Servicio>(result, InscripcionNoPermitida);
    });
  });

  group('ServiciosRepositoryImpl.desapuntarse', () {
    test('maps 404 to noInscrito', () async {
      when(() => api.desapuntarse('id-1')).thenThrow(
        ApiException(statusCode: 404, message: 'No estás inscrito'),
      );

      final result = await repo.desapuntarse('id-1');

      expectFailure<Servicio>(result, NoInscrito);
    });

    test('maps 409 to inscripcionNoPermitida', () async {
      when(() => api.desapuntarse('id-1')).thenThrow(
        ApiException(statusCode: 409, message: 'convocado'),
      );

      final result = await repo.desapuntarse('id-1');

      expectFailure<Servicio>(result, InscripcionNoPermitida);
    });
  });

  group('ServiciosRepositoryImpl.listVoluntarios', () {
    test('maps body to domain entities', () async {
      when(() => api.listVoluntarios('id-1')).thenAnswer((_) async =>
          const ApiResponse(body: [
            {
              'voluntario_id': 'v-1',
              'nombre': 'Ana',
              'telefono': '600',
              'tipo': 'inscrito',
              'fecha': '2026-06-10T07:30:00',
            },
            {
              'voluntario_id': 'v-2',
              'nombre': 'Bea',
              'telefono': '601',
              'tipo': 'convocado',
              'fecha': '2026-06-10T07:31:00',
            },
          ], headers: {}));

      final result = await repo.listVoluntarios('id-1');

      switch (result) {
        case Success(:final value):
          expect(value, hasLength(2));
          expect(value.first.nombre, 'Ana');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<List<VoluntarioInscrito>>>());
    });
  });
}
