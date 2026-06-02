// Use case: asignar material a un servicio (R1, CU-22 / US-05-06).

import '../../../../infrastructure/error/result.dart';
import '../repositories/servicios_repository.dart';

class AsignarMaterialServicio {
  final ServiciosRepository _repository;

  const AsignarMaterialServicio(this._repository);

  Future<Result<void>> call(
    String servicioId, {
    required String materialId,
    int cantidad = 1,
  }) {
    return _repository.asignarMaterial(
      servicioId,
      materialId: materialId,
      cantidad: cantidad,
    );
  }
}
