import '../../../../infrastructure/error/result.dart';
import '../entities/ubicacion.dart';
import '../repositories/ubicaciones_repository.dart';

class ActualizarUbicacion {
  final UbicacionesRepository _repository;

  const ActualizarUbicacion(this._repository);

  Future<Result<Ubicacion>> call(
    String id, {
    String? nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) {
    return _repository.actualizar(
      id,
      nombre: nombre,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
    );
  }
}
