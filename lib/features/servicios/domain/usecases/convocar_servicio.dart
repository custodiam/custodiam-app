// Callable use case for US-03-04 (convocar disponibles, sin lista) y
// US-03-05/06 (convocar voluntarios concretos). El backend trata la
// lista vacía como "convocar a todos los activos".

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class ConvocarServicio {
  final ServiciosRepository _repository;

  const ConvocarServicio(this._repository);

  Future<Result<Servicio>> call(
    String id, {
    List<String>? voluntarioIds,
  }) {
    return _repository.convocar(id, voluntarioIds: voluntarioIds);
  }
}
