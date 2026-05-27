// Concrete NotificacionesRepository. Combines FcmService + DispositivosApi
// + PreferenciasLocalDataSource. Returns Result<T>; never throws across
// layers. Implements the "opt-in cliente externo" pattern: if FCM is not
// available (VM tests, Web without VAPID, denied permissions), the
// register call returns Success(null) so the login flow never fails
// because of notifications.

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/dispositivo_registrado.dart';
import '../../domain/entities/notificacion_payload.dart';
import '../../domain/entities/preferencias_notificaciones.dart';
import '../../domain/repositories/notificaciones_repository.dart';
import '../datasources/dispositivos_api.dart';
import '../datasources/fcm_service.dart';
import '../datasources/preferencias_local_data_source.dart';
import '../models/dispositivo_registrado_model.dart';

class NotificacionesRepositoryImpl implements NotificacionesRepository {
  final FcmService _fcm;
  final DispositivosApi _api;
  final PreferenciasLocalDataSource _preferencias;

  const NotificacionesRepositoryImpl({
    required FcmService fcm,
    required DispositivosApi api,
    required PreferenciasLocalDataSource preferencias,
  })  : _fcm = fcm,
        _api = api,
        _preferencias = preferencias;

  @override
  Future<Result<DispositivoRegistrado?>> registrarMiDispositivo() async {
    if (!_fcm.isAvailable) {
      dev.log(
        'FcmService no disponible (VM tests / Web sin VAPID / init falló); '
        'registro saltado.',
        name: 'Push',
      );
      return const Success(null);
    }
    final granted = await _fcm.requestPermission();
    if (!granted) {
      dev.log('Permiso de notificaciones denegado; registro saltado.',
          name: 'Push');
      return const Success(null);
    }
    final token = await _fcm.getToken();
    if (token == null || token.isEmpty) {
      dev.log(
        'FCM devolvió token vacío (Web sin VAPID es el caso típico); '
        'registro saltado.',
        name: 'Push',
      );
      return const Success(null);
    }
    try {
      final json = await _api.registrar(
        fcmToken: token,
        plataforma: _fcm.plataforma,
      );
      return Success(DispositivoRegistradoModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'dispositivos.registrar failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<PreferenciasNotificaciones> getPreferencias() {
    return _preferencias.load();
  }

  @override
  Future<void> setPreferencias(PreferenciasNotificaciones preferencias) {
    return _preferencias.save(preferencias);
  }

  @override
  Future<NotificacionPayload?> getInitialMessage() {
    return _fcm.getInitialMessage();
  }

  @override
  Stream<NotificacionPayload> get onMessageOpenedApp =>
      _fcm.onMessageOpenedApp;

  @override
  Stream<NotificacionPayload> get onForegroundMessage =>
      _fcm.onForegroundMessage;

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) return const AuthFailure.sessionExpired();
    return NetworkFailure.serverError(e.statusCode);
  }
}
