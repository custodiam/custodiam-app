// Aplanado para GET /servicios/{id}/voluntarios. Identifica al
// voluntario y diferencia inscripción propia vs convocatoria.

import 'tipo_inscripcion.dart';

class VoluntarioInscrito {
  final String voluntarioId;
  final String nombre;

  /// Teléfono del voluntario. Es null cuando el backend lo oculta (a quien
  /// consulta sin ser mando solo se le devuelve el teléfono de los mandos,
  /// no el del resto de operativos). La UI solo lo muestra si viene no-nulo.
  final String? telefono;
  final TipoInscripcion tipo;
  final DateTime fecha;

  const VoluntarioInscrito({
    required this.voluntarioId,
    required this.nombre,
    this.telefono,
    required this.tipo,
    required this.fecha,
  });
}
