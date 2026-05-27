import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario_rol_asignacion.dart';
import '../repositories/voluntarios_repository.dart';

class ListRolesVoluntario {
  final VoluntariosRepository _repository;

  const ListRolesVoluntario(this._repository);

  Future<Result<List<VoluntarioRolAsignacion>>> call(String voluntarioId) =>
      _repository.listRolesAsignados(voluntarioId);
}
