// Plataforma del dispositivo registrado en FCM. Mirrors backend
// app/models/dispositivo.py: PlataformaDispositivo.

enum PlataformaDispositivo {
  android('android'),
  ios('ios'),
  web('web');

  const PlataformaDispositivo(this.wire);

  /// Identificador textual; coincide con el StrEnum del backend.
  final String wire;

  static PlataformaDispositivo? fromWire(String value) {
    for (final p in PlataformaDispositivo.values) {
      if (p.wire == value) return p;
    }
    return null;
  }
}
