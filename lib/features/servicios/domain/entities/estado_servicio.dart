// Estado del ciclo de vida de un servicio. Wire values mirror the
// backend StrEnum (app/models/servicio.py: EstadoServicio).

enum EstadoServicio {
  borrador('borrador'),
  publicado('publicado'),
  activo('activo'),
  cerrado('cerrado');

  const EstadoServicio(this.wire);

  /// Identificador textual; coincide con el value del StrEnum del backend.
  final String wire;

  static EstadoServicio? fromWire(String value) {
    for (final e in EstadoServicio.values) {
      if (e.wire == value) return e;
    }
    return null;
  }
}
