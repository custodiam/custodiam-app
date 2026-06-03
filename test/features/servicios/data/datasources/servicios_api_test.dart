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

  group('ServiciosApi.update (A5)', () {
    test('PATCH /servicios/{id} con el cuerpo parcial', () async {
      when(() => client.patch(any(), any()))
          .thenAnswer((_) async => {'id': 'id-1'});

      await api.update('id-1', {'titulo': 'Nuevo'});

      verify(() => client.patch('/servicios/id-1', {'titulo': 'Nuevo'}))
          .called(1);
    });
  });

  group('ServiciosApi.delete (A7)', () {
    test('DELETE /servicios/{id}', () async {
      when(() => client.delete(any())).thenAnswer((_) async => {});

      await api.delete('id-1');

      verify(() => client.delete('/servicios/id-1')).called(1);
    });

    test('absorbe la FormatException del 204 (cuerpo vacío)', () async {
      // ApiClient.delete pasa por jsonDecode, que lanza FormatException sobre
      // el cuerpo vacío del 204 No Content aunque el borrado haya ido bien.
      when(() => client.delete(any()))
          .thenThrow(const FormatException('Unexpected end of input'));

      // No debe propagar: termina normalmente.
      await expectLater(api.delete('id-1'), completes);
    });

    test('propaga ApiException de un fallo real (p. ej. 409)', () async {
      when(() => client.delete(any())).thenThrow(
        ApiException(statusCode: 409, message: 'tiene actividad'),
      );

      await expectLater(api.delete('id-1'), throwsA(isA<ApiException>()));
    });
  });
}
