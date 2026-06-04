// Implementación real de [LocalNotificationsService] sobre
// `flutter_local_notifications` (Android) + `firebase_messaging` (opciones
// de presentación foreground en iOS). Vive en archivo aparte para que los
// tests del bootstrap/repository inyecten un fake sin arrastrar la
// dependencia ni romper `flutter test` en una VM sin platform channels.

import 'dart:developer' as dev;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notifications_service.dart';

class LocalNotificationsServiceFlutter implements LocalNotificationsService {
  LocalNotificationsServiceFlutter([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // El sonido, la vibración y el heads-up son inmutables tras crear el
  // canal en Android 8+: cambiarlos exige reinstalar. Si en el futuro se
  // quiere un sonido de emergencia distinto, crear un canal con id nuevo.
  static const AndroidNotificationChannel _canalEmergencias =
      AndroidNotificationChannel(
    kCanalEmergencias,
    'Emergencias',
    description: 'Activaciones y alertas urgentes de Protección Civil.',
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _canalAvisos =
      AndroidNotificationChannel(
    kCanalAvisos,
    'Avisos',
    description: 'Notificaciones de servicios y avisos generales.',
    importance: Importance.defaultImportance,
  );

  @override
  Future<void> init({
    required void Function(String? servicioId) onTapServicio,
  }) async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          // Sin pedir permisos en iOS: firebase_messaging.requestPermission()
          // ya los solicita; pedirlos aquí dispararía un segundo diálogo.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onTapServicio(response.payload),
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(_canalEmergencias);
        await android.createNotificationChannel(_canalAvisos);
      }

      // iOS/macOS: que el sistema muestre el banner heads-up en primer
      // plano (no-op en Android).
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initialized = true;
    } catch (e, stack) {
      dev.log(
        'LocalNotificationsService.init falló '
        '(esperado en VM/web sin platform channels): $e',
        name: 'Push',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> mostrarEmergencia({
    required String titulo,
    required String cuerpo,
    String? servicioId,
  }) async {
    // En iOS el banner foreground lo pinta el sistema vía las presentation
    // options; duplicarlo con el plugin daría una notificación doble.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _plugin.show(
        id: (servicioId ?? '$titulo$cuerpo').hashCode,
        title: titulo,
        body: cuerpo,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _canalEmergencias.id,
            _canalEmergencias.name,
            channelDescription: _canalEmergencias.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: servicioId,
      );
    } catch (e, stack) {
      dev.log(
        'LocalNotificationsService.mostrarEmergencia falló: $e',
        name: 'Push',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
