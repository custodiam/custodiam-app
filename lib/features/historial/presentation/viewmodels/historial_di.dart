// DI de la feature historial (US-02-06). Cadena estándar: api → repo →
// use cases.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/historial_api.dart';
import '../../data/repositories/historial_repository_impl.dart';
import '../../domain/repositories/historial_repository.dart';
import '../../domain/usecases/obtener_mi_historial.dart';
import '../../domain/usecases/obtener_mi_resumen.dart';

final historialApiProvider = Provider<HistorialApi>((ref) {
  return HistorialApi(ref.watch(apiClientProvider));
});

final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  return HistorialRepositoryImpl(ref.watch(historialApiProvider));
});

final obtenerMiHistorialProvider = Provider<ObtenerMiHistorial>((ref) {
  return ObtenerMiHistorial(ref.watch(historialRepositoryProvider));
});

final obtenerMiResumenProvider = Provider<ObtenerMiResumen>((ref) {
  return ObtenerMiResumen(ref.watch(historialRepositoryProvider));
});
