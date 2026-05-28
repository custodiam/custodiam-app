// Thin wrapper sobre ApiClient con los endpoints de disponibilidad
// (US-02-04 / CU-12). Mantiene el formato wire; el repository es quien
// envuelve en Result<T> y mapea excepciones a Failure.

import '../../../../infrastructure/network/api_client.dart';

class DisponibilidadApi {
  final ApiClient _client;

  const DisponibilidadApi(this._client);

  /// GET /voluntarios/me/disponibilidad?year=YYYY&month=MM.
  /// Devuelve el objeto `{year, month, dias[]}` tal cual lo serializa
  /// FastAPI.
  Future<Map<String, dynamic>> obtenerMes({
    required int year,
    required int month,
  }) {
    return _client.get(
      '/voluntarios/me/disponibilidad?year=$year&month=$month',
    );
  }

  /// PUT /voluntarios/me/disponibilidad/{fecha} body `{disponible}`.
  /// Upsert idempotente; devuelve la fila resultante.
  Future<Map<String, dynamic>> marcarDia({
    required DateTime fecha,
    required bool disponible,
  }) {
    final iso = _formatIsoDate(fecha);
    return _client.put(
      '/voluntarios/me/disponibilidad/$iso',
      {'disponible': disponible},
    );
  }

  /// Helper interno: ISO-8601 estricto `YYYY-MM-DD` sin componente
  /// horario. Evita usar `DateTime.toIso8601String()` que arrastra
  /// `T00:00:00.000` y rompería el parser estricto de `date` del
  /// backend.
  String _formatIsoDate(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
