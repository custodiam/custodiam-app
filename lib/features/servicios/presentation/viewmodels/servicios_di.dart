// Servicios-feature DI: composes ApiClient -> DataSource -> Repository
// -> UseCase into Riverpod providers (guide 26 §6).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/servicios_api.dart';
import '../../data/repositories/servicios_repository_impl.dart';
import '../../domain/repositories/servicios_repository.dart';
import '../../domain/usecases/actualizar_servicio.dart';
import '../../domain/usecases/asignar_material_servicio.dart';
import '../../domain/usecases/asignar_vehiculo_servicio.dart';
import '../../domain/usecases/cerrar_servicio.dart';
import '../../domain/usecases/convocar_servicio.dart';
import '../../domain/usecases/crear_servicio.dart';
import '../../domain/usecases/desapuntarse_servicio.dart';
import '../../domain/usecases/eliminar_servicio.dart';
import '../../domain/usecases/get_inventario_servicio.dart';
import '../../domain/usecases/get_servicio_by_id.dart';
import '../../domain/usecases/inscribirse_servicio.dart';
import '../../domain/usecases/list_servicios.dart';
import '../../domain/usecases/list_voluntarios_servicio.dart';
import '../../domain/usecases/publicar_servicio.dart';
import '../../domain/usecases/quitar_material_servicio.dart';
import '../../domain/usecases/quitar_vehiculo_servicio.dart';

final serviciosApiProvider = Provider<ServiciosApi>((ref) {
  return ServiciosApi(ref.watch(apiClientProvider));
});

final serviciosRepositoryProvider = Provider<ServiciosRepository>((ref) {
  return ServiciosRepositoryImpl(ref.watch(serviciosApiProvider));
});

final listServiciosProvider = Provider<ListServicios>((ref) {
  return ListServicios(ref.watch(serviciosRepositoryProvider));
});

final getServicioByIdProvider = Provider<GetServicioById>((ref) {
  return GetServicioById(ref.watch(serviciosRepositoryProvider));
});

final crearServicioProvider = Provider<CrearServicio>((ref) {
  return CrearServicio(ref.watch(serviciosRepositoryProvider));
});

final actualizarServicioProvider = Provider<ActualizarServicio>((ref) {
  return ActualizarServicio(ref.watch(serviciosRepositoryProvider));
});

final eliminarServicioProvider = Provider<EliminarServicio>((ref) {
  return EliminarServicio(ref.watch(serviciosRepositoryProvider));
});

final publicarServicioProvider = Provider<PublicarServicio>((ref) {
  return PublicarServicio(ref.watch(serviciosRepositoryProvider));
});

final convocarServicioProvider = Provider<ConvocarServicio>((ref) {
  return ConvocarServicio(ref.watch(serviciosRepositoryProvider));
});

final cerrarServicioProvider = Provider<CerrarServicio>((ref) {
  return CerrarServicio(ref.watch(serviciosRepositoryProvider));
});

final inscribirseServicioProvider = Provider<InscribirseServicio>((ref) {
  return InscribirseServicio(ref.watch(serviciosRepositoryProvider));
});

final desapuntarseServicioProvider = Provider<DesapuntarseServicio>((ref) {
  return DesapuntarseServicio(ref.watch(serviciosRepositoryProvider));
});

final listVoluntariosServicioProvider = Provider<ListVoluntariosServicio>((
  ref,
) {
  return ListVoluntariosServicio(ref.watch(serviciosRepositoryProvider));
});

final getInventarioServicioProvider = Provider<GetInventarioServicio>((ref) {
  return GetInventarioServicio(ref.watch(serviciosRepositoryProvider));
});

final asignarMaterialServicioProvider = Provider<AsignarMaterialServicio>((
  ref,
) {
  return AsignarMaterialServicio(ref.watch(serviciosRepositoryProvider));
});

final asignarVehiculoServicioProvider = Provider<AsignarVehiculoServicio>((
  ref,
) {
  return AsignarVehiculoServicio(ref.watch(serviciosRepositoryProvider));
});

final quitarMaterialServicioProvider = Provider<QuitarMaterialServicio>((ref) {
  return QuitarMaterialServicio(ref.watch(serviciosRepositoryProvider));
});

final quitarVehiculoServicioProvider = Provider<QuitarVehiculoServicio>((ref) {
  return QuitarVehiculoServicio(ref.watch(serviciosRepositoryProvider));
});
