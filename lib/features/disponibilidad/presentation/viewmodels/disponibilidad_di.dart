// DI de la feature disponibilidad (US-02-04). Sigue el patrón fijado
// por las otras features del Sprint 5: providers explícitos por capa
// (api → repo → use case) que los tests puedan overridear sin tocar
// el ViewModel.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/disponibilidad_api.dart';
import '../../data/repositories/disponibilidad_repository_impl.dart';
import '../../domain/repositories/disponibilidad_repository.dart';
import '../../domain/usecases/marcar_mi_dia.dart';
import '../../domain/usecases/obtener_mi_mes.dart';

final disponibilidadApiProvider = Provider<DisponibilidadApi>((ref) {
  return DisponibilidadApi(ref.watch(apiClientProvider));
});

final disponibilidadRepositoryProvider =
    Provider<DisponibilidadRepository>((ref) {
  return DisponibilidadRepositoryImpl(ref.watch(disponibilidadApiProvider));
});

final obtenerMiMesProvider = Provider<ObtenerMiMes>((ref) {
  return ObtenerMiMes(ref.watch(disponibilidadRepositoryProvider));
});

final marcarMiDiaProvider = Provider<MarcarMiDia>((ref) {
  return MarcarMiDia(ref.watch(disponibilidadRepositoryProvider));
});
