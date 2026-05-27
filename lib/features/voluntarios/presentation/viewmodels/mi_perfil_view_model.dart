// AsyncNotifier exposing the authenticated user's full profile
// (US-02-05). Failures are surfaced through AsyncError so the page
// can ref.listen and render an AppErrorState or snackbar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/usecases/get_my_profile.dart';
import 'voluntarios_di.dart';

class MiPerfilViewModel extends AsyncNotifier<Voluntario> {
  GetMyProfile get _getMyProfile => ref.read(getMyProfileProvider);

  @override
  Future<Voluntario> build() async {
    final result = await _getMyProfile();
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _getMyProfile();
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }

  /// Replace the cached profile after a successful PATCH (called from
  /// EditarMiPerfilViewModel) so the page does not need to re-fetch.
  void setProfile(Voluntario voluntario) {
    state = AsyncData(voluntario);
  }
}

final miPerfilViewModelProvider =
    AsyncNotifierProvider<MiPerfilViewModel, Voluntario>(
  MiPerfilViewModel.new,
);
