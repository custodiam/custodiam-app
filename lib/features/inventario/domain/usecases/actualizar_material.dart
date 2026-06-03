import '../../../../infrastructure/error/result.dart';
import '../entities/material_item.dart';
import '../repositories/inventario_repository.dart';

class ActualizarMaterial {
  final InventarioRepository _repository;

  const ActualizarMaterial(this._repository);

  /// [campos] solo lleva las claves a modificar (cuerpo parcial PATCH).
  Future<Result<MaterialItem>> call(
    String id,
    Map<String, dynamic> campos,
  ) =>
      _repository.updateMaterial(id, campos);
}
