import '../../../../infrastructure/error/result.dart';
import '../entities/mes_disponibilidad.dart';
import '../repositories/disponibilidad_repository.dart';

class ObtenerMiMes {
  final DisponibilidadRepository _repo;

  const ObtenerMiMes(this._repo);

  Future<Result<MesDisponibilidad>> call({
    required int year,
    required int month,
  }) {
    return _repo.obtenerMes(year: year, month: month);
  }
}
