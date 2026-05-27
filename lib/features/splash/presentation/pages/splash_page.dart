// SplashPage is the app's initial route. It renders the brand colour
// + shield while AppStartupUseCase runs and then navigates to /home
// or /login based on session state. Per guide 26 §7.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/decide_startup_destination.dart';
import '../viewmodels/app_startup_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final destination = await ref.read(appStartupProvider.future);
    if (!mounted) return;

    switch (destination) {
      case StartupDestination.home:
        context.go('/home');
      case StartupDestination.login:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        // Logo de la app sobre el color brand. El PNG tiene fondo
        // transparente, así que el color del Scaffold se ve a través
        // del logo y mantiene continuidad visual con el splash nativo
        // (que es solo color, sin imagen, configurado en pubspec.yaml
        // → flutter_native_splash). El width fijo garantiza que el
        // logo no se estire en pantallas pequeñas y que en tablet
        // siga proporcionado; la guía 29 §3 prefiere tamaños fijos
        // en assets de marca antes que escalado fraccional.
        child: Image.asset(
          'assets/logo.png',
          width: 160,
          height: 160,
          semanticLabel: 'Custodiam',
        ),
      ),
    );
  }
}
