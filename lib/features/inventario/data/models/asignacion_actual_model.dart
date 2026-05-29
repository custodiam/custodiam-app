import '../../domain/entities/asignacion_actual.dart';
import '../../domain/entities/tipo_asignacion.dart';

class AsignacionActualModel {
  const AsignacionActualModel._();

  static AsignacionActual fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoAsignacion.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de asignación: $tipoRaw');
    }
    return AsignacionActual(
      tipo: tipo,
      voluntarioId: json['voluntario_id'] as String?,
      servicioId: json['servicio_id'] as String?,
      vehiculoId: json['vehiculo_id'] as String?,
      servicioTitulo: json['servicio_titulo'] as String?,
      cantidad: (json['cantidad'] as int?) ?? 1,
      fechaAsignacion: DateTime.parse(json['fecha_asignacion'] as String),
    );
  }
}
