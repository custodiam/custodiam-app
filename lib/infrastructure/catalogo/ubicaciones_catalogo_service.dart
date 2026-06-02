// Servicio de lectura y alta del catálogo de ubicaciones (E10 / PR2),
// análogo a InventarioCatalogoService. Alimenta el picker de selección de
// ubicación en las altas de material y vehículo y permite crear una
// ubicación nueva sobre la marcha (footer "crear" del picker).
//
// Vive en infrastructure (guía 26 §1 / §6): es un catálogo transversal con
// tipo neutro `CatalogoRecurso`, así que ninguna feature acopla con otra.
// Propaga ApiException en error (no envuelve en Result): sus consumidores
// son `AppCatalogSearchPicker.onLoadPage` y un diálogo que captura la
// excepción para mostrar el mensaje.

import '../network/api_client.dart';
import 'catalogo_recurso.dart';

class UbicacionesCatalogoService {
  final ApiClient _client;

  const UbicacionesCatalogoService(this._client);

  /// Tamaño de página alineado con el `limit` por defecto del backend.
  static const int pageSize = 50;

  /// Lista paginada filtrada por [query] (alimenta el picker). Una página
  /// vacía marca el fin de la paginación.
  Future<List<CatalogoRecurso>> buscarUbicaciones(String query, int page) async {
    final params = <String, String>{
      'skip': (page * pageSize).toString(),
      'limit': pageSize.toString(),
    };
    final q = query.trim();
    if (q.isNotEmpty) params['q'] = q;
    final res = await _client.getList('/ubicaciones', queryParams: params);
    return res.body
        .cast<Map<String, dynamic>>()
        .map(CatalogoRecurso.ubicacion)
        .toList(growable: false);
  }

  /// Crea una ubicación y devuelve su representación neutra para dejarla
  /// seleccionada sin recargar el catálogo. Propaga [ApiException] (409 si el
  /// nombre ya existe, 403 si el rol no tiene `ubicaciones.crear`).
  Future<CatalogoRecurso> crear({
    required String nombre,
    String? descripcion,
  }) async {
    final body = <String, dynamic>{'nombre': nombre};
    final desc = descripcion?.trim();
    if (desc != null && desc.isNotEmpty) body['descripcion'] = desc;
    final json = await _client.post('/ubicaciones', body);
    return CatalogoRecurso.ubicacion(json);
  }
}
