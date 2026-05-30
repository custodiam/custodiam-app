import 'asignacion_actual.dart';
import 'estado_inventario.dart';
import 'tipo_vehiculo.dart';

class VehiculoItem {
  final String id;
  final String codigoInterno;
  final String matricula;
  final TipoVehiculo tipo;
  final String? marcaModelo;
  final DateTime? fechaItv;
  final String? fotoUrl;
  final String? observaciones;
  // Etiqueta legacy opcional de ubicación (PR2): la referencia canónica es
  // el FK del backend; el texto puede no venir.
  final String? ubicacionBase;
  final EstadoInventario estado;
  final String? observacionesIncidencia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Asignación a servicio activa del vehículo, o `null` si está libre
  /// (PR1). Un vehículo es una unidad única, así que su asignación es
  /// singular. Solo llega en el detalle, nunca en el listado.
  final AsignacionActual? asignacionActual;

  const VehiculoItem({
    required this.id,
    required this.codigoInterno,
    required this.matricula,
    required this.tipo,
    this.ubicacionBase,
    required this.estado,
    this.marcaModelo,
    this.fechaItv,
    this.fotoUrl,
    this.observaciones,
    this.observacionesIncidencia,
    this.createdAt,
    this.updatedAt,
    this.asignacionActual,
  });
}
