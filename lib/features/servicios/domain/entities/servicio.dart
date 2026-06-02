// Servicio completo devuelto por GET /servicios/{id}.
// Mirrors ServicioResponse del backend (app/schemas/servicio.py).

import 'estado_servicio.dart';
import 'tipo_servicio.dart';

class Servicio {
  final String id;
  final String titulo;
  final String? descripcion;
  final TipoServicio tipo;
  final EstadoServicio estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String ubicacion;

  /// Coordenadas exactas de la ubicación, fuente de verdad para abrir
  /// el mapa nativo (ADR-030). Son nulas mientras el servicio no tenga
  /// ubicación geolocalizada; `ubicacion` (texto) sigue siendo la
  /// etiqueta humana. Siempre van juntas o ambas nulas (lo garantiza
  /// el backend).
  final double? ubicacionLat;
  final double? ubicacionLng;
  final int? numeroVoluntarios;

  /// Número de voluntarios actualmente inscritos. Lo aporta el backend
  /// (inscritos_count, no nullable, default 0) para que la UI pueda
  /// bloquear "Apuntarme" cuando se alcanza el aforo.
  final int inscritosCount;
  final String? notasMaterial;
  final String? notasVehiculos;
  final String? observacionesCierre;
  final String? creadoPorKeycloakId;
  final DateTime? fechaCierre;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Servicio({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.estado,
    required this.fechaInicio,
    required this.ubicacion,
    required this.inscritosCount,
    this.descripcion,
    this.fechaFin,
    this.ubicacionLat,
    this.ubicacionLng,
    this.numeroVoluntarios,
    this.notasMaterial,
    this.notasVehiculos,
    this.observacionesCierre,
    this.creadoPorKeycloakId,
    this.fechaCierre,
    this.createdAt,
    this.updatedAt,
  });
}
