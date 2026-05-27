import 'estado_inventario.dart';
import 'tipo_vehiculo.dart';

class VehiculoSummary {
  final String id;
  final String codigoInterno;
  final String matricula;
  final TipoVehiculo tipo;
  final EstadoInventario estado;
  final String ubicacionBase;

  const VehiculoSummary({
    required this.id,
    required this.codigoInterno,
    required this.matricula,
    required this.tipo,
    required this.estado,
    required this.ubicacionBase,
  });
}
