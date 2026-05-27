// Fichaje-feature DI (guide 26 §6).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/fichaje_api.dart';
import '../../data/repositories/fichaje_repository_impl.dart';
import '../../domain/repositories/fichaje_repository.dart';
import '../../domain/usecases/fichar_entrada.dart';
import '../../domain/usecases/fichar_salida.dart';
import '../../domain/usecases/get_mis_fichajes.dart';
import '../../domain/usecases/get_mis_horas.dart';
import '../../domain/usecases/list_fichados_servicio.dart';

final fichajeApiProvider = Provider<FichajeApi>((ref) {
  return FichajeApi(ref.watch(apiClientProvider));
});

final fichajeRepositoryProvider = Provider<FichajeRepository>((ref) {
  return FichajeRepositoryImpl(ref.watch(fichajeApiProvider));
});

final ficharEntradaProvider = Provider<FicharEntrada>((ref) {
  return FicharEntrada(ref.watch(fichajeRepositoryProvider));
});

final ficharSalidaProvider = Provider<FicharSalida>((ref) {
  return FicharSalida(ref.watch(fichajeRepositoryProvider));
});

final listFichadosServicioProvider = Provider<ListFichadosServicio>((ref) {
  return ListFichadosServicio(ref.watch(fichajeRepositoryProvider));
});

final getMisFichajesProvider = Provider<GetMisFichajes>((ref) {
  return GetMisFichajes(ref.watch(fichajeRepositoryProvider));
});

final getMisHorasProvider = Provider<GetMisHoras>((ref) {
  return GetMisHoras(ref.watch(fichajeRepositoryProvider));
});
