// Thin wrapper around ApiClient for the fichaje endpoints (sub-recurso
// del servicio + self).

import '../../../../infrastructure/network/api_client.dart';

class FichajeApi {
  final ApiClient _client;

  const FichajeApi(this._client);

  Future<Map<String, dynamic>> ficharEntrada(String servicioId) {
    return _client.post('/servicios/$servicioId/fichaje/entrada', const {});
  }

  Future<Map<String, dynamic>> ficharSalida(String servicioId) {
    return _client.post('/servicios/$servicioId/fichaje/salida', const {});
  }

  Future<ApiResponse<List<dynamic>>> listFichadosServicio(
    String servicioId,
  ) {
    return _client.getList('/servicios/$servicioId/fichaje');
  }

  Future<ApiResponse<List<dynamic>>> misFichajes() {
    return _client.getList('/fichajes/me');
  }

  Future<Map<String, dynamic>> misHoras() {
    return _client.get('/fichajes/me/horas');
  }
}
