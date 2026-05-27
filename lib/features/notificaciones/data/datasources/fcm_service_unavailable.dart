// Fallback usado cuando Firebase no está disponible (VM tests, Web sin
// VAPID, Firebase init falló). Devuelve valores neutros para que el
// resto del feature opere sin propagar errores.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/notificacion_payload.dart';
import '../../domain/entities/plataforma_dispositivo.dart';
import 'fcm_service.dart';

class FcmServiceUnavailable implements FcmService {
  const FcmServiceUnavailable();

  @override
  bool get isAvailable => false;

  @override
  PlataformaDispositivo get plataforma {
    if (kIsWeb) return PlataformaDispositivo.web;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? PlataformaDispositivo.ios
        : PlataformaDispositivo.android;
  }

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<NotificacionPayload?> getInitialMessage() async => null;

  @override
  Stream<NotificacionPayload> get onMessageOpenedApp => const Stream.empty();

  @override
  Stream<NotificacionPayload> get onForegroundMessage => const Stream.empty();
}
