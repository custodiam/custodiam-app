// AsyncNotifier that drives AltaVoluntarioPage (US-02-01). Initial
// state is AsyncData(null); submit() resolves to AsyncData(newVoluntario)
// on Success or AsyncError(Failure) on Fail.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/entities/voluntario_create.dart';
import '../../domain/usecases/create_voluntario.dart';
import 'voluntarios_di.dart';

class AltaVoluntarioViewModel extends AsyncNotifier<Voluntario?> {
  CreateVoluntario get _createVoluntario => ref.read(createVoluntarioProvider);

  @override
  Future<Voluntario?> build() async => null;

  Future<void> submit(VoluntarioCreate data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _createVoluntario(data);
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final altaVoluntarioViewModelProvider =
    AsyncNotifierProvider<AltaVoluntarioViewModel, Voluntario?>(
  AltaVoluntarioViewModel.new,
);
