// Callable use case para el borrado de un servicio (A7).

import '../../../../infrastructure/error/result.dart';
import '../repositories/servicios_repository.dart';

class EliminarServicio {
  final ServiciosRepository _repository;

  const EliminarServicio(this._repository);

  Future<Result<void>> call(String id) => _repository.delete(id);
}
