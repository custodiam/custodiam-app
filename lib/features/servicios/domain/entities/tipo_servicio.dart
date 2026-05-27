// Tipo de servicio. Wire values mirror the backend StrEnum
// (app/models/servicio.py: TipoServicio).

enum TipoServicio {
  preventivo('preventivo'),
  emergencia('emergencia'),
  formacion('formacion'),
  otro('otro');

  const TipoServicio(this.wire);

  final String wire;

  static TipoServicio? fromWire(String value) {
    for (final t in TipoServicio.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
