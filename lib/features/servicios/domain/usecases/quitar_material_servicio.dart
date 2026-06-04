// Use case: quitar un material de un servicio (R1, CU-22 — inversa de asignar).

import '../../../../infrastructure/error/result.dart';
import '../repositories/servicios_repository.dart';

class QuitarMaterialServicio {
  final ServiciosRepository _repository;

  const QuitarMaterialServicio(this._repository);

  Future<Result<void>> call(String servicioId, {required String asignacionId}) {
    return _repository.quitarMaterial(servicioId, asignacionId: asignacionId);
  }
}
