// MiHistorialPage (US-02-06 / CU-13).
//
// Layout:
// - Cabecera con resumen (horas totales, servicios cerrados, último).
// - Fila de filtros por tipo (ChoiceChip), un chip "Todos" para
//   resetear y un chip por cada `TipoEventoVoluntario` relevante.
// - Lista paginada infinita (scroll detect a 200px del fondo dispara
//   `loadMore()` mientras `hayMas`).
//
// Se gata por `voluntariosVerPropio`; el backend exige el mismo
// permiso, así que un usuario sin él recibe la fallback screen sin
// llegar a tocar la red.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_date_range_picker.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/evento_voluntario.dart';
import '../../domain/entities/resumen_voluntario.dart';
import '../../domain/entities/tipo_evento_voluntario.dart';
import '../viewmodels/mi_historial_view_model.dart';
import '../viewmodels/mi_resumen_view_model.dart';

class MiHistorialPage extends ConsumerWidget {
  const MiHistorialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosVerPropio,
      fallback: _ForbiddenScreen(),
      child: _MiHistorialBody(),
    );
  }
}

class _MiHistorialBody extends ConsumerStatefulWidget {
  const _MiHistorialBody();

  @override
  ConsumerState<_MiHistorialBody> createState() => _MiHistorialBodyState();
}

class _MiHistorialBodyState extends ConsumerState<_MiHistorialBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final actual = _scrollController.position.pixels;
    if (maxScroll - actual <= 200) {
      ref.read(miHistorialViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncHistorial = ref.watch(miHistorialViewModelProvider);
    final asyncResumen = ref.watch(miResumenViewModelProvider);

    final estadoActual = asyncHistorial.valueOrNull;

    return AppPageScaffold(
      title: 'Mi historial',
      actions: [
        IconButton(
          key: const ValueKey('mi_historial_filtro_fechas'),
          tooltip: 'Filtrar por fechas',
          icon: const Icon(Icons.date_range),
          onPressed: estadoActual == null
              ? null
              : () => _abrirDateRangePicker(context, estadoActual),
        ),
        IconButton(
          key: const ValueKey('mi_historial_refresh'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(miHistorialViewModelProvider.notifier).refresh();
            ref.read(miResumenViewModelProvider.notifier).refresh();
          },
        ),
      ],
      body: Column(
        children: [
          _ResumenCard(asyncResumen: asyncResumen),
          if (estadoActual != null && _tieneRangoActivo(estadoActual))
            _RangoActivoChip(
              desde: estadoActual.desde,
              hasta: estadoActual.hasta,
              onLimpiar: () => ref
                  .read(miHistorialViewModelProvider.notifier)
                  .setRangoFechas(),
            ),
          const Divider(height: 1),
          Expanded(
            child: asyncHistorial.when(
              loading: () =>
                  const AppLoadingIndicator.fullScreen(),
              error: (error, _) {
                if (error is VoluntarioNotFound) {
                  return AppEmptyState(
                    title: 'Sin perfil',
                    description: error.message,
                    icon: Icons.person_outline,
                  );
                }
                final message = error is Failure
                    ? error.message
                    : 'No se pudo cargar el historial.';
                return AppErrorState(
                  title: 'No se pudo cargar tu historial',
                  description: message,
                  onRetry: () => ref
                      .read(miHistorialViewModelProvider.notifier)
                      .refresh(),
                );
              },
              data: (estado) => _ListaContent(
                estado: estado,
                scrollController: _scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _tieneRangoActivo(MiHistorialState estado) =>
      estado.desde != null || estado.hasta != null;

  Future<void> _abrirDateRangePicker(
    BuildContext context,
    MiHistorialState estado,
  ) async {
    final hoy = DateTime.now();
    final inicial =
        estado.desde != null && estado.hasta != null
            ? DateTimeRange(start: estado.desde!, end: estado.hasta!)
            : null;
    // Acotamos el `firstDate` a hace cinco años porque el voluntario
    // medio del piloto tiene historial reciente. Si en el futuro hace
    // falta cubrir más, basta con extender este parámetro o pedirlo a
    // un endpoint que devuelva la fecha de alta del voluntario.
    final hace5Anios = DateTime(hoy.year - 5, hoy.month, hoy.day);

    final range = await showAppDateRangePicker(
      context: context,
      firstDate: hace5Anios,
      lastDate: hoy,
      initialDateRange: inicial,
    );
    if (range == null) return;
    if (!mounted) return;
    await ref.read(miHistorialViewModelProvider.notifier).setRangoFechas(
          desde: range.start,
          hasta: range.end,
        );
  }
}

class _RangoActivoChip extends StatelessWidget {
  final DateTime? desde;
  final DateTime? hasta;
  final VoidCallback onLimpiar;

  const _RangoActivoChip({
    required this.desde,
    required this.hasta,
    required this.onLimpiar,
  });

  String _fmt(DateTime f) => DateFormat('dd/MM/yyyy', 'es_ES').format(f);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = desde != null && hasta != null
        ? 'Del ${_fmt(desde!)} al ${_fmt(hasta!)}'
        : desde != null
            ? 'Desde ${_fmt(desde!)}'
            : 'Hasta ${_fmt(hasta!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          key: const ValueKey('mi_historial_chip_rango_activo'),
          avatar: Icon(Icons.date_range,
              size: 18, color: theme.colorScheme.onSecondaryContainer),
          label: Text(label),
          backgroundColor: theme.colorScheme.secondaryContainer,
          deleteIcon: const Icon(Icons.close, size: 18),
          deleteButtonTooltipMessage: 'Quitar filtro de fechas',
          onDeleted: onLimpiar,
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final AsyncValue<ResumenVoluntario> asyncResumen;

  const _ResumenCard({required this.asyncResumen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: asyncResumen.when(
        loading: () => const SizedBox(
          height: 80,
          child: AppLoadingIndicator.fullScreen(),
        ),
        error: (_, _) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'No se pudo cargar el resumen.',
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
        data: (resumen) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Metrica(
                    label: 'Horas',
                    valor: resumen.horasTotales.toString(),
                  ),
                  _Metrica(
                    label: 'Servicios',
                    valor: resumen.serviciosRealizados.toString(),
                  ),
                ],
              ),
              if (resumen.ultimoServicio != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Último servicio: ${resumen.ultimoServicio!.titulo} '
                  '(${_formatFecha(resumen.ultimoServicio!.fechaInicio)})',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime f) =>
      DateFormat('dd/MM/yyyy', 'es_ES').format(f);
}

class _Metrica extends StatelessWidget {
  final String label;
  final String valor;

  const _Metrica({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          valor,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _ListaContent extends ConsumerWidget {
  final MiHistorialState estado;
  final ScrollController scrollController;

  const _ListaContent({
    required this.estado,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado.eventos.isEmpty) {
      return const AppEmptyState(
        title: 'Sin actividad registrada',
        description: 'Aún no has generado eventos en tu historial.',
        icon: Icons.history,
      );
    }

    return Column(
      children: [
        _FiltroTiposBar(
          seleccionados: estado.filtroTipos,
          onChange: (tipos) => ref
              .read(miHistorialViewModelProvider.notifier)
              .setFiltroTipos(tipos),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: estado.eventos.length + (estado.hayMas ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= estado.eventos.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AppLoadingIndicator.fullScreen(),
                );
              }
              return _EventoTile(evento: estado.eventos[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FiltroTiposBar extends StatelessWidget {
  final List<TipoEventoVoluntario> seleccionados;
  final void Function(List<TipoEventoVoluntario>) onChange;

  const _FiltroTiposBar({
    required this.seleccionados,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: ChoiceChip(
              key: const ValueKey('mi_historial_filtro_todos'),
              label: const Text('Todos'),
              selected: seleccionados.isEmpty,
              onSelected: (_) => onChange(const []),
            ),
          ),
          for (final tipo in TipoEventoVoluntario.values)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: ChoiceChip(
                key: ValueKey('mi_historial_filtro_${tipo.wire}'),
                label: Text(tipo.etiqueta),
                selected: seleccionados.contains(tipo),
                onSelected: (sel) {
                  final nuevos = List<TipoEventoVoluntario>.from(seleccionados);
                  if (sel) {
                    nuevos.add(tipo);
                  } else {
                    nuevos.remove(tipo);
                  }
                  onChange(nuevos);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final EventoVoluntario evento;

  const _EventoTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(_iconoDe(evento.tipo)),
      title: Text(evento.tipo.etiqueta),
      subtitle: Text(
        evento.createdAt != null
            ? DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(
                evento.createdAt!.toLocal(),
              )
            : '—',
        style: theme.textTheme.bodySmall,
      ),
      trailing: evento.actorKeycloakId != null
          ? Tooltip(
              message: 'Actor: ${evento.actorKeycloakId}',
              child: const Icon(Icons.person_outline, size: 18),
            )
          : null,
    );
  }

  IconData _iconoDe(TipoEventoVoluntario tipo) {
    switch (tipo) {
      case TipoEventoVoluntario.alta:
        return Icons.person_add_alt;
      case TipoEventoVoluntario.baja:
        return Icons.person_off_outlined;
      case TipoEventoVoluntario.anonimizacion:
        return Icons.privacy_tip_outlined;
      case TipoEventoVoluntario.cambioRolAsignado:
        return Icons.badge_outlined;
      case TipoEventoVoluntario.cambioRolRevocado:
        return Icons.no_accounts_outlined;
      case TipoEventoVoluntario.fichajeEntrada:
        return Icons.login;
      case TipoEventoVoluntario.fichajeSalida:
        return Icons.logout;
      case TipoEventoVoluntario.inscripcionServicio:
        return Icons.event_available_outlined;
      case TipoEventoVoluntario.bajaInscripcion:
        return Icons.event_busy_outlined;
      case TipoEventoVoluntario.asignacionMaterial:
        return Icons.inventory_2_outlined;
      case TipoEventoVoluntario.devolucionMaterial:
        return Icons.assignment_return_outlined;
    }
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Mi historial',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar el historial propio.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
