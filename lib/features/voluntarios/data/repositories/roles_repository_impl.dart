import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/rol.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_api.dart';
import '../models/rol_model.dart';

class RolesRepositoryImpl implements RolesRepository {
  final RolesApi _api;

  const RolesRepositoryImpl(this._api);

  @override
  Future<Result<List<Rol>>> listCatalogo() async {
    try {
      final response = await _api.listCatalogo();
      final roles = response.body
          .cast<Map<String, dynamic>>()
          .map(RolModel.fromJson)
          .toList(growable: false);
      return Success(roles);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const Fail(AuthFailure.sessionExpired());
      }
      return Fail(NetworkFailure.serverError(e.statusCode));
    } catch (e, stack) {
      dev.log(
        'roles.listCatalogo failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }
}
