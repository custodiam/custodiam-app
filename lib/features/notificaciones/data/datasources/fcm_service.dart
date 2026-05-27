// Abstracción sobre `FirebaseMessaging.instance`. Una sola clase entera
// detrás de la cual el resto del código nunca ve el SDK de Firebase
// directamente. La implementación real (`FcmServiceFirebase`) vive en
// `fcm_service_firebase.dart`; los tests usan una fake en memoria.
//
// El método `isAvailable` permite que el repository devuelva Success
// (con dispositivo `null`) cuando el target no soporta FCM —
// principalmente VM de tests y Web sin configuración VAPID — sin
// romper el flujo de login.

import '../../domain/entities/notificacion_payload.dart';
import '../../domain/entities/plataforma_dispositivo.dart';

abstract class FcmService {
  /// `true` si la instancia real de Firebase está disponible. Cuando
  /// es `false`, el wrapper devuelve valores neutros (`null` para
  /// token, `denied` para permisos, streams vacíos) y los consumidores
  /// pueden cortar el flujo sin propagar errores.
  bool get isAvailable;

  /// La plataforma actual del cliente, mapeada al enum del backend.
  PlataformaDispositivo get plataforma;

  /// Pide al usuario permiso de notificaciones (Android 13+, iOS y
  /// macOS lo exigen al primer arranque). Devuelve `true` si el
  /// usuario concedió permiso, `false` en cualquier otro caso
  /// (denied, provisional, not determined, FCM no disponible).
  Future<bool> requestPermission();

  /// Token FCM actual o `null` si FCM no está disponible o el usuario
  /// denegó permisos. En Web requiere VAPID configurado; sin VAPID
  /// devuelve `null` y deja constancia en el log.
  Future<String?> getToken();

  /// Stream que emite el token nuevo cuando FCM lo rota. La sesión
  /// debe suscribirse para reenviar el token actualizado a
  /// `POST /dispositivos`.
  Stream<String> get onTokenRefresh;

  /// Mensaje que abrió la app desde estado "terminated" (banner
  /// tocado con la app cerrada). Se consume una sola vez al
  /// arranque.
  Future<NotificacionPayload?> getInitialMessage();

  /// Stream de mensajes que abren la app desde "background" (banner
  /// tocado con la app en segundo plano).
  Stream<NotificacionPayload> get onMessageOpenedApp;

  /// Stream de mensajes recibidos en "foreground" (app en primer
  /// plano). El SO no muestra banner en este caso; la app puede
  /// pintar un AppSnackbar o refrescar listas.
  Stream<NotificacionPayload> get onForegroundMessage;
}
