// Ata el ciclo de datos al ciclo de sesión: cuando el usuario CIERRA sesión
// (o la sesión expira), invalida los providers cuyo estado pertenece al
// usuario saliente, para que la cuenta siguiente no vea datos cacheados de
// la anterior (bug "salgo de una cuenta y entro en otra y veo lo del
// usuario previo").
//
// Patrón idiomático Riverpod (FAQ oficial + issues del autor): no se recrea
// el ProviderScope (anti-patrón); se invalidan los providers afectados al
// cambiar la sesión. La lista vive en infrastructure/di/user_scoped_providers.dart.
//
// Se monta FUERA del shell (envolviendo MaterialApp, igual que FcmBootstrap)
// para sobrevivir al desmontaje del shell durante el logout. Comparte la
// señal `authStateListenable` con FcmBootstrap (registro FCM): son listeners
// distintos sobre el mismo ValueNotifier, por motivos distintos.

import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/di/providers.dart';
import '../../infrastructure/di/user_scoped_providers.dart';

class AuthLifecycleListener extends ConsumerStatefulWidget {
  final Widget child;
  const AuthLifecycleListener({super.key, required this.child});

  @override
  ConsumerState<AuthLifecycleListener> createState() =>
      _AuthLifecycleListenerState();
}

class _AuthLifecycleListenerState extends ConsumerState<AuthLifecycleListener> {
  VoidCallback? _listener;
  // Cacheado para des-suscribir en `dispose` SIN tocar `ref`: Riverpod marca
  // el `ref` como inválido durante el dispose y lanza StateError si se toca
  // (misma regresión documentada en FcmBootstrap).
  Listenable? _listenable;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // ref.listen no está disponible en initState; usamos el Listenable
    // directamente en post-frame, con el árbol ya montado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bind();
    });
  }

  void _bind() {
    final authService = ref.read(authServiceProvider);
    final listenable = authService.authStateListenable;
    _listenable = listenable;
    // M1: inicializar el flag con el valor REAL en el momento del bind (NO a
    // un literal). Y NO disparar el listener al montar: invalidar al arrancar
    // con sesión restaurada tiraría las listas recién cargadas, y arrancar sin
    // sesión fabricaría un `true→false` espurio.
    _wasAuthenticated = authService.isAuthenticated;
    _listener = () {
      final now = authService.isAuthenticated;
      // Solo en la transición autenticado → no autenticado (logout real o
      // refresh de token muerto). El login (false→true) y el refresh exitoso
      // (true→true, que ValueNotifier ni siquiera notifica) no invalidan.
      if (_wasAuthenticated && !now) {
        resetUserScopedProviders(ref.invalidate);
        dev.log(
          'Sesión cerrada: estado de datos del usuario invalidado.',
          name: 'Auth',
        );
      }
      _wasAuthenticated = now;
    };
    listenable.addListener(_listener!);
  }

  @override
  void dispose() {
    final listener = _listener;
    final listenable = _listenable;
    if (listener != null && listenable != null) {
      try {
        listenable.removeListener(listener);
      } catch (e) {
        dev.log(
          'AuthLifecycleListener.dispose: removeListener fallback — $e',
          name: 'Auth',
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
