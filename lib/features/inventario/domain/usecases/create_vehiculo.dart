import '../../../../infrastructure/error/result.dart';
import '../entities/vehiculo_create.dart';
import '../entities/vehiculo_item.dart';
import '../repositories/inventario_repository.dart';

class CreateVehiculo {
  final InventarioRepository _repository;
  const CreateVehiculo(this._repository);
  Future<Result<VehiculoItem>> call(VehiculoCreate data) =>
      _repository.createVehiculo(data);
}
