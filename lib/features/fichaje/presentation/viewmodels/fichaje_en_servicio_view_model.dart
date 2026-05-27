// FamilyAsyncNotifier por servicioId. Combina:
//   - `miFichaje`: el fichaje abierto del usuario en ese servicio
//     (derivado de GET /fichajes/me filtrando por servicio_id), o
//     `null` si no hay ninguno.
//   - acciones `ficharEntrada` y `ficharSalida` que refrescan el
//     estado al completarse.
//
// La lista de voluntarios fichados (US-04-04) vive en otro provider
// porque requiere un permiso distinto (`fichaje.ver_voluntarios_en_servicio`).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/fichaje.dart';
import '../../domain/usecases/fichar_entrada.dart';
import '../../domain/usecases/fichar_salida.dart';
import '../../domain/usecases/get_mis_fichajes.dart';
import 'fichaje_di.dart';

class FichajeEnServicioState {
  /// El fichaje activo del usuario en ese servicio (cerrado o abierto).
  /// Si null, el usuario nunca ha fichado en ese servicio.
  final Fichaje? fichaje;

  const FichajeEnServicioState({this.fichaje});

  bool get tieneEntradaAbierta =>
      fichaje != null && fichaje!.horaSalida == null;

  bool get yaFichadoYCerrado =>
      fichaje != null && fichaje!.horaSalida != null;
}

class FichajeEnServicioViewModel
    extends FamilyAsyncNotifier<FichajeEnServicioState, String> {
  GetMisFichajes get _getMisFichajes => ref.read(getMisFichajesProvider);
  FicharEntrada get _ficharEntrada => ref.read(ficharEntradaProvider);
  FicharSalida get _ficharSalida => ref.read(ficharSalidaProvider);

  @override
  Future<FichajeEnServicioState> build(String arg) async {
    return _fetch();
  }

  Future<FichajeEnServicioState> _fetch() async {
    final result = await _getMisFichajes();
    return switch (result) {
      Success(:final value) => FichajeEnServicioState(
          fichaje: _findActiveOrLatest(value, arg),
        ),
      Fail(:final failure) => throw failure,
    };
  }

  /// Selecciona el fichaje "relevante" para mostrar al usuario:
  ///   1. Uno abierto en este servicio, si lo hay.
  ///   2. El más reciente cerrado en este servicio, si no hay abierto.
  ///   3. `null` si nunca fichó aquí.
  Fichaje? _findActiveOrLatest(List<Fichaje> all, String servicioId) {
    Fichaje? abierto;
    Fichaje? cerrado;
    for (final f in all) {
      if (f.servicioId != servicioId) continue;
      if (f.horaSalida == null) {
        abierto = f;
      } else if (cerrado == null ||
          f.horaEntrada.isAfter(cerrado.horaEntrada)) {
        cerrado = f;
      }
    }
    return abierto ?? cerrado;
  }

  Future<void> ficharEntrada() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _ficharEntrada(arg);
      return switch (result) {
        Success(:final value) => FichajeEnServicioState(fichaje: value),
        Fail(:final failure) => throw failure,
      };
    });
  }

  Future<void> ficharSalida() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _ficharSalida(arg);
      return switch (result) {
        Success(:final value) => FichajeEnServicioState(fichaje: value),
        Fail(:final failure) => throw failure,
      };
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final fichajeEnServicioViewModelProvider = AsyncNotifierProvider.family<
    FichajeEnServicioViewModel,
    FichajeEnServicioState,
    String>(FichajeEnServicioViewModel.new);
