// Tipo de asignación de material. Mirrors app/models/asignacion_material.py.

enum TipoAsignacion {
  /// Equipamiento personal fijo (US-05-03).
  personal('personal'),

  /// Préstamo temporal pendiente de devolución (US-05-04).
  prestamo('prestamo'),

  /// Reservado para un servicio concreto (US-05-06).
  servicio('servicio'),

  /// Dotación fija de material asignada permanentemente a un vehículo (PR3).
  dotacionVehiculo('dotacion_vehiculo');

  const TipoAsignacion(this.wire);

  final String wire;

  static TipoAsignacion? fromWire(String value) {
    for (final t in TipoAsignacion.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
