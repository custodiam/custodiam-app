import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_item.dart';
import 'asignacion_actual_model.dart';

class VehiculoItemModel {
  const VehiculoItemModel._();

  static VehiculoItem fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoVehiculo.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de vehículo: $tipoRaw');
    }
    final estadoRaw = json['estado'] as String;
    final estado = EstadoInventario.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado de inventario: $estadoRaw');
    }
    return VehiculoItem(
      id: json['id'] as String,
      codigoInterno: json['codigo_interno'] as String,
      matricula: json['matricula'] as String,
      tipo: tipo,
      marcaModelo: json['marca_modelo'] as String?,
      fechaItv: json['fecha_itv'] != null
          ? DateTime.parse(json['fecha_itv'] as String)
          : null,
      fotoUrl: json['foto_url'] as String?,
      observaciones: json['observaciones'] as String?,
      ubicacionBase: json['ubicacion_base'] as String,
      estado: estado,
      observacionesIncidencia: json['observaciones_incidencia'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      asignacionActual: json['asignacion_actual'] != null
          ? AsignacionActualModel.fromJson(
              json['asignacion_actual'] as Map<String, dynamic>)
          : null,
    );
  }
}
