// JSON ↔ domain mapper para ResumenVoluntario y UltimoServicioResumen.

import '../../domain/entities/resumen_voluntario.dart';

class ResumenVoluntarioModel {
  const ResumenVoluntarioModel._();

  static ResumenVoluntario fromJson(Map<String, dynamic> json) {
    final ultimoRaw = json['ultimo_servicio'];
    return ResumenVoluntario(
      horasTotales: json['horas_totales'] as int,
      segundosTotales: json['segundos_totales'] as int,
      serviciosRealizados: json['servicios_realizados'] as int,
      ultimoServicio: ultimoRaw is Map<String, dynamic>
          ? UltimoServicioResumen(
              servicioId: ultimoRaw['servicio_id'] as String,
              titulo: ultimoRaw['titulo'] as String,
              fechaInicio: DateTime.parse(ultimoRaw['fecha_inicio'] as String),
            )
          : null,
    );
  }
}
