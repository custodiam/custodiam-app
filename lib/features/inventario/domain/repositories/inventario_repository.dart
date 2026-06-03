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

  /// Actualiza parcialmente un material (PATCH). [campos] solo lleva las
  /// claves a modificar (cuerpo parcial del backend). Mapea 404 → notFound y
  /// 409 → conflicto con el mensaje del backend (p. ej. código duplicado).
  Future<Result<MaterialItem>> updateMaterial(
    String id,
    Map<String, dynamic> campos,
  );

  /// Elimina un material. El backend responde 204; un 409 indica que el
  /// material todavía tiene asignaciones activas.
  Future<Result<void>> deleteMaterial(String id);
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

  /// Actualiza parcialmente un vehículo (PATCH). Mismo contrato de errores que
  /// [updateMaterial] (404 → notFound, 409 → conflicto con mensaje, p. ej.
  /// matrícula duplicada).
  Future<Result<VehiculoItem>> updateVehiculo(
    String id,
    Map<String, dynamic> campos,
  );

  /// Elimina un vehículo. 204 en éxito; 409 si tiene asignaciones activas.
  Future<Result<void>> deleteVehiculo(String id);
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
