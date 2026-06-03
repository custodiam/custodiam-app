// FamilyAsyncNotifier del personal de un servicio (A9). Carga la lista de
// voluntarios inscritos/convocados vía ListVoluntariosServicio. Es solo
// lectura: no hay acciones de mutación, así que únicamente expone refresh()
// además del build inicial (mismo patrón que ServicioInventarioViewModel).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/voluntario_inscrito.dart';
import '../../domain/usecases/list_voluntarios_servicio.dart';
import 'servicios_di.dart';

class PersonalServicioViewModel
    extends FamilyAsyncNotifier<List<VoluntarioInscrito>, String> {
  ListVoluntariosServicio get _list =>
      ref.read(listVoluntariosServicioProvider);

  @override
  Future<List<VoluntarioInscrito>> build(String arg) async => _fetch();

  Future<List<VoluntarioInscrito>> _fetch() async {
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

final personalServicioViewModelProvider = AsyncNotifierProvider.family<
    PersonalServicioViewModel, List<VoluntarioInscrito>, String>(
  PersonalServicioViewModel.new,
);
