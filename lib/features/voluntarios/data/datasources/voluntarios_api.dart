// Thin wrapper around ApiClient with the voluntarios endpoints.
// The data source stays close to the wire format (query params,
// status codes) and lets the repository handle Result<T> shaping.

import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/estado_voluntario.dart';

class VoluntariosApi {
  final ApiClient _client;

  const VoluntariosApi(this._client);

  /// GET /voluntarios — paginated list with optional filters.
  /// Returns the raw envelope so the repository can read
  /// `X-Total-Count` for pagination.
  Future<ApiResponse<List<dynamic>>> list({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoVoluntario? estado,
    String? rolId,
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
    if (rolId != null) {
      params['rol_id'] = rolId;
    }
    return _client.getList('/voluntarios', queryParams: params);
  }

  /// GET /voluntarios/me — full profile of the authenticated user.
  Future<Map<String, dynamic>> getMe() {
    return _client.get('/voluntarios/me');
  }

  /// PATCH /voluntarios/me — update self contact data.
  Future<Map<String, dynamic>> patchMe(Map<String, dynamic> body) {
    return _client.patch('/voluntarios/me', body);
  }
}
