import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_summary.dart';

class VehiculoSummaryModel {
  const VehiculoSummaryModel._();

  static VehiculoSummary fromJson(Map<String, dynamic> json) {
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
    return VehiculoSummary(
      id: json['id'] as String,
      codigoInterno: json['codigo_interno'] as String,
      matricula: json['matricula'] as String,
      tipo: tipo,
      estado: estado,
      ubicacionBase: json['ubicacion_base'] as String?,
    );
  }
}
