// Implementación concreta de HistorialRepository. Convierte el envelope
// `ApiResponse<List<dynamic>>` en `HistorialPage` extrayendo
// `X-Total-Count`; envuelve cualquier error en Result<T>.

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/historial_page.dart';
import '../../domain/entities/resumen_voluntario.dart';
import '../../domain/entities/tipo_evento_voluntario.dart';
import '../../domain/repositories/historial_repository.dart';
import '../datasources/historial_api.dart';
import '../models/evento_voluntario_model.dart';
import '../models/resumen_voluntario_model.dart';

class HistorialRepositoryImpl implements HistorialRepository {
  final HistorialApi _api;

  const HistorialRepositoryImpl(this._api);

  @override
  Future<Result<HistorialPage>> obtenerHistorial({
    int skip = 0,
    int limit = 50,
    List<TipoEventoVoluntario>? tipos,
    DateTime? since,
    DateTime? until,
  }) async {
    try {
      final response = await _api.obtenerHistorial(
        skip: skip,
        limit: limit,
        tipos: tipos,
        since: since,
        until: until,
      );
      final eventos = response.body
          .map((e) =>
              EventoVoluntarioModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      final total = _parseTotalCount(response.headers, fallback: eventos.length);
      return Success(
        HistorialPage(
          eventos: eventos,
          total: total,
          skip: skip,
          limit: limit,
        ),
      );
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'historial.obtenerHistorial failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<ResumenVoluntario>> obtenerResumen() async {
    try {
      final json = await _api.obtenerResumen();
      return Success(ResumenVoluntarioModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'historial.obtenerResumen failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) return const AuthFailure.sessionExpired();
    if (e.statusCode == 404) return const VoluntariosFailure.notFound();
    return NetworkFailure.serverError(e.statusCode);
  }

  /// Acepta la cabecera con cualquier capitalización (HTTP es case
  /// insensitive, pero `package:http` baja todo a lowercase).
  int _parseTotalCount(Map<String, String> headers, {required int fallback}) {
    final raw = headers['x-total-count'] ?? headers['X-Total-Count'];
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  }
}
