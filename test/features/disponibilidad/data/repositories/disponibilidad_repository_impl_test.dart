import 'package:custodiam/features/disponibilidad/data/datasources/disponibilidad_api.dart';
import 'package:custodiam/features/disponibilidad/data/repositories/disponibilidad_repository_impl.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DisponibilidadApi {}

Map<String, dynamic> _diaJson({
  String fecha = '2026-06-15',
  bool disponible = true,
}) =>
    {
      'id': 'dia-1',
      'voluntario_id': 'vol-1',
      'fecha': fecha,
      'disponible': disponible,
    };

Map<String, dynamic> _mesJson({
  int year = 2026,
  int month = 6,
  List<Map<String, dynamic>>? dias,
}) =>
    {
      'year': year,
      'month': month,
      'dias': dias ?? [_diaJson()],
    };

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  late _MockApi api;
  late DisponibilidadRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = DisponibilidadRepositoryImpl(api);
  });

  group('obtenerMes', () {
    test('devuelve Success con el mes parseado', () async {
      when(() => api.obtenerMes(year: 2026, month: 6))
          .thenAnswer((_) async => _mesJson());

      final result = await repo.obtenerMes(year: 2026, month: 6);

      switch (result) {
        case Success(:final value):
          expect(value.year, 2026);
          expect(value.month, 6);
          expect(value.dias, hasLength(1));
          expect(value.estaDisponible(15), isTrue);
        case Fail():
          fail('Expected Success');
      }
    });

    test('mapea 401 a AuthFailure.sessionExpired', () async {
      when(() => api.obtenerMes(year: 2026, month: 6))
          .thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.obtenerMes(year: 2026, month: 6);
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<SessionExpired>());
      }
    });

    test('mapea 404 a VoluntariosFailure.notFound', () async {
      when(() => api.obtenerMes(year: 2026, month: 6))
          .thenThrow(ApiException(statusCode: 404, message: 'no voluntario'));

      final result = await repo.obtenerMes(year: 2026, month: 6);
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<VoluntarioNotFound>());
      }
    });

    test('mapea 500 a NetworkFailure.serverError', () async {
      when(() => api.obtenerMes(year: 2026, month: 6))
          .thenThrow(ApiException(statusCode: 500, message: 'boom'));

      final result = await repo.obtenerMes(year: 2026, month: 6);
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<ServerError>());
          expect((failure as ServerError).statusCode, 500);
      }
    });
  });

  group('marcarDia', () {
    test('devuelve Success con la fila resultante', () async {
      when(() => api.marcarDia(
            fecha: any(named: 'fecha'),
            disponible: true,
          )).thenAnswer((_) async => _diaJson(disponible: true));

      final result =
          await repo.marcarDia(fecha: DateTime(2026, 6, 15), disponible: true);

      switch (result) {
        case Success(:final value):
          expect(value.id, 'dia-1');
          expect(value.disponible, isTrue);
        case Fail():
          fail('Expected Success');
      }
    });

    test('mapea 422 a DisponibilidadFailure.fechaPasada', () async {
      when(() => api.marcarDia(
            fecha: any(named: 'fecha'),
            disponible: any(named: 'disponible'),
          )).thenThrow(
        ApiException(
          statusCode: 422,
          message: 'no puedes editar el pasado',
        ),
      );

      final result =
          await repo.marcarDia(fecha: DateTime(2020), disponible: true);

      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<FechaPasada>());
      }
    });

    test('mapea 404 a VoluntariosFailure.notFound', () async {
      when(() => api.marcarDia(
            fecha: any(named: 'fecha'),
            disponible: any(named: 'disponible'),
          )).thenThrow(ApiException(statusCode: 404, message: 'no voluntario'));

      final result =
          await repo.marcarDia(fecha: DateTime(2026, 6, 15), disponible: true);
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<VoluntarioNotFound>());
      }
    });

    test('captura excepciones genéricas como NetworkFailure.unknown',
        () async {
      when(() => api.marcarDia(
            fecha: any(named: 'fecha'),
            disponible: any(named: 'disponible'),
          )).thenThrow(StateError('socket cerrado'));

      final result =
          await repo.marcarDia(fecha: DateTime(2026, 6, 15), disponible: true);
      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<UnknownNetworkError>());
      }
    });
  });
}
