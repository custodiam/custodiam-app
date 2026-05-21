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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/feedback/app_snackbar.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../infrastructure/auth/keycloak_auth_service.dart';
import '../infrastructure/di/providers.dart';
import '../infrastructure/error/failure.dart';

final router = GoRouter(
  initialLocation: '/',
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
      builder: (_, __) => const _HomePagePlaceholder(),
    ),
    if (kIsWeb)
      GoRoute(
        path: '/callback',
        name: 'callback',
        builder: (_, state) => _CallbackHandler(callbackUri: state.uri),
      ),
  ],
);

class _HomePagePlaceholder extends ConsumerWidget {
  const _HomePagePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AsyncValue<void>>(authViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is AuthFailure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'Error al cerrar sesión',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
        data: (_) {
          // After logout the AuthService has cleared the session, so the
          // home page is no longer valid for this user. Bounce to /login.
          if (prev is AsyncLoading) {
            context.go('/login');
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custodiam'),
        actions: [
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
                : () =>
                    ref.read(authViewModelProvider.notifier).logout(),
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
