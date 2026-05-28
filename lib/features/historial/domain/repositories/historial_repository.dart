// Contrato del repositorio del historial. Mapea exactamente los dos
// endpoints de `custodiam-api`:
//
//   - GET /voluntarios/me/historial (paginado con X-Total-Count)
//   - GET /voluntarios/me/resumen

import '../../../../infrastructure/error/result.dart';
import '../entities/historial_page.dart';
import '../entities/resumen_voluntario.dart';
import '../entities/tipo_evento_voluntario.dart';

abstract class HistorialRepository {
  /// Lista paginada de eventos del voluntario actual, más recientes
  /// primero. Los filtros `tipos`, `since` y `until` reflejan los
  /// query parameters del backend; si alguno es `null` no se aplica.
  Future<Result<HistorialPage>> obtenerHistorial({
    int skip = 0,
    int limit = 50,
    List<TipoEventoVoluntario>? tipos,
    DateTime? since,
    DateTime? until,
  });

  /// Resumen agregado: horas + servicios cerrados + último servicio.
  Future<Result<ResumenVoluntario>> obtenerResumen();
}
