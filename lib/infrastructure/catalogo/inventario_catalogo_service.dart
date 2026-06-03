// Servicio de lectura del catálogo de inventario, compartido entre features
// (guía 26 §1 / §6: lo que dos features necesitan sube a infrastructure).
// `servicios` lo usa para alimentar el picker al asignar recursos a un
// servicio (R1); `inventario` puede reutilizarlo. Devuelve el tipo neutro
// `CatalogoRecurso`, así que ninguna feature acopla con otra.
//
// Como su consumidor directo es AppCatalogSearchPicker.onLoadPage
// (Future<List<T>> que captura excepciones), este servicio propaga
// ApiException en error en vez de envolver en Result: no cruza la frontera
// de dominio de ninguna feature.

import '../network/api_client.dart';
import 'catalogo_recurso.dart';

class InventarioCatalogoService {
  final ApiClient _client;

  const InventarioCatalogoService(this._client);

  /// Tamaño de página alineado con el `limit` por defecto del backend.
  static const int pageSize = 50;

  /// Lista material del catálogo. Si se pasa [servicioId], el backend filtra
  /// a lo disponible para el intervalo de ese servicio (query
  /// `disponible_para_servicio`), de modo que el picker de asignación solo
  /// ofrezca recursos asignables.
  Future<List<CatalogoRecurso>> buscarMaterial(
    String query,
    int page, {
    String? servicioId,
  }) {
    return _buscar(
      '/inventario/material',
      query,
      page,
      CatalogoRecurso.material,
      servicioId: servicioId,
    );
  }

  /// Lista vehículos del catálogo. Ver [buscarMaterial] para el filtro
  /// [servicioId] / `disponible_para_servicio`.
  Future<List<CatalogoRecurso>> buscarVehiculos(
    String query,
    int page, {
    String? servicioId,
  }) {
    return _buscar(
      '/inventario/vehiculos',
      query,
      page,
      CatalogoRecurso.vehiculo,
      servicioId: servicioId,
    );
  }

  Future<List<CatalogoRecurso>> _buscar(
    String path,
    String query,
    int page,
    CatalogoRecurso Function(Map<String, dynamic>) fromJson, {
    String? servicioId,
  }) async {
    final params = <String, String>{
      'skip': (page * pageSize).toString(),
      'limit': pageSize.toString(),
    };
    final q = query.trim();
    if (q.isNotEmpty) params['q'] = q;
    if (servicioId != null) params['disponible_para_servicio'] = servicioId;
    final res = await _client.getList(path, queryParams: params);
    return res.body
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
