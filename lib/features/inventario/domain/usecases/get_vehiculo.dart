import '../../../../infrastructure/error/result.dart';
import '../entities/vehiculo_item.dart';
import '../repositories/inventario_repository.dart';

class GetVehiculo {
  final InventarioRepository _repository;
  const GetVehiculo(this._repository);
  Future<Result<VehiculoItem>> call(String id) => _repository.getVehiculo(id);
}
