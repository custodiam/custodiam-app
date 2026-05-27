// FamilyAsyncNotifier para la ficha de un material. Acciones:
// reportar incidencia (avería/pérdida — US-05-08/09), asignar a
// voluntario (US-05-03/04) y devolver (US-05-05).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/tipo_asignacion.dart';
import '../../domain/usecases/asignar_material_a_voluntario.dart';
import '../../domain/usecases/devolver_material.dart';
import '../../domain/usecases/get_material.dart';
import '../../domain/usecases/reportar_incidencia_material.dart';
import 'inventario_di.dart';

class MaterialFichaViewModel
    extends FamilyAsyncNotifier<MaterialItem, String> {
  GetMaterial get _get => ref.read(getMaterialProvider);
  ReportarIncidenciaMaterial get _incidencia =>
      ref.read(reportarIncidenciaMaterialProvider);
  AsignarMaterialAVoluntario get _asignar =>
      ref.read(asignarMaterialAVoluntarioProvider);
  DevolverMaterial get _devolver => ref.read(devolverMaterialProvider);

  @override
  Future<MaterialItem> build(String arg) async => _fetch();

  Future<MaterialItem> _fetch() async {
    final result = await _get(arg);
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> reportarIncidencia({
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _incidencia(
        arg,
        nuevoEstado: nuevoEstado,
        descripcion: descripcion,
      );
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }

  Future<bool> asignarAVoluntario({
    required String voluntarioId,
    required TipoAsignacion tipo,
    int cantidad = 1,
  }) async {
    final result = await _asignar(
      arg,
      voluntarioId: voluntarioId,
      tipo: tipo,
      cantidad: cantidad,
    );
    return switch (result) {
      Success() => true,
      Fail(:final failure) => () {
          state = AsyncError(failure, StackTrace.current);
          return false;
        }(),
    };
  }

  Future<bool> devolver({
    required String voluntarioId,
    String? observaciones,
  }) async {
    final result = await _devolver(
      arg,
      voluntarioId: voluntarioId,
      observaciones: observaciones,
    );
    return switch (result) {
      Success() => true,
      Fail(:final failure) => () {
          state = AsyncError(failure, StackTrace.current);
          return false;
        }(),
    };
  }
}

final materialFichaViewModelProvider = AsyncNotifierProvider.family<
    MaterialFichaViewModel, MaterialItem, String>(
  MaterialFichaViewModel.new,
);
