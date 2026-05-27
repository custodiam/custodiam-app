// Input for POST /inventario/vehiculos (US-05-02).

import 'tipo_vehiculo.dart';

class VehiculoCreate {
  final String codigoInterno;
  final String matricula;
  final TipoVehiculo tipo;
  final String? marcaModelo;
  final DateTime? fechaItv;
  final String? fotoUrl;
  final String? observaciones;
  final String ubicacionBase;

  const VehiculoCreate({
    required this.codigoInterno,
    required this.matricula,
    required this.tipo,
    required this.ubicacionBase,
    this.marcaModelo,
    this.fechaItv,
    this.fotoUrl,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'codigo_interno': codigoInterno,
      'matricula': matricula,
      'tipo': tipo.wire,
      'ubicacion_base': ubicacionBase,
    };
    if (marcaModelo != null) json['marca_modelo'] = marcaModelo;
    if (fechaItv != null) {
      final mm = fechaItv!.month.toString().padLeft(2, '0');
      final dd = fechaItv!.day.toString().padLeft(2, '0');
      json['fecha_itv'] = '${fechaItv!.year}-$mm-$dd';
    }
    if (fotoUrl != null) json['foto_url'] = fotoUrl;
    if (observaciones != null) json['observaciones'] = observaciones;
    return json;
  }
}
