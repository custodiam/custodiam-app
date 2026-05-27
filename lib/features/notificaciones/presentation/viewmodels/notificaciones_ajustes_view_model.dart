// AsyncNotifier que mueve NotificacionesAjustesPage (US-06-03).
// Carga las preferencias locales en build() y expone toggles para
// nuevos servicios y recordatorios. Las emergencias quedan SIEMPRE
// activas en el dominio (los disable solo desde los ajustes del SO).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/preferencias_notificaciones.dart';
import '../../domain/usecases/get_preferencias_notificaciones.dart';
import '../../domain/usecases/update_preferencias_notificaciones.dart';
import 'notificaciones_di.dart';

class NotificacionesAjustesViewModel
    extends AsyncNotifier<PreferenciasNotificaciones> {
  GetPreferenciasNotificaciones get _get =>
      ref.read(getPreferenciasNotificacionesProvider);
  UpdatePreferenciasNotificaciones get _update =>
      ref.read(updatePreferenciasNotificacionesProvider);

  @override
  Future<PreferenciasNotificaciones> build() => _get();

  Future<void> setNuevosServicios(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(nuevosServicios: value);
    state = AsyncData(next);
    await _update(next);
  }

  Future<void> setRecordatorios(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(recordatorios: value);
    state = AsyncData(next);
    await _update(next);
  }
}

final notificacionesAjustesViewModelProvider = AsyncNotifierProvider<
    NotificacionesAjustesViewModel,
    PreferenciasNotificaciones>(NotificacionesAjustesViewModel.new);
