// Callable use case for US-03-03.

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class PublicarServicio {
  final ServiciosRepository _repository;

  const PublicarServicio(this._repository);

  Future<Result<Servicio>> call(String id) => _repository.publicar(id);
}
