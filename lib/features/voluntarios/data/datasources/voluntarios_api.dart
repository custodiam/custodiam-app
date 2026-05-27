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

  /// POST /voluntarios — create a new volunteer (admin only).
  Future<Map<String, dynamic>> create(Map<String, dynamic> body) {
    return _client.post('/voluntarios', body);
  }

  /// GET /voluntarios/{id} — full profile of any voluntario.
  Future<Map<String, dynamic>> getById(String id) {
    return _client.get('/voluntarios/$id');
  }

  /// PATCH /voluntarios/{id} — admin update.
  Future<Map<String, dynamic>> patchAdmin(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.patch('/voluntarios/$id', body);
  }

  /// GET /voluntarios/{id}/roles — active role assignments.
  Future<ApiResponse<List<dynamic>>> listRolesAsignados(String voluntarioId) {
    return _client.getList('/voluntarios/$voluntarioId/roles');
  }

  /// POST /voluntarios/{id}/roles — assign a role.
  Future<Map<String, dynamic>> asignarRol(
    String voluntarioId,
    String rolId,
  ) {
    return _client.post('/voluntarios/$voluntarioId/roles', {'rol_id': rolId});
  }

  /// DELETE /voluntarios/{id}/roles/{rol_id} — close an assignment.
  Future<Map<String, dynamic>> quitarRol(
    String voluntarioId,
    String rolId,
  ) {
    return _client.delete('/voluntarios/$voluntarioId/roles/$rolId');
  }

  /// DELETE /voluntarios/{id} — soft delete (estado=baja + Keycloak
  /// disabled). El backend lo trata como idempotente: si ya está de
  /// baja, devuelve 200 con el mismo voluntario. Si el voluntario no
  /// tiene `keycloak_id` (caso seed admin), no se sincroniza con
  /// Keycloak y devuelve 200 igualmente.
  Future<Map<String, dynamic>> darDeBaja(String id) {
    return _client.delete('/voluntarios/$id');
  }

  /// POST /voluntarios/{id}/anonimizar — Art. 17 RGPD. Sobrescribe los
  /// PII del registro con valores anónimos y elimina la cuenta de
  /// Keycloak. Operación irreversible.
  Future<Map<String, dynamic>> anonimizar(String id) {
    return _client.post('/voluntarios/$id/anonimizar', const {});
  }
}
