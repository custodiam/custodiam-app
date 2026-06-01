// Ubicaciones-submodule DI (E10). El catálogo de gestión vive bajo inventario
// porque solo material y vehículos referencian una ubicación base (guía 26
// §6). El `UbicacionesCatalogoService` de infraestructura (lectura para el
// picker) es independiente de esta capa de gestión.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/ubicaciones_api.dart';
import '../../data/repositories/ubicaciones_repository_impl.dart';
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

final crearUbicacionProvider = Provider<CrearUbicacion>((ref) {
  return CrearUbicacion(ref.watch(ubicacionesRepositoryProvider));
});

final actualizarUbicacionProvider = Provider<ActualizarUbicacion>((ref) {
  return ActualizarUbicacion(ref.watch(ubicacionesRepositoryProvider));
});

final eliminarUbicacionProvider = Provider<EliminarUbicacion>((ref) {
  return EliminarUbicacion(ref.watch(ubicacionesRepositoryProvider));
});
