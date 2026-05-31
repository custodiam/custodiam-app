// NotificacionesAjustesPage (US-06-03). Tres toggles: emergencias
// (informativo, siempre ON), nuevos servicios y recordatorios.
// Guardado automático en `shared_preferences` al cambiar el switch.
//
// El acceso está gateado por `notificaciones.configurar_propias`,
// permiso que todos los roles humanos tienen según la matriz RBAC
// v0.1.0 (incluido el voluntario en prácticas).

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../viewmodels/notificaciones_ajustes_view_model.dart';

class NotificacionesAjustesPage extends ConsumerWidget {
  const NotificacionesAjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.notificacionesConfigurarPropias,
      fallback: _ForbiddenScreen(),
      child: _AjustesBody(),
    );
  }
}

class _AjustesBody extends ConsumerWidget {
  const _AjustesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(notificacionesAjustesViewModelProvider);

    ref.listen(notificacionesAjustesViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudieron guardar los ajustes.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      title: 'Notificaciones',
      body: asyncState.when(
        loading: () => const AppLoadingIndicator.fullScreen(),
        error: (error, _) => AppErrorState(
          title: 'No se pudieron cargar los ajustes',
          description: error is Failure ? error.message : null,
          onRetry: () =>
              ref.read(notificacionesAjustesViewModelProvider.notifier),
        ),
        data: (prefs) => _AjustesContent(prefs: prefs),
      ),
    );
  }
}

class _AjustesContent extends ConsumerWidget {
  final dynamic prefs;
  const _AjustesContent({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Elige qué notificaciones quieres recibir en este dispositivo. '
          'Las emergencias se reciben SIEMPRE mientras el sistema permita '
          'notificaciones a la app.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Toggle informativo: las emergencias no se pueden deshabilitar
        // desde la app por diseño. Se muestra disabled para dejarlo
        // explícito en la UI.
        SwitchListTile(
          key: K.notifAjustesEmergencias,
          title: const Text('Emergencias'),
          subtitle: const Text(
            'Activadas siempre por seguridad. Para silenciarlas, '
            'usa los ajustes del sistema.',
          ),
          value: true,
          onChanged: null,
          secondary: Icon(
            Symbols.warning_amber,
            color: theme.colorScheme.error,
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          key: K.notifAjustesNuevosServicios,
          title: const Text('Nuevos servicios disponibles'),
          subtitle: const Text(
            'Aviso cuando se publica un servicio preventivo o de '
            'formación al que puedes apuntarte.',
          ),
          value: prefs.nuevosServicios as bool,
          onChanged: (v) => ref
              .read(notificacionesAjustesViewModelProvider.notifier)
              .setNuevosServicios(v),
          secondary: const Icon(Symbols.event_available),
        ),
        const Divider(height: 1),
        SwitchListTile(
          key: K.notifAjustesRecordatorios,
          title: const Text('Recordatorios de mis servicios'),
          subtitle: const Text(
            'Aviso unas horas antes de un servicio en el que estás '
            'inscrito o has sido convocado.',
          ),
          value: prefs.recordatorios as bool,
          onChanged: (v) => ref
              .read(notificacionesAjustesViewModelProvider.notifier)
              .setRecordatorios(v),
          secondary: const Icon(Symbols.alarm),
        ),
      ],
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Notificaciones',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite configurar las notificaciones.',
        icon: Symbols.lock,
      ),
    );
  }
}
