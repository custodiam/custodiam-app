// MiDisponibilidadPage (US-02-04 / CU-12).
//
// Calendario mensual interactivo en /mi-perfil/disponibilidad. Toca un
// día para alternar la disponibilidad declarada. Los días anteriores a
// hoy aparecen deshabilitados (el backend devuelve 422 FechaPasada en
// PUT, y el cliente espeja la regla para no enviar la request).
//
// La página se gata por `voluntariosVerPropio`; el toggle se gata
// adicionalmente por `voluntariosDisponibilidadPropia` (ambos están en
// el frozenset base operativo, así que en la práctica un voluntario
// con acceso a la página también puede tocar).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/mes_disponibilidad.dart';
import '../viewmodels/mi_disponibilidad_view_model.dart';

class MiDisponibilidadPage extends ConsumerWidget {
  const MiDisponibilidadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosVerPropio,
      fallback: _ForbiddenScreen(),
      child: _MiDisponibilidadBody(),
    );
  }
}

class _MiDisponibilidadBody extends ConsumerWidget {
  const _MiDisponibilidadBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(miDisponibilidadViewModelProvider);

    return AppPageScaffold(
      title: 'Mi disponibilidad',
      actions: [
        IconButton(
          key: const ValueKey('mi_disponibilidad_refresh'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref
              .read(miDisponibilidadViewModelProvider.notifier)
              .refresh(),
        ),
      ],
      body: asyncState.when(
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
              error is Failure ? error.message : 'No se pudo cargar el calendario.';
          return AppErrorState(
            title: 'No se pudo cargar tu disponibilidad',
            description: message,
            onRetry: () => ref
                .read(miDisponibilidadViewModelProvider.notifier)
                .refresh(),
          );
        },
        data: (mes) => _CalendarioContent(mes: mes),
      ),
    );
  }
}

class _CalendarioContent extends ConsumerWidget {
  final MesDisponibilidad mes;

  const _CalendarioContent({required this.mes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(miDisponibilidadViewModelProvider.notifier);
    final roles =
        ref.watch(authServiceProvider).currentUser?.roles ?? const <String>[];
    final tieneToggle = permissionsForRoles(roles)
        .contains(Permission.voluntariosDisponibilidadPropia);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _MesNavegacion(
            year: mes.year,
            month: mes.month,
            onPrev: () => _navegar(notifier, mes.year, mes.month, -1),
            onNext: () => _navegar(notifier, mes.year, mes.month, 1),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _LeyendaDias(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _GrilladeDias(
              mes: mes,
              habilitado: tieneToggle,
              onTap: (fecha) async {
                final failure = await notifier.toggleDia(fecha);
                if (failure != null && context.mounted) {
                  AppSnackbar.show(
                    context,
                    message: failure.message ?? 'No se pudo actualizar el día.',
                    variant: AppSnackbarVariant.danger,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navegar(
    MiDisponibilidadViewModel notifier,
    int currentYear,
    int currentMonth,
    int delta,
  ) {
    var year = currentYear;
    var month = currentMonth + delta;
    if (month > 12) {
      month = 1;
      year += 1;
    } else if (month < 1) {
      month = 12;
      year -= 1;
    }
    notifier.cambiarMes(year: year, month: month);
  }
}

class _MesNavegacion extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MesNavegacion({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat.yMMMM('es_ES');
    final etiqueta = formatter.format(DateTime(year, month));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          key: const ValueKey('mi_disponibilidad_prev_month'),
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
        ),
        Text(
          etiqueta[0].toUpperCase() + etiqueta.substring(1),
          style: theme.textTheme.titleLarge,
        ),
        IconButton(
          key: const ValueKey('mi_disponibilidad_next_month'),
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _LeyendaDias extends StatelessWidget {
  const _LeyendaDias();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: [
        for (final dia in etiquetas)
          Expanded(
            child: Center(
              child: Text(
                dia,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GrilladeDias extends StatelessWidget {
  final MesDisponibilidad mes;
  final bool habilitado;
  final void Function(DateTime fecha) onTap;

  const _GrilladeDias({
    required this.mes,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    final primerDia = DateTime(mes.year, mes.month, 1);
    final diasEnMes = DateTime(mes.year, mes.month + 1, 0).day;
    // weekday: lunes=1 ... domingo=7. Restamos 1 para offset 0..6.
    final offsetInicial = primerDia.weekday - 1;
    final totalCeldas =
        ((offsetInicial + diasEnMes) / 7).ceil() * 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalCeldas,
      itemBuilder: (context, index) {
        final diaDelMes = index - offsetInicial + 1;
        if (diaDelMes < 1 || diaDelMes > diasEnMes) {
          return const SizedBox.shrink();
        }
        final fecha = DateTime(mes.year, mes.month, diaDelMes);
        final esPasado = fecha.isBefore(hoySinHora);
        final disponible = mes.estaDisponible(diaDelMes);

        return _CeldaDia(
          dia: diaDelMes,
          fecha: fecha,
          disponible: disponible,
          esPasado: esPasado,
          esHoy: fecha == hoySinHora,
          habilitado: habilitado,
          onTap: onTap,
        );
      },
    );
  }
}

class _CeldaDia extends StatelessWidget {
  final int dia;
  final DateTime fecha;
  final bool disponible;
  final bool esPasado;
  final bool esHoy;
  final bool habilitado;
  final void Function(DateTime fecha) onTap;

  const _CeldaDia({
    required this.dia,
    required this.fecha,
    required this.disponible,
    required this.esPasado,
    required this.esHoy,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;

    if (disponible) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (esPasado) {
      background = scheme.surfaceContainerHigh;
      foreground = scheme.onSurfaceVariant.withValues(alpha: 0.5);
    } else {
      background = scheme.surfaceContainerLow;
      foreground = scheme.onSurface;
    }

    final tappable = habilitado && !esPasado;
    final border = esHoy
        ? Border.all(color: scheme.primary, width: 2)
        : null;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        label: _semanticLabel(),
        button: tappable,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: border?.top ?? BorderSide.none,
          ),
          child: InkWell(
            key: ValueKey('mi_disponibilidad_dia_$dia'),
            borderRadius: BorderRadius.circular(8),
            onTap: tappable ? () => onTap(fecha) : null,
            child: Center(
              child: Text(
                dia.toString(),
                style: TextStyle(
                  color: foreground,
                  fontWeight: disponible ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    final base = 'Día $dia';
    if (esPasado) return '$base (pasado, no editable)';
    if (disponible) return '$base disponible';
    return '$base no disponible';
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Mi disponibilidad',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite gestionar la disponibilidad propia.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
