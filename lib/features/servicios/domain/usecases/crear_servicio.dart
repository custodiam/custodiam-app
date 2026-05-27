// Callable use case for US-03-01 / US-03-02.

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../entities/servicio_create.dart';
import '../repositories/servicios_repository.dart';

class CrearServicio {
  final ServiciosRepository _repository;

  const CrearServicio(this._repository);

  Future<Result<Servicio>> call(ServicioCreate data) =>
      _repository.create(data);
}
