// Input for POST /servicios. Mirrors ServicioCreate del backend.
// El estado inicial lo decide el servidor según el tipo:
// preventivo/formacion/otro → borrador; emergencia → activo.

import 'tipo_servicio.dart';

class ServicioCreate {
  final String titulo;
  final String? descripcion;
  final TipoServicio tipo;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String ubicacion;
  final int? numeroVoluntarios;
  final String? notasMaterial;
  final String? notasVehiculos;

  const ServicioCreate({
    required this.titulo,
    required this.tipo,
    required this.fechaInicio,
    required this.ubicacion,
    this.descripcion,
    this.fechaFin,
    this.numeroVoluntarios,
    this.notasMaterial,
    this.notasVehiculos,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'titulo': titulo,
      'tipo': tipo.wire,
      // El backend espera ISO 8601 con offset; toIso8601String() produce
      // formato compatible con datetime de Python (FastAPI/pydantic).
      'fecha_inicio': fechaInicio.toIso8601String(),
      'ubicacion': ubicacion,
    };
    if (descripcion != null) json['descripcion'] = descripcion;
    if (fechaFin != null) json['fecha_fin'] = fechaFin!.toIso8601String();
    if (numeroVoluntarios != null) {
      json['numero_voluntarios'] = numeroVoluntarios;
    }
    if (notasMaterial != null) json['notas_material'] = notasMaterial;
    if (notasVehiculos != null) json['notas_vehiculos'] = notasVehiculos;
    return json;
  }
}
