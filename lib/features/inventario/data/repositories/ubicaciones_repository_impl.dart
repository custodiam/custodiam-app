// UbicacionesRepository concreto. Convierte ApiException en
// UbicacionesFailure (guía 26 §4). El 409 significa nombre duplicado en
// crear/actualizar y "en uso" en eliminar; se distingue por el método, sin
// parsear el detail.

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/entities/ubicaciones_page.dart';
import '../../domain/repositories/ubicaciones_repository.dart';
import '../datasources/ubicaciones_api.dart';
import '../models/ubicacion_model.dart';

class UbicacionesRepositoryImpl implements UbicacionesRepository {
  final UbicacionesApi _api;

  const UbicacionesRepositoryImpl(this._api);

  @override
  Future<Result<UbicacionesPage>> listar({
    int skip = 0,
    int limit = 50,
    String? query,
  }) async {
    try {
      final response =
          await _api.listar(skip: skip, limit: limit, query: query);
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(UbicacionModel.fromJson)
          .toList(growable: false);
      final totalRaw = response.headers['x-total-count'] ??
          response.headers['X-Total-Count'];
      final total = int.tryParse(totalRaw ?? '') ?? items.length;
      return Success(UbicacionesPage(items: items, total: total));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('ubicaciones.listar failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Ubicacion>> obtener(String id) async {
    try {
      final json = await _api.obtener(id);
      return Success(UbicacionModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('ubicaciones.obtener failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Ubicacion>> crear({
    required String nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) async {
    try {
      final json = await _api.crear(
        _body(nombre: nombre, descripcion: descripcion, lat: lat, lng: lng),
      );
      return Success(UbicacionModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(UbicacionesFailure.nombreDuplicado());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('ubicaciones.crear failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Ubicacion>> actualizar(
    String id, {
    String? nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) async {
    try {
      final json = await _api.actualizar(
        id,
        _bodyActualizar(
          nombre: nombre,
          descripcion: descripcion,
          lat: lat,
          lng: lng,
        ),
      );
      return Success(UbicacionModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(UbicacionesFailure.nombreDuplicado());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('ubicaciones.actualizar failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> eliminar(String id) async {
    try {
      await _api.eliminar(id);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(UbicacionesFailure.enUso());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('ubicaciones.eliminar failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  /// Body para POST (crear). Solo incluye lo no nulo: no fija descripción ni
  /// coordenadas si no se aportan. lat/lng van juntas o ninguna (invariante
  /// del backend). `nombre` siempre llega en crear.
  Map<String, dynamic> _body({
    String? nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;
    if (lat != null && lng != null) {
      body['lat'] = lat;
      body['lng'] = lng;
    }
    return body;
  }

  /// Body para PATCH (actualizar). A diferencia de [_body], envía
  /// `descripcion`, `lat` y `lng` SIEMPRE (incluido null) para que la edición
  /// refleje borrados: quitar las coordenadas o vaciar la descripción debe
  /// persistir, no quedar como "no tocar". El backend aplica el patch con
  /// `exclude_unset=True`, así que una clave enviada con null limpia la
  /// columna; el validador "ambos o ninguno" admite el par (null, null) y el
  /// formulario fija/quita lat+lng juntos, así que nunca se manda una sola.
  /// `nombre` solo se incluye si llega (el formulario lo valida no vacío).
  Map<String, dynamic> _bodyActualizar({
    String? nombre,
    String? descripcion,
    double? lat,
    double? lng,
  }) {
    final body = <String, dynamic>{
      'descripcion': descripcion,
      'lat': lat,
      'lng': lng,
    };
    if (nombre != null) body['nombre'] = nombre;
    return body;
  }

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) return const AuthFailure.sessionExpired();
    if (e.statusCode == 404) return const UbicacionesFailure.notFound();
    return NetworkFailure.serverError(e.statusCode);
  }
}
