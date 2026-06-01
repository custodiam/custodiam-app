import '../../domain/entities/ubicacion.dart';

class UbicacionModel {
  const UbicacionModel._();

  /// Construye desde `UbicacionSummary` (GET lista: id+nombre+lat+lng, sin
  /// descripción) o `UbicacionResponse` (GET detalle / POST / PATCH: con
  /// descripción). `descripcion` queda en null cuando el JSON no la trae.
  static Ubicacion fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
