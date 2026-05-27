// Callable use case for US-03-08 (apuntarse a un servicio).

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class InscribirseServicio {
  final ServiciosRepository _repository;

  const InscribirseServicio(this._repository);

  Future<Result<Servicio>> call(String id) => _repository.inscribirse(id);
}
