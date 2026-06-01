// Servicio de lectura del catálogo de voluntarios para pickers de selección,
// análogo a UbicacionesCatalogoService. Alimenta el selector de voluntario de
// los diálogos de asignar/prestar y devolver material (sustituye al campo de
// UUID a mano).
//
// Vive en infrastructure (guía 26 §1): es un catálogo transversal con tipo
// neutro `CatalogoRecurso`, así que `features/inventario` lo consume sin
// importar `features/voluntarios`. Propaga ApiException en error (no envuelve
// en Result): su consumidor es `AppCatalogSearchPicker.onLoadPage`.

import '../network/api_client.dart';
import 'catalogo_recurso.dart';

class VoluntariosCatalogoService {
  final ApiClient _client;

  const VoluntariosCatalogoService(this._client);

  /// Tamaño de página alineado con el `limit` por defecto del backend.
  static const int pageSize = 50;

  /// Lista paginada filtrada por [query] (busca por nombre, DNI o teléfono en
  /// el backend) para alimentar el picker. Una página vacía marca el fin de la
  /// paginación.
  Future<List<CatalogoRecurso>> buscarVoluntarios(String query, int page) async {
    final params = <String, String>{
      'skip': (page * pageSize).toString(),
      'limit': pageSize.toString(),
    };
    final q = query.trim();
    if (q.isNotEmpty) params['q'] = q;
    final res = await _client.getList('/voluntarios', queryParams: params);
    return res.body
        .cast<Map<String, dynamic>>()
        .map(CatalogoRecurso.voluntario)
        .toList(growable: false);
  }
}
