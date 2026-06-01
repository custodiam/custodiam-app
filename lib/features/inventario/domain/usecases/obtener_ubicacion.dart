import '../../../../infrastructure/error/result.dart';
import '../entities/ubicacion.dart';
import '../repositories/ubicaciones_repository.dart';

class ObtenerUbicacion {
  final UbicacionesRepository _repository;

  const ObtenerUbicacion(this._repository);

  Future<Result<Ubicacion>> call(String id) => _repository.obtener(id);
}
