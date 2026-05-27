// Fichaje individual (CU-05/06). Mirrors FichajeResponse del backend.

class Fichaje {
  final String id;
  final String servicioId;
  final String voluntarioId;
  final DateTime horaEntrada;
  final DateTime? horaSalida;
  final bool automatico;
  final int? duracionSegundos;

  const Fichaje({
    required this.id,
    required this.servicioId,
    required this.voluntarioId,
    required this.horaEntrada,
    required this.automatico,
    this.horaSalida,
    this.duracionSegundos,
  });

  bool get estaAbierto => horaSalida == null;
}
