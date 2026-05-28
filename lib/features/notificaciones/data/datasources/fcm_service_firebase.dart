// Implementación real de `FcmService` sobre `firebase_messaging`. Vive
// en un archivo separado para que los tests del repository (que
// inyectan un fake) no arrastren la dependencia ni rompan al ejecutar
// `flutter test` contra una VM sin platform channels.
//
// Si `FirebaseMessaging.instance` no está disponible (Firebase no
// inicializado, plataforma no soportada), el constructor estático
// `tryInstance()` devuelve `null` y el resto del feature opera en
// modo deshabilitado.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';
import '../../domain/entities/notificacion_payload.dart';
import '../../domain/entities/plataforma_dispositivo.dart';
import 'fcm_service.dart';

class FcmServiceFirebase implements FcmService {
  final FirebaseMessaging _messaging;

  FcmServiceFirebase(this._messaging);

  /// Construye una instancia real si Firebase ya está inicializado.
  /// Si la inicialización falló al arranque, devuelve `null` y el
  /// resto del feature usará el modo deshabilitado.
  static FcmServiceFirebase? tryInstance() {
    try {
      return FcmServiceFirebase(FirebaseMessaging.instance);
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isAvailable => true;

  @override
  PlataformaDispositivo get plataforma {
    if (kIsWeb) return PlataformaDispositivo.web;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? PlataformaDispositivo.ios
        : PlataformaDispositivo.android;
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    // En Web `getToken` exige la VAPID key; si el build no la inyecta
    // vía `--dart-define=FCM_VAPID_KEY=...` el SDK devuelve null y el
    // repository entra automáticamente en modo `FcmServiceUnavailable`,
    // por lo que el login NUNCA se rompe por culpa de notificaciones.
    if (kIsWeb) {
      if (EnvConfig.fcmVapidKey.isEmpty) return null;
      return _messaging.getToken(vapidKey: EnvConfig.fcmVapidKey);
    }
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<NotificacionPayload?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toPayload(message);
  }

  @override
  Stream<NotificacionPayload> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toPayload);

  @override
  Stream<NotificacionPayload> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_toPayload);

  NotificacionPayload _toPayload(RemoteMessage message) {
    final data = <String, String>{
      for (final entry in message.data.entries)
        entry.key.toString(): entry.value.toString(),
    };
    return NotificacionPayload(
      tipo: data['tipo'],
      servicioId: data['servicio_id'],
      prioridad: data['prioridad'],
      titulo: message.notification?.title,
      cuerpo: message.notification?.body,
      data: data,
    );
  }
}
