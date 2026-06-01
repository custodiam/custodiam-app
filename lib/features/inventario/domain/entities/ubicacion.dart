// Ubicación del catálogo (E10). Lugar con nombre único y, opcionalmente,
// coordenadas (lat/lng van juntas o ninguna, invariante del backend). La
// descripción solo llega en el detalle (GET /ubicaciones/{id}); el summary
// de la lista trae id + nombre + coordenadas.

class Ubicacion {
  final String id;
  final String nombre;
  final String? descripcion;
  final double? lat;
  final double? lng;

  const Ubicacion({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.lat,
    this.lng,
  });

  bool get tieneCoordenadas => lat != null && lng != null;
}
