import 'package:custodiam/infrastructure/catalogo/inventario_catalogo_service.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

ApiResponse<List<dynamic>> _resp(List<Map<String, dynamic>> rows) =>
    ApiResponse<List<dynamic>>(body: rows, headers: const {});

void main() {
  late _MockApiClient client;
  late InventarioCatalogoService service;

  setUp(() {
    client = _MockApiClient();
    service = InventarioCatalogoService(client);
  });

  test('buscarMaterial maps rows and forwards q/skip/limit', () async {
    when(
      () => client.getList(
        '/inventario/material',
        queryParams: any(named: 'queryParams'),
      ),
    ).thenAnswer(
      (_) async => _resp([
        {'id': 'm-1', 'nombre': 'Casco', 'codigo': 'CAS-1'},
        {'id': 'm-2', 'nombre': 'Botas', 'codigo': 'BOT-1'},
      ]),
    );

    final result = await service.buscarMaterial('cas', 1);

    expect(result, hasLength(2));
    expect(result.first.id, 'm-1');
    expect(result.first.label, 'Casco');

    final params = verify(
      () => client.getList(
        '/inventario/material',
        queryParams: captureAny(named: 'queryParams'),
      ),
    ).captured.single as Map<String, String>;
    expect(params['q'], 'cas');
    expect(params['skip'], '50'); // page 1 * pageSize 50
    expect(params['limit'], '50');
  });

  test('buscarVehiculos labels rows with código interno + matrícula', () async {
    when(
      () => client.getList(
        '/inventario/vehiculos',
        queryParams: any(named: 'queryParams'),
      ),
    ).thenAnswer(
      (_) async => _resp([
        {'id': 'v-1', 'codigo_interno': 'VEH-1', 'matricula': '1234ABC'},
      ]),
    );

    final result = await service.buscarVehiculos('', 0);

    expect(result, hasLength(1));
    expect(result.first.id, 'v-1');
    expect(result.first.label, 'VEH-1 · 1234ABC');
  });

  test('omits q when the filter is blank and computes skip from the page',
      () async {
    when(
      () => client.getList(
        '/inventario/material',
        queryParams: any(named: 'queryParams'),
      ),
    ).thenAnswer((_) async => _resp(const []));

    await service.buscarMaterial('   ', 0);

    final params = verify(
      () => client.getList(
        '/inventario/material',
        queryParams: captureAny(named: 'queryParams'),
      ),
    ).captured.single as Map<String, String>;
    expect(params.containsKey('q'), isFalse);
    expect(params['skip'], '0');
  });
}
