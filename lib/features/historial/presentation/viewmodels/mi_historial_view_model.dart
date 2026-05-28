// ViewModel del listado paginado de eventos del historial (US-02-06).
//
// Expone:
// - `state` = AsyncValue<List<EventoVoluntario>> con el contenido
//   acumulado de las páginas cargadas hasta la fecha.
// - `total` = total reportado por el backend (X-Total-Count) para que
//   la UI sepa si quedan más páginas.
// - `loadMore()` carga la siguiente página y la concatena al estado.
// - `setFiltroTipos()` y `setRangoFechas()` resetean la paginación
//   y vuelven a cargar desde 0.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/evento_voluntario.dart';
import '../../domain/entities/historial_page.dart';
import '../../domain/entities/tipo_evento_voluntario.dart';
import 'historial_di.dart';

const int _kPageSize = 50;

class MiHistorialState {
  final List<EventoVoluntario> eventos;
  final int total;
  final int skip;
  final bool cargandoMas;
  final List<TipoEventoVoluntario> filtroTipos;
  final DateTime? desde;
  final DateTime? hasta;

  const MiHistorialState({
    required this.eventos,
    required this.total,
    required this.skip,
    required this.cargandoMas,
    required this.filtroTipos,
    required this.desde,
    required this.hasta,
  });

  bool get hayMas => skip < total;

  MiHistorialState copyWith({
    List<EventoVoluntario>? eventos,
    int? total,
    int? skip,
    bool? cargandoMas,
    List<TipoEventoVoluntario>? filtroTipos,
    DateTime? desde,
    DateTime? hasta,
    bool desdeNull = false,
    bool hastaNull = false,
  }) {
    return MiHistorialState(
      eventos: eventos ?? this.eventos,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      cargandoMas: cargandoMas ?? this.cargandoMas,
      filtroTipos: filtroTipos ?? this.filtroTipos,
      desde: desdeNull ? null : (desde ?? this.desde),
      hasta: hastaNull ? null : (hasta ?? this.hasta),
    );
  }
}

class MiHistorialViewModel extends AsyncNotifier<MiHistorialState> {
  @override
  Future<MiHistorialState> build() async {
    return _cargarPrimeraPagina(
      filtroTipos: const <TipoEventoVoluntario>[],
      desde: null,
      hasta: null,
    );
  }

  Future<MiHistorialState> _cargarPrimeraPagina({
    required List<TipoEventoVoluntario> filtroTipos,
    required DateTime? desde,
    required DateTime? hasta,
  }) async {
    final useCase = ref.read(obtenerMiHistorialProvider);
    final result = await useCase(
      skip: 0,
      limit: _kPageSize,
      tipos: filtroTipos.isEmpty ? null : filtroTipos,
      since: desde,
      until: hasta,
    );
    return switch (result) {
      Success(:final HistorialPage value) => MiHistorialState(
          eventos: value.eventos,
          total: value.total,
          skip: value.eventos.length,
          cargandoMas: false,
          filtroTipos: filtroTipos,
          desde: desde,
          hasta: hasta,
        ),
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _cargarPrimeraPagina(
          filtroTipos: current?.filtroTipos ?? const <TipoEventoVoluntario>[],
          desde: current?.desde,
          hasta: current?.hasta,
        ));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hayMas || current.cargandoMas) return;

    state = AsyncData(current.copyWith(cargandoMas: true));

    final useCase = ref.read(obtenerMiHistorialProvider);
    final result = await useCase(
      skip: current.skip,
      limit: _kPageSize,
      tipos: current.filtroTipos.isEmpty ? null : current.filtroTipos,
      since: current.desde,
      until: current.hasta,
    );

    switch (result) {
      case Success(:final HistorialPage value):
        state = AsyncData(current.copyWith(
          eventos: [...current.eventos, ...value.eventos],
          total: value.total,
          skip: current.skip + value.eventos.length,
          cargandoMas: false,
        ));
      case Fail(:final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }

  Future<void> setFiltroTipos(List<TipoEventoVoluntario> tipos) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _cargarPrimeraPagina(
          filtroTipos: tipos,
          desde: current?.desde,
          hasta: current?.hasta,
        ));
  }

  Future<void> setRangoFechas({DateTime? desde, DateTime? hasta}) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _cargarPrimeraPagina(
          filtroTipos: current?.filtroTipos ?? const <TipoEventoVoluntario>[],
          desde: desde,
          hasta: hasta,
        ));
  }
}

final miHistorialViewModelProvider =
    AsyncNotifierProvider<MiHistorialViewModel, MiHistorialState>(
  MiHistorialViewModel.new,
);
