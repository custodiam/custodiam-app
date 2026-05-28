// Contrato del repositorio de disponibilidad. Espeja exactamente los
// dos endpoints REST publicados por `custodiam-api` para US-02-04:
//
//   - GET /voluntarios/me/disponibilidad?year=YYYY&month=MM
//   - PUT /voluntarios/me/disponibilidad/{fecha} body {disponible}

import '../../../../infrastructure/error/result.dart';
import '../entities/dia_disponibilidad.dart';
import '../entities/mes_disponibilidad.dart';

abstract class DisponibilidadRepository {
  /// Carga la disponibilidad declarada para el mes indicado por el
  /// voluntario actual. Los días que no estén en la lista se
  /// interpretan como "no disponible" en la UI.
  Future<Result<MesDisponibilidad>> obtenerMes({
    required int year,
    required int month,
  });

  /// Marca o desmarca un día como disponible. Idempotente: el backend
  /// hace upsert sobre `(voluntario, fecha)`. Devuelve la fila
  /// resultante para que el ViewModel mantenga el estado sin esperar
  /// otro GET.
  Future<Result<DiaDisponibilidad>> marcarDia({
    required DateTime fecha,
    required bool disponible,
  });
}
