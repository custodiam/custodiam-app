// Callable use case for US-02-03 (CU-11 A).

import '../../../../infrastructure/error/result.dart';
import '../entities/mi_perfil_update.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class UpdateMyProfile {
  final VoluntariosRepository _repository;

  const UpdateMyProfile(this._repository);

  Future<Result<Voluntario>> call(MiPerfilUpdate patch) =>
      _repository.updateMyProfile(patch);
}
