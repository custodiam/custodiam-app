// Notificaciones-feature DI. La cadena es algo más larga que en las
// otras features porque combina tres fuentes (FCM, HTTP, prefs
// locales). La selección entre `FcmServiceFirebase` real y
// `FcmServiceUnavailable` se hace en runtime: si la construcción de
// la instancia real falla (Firebase no inicializado), se cae al
// fallback sin error.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/dispositivos_api.dart';
import '../../data/datasources/fcm_service.dart';
import '../../data/datasources/fcm_service_firebase.dart';
import '../../data/datasources/fcm_service_unavailable.dart';
import '../../data/datasources/preferencias_local_data_source.dart';
import '../../data/repositories/notificaciones_repository_impl.dart';
import '../../domain/repositories/notificaciones_repository.dart';
import '../../domain/usecases/get_preferencias_notificaciones.dart';
import '../../domain/usecases/registrar_mi_dispositivo.dart';
import '../../domain/usecases/update_preferencias_notificaciones.dart';

final dispositivosApiProvider = Provider<DispositivosApi>((ref) {
  return DispositivosApi(ref.watch(apiClientProvider));
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmServiceFirebase.tryInstance() ?? const FcmServiceUnavailable();
});

final preferenciasLocalDataSourceProvider =
    Provider<PreferenciasLocalDataSource>((ref) {
  // Cada uso de prefs reabre la misma instancia singleton del paquete.
  return PreferenciasLocalDataSource(SharedPreferences.getInstance());
});

final notificacionesRepositoryProvider =
    Provider<NotificacionesRepository>((ref) {
  return NotificacionesRepositoryImpl(
    fcm: ref.watch(fcmServiceProvider),
    api: ref.watch(dispositivosApiProvider),
    preferencias: ref.watch(preferenciasLocalDataSourceProvider),
  );
});

final registrarMiDispositivoProvider = Provider<RegistrarMiDispositivo>((ref) {
  return RegistrarMiDispositivo(ref.watch(notificacionesRepositoryProvider));
});

final getPreferenciasNotificacionesProvider =
    Provider<GetPreferenciasNotificaciones>((ref) {
  return GetPreferenciasNotificaciones(
    ref.watch(notificacionesRepositoryProvider),
  );
});

final updatePreferenciasNotificacionesProvider =
    Provider<UpdatePreferenciasNotificaciones>((ref) {
  return UpdatePreferenciasNotificaciones(
    ref.watch(notificacionesRepositoryProvider),
  );
});
