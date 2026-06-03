import '../../../../infrastructure/error/result.dart';
import '../repositories/inventario_repository.dart';

class EliminarVehiculo {
  final InventarioRepository _repository;

  const EliminarVehiculo(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteVehiculo(id);
}
