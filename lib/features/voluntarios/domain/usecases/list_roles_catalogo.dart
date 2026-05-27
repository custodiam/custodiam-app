import '../../../../infrastructure/error/result.dart';
import '../entities/rol.dart';
import '../repositories/roles_repository.dart';

class ListRolesCatalogo {
  final RolesRepository _repository;

  const ListRolesCatalogo(this._repository);

  Future<Result<List<Rol>>> call() => _repository.listCatalogo();
}
