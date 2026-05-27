import '../../../../infrastructure/error/result.dart';
import '../entities/estado_inventario.dart';
import '../entities/vehiculo_item.dart';
import '../repositories/inventario_repository.dart';

class ReportarIncidenciaVehiculo {
  final InventarioRepository _repository;
  const ReportarIncidenciaVehiculo(this._repository);

  Future<Result<VehiculoItem>> call(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) {
    return _repository.reportarIncidenciaVehiculo(
      id,
      nuevoEstado: nuevoEstado,
      descripcion: descripcion,
    );
  }
}
