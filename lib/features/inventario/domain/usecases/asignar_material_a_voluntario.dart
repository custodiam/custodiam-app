import '../../../../infrastructure/error/result.dart';
import '../entities/asignacion_material.dart';
import '../entities/tipo_asignacion.dart';
import '../repositories/inventario_repository.dart';

class AsignarMaterialAVoluntario {
  final InventarioRepository _repository;
  const AsignarMaterialAVoluntario(this._repository);

  Future<Result<AsignacionMaterial>> call(
    String materialId, {
    required String voluntarioId,
    required TipoAsignacion tipo,
    int cantidad = 1,
  }) {
    return _repository.asignarMaterialAVoluntario(
      materialId,
      voluntarioId: voluntarioId,
      tipo: tipo,
      cantidad: cantidad,
    );
  }
}
