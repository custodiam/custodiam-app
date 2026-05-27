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
  final String ubicacionBase;
  final DateTime? fechaAdquisicion;
  final DateTime? fechaProximaRevision;
  final String? fotoUrl;

  const MaterialCreate({
    required this.nombre,
    required this.tipo,
    required this.ubicacionBase,
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
      'ubicacion_base': ubicacionBase,
    };
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
