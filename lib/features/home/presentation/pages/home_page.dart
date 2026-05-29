// Dashboard básico tras login. Es la rama 0 del StatefulShellRoute
// (ver lib/app/router.dart). Sustituye al antiguo HomePagePlaceholder.
//
// Contenido en F1 (remediación de navegación):
//   - Saludo con el nombre del usuario
//   - Banner de mando operativo (solo para roles con serviciosCrearEmergencia
//     o serviciosConvocar)
//   - Dos accesos rápidos: editar disponibilidad propia y ver próximos servicios
//
// El logout vive en el drawer (lib/app/widgets/custodiam_shell.dart),
// no en el AppBar de esta page, para no duplicarlo entre cada rama.
//
// El layout más rico del dashboard (calendario superior, comunicados,
// secciones por rol) es feature funcional futura que aún no se ha
// definido — se aborda como User Story propia, no aquí.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/cards/app_quick_action_card.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../auth/presentation/viewmodels/auth_di.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceForViewModelProvider).currentUser;
    final greeting = (user?.fullName.isNotEmpty ?? false)
        ? 'Hola, ${user!.fullName}'
        : 'Hola';

    return AppPageScaffold(
      title: 'Custodiam',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              const SizedBox(height: AppSpacing.md),
              const Icon(Icons.shield, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Custodiam',
                key: const ValueKey('home_title'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                greeting,
                key: K.homeGreeting,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Protección Civil — MVP en desarrollo',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppPermissionGate.anyOf(
                anyOf: [
                  Permission.serviciosCrearEmergencia,
                  Permission.serviciosConvocar,
                ],
                child: _ComandoOperativoBanner(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Auditoría RBAC (29-may, hallazgo D2): el banner sólo
              // informaba; ahora ofrece atajo a "Crear emergencia".
              // Una emergencia se mide en segundos: ahorra
              // drawer → Servicios → +. El query param `?tipo=emergencia`
              // hace que el alta abra con el tipo ya seleccionado.
              AppPermissionGate(
                permission: Permission.serviciosCrearEmergencia,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppQuickActionCard(
                    key: K.homeQuickActionEmergencia,
                    icon: MdiIcons.alarmLight,
                    title: 'Crear emergencia',
                    subtitle:
                        'Genera un servicio de emergencia y convoca al equipo.',
                    onTap: () =>
                        context.go('/servicios/alta?tipo=emergencia'),
                  ),
                ),
              ),
              AppPermissionGate(
                permission: Permission.voluntariosDisponibilidadPropia,
                child: AppQuickActionCard(
                  key: K.homeQuickActionDisponibilidad,
                  icon: Icons.event_available_outlined,
                  title: 'Editar mi disponibilidad',
                  subtitle: 'Marca las fechas en las que estás disponible.',
                  onTap: () => context.go('/mi-perfil/disponibilidad'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPermissionGate(
                permission: Permission.serviciosVerPublicados,
                child: AppQuickActionCard(
                  key: K.homeQuickActionServicios,
                  icon: MdiIcons.alarmLightOutline,
                  title: 'Ver próximos servicios',
                  subtitle: 'Servicios publicados a los que puedes apuntarte.',
                  onTap: () => context.go('/servicios'),
                ),
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
      key: K.homeBannerMando,
      padding: const EdgeInsets.all(AppSpacing.smMd),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.smMd),
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

