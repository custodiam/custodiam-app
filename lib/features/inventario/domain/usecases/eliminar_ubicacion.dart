import '../../../../infrastructure/error/result.dart';
import '../repositories/ubicaciones_repository.dart';

class EliminarUbicacion {
  final UbicacionesRepository _repository;

  const EliminarUbicacion(this._repository);

  Future<Result<void>> call(String id) => _repository.eliminar(id);
}
