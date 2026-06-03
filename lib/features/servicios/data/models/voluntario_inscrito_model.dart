// JSON ↔ domain mapper for VoluntarioInscrito.

import '../../domain/entities/tipo_inscripcion.dart';
import '../../domain/entities/voluntario_inscrito.dart';

class VoluntarioInscritoModel {
  const VoluntarioInscritoModel._();

  static VoluntarioInscrito fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoInscripcion.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de inscripción: $tipoRaw');
    }
    return VoluntarioInscrito(
      voluntarioId: json['voluntario_id'] as String,
      nombre: json['nombre'] as String,
      // El backend oculta el teléfono a quien no es mando; llega null.
      telefono: json['telefono'] as String?,
      tipo: tipo,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}
