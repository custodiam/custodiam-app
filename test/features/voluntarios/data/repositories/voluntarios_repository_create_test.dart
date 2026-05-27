// Coverage for VoluntariosRepositoryImpl.create (US-02-01). 409 is
// intentionally collapsed into VoluntariosFailure.dniOrEmailDuplicado
// because the backend message does not always disambiguate between
// dni and email — the form shows a single accurate message.

import 'package:custodiam/features/voluntarios/data/datasources/voluntarios_api.dart';
import 'package:custodiam/features/voluntarios/data/repositories/voluntarios_repository_impl.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_create.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements VoluntariosApi {}

VoluntarioCreate _data() => VoluntarioCreate(
      nombre: 'Carlos López',
      telefono: '600111222',
      municipio: 'Villanueva',
      fechaNacimiento: DateTime(1995, 6, 20),
      dni: '11111111B',
      email: 'carlos@example.com',
    );

Map<String, dynamic> _responseJson() => {
      'id': 'new-id',
      'nombre': 'Carlos López',
      'telefono': '600111222',
      'municipio': 'Villanueva',
      'fecha_nacimiento': '1995-06-20',
      'estado': 'activo',
      'fecha_alta': '2026-05-27',
      'conductor_habilitado': false,
      'dni': '11111111B',
      'email': 'carlos@example.com',
    };

void main() {
  late _MockApi api;
  late VoluntariosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = VoluntariosRepositoryImpl(api);
  });

  test('serialises payload and returns Success on 201', () async {
    when(() => api.create(any())).thenAnswer((_) async => _responseJson());

    final result = await repo.create(_data());

    expect(result, isA<Success<Voluntario>>());
    final captured = verify(() => api.create(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(captured['nombre'], 'Carlos López');
    expect(captured['fecha_nacimiento'], '1995-06-20');
    expect(captured['conductor_habilitado'], false);
    expect(captured['dni'], '11111111B');
    expect(captured['email'], 'carlos@example.com');
  });

  test('maps 409 to VoluntariosFailure.dniOrEmailDuplicado', () async {
    when(() => api.create(any()))
        .thenThrow(ApiException(statusCode: 409, message: 'dupe'));

    final result = await repo.create(_data());

    expectFailure<Voluntario>(result, DniOrEmailDuplicado);
  });

  test('maps 502 to VoluntariosFailure.keycloakSyncFailed', () async {
    when(() => api.create(any()))
        .thenThrow(ApiException(statusCode: 502, message: 'kc down'));

    final result = await repo.create(_data());

    expectFailure<Voluntario>(result, KeycloakSyncFailed);
  });

  test('maps 401 to AuthFailure.sessionExpired', () async {
    when(() => api.create(any()))
        .thenThrow(ApiException(statusCode: 401, message: 'expired'));

    final result = await repo.create(_data());

    expectFailure<Voluntario>(result, SessionExpired);
  });

  test('maps other non-2xx to NetworkFailure.serverError', () async {
    when(() => api.create(any()))
        .thenThrow(ApiException(statusCode: 500, message: 'boom'));

    final result = await repo.create(_data());

    expectFailure<Voluntario>(result, ServerError);
  });
}
