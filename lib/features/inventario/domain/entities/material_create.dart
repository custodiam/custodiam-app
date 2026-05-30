// Input for POST /inventario/material (US-05-01).

import 'tipo_material.dart';

class MaterialCreate {
  final String nombre;
  final String? descripcion;
  final String? codigo;
  final String? numeroSerie;
  final TipoMaterial tipo;
  final String? categoria;
  final int cantidad;
  // Ubicación: el texto es legacy opcional; la referencia canónica es el FK
  // al catálogo `ubicaciones` (PR2).
  final String? ubicacionBase;
  final String? ubicacionBaseId;
  final DateTime? fechaAdquisicion;
  final DateTime? fechaProximaRevision;
  final String? fotoUrl;

  const MaterialCreate({
    required this.nombre,
    required this.tipo,
    this.ubicacionBase,
    this.ubicacionBaseId,
    this.descripcion,
    this.codigo,
    this.numeroSerie,
    this.categoria,
    this.cantidad = 1,
    this.fechaAdquisicion,
    this.fechaProximaRevision,
    this.fotoUrl,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'nombre': nombre,
      'tipo': tipo.wire,
      'cantidad': cantidad,
    };
    if (ubicacionBase != null) json['ubicacion_base'] = ubicacionBase;
    if (ubicacionBaseId != null) json['ubicacion_base_id'] = ubicacionBaseId;
    if (descripcion != null) json['descripcion'] = descripcion;
    if (codigo != null) json['codigo'] = codigo;
    if (numeroSerie != null) json['numero_serie'] = numeroSerie;
    if (categoria != null) json['categoria'] = categoria;
    if (fechaAdquisicion != null) {
      json['fecha_adquisicion'] = _date(fechaAdquisicion!);
    }
    if (fechaProximaRevision != null) {
      json['fecha_proxima_revision'] = _date(fechaProximaRevision!);
    }
    if (fotoUrl != null) json['foto_url'] = fotoUrl;
    return json;
  }

  String _date(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
