import '../../../../infrastructure/error/result.dart';
import '../entities/resumen_voluntario.dart';
import '../repositories/historial_repository.dart';

class ObtenerMiResumen {
  final HistorialRepository _repo;

  const ObtenerMiResumen(this._repo);

  Future<Result<ResumenVoluntario>> call() => _repo.obtenerResumen();
}
