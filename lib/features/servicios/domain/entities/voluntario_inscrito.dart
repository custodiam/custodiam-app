// Aplanado para GET /servicios/{id}/voluntarios. Identifica al
// voluntario y diferencia inscripción propia vs convocatoria.

import 'tipo_inscripcion.dart';

class VoluntarioInscrito {
  final String voluntarioId;
  final String nombre;
  final String telefono;
  final TipoInscripcion tipo;
  final DateTime fecha;

  const VoluntarioInscrito({
    required this.voluntarioId,
    required this.nombre,
    required this.telefono,
    required this.tipo,
    required this.fecha,
  });
}
