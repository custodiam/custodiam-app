// Shell raíz de navegación. Envuelve el StatefulShellRoute.indexedStack
// del router en un Scaffold con:
//
//   - body: el `navigationShell` (renderiza la branch activa)
//   - drawer: lateral con todos los destinos (incluye logout)
//   - bottomNavigationBar: `AppBottomNavBar` con
//       · hamburguesa (abre el drawer)
//       · 3 accesos rápidos al centro (Inicio, Servicios, Inventario)
//       · avatar circular del usuario (lleva a /mi-perfil)
//
// El shell NO impone su propia AppBar superior — cada page mantiene la
// suya con título propio y back automático en subrutas. Material 3
// idiomático con `StatefulShellRoute.indexedStack` y ADR-028 para las
// `K.shell*` que estabilizan los puntos de tap para tests.
//
// `PopScope` intercepta el back físico/gesture cuando se está en una
// branch distinta a Home y salta a Home en lugar de salir de la app —
// patrón Material 3 idiomático para bottom navigation, equivalente al
// "primary destination" behaviour de Gmail / Calendar / Drive.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/auth/app_permission_gate.dart';
import '../../core/ui/feedback/app_confirm_dialog.dart';
import '../../core/ui/navigation/app_bottom_nav_bar.dart';
import '../../core/ui/navigation/app_drawer_header.dart';
import '../../core/ui/navigation/app_nav_bar_icon_button.dart';
import '../../core/ui/navigation/app_navigation_drawer.dart';
import '../../core/ui/theme/app_colors.dart';
import '../../core/ui/tokens/app_spacing.dart';
import '../../features/auth/presentation/viewmodels/auth_di.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/auth/presentation/widgets/auth_failure_feedback.dart';
import '../../infrastructure/auth/current_user.dart';
import '../../infrastructure/auth/permissions.dart';
import '../../infrastructure/error/failure.dart';
import '../test_keys.dart';

/// Índices de cada `StatefulShellBranch` declarada en `router.dart`.
/// Mantenidos juntos para que un cambio en el router se traduzca en
/// un solo punto de edición.
class CustodiamBranchIndex {
  CustodiamBranchIndex._();

  static const int home = 0;
  static const int voluntarios = 1;
  static const int servicios = 2;
  static const int inventario = 3;
  static const int ajustes = 4;
}

class CustodiamShell extends ConsumerWidget {
  const CustodiamShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Snackbar feedback para fallos de auth (logout fallido, sesión
    // expirada). Vive en el shell para sobrevivir cambios de branch
    // y estar disponible independientemente de la page mounted.
    ref.listen<AsyncValue<void>>(authViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is AuthFailure) {
            showAuthFailure(context, error);
          }
        },
      );
    });

    final bool atHome =
        navigationShell.currentIndex == CustodiamBranchIndex.home;

    return PopScope(
      // Si estoy en una branch que NO es Home, intercepto el back y
      // salto a Home en lugar de salir de la app. Solo permito el pop
      // del sistema cuando ya estoy en Home (entonces sí salgo).
      canPop: atHome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        navigationShell.goBranch(
          CustodiamBranchIndex.home,
          initialLocation: true,
        );
      },
      child: Scaffold(
        body: navigationShell,
        drawer: const _CustodiamDrawer(),
        bottomNavigationBar: _CustodiamBottomBar(
          navigationShell: navigationShell,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BottomAppBar (compone AppBottomNavBar + AppNavBarIconButton)
// ---------------------------------------------------------------------------

class _CustodiamBottomBar extends ConsumerWidget {
  const _CustodiamBottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final currentIndex = navigationShell.currentIndex;

    return AppBottomNavBar(
      children: [
        // Hamburguesa abre el drawer con todas las branches.
        Builder(
          builder: (innerContext) => AppNavBarIconButton(
            key: K.shellDrawerButton,
            tooltip: 'Menú',
            icon: Symbols.menu,
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
          ),
        ),
        const Spacer(),
        AppNavBarIconButton(
          key: K.shellHomeButton,
          tooltip: 'Inicio',
          icon: Symbols.home,
          iconSelected: Symbols.home,
          isSelected: currentIndex == CustodiamBranchIndex.home,
          onPressed: () => _goBranch(CustodiamBranchIndex.home),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppPermissionGate(
          permission: Permission.serviciosVerPublicados,
          child: AppNavBarIconButton(
            key: K.shellServiciosButton,
            tooltip: 'Servicios',
            icon: Symbols.emergency,
            iconSelected: Symbols.emergency,
            isSelected: currentIndex == CustodiamBranchIndex.servicios,
            onPressed: () => _goBranch(CustodiamBranchIndex.servicios),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppPermissionGate(
          permission: Permission.inventarioVer,
          child: AppNavBarIconButton(
            key: K.shellInventarioButton,
            tooltip: 'Inventario',
            icon: Symbols.inventory_2,
            iconSelected: Symbols.inventory_2,
            isSelected: currentIndex == CustodiamBranchIndex.inventario,
            onPressed: () => _goBranch(CustodiamBranchIndex.inventario),
          ),
        ),
        const Spacer(),
        AppPermissionGate(
          permission: Permission.voluntariosVerPropio,
          child: _AvatarButton(
            user: user,
            onTap: () => context.go('/mi-perfil'),
          ),
        ),
      ],
    );
  }

  /// Salta a la rama indicada conservando su estado si ya estaba activa,
  /// volviéndola a su initialLocation si se la pulsa estando ya
  /// seleccionada (patrón "tap-twice-to-reset" habitual en Material 3
  /// con `BottomNavigationBar`).
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.user, required this.onTap});

  final CurrentUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = _initial(user);
    return Semantics(
      button: true,
      label: 'Mi perfil',
      child: InkWell(
        key: K.shellAvatarButton,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brand,
            child: initial != null
                ? Text(initial)
                : const Icon(Symbols.person, color: AppColors.brand),
          ),
        ),
      ),
    );
  }

  String? _initial(CurrentUser? user) {
    final name = user?.givenName.trim() ?? '';
    if (name.isEmpty) return null;
    return name.substring(0, 1).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Drawer (compone AppNavigationDrawer + AppDrawerHeader)
// ---------------------------------------------------------------------------

class _CustodiamDrawer extends ConsumerWidget {
  const _CustodiamDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final authState = ref.watch(authViewModelProvider);

    return AppNavigationDrawer(
      header: AppDrawerHeader(displayName: user?.fullName ?? ''),
      destinations: [
        _DrawerTile(
          tileKey: K.drawerHomeTile,
          icon: Symbols.home,
          label: 'Inicio',
          onTap: () => _goAndCloseDrawer(context, '/home'),
        ),
        AppPermissionGate(
          permission: Permission.voluntariosListar,
          child: _DrawerTile(
            tileKey: K.drawerVoluntariosTile,
            icon: Symbols.people,
            label: 'Voluntarios',
            onTap: () => _goAndCloseDrawer(context, '/voluntarios'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.voluntariosVerPropio,
          child: _DrawerTile(
            tileKey: K.drawerMiPerfilTile,
            icon: Symbols.person,
            label: 'Mi perfil',
            onTap: () => _goAndCloseDrawer(context, '/mi-perfil'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.serviciosVerPublicados,
          child: _DrawerTile(
            tileKey: K.drawerServiciosTile,
            icon: Symbols.emergency,
            label: 'Servicios',
            onTap: () => _goAndCloseDrawer(context, '/servicios'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.inventarioVer,
          child: _DrawerTile(
            tileKey: K.drawerInventarioTile,
            icon: Symbols.inventory_2,
            label: 'Inventario',
            onTap: () => _goAndCloseDrawer(context, '/inventario'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.notificacionesConfigurarPropias,
          child: _DrawerTile(
            tileKey: K.drawerNotificacionesTile,
            icon: Symbols.notifications,
            label: 'Notificaciones',
            onTap: () =>
                _goAndCloseDrawer(context, '/ajustes/notificaciones'),
          ),
        ),
        // Capacidades transversales sin pantalla propia todavía. Cada
        // tile está gateado por su permiso RBAC y lleva a una página
        // "Próximamente" (AppComingSoonPage) — da superficie a la
        // capacidad sin prometer una funcionalidad aún no construida.
        AppPermissionGate(
          permission: Permission.sistemaPanelAdmin,
          child: _DrawerTile(
            tileKey: K.drawerAdministracionTile,
            icon: Symbols.admin_panel_settings,
            label: 'Administración',
            onTap: () => _goAndCloseDrawer(context, '/administracion'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.sistemaExportarRgpd,
          child: _DrawerTile(
            tileKey: K.drawerRgpdTile,
            icon: Symbols.privacy_tip,
            label: 'Exportar datos (RGPD)',
            onTap: () => _goAndCloseDrawer(context, '/exportar-rgpd'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.documentalGestionar,
          child: _DrawerTile(
            tileKey: K.drawerDocumentalTile,
            icon: Symbols.folder,
            label: 'Gestión documental',
            onTap: () => _goAndCloseDrawer(context, '/gestion-documental'),
          ),
        ),
        AppPermissionGate(
          permission: Permission.economicoGestionar,
          child: _DrawerTile(
            tileKey: K.drawerEconomicoTile,
            icon: Symbols.payments,
            label: 'Gestión económica',
            onTap: () => _goAndCloseDrawer(context, '/gestion-economica'),
          ),
        ),
        // Ajustes: sin AppPermissionGate por diseño. La página
        // /settings expone preferencias locales (tema, etc.) que no
        // tocan backend ni dependen de RBAC. Documentado para que
        // auditorías futuras no la marquen como falso positivo.
        _DrawerTile(
          tileKey: K.drawerSettingsTile,
          icon: Symbols.settings,
          label: 'Ajustes',
          onTap: () => _goAndCloseDrawer(context, '/settings'),
        ),
      ],
      footer: _DrawerTile(
        tileKey: K.drawerLogoutTile,
        icon: Symbols.logout,
        label: 'Cerrar sesión',
        trailing: authState.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: authState.isLoading ? null : () => _confirmLogout(context, ref),
      ),
    );
  }

  void _goAndCloseDrawer(BuildContext context, String location) {
    Navigator.of(context).pop(); // cierra el drawer
    context.go(location);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cerrar sesión',
      message: '¿Seguro que quieres cerrar sesión? '
          'Tendrás que volver a iniciar sesión para acceder.',
      confirmLabel: 'Cerrar sesión',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    Navigator.of(context).pop(); // cierra el drawer antes del logout
    ref.read(authViewModelProvider.notifier).logout();
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final Key tileKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
