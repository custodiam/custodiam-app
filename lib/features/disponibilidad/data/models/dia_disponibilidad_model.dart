// JSON ↔ domain mapper para DiaDisponibilidad.

import '../../domain/entities/dia_disponibilidad.dart';
import '../../domain/entities/mes_disponibilidad.dart';

class DiaDisponibilidadModel {
  const DiaDisponibilidadModel._();

  static DiaDisponibilidad fromJson(Map<String, dynamic> json) {
    return DiaDisponibilidad(
      id: json['id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      disponible: json['disponible'] as bool,
    );
  }
}

class MesDisponibilidadModel {
  const MesDisponibilidadModel._();

  static MesDisponibilidad fromJson(Map<String, dynamic> json) {
    final diasRaw = json['dias'] as List<dynamic>;
    return MesDisponibilidad(
      year: json['year'] as int,
      month: json['month'] as int,
      dias: diasRaw
          .map((e) => DiaDisponibilidadModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
