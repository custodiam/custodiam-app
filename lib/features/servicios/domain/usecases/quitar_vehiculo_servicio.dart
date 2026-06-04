// Use case: quitar un vehículo de un servicio (R1, CU-22 — inversa de asignar).

import '../../../../infrastructure/error/result.dart';
import '../repositories/servicios_repository.dart';

class QuitarVehiculoServicio {
  final ServiciosRepository _repository;

  const QuitarVehiculoServicio(this._repository);

  Future<Result<void>> call(String servicioId, {required String asignacionId}) {
    return _repository.quitarVehiculo(servicioId, asignacionId: asignacionId);
  }
}
