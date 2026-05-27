// Tipo de material. Mirrors app/models/material.py.

enum TipoMaterial {
  personal('personal'),
  prestable('prestable'),
  servicio('servicio');

  const TipoMaterial(this.wire);

  final String wire;

  static TipoMaterial? fromWire(String value) {
    for (final t in TipoMaterial.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
