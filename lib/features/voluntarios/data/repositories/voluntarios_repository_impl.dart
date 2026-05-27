// Concrete VoluntariosRepository. Converts wire exceptions into
// Failure variants so the rest of the app never deals with
// ApiException directly (guide 26 §4).

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/mi_perfil_update.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/entities/voluntario_create.dart';
import '../../domain/entities/voluntario_rol_asignacion.dart';
import '../../domain/entities/voluntario_update_admin.dart';
import '../../domain/entities/voluntarios_page.dart';
import '../../domain/repositories/voluntarios_repository.dart';
import '../datasources/voluntarios_api.dart';
import '../models/voluntario_model.dart';
import '../models/voluntario_rol_asignacion_model.dart';
import '../models/voluntario_summary_model.dart';

class VoluntariosRepositoryImpl implements VoluntariosRepository {
  final VoluntariosApi _api;

  const VoluntariosRepositoryImpl(this._api);

  @override
  Future<Result<VoluntariosPage>> list({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoVoluntario? estado,
  }) async {
    try {
      final response = await _api.list(
        skip: skip,
        limit: limit,
        query: query,
        estado: estado,
      );
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(VoluntarioSummaryModel.fromJson)
          .toList(growable: false);
      // http lowercases header names; account for both forms just in
      // case a proxy preserves the original casing.
      final totalRaw = response.headers['x-total-count'] ??
          response.headers['X-Total-Count'];
      final total = int.tryParse(totalRaw ?? '') ?? items.length;
      return Success(VoluntariosPage(items: items, total: total));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.list failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Voluntario>> getMyProfile() async {
    try {
      final json = await _api.getMe();
      return Success(VoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.getMyProfile failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Voluntario>> updateMyProfile(MiPerfilUpdate patch) async {
    try {
      final json = await _api.patchMe(patch.toJson());
      return Success(VoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.updateMyProfile failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Voluntario>> create(VoluntarioCreate data) async {
    try {
      final json = await _api.create(data.toJson());
      return Success(VoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      // 409 in POST /voluntarios is ambiguous: either DNI or email
      // collided. Surface a dedicated failure so the form can show a
      // single, accurate message instead of guessing which field.
      if (e.statusCode == 409) {
        return const Fail(VoluntariosFailure.dniOrEmailDuplicado());
      }
      if (e.statusCode == 502) {
        return const Fail(VoluntariosFailure.keycloakSyncFailed());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.create failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Voluntario>> getById(String id) async {
    try {
      final json = await _api.getById(id);
      return Success(VoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.getById failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Voluntario>> updateAdmin(
    String id,
    VoluntarioUpdateAdmin patch,
  ) async {
    try {
      final json = await _api.patchAdmin(id, patch.toJson());
      return Success(VoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      // Same 409 collapse rationale as create(): backend does not
      // disambiguate dni vs email collisions in the detail.
      if (e.statusCode == 409) {
        return const Fail(VoluntariosFailure.dniOrEmailDuplicado());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.updateAdmin failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<List<VoluntarioRolAsignacion>>> listRolesAsignados(
    String voluntarioId,
  ) async {
    try {
      final response = await _api.listRolesAsignados(voluntarioId);
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(VoluntarioRolAsignacionModel.fromJson)
          .toList(growable: false);
      return Success(items);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.listRolesAsignados failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VoluntarioRolAsignacion>> asignarRol(
    String voluntarioId,
    String rolId,
  ) async {
    try {
      final json = await _api.asignarRol(voluntarioId, rolId);
      return Success(VoluntarioRolAsignacionModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(VoluntariosFailure.rolYaAsignado());
      }
      if (e.statusCode == 404) {
        return const Fail(VoluntariosFailure.rolOAsignacionNoEncontrado());
      }
      if (e.statusCode == 502) {
        return const Fail(VoluntariosFailure.keycloakSyncFailed());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.asignarRol failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VoluntarioRolAsignacion>> quitarRol(
    String voluntarioId,
    String rolId,
  ) async {
    try {
      final json = await _api.quitarRol(voluntarioId, rolId);
      return Success(VoluntarioRolAsignacionModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const Fail(VoluntariosFailure.rolOAsignacionNoEncontrado());
      }
      if (e.statusCode == 502) {
        return const Fail(VoluntariosFailure.keycloakSyncFailed());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'voluntarios.quitarRol failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) {
      return const AuthFailure.sessionExpired();
    }
    if (e.statusCode == 404) {
      return const VoluntariosFailure.notFound();
    }
    if (e.statusCode == 409) {
      return const VoluntariosFailure.emailDuplicado();
    }
    return NetworkFailure.serverError(e.statusCode);
  }
}
