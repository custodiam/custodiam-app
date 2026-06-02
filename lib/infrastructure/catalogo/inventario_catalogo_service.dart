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

  Future<List<CatalogoRecurso>> buscarMaterial(String query, int page) {
    return _buscar('/inventario/material', query, page, CatalogoRecurso.material);
  }

  Future<List<CatalogoRecurso>> buscarVehiculos(String query, int page) {
    return _buscar(
      '/inventario/vehiculos',
      query,
      page,
      CatalogoRecurso.vehiculo,
    );
  }

  Future<List<CatalogoRecurso>> _buscar(
    String path,
    String query,
    int page,
    CatalogoRecurso Function(Map<String, dynamic>) fromJson,
  ) async {
    final params = <String, String>{
      'skip': (page * pageSize).toString(),
      'limit': pageSize.toString(),
    };
    final q = query.trim();
    if (q.isNotEmpty) params['q'] = q;
    final res = await _client.getList(path, queryParams: params);
    return res.body
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
