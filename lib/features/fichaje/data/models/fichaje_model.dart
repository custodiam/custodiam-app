// JSON ↔ domain mapper for Fichaje.

import '../../domain/entities/fichaje.dart';

class FichajeModel {
  const FichajeModel._();

  static Fichaje fromJson(Map<String, dynamic> json) {
    return Fichaje(
      id: json['id'] as String,
      servicioId: json['servicio_id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      horaEntrada: DateTime.parse(json['hora_entrada'] as String),
      horaSalida: json['hora_salida'] != null
          ? DateTime.parse(json['hora_salida'] as String)
          : null,
      automatico: json['automatico'] as bool,
      duracionSegundos: json['duracion_segundos'] as int?,
    );
  }
}
