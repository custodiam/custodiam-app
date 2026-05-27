import '../../domain/entities/horas_acumuladas.dart';

class HorasAcumuladasModel {
  const HorasAcumuladasModel._();

  static HorasAcumuladas fromJson(Map<String, dynamic> json) {
    return HorasAcumuladas(
      voluntarioId: json['voluntario_id'] as String,
      totalSegundos: json['total_segundos'] as int,
      // Backend devuelve un float (`round(total_seg / 3600, 2)`),
      // pero JSON puede entregar int si total_horas es entero. Toleramos
      // ambos para no fallar la deserialización en valores como 0 ó 12.
      totalHoras: (json['total_horas'] as num).toDouble(),
      fichajesCerrados: json['fichajes_cerrados'] as int,
      fichajesAbiertos: json['fichajes_abiertos'] as int,
    );
  }
}
