// MiPerfilPage (US-02-05).
//
// Read-only view of the authenticated user's full profile. The roles
// section is sourced from CurrentUser (JWT claims) because the
// backend keeps roles out of the VoluntarioResponse payload by
// design (ADR-013 RBAC lockstep).
//
// The "Editar" CTA is wrapped in AppPermissionGate(editar_propio):
// users without the permission see the rest of the page but no
// button. Tap navigates to /mi-perfil/editar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/voluntario.dart';
import '../viewmodels/mi_perfil_view_model.dart';

class MiPerfilPage extends ConsumerWidget {
  const MiPerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosVerPropio,
      fallback: _ForbiddenScreen(),
      child: _MiPerfilPageBody(),
    );
  }
}

class _MiPerfilPageBody extends ConsumerWidget {
  const _MiPerfilPageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(miPerfilViewModelProvider);
    final roles = ref.watch(authServiceProvider).currentUser?.roles ?? const [];

    return AppPageScaffold(
      title: 'Mi perfil',
      actions: [
        IconButton(
          key: const ValueKey('mi_perfil_refresh_button'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(miPerfilViewModelProvider.notifier).refresh(),
        ),
      ],
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is VoluntarioNotFound) {
            return AppEmptyState(
              title: 'Sin perfil',
              description: error.message,
              icon: Icons.person_outline,
            );
          }
          final message =
              error is Failure ? error.message : 'No se pudo cargar el perfil.';
          return AppErrorState(
            title: 'No se pudo cargar tu perfil',
            description: message,
            onRetry: () =>
                ref.read(miPerfilViewModelProvider.notifier).refresh(),
          );
        },
        data: (v) => _ProfileContent(voluntario: v, roles: roles),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Voluntario voluntario;
  final List<String> roles;

  const _ProfileContent({required this.voluntario, required this.roles});

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            child: Text(
              voluntario.nombre.isNotEmpty
                  ? voluntario.nombre[0].toUpperCase()
                  : '?',
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            voluntario.nombre,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: 'Datos personales', children: [
          _Row(label: 'DNI', value: voluntario.dni ?? '—'),
          _Row(
            label: 'Fecha de nacimiento',
            value: _formatDate(voluntario.fechaNacimiento),
          ),
          _Row(
            label: 'Conductor habilitado',
            value: voluntario.conductorHabilitado ? 'Sí' : 'No',
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: 'Contacto', children: [
          _Row(label: 'Teléfono', value: voluntario.telefono),
          _Row(label: 'Email', value: voluntario.email ?? '—'),
          _Row(label: 'Municipio', value: voluntario.municipio),
          _Row(label: 'Dirección', value: voluntario.direccion ?? '—'),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: 'En la agrupación', children: [
          _Row(
            label: 'Alta',
            value: _formatDate(voluntario.fechaAlta),
          ),
          if (voluntario.fechaBaja != null)
            _Row(label: 'Baja', value: _formatDate(voluntario.fechaBaja!)),
          _Row(
            label: 'Roles',
            value: roles.isEmpty ? '—' : roles.join(', '),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        const _MiActividadSection(),
        const SizedBox(height: AppSpacing.xl),
        const AppPermissionGate(
          permission: Permission.voluntariosEditarPropio,
          child: _EditButton(),
        ),
      ],
    );
  }
}

class _MiActividadSection extends StatelessWidget {
  const _MiActividadSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mi actividad', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              AppPermissionGate(
                permission: Permission.fichajeVerPropio,
                child: _ActividadTile(
                  icon: Icons.timer_outlined,
                  label: 'Mis horas',
                  route: '/mi-perfil/horas',
                  keyValue: 'mi_perfil_tile_horas',
                ),
              ),
              AppPermissionGate(
                // Auditoría RBAC (29-may, B1): el tile abre el calendario
                // de gestión, no una vista. secretario/tesorero tienen
                // `voluntariosVerPropio` pero no `voluntariosDisponibilidadPropia`,
                // así que veían el tile y aterrizaban en una pantalla
                // sin toggle activo. Lockstep semántico con el permiso
                // que realmente controla la edición.
                permission: Permission.voluntariosDisponibilidadPropia,
                child: _ActividadTile(
                  icon: Icons.event_available_outlined,
                  label: 'Mi disponibilidad',
                  route: '/mi-perfil/disponibilidad',
                  keyValue: 'mi_perfil_tile_disponibilidad',
                ),
              ),
              AppPermissionGate(
                permission: Permission.voluntariosVerPropio,
                child: _ActividadTile(
                  icon: Icons.history,
                  label: 'Mi historial',
                  route: '/mi-perfil/historial',
                  keyValue: 'mi_perfil_tile_historial',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActividadTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String keyValue;

  const _ActividadTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.keyValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(keyValue),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton();

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      key: const ValueKey('mi_perfil_edit_button'),
      label: 'Editar mis datos de contacto',
      icon: Icons.edit_outlined,
      expanded: true,
      onPressed: () => context.go('/mi-perfil/editar'),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Mi perfil',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar el perfil propio.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
