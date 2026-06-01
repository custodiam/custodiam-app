// Página de resultados del catálogo de ubicaciones: los elementos visibles
// más el total (cabecera X-Total-Count) para la paginación por scroll.

import 'ubicacion.dart';

class UbicacionesPage {
  final List<Ubicacion> items;
  final int total;

  const UbicacionesPage({required this.items, required this.total});
}
