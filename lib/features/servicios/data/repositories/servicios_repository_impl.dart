// Concrete ServiciosRepository. Converts wire exceptions into
// Failure variants. Per guide 26 §4 the rest of the app never sees
// ApiException directly.

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/servicio_create.dart';
import '../../domain/entities/servicio_inventario.dart';
import '../../domain/entities/servicios_page.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../../domain/entities/voluntario_inscrito.dart';
import '../../domain/repositories/servicios_repository.dart';
import '../datasources/servicios_api.dart';
import '../models/servicio_inventario_model.dart';
import '../models/servicio_model.dart';
import '../models/servicio_summary_model.dart';
import '../models/voluntario_inscrito_model.dart';

class ServiciosRepositoryImpl implements ServiciosRepository {
  final ServiciosApi _api;

  const ServiciosRepositoryImpl(this._api);

  @override
  Future<Result<ServiciosPage>> list({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoServicio? estado,
    TipoServicio? tipo,
  }) async {
    try {
      final response = await _api.list(
        skip: skip,
        limit: limit,
        query: query,
        estado: estado,
        tipo: tipo,
      );
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(ServicioSummaryModel.fromJson)
          .toList(growable: false);
      final totalRaw = response.headers['x-total-count'] ??
          response.headers['X-Total-Count'];
      final total = int.tryParse(totalRaw ?? '') ?? items.length;
      return Success(ServiciosPage(items: items, total: total));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.list failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> getById(String id) async {
    try {
      final json = await _api.getById(id);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.getById failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> create(ServicioCreate data) async {
    try {
      final json = await _api.create(data.toJson());
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.create failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> publicar(String id) async {
    try {
      final json = await _api.publicar(id);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(ServiciosFailure.transicionInvalida(_extractDetail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.publicar failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> convocar(
    String id, {
    List<String>? voluntarioIds,
  }) async {
    try {
      final json = await _api.convocar(id, voluntarioIds: voluntarioIds);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(ServiciosFailure.transicionInvalida(_extractDetail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.convocar failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> cerrar(
    String id, {
    String? observaciones,
  }) async {
    try {
      final json = await _api.cerrar(id, observaciones: observaciones);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(ServiciosFailure.transicionInvalida(_extractDetail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.cerrar failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> inscribirse(String id) async {
    try {
      final json = await _api.inscribirse(id);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // El backend devuelve dos mensajes distintos (ya inscrito vs
        // estado no admite). Usamos el detalle para diferenciar; si no
        // coincide, optamos por "ya inscrito" porque es el caso más
        // frecuente desde la UI.
        final detail = _extractDetail(e).toLowerCase();
        if (detail.contains('estado actual') ||
            detail.contains('no admite')) {
          return const Fail(ServiciosFailure.inscripcionNoPermitida());
        }
        return const Fail(ServiciosFailure.yaInscrito());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.inscribirse failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Servicio>> desapuntarse(String id) async {
    try {
      final json = await _api.desapuntarse(id);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const Fail(ServiciosFailure.noInscrito());
      }
      if (e.statusCode == 409) {
        return const Fail(ServiciosFailure.inscripcionNoPermitida());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.desapuntarse failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<List<VoluntarioInscrito>>> listVoluntarios(String id) async {
    try {
      final response = await _api.listVoluntarios(id);
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(VoluntarioInscritoModel.fromJson)
          .toList(growable: false);
      return Success(items);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.listVoluntarios failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<ServicioInventario>> getInventario(String id) async {
    try {
      final json = await _api.getInventario(id);
      return Success(ServicioInventarioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.getInventario failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> asignarMaterial(
    String id, {
    required String materialId,
    int cantidad = 1,
  }) async {
    try {
      await _api.asignarMaterial(id, {
        'material_id': materialId,
        'cantidad': cantidad,
      });
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(_mapAsignacion409(e, esVehiculo: false));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.asignarMaterial failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> asignarVehiculo(
    String id, {
    required String vehiculoId,
  }) async {
    try {
      await _api.asignarVehiculo(id, {'vehiculo_id': vehiculoId});
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(_mapAsignacion409(e, esVehiculo: true));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.asignarVehiculo failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  /// Los POST de asignar a servicio agrupan varios 409. El de solape temporal
  /// (Política A) llega como {"detail": {"mensaje": ..., "conflictos": [...]}},
  /// el único con esa clave; el resto son detail planos.
  Failure _mapAsignacion409(ApiException e, {required bool esVehiculo}) {
    final detail = e.message.toLowerCase();
    if (detail.contains('conflictos') ||
        detail.contains('solapad') ||
        detail.contains('ocupado')) {
      return const InventarioFailure.recursoSolapado();
    }
    if (detail.contains('no operativo') ||
        detail.contains('no está operativo')) {
      return esVehiculo
          ? const InventarioFailure.vehiculoNoOperativo()
          : const InventarioFailure.materialNoOperativo();
    }
    if (detail.contains('cantidad')) {
      return const InventarioFailure.cantidadInsuficiente();
    }
    if (detail.contains('tipo')) {
      return const InventarioFailure.tipoIncompatible();
    }
    return NetworkFailure.serverError(e.statusCode);
  }

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) {
      return const AuthFailure.sessionExpired();
    }
    if (e.statusCode == 404) {
      return const ServiciosFailure.notFound();
    }
    return NetworkFailure.serverError(e.statusCode);
  }

  /// El backend devuelve un cuerpo JSON con la forma {"detail": "..."}
  /// para errores. Lo extraemos best-effort; si no es JSON o no tiene
  /// detail, devolvemos el body crudo para que el snackbar siga siendo
  /// útil.
  String _extractDetail(ApiException e) {
    final body = e.message;
    final idx = body.indexOf('"detail"');
    if (idx < 0) return body;
    final colon = body.indexOf(':', idx);
    if (colon < 0) return body;
    final start = body.indexOf('"', colon + 1);
    if (start < 0) return body;
    final end = body.indexOf('"', start + 1);
    if (end < 0) return body;
    return body.substring(start + 1, end);
  }
}
