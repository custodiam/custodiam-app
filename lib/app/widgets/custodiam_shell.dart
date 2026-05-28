// Shell raíz de navegación. Envuelve el StatefulShellRoute.indexedStack
// del router en un Scaffold con:
//
//   - body: el `navigationShell` (renderiza la branch activa)
//   - drawer: lateral con todos los destinos (incluye logout)
//   - bottomNavigationBar: BottomAppBar custom con
//       · hamburguesa (abre el drawer)
//       · 3 accesos rápidos al centro (Inicio, Servicios, Inventario)
//       · avatar circular del usuario (lleva a /mi-perfil)
//
// El shell NO impone su propia AppBar superior — cada page mantiene la
// suya con título propio y back automático en subrutas. Material 3
// idiomático con `StatefulShellRoute.indexedStack` y ADR-028 para las
// `K.shell*` que estabilizan los puntos de tap para tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/auth/app_permission_gate.dart';
import '../../core/ui/feedback/app_confirm_dialog.dart';
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
    // Logout (and any auth-state-affecting action) is triggered from the
    // drawer in this shell, so the snackbar feedback for auth failures
    // lives here at the shell level. This way it survives across branch
    // switches and is available regardless of which page is currently
    // mounted. Previously this listener lived in HomePagePlaceholder.
    ref.listen<AsyncValue<void>>(authViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is AuthFailure) {
            showAuthFailure(context, error);
          }
        },
      );
    });

    return Scaffold(
      body: navigationShell,
      drawer: const _CustodiamDrawer(),
      bottomNavigationBar: _CustodiamBottomBar(
        navigationShell: navigationShell,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BottomAppBar custom
// ---------------------------------------------------------------------------

class _CustodiamBottomBar extends ConsumerWidget {
  const _CustodiamBottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final currentIndex = navigationShell.currentIndex;

    return BottomAppBar(
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // Hamburguesa abre el drawer con todas las branches.
          Builder(
            builder: (innerContext) => IconButton(
              key: K.shellDrawerButton,
              tooltip: 'Menú',
              color: scheme.onPrimary,
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(innerContext).openDrawer(),
            ),
          ),
          const Spacer(),
          _BranchIconButton(
            buttonKey: K.shellHomeButton,
            tooltip: 'Inicio',
            iconSelected: Icons.home,
            iconUnselected: Icons.home_outlined,
            isSelected: currentIndex == CustodiamBranchIndex.home,
            onTap: () => _goBranch(CustodiamBranchIndex.home),
          ),
          AppPermissionGate(
            permission: Permission.serviciosVerPublicados,
            child: _BranchIconButton(
              buttonKey: K.shellServiciosButton,
              tooltip: 'Servicios',
              iconSelected: Icons.event,
              iconUnselected: Icons.event_outlined,
              isSelected: currentIndex == CustodiamBranchIndex.servicios,
              onTap: () => _goBranch(CustodiamBranchIndex.servicios),
            ),
          ),
          AppPermissionGate(
            permission: Permission.inventarioVer,
            child: _BranchIconButton(
              buttonKey: K.shellInventarioButton,
              tooltip: 'Inventario',
              iconSelected: Icons.inventory_2,
              iconUnselected: Icons.inventory_2_outlined,
              isSelected: currentIndex == CustodiamBranchIndex.inventario,
              onTap: () => _goBranch(CustodiamBranchIndex.inventario),
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
      ),
    );
  }

  /// Salta a la rama indicada conservando su estado si ya estaba activa,
  /// volviéndola a su initialLocation si se la pulsa estando ya seleccionada
  /// (patrón "tap-twice-to-reset" habitual en Material 3 con
  /// `BottomNavigationBar`).
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _BranchIconButton extends StatelessWidget {
  const _BranchIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.iconSelected,
    required this.iconUnselected,
    required this.isSelected,
    required this.onTap,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData iconSelected;
  final IconData iconUnselected;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      color: scheme.onPrimary,
      icon: Icon(isSelected ? iconSelected : iconUnselected),
      onPressed: onTap,
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.user, required this.onTap});

  final CurrentUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            backgroundColor: scheme.onPrimary,
            foregroundColor: scheme.primary,
            child: initial != null
                ? Text(initial)
                : Icon(Icons.person, color: scheme.primary),
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
// Drawer lateral con todos los destinos
// ---------------------------------------------------------------------------

class _CustodiamDrawer extends ConsumerWidget {
  const _CustodiamDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final authState = ref.watch(authViewModelProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user, scheme: scheme),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _DrawerTile(
                    tileKey: K.drawerHomeTile,
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    onTap: () => _goAndCloseDrawer(context, '/home'),
                  ),
                  AppPermissionGate(
                    permission: Permission.voluntariosListar,
                    child: _DrawerTile(
                      tileKey: K.drawerVoluntariosTile,
                      icon: Icons.people_outline,
                      label: 'Voluntarios',
                      onTap: () => _goAndCloseDrawer(context, '/voluntarios'),
                    ),
                  ),
                  AppPermissionGate(
                    permission: Permission.voluntariosVerPropio,
                    child: _DrawerTile(
                      tileKey: K.drawerMiPerfilTile,
                      icon: Icons.person_outline,
                      label: 'Mi perfil',
                      onTap: () => _goAndCloseDrawer(context, '/mi-perfil'),
                    ),
                  ),
                  AppPermissionGate(
                    permission: Permission.serviciosVerPublicados,
                    child: _DrawerTile(
                      tileKey: K.drawerServiciosTile,
                      icon: Icons.event_outlined,
                      label: 'Servicios',
                      onTap: () => _goAndCloseDrawer(context, '/servicios'),
                    ),
                  ),
                  AppPermissionGate(
                    permission: Permission.inventarioVer,
                    child: _DrawerTile(
                      tileKey: K.drawerInventarioTile,
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventario',
                      onTap: () => _goAndCloseDrawer(context, '/inventario'),
                    ),
                  ),
                  AppPermissionGate(
                    permission: Permission.notificacionesConfigurarPropias,
                    child: _DrawerTile(
                      tileKey: K.drawerNotificacionesTile,
                      icon: Icons.notifications_outlined,
                      label: 'Notificaciones',
                      onTap: () =>
                          _goAndCloseDrawer(context, '/ajustes/notificaciones'),
                    ),
                  ),
                  _DrawerTile(
                    tileKey: K.drawerSettingsTile,
                    icon: Icons.settings_outlined,
                    label: 'Ajustes',
                    onTap: () => _goAndCloseDrawer(context, '/settings'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerTile(
              tileKey: K.drawerLogoutTile,
              icon: Icons.logout,
              label: 'Cerrar sesión',
              trailing: authState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: authState.isLoading
                  ? null
                  : () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user, required this.scheme});

  final CurrentUser? user;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fullName = user?.fullName ?? '';
    final hasName = fullName.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      color: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.onPrimary,
            foregroundColor: scheme.primary,
            child: hasName
                ? Text(
                    fullName.substring(0, 1).toUpperCase(),
                    style: textTheme.titleLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.person, color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text(
            hasName ? fullName : 'Sesión activa',
            style: textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
          ),
          Text(
            'Custodiam',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
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
