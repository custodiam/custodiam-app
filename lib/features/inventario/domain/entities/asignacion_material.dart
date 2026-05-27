import 'tipo_asignacion.dart';

class AsignacionMaterial {
  final String id;
  final String materialId;
  final String? voluntarioId;
  final String? servicioId;
  final TipoAsignacion tipo;
  final int cantidad;
  final DateTime fechaAsignacion;
  final DateTime? fechaDevolucion;
  final String? observacionesDevolucion;
  final bool activa;

  const AsignacionMaterial({
    required this.id,
    required this.materialId,
    required this.tipo,
    required this.cantidad,
    required this.fechaAsignacion,
    required this.activa,
    this.voluntarioId,
    this.servicioId,
    this.fechaDevolucion,
    this.observacionesDevolucion,
  });
}
