// Use case: liberar una línea de dotación fija de un vehículo (PR3).

import '../../../../infrastructure/error/result.dart';
import '../repositories/inventario_repository.dart';

class LiberarDotacionVehiculo {
  final InventarioRepository _repo;

  const LiberarDotacionVehiculo(this._repo);

  Future<Result<void>> call(
    String vehiculoId, {
    required String asignacionId,
  }) {
    return _repo.liberarDotacionVehiculo(
      vehiculoId,
      asignacionId: asignacionId,
    );
  }
}
