// Ubicaciones-submodule DI (E10). El catálogo de gestión vive bajo inventario
// porque solo material y vehículos referencian una ubicación base (guía 26
// §6). El `UbicacionesCatalogoService` de infraestructura (lectura para el
// picker) es independiente de esta capa de gestión.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/result.dart';
import '../../data/datasources/ubicaciones_api.dart';
import '../../data/repositories/ubicaciones_repository_impl.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/repositories/ubicaciones_repository.dart';
import '../../domain/usecases/actualizar_ubicacion.dart';
import '../../domain/usecases/crear_ubicacion.dart';
import '../../domain/usecases/eliminar_ubicacion.dart';
import '../../domain/usecases/listar_ubicaciones.dart';
import '../../domain/usecases/obtener_ubicacion.dart';

final ubicacionesApiProvider = Provider<UbicacionesApi>((ref) {
  return UbicacionesApi(ref.watch(apiClientProvider));
});

final ubicacionesRepositoryProvider = Provider<UbicacionesRepository>((ref) {
  return UbicacionesRepositoryImpl(ref.watch(ubicacionesApiProvider));
});

final listarUbicacionesProvider = Provider<ListarUbicaciones>((ref) {
  return ListarUbicaciones(ref.watch(ubicacionesRepositoryProvider));
});

final obtenerUbicacionProvider = Provider<ObtenerUbicacion>((ref) {
  return ObtenerUbicacion(ref.watch(ubicacionesRepositoryProvider));
});

/// Resuelve una ubicación del catálogo por id, exponiéndola como [AsyncValue].
/// La usa el botón "ver en el mapa" de las fichas de material/vehículo: el
/// detalle de inventario solo trae el FK de la ubicación, no sus coordenadas
/// (viven en el catálogo, E10), así que se cargan bajo demanda. Un `Fail` del
/// repositorio se propaga como error del provider; el consumidor decide cómo
/// degradar (el botón simplemente no se muestra).
final ubicacionPorIdProvider =
    FutureProvider.family<Ubicacion, String>((ref, id) async {
  final result = await ref.watch(obtenerUbicacionProvider).call(id);
  return switch (result) {
    Success(:final value) => value,
    Fail(:final failure) => throw failure,
  };
});

final crearUbicacionProvider = Provider<CrearUbicacion>((ref) {
  return CrearUbicacion(ref.watch(ubicacionesRepositoryProvider));
});

final actualizarUbicacionProvider = Provider<ActualizarUbicacion>((ref) {
  return ActualizarUbicacion(ref.watch(ubicacionesRepositoryProvider));
});

final eliminarUbicacionProvider = Provider<EliminarUbicacion>((ref) {
  return EliminarUbicacion(ref.watch(ubicacionesRepositoryProvider));
});
