// Use case: listar los recursos (material + vehículos) asignados a un
// servicio (R1, lectura).

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio_inventario.dart';
import '../repositories/servicios_repository.dart';

class GetInventarioServicio {
  final ServiciosRepository _repository;

  const GetInventarioServicio(this._repository);

  Future<Result<ServicioInventario>> call(String servicioId) {
    return _repository.getInventario(servicioId);
  }
}
