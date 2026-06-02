// Elemento neutro de un catálogo de inventario para alimentar pickers de
// selección (AppCatalogSearchPicker). Vive en infrastructure (no en una
// feature) para que cualquier feature lo consuma sin importar de otra:
// `servicios` necesita listar el catálogo de inventario al asignar recursos
// a un servicio (R1), pero `features/servicios` no puede importar
// `features/inventario` (guía 26 §1). El tipo es deliberadamente mínimo
// —id + etiqueta visible— porque el picker solo necesita eso para mostrar y
// devolver la selección.

class CatalogoRecurso {
  final String id;
  final String label;

  const CatalogoRecurso({required this.id, required this.label});

  /// Construye desde una fila de `GET /inventario/material` (MaterialSummary).
  factory CatalogoRecurso.material(Map<String, dynamic> json) {
    return CatalogoRecurso(
      id: json['id'] as String,
      label: json['nombre'] as String,
    );
  }

  /// Construye desde una fila de `GET /inventario/vehiculos` (VehiculoSummary):
  /// se muestra el código interno y la matrícula, los dos identificadores que
  /// un mando reconoce de un vistazo.
  factory CatalogoRecurso.vehiculo(Map<String, dynamic> json) {
    return CatalogoRecurso(
      id: json['id'] as String,
      label: '${json['codigo_interno']} · ${json['matricula']}',
    );
  }

  /// Construye desde una fila de `GET /ubicaciones` (UbicacionSummary) o desde
  /// la respuesta de `POST /ubicaciones` (UbicacionResponse): en ambas el
  /// nombre es la etiqueta visible (PR2).
  factory CatalogoRecurso.ubicacion(Map<String, dynamic> json) {
    return CatalogoRecurso(
      id: json['id'] as String,
      label: json['nombre'] as String,
    );
  }

  /// Construye desde una fila de `GET /voluntarios` (VoluntarioSummary): se
  /// muestra el nombre y el teléfono, los dos datos con los que un mando
  /// reconoce a un voluntario al asignarle material.
  factory CatalogoRecurso.voluntario(Map<String, dynamic> json) {
    return CatalogoRecurso(
      id: json['id'] as String,
      label: '${json['nombre']} · ${json['telefono']}',
    );
  }
}
