// JSON ↔ domain mapper for DispositivoRegistrado.

import '../../domain/entities/dispositivo_registrado.dart';
import '../../domain/entities/plataforma_dispositivo.dart';

class DispositivoRegistradoModel {
  const DispositivoRegistradoModel._();

  static DispositivoRegistrado fromJson(Map<String, dynamic> json) {
    final plataformaRaw = json['plataforma'] as String;
    final plataforma = PlataformaDispositivo.fromWire(plataformaRaw);
    if (plataforma == null) {
      throw FormatException('Unknown plataforma: $plataformaRaw');
    }
    return DispositivoRegistrado(
      id: json['id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      fcmToken: json['fcm_token'] as String,
      plataforma: plataforma,
      activo: json['activo'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      ultimaActualizacion: json['ultima_actualizacion'] != null
          ? DateTime.parse(json['ultima_actualizacion'] as String)
          : null,
    );
  }
}
