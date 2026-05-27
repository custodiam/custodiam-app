// Widget que envuelve la app y ata el ciclo FCM al ciclo de auth.
//
// US-06-04: cuando `authService.isAuthenticated` pasa a true, dispara
// `RegistrarMiDispositivo` para que el token FCM quede registrado en
// el backend. El use case es idempotente y devuelve Success(null) si
// FCM no está disponible o el usuario denegó el permiso — en
// cualquier caso el flujo de login NUNCA se rompe por culpa de las
// notificaciones.
//
// US-06-01/02: escucha tres fuentes de mensajes (initial, opened from
// background, foreground) y navega a `/servicios/{servicio_id}`
// cuando el payload trae uno. El foreground también dispara un
// AppSnackbar para que el usuario vea la notificación sin tener que
// minimizar la app.

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/notificacion_payload.dart';
import '../viewmodels/notificaciones_di.dart';

class FcmBootstrap extends ConsumerStatefulWidget {
  final Widget child;
  const FcmBootstrap({super.key, required this.child});

  @override
  ConsumerState<FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends ConsumerState<FcmBootstrap> {
  StreamSubscription<NotificacionPayload>? _openedSub;
  StreamSubscription<NotificacionPayload>? _foregroundSub;
  bool _initialChecked = false;
  bool _registeredOnce = false;
  VoidCallback? _authListener;
  // Cacheamos el ValueListenable para poder darnos de baja en
  // `dispose` sin tocar `ref` — Riverpod marca el `ref` como
  // inválido durante el ciclo de dispose y lanza StateError si lo
  // tocamos ahí (regresión detectada por el smoke `app_test.dart`).
  Listenable? _authListenable;

  @override
  void initState() {
    super.initState();
    // El registro se dispara escuchando el ValueListenable de auth.
    // ref.listen no está disponible en initState, así que usamos el
    // listenable directamente; lo arrancamos en post-frame para que
    // el árbol esté montado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Si el widget se desmontó antes del frame (típico en widget
      // tests rápidos), no continuamos: tocar `ref` aquí también
      // dispararía el StateError del Riverpod ConsumerStatefulElement.
      if (!mounted) return;
      _bindAuthListener();
      _bindMessageStreams();
      _checkInitialMessage();
    });
  }

  void _bindAuthListener() {
    final authService = ref.read(authServiceProvider);
    final listenable = authService.authStateListenable;
    _authListenable = listenable;
    _authListener = () {
      if (authService.isAuthenticated && !_registeredOnce) {
        _registeredOnce = true;
        _registerDevice();
      }
      if (!authService.isAuthenticated) {
        // Permite re-registro en el siguiente login (p. ej. tras
        // logout + relogin con otro usuario).
        _registeredOnce = false;
      }
    };
    listenable.addListener(_authListener!);
    // Dispara una vez por si la sesión ya estaba activa cuando este
    // widget se montó (caso restoreSession en SplashPage).
    _authListener!();
  }

  Future<void> _registerDevice() async {
    final usecase = ref.read(registrarMiDispositivoProvider);
    final result = await usecase();
    switch (result) {
      case Success(:final value):
        if (value == null) {
          dev.log('FCM no disponible o permiso denegado.', name: 'Push');
        } else {
          dev.log(
            'Dispositivo FCM registrado: ${value.id} (${value.plataforma.wire})',
            name: 'Push',
          );
        }
      case Fail(:final failure):
        // Si el backend devuelve 401 el refreshListenable ya bouncea
        // al login; aquí solo dejamos rastro.
        dev.log(
          'Registro de dispositivo FCM falló: ${failure.message}',
          name: 'Push',
        );
    }
  }

  void _bindMessageStreams() {
    final repo = ref.read(notificacionesRepositoryProvider);
    _openedSub = repo.onMessageOpenedApp.listen(_handleOpenedMessage);
    _foregroundSub =
        repo.onForegroundMessage.listen(_handleForegroundMessage);
  }

  Future<void> _checkInitialMessage() async {
    if (_initialChecked) return;
    _initialChecked = true;
    final repo = ref.read(notificacionesRepositoryProvider);
    final payload = await repo.getInitialMessage();
    if (payload != null && mounted) {
      _navigateForPayload(payload);
    }
  }

  void _handleOpenedMessage(NotificacionPayload payload) {
    if (!mounted) return;
    _navigateForPayload(payload);
  }

  void _handleForegroundMessage(NotificacionPayload payload) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final titulo = payload.titulo ?? 'Notificación';
    final cuerpo = payload.cuerpo;
    AppSnackbar.show(
      context,
      message: cuerpo == null || cuerpo.isEmpty ? titulo : '$titulo · $cuerpo',
      variant: payload.tipo == 'emergencia'
          ? AppSnackbarVariant.danger
          : AppSnackbarVariant.info,
    );
  }

  void _navigateForPayload(NotificacionPayload payload) {
    final servicioId = payload.servicioId;
    if (servicioId == null || servicioId.isEmpty) return;
    final router = ref.read(routerProvider);
    router.go('/servicios/$servicioId');
  }

  @override
  void dispose() {
    // No tocar `ref` aquí: Riverpod lo marca como inválido durante el
    // ciclo de dispose. Usamos la referencia cacheada al Listenable
    // capturada en `_bindAuthListener`. El smoke `test/app/app_test.dart`
    // detectó este StateError al hacer pumpWidget rápido seguido de
    // tear-down (rebuild del árbol antes del primer frame).
    final listener = _authListener;
    final listenable = _authListenable;
    if (listener != null && listenable != null) {
      try {
        listenable.removeListener(listener);
      } catch (e) {
        debugPrint('FcmBootstrap.dispose: removeListener fallback — $e');
      }
    }
    _openedSub?.cancel();
    _foregroundSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
