// Callable use case for "ver voluntarios del servicio" (US-04-04
// reuses this; in E03 lo usa la ficha admin).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario_inscrito.dart';
import '../repositories/servicios_repository.dart';

class ListVoluntariosServicio {
  final ServiciosRepository _repository;

  const ListVoluntariosServicio(this._repository);

  Future<Result<List<VoluntarioInscrito>>> call(String id) {
    return _repository.listVoluntarios(id);
  }
}
