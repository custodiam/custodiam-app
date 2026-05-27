import '../../../../infrastructure/error/result.dart';
import '../entities/material_item.dart';
import '../repositories/inventario_repository.dart';

class GetMaterial {
  final InventarioRepository _repository;
  const GetMaterial(this._repository);
  Future<Result<MaterialItem>> call(String id) => _repository.getMaterial(id);
}
