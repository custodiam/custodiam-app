// Tipo de vehículo. Mirrors app/models/vehiculo.py.

enum TipoVehiculo {
  furgoneta('furgoneta'),
  pickUp('pick_up'),
  ambulancia('ambulancia'),
  remolque('remolque');

  const TipoVehiculo(this.wire);

  final String wire;

  static TipoVehiculo? fromWire(String value) {
    for (final t in TipoVehiculo.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
