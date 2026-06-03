// Thin wrapper around ApiClient with the inventario endpoints.

import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/tipo_material.dart';
import '../../domain/entities/tipo_vehiculo.dart';

class InventarioApi {
  final ApiClient _client;

  const InventarioApi(this._client);

  // — Material —

  Future<ApiResponse<List<dynamic>>> listMaterial({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoMaterial? tipo,
    String? categoria,
  }) {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (estado != null) params['estado'] = estado.wire;
    if (tipo != null) params['tipo'] = tipo.wire;
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }
    return _client.getList('/inventario/material', queryParams: params);
  }

  Future<Map<String, dynamic>> getMaterial(String id) {
    return _client.get('/inventario/material/$id');
  }

  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> body) {
    return _client.post('/inventario/material', body);
  }

  Future<Map<String, dynamic>> updateMaterial(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.patch('/inventario/material/$id', body);
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _client.delete('/inventario/material/$id');
    } on FormatException {
      // El backend devuelve 204 No Content (cuerpo vacío). ApiClient.delete
      // pasa por jsonDecode, que lanza FormatException sobre el cuerpo vacío
      // aunque la operación haya tenido éxito; lo absorbemos aquí. Un fallo
      // real (no-2xx) llega como ApiException y sí se propaga.
      return;
    }
  }

  Future<Map<String, dynamic>> reportarIncidenciaMaterial(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.post('/inventario/material/$id/incidencia', body);
  }

  Future<Map<String, dynamic>> asignarMaterialAVoluntario(
    String materialId,
    Map<String, dynamic> body,
  ) {
    return _client.post('/inventario/material/$materialId/asignar', body);
  }

  Future<Map<String, dynamic>> devolverMaterial(
    String materialId,
    Map<String, dynamic> body,
  ) {
    return _client.post('/inventario/material/$materialId/devolver', body);
  }

  // — Vehículo —

  Future<ApiResponse<List<dynamic>>> listVehiculos({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoVehiculo? tipo,
  }) {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (estado != null) params['estado'] = estado.wire;
    if (tipo != null) params['tipo'] = tipo.wire;
    return _client.getList('/inventario/vehiculos', queryParams: params);
  }

  Future<Map<String, dynamic>> getVehiculo(String id) {
    return _client.get('/inventario/vehiculos/$id');
  }

  Future<Map<String, dynamic>> createVehiculo(Map<String, dynamic> body) {
    return _client.post('/inventario/vehiculos', body);
  }

  Future<Map<String, dynamic>> updateVehiculo(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.patch('/inventario/vehiculos/$id', body);
  }

  Future<void> deleteVehiculo(String id) async {
    try {
      await _client.delete('/inventario/vehiculos/$id');
    } on FormatException {
      // 204 No Content: mismo motivo que deleteMaterial.
      return;
    }
  }

  Future<Map<String, dynamic>> reportarIncidenciaVehiculo(
    String id,
    Map<String, dynamic> body,
  ) {
    return _client.post('/inventario/vehiculos/$id/incidencia', body);
  }

  // — Dotación fija de vehículo (PR3) —

  Future<List<dynamic>> listarDotacionVehiculo(String vehiculoId) async {
    final res =
        await _client.getList('/inventario/vehiculos/$vehiculoId/dotacion');
    return res.body;
  }

  Future<Map<String, dynamic>> asignarDotacionVehiculo(
    String vehiculoId,
    Map<String, dynamic> body,
  ) {
    return _client.post('/inventario/vehiculos/$vehiculoId/dotacion', body);
  }

  Future<void> liberarDotacionVehiculo(
    String vehiculoId,
    String asignacionId,
  ) async {
    try {
      await _client.delete(
        '/inventario/vehiculos/$vehiculoId/dotacion/$asignacionId',
      );
    } on FormatException {
      // El backend devuelve 204 No Content (cuerpo vacío). ApiClient.delete
      // pasa por jsonDecode, que lanza FormatException sobre el cuerpo vacío
      // aunque la operación haya tenido éxito; lo absorbemos aquí. Un fallo
      // real (no-2xx) llega como ApiException y sí se propaga.
      return;
    }
  }
}
