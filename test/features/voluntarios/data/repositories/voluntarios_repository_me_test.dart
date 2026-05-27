// Coverage for the /me-related methods of VoluntariosRepositoryImpl
// (US-02-05 / US-02-03). The listing path lives in
// voluntarios_repository_impl_test.dart.

import 'package:custodiam/features/voluntarios/data/datasources/voluntarios_api.dart';
import 'package:custodiam/features/voluntarios/data/repositories/voluntarios_repository_impl.dart';
import 'package:custodiam/features/voluntarios/domain/entities/mi_perfil_update.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/result_helpers.dart';

class _MockApi extends Mock implements VoluntariosApi {}

Map<String, dynamic> _profileJson({String email = 'ana@example.com'}) => {
      'id': 'id-1',
      'nombre': 'Ana Pérez',
      'telefono': '600000000',
      'municipio': 'Zuera',
      'fecha_nacimiento': '1990-05-10',
      'estado': 'activo',
      'fecha_alta': '2024-01-15',
      'conductor_habilitado': false,
      'email': email,
    };

void main() {
  late _MockApi api;
  late VoluntariosRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    repo = VoluntariosRepositoryImpl(api);
  });

  group('getMyProfile', () {
    test('returns Success<Voluntario> on 200', () async {
      when(() => api.getMe()).thenAnswer((_) async => _profileJson());

      final result = await repo.getMyProfile();

      expect(result, isA<Success<Voluntario>>());
      switch (result) {
        case Success(:final value):
          expect(value.nombre, 'Ana Pérez');
          expect(value.email, 'ana@example.com');
        case Fail():
          fail('Expected Success');
      }
    });

    test('maps 404 to VoluntariosFailure.notFound', () async {
      when(() => api.getMe())
          .thenThrow(ApiException(statusCode: 404, message: 'no row'));

      final result = await repo.getMyProfile();

      expectFailure<Voluntario>(result, VoluntarioNotFound);
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.getMe())
          .thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.getMyProfile();

      expectFailure<Voluntario>(result, SessionExpired);
    });

    test('maps 5xx to NetworkFailure.serverError', () async {
      when(() => api.getMe())
          .thenThrow(ApiException(statusCode: 503, message: 'boom'));

      final result = await repo.getMyProfile();

      expectFailure<Voluntario>(result, ServerError);
    });
  });

  group('updateMyProfile', () {
    test('sends the patch JSON and returns the updated profile', () async {
      when(() => api.patchMe(any())).thenAnswer(
        (_) async => _profileJson(email: 'new@example.com'),
      );

      final result = await repo.updateMyProfile(
        const MiPerfilUpdate(email: 'new@example.com'),
      );

      verify(() => api.patchMe({'email': 'new@example.com'})).called(1);
      switch (result) {
        case Success(:final value):
          expect(value.email, 'new@example.com');
        case Fail():
          fail('Expected Success');
      }
    });

    test('omits unchanged fields from the wire payload', () async {
      when(() => api.patchMe(any()))
          .thenAnswer((_) async => _profileJson());

      await repo.updateMyProfile(
        const MiPerfilUpdate(telefono: '699999999'),
      );

      final captured = verify(() => api.patchMe(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured, {'telefono': '699999999'});
    });

    test('maps 409 to VoluntariosFailure.emailDuplicado', () async {
      when(() => api.patchMe(any()))
          .thenThrow(ApiException(statusCode: 409, message: 'dupe'));

      final result = await repo.updateMyProfile(
        const MiPerfilUpdate(email: 'taken@example.com'),
      );

      expectFailure<Voluntario>(result, EmailDuplicado);
    });

    test('maps 401 to AuthFailure.sessionExpired', () async {
      when(() => api.patchMe(any()))
          .thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result =
          await repo.updateMyProfile(const MiPerfilUpdate(telefono: 't'));

      expectFailure<Voluntario>(result, SessionExpired);
    });
  });
}
