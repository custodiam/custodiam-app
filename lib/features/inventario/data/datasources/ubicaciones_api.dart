// Wrapper fino sobre ApiClient con los endpoints del catálogo de ubicaciones
// (E10). Análogo a InventarioApi.

import '../../../../infrastructure/network/api_client.dart';

class UbicacionesApi {
  final ApiClient _client;

  const UbicacionesApi(this._client);

  Future<ApiResponse<List<dynamic>>> listar({
    int skip = 0,
    int limit = 50,
    String? query,
  }) {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    return _client.getList('/ubicaciones', queryParams: params);
  }

  Future<Map<String, dynamic>> obtener(String id) {
    return _client.get('/ubicaciones/$id');
  }

  Future<Map<String, dynamic>> crear(Map<String, dynamic> body) {
    return _client.post('/ubicaciones', body);
  }

  Future<Map<String, dynamic>> actualizar(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.patch('/ubicaciones/$id', body);
  }

  Future<void> eliminar(String id) async {
    try {
      await _client.delete('/ubicaciones/$id');
    } on FormatException {
      // El backend responde 204 No Content (cuerpo vacío); ApiClient.delete
      // pasa por jsonDecode y lanza FormatException sobre el vacío aunque la
      // operación haya ido bien. Un fallo real (no-2xx) llega como
      // ApiException y sí se propaga (p. ej. 409 si está en uso).
      return;
    }
  }
}
