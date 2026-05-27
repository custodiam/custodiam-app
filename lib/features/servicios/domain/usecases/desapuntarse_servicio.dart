// Callable use case for US-03-09 (darse de baja).

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class DesapuntarseServicio {
  final ServiciosRepository _repository;

  const DesapuntarseServicio(this._repository);

  Future<Result<Servicio>> call(String id) => _repository.desapuntarse(id);
}
