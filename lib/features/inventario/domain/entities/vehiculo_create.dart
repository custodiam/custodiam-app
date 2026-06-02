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
  // Ubicación: el texto es legacy opcional; la referencia canónica es el FK
  // al catálogo `ubicaciones` (PR2).
  final String? ubicacionBase;
  final String? ubicacionBaseId;

  const VehiculoCreate({
    required this.codigoInterno,
    required this.matricula,
    required this.tipo,
    this.ubicacionBase,
    this.ubicacionBaseId,
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
    };
    if (ubicacionBase != null) json['ubicacion_base'] = ubicacionBase;
    if (ubicacionBaseId != null) json['ubicacion_base_id'] = ubicacionBaseId;
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
