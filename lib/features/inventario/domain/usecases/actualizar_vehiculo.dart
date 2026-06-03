import '../../../../infrastructure/error/result.dart';
import '../entities/vehiculo_item.dart';
import '../repositories/inventario_repository.dart';

class ActualizarVehiculo {
  final InventarioRepository _repository;

  const ActualizarVehiculo(this._repository);

  /// [campos] solo lleva las claves a modificar (cuerpo parcial PATCH).
  Future<Result<VehiculoItem>> call(
    String id,
    Map<String, dynamic> campos,
  ) =>
      _repository.updateVehiculo(id, campos);
}
