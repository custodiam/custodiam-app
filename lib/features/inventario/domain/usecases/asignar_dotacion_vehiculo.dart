// Use case: asignar material como dotación fija de un vehículo (PR3).

import '../../../../infrastructure/error/result.dart';
import '../entities/dotacion_vehiculo.dart';
import '../repositories/inventario_repository.dart';

class AsignarDotacionVehiculo {
  final InventarioRepository _repo;

  const AsignarDotacionVehiculo(this._repo);

  Future<Result<DotacionVehiculo>> call(
    String vehiculoId, {
    required String materialId,
    int cantidad = 1,
  }) {
    return _repo.asignarDotacionVehiculo(
      vehiculoId,
      materialId: materialId,
      cantidad: cantidad,
    );
  }
}
