// Resumen agregado de horas (US-04-03). Mirrors HorasAcumuladasResponse
// del backend.

class HorasAcumuladas {
  final String voluntarioId;
  final int totalSegundos;
  final double totalHoras;
  final int fichajesCerrados;
  final int fichajesAbiertos;

  const HorasAcumuladas({
    required this.voluntarioId,
    required this.totalSegundos,
    required this.totalHoras,
    required this.fichajesCerrados,
    required this.fichajesAbiertos,
  });
}
