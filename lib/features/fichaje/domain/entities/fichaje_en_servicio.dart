// Aplanado para GET /servicios/{id}/fichaje (US-04-04). Incluye los
// datos mínimos del voluntario para identificarle sin un segundo
// round-trip.

class FichajeEnServicio {
  final String fichajeId;
  final String voluntarioId;
  final String nombre;
  final DateTime horaEntrada;
  final DateTime? horaSalida;
  final bool automatico;
  final int? duracionSegundos;

  const FichajeEnServicio({
    required this.fichajeId,
    required this.voluntarioId,
    required this.nombre,
    required this.horaEntrada,
    required this.automatico,
    this.horaSalida,
    this.duracionSegundos,
  });

  bool get estaAbierto => horaSalida == null;
}
