// Resumen de horas acumuladas para US-04-03.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/horas_acumuladas.dart';
import '../../domain/usecases/get_mis_horas.dart';
import 'fichaje_di.dart';

class MisHorasViewModel extends AsyncNotifier<HorasAcumuladas> {
  GetMisHoras get _get => ref.read(getMisHorasProvider);

  @override
  Future<HorasAcumuladas> build() async {
    final result = await _get();
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

final misHorasViewModelProvider =
    AsyncNotifierProvider<MisHorasViewModel, HorasAcumuladas>(
  MisHorasViewModel.new,
);
