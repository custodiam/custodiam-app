import '../../domain/entities/fichaje_en_servicio.dart';

class FichajeEnServicioModel {
  const FichajeEnServicioModel._();

  static FichajeEnServicio fromJson(Map<String, dynamic> json) {
    return FichajeEnServicio(
      fichajeId: json['fichaje_id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      nombre: json['nombre'] as String,
      horaEntrada: DateTime.parse(json['hora_entrada'] as String),
      horaSalida: json['hora_salida'] != null
          ? DateTime.parse(json['hora_salida'] as String)
          : null,
      automatico: json['automatico'] as bool,
      duracionSegundos: json['duracion_segundos'] as int?,
    );
  }
}
