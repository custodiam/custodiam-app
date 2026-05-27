import '../../../../infrastructure/error/result.dart';
import '../entities/material_create.dart';
import '../entities/material_item.dart';
import '../repositories/inventario_repository.dart';

class CreateMaterial {
  final InventarioRepository _repository;
  const CreateMaterial(this._repository);
  Future<Result<MaterialItem>> call(MaterialCreate data) =>
      _repository.createMaterial(data);
}
