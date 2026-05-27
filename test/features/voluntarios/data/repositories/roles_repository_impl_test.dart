import 'package:custodiam/features/voluntarios/data/datasources/roles_api.dart';
import 'package:custodiam/features/voluntarios/data/repositories/roles_repository_impl.dart';
import 'package:custodiam/features/voluntarios/domain/entities/rol.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements RolesApi {}

ApiResponse<List<dynamic>> _wrap(List<Map<String, dynamic>> items) =>
    ApiResponse(body: items, headers: const {});

void main() {
  late _MockApi api;
  late RolesRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = RolesRepositoryImpl(api);
  });

  test('listCatalogo returns Success with mapped Rol list', () async {
    when(() => api.listCatalogo()).thenAnswer((_) async => _wrap([
          {'id': 'a', 'nombre': 'voluntario', 'nivel': 1},
          {
            'id': 'b',
            'nombre': 'jefe_equipo',
            'nivel': 3,
            'descripcion': 'Mando intermedio',
          },
        ]));

    final result = await repo.listCatalogo();

    expect(result, isA<Success<List<Rol>>>());
    switch (result) {
      case Success(:final value):
        expect(value, hasLength(2));
        expect(value.first.nombre, 'voluntario');
        expect(value.last.descripcion, 'Mando intermedio');
      case Fail():
        fail('Expected Success');
    }
  });

  test('maps 401 to AuthFailure.sessionExpired', () async {
    when(() => api.listCatalogo())
        .thenThrow(ApiException(statusCode: 401, message: 'expired'));

    final result = await repo.listCatalogo();

    expectFailure<List<Rol>>(result, SessionExpired);
  });

  test('maps other non-2xx to NetworkFailure.serverError', () async {
    when(() => api.listCatalogo())
        .thenThrow(ApiException(statusCode: 503, message: 'boom'));

    final result = await repo.listCatalogo();

    expectFailure<List<Rol>>(result, ServerError);
  });
}
