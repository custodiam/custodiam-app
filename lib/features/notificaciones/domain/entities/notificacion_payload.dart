// Notification payload normalised across foreground/background/opened.
// The backend sends `tipo` (string), `servicio_id` (UUID) and a `prioridad`
// inside `data:` (FCM data-only messages). The Apple/Android `notification`
// fields (title + body) come as `title`/`body`. We keep both planes here
// so the page that handles the tap can decide where to navigate without
// depending on the FirebaseMessaging types.

class NotificacionPayload {
  /// `tipo` del backend (`emergencia`, `nuevo_servicio`, `recordatorio`, ...).
  final String? tipo;

  /// UUID del servicio al que apunta la notificación, si aplica.
  final String? servicioId;

  /// Prioridad declarada por el backend (`critica`, `alta`, `normal`, `baja`).
  final String? prioridad;

  /// Título visible al usuario (rellenado por el backend en el bloque
  /// `notification`).
  final String? titulo;

  /// Cuerpo visible al usuario.
  final String? cuerpo;

  /// Mapa de datos crudo; los wrappers concretos pueden inspeccionarlo
  /// para campos extra que el dominio aún no conoce sin esperar a bumps.
  final Map<String, String> data;

  const NotificacionPayload({
    this.tipo,
    this.servicioId,
    this.prioridad,
    this.titulo,
    this.cuerpo,
    this.data = const {},
  });
}
