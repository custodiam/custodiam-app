// Respuesta agregada del backend para un mes concreto: año, mes y los
// días declarados. La cabecera year/month viene explícita para que el
// cliente pueda detectar respuestas desfasadas si el usuario navega
// rápidamente entre meses (último GET en vuelo gana, pero podemos
// descartarlo si el año o el mes ya no coinciden con el seleccionado).

import 'dia_disponibilidad.dart';

class MesDisponibilidad {
  final int year;
  final int month;
  final List<DiaDisponibilidad> dias;

  const MesDisponibilidad({
    required this.year,
    required this.month,
    required this.dias,
  });

  /// Devuelve `true` si el voluntario declaró disponibilidad para el
  /// día con [day] del mes. Si el día no aparece en [dias], se
  /// interpreta como "no disponible".
  bool estaDisponible(int day) {
    for (final dia in dias) {
      if (dia.fecha.day == day && dia.disponible) return true;
    }
    return false;
  }
}
