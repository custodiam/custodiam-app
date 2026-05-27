// Estado de un material/vehículo. Mirrors app/models/material.py.

enum EstadoInventario {
  operativo('operativo'),
  averiado('averiado'),
  perdido('perdido'),
  enUso('en_uso');

  const EstadoInventario(this.wire);

  final String wire;

  static EstadoInventario? fromWire(String value) {
    for (final e in EstadoInventario.values) {
      if (e.wire == value) return e;
    }
    return null;
  }
}
