// Thin wrapper sobre ApiClient con los endpoints del historial
// (EN-02-04 / US-02-06). Mantiene el formato wire; el repository
// envuelve en Result<T>.

import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/tipo_evento_voluntario.dart';

class HistorialApi {
  final ApiClient _client;

  const HistorialApi(this._client);

  /// GET /voluntarios/me/historial?skip=&limit=&tipo=&since=&until=
  /// Devuelve el body lista + cabeceras (X-Total-Count en particular).
  Future<ApiResponse<List<dynamic>>> obtenerHistorial({
    int skip = 0,
    int limit = 50,
    List<TipoEventoVoluntario>? tipos,
    DateTime? since,
    DateTime? until,
  }) {
    final query = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (since != null) query['since'] = since.toIso8601String();
    if (until != null) query['until'] = until.toIso8601String();

    // Los filtros por tipo son repetibles en la URL: `?tipo=A&tipo=B`.
    // `Uri.replace(queryParameters: ...)` no soporta valores repetidos
    // por la misma clave, así que los serializamos a mano y los
    // concatenamos al path.
    final repeticionTipos = (tipos == null || tipos.isEmpty)
        ? ''
        : tipos.map((t) => '&tipo=${Uri.encodeQueryComponent(t.wire)}').join();

    final base = Uri(path: '/voluntarios/me/historial', queryParameters: query)
        .toString();
    return _client.getList('$base$repeticionTipos');
  }

  /// GET /voluntarios/me/resumen.
  Future<Map<String, dynamic>> obtenerResumen() {
    return _client.get('/voluntarios/me/resumen');
  }
}
