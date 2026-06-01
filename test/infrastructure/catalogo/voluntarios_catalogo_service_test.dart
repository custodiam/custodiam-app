import 'package:custodiam/infrastructure/catalogo/voluntarios_catalogo_service.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

ApiResponse<List<dynamic>> _resp(List<Map<String, dynamic>> rows) =>
    ApiResponse<List<dynamic>>(body: rows, headers: const {});

void main() {
  late _MockApiClient client;
  late VoluntariosCatalogoService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockApiClient();
    service = VoluntariosCatalogoService(client);
  });

  group('buscarVoluntarios', () {
    test('mapea filas a CatalogoRecurso (nombre · teléfono) y reenvía '
        'q/skip/limit', () async {
      when(
        () => client.getList(
          '/voluntarios',
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => _resp([
          {'id': 'v-1', 'nombre': 'Ana García', 'telefono': '600111222'},
          {'id': 'v-2', 'nombre': 'Beatriz López', 'telefono': '699888777'},
        ]),
      );

      final result = await service.buscarVoluntarios('ana', 1);

      expect(result, hasLength(2));
      expect(result.first.id, 'v-1');
      expect(result.first.label, 'Ana García · 600111222');

      final params = verify(
        () => client.getList(
          '/voluntarios',
          queryParams: captureAny(named: 'queryParams'),
        ),
      ).captured.single as Map<String, String>;
      expect(params['q'], 'ana');
      expect(params['skip'], '50'); // page 1 * pageSize 50
      expect(params['limit'], '50');
    });

    test('omite q cuando el filtro está en blanco', () async {
      when(
        () => client.getList(
          '/voluntarios',
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer((_) async => _resp(const []));

      await service.buscarVoluntarios('   ', 0);

      final params = verify(
        () => client.getList(
          '/voluntarios',
          queryParams: captureAny(named: 'queryParams'),
        ),
      ).captured.single as Map<String, String>;
      expect(params.containsKey('q'), isFalse);
      expect(params['skip'], '0');
    });
  });
}
