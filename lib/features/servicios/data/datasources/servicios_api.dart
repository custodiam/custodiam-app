// Thin wrapper around ApiClient with the servicios endpoints. The
// data source stays close to the wire format (query params, status
// codes); the repository handles Result<T> shaping.

import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/tipo_servicio.dart';

class ServiciosApi {
  final ApiClient _client;

  const ServiciosApi(this._client);

  /// GET /servicios — paginated list. Returns the raw envelope so the
  /// repository can read `X-Total-Count`.
  Future<ApiResponse<List<dynamic>>> list({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoServicio? estado,
    TipoServicio? tipo,
  }) {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }
    if (estado != null) {
      params['estado'] = estado.wire;
    }
    if (tipo != null) {
      params['tipo'] = tipo.wire;
    }
    return _client.getList('/servicios', queryParams: params);
  }

  Future<Map<String, dynamic>> getById(String id) {
    return _client.get('/servicios/$id');
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) {
    return _client.post('/servicios', body);
  }

  Future<Map<String, dynamic>> publicar(String id) {
    return _client.post('/servicios/$id/publicar', const {});
  }

  /// `voluntarioIds == null` o lista vacía → backend convoca a todos
  /// los activos disponibles (US-03-04). Lista no vacía → US-03-05/06.
  Future<Map<String, dynamic>> convocar(
    String id, {
    List<String>? voluntarioIds,
  }) {
    final body = <String, dynamic>{
      'voluntario_ids': voluntarioIds ?? const <String>[],
    };
    return _client.post('/servicios/$id/convocar', body);
  }

  Future<Map<String, dynamic>> cerrar(
    String id, {
    String? observaciones,
  }) {
    final body = <String, dynamic>{};
    if (observaciones != null && observaciones.isNotEmpty) {
      body['observaciones_cierre'] = observaciones;
    }
    return _client.post('/servicios/$id/cerrar', body);
  }

  Future<Map<String, dynamic>> inscribirse(String id) {
    return _client.post('/servicios/$id/inscribirse', const {});
  }

  Future<Map<String, dynamic>> desapuntarse(String id) {
    return _client.delete('/servicios/$id/inscribirse');
  }

  Future<ApiResponse<List<dynamic>>> listVoluntarios(String id) {
    return _client.getList('/servicios/$id/voluntarios');
  }
}
