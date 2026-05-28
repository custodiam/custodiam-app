import '../../../../infrastructure/error/result.dart';
import '../entities/historial_page.dart';
import '../entities/tipo_evento_voluntario.dart';
import '../repositories/historial_repository.dart';

class ObtenerMiHistorial {
  final HistorialRepository _repo;

  const ObtenerMiHistorial(this._repo);

  Future<Result<HistorialPage>> call({
    int skip = 0,
    int limit = 50,
    List<TipoEventoVoluntario>? tipos,
    DateTime? since,
    DateTime? until,
  }) {
    return _repo.obtenerHistorial(
      skip: skip,
      limit: limit,
      tipos: tipos,
      since: since,
      until: until,
    );
  }
}
