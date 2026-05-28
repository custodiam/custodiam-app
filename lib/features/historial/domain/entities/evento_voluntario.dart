// Una fila del audit log del voluntario (EN-02-04). Inmutable, sin
// dependencias de Flutter. El `payload` mantiene la firma `dict|null`
// del backend porque su esquema varía por tipo de evento y la UI lo
// renderiza con un widget genérico key/value cuando hace falta.

import 'tipo_evento_voluntario.dart';

class EventoVoluntario {
  final String id;
  final String voluntarioId;
  final TipoEventoVoluntario tipo;
  final Map<String, dynamic>? payload;
  final String? actorKeycloakId;
  final DateTime? createdAt;

  const EventoVoluntario({
    required this.id,
    required this.voluntarioId,
    required this.tipo,
    required this.payload,
    required this.actorKeycloakId,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventoVoluntario && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
