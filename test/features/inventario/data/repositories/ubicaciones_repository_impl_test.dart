// Tests del repositorio del catálogo de ubicaciones (E10). Mockea
// UbicacionesApi (mocktail) y verifica:
//  - listar mapea items + lee X-Total-Count,
//  - obtener / crear felices,
//  - mapeo de 409 a nombreDuplicado (crear/actualizar) y enUso (eliminar),
//  - mapeo de 404 a notFound y 401 a AuthFailure.sessionExpired,
//  - eliminar 204 (cuerpo vacío) resuelve Success<void>,
//  - el body de crear/actualizar arma lat+lng solo cuando llegan ambos.
//
// El mapeo de Failure vive en guía 26 §4; este test fija su contrato.

import 'package:custodiam/features/inventario/data/datasources/ubicaciones_api.dart';
import 'package:custodiam/features/inventario/data/repositories/ubicaciones_repository_impl.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicacion.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicaciones_page.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements UbicacionesApi {}

Map<String, dynamic> _summary({
  String id = 'u-1',
  String nombre = 'Base Zuera',
  double? lat,
  double? lng,
}) {
  return {
    'id': id,
    'nombre': nombre,
    'lat': lat,
    'lng': lng,
  };
}

Map<String, dynamic> _detalle({
  String id = 'u-1',
  String nombre = 'Base Zuera',
  String? descripcion = 'Parque municipal',
  double? lat = 41.86,
  double? lng = -0.78,
}) {
  return {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'lat': lat,
    'lng': lng,
  };
}

void main() {
  late _MockApi api;
  late UbicacionesRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = UbicacionesRepositoryImpl(api);
  });

  group('listar', () {
    test('mapea items y lee la cabecera x-total-count', () async {
      when(() => api.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer((_) async => ApiResponse(
            body: [
              _summary(id: 'a', nombre: 'Base A', lat: 41.0, lng: -0.7),
              _summary(id: 'b', nombre: 'Base B'),
            ],
            headers: const {'x-total-count': '12'},
          ));

      final result = await repo.listar();

      switch (result) {
        case Success(:final value):
          expect(value.items, hasLength(2));
          expect(value.total, 12);
          expect(value.items.first.nombre, 'Base A');
          expect(value.items.first.tieneCoordenadas, isTrue);
          expect(value.items[1].tieneCoordenadas, isFalse);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<UbicacionesPage>>());
    });

    test('sin cabecera de total cae al tamaño de la lista', () async {
      when(() => api.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer((_) async => ApiResponse(
            body: [_summary(id: 'a')],
            headers: const {},
          ));

      final result = await repo.listar();

      switch (result) {
        case Success(:final value):
          expect(value.total, 1);
        case Fail():
          fail('Expected Success');
      }
    });

    test('mapea 401 a AuthFailure.sessionExpired', () async {
      when(() => api.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.listar();

      expectFailure<UbicacionesPage>(result, SessionExpired);
    });
  });

  group('obtener', () {
    test('parsea el detalle con descripción y coordenadas', () async {
      when(() => api.obtener('u-1')).thenAnswer((_) async => _detalle());

      final result = await repo.obtener('u-1');

      switch (result) {
        case Success(:final value):
          expect(value.id, 'u-1');
          expect(value.descripcion, 'Parque municipal');
          expect(value.tieneCoordenadas, isTrue);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<Ubicacion>>());
    });

    test('mapea 404 a UbicacionNoEncontrada', () async {
      when(() => api.obtener('u-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'not found'));

      final result = await repo.obtener('u-1');

      expectFailure<Ubicacion>(result, UbicacionNoEncontrada);
    });
  });

  group('crear', () {
    test('éxito: parsea la respuesta', () async {
      when(() => api.crear(any())).thenAnswer((_) async => _detalle());

      final result = await repo.crear(nombre: 'Base Zuera');

      switch (result) {
        case Success(:final value):
          expect(value.nombre, 'Base Zuera');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<Ubicacion>>());
    });

    test('mapea 409 a UbicacionNombreDuplicado', () async {
      when(() => api.crear(any()))
          .thenThrow(ApiException(statusCode: 409, message: 'dup'));

      final result = await repo.crear(nombre: 'Base Zuera');

      expectFailure<Ubicacion>(result, UbicacionNombreDuplicado);
    });

    test('el body incluye lat+lng solo cuando llegan ambos', () async {
      when(() => api.crear(any())).thenAnswer((_) async => _detalle());

      await repo.crear(
        nombre: 'Base Zuera',
        descripcion: 'Parque',
        lat: 41.86,
        lng: -0.78,
      );

      final body = verify(() => api.crear(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(body['nombre'], 'Base Zuera');
      expect(body['descripcion'], 'Parque');
      expect(body['lat'], 41.86);
      expect(body['lng'], -0.78);
    });

    test('el body omite lat+lng cuando solo llega una coordenada', () async {
      when(() => api.crear(any())).thenAnswer((_) async => _detalle());

      // lat sin lng: la pareja se descarta (invariante del backend).
      await repo.crear(nombre: 'Base Zuera', lat: 41.86);

      final body = verify(() => api.crear(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(body.containsKey('lat'), isFalse);
      expect(body.containsKey('lng'), isFalse);
      // Descripción nula tampoco entra.
      expect(body.containsKey('descripcion'), isFalse);
    });
  });

  group('actualizar', () {
    test('éxito: parsea la respuesta', () async {
      when(() => api.actualizar('u-1', any()))
          .thenAnswer((_) async => _detalle(nombre: 'Base nueva'));

      final result = await repo.actualizar('u-1', nombre: 'Base nueva');

      switch (result) {
        case Success(:final value):
          expect(value.nombre, 'Base nueva');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<Ubicacion>>());
    });

    test('mapea 409 a UbicacionNombreDuplicado', () async {
      when(() => api.actualizar('u-1', any()))
          .thenThrow(ApiException(statusCode: 409, message: 'dup'));

      final result = await repo.actualizar('u-1', nombre: 'Base nueva');

      expectFailure<Ubicacion>(result, UbicacionNombreDuplicado);
    });

    test('el body incluye lat+lng solo cuando llegan ambos', () async {
      when(() => api.actualizar('u-1', any()))
          .thenAnswer((_) async => _detalle());

      await repo.actualizar('u-1', nombre: 'X', lat: 1.0, lng: 2.0);

      final body = verify(() => api.actualizar('u-1', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body['lat'], 1.0);
      expect(body['lng'], 2.0);
    });
  });

  group('eliminar', () {
    test('éxito: resuelve Success<void>', () async {
      when(() => api.eliminar('u-1')).thenAnswer((_) async {});

      final result = await repo.eliminar('u-1');

      expect(result, isA<Success<void>>());
    });

    test('mapea 409 a UbicacionEnUso', () async {
      when(() => api.eliminar('u-1'))
          .thenThrow(ApiException(statusCode: 409, message: 'en uso'));

      final result = await repo.eliminar('u-1');

      expectFailure<void>(result, UbicacionEnUso);
    });

    test('mapea 404 a UbicacionNoEncontrada', () async {
      when(() => api.eliminar('u-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'not found'));

      final result = await repo.eliminar('u-1');

      expectFailure<void>(result, UbicacionNoEncontrada);
    });
  });
}
