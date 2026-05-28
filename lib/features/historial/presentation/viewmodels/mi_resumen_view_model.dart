// ViewModel del resumen agregado del voluntario (US-02-06 / CU-13).
// Se mantiene separado del historial porque ambos cargan en paralelo y
// la UI puede refrescarlos de forma independiente.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/resumen_voluntario.dart';
import 'historial_di.dart';

class MiResumenViewModel extends AsyncNotifier<ResumenVoluntario> {
  @override
  Future<ResumenVoluntario> build() async {
    final useCase = ref.read(obtenerMiResumenProvider);
    final result = await useCase();
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final miResumenViewModelProvider =
    AsyncNotifierProvider<MiResumenViewModel, ResumenVoluntario>(
  MiResumenViewModel.new,
);
