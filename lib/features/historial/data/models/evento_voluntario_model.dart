// JSON ↔ domain mapper para EventoVoluntario.

import '../../domain/entities/evento_voluntario.dart';
import '../../domain/entities/tipo_evento_voluntario.dart';

class EventoVoluntarioModel {
  const EventoVoluntarioModel._();

  static EventoVoluntario fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo_evento'] as String;
    final tipo = TipoEventoVoluntario.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo_evento: $tipoRaw');
    }
    final payloadRaw = json['payload'];
    return EventoVoluntario(
      id: json['id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      tipo: tipo,
      payload: payloadRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(payloadRaw)
          : null,
      actorKeycloakId: json['actor_keycloak_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
