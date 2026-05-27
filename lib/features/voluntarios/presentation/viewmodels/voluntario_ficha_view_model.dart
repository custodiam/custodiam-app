// FamilyAsyncNotifier driving VoluntarioFichaPage (US-02-02).
//
// Loads the volunteer record, the catalog of assignable roles, and
// the active role assignments in parallel on build. Exposes
// imperative actions for the admin form (saveAdmin) and the roles
// section (asignarRol, quitarRol). Each mutation re-fetches the
// affected slice and surfaces failures via AsyncError so the page
// can ref.listen and render a typed snackbar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/entities/voluntario_rol_asignacion.dart';
import '../../domain/entities/voluntario_update_admin.dart';
import '../../domain/usecases/asignar_rol.dart';
import '../../domain/usecases/get_voluntario_by_id.dart';
import '../../domain/usecases/list_roles_catalogo.dart';
import '../../domain/usecases/list_roles_voluntario.dart';
import '../../domain/usecases/quitar_rol.dart';
import '../../domain/usecases/update_voluntario_admin.dart';
import 'voluntarios_di.dart';

class VoluntarioFichaState {
  final Voluntario voluntario;
  final List<VoluntarioRolAsignacion> rolesAsignados;
  final List<Rol> catalogoRoles;
  final bool isMutating;

  const VoluntarioFichaState({
    required this.voluntario,
    required this.rolesAsignados,
    required this.catalogoRoles,
    this.isMutating = false,
  });

  VoluntarioFichaState copyWith({
    Voluntario? voluntario,
    List<VoluntarioRolAsignacion>? rolesAsignados,
    List<Rol>? catalogoRoles,
    bool? isMutating,
  }) {
    return VoluntarioFichaState(
      voluntario: voluntario ?? this.voluntario,
      rolesAsignados: rolesAsignados ?? this.rolesAsignados,
      catalogoRoles: catalogoRoles ?? this.catalogoRoles,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

class VoluntarioFichaViewModel
    extends FamilyAsyncNotifier<VoluntarioFichaState, String> {
  GetVoluntarioById get _getById => ref.read(getVoluntarioByIdProvider);
  UpdateVoluntarioAdmin get _updateAdmin =>
      ref.read(updateVoluntarioAdminProvider);
  ListRolesVoluntario get _listRoles => ref.read(listRolesVoluntarioProvider);
  ListRolesCatalogo get _listCatalogo => ref.read(listRolesCatalogoProvider);
  AsignarRol get _asignarRol => ref.read(asignarRolProvider);
  QuitarRol get _quitarRol => ref.read(quitarRolProvider);

  @override
  Future<VoluntarioFichaState> build(String voluntarioId) async {
    final results = await Future.wait([
      _getById(voluntarioId),
      _listRoles(voluntarioId),
      _listCatalogo(),
    ]);
    final volResult = results[0] as Result<Voluntario>;
    final rolesResult =
        results[1] as Result<List<VoluntarioRolAsignacion>>;
    final catalogoResult = results[2] as Result<List<Rol>>;
    return _combine(volResult, rolesResult, catalogoResult);
  }

  VoluntarioFichaState _combine(
    Result<Voluntario> volResult,
    Result<List<VoluntarioRolAsignacion>> rolesResult,
    Result<List<Rol>> catalogoResult,
  ) {
    // Si el voluntario falla, propagamos esa Failure: sin él no hay
    // ficha que pintar. Si roles o catálogo fallan, propagamos su
    // Failure por separado (la pantalla ya ha pintado vacío).
    final voluntario = switch (volResult) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
    final roles = switch (rolesResult) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
    final catalogo = switch (catalogoResult) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
    return VoluntarioFichaState(
      voluntario: voluntario,
      rolesAsignados: roles,
      catalogoRoles: catalogo,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await Future.wait([
        _getById(arg),
        _listRoles(arg),
        _listCatalogo(),
      ]);
      return _combine(
        results[0] as Result<Voluntario>,
        results[1] as Result<List<VoluntarioRolAsignacion>>,
        results[2] as Result<List<Rol>>,
      );
    });
  }

  Future<void> saveAdmin(VoluntarioUpdateAdmin patch) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isMutating: true));
    final result = await _updateAdmin(arg, patch);
    state = switch (result) {
      Success(:final value) => AsyncData(current.copyWith(
          voluntario: value,
          isMutating: false,
        )),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  Future<void> asignarRol(String rolId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isMutating: true));
    final result = await _asignarRol(arg, rolId);
    state = switch (result) {
      Success(:final value) => AsyncData(current.copyWith(
          rolesAsignados: [...current.rolesAsignados, value],
          isMutating: false,
        )),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  Future<void> quitarRol(String rolId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isMutating: true));
    final result = await _quitarRol(arg, rolId);
    state = switch (result) {
      Success() => AsyncData(current.copyWith(
          rolesAsignados: current.rolesAsignados
              .where((a) => a.rolId != rolId)
              .toList(growable: false),
          isMutating: false,
        )),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final voluntarioFichaViewModelProvider = AsyncNotifierProvider.family<
    VoluntarioFichaViewModel,
    VoluntarioFichaState,
    String>(VoluntarioFichaViewModel.new);
