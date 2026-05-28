// Implementación concreta de DisponibilidadRepository. Llama al API y
// envuelve la respuesta en Result<T>; nunca lanza excepciones a través
// de capas. Mapea los 404 (voluntario no encontrado) y los 422 con
// payload "FechaPasada" a failures tipados del dominio.

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/dia_disponibilidad.dart';
import '../../domain/entities/mes_disponibilidad.dart';
import '../../domain/repositories/disponibilidad_repository.dart';
import '../datasources/disponibilidad_api.dart';
import '../models/dia_disponibilidad_model.dart';

class DisponibilidadRepositoryImpl implements DisponibilidadRepository {
  final DisponibilidadApi _api;

  const DisponibilidadRepositoryImpl(this._api);

  @override
  Future<Result<MesDisponibilidad>> obtenerMes({
    required int year,
    required int month,
  }) async {
    try {
      final json = await _api.obtenerMes(year: year, month: month);
      return Success(MesDisponibilidadModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'disponibilidad.obtenerMes failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<DiaDisponibilidad>> marcarDia({
    required DateTime fecha,
    required bool disponible,
  }) async {
    try {
      final json = await _api.marcarDia(fecha: fecha, disponible: disponible);
      return Success(DiaDisponibilidadModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'disponibilidad.marcarDia failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  /// Reparte el `ApiException` entre los failures de dominio. El 422
  /// se interpreta SIEMPRE como `FechaPasada` desde el cliente: es la
  /// única regla de dominio del backend que devuelve 422 (el otro caso,
  /// `MesInvalido`, ya está pre-filtrado por el GET que valida el rango
  /// del Query antes incluso de tocar el service).
  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) return const AuthFailure.sessionExpired();
    if (e.statusCode == 404) return const VoluntariosFailure.notFound();
    if (e.statusCode == 422) return const DisponibilidadFailure.fechaPasada();
    return NetworkFailure.serverError(e.statusCode);
  }
}
