// Concrete FichajeRepository. Converts wire exceptions into FichajeFailure
// variants (guide 26 §4).

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/fichaje.dart';
import '../../domain/entities/fichaje_en_servicio.dart';
import '../../domain/entities/horas_acumuladas.dart';
import '../../domain/repositories/fichaje_repository.dart';
import '../datasources/fichaje_api.dart';
import '../models/fichaje_en_servicio_model.dart';
import '../models/fichaje_model.dart';
import '../models/horas_acumuladas_model.dart';

class FichajeRepositoryImpl implements FichajeRepository {
  final FichajeApi _api;

  const FichajeRepositoryImpl(this._api);

  @override
  Future<Result<Fichaje>> ficharEntrada(String servicioId) async {
    try {
      final json = await _api.ficharEntrada(servicioId);
      return Success(FichajeModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(_mapEntrada409(e));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'fichaje.ficharEntrada failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<Fichaje>> ficharSalida(String servicioId) async {
    try {
      final json = await _api.ficharSalida(servicioId);
      return Success(FichajeModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // El backend devuelve 404 cuando no hay entrada abierta (es
        // un "no estado" más que un "no encontrado").
        return const Fail(FichajeFailure.sinFichajeAbierto());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'fichaje.ficharSalida failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<List<FichajeEnServicio>>> listFichadosServicio(
    String servicioId,
  ) async {
    try {
      final response = await _api.listFichadosServicio(servicioId);
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(FichajeEnServicioModel.fromJson)
          .toList(growable: false);
      return Success(items);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'fichaje.listFichadosServicio failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<List<Fichaje>>> misFichajes() async {
    try {
      final response = await _api.misFichajes();
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(FichajeModel.fromJson)
          .toList(growable: false);
      return Success(items);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'fichaje.misFichajes failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<HorasAcumuladas>> misHoras() async {
    try {
      final json = await _api.misHoras();
      return Success(HorasAcumuladasModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'fichaje.misHoras failed: $e',
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
      return const FichajeFailure.notFound();
    }
    return NetworkFailure.serverError(e.statusCode);
  }

  /// El backend reutiliza 409 para tres situaciones distintas en
  /// `/entrada`. Las repartimos best-effort por el contenido del
  /// detail; si no encaja, caemos en yaFichado por ser la más
  /// frecuente desde la UI.
  Failure _mapEntrada409(ApiException e) {
    final detail = e.message.toLowerCase();
    if (detail.contains('no admite fichajes') ||
        detail.contains('no activo')) {
      return const FichajeFailure.servicioNoActivo();
    }
    if (detail.contains('no estás inscrito') ||
        detail.contains('no inscrito') ||
        detail.contains('convocado')) {
      return const FichajeFailure.voluntarioNoInscrito();
    }
    return const FichajeFailure.yaFichado();
  }
}
