// Repository contract for the inventario feature. Covers material,
// vehículo, asignaciones a voluntario y devoluciones. Asignación a
// servicio (US-05-06/07) NO entra en el alcance del MVP cliente y se
// deja como deuda explícita — el backend ya expone los endpoints.

import '../../../../infrastructure/error/result.dart';
import '../entities/asignacion_material.dart';
import '../entities/dotacion_vehiculo.dart';
import '../entities/estado_inventario.dart';
import '../entities/material_create.dart';
import '../entities/material_item.dart';
import '../entities/materiales_page.dart';
import '../entities/tipo_asignacion.dart';
import '../entities/tipo_material.dart';
import '../entities/tipo_vehiculo.dart';
import '../entities/vehiculo_create.dart';
import '../entities/vehiculo_item.dart';
import '../entities/vehiculos_page.dart';

abstract class InventarioRepository {
  // Material
  Future<Result<MaterialesPage>> listMaterial({
    int skip,
    int limit,
    String? query,
    EstadoInventario? estado,
    TipoMaterial? tipo,
    String? categoria,
  });
  Future<Result<MaterialItem>> getMaterial(String id);
  Future<Result<MaterialItem>> createMaterial(MaterialCreate data);
  Future<Result<MaterialItem>> reportarIncidenciaMaterial(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  });
  Future<Result<AsignacionMaterial>> asignarMaterialAVoluntario(
    String materialId, {
    required String voluntarioId,
    required TipoAsignacion tipo,
    int cantidad,
  });
  Future<Result<AsignacionMaterial>> devolverMaterial(
    String materialId, {
    required String voluntarioId,
    String? observaciones,
  });

  // Vehículo
  Future<Result<VehiculosPage>> listVehiculos({
    int skip,
    int limit,
    String? query,
    EstadoInventario? estado,
    TipoVehiculo? tipo,
  });
  Future<Result<VehiculoItem>> getVehiculo(String id);
  Future<Result<VehiculoItem>> createVehiculo(VehiculoCreate data);
  Future<Result<VehiculoItem>> reportarIncidenciaVehiculo(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  });

  // Dotación fija de vehículo (PR3)
  Future<Result<List<DotacionVehiculo>>> listarDotacionVehiculo(
    String vehiculoId,
  );
  Future<Result<DotacionVehiculo>> asignarDotacionVehiculo(
    String vehiculoId, {
    required String materialId,
    int cantidad,
  });
  Future<Result<void>> liberarDotacionVehiculo(
    String vehiculoId, {
    required String asignacionId,
  });
}
