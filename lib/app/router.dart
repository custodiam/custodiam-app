// App-wide GoRouter configuration.
//
// '/' is SplashPage. It runs DecideStartupDestination (guía 26 §7) and
// navigates to '/home' or '/login' according to the live session.
//
// '/login' is the real LoginPage (EN-01-02 PR B). '/home' is still a
// private placeholder until the dashboard feature lands; it carries
// the logout button so the auth flow can be exercised end-to-end.
//
// '/callback' only exists on web. KeycloakAuthService.login() returns
// immediately after launching the browser; the redirect lands here and
// _CallbackHandler completes the authorization-code exchange before
// pushing the user to /home (or back to /login on failure).
//
// US-01-03: the GoRouter is wrapped in a Riverpod Provider so it can
// observe AuthService.authStateListenable and run a redirect every
// time the auth state flips. When a refresh-token expires mid-session,
// the protected routes auto-bounce to /login. LoginPage then reads
// AuthService.consumeExpiredFlag() to decide whether to show the
// "sesión expirada" banner.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/feedback/app_confirm_dialog.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/widgets/auth_failure_feedback.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../infrastructure/auth/keycloak_auth_service.dart';
import '../infrastructure/di/providers.dart';
import '../infrastructure/error/failure.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService.authStateListenable,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isProtected = loc != '/' && loc != '/login' && loc != '/callback';
      if (!authService.isAuthenticated && isProtected) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomePagePlaceholder(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsPage(),
      ),
      if (kIsWeb)
        GoRoute(
          path: '/callback',
          name: 'callback',
          builder: (_, state) => _CallbackHandler(callbackUri: state.uri),
        ),
    ],
  );
});

/// Stand-in for the dashboard until the real home feature lands.
/// Public so widget tests can mount the logout flow without spinning
/// up the full router. Will be replaced when the home feature is built
/// (Sprint 4+).
class HomePagePlaceholder extends ConsumerWidget {
  const HomePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AsyncValue<void>>(authViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is AuthFailure) {
            showAuthFailure(context, error);
          }
        },
      );
    });
    // Note: success-path navigation to /login is handled by the
    // router's redirect (US-01-03). AuthService publishes the auth
    // flip; refreshListenable picks it up and bounces protected routes.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custodiam'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: authState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            onPressed: authState.isLoading
                ? null
                : () async {
                    final confirmed = await AppConfirmDialog.show(
                      context,
                      title: 'Cerrar sesión',
                      message:
                          '¿Seguro que quieres cerrar sesión? Tendrás que '
                          'volver a iniciar sesión para acceder.',
                      confirmLabel: 'Cerrar sesión',
                      isDestructive: true,
                    );
                    if (!confirmed) return;
                    if (!context.mounted) return;
                    ref.read(authViewModelProvider.notifier).logout();
                  },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 64),
            SizedBox(height: 16),
            Text(
              'Custodiam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Protección Civil — MVP en desarrollo'),
          ],
        ),
      ),
    );
  }
}

class _CallbackHandler extends ConsumerStatefulWidget {
  const _CallbackHandler({required this.callbackUri});

  final Uri callbackUri;

  @override
  ConsumerState<_CallbackHandler> createState() => _CallbackHandlerState();
}

class _CallbackHandlerState extends ConsumerState<_CallbackHandler> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_handleCallback);
  }

  Future<void> _handleCallback() async {
    final authService = ref.read(authServiceProvider);
    if (authService is KeycloakAuthService) {
      await authService.handleWebCallback(widget.callbackUri);
    }
    if (!mounted) return;
    context.go(authService.isAuthenticated ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
