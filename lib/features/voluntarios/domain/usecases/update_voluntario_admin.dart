import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../entities/voluntario_update_admin.dart';
import '../repositories/voluntarios_repository.dart';

class UpdateVoluntarioAdmin {
  final VoluntariosRepository _repository;

  const UpdateVoluntarioAdmin(this._repository);

  Future<Result<Voluntario>> call(String id, VoluntarioUpdateAdmin patch) =>
      _repository.updateAdmin(id, patch);
}
