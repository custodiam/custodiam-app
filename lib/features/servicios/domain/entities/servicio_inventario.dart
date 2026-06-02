// Recursos (material + vehículos) asignados a un servicio. Aplanado de
// GET /servicios/{id}/inventario (R1). Cada elemento trae ya el nombre /
// identificadores del recurso para mostrarlos sin un segundo viaje.

class MaterialAsignadoServicio {
  final String id; // id de la asignación
  final String materialId;
  final String materialNombre;
  final int cantidad;
  final DateTime fechaAsignacion;

  const MaterialAsignadoServicio({
    required this.id,
    required this.materialId,
    required this.materialNombre,
    required this.cantidad,
    required this.fechaAsignacion,
  });
}

class VehiculoAsignadoServicio {
  final String id; // id de la asignación
  final String vehiculoId;
  final String codigoInterno;
  final String matricula;
  final DateTime fechaAsignacion;

  const VehiculoAsignadoServicio({
    required this.id,
    required this.vehiculoId,
    required this.codigoInterno,
    required this.matricula,
    required this.fechaAsignacion,
  });
}

class ServicioInventario {
  final List<MaterialAsignadoServicio> material;
  final List<VehiculoAsignadoServicio> vehiculos;

  const ServicioInventario({required this.material, required this.vehiculos});

  bool get isEmpty => material.isEmpty && vehiculos.isEmpty;
}
