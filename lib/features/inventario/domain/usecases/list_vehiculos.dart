import '../../../../infrastructure/error/result.dart';
import '../entities/estado_inventario.dart';
import '../entities/tipo_vehiculo.dart';
import '../entities/vehiculos_page.dart';
import '../repositories/inventario_repository.dart';

class ListVehiculos {
  final InventarioRepository _repository;
  const ListVehiculos(this._repository);

  Future<Result<VehiculosPage>> call({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoVehiculo? tipo,
  }) {
    return _repository.listVehiculos(
      skip: skip,
      limit: limit,
      query: query,
      estado: estado,
      tipo: tipo,
    );
  }
}
