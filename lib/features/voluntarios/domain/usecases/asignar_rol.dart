import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario_rol_asignacion.dart';
import '../repositories/voluntarios_repository.dart';

class AsignarRol {
  final VoluntariosRepository _repository;

  const AsignarRol(this._repository);

  Future<Result<VoluntarioRolAsignacion>> call(
    String voluntarioId,
    String rolId,
  ) =>
      _repository.asignarRol(voluntarioId, rolId);
}
