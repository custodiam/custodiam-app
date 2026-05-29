// MisHorasPage (US-04-03). Resumen total de horas acumuladas + número
// de fichajes cerrados y abiertos. Accesible desde /mi-perfil/horas.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/horas_acumuladas.dart';
import '../viewmodels/mis_horas_view_model.dart';

class MisHorasPage extends ConsumerWidget {
  const MisHorasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.fichajeVerPropio,
      fallback: _ForbiddenScreen(),
      child: _MisHorasBody(),
    );
  }
}

class _MisHorasBody extends ConsumerWidget {
  const _MisHorasBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(misHorasViewModelProvider);

    return AppPageScaffold(
      title: 'Mis horas',
      actions: [
        AppIconButton(
          key: const ValueKey('mis_horas_refresh'),
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () =>
              ref.read(misHorasViewModelProvider.notifier).refresh(),
        ),
      ],
      body: asyncState.when(
        loading: () => const AppLoadingIndicator.fullScreen(),
        error: (error, _) => AppErrorState(
          title: 'No se pudieron cargar tus horas',
          description: error is Failure ? error.message : null,
          onRetry: () =>
              ref.read(misHorasViewModelProvider.notifier).refresh(),
        ),
        data: (horas) => _MisHorasContent(horas: horas),
      ),
    );
  }
}

class _MisHorasContent extends StatelessWidget {
  final HorasAcumuladas horas;

  const _MisHorasContent({required this.horas});

  String _formatTotal(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(
                  _formatTotal(horas.totalSegundos),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Total acumulado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MetricRow(
            icon: Symbols.check_circle,
            label: 'Fichajes cerrados',
            value: horas.fichajesCerrados.toString(),
          ),
          _MetricRow(
            icon: Symbols.timer,
            label: 'Fichajes abiertos',
            value: horas.fichajesAbiertos.toString(),
          ),
          _MetricRow(
            icon: Symbols.functions,
            label: 'Horas (decimal)',
            value: horas.totalHoras.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
      title: 'Mis horas',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar tus horas.',
        icon: Symbols.lock,
      ),
    );
  }
}
