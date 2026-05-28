import 'package:custodiam/features/historial/data/datasources/historial_api.dart';
import 'package:custodiam/features/historial/data/repositories/historial_repository_impl.dart';
import 'package:custodiam/features/historial/domain/entities/tipo_evento_voluntario.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements HistorialApi {}

Map<String, dynamic> _eventoJson({
  String id = 'ev-1',
  String tipo = 'fichaje_entrada',
}) =>
    {
      'id': id,
      'voluntario_id': 'vol-1',
      'tipo_evento': tipo,
      'payload': {'servicio_id': 'svc-1'},
      'actor_keycloak_id': 'kc-1',
      'created_at': '2026-05-28T10:00:00',
    };

Map<String, dynamic> _resumenJson({bool conUltimo = true}) => {
      'horas_totales': 42,
      'segundos_totales': 42 * 3600,
      'servicios_realizados': 7,
      'ultimo_servicio': conUltimo
          ? {
              'servicio_id': 'svc-9',
              'titulo': 'Cabalgata de Reyes',
              'fecha_inicio': '2026-01-05T18:00:00',
            }
          : null,
    };

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  late _MockApi api;
  late HistorialRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = HistorialRepositoryImpl(api);
  });

  group('obtenerHistorial', () {
    test('parsea eventos y lee X-Total-Count del header', () async {
      when(() => api.obtenerHistorial(
            skip: 0,
            limit: 50,
            tipos: null,
            since: null,
            until: null,
          )).thenAnswer((_) async => ApiResponse(
            body: [_eventoJson(id: 'a'), _eventoJson(id: 'b')],
            headers: const {'x-total-count': '120'},
          ));

      final result = await repo.obtenerHistorial();

      switch (result) {
        case Success(:final value):
          expect(value.eventos, hasLength(2));
          expect(value.total, 120);
          expect(value.hayMas, isTrue);
          expect(value.eventos.first.tipo, TipoEventoVoluntario.fichajeEntrada);
        case Fail():
          fail('Expected Success');
      }
    });

    test('si falta X-Total-Count usa el len de la página', () async {
      when(() => api.obtenerHistorial(
            skip: 0,
            limit: 50,
            tipos: null,
            since: null,
            until: null,
          )).thenAnswer((_) async => ApiResponse(
            body: [_eventoJson()],
            headers: const {},
          ));

      final result = await repo.obtenerHistorial();
      switch (result) {
        case Success(:final value):
          expect(value.total, 1);
          expect(value.hayMas, isFalse);
        case Fail():
          fail('Expected Success');
      }
    });

    test('propaga filtros tipos/since/until al api', () async {
      final since = DateTime.utc(2026, 1, 1);
      final until = DateTime.utc(2026, 6, 30);
      const tipos = [TipoEventoVoluntario.fichajeEntrada];
      when(() => api.obtenerHistorial(
            skip: 10,
            limit: 25,
            tipos: tipos,
            since: since,
            until: until,
          )).thenAnswer((_) async => const ApiResponse(
                body: <dynamic>[],
                headers: {'x-total-count': '0'},
              ));

      await repo.obtenerHistorial(
        skip: 10,
        limit: 25,
        tipos: tipos,
        since: since,
        until: until,
      );

      verify(() => api.obtenerHistorial(
            skip: 10,
            limit: 25,
            tipos: tipos,
            since: since,
            until: until,
          )).called(1);
    });

    test('mapea 401 a AuthFailure.sessionExpired', () async {
      when(() => api.obtenerHistorial(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            tipos: any(named: 'tipos'),
            since: any(named: 'since'),
            until: any(named: 'until'),
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.obtenerHistorial();
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<SessionExpired>());
      }
    });

    test('mapea 404 a VoluntariosFailure.notFound', () async {
      when(() => api.obtenerHistorial(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            tipos: any(named: 'tipos'),
            since: any(named: 'since'),
            until: any(named: 'until'),
          )).thenThrow(ApiException(statusCode: 404, message: 'no voluntario'));

      final result = await repo.obtenerHistorial();
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<VoluntarioNotFound>());
      }
    });

    test('excepciones genéricas → NetworkFailure.unknown', () async {
      when(() => api.obtenerHistorial(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            tipos: any(named: 'tipos'),
            since: any(named: 'since'),
            until: any(named: 'until'),
          )).thenThrow(StateError('socket cerrado'));

      final result = await repo.obtenerHistorial();
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<UnknownNetworkError>());
      }
    });
  });

  group('obtenerResumen', () {
    test('parsea resumen con ultimoServicio presente', () async {
      when(() => api.obtenerResumen())
          .thenAnswer((_) async => _resumenJson());

      final result = await repo.obtenerResumen();
      switch (result) {
        case Success(:final value):
          expect(value.horasTotales, 42);
          expect(value.serviciosRealizados, 7);
          expect(value.ultimoServicio, isNotNull);
          expect(value.ultimoServicio!.titulo, 'Cabalgata de Reyes');
        case Fail():
          fail('Expected Success');
      }
    });

    test('parsea resumen sin ultimoServicio (null)', () async {
      when(() => api.obtenerResumen())
          .thenAnswer((_) async => _resumenJson(conUltimo: false));

      final result = await repo.obtenerResumen();
      switch (result) {
        case Success(:final value):
          expect(value.ultimoServicio, isNull);
          expect(value.horasTotales, 42);
        case Fail():
          fail('Expected Success');
      }
    });

    test('mapea 404 del resumen a VoluntariosFailure.notFound', () async {
      when(() => api.obtenerResumen())
          .thenThrow(ApiException(statusCode: 404, message: 'no voluntario'));

      final result = await repo.obtenerResumen();
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<VoluntarioNotFound>());
      }
    });
  });
}
