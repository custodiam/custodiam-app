// Entidad de dominio para una fila del calendario mensual de
// disponibilidad. Refleja un día concreto declarado por el voluntario.
// Si un día del mes no aparece en la lista que devuelve el backend, el
// cliente lo renderiza como "no disponible" por defecto (criterio de
// aceptación de US-02-04).

class DiaDisponibilidad {
  final String id;
  final String voluntarioId;
  final DateTime fecha;
  final bool disponible;

  const DiaDisponibilidad({
    required this.id,
    required this.voluntarioId,
    required this.fecha,
    required this.disponible,
  });

  DiaDisponibilidad copyWith({bool? disponible}) {
    return DiaDisponibilidad(
      id: id,
      voluntarioId: voluntarioId,
      fecha: fecha,
      disponible: disponible ?? this.disponible,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaDisponibilidad &&
          id == other.id &&
          voluntarioId == other.voluntarioId &&
          fecha == other.fecha &&
          disponible == other.disponible;

  @override
  int get hashCode => Object.hash(id, voluntarioId, fecha, disponible);
}
