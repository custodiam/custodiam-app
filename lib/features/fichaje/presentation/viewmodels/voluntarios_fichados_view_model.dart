// FamilyAsyncNotifier por servicioId. Lista de voluntarios con
// fichaje (abierto o cerrado) en ese servicio. Requiere
// `fichaje.ver_voluntarios_en_servicio` server-side y se gatea en UI
// con AppPermissionGate.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/fichaje_en_servicio.dart';
import '../../domain/usecases/list_fichados_servicio.dart';
import 'fichaje_di.dart';

class VoluntariosFichadosViewModel
    extends FamilyAsyncNotifier<List<FichajeEnServicio>, String> {
  ListFichadosServicio get _list =>
      ref.read(listFichadosServicioProvider);

  @override
  Future<List<FichajeEnServicio>> build(String arg) async {
    return _fetch();
  }

  Future<List<FichajeEnServicio>> _fetch() async {
    final result = await _list(arg);
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final voluntariosFichadosViewModelProvider = AsyncNotifierProvider.family<
    VoluntariosFichadosViewModel,
    List<FichajeEnServicio>,
    String>(VoluntariosFichadosViewModel.new);
