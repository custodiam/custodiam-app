// Concrete InventarioRepository. Converts ApiException to
// InventarioFailure variants (guide 26 §4).

import 'dart:convert';
import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/asignacion_material.dart';
import '../../domain/entities/dotacion_vehiculo.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_create.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/materiales_page.dart';
import '../../domain/entities/tipo_asignacion.dart';
import '../../domain/entities/tipo_material.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_create.dart';
import '../../domain/entities/vehiculo_item.dart';
import '../../domain/entities/vehiculos_page.dart';
import '../../domain/repositories/inventario_repository.dart';
import '../datasources/inventario_api.dart';
import '../models/asignacion_material_model.dart';
import '../models/dotacion_vehiculo_model.dart';
import '../models/material_item_model.dart';
import '../models/material_summary_model.dart';
import '../models/vehiculo_item_model.dart';
import '../models/vehiculo_summary_model.dart';

class InventarioRepositoryImpl implements InventarioRepository {
  final InventarioApi _api;

  const InventarioRepositoryImpl(this._api);

  @override
  Future<Result<MaterialesPage>> listMaterial({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoMaterial? tipo,
    String? categoria,
  }) async {
    try {
      final response = await _api.listMaterial(
        skip: skip,
        limit: limit,
        query: query,
        estado: estado,
        tipo: tipo,
        categoria: categoria,
      );
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(MaterialSummaryModel.fromJson)
          .toList(growable: false);
      final totalRaw = response.headers['x-total-count'] ??
          response.headers['X-Total-Count'];
      final total = int.tryParse(totalRaw ?? '') ?? items.length;
      return Success(MaterialesPage(items: items, total: total));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log(
        'inventario.listMaterial failed: $e',
        name: 'API',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<MaterialItem>> getMaterial(String id) async {
    try {
      final json = await _api.getMaterial(id);
      return Success(MaterialItemModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.getMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<MaterialItem>> createMaterial(MaterialCreate data) async {
    try {
      final json = await _api.createMaterial(data.toJson());
      return Success(MaterialItemModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.createMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<MaterialItem>> updateMaterial(
    String id,
    Map<String, dynamic> campos,
  ) async {
    try {
      final json = await _api.updateMaterial(id, campos);
      return Success(MaterialItemModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(InventarioFailure.conflicto(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.updateMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> deleteMaterial(String id) async {
    try {
      await _api.deleteMaterial(id);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(InventarioFailure.enUso(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.deleteMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<MaterialItem>> reportarIncidenciaMaterial(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) async {
    try {
      final json = await _api.reportarIncidenciaMaterial(id, {
        'tipo': nuevoEstado.wire,
        'descripcion': descripcion,
      });
      return Success(MaterialItemModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(InventarioFailure.estadoFinal());
      }
      if (e.statusCode == 422) {
        return const Fail(InventarioFailure.estadoIncidenciaInvalido());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.incidenciaMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<AsignacionMaterial>> asignarMaterialAVoluntario(
    String materialId, {
    required String voluntarioId,
    required TipoAsignacion tipo,
    int cantidad = 1,
  }) async {
    try {
      final json = await _api.asignarMaterialAVoluntario(materialId, {
        'voluntario_id': voluntarioId,
        'tipo': tipo.wire,
        'cantidad': cantidad,
      });
      return Success(AsignacionMaterialModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(_mapAsignacion409(e));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.asignarMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<AsignacionMaterial>> devolverMaterial(
    String materialId, {
    required String voluntarioId,
    String? observaciones,
  }) async {
    try {
      final body = <String, dynamic>{'voluntario_id': voluntarioId};
      if (observaciones != null && observaciones.isNotEmpty) {
        body['observaciones'] = observaciones;
      }
      final json = await _api.devolverMaterial(materialId, body);
      return Success(AsignacionMaterialModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // El backend distingue "material no encontrado" y "asignación
        // no encontrada"; ambos llegan como 404. Diferenciamos por el
        // detail; si no llega, asumimos asignación porque es lo más
        // habitual desde la UI (el material existía al pulsar).
        final detail = e.message.toLowerCase();
        if (detail.contains('material')) {
          return const Fail(InventarioFailure.notFound());
        }
        return const Fail(InventarioFailure.asignacionNoEncontrada());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.devolverMaterial failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VehiculosPage>> listVehiculos({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoVehiculo? tipo,
  }) async {
    try {
      final response = await _api.listVehiculos(
        skip: skip,
        limit: limit,
        query: query,
        estado: estado,
        tipo: tipo,
      );
      final items = response.body
          .cast<Map<String, dynamic>>()
          .map(VehiculoSummaryModel.fromJson)
          .toList(growable: false);
      final totalRaw = response.headers['x-total-count'] ??
          response.headers['X-Total-Count'];
      final total = int.tryParse(totalRaw ?? '') ?? items.length;
      return Success(VehiculosPage(items: items, total: total));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.listVehiculos failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VehiculoItem>> getVehiculo(String id) async {
    try {
      final json = await _api.getVehiculo(id);
      return Success(VehiculoItemModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.getVehiculo failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VehiculoItem>> createVehiculo(VehiculoCreate data) async {
    try {
      final json = await _api.createVehiculo(data.toJson());
      return Success(VehiculoItemModel.fromJson(json));
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.createVehiculo failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VehiculoItem>> updateVehiculo(
    String id,
    Map<String, dynamic> campos,
  ) async {
    try {
      final json = await _api.updateVehiculo(id, campos);
      return Success(VehiculoItemModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(InventarioFailure.conflicto(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.updateVehiculo failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> deleteVehiculo(String id) async {
    try {
      await _api.deleteVehiculo(id);
      return const Success(null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(InventarioFailure.enUso(_detail(e)));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.deleteVehiculo failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<VehiculoItem>> reportarIncidenciaVehiculo(
    String id, {
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) async {
    try {
      final json = await _api.reportarIncidenciaVehiculo(id, {
        'tipo': nuevoEstado.wire,
        'descripcion': descripcion,
      });
      return Success(VehiculoItemModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return const Fail(InventarioFailure.estadoFinal());
      }
      if (e.statusCode == 422) {
        return const Fail(InventarioFailure.estadoIncidenciaInvalido());
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.incidenciaVehiculo failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<List<DotacionVehiculo>>> listarDotacionVehiculo(
    String vehiculoId,
  ) async {
    try {
      final res = await _api.listarDotacionVehiculo(vehiculoId);
      final items = res
          .cast<Map<String, dynamic>>()
          .map(DotacionVehiculoModel.fromJson)
          .toList(growable: false);
      return Success(items);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.listarDotacion failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<DotacionVehiculo>> asignarDotacionVehiculo(
    String vehiculoId, {
    required String materialId,
    int cantidad = 1,
  }) async {
    try {
      final json = await _api.asignarDotacionVehiculo(vehiculoId, {
        'material_id': materialId,
        'cantidad': cantidad,
      });
      return Success(DotacionVehiculoModel.fromJson(json));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return Fail(_mapAsignacion409(e));
      }
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.asignarDotacion failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<void>> liberarDotacionVehiculo(
    String vehiculoId, {
    required String asignacionId,
  }) async {
    try {
      await _api.liberarDotacionVehiculo(vehiculoId, asignacionId);
      return const Success(null);
    } on ApiException catch (e) {
      return Fail(_mapApiException(e));
    } catch (e, stack) {
      dev.log('inventario.liberarDotacion failed: $e',
          name: 'API', error: e, stackTrace: stack);
      return const Fail(NetworkFailure.unknown());
    }
  }

  Failure _mapApiException(ApiException e) {
    if (e.statusCode == 401) return const AuthFailure.sessionExpired();
    if (e.statusCode == 404) return const InventarioFailure.notFound();
    return NetworkFailure.serverError(e.statusCode);
  }

  /// Extrae el `detail` legible de un error del backend. FastAPI serializa los
  /// errores como `{"detail": "..."}`; `ApiException.message` es el cuerpo
  /// crudo. Si el cuerpo no es ese JSON (o `detail` no es una cadena) se
  /// devuelve `null` para que el [Failure] use su mensaje por defecto.
  String? _detail(ApiException e) {
    try {
      final decoded = jsonDecode(e.message);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } on FormatException {
      // Cuerpo no-JSON: nos quedamos con el mensaje por defecto del Failure.
    }
    return null;
  }

  /// El POST /asignar agrupa varios 409 distintos del backend; los
  /// repartimos best-effort por el detail.
  Failure _mapAsignacion409(ApiException e) {
    final detail = e.message.toLowerCase();
    // Solape temporal (PR6 / Política A): el backend lo serializa como
    // {"mensaje": ..., "conflictos": [...]}, el único 409 con esa clave; el
    // resto son detail planos. Preparado para la futura asignación a
    // servicio, que reutilizará este dispatcher.
    if (detail.contains('conflictos') ||
        detail.contains('solapad') ||
        detail.contains('ocupado')) {
      return const InventarioFailure.recursoSolapado();
    }
    if (detail.contains('no operativo') ||
        detail.contains('no está operativo')) {
      return const InventarioFailure.materialNoOperativo();
    }
    if (detail.contains('tipo') &&
        (detail.contains('compatible') || detail.contains('no es'))) {
      return const InventarioFailure.tipoIncompatible();
    }
    if (detail.contains('ya asignado') || detail.contains('ya está asignado')) {
      return const InventarioFailure.yaAsignado();
    }
    if (detail.contains('cantidad') &&
        (detail.contains('insuficiente') || detail.contains('disponible'))) {
      return const InventarioFailure.cantidadInsuficiente();
    }
    return NetworkFailure.serverError(e.statusCode);
  }
}
