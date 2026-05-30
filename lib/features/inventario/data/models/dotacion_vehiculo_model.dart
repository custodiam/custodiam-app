import '../../domain/entities/dotacion_vehiculo.dart';

class DotacionVehiculoModel {
  const DotacionVehiculoModel._();

  static DotacionVehiculo fromJson(Map<String, dynamic> json) {
    return DotacionVehiculo(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      materialNombre: json['material_nombre'] as String,
      cantidad: json['cantidad'] as int,
      fechaAsignacion: DateTime.parse(json['fecha_asignacion'] as String),
    );
  }
}
