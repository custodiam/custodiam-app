import '../../../../infrastructure/error/result.dart';
import '../repositories/inventario_repository.dart';

class EliminarMaterial {
  final InventarioRepository _repository;

  const EliminarMaterial(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteMaterial(id);
}
