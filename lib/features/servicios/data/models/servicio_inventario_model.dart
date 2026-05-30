// JSON → domain mapper para GET /servicios/{id}/inventario (R1). El cuerpo
// es un objeto {material: [...], vehiculos: [...]}.

import '../../domain/entities/servicio_inventario.dart';

class ServicioInventarioModel {
  const ServicioInventarioModel._();

  static ServicioInventario fromJson(Map<String, dynamic> json) {
    final material = (json['material'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_material)
        .toList(growable: false);
    final vehiculos = (json['vehiculos'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_vehiculo)
        .toList(growable: false);
    return ServicioInventario(material: material, vehiculos: vehiculos);
  }

  static MaterialAsignadoServicio _material(Map<String, dynamic> j) {
    return MaterialAsignadoServicio(
      id: j['id'] as String,
      materialId: j['material_id'] as String,
      materialNombre: j['material_nombre'] as String,
      cantidad: j['cantidad'] as int,
      fechaAsignacion: DateTime.parse(j['fecha_asignacion'] as String),
    );
  }

  static VehiculoAsignadoServicio _vehiculo(Map<String, dynamic> j) {
    return VehiculoAsignadoServicio(
      id: j['id'] as String,
      vehiculoId: j['vehiculo_id'] as String,
      codigoInterno: j['codigo_interno'] as String,
      matricula: j['matricula'] as String,
      fechaAsignacion: DateTime.parse(j['fecha_asignacion'] as String),
    );
  }
}
