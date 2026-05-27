import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario_rol_asignacion.dart';
import '../repositories/voluntarios_repository.dart';

class QuitarRol {
  final VoluntariosRepository _repository;

  const QuitarRol(this._repository);

  Future<Result<VoluntarioRolAsignacion>> call(
    String voluntarioId,
    String rolId,
  ) =>
      _repository.quitarRol(voluntarioId, rolId);
}
