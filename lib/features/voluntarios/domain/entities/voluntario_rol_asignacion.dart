// Asignación activa de un rol a un voluntario. Mirrors
// VoluntarioRolResponse en custodiam-api (app/schemas/voluntario.py).
// `fechaHasta` viene `null` para asignaciones vivas y se rellena al
// hacer DELETE (soft delete que cierra la asignación).

class VoluntarioRolAsignacion {
  final String id;
  final String voluntarioId;
  final String rolId;
  final String rolNombre;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const VoluntarioRolAsignacion({
    required this.id,
    required this.voluntarioId,
    required this.rolId,
    required this.rolNombre,
    this.fechaDesde,
    this.fechaHasta,
  });
}
