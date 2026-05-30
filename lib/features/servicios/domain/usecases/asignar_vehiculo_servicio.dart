// Use case: asignar un vehículo a un servicio (R1, CU-22 / US-05-07).

import '../../../../infrastructure/error/result.dart';
import '../repositories/servicios_repository.dart';

class AsignarVehiculoServicio {
  final ServiciosRepository _repository;

  const AsignarVehiculoServicio(this._repository);

  Future<Result<void>> call(
    String servicioId, {
    required String vehiculoId,
  }) {
    return _repository.asignarVehiculo(servicioId, vehiculoId: vehiculoId);
  }
}
