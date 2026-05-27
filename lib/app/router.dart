// App-wide GoRouter configuration.
//
// '/' is SplashPage. It runs DecideStartupDestination (guía 26 §7) and
// navigates to '/home' or '/login' according to the live session.
//
// '/login' is the real LoginPage (EN-01-02 PR B). '/home' is still a
// private placeholder until the dashboard feature lands; it carries
// the logout button so the auth flow can be exercised end-to-end.
//
// '/callback' only exists on web. KeycloakWebAuthService.login() returns
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

import '../core/ui/auth/app_permission_gate.dart';
import '../core/ui/feedback/app_confirm_dialog.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/viewmodels/auth_di.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/auth/presentation/widgets/auth_failure_feedback.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/servicios/presentation/pages/alta_servicio_page.dart';
import '../features/servicios/presentation/pages/servicio_ficha_page.dart';
import '../features/servicios/presentation/pages/servicios_list_page.dart';
import '../features/voluntarios/presentation/pages/alta_voluntario_page.dart';
import '../features/voluntarios/presentation/pages/editar_mi_perfil_page.dart';
import '../features/voluntarios/presentation/pages/mi_perfil_page.dart';
import '../features/voluntarios/presentation/pages/voluntario_ficha_page.dart';
import '../features/voluntarios/presentation/pages/voluntarios_list_page.dart';
import '../infrastructure/auth/keycloak_web_auth_service.dart';
import '../infrastructure/auth/permissions.dart';
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
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, _) => const HomePagePlaceholder(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: '/voluntarios',
        name: 'voluntarios',
        builder: (_, _) => const VoluntariosListPage(),
      ),
      GoRoute(
        path: '/voluntarios/alta',
        name: 'voluntarios-alta',
        builder: (_, _) => const AltaVoluntarioPage(),
      ),
      GoRoute(
        path: '/voluntarios/:id',
        name: 'voluntario-ficha',
        builder: (_, state) => VoluntarioFichaPage(
          voluntarioId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/mi-perfil',
        name: 'mi-perfil',
        builder: (_, _) => const MiPerfilPage(),
      ),
      GoRoute(
        path: '/mi-perfil/editar',
        name: 'mi-perfil-editar',
        builder: (_, _) => const EditarMiPerfilPage(),
      ),
      GoRoute(
        path: '/servicios',
        name: 'servicios',
        builder: (_, _) => const ServiciosListPage(),
      ),
      GoRoute(
        path: '/servicios/alta',
        name: 'servicios-alta',
        builder: (_, _) => const AltaServicioPage(),
      ),
      GoRoute(
        path: '/servicios/:id',
        name: 'servicio-ficha',
        builder: (_, state) => ServicioFichaPage(
          servicioId: state.pathParameters['id']!,
        ),
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

    // Read currentUser from the feature-local wrapper so tests can
    // override the auth source by overriding a single provider.
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final greeting = user?.fullName.isNotEmpty == true
        ? 'Hola, ${user!.fullName}'
        : 'Hola';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custodiam'),
        actions: [
          // Demo de UI condicional (US-01-04): el botón de "Voluntarios"
          // solo aparece para quien tiene voluntarios.listar — ver
          // matriz en docs/trabajo/backlog/RBAC_v0.1.0.md.
          AppPermissionGate(
            permission: Permission.voluntariosListar,
            child: IconButton(
              key: const ValueKey('home_voluntarios_button'),
              tooltip: 'Voluntarios',
              icon: const Icon(Icons.people_outline),
              onPressed: () => context.go('/voluntarios'),
            ),
          ),
          AppPermissionGate(
            permission: Permission.serviciosVerPublicados,
            child: IconButton(
              key: const ValueKey('home_servicios_button'),
              tooltip: 'Servicios',
              icon: const Icon(Icons.event_outlined),
              onPressed: () => context.go('/servicios'),
            ),
          ),
          AppPermissionGate(
            permission: Permission.voluntariosVerPropio,
            child: IconButton(
              key: const ValueKey('home_mi_perfil_button'),
              tooltip: 'Mi perfil',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/mi-perfil'),
            ),
          ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Custodiam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(greeting),
            const SizedBox(height: 8),
            const Text('Protección Civil — MVP en desarrollo'),
            const SizedBox(height: 24),
            // Banner solo visible para mandos altos / coordinador.
            const AppPermissionGate.anyOf(
              anyOf: [
                Permission.serviciosCrearEmergencia,
                Permission.serviciosConvocar,
              ],
              child: _ComandoOperativoBanner(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComandoOperativoBanner extends StatelessWidget {
  const _ComandoOperativoBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('home_comando_banner'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Tienes capacidad de mando operativo activa.',
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
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
    // On web the provider always returns KeycloakWebAuthService; the
    // `is` cast is defensive so a test that overrides the provider with
    // a fake AuthService that does not implement handleWebCallback
    // simply skips the exchange and falls through to the redirect.
    if (authService is KeycloakWebAuthService) {
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
