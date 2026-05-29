// FichajeEnServicioPage (US-04-01, US-04-02, US-04-03 contador, US-04-04).
//
// Tres bloques apilados:
//   1. Mi estado actual de fichaje + contador en vivo si está abierto.
//   2. Botones Fichar entrada / Fichar salida (según estado).
//   3. Lista de voluntarios fichados (solo si tengo permiso jefe+).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/fichaje.dart';
import '../../domain/entities/fichaje_en_servicio.dart';
import '../viewmodels/fichaje_en_servicio_view_model.dart';
import '../viewmodels/voluntarios_fichados_view_model.dart';

class FichajeEnServicioPage extends ConsumerWidget {
  final String servicioId;

  const FichajeEnServicioPage({super.key, required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate.anyOf(
      anyOf: const [
        Permission.fichajeFicharPropio,
        Permission.fichajeVerVoluntariosEnServicio,
      ],
      fallback: const _ForbiddenScreen(),
      child: _FichajeBody(servicioId: servicioId),
    );
  }
}

class _FichajeBody extends ConsumerWidget {
  final String servicioId;

  const _FichajeBody({required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(fichajeEnServicioViewModelProvider(servicioId),
        (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo completar el fichaje.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      title: 'Fichaje',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppPermissionGate(
            permission: Permission.fichajeFicharPropio,
            child: _MiFichajeCard(servicioId: servicioId),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPermissionGate(
            permission: Permission.fichajeVerVoluntariosEnServicio,
            child: _VoluntariosFichadosSection(servicioId: servicioId),
          ),
        ],
      ),
    );
  }
}

class _MiFichajeCard extends ConsumerWidget {
  final String servicioId;

  const _MiFichajeCard({required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(fichajeEnServicioViewModelProvider(servicioId));

    return asyncState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppLoadingIndicator.fullScreen(),
      ),
      error: (error, _) {
        final message =
            error is Failure ? error.message : 'No se pudo cargar tu fichaje.';
        return AppErrorState(
          title: 'No se pudo cargar tu fichaje',
          description: message,
          onRetry: () => ref
              .read(fichajeEnServicioViewModelProvider(servicioId)
                  .notifier)
              .refresh(),
        );
      },
      data: (state) => _MiFichajeContent(
        servicioId: servicioId,
        state: state,
        loading: asyncState.isLoading,
      ),
    );
  }
}

class _MiFichajeContent extends ConsumerWidget {
  final String servicioId;
  final FichajeEnServicioState state;
  final bool loading;

  const _MiFichajeContent({
    required this.servicioId,
    required this.state,
    required this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mi fichaje', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (state.fichaje == null)
            Text(
              'Todavía no has fichado entrada en este servicio.',
              style: theme.textTheme.bodyMedium,
            )
          else
            _DetalleFichaje(fichaje: state.fichaje!),
          const SizedBox(height: AppSpacing.md),
          if (state.tieneEntradaAbierta)
            AppSecondaryButton(
              key: const ValueKey('fichaje_salida_button'),
              label: 'Fichar salida',
              icon: Symbols.logout,
              expanded: true,
              onPressed: loading
                  ? null
                  : () => ref
                      .read(fichajeEnServicioViewModelProvider(servicioId)
                          .notifier)
                      .ficharSalida(),
            )
          else
            AppPrimaryButton(
              key: const ValueKey('fichaje_entrada_button'),
              label: state.yaFichadoYCerrado
                  ? 'Fichar entrada de nuevo'
                  : 'Fichar entrada',
              icon: Symbols.login,
              expanded: true,
              isLoading: loading,
              onPressed: loading
                  ? null
                  : () => ref
                      .read(fichajeEnServicioViewModelProvider(servicioId)
                          .notifier)
                      .ficharEntrada(),
            ),
        ],
      ),
    );
    return card;
  }
}

/// Muestra hora de entrada y, si está abierto, un contador en vivo
/// con `Hh Mmin`. Si ya está cerrado, formatea la duración registrada.
class _DetalleFichaje extends StatefulWidget {
  final Fichaje fichaje;

  const _DetalleFichaje({required this.fichaje});

  @override
  State<_DetalleFichaje> createState() => _DetalleFichajeState();
}

class _DetalleFichajeState extends State<_DetalleFichaje> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.fichaje.estaAbierto) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatHora(DateTime f) {
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  String _formatDuracion(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = widget.fichaje;
    final duracion = f.estaAbierto
        ? DateTime.now().difference(f.horaEntrada)
        : Duration(seconds: f.duracionSegundos ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.login,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Entrada: ${_formatHora(f.horaEntrada)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (f.horaSalida != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Symbols.logout,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Salida: ${_formatHora(f.horaSalida!)}'
                '${f.automatico ? " · Automática" : ""}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Symbols.timer,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              f.estaAbierto
                  ? 'En servicio: ${_formatDuracion(duracion)}'
                  : 'Tiempo registrado: ${_formatDuracion(duracion)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _VoluntariosFichadosSection extends ConsumerWidget {
  final String servicioId;

  const _VoluntariosFichadosSection({required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(voluntariosFichadosViewModelProvider(servicioId));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Voluntarios fichados',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('voluntarios_fichados_refresh'),
              tooltip: 'Recargar',
              icon: const Icon(Symbols.refresh, size: 20),
              onPressed: () => ref
                  .read(voluntariosFichadosViewModelProvider(servicioId)
                      .notifier)
                  .refresh(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        asyncState.when(
          loading: () =>
              const AppLoadingIndicator.fullScreen(),
          error: (error, _) {
            final message = error is Failure
                ? error.message
                : 'No se pudo cargar la lista.';
            return AppErrorState(
              title: 'No se pudo cargar la lista',
              description: message,
              onRetry: () => ref
                  .read(voluntariosFichadosViewModelProvider(servicioId)
                      .notifier)
                  .refresh(),
            );
          },
          data: (items) {
            if (items.isEmpty) {
              return const AppEmptyState(
                title: 'Aún no hay voluntarios fichados',
                description: 'Cuando alguno fiche entrada aparecerá aquí.',
                icon: Symbols.people,
              );
            }
            return Column(
              children: items
                  .map((f) => _VoluntarioFichadoTile(fichaje: f))
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _VoluntarioFichadoTile extends StatelessWidget {
  final FichajeEnServicio fichaje;

  const _VoluntarioFichadoTile({required this.fichaje});

  String _formatHora(DateTime f) {
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  String _formatDuracion(int segundos) {
    final d = Duration(seconds: segundos);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final abierto = fichaje.estaAbierto;
    final transcurridos = abierto
        ? DateTime.now().difference(fichaje.horaEntrada).inSeconds
        : (fichaje.duracionSegundos ?? 0);
    return ListTile(
      key: ValueKey('voluntarios_fichados_item_${fichaje.fichajeId}'),
      leading: CircleAvatar(
        backgroundColor: abierto
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          abierto ? Symbols.timer : Symbols.check,
          color: abierto
              ? Theme.of(context).colorScheme.onTertiaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(fichaje.nombre),
      subtitle: Text(
        abierto
            ? 'Entrada ${_formatHora(fichaje.horaEntrada)} · '
                'llevando ${_formatDuracion(transcurridos)}'
            : 'Entrada ${_formatHora(fichaje.horaEntrada)} · '
                'salida ${_formatHora(fichaje.horaSalida!)} · '
                '${_formatDuracion(transcurridos)}',
      ),
      trailing: fichaje.automatico
          ? const Chip(label: Text('Auto'), visualDensity: VisualDensity.compact)
          : null,
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Fichaje',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite fichar en este servicio.',
        icon: Symbols.lock,
      ),
    );
  }
}
