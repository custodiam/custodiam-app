// Callable use case para la edición de un servicio (A5).

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class ActualizarServicio {
  final ServiciosRepository _repository;

  const ActualizarServicio(this._repository);

  /// [campos] solo lleva las claves a modificar (cuerpo parcial PATCH).
  Future<Result<Servicio>> call(String id, Map<String, dynamic> campos) =>
      _repository.update(id, campos);
}
