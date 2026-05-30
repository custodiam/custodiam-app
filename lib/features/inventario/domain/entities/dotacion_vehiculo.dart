// Una línea de dotación fija: material asignado de forma permanente a un
// vehículo (PR3). Espejo de DotacionVehiculoResponse del backend: vista
// curada que aplana el nombre del material para no cruzar con el catálogo.
// `id` es el id de la asignación (lo que el DELETE espera como
// `asignacion_id`).

class DotacionVehiculo {
  final String id;
  final String materialId;
  final String materialNombre;
  final int cantidad;
  final DateTime fechaAsignacion;

  const DotacionVehiculo({
    required this.id,
    required this.materialId,
    required this.materialNombre,
    required this.cantidad,
    required this.fechaAsignacion,
  });
}
