// Dispositivo registrado contra el backend. Mirrors el DispositivoResponse
// del backend (app/schemas/dispositivo.py).

import 'plataforma_dispositivo.dart';

class DispositivoRegistrado {
  final String id;
  final String voluntarioId;
  final String fcmToken;
  final PlataformaDispositivo plataforma;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? ultimaActualizacion;

  const DispositivoRegistrado({
    required this.id,
    required this.voluntarioId,
    required this.fcmToken,
    required this.plataforma,
    required this.activo,
    this.createdAt,
    this.ultimaActualizacion,
  });
}
