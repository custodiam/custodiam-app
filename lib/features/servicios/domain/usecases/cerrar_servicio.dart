// Callable use case for US-03-10.

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class CerrarServicio {
  final ServiciosRepository _repository;

  const CerrarServicio(this._repository);

  Future<Result<Servicio>> call(String id, {String? observaciones}) {
    return _repository.cerrar(id, observaciones: observaciones);
  }
}
