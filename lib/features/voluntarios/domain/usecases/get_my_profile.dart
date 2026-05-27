// Callable use case for US-02-05 (CU-13).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class GetMyProfile {
  final VoluntariosRepository _repository;

  const GetMyProfile(this._repository);

  Future<Result<Voluntario>> call() => _repository.getMyProfile();
}
