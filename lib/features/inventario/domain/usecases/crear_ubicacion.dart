import '../../../../infrastructure/error/result.dart';
import '../entities/ubicacion.dart';
import '../repositories/ubicaciones_repository.dart';

class CrearUbicacion {
  final UbicacionesRepository _repository;

  const CrearUbicacion(this._repository);

  Future<Result<Ubicacion>> call({
    required String nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) {
    return _repository.crear(
      nombre: nombre,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
    );
  }
}
