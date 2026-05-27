import 'package:custodiam/features/voluntarios/data/datasources/voluntarios_api.dart';
import 'package:custodiam/features/voluntarios/data/repositories/voluntarios_repository_impl.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntarios_page.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements VoluntariosApi {}

ApiResponse<List<dynamic>> _envelope(
  List<Map<String, dynamic>> items, {
  required int total,
}) {
  return ApiResponse(
    body: items,
    headers: {'x-total-count': total.toString()},
  );
}

Map<String, dynamic> _row({
  String id = 'id-1',
  String nombre = 'Ana',
  String estado = 'activo',
}) {
  return {
    'id': id,
    'nombre': nombre,
    'telefono': '600',
    'municipio': 'Zuera',
    'estado': estado,
    'conductor_habilitado': false,
  };
}

void main() {
  late _MockApi api;
  late VoluntariosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = VoluntariosRepositoryImpl(api);
  });

  group('VoluntariosRepositoryImpl.list', () {
    test('maps body items to domain and reads X-Total-Count', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => _envelope(
            [_row(id: 'a', nombre: 'Ana'), _row(id: 'b', nombre: 'Bea')],
            total: 237,
          ));

      final result = await repo.list();

      expect(result, isA<Success<VoluntariosPage>>());
      switch (result) {
        case Success(:final value):
          expect(value.items, hasLength(2));
          expect(value.items.first.id, 'a');
          expect(value.items.first.nombre, 'Ana');
          expect(value.total, 237);
        case Fail():
          fail('Expected Success');
      }
    });

    test('forwards skip, limit, query and estado to the data source',
        () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => _envelope([], total: 0));

      await repo.list(
        skip: 50,
        limit: 25,
        query: 'ana',
        estado: EstadoVoluntario.baja,
      );

      verify(() => api.list(
            skip: 50,
            limit: 25,
            query: 'ana',
            estado: EstadoVoluntario.baja,
          )).called(1);
    });

    test('falls back to items.length when X-Total-Count is missing',
        () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer(
        (_) async => ApiResponse(body: [_row()], headers: const {}),
      );

      final result = await repo.list();

      switch (result) {
        case Success(:final value):
          expect(value.total, 1);
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.list();

      expectFailure<VoluntariosPage>(result, SessionExpired);
    });

    test('maps other non-2xx to NetworkFailure.serverError carrying status',
        () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenThrow(ApiException(statusCode: 503, message: 'boom'));

      final result = await repo.list();

      expectFailure<VoluntariosPage>(result, ServerError);
      switch (result) {
        case Fail(:final failure):
          expect((failure as ServerError).statusCode, 503);
        case Success():
          fail('Expected Fail');
      }
    });

    test('maps unexpected errors to NetworkFailure.unknown', () async {
      when(() => api.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenThrow(StateError('parse error'));

      final result = await repo.list();

      expectFailure<VoluntariosPage>(result, UnknownNetworkError);
    });
  });
}
