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
  final int? numeroVoluntarios;
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
    this.descripcion,
    this.fechaFin,
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
