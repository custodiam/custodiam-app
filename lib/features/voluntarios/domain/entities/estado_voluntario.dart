// Estado operativo del voluntario. Wire values mirror the backend
// StrEnum (app/models/voluntario.py: EstadoVoluntario). Keep both in
// lockstep when a new state lands on the API side.

enum EstadoVoluntario {
  activo('activo'),
  baja('baja'),
  suspendido('suspendido');

  const EstadoVoluntario(this.wire);

  /// Identificador textual; coincide con el value del StrEnum del backend.
  final String wire;

  static EstadoVoluntario? fromWire(String value) {
    for (final e in EstadoVoluntario.values) {
      if (e.wire == value) return e;
    }
    return null;
  }
}
