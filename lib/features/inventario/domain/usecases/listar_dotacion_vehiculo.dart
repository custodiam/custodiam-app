// Use case: listar la dotación fija de un vehículo (PR3).

import '../../../../infrastructure/error/result.dart';
import '../entities/dotacion_vehiculo.dart';
import '../repositories/inventario_repository.dart';

class ListarDotacionVehiculo {
  final InventarioRepository _repo;

  const ListarDotacionVehiculo(this._repo);

  Future<Result<List<DotacionVehiculo>>> call(String vehiculoId) {
    return _repo.listarDotacionVehiculo(vehiculoId);
  }
}
