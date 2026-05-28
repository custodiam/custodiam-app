// ViewModel del calendario mensual de disponibilidad (US-02-04).
//
// El estado expuesto es `MesDisponibilidad`: el cliente sabe a la vez
// qué mes está mostrando y qué días dentro del mes están declarados
// disponibles. La navegación entre meses se hace con `cambiarMes` que
// reentra a `build()` recargando del backend.
//
// El método `toggleDia` aplica un patrón optimista: actualiza el
// estado local primero (para responsividad) y revierte el cambio si
// el backend rechaza la operación (típicamente 422 FechaPasada).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/dia_disponibilidad.dart';
import '../../domain/entities/mes_disponibilidad.dart';
import 'disponibilidad_di.dart';

class MiDisponibilidadViewModel extends AsyncNotifier<MesDisponibilidad> {
  late int _year;
  late int _month;

  int get year => _year;
  int get month => _month;

  @override
  Future<MesDisponibilidad> build() async {
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    return _cargar(_year, _month);
  }

  Future<MesDisponibilidad> _cargar(int year, int month) async {
    final useCase = ref.read(obtenerMiMesProvider);
    final result = await useCase(year: year, month: month);
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _cargar(_year, _month));
  }

  Future<void> cambiarMes({required int year, required int month}) async {
    _year = year;
    _month = month;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _cargar(_year, _month));
  }

  /// Alterna la disponibilidad de un día. Devuelve `null` en éxito; en
  /// caso contrario devuelve el `Failure` para que la página decida
  /// qué snackbar pintar (típicamente `FechaPasada`).
  Future<Failure?> toggleDia(DateTime fecha) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    final estaba = current.estaDisponible(fecha.day);
    final nuevoEstado = !estaba;

    // Aplicar cambio optimista en el estado local.
    final optimista = _aplicarToggleLocal(current, fecha, nuevoEstado);
    state = AsyncData(optimista);

    final useCase = ref.read(marcarMiDiaProvider);
    final result =
        await useCase(fecha: fecha, disponible: nuevoEstado);
    switch (result) {
      case Success(:final value):
        // Reemplazar la fila optimista por la real del backend (con
        // su `id` correcto si era una alta nueva). Mantiene la lista
        // ordenada por día tal como vino del backend.
        state = AsyncData(_reemplazarConBackend(current, fecha, value));
        return null;
      case Fail(:final failure):
        // Revertir: volver al estado previo al toggle.
        state = AsyncData(current);
        return failure;
    }
  }

  MesDisponibilidad _aplicarToggleLocal(
    MesDisponibilidad mes,
    DateTime fecha,
    bool disponible,
  ) {
    final dias = List<DiaDisponibilidad>.from(mes.dias);
    final indice = dias.indexWhere((d) => d.fecha.day == fecha.day);
    if (indice >= 0) {
      dias[indice] = dias[indice].copyWith(disponible: disponible);
    } else {
      dias.add(DiaDisponibilidad(
        id: 'optimista-${fecha.toIso8601String()}',
        voluntarioId: dias.isNotEmpty ? dias.first.voluntarioId : '',
        fecha: fecha,
        disponible: disponible,
      ));
    }
    return MesDisponibilidad(year: mes.year, month: mes.month, dias: dias);
  }

  MesDisponibilidad _reemplazarConBackend(
    MesDisponibilidad previo,
    DateTime fecha,
    DiaDisponibilidad real,
  ) {
    final dias = List<DiaDisponibilidad>.from(previo.dias);
    final indice = dias.indexWhere((d) => d.fecha.day == fecha.day);
    if (indice >= 0) {
      dias[indice] = real;
    } else {
      dias.add(real);
    }
    return MesDisponibilidad(year: previo.year, month: previo.month, dias: dias);
  }
}

final miDisponibilidadViewModelProvider =
    AsyncNotifierProvider<MiDisponibilidadViewModel, MesDisponibilidad>(
  MiDisponibilidadViewModel.new,
);
