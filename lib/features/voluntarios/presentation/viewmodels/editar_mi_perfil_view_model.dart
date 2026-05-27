// AsyncNotifier that drives the EditarMiPerfilPage form (US-02-03).
// State is AsyncValue<Voluntario?>: null while the user is still
// editing, the updated record after a successful PATCH, an error
// (AuthFailure / NetworkFailure / VoluntariosFailure.emailDuplicado)
// after a failed submit. The page listens for both branches.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/mi_perfil_update.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/usecases/update_my_profile.dart';
import 'voluntarios_di.dart';

class EditarMiPerfilViewModel extends AsyncNotifier<Voluntario?> {
  UpdateMyProfile get _updateMyProfile => ref.read(updateMyProfileProvider);

  @override
  Future<Voluntario?> build() async => null;

  Future<void> submit(MiPerfilUpdate patch) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _updateMyProfile(patch);
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final editarMiPerfilViewModelProvider =
    AsyncNotifierProvider<EditarMiPerfilViewModel, Voluntario?>(
  EditarMiPerfilViewModel.new,
);
