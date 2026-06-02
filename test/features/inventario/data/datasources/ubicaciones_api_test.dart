// Tests del datasource del catálogo de ubicaciones (E10). Mockea ApiClient y
// fija la única lógica no trivial del wrapper: que `eliminar` absorba la
// FormatException que ApiClient.delete lanza sobre el cuerpo vacío de un 204,
// pero propague una ApiException de un fallo real (p. ej. 409 "en uso"). Cubre
// también que listar arma los query params y que crear/actualizar/obtener
// delegan en el verbo y la ruta correctos.

import 'package:custodiam/features/inventario/data/datasources/ubicaciones_api.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String, String>{});
  });

  late _MockClient client;
  late UbicacionesApi api;

  setUp(() {
    client = _MockClient();
    api = UbicacionesApi(client);
  });

  group('eliminar', () {
    test('absorbe la FormatException del 204 con cuerpo vacío', () async {
      // ApiClient.delete pasa el cuerpo por jsonDecode; un 204 (cuerpo vacío)
      // lanza FormatException aunque la operación haya ido bien. El datasource
      // la traga y resuelve sin error.
      when(() => client.delete(any()))
          .thenThrow(const FormatException('Unexpected end of input'));

      await expectLater(api.eliminar('u-1'), completes);
    });

    test('propaga la ApiException de un fallo real (409 en uso)', () async {
      when(() => client.delete(any()))
          .thenThrow(ApiException(statusCode: 409, message: 'en uso'));

      await expectLater(api.eliminar('u-1'), throwsA(isA<ApiException>()));
    });

    test('un 2xx con cuerpo resuelve sin lanzar', () async {
      when(() => client.delete(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      await expectLater(api.eliminar('u-1'), completes);
    });
  });

  group('listar', () {
    test('arma skip/limit y omite q vacío', () async {
      when(() => client.getList(any(), queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => const ApiResponse(body: [], headers: {}));

      await api.listar(skip: 50, limit: 50);

      final params = verify(() => client.getList('/ubicaciones',
              queryParams: captureAny(named: 'queryParams')))
          .captured
          .single as Map<String, String>;
      expect(params['skip'], '50');
      expect(params['limit'], '50');
      expect(params.containsKey('q'), isFalse);
    });

    test('incluye q cuando hay query', () async {
      when(() => client.getList(any(), queryParams: any(named: 'queryParams')))
          .thenAnswer((_) async => const ApiResponse(body: [], headers: {}));

      await api.listar(query: 'zuera');

      final params = verify(() => client.getList('/ubicaciones',
              queryParams: captureAny(named: 'queryParams')))
          .captured
          .single as Map<String, String>;
      expect(params['q'], 'zuera');
    });
  });

  group('crear / actualizar / obtener', () {
    test('crear delega el body al POST /ubicaciones', () async {
      when(() => client.post(any(), any()))
          .thenAnswer((_) async => {'id': 'u-1', 'nombre': 'X'});

      final json = await api.crear({'nombre': 'X'});

      expect(json['id'], 'u-1');
      verify(() => client.post('/ubicaciones', {'nombre': 'X'})).called(1);
    });

    test('actualizar delega al PATCH /ubicaciones/{id}', () async {
      when(() => client.patch(any(), any()))
          .thenAnswer((_) async => {'id': 'u-1', 'nombre': 'Y'});

      await api.actualizar('u-1', {'nombre': 'Y'});

      verify(() => client.patch('/ubicaciones/u-1', {'nombre': 'Y'})).called(1);
    });

    test('obtener delega al GET /ubicaciones/{id}', () async {
      when(() => client.get(any())).thenAnswer((_) async => {'id': 'u-1'});

      await api.obtener('u-1');

      verify(() => client.get('/ubicaciones/u-1')).called(1);
    });
  });
}
