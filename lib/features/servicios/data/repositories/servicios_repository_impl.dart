// Concrete ServiciosRepository. Converts wire exceptions into
// Failure variants. Per guide 26 §4 the rest of the app never sees
// ApiException directly.

import 'dart:convert';
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
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final response = await _api.list(
        skip: skip,
        limit: limit,
        query: query,
        estado: estado,
        tipo: tipo,
        desde: desde,
        hasta: hasta,
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
  Future<Result<Servicio>> update(
    String id,
    Map<String, dynamic> campos,
  ) async {
    try {
      final json = await _api.update(id, campos);
      return Success(ServicioModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(ServiciosFailure.tieneActividad(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.update failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _api.delete(id);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // El servicio tiene actividad (inscripciones/fichajes/recursos): el
        // backend devuelve "ciérralo en lugar de borrarlo". Conservamos ese
        // mensaje para mostrarlo tal cual en la ficha.
        return Fail(ServiciosFailure.tieneActividad(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'servicios.delete failed: $e',
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
        // estado no admite). Usamos el detalle para diferenciar; el caso
        // "ya inscrito" tiene un texto propio claro, pero el resto de 409
        // conserva el mensaje real del backend en vez de un texto fijo, para
        // no descartar la causa concreta del rechazo.
        final detail = _extractDetail(e).toLowerCase();
        if (detail.contains('ya') && detail.contains('inscrit')) {
          return const Fail(ServiciosFailure.yaInscrito());
        }
        return Fail(ServiciosFailure.tieneActividad(_detail(e)));
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
        // Cualquier 409 al darse de baja (p. ej. el servicio ya no admite la
        // operación en su estado) conserva el mensaje real del backend en vez
        // de colapsarlo a un texto fijo de "inscripción no permitida", que
        // resultaba engañoso. (El backend ya permite la baja a un convocado;
        // los 409 que queden son situaciones reales que el usuario debe leer.)
        return Fail(ServiciosFailure.tieneActividad(_detail(e)));
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

  /// Los POST de asignar a servicio agrupan varios 409 y los serializa de dos
  /// formas distintas:
  ///
  /// - **Solape temporal** (Política A): `detail` es un objeto
  ///   `{"mensaje": ..., "conflictos": [...]}`. Es el único 409 con esa forma.
  ///   Usamos el `mensaje` del backend y, si hay conflictos, los anexamos para
  ///   que el usuario sepa cuántos servicios están en colisión.
  /// - **El resto** (ServicioCerrado, MaterialNoOperativo,
  ///   TipoAsignacionNoCompatible, CantidadInsuficiente): `detail` es una
  ///   cadena. La clasificamos por su contenido y la portamos en el [Failure]
  ///   para no descartar el motivo concreto del rechazo.
  ///
  /// Si el cuerpo no es el JSON esperado, caemos a [ServerError] conservando
  /// el código.
  Failure _mapAsignacion409(ApiException e, {required bool esVehiculo}) {
    final detail = _decodeDetail(e);
    if (detail is Map) {
      // Forma de solape: {"mensaje": ..., "conflictos": [...]}.
      final mensaje = detail['mensaje'];
      final conflictos = detail['conflictos'];
      final texto = mensaje is String ? mensaje : null;
      if (conflictos is List && conflictos.isNotEmpty) {
        final n = conflictos.length;
        final sufijo = n == 1
            ? ' (1 conflicto)'
            : ' ($n conflictos)';
        return InventarioFailure.recursoSolapado(
          '${texto ?? 'El recurso ya está reservado en ese intervalo.'}'
          '$sufijo',
        );
      }
      return InventarioFailure.recursoSolapado(texto);
    }

    if (detail is String) {
      final lower = detail.toLowerCase();
      if (lower.contains('cerrad')) {
        return ServiciosFailure.cerrado(detail);
      }
      if (lower.contains('solapad') ||
          lower.contains('ocupad') ||
          lower.contains('reservad')) {
        return InventarioFailure.recursoSolapado(detail);
      }
      if (lower.contains('operativo')) {
        return esVehiculo
            ? InventarioFailure.vehiculoNoOperativo(detail)
            : InventarioFailure.materialNoOperativo(detail);
      }
      if (lower.contains('cantidad')) {
        return InventarioFailure.cantidadInsuficiente(detail);
      }
      if (lower.contains('tipo')) {
        return InventarioFailure.tipoIncompatible(detail);
      }
      // Detail legible pero no clasificable: lo mostramos tal cual.
      return InventarioFailure.conflicto(detail);
    }

    return NetworkFailure.serverError(e.statusCode);
  }

  /// Decodifica el `detail` de un 409 de asignación. Devuelve el `Map` o la
  /// `String` que cuelga de `detail`; `null` si el cuerpo no es JSON con esa
  /// clave (para que el llamador caiga a [ServerError]).
  Object? _decodeDetail(ApiException e) {
    try {
      final decoded = jsonDecode(e.message);
      if (decoded is Map && decoded.containsKey('detail')) {
        return decoded['detail'];
      }
    } on FormatException {
      // Cuerpo no-JSON: el llamador decide el fallback.
    }
    return null;
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

  /// Extrae el `detail` legible de un 409 cuando el backend lo serializa como
  /// `{"detail": "..."}`. Devuelve `null` si el cuerpo no es ese JSON (o
  /// `detail` no es cadena), para que el [Failure] use su mensaje por defecto.
  /// Espeja el helper homónimo del módulo de inventario.
  String? _detail(ApiException e) {
    try {
      final decoded = jsonDecode(e.message);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      // Cuerpo no-JSON: nos quedamos con el mensaje por defecto del Failure.
    }
    return null;
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
