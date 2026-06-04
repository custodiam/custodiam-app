import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key global del `ScaffoldMessenger` raíz, asociada a
/// `MaterialApp.scaffoldMessengerKey`. Permite mostrar SnackBars desde
/// handlers que viven POR ENCIMA del árbol de `MaterialApp` —como el de
/// notificaciones FCM en primer plano (`FcmBootstrap`)—, donde
/// `ScaffoldMessenger.of(context)` no encontraría ningún messenger.
///
/// Vive en su propio archivo (sin dependencias de `app.dart` ni de las
/// features) para que tanto el widget raíz como `FcmBootstrap` lo
/// importen sin crear un ciclo de imports.
final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  return GlobalKey<ScaffoldMessengerState>();
});
