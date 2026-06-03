// Inventario-feature DI (guide 26 §6).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/inventario_api.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../../domain/usecases/actualizar_material.dart';
import '../../domain/usecases/actualizar_vehiculo.dart';
import '../../domain/usecases/asignar_dotacion_vehiculo.dart';
import '../../domain/usecases/asignar_material_a_voluntario.dart';
import '../../domain/usecases/create_material.dart';
import '../../domain/usecases/create_vehiculo.dart';
import '../../domain/usecases/devolver_material.dart';
import '../../domain/usecases/eliminar_material.dart';
import '../../domain/usecases/eliminar_vehiculo.dart';
import '../../domain/usecases/get_material.dart';
import '../../domain/usecases/get_vehiculo.dart';
import '../../domain/usecases/liberar_dotacion_vehiculo.dart';
import '../../domain/usecases/list_materiales.dart';
import '../../domain/usecases/list_vehiculos.dart';
import '../../domain/usecases/listar_dotacion_vehiculo.dart';
import '../../domain/usecases/reportar_incidencia_material.dart';
import '../../domain/usecases/reportar_incidencia_vehiculo.dart';

final inventarioApiProvider = Provider<InventarioApi>((ref) {
  return InventarioApi(ref.watch(apiClientProvider));
});

final inventarioRepositoryProvider = Provider<InventarioRepository>((ref) {
  return InventarioRepositoryImpl(ref.watch(inventarioApiProvider));
});

final listMaterialesProvider = Provider<ListMateriales>((ref) {
  return ListMateriales(ref.watch(inventarioRepositoryProvider));
});

final getMaterialProvider = Provider<GetMaterial>((ref) {
  return GetMaterial(ref.watch(inventarioRepositoryProvider));
});

final createMaterialProvider = Provider<CreateMaterial>((ref) {
  return CreateMaterial(ref.watch(inventarioRepositoryProvider));
});

final actualizarMaterialProvider = Provider<ActualizarMaterial>((ref) {
  return ActualizarMaterial(ref.watch(inventarioRepositoryProvider));
});

final eliminarMaterialProvider = Provider<EliminarMaterial>((ref) {
  return EliminarMaterial(ref.watch(inventarioRepositoryProvider));
});

final reportarIncidenciaMaterialProvider =
    Provider<ReportarIncidenciaMaterial>((ref) {
  return ReportarIncidenciaMaterial(ref.watch(inventarioRepositoryProvider));
});

final asignarMaterialAVoluntarioProvider =
    Provider<AsignarMaterialAVoluntario>((ref) {
  return AsignarMaterialAVoluntario(ref.watch(inventarioRepositoryProvider));
});

final devolverMaterialProvider = Provider<DevolverMaterial>((ref) {
  return DevolverMaterial(ref.watch(inventarioRepositoryProvider));
});

final listVehiculosProvider = Provider<ListVehiculos>((ref) {
  return ListVehiculos(ref.watch(inventarioRepositoryProvider));
});

final getVehiculoProvider = Provider<GetVehiculo>((ref) {
  return GetVehiculo(ref.watch(inventarioRepositoryProvider));
});

final createVehiculoProvider = Provider<CreateVehiculo>((ref) {
  return CreateVehiculo(ref.watch(inventarioRepositoryProvider));
});

final actualizarVehiculoProvider = Provider<ActualizarVehiculo>((ref) {
  return ActualizarVehiculo(ref.watch(inventarioRepositoryProvider));
});

final eliminarVehiculoProvider = Provider<EliminarVehiculo>((ref) {
  return EliminarVehiculo(ref.watch(inventarioRepositoryProvider));
});

final reportarIncidenciaVehiculoProvider =
    Provider<ReportarIncidenciaVehiculo>((ref) {
  return ReportarIncidenciaVehiculo(ref.watch(inventarioRepositoryProvider));
});

final listarDotacionVehiculoProvider = Provider<ListarDotacionVehiculo>((ref) {
  return ListarDotacionVehiculo(ref.watch(inventarioRepositoryProvider));
});

final asignarDotacionVehiculoProvider =
    Provider<AsignarDotacionVehiculo>((ref) {
  return AsignarDotacionVehiculo(ref.watch(inventarioRepositoryProvider));
});

final liberarDotacionVehiculoProvider =
    Provider<LiberarDotacionVehiculo>((ref) {
  return LiberarDotacionVehiculo(ref.watch(inventarioRepositoryProvider));
});
