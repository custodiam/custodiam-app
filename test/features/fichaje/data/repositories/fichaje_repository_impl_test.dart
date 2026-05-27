import 'package:custodiam/features/fichaje/data/datasources/fichaje_api.dart';
import 'package:custodiam/features/fichaje/data/repositories/fichaje_repository_impl.dart';
import 'package:custodiam/features/fichaje/domain/entities/fichaje.dart';
import 'package:custodiam/features/fichaje/domain/entities/fichaje_en_servicio.dart';
import 'package:custodiam/features/fichaje/domain/entities/horas_acumuladas.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements FichajeApi {}

Map<String, dynamic> _fichajeRow({
  String id = 'f-1',
  String servicioId = 'svc-1',
  String? horaSalida,
  bool automatico = false,
}) {
  return {
    'id': id,
    'servicio_id': servicioId,
    'voluntario_id': 'v-1',
    'hora_entrada': '2026-06-10T08:00:00',
    'hora_salida': horaSalida,
    'automatico': automatico,
    'duracion_segundos': horaSalida != null ? 7200 : null,
  };
}

void main() {
  late _MockApi api;
  late FichajeRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = FichajeRepositoryImpl(api);
  });

  group('FichajeRepositoryImpl.ficharEntrada', () {
    test('returns Success on 201', () async {
      when(() => api.ficharEntrada('svc-1'))
          .thenAnswer((_) async => _fichajeRow());

      final result = await repo.ficharEntrada('svc-1');

      switch (result) {
        case Success(:final value):
          expect(value.servicioId, 'svc-1');
          expect(value.estaAbierto, isTrue);
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 409 "no admite fichajes" to servicioNoActivo', () async {
      when(() => api.ficharEntrada('svc-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"El servicio no admite fichajes: ..."}',
        ),
      );

      final result = await repo.ficharEntrada('svc-1');

      expectFailure<Fichaje>(result, ServicioNoActivoParaFichar);
    });

    test('maps 409 "no inscrito" to voluntarioNoInscrito', () async {
      when(() => api.ficharEntrada('svc-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message:
              '{"detail":"No estás inscrito ni convocado en este servicio"}',
        ),
      );

      final result = await repo.ficharEntrada('svc-1');

      expectFailure<Fichaje>(result, VoluntarioNoInscritoParaFichar);
    });

    test('maps generic 409 to yaFichado (default)', () async {
      when(() => api.ficharEntrada('svc-1')).thenThrow(
        ApiException(
          statusCode: 409,
          message: '{"detail":"otra cosa"}',
        ),
      );

      final result = await repo.ficharEntrada('svc-1');

      expectFailure<Fichaje>(result, YaFichado);
    });
  });

  group('FichajeRepositoryImpl.ficharSalida', () {
    test('returns Success on 200', () async {
      when(() => api.ficharSalida('svc-1')).thenAnswer(
        (_) async => _fichajeRow(horaSalida: '2026-06-10T10:00:00'),
      );

      final result = await repo.ficharSalida('svc-1');

      switch (result) {
        case Success(:final value):
          expect(value.estaAbierto, isFalse);
          expect(value.duracionSegundos, 7200);
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 404 to sinFichajeAbierto', () async {
      when(() => api.ficharSalida('svc-1'))
          .thenThrow(ApiException(statusCode: 404, message: 'nope'));

      final result = await repo.ficharSalida('svc-1');

      expectFailure<Fichaje>(result, SinFichajeAbierto);
    });
  });

  group('FichajeRepositoryImpl.listFichadosServicio', () {
    test('maps body to FichajeEnServicio entities', () async {
      when(() => api.listFichadosServicio('svc-1')).thenAnswer(
        (_) async => const ApiResponse(
          body: [
            {
              'fichaje_id': 'f-1',
              'voluntario_id': 'v-1',
              'nombre': 'Ana',
              'hora_entrada': '2026-06-10T08:00:00',
              'hora_salida': null,
              'automatico': false,
              'duracion_segundos': null,
            },
            {
              'fichaje_id': 'f-2',
              'voluntario_id': 'v-2',
              'nombre': 'Bea',
              'hora_entrada': '2026-06-10T08:05:00',
              'hora_salida': '2026-06-10T10:05:00',
              'automatico': false,
              'duracion_segundos': 7200,
            },
          ],
          headers: {},
        ),
      );

      final result = await repo.listFichadosServicio('svc-1');

      switch (result) {
        case Success(:final value):
          expect(value, hasLength(2));
          expect(value.first.nombre, 'Ana');
          expect(value.last.estaAbierto, isFalse);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<List<FichajeEnServicio>>>());
    });
  });

  group('FichajeRepositoryImpl.misHoras', () {
    test('parses HorasAcumuladasResponse', () async {
      when(() => api.misHoras()).thenAnswer((_) async => {
            'voluntario_id': 'v-1',
            'total_segundos': 7200,
            'total_horas': 2.0,
            'fichajes_cerrados': 1,
            'fichajes_abiertos': 0,
          });

      final result = await repo.misHoras();

      switch (result) {
        case Success(:final value):
          expect(value.totalSegundos, 7200);
          expect(value.totalHoras, 2.0);
          expect(value.fichajesCerrados, 1);
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<HorasAcumuladas>>());
    });

    test('tolera total_horas como int en JSON', () async {
      when(() => api.misHoras()).thenAnswer((_) async => {
            'voluntario_id': 'v-1',
            'total_segundos': 0,
            'total_horas': 0,
            'fichajes_cerrados': 0,
            'fichajes_abiertos': 0,
          });

      final result = await repo.misHoras();

      switch (result) {
        case Success(:final value):
          expect(value.totalHoras, 0.0);
        case Fail():
          fail('Expected Success');
      }
    });
  });
}
