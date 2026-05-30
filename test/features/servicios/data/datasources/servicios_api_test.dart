import 'package:custodiam/features/servicios/data/datasources/servicios_api.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements ApiClient {}

void main() {
  late _MockClient client;
  late ServiciosApi api;

  setUp(() {
    client = _MockClient();
    api = ServiciosApi(client);
    when(() => client.getList(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => const ApiResponse(body: [], headers: {}));
  });

  Map<String, String> capturedParams() {
    return verify(
      () => client.getList(
        '/servicios',
        queryParams: captureAny(named: 'queryParams'),
      ),
    ).captured.single as Map<String, String>;
  }

  group('ServiciosApi.list query params', () {
    test('serializes desde/hasta as YYYY-MM-DD calendar dates', () async {
      await api.list(
        desde: DateTime(2026, 6, 1, 18, 30),
        hasta: DateTime(2026, 6, 30, 9, 5),
      );

      final params = capturedParams();
      // La hora se descarta: el backend espera un `date` puro.
      expect(params['desde'], '2026-06-01');
      expect(params['hasta'], '2026-06-30');
    });

    test('zero-pads single-digit months and days', () async {
      await api.list(desde: DateTime(2026, 1, 5), hasta: DateTime(2026, 3, 9));

      final params = capturedParams();
      expect(params['desde'], '2026-01-05');
      expect(params['hasta'], '2026-03-09');
    });

    test('omits desde/hasta when not provided', () async {
      await api.list(estado: EstadoServicio.activo, tipo: TipoServicio.preventivo);

      final params = capturedParams();
      expect(params.containsKey('desde'), isFalse);
      expect(params.containsKey('hasta'), isFalse);
      expect(params['estado'], 'activo');
    });
  });
}
