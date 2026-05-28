import '../../../../infrastructure/error/result.dart';
import '../entities/dia_disponibilidad.dart';
import '../repositories/disponibilidad_repository.dart';

class MarcarMiDia {
  final DisponibilidadRepository _repo;

  const MarcarMiDia(this._repo);

  Future<Result<DiaDisponibilidad>> call({
    required DateTime fecha,
    required bool disponible,
  }) {
    return _repo.marcarDia(fecha: fecha, disponible: disponible);
  }
}
