// Vista curada de "a quién / dónde está asignado" un activo (PR1).
//
// Espejo del AsignacionActualResponse del backend: es una lectura de
// trazabilidad, deliberadamente distinta del registro completo
// AsignacionMaterial (que lleva id, activa, fechaDevolucion...). Aquí
// solo viaja lo que la ficha necesita pintar: tipo, target, cantidad y
// fecha. Exactamente uno de {voluntarioId, servicioId, vehiculoId} viene
// informado según `tipo`.

import 'tipo_asignacion.dart';

class AsignacionActual {
  final TipoAsignacion tipo;
  final String? voluntarioId;
  final String? servicioId;
  final String? vehiculoId;

  /// Título del servicio, adjuntado por el backend solo en la asignación
  /// singular de un vehículo (evita un segundo viaje para resolverlo).
  final String? servicioTitulo;
  final int cantidad;
  final DateTime fechaAsignacion;

  const AsignacionActual({
    required this.tipo,
    required this.cantidad,
    required this.fechaAsignacion,
    this.voluntarioId,
    this.servicioId,
    this.vehiculoId,
    this.servicioTitulo,
  });
}
