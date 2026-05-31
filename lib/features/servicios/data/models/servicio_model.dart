// JSON ↔ domain mapper for Servicio (full detail).

import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/tipo_servicio.dart';

class ServicioModel {
  const ServicioModel._();

  static Servicio fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoServicio.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo from API: $tipoRaw');
    }
    final estadoRaw = json['estado'] as String;
    final estado = EstadoServicio.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado from API: $estadoRaw');
    }
    return Servicio(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      tipo: tipo,
      estado: estado,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      ubicacion: json['ubicacion'] as String,
      ubicacionLat: (json['ubicacion_lat'] as num?)?.toDouble(),
      ubicacionLng: (json['ubicacion_lng'] as num?)?.toDouble(),
      numeroVoluntarios: json['numero_voluntarios'] as int?,
      inscritosCount: json['inscritos_count'] as int,
      notasMaterial: json['notas_material'] as String?,
      notasVehiculos: json['notas_vehiculos'] as String?,
      observacionesCierre: json['observaciones_cierre'] as String?,
      creadoPorKeycloakId: json['creado_por_keycloak_id'] as String?,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
