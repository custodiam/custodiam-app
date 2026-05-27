// Tipo de inscripción de un voluntario en un servicio. Espeja el
// backend StrEnum (app/models/inscripcion_servicio.py: TipoInscripcion).
//
// - `inscrito`: el voluntario se apuntó por iniciativa propia (US-03-08).
// - `convocado`: el voluntario fue llamado por un mando (US-03-04/05/06).

enum TipoInscripcion {
  inscrito('inscrito'),
  convocado('convocado');

  const TipoInscripcion(this.wire);

  final String wire;

  static TipoInscripcion? fromWire(String value) {
    for (final t in TipoInscripcion.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
