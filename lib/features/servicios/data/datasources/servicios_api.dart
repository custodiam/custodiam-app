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
  ///
  /// `desde`/`hasta` se envían como fechas de calendario `YYYY-MM-DD`
  /// (el backend las interpreta como rango inclusivo sobre
  /// `fecha_inicio`); solo se usa la parte de fecha, la hora se ignora.
  Future<ApiResponse<List<dynamic>>> list({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoServicio? estado,
    TipoServicio? tipo,
    DateTime? desde,
    DateTime? hasta,
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
    if (desde != null) {
      params['desde'] = _wireDate(desde);
    }
    if (hasta != null) {
      params['hasta'] = _wireDate(hasta);
    }
    return _client.getList('/servicios', queryParams: params);
  }

  /// Serializa solo la parte de calendario (`YYYY-MM-DD`), sin hora ni
  /// zona horaria, para casar con el query param `date` del backend.
  static String _wireDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<Map<String, dynamic>> getById(String id) {
    return _client.get('/servicios/$id');
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) {
    return _client.post('/servicios', body);
  }

  /// PATCH /servicios/{id} — actualización parcial (A5). El backend acepta
  /// un cuerpo parcial (sin `estado`, que solo cambia por las transiciones).
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> body) {
    return _client.patch('/servicios/$id', body);
  }

  /// DELETE /servicios/{id} — borrado (A7). El backend responde 204 No
  /// Content (cuerpo vacío). ApiClient.delete pasa por jsonDecode, que lanza
  /// FormatException sobre el cuerpo vacío aunque la operación haya tenido
  /// éxito; lo absorbemos aquí. Un fallo real (no-2xx, p. ej. el 409 cuando el
  /// servicio tiene actividad) llega como ApiException y sí se propaga.
  Future<void> delete(String id) async {
    try {
      await _client.delete('/servicios/$id');
    } on FormatException {
      return;
    }
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

  Future<Map<String, dynamic>> cerrar(String id, {String? observaciones}) {
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

  /// GET /servicios/{id}/inventario — recursos asignados (R1). Cuerpo objeto
  /// {material: [...], vehiculos: [...]}.
  Future<Map<String, dynamic>> getInventario(String id) {
    return _client.get('/servicios/$id/inventario');
  }

  Future<Map<String, dynamic>> asignarMaterial(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.post('/servicios/$id/inventario/material', body);
  }

  Future<Map<String, dynamic>> asignarVehiculo(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.post('/servicios/$id/inventario/vehiculo', body);
  }

  /// DELETE /servicios/{id}/inventario/material/{asignacionId} (204, cuerpo
  /// vacío → absorbemos la FormatException igual que en [delete]). Un fallo
  /// real (p. ej. 404 si la asignación no pertenece al servicio) llega como
  /// ApiException y se propaga.
  Future<void> quitarMaterial(String id, String asignacionId) async {
    try {
      await _client.delete('/servicios/$id/inventario/material/$asignacionId');
    } on FormatException {
      return;
    }
  }

  /// DELETE /servicios/{id}/inventario/vehiculo/{asignacionId} (204).
  Future<void> quitarVehiculo(String id, String asignacionId) async {
    try {
      await _client.delete('/servicios/$id/inventario/vehiculo/$asignacionId');
    } on FormatException {
      return;
    }
  }
}
