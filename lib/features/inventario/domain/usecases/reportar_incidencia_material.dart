import '../../../../infrastructure/error/result.dart';
import '../entities/estado_inventario.dart';
import '../entities/material_item.dart';
import '../repositories/inventario_repository.dart';

class ReportarIncidenciaMaterial {
  final InventarioRepository _repository;
  const ReportarIncidenciaMaterial(this._repository);

  Future<Result<MaterialItem>> call(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) {
    return _repository.reportarIncidenciaMaterial(
      id,
      nuevoEstado: nuevoEstado,
      descripcion: descripcion,
    );
  }
}
