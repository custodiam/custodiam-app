// Callable use case for the servicio ficha (US-03-07 paso 4).

import '../../../../infrastructure/error/result.dart';
import '../entities/servicio.dart';
import '../repositories/servicios_repository.dart';

class GetServicioById {
  final ServiciosRepository _repository;

  const GetServicioById(this._repository);

  Future<Result<Servicio>> call(String id) => _repository.getById(id);
}
