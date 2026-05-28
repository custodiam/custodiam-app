// App-wide GoRouter configuration with `StatefulShellRoute.indexedStack`.
//
// The router has three top-level routes outside the shell (splash, login,
// callback) and five branches inside the shell:
//
//   Branch 0 — Inicio:       /home
//   Branch 1 — Voluntarios:  /voluntarios{,/alta,/:id}, /mi-perfil{,/editar,
//                            /horas,/disponibilidad,/historial}
//   Branch 2 — Servicios:    /servicios{,/alta,/:id{,/fichaje}}
//   Branch 3 — Inventario:   /inventario{,/material{/alta,/:id},/vehiculos{
//                            /alta,/:id}}
//   Branch 4 — Ajustes:      /settings, /ajustes/notificaciones
//
// Each branch owns its own Navigator. `context.go('/voluntarios/123')`
// pushes onto the voluntarios branch stack, so the Android system back
// button and iOS swipe-back gesture work to return to `/voluntarios`
// — the bug that the flat-routes + `context.go(...)` previous setup
// produced (no back stack ever materialised because go() replaced
// instead of pushing). Branch state (scroll position, in-progress
// forms) survives across branch switches because IndexedStack keeps
// the inactive branches alive.
//
// The shell itself (Scaffold with BottomAppBar + drawer) lives in
// `CustodiamShell` (`widgets/custodiam_shell.dart`).
//
// Per ADR-013 the redirect still bounces protected routes to /login
// when AuthService.authStateListenable fires (logout, refresh-token
// expiry mid-session). The `LoginPage` consumes
// `AuthService.consumeExpiredFlag()` to decide whether to show the
// "sesión expirada" banner.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/disponibilidad/presentation/pages/mi_disponibilidad_page.dart';
import '../features/fichaje/presentation/pages/fichaje_en_servicio_page.dart';
import '../features/fichaje/presentation/pages/mis_horas_page.dart';
import '../features/historial/presentation/pages/mi_historial_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/inventario/presentation/pages/alta_material_page.dart';
import '../features/inventario/presentation/pages/alta_vehiculo_page.dart';
import '../features/inventario/presentation/pages/inventario_list_page.dart';
import '../features/inventario/presentation/pages/material_ficha_page.dart';
import '../features/inventario/presentation/pages/vehiculo_ficha_page.dart';
import '../features/notificaciones/presentation/pages/notificaciones_ajustes_page.dart';
import '../features/servicios/presentation/pages/alta_servicio_page.dart';
import '../features/servicios/presentation/pages/servicio_ficha_page.dart';
import '../features/servicios/presentation/pages/servicios_list_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/voluntarios/presentation/pages/alta_voluntario_page.dart';
import '../features/voluntarios/presentation/pages/editar_mi_perfil_page.dart';
import '../features/voluntarios/presentation/pages/mi_perfil_page.dart';
import '../features/voluntarios/presentation/pages/voluntario_ficha_page.dart';
import '../features/voluntarios/presentation/pages/voluntarios_list_page.dart';
import '../infrastructure/auth/keycloak_web_auth_service.dart';
import '../infrastructure/di/providers.dart';
import 'widgets/custodiam_shell.dart';

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
      if (kIsWeb)
        GoRoute(
          path: '/callback',
          name: 'callback',
          builder: (_, state) => _CallbackHandler(callbackUri: state.uri),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CustodiamShell(
          navigationShell: navigationShell,
        ),
        branches: [
          // ---------- Branch 0 — Inicio --------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          // ---------- Branch 1 — Voluntarios + Mi perfil ---------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/voluntarios',
                name: 'voluntarios',
                builder: (_, _) => const VoluntariosListPage(),
                routes: [
                  GoRoute(
                    path: 'alta',
                    name: 'voluntarios-alta',
                    builder: (_, _) => const AltaVoluntarioPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'voluntario-ficha',
                    builder: (_, state) => VoluntarioFichaPage(
                      voluntarioId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/mi-perfil',
                name: 'mi-perfil',
                builder: (_, _) => const MiPerfilPage(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    name: 'mi-perfil-editar',
                    builder: (_, _) => const EditarMiPerfilPage(),
                  ),
                  GoRoute(
                    path: 'horas',
                    name: 'mi-perfil-horas',
                    builder: (_, _) => const MisHorasPage(),
                  ),
                  GoRoute(
                    path: 'disponibilidad',
                    name: 'mi-perfil-disponibilidad',
                    builder: (_, _) => const MiDisponibilidadPage(),
                  ),
                  GoRoute(
                    path: 'historial',
                    name: 'mi-perfil-historial',
                    builder: (_, _) => const MiHistorialPage(),
                  ),
                ],
              ),
            ],
          ),
          // ---------- Branch 2 — Servicios -----------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servicios',
                name: 'servicios',
                builder: (_, _) => const ServiciosListPage(),
                routes: [
                  GoRoute(
                    path: 'alta',
                    name: 'servicios-alta',
                    builder: (_, _) => const AltaServicioPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'servicio-ficha',
                    builder: (_, state) => ServicioFichaPage(
                      servicioId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'fichaje',
                        name: 'servicio-fichaje',
                        builder: (_, state) => FichajeEnServicioPage(
                          servicioId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // ---------- Branch 3 — Inventario ----------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventario',
                name: 'inventario',
                builder: (_, _) => const InventarioListPage(),
                routes: [
                  GoRoute(
                    path: 'material/alta',
                    name: 'inventario-material-alta',
                    builder: (_, _) => const AltaMaterialPage(),
                  ),
                  GoRoute(
                    path: 'material/:id',
                    name: 'inventario-material-ficha',
                    builder: (_, state) => MaterialFichaPage(
                      materialId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'vehiculos/alta',
                    name: 'inventario-vehiculo-alta',
                    builder: (_, _) => const AltaVehiculoPage(),
                  ),
                  GoRoute(
                    path: 'vehiculos/:id',
                    name: 'inventario-vehiculo-ficha',
                    builder: (_, state) => VehiculoFichaPage(
                      vehiculoId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ---------- Branch 4 — Ajustes -------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (_, _) => const SettingsPage(),
              ),
              GoRoute(
                path: '/ajustes/notificaciones',
                name: 'ajustes-notificaciones',
                builder: (_, _) => const NotificacionesAjustesPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

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
