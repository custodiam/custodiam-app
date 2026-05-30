import 'package:custodiam/infrastructure/catalogo/ubicaciones_catalogo_service.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

ApiResponse<List<dynamic>> _resp(List<Map<String, dynamic>> rows) =>
    ApiResponse<List<dynamic>>(body: rows, headers: const {});

void main() {
  late _MockApiClient client;
  late UbicacionesCatalogoService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockApiClient();
    service = UbicacionesCatalogoService(client);
  });

  group('buscarUbicaciones', () {
    test('mapea filas a CatalogoRecurso y reenvía q/skip/limit', () async {
      when(
        () => client.getList(
          '/ubicaciones',
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => _resp([
          {'id': 'u-1', 'nombre': 'Base Zuera'},
          {'id': 'u-2', 'nombre': 'Almacén'},
        ]),
      );

      final result = await service.buscarUbicaciones('zu', 1);

      expect(result, hasLength(2));
      expect(result.first.id, 'u-1');
      expect(result.first.label, 'Base Zuera');

      final params = verify(
        () => client.getList(
          '/ubicaciones',
          queryParams: captureAny(named: 'queryParams'),
        ),
      ).captured.single as Map<String, String>;
      expect(params['q'], 'zu');
      expect(params['skip'], '50'); // page 1 * pageSize 50
      expect(params['limit'], '50');
    });

    test('omite q cuando el filtro está en blanco', () async {
      when(
        () => client.getList(
          '/ubicaciones',
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer((_) async => _resp(const []));

      await service.buscarUbicaciones('   ', 0);

      final params = verify(
        () => client.getList(
          '/ubicaciones',
          queryParams: captureAny(named: 'queryParams'),
        ),
      ).captured.single as Map<String, String>;
      expect(params.containsKey('q'), isFalse);
      expect(params['skip'], '0');
    });
  });

  group('crear', () {
    test('manda nombre + descripción y devuelve el recurso creado', () async {
      when(() => client.post('/ubicaciones', any())).thenAnswer(
        (_) async => {'id': 'u-9', 'nombre': 'Nave nueva'},
      );

      final creada = await service.crear(
        nombre: 'Nave nueva',
        descripcion: 'Polígono',
      );

      expect(creada.id, 'u-9');
      expect(creada.label, 'Nave nueva');

      final body = verify(
        () => client.post('/ubicaciones', captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(body['nombre'], 'Nave nueva');
      expect(body['descripcion'], 'Polígono');
    });

    test('omite la descripción cuando está vacía', () async {
      when(() => client.post('/ubicaciones', any())).thenAnswer(
        (_) async => {'id': 'u-10', 'nombre': 'Sin desc'},
      );

      await service.crear(nombre: 'Sin desc', descripcion: '   ');

      final body = verify(
        () => client.post('/ubicaciones', captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(body.containsKey('descripcion'), isFalse);
    });

    test('propaga ApiException cuando el nombre ya existe (409)', () async {
      when(() => client.post('/ubicaciones', any())).thenThrow(
        ApiException(statusCode: 409, message: 'duplicada'),
      );

      expect(
        () => service.crear(nombre: 'Repetida'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
