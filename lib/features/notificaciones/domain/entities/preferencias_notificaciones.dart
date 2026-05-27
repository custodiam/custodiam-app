// Preferencias locales de notificaciones (US-06-03). Se almacenan con
// shared_preferences; no hay endpoint backend de preferencias en MVP.
// Las emergencias quedan SIEMPRE activas en el dominio: el toggle
// existe en UI pero deshabilitarlas requiere ir a los ajustes del
// sistema operativo (es lo más seguro para un sistema de Protección
// Civil — un voluntario no puede silenciar emergencias por accidente
// desde la app).

class PreferenciasNotificaciones {
  /// Las emergencias se reciben siempre que el SO permita notificaciones.
  /// Este flag es informativo y siempre vale `true` en el dominio.
  final bool emergencias;

  /// El voluntario quiere recibir push cuando se publica un servicio nuevo
  /// (preventivo / formación / otro) al que puede apuntarse.
  final bool nuevosServicios;

  /// El voluntario quiere recibir recordatorios próximos a sus servicios
  /// inscritos. Reservado para F2; el toggle existe ya para evitar bumps
  /// de UI cuando llegue el feature backend.
  final bool recordatorios;

  const PreferenciasNotificaciones({
    this.emergencias = true,
    this.nuevosServicios = true,
    this.recordatorios = true,
  });

  static const defaults = PreferenciasNotificaciones();

  PreferenciasNotificaciones copyWith({
    bool? nuevosServicios,
    bool? recordatorios,
  }) {
    return PreferenciasNotificaciones(
      // Emergencias no se puede toggle desde la app.
      emergencias: true,
      nuevosServicios: nuevosServicios ?? this.nuevosServicios,
      recordatorios: recordatorios ?? this.recordatorios,
    );
  }
}
