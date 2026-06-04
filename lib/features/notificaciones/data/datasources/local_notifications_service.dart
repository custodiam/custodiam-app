// Abstracción para mostrar notificaciones del sistema cuando la app está
// en PRIMER PLANO. FCM no las pinta automáticamente en foreground en
// Android (solo emite el mensaje por `onMessage`), así que las dibujamos
// con `flutter_local_notifications`; en iOS las muestra el sistema vía
// `setForegroundNotificationPresentationOptions`. La implementación real
// (`LocalNotificationsServiceFlutter`) arrastra platform channels, por lo
// que los tests inyectan un fake en memoria y la VM usa el `Noop`.

/// Id del canal de emergencias. DEBE coincidir con el `channel_id` que
/// manda el backend (`ANDROID_CHANNEL_EMERGENCIAS` en `fcm_admin.py`). El
/// sonido y el comportamiento heads-up se fijan al crear el canal.
const String kCanalEmergencias = 'custodiam_emergencias';

/// Id del canal de avisos generales. Coincide con `ANDROID_CHANNEL_AVISOS`
/// del backend y con el `default_notification_channel_id` del manifest.
const String kCanalAvisos = 'custodiam_avisos';

abstract class LocalNotificationsService {
  /// Inicializa el plugin, crea los canales (Android) y habilita la
  /// presentación en primer plano (iOS). [onTapServicio] se invoca con el
  /// `servicio_id` (o `null`) cuando el usuario toca una notificación
  /// pintada por este servicio. Idempotente y nunca lanza: si la
  /// plataforma no soporta notificaciones locales, queda en no-op.
  Future<void> init({required void Function(String? servicioId) onTapServicio});

  /// Pinta una notificación heads-up con sonido para una emergencia. Solo
  /// surte efecto en Android; en iOS es no-op porque el banner foreground
  /// lo muestra el sistema (duplicarlo daría una notificación doble).
  /// [servicioId] viaja como payload para reusar la navegación al tocarla.
  Future<void> mostrarEmergencia({
    required String titulo,
    required String cuerpo,
    String? servicioId,
  });
}

/// Implementación neutra para Web (el plugin no soporta web) y para
/// cualquier entorno sin platform channels (VM de tests sin override).
class LocalNotificationsServiceNoop implements LocalNotificationsService {
  const LocalNotificationsServiceNoop();

  @override
  Future<void> init({
    required void Function(String? servicioId) onTapServicio,
  }) async {}

  @override
  Future<void> mostrarEmergencia({
    required String titulo,
    required String cuerpo,
    String? servicioId,
  }) async {}
}
