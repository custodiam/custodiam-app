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
  final String ubicacionBase;
  final EstadoInventario estado;
  final String? observacionesIncidencia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehiculoItem({
    required this.id,
    required this.codigoInterno,
    required this.matricula,
    required this.tipo,
    required this.ubicacionBase,
    required this.estado,
    this.marcaModelo,
    this.fechaItv,
    this.fotoUrl,
    this.observaciones,
    this.observacionesIncidencia,
    this.createdAt,
    this.updatedAt,
  });
}
