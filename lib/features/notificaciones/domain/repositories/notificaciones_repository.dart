// Repository contract for the notificaciones feature. Combines two
// data sources behind a single interface so the rest of the app never
// imports FirebaseMessaging directly:
//
//   1. FcmService — wraps FirebaseMessaging (token, permission, streams).
//   2. DispositivosApi — registers/unregisters tokens against the backend.
//   3. Local preferences — shared_preferences with the US-06-03 toggles.
//
// All methods return Result<T>; implementations never throw across layers.

import '../../../../infrastructure/error/result.dart';
import '../entities/dispositivo_registrado.dart';
import '../entities/notificacion_payload.dart';
import '../entities/preferencias_notificaciones.dart';

abstract class NotificacionesRepository {
  /// US-06-04: si el usuario concedió permiso, obtiene el token FCM y
  /// lo registra contra `POST /dispositivos`. El backend es idempotente
  /// (no falla si ya existe el token); el cliente trata como Success
  /// también los modos "FCM deshabilitado en este target" para que el
  /// flujo de login nunca se rompa por culpa de notificaciones.
  ///
  /// Devuelve `null` (envuelto en Success) cuando FCM no está disponible
  /// en el target (VM de tests, Web sin VAPID configurada) o cuando el
  /// usuario denegó los permisos. La página de ajustes lo trata como
  /// "registro saltado" y muestra un aviso suave.
  Future<Result<DispositivoRegistrado?>> registrarMiDispositivo();

  /// US-06-03 (parte 1): cargar las preferencias locales del usuario.
  Future<PreferenciasNotificaciones> getPreferencias();

  /// US-06-03 (parte 2): guardar las preferencias locales.
  Future<void> setPreferencias(PreferenciasNotificaciones preferencias);

  /// US-06-01/02 (parte 1): la notificación que abrió la app desde un
  /// estado "terminated" (touch en banner cuando la app no estaba
  /// abierta). El bootstrap consulta este valor una sola vez al
  /// arrancar.
  Future<NotificacionPayload?> getInitialMessage();

  /// US-06-01/02 (parte 2): stream de notificaciones que abren la app
  /// desde "background" (el usuario tocó el banner con la app en
  /// segundo plano). El handler global escucha aquí.
  Stream<NotificacionPayload> get onMessageOpenedApp;

  /// US-06-01/02 (parte 3, opcional): stream de notificaciones que
  /// llegan con la app en "foreground" (el usuario está mirando la
  /// app). Útil para refrescar listas sin esperar a que el usuario
  /// pulse algo.
  Stream<NotificacionPayload> get onForegroundMessage;
}
