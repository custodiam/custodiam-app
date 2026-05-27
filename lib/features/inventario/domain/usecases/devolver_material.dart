import '../../../../infrastructure/error/result.dart';
import '../entities/asignacion_material.dart';
import '../repositories/inventario_repository.dart';

class DevolverMaterial {
  final InventarioRepository _repository;
  const DevolverMaterial(this._repository);

  Future<Result<AsignacionMaterial>> call(
    String materialId, {
    required String voluntarioId,
    String? observaciones,
  }) {
    return _repository.devolverMaterial(
      materialId,
      voluntarioId: voluntarioId,
      observaciones: observaciones,
    );
  }
}
