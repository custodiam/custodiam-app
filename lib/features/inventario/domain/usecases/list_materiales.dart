import '../../../../infrastructure/error/result.dart';
import '../entities/estado_inventario.dart';
import '../entities/materiales_page.dart';
import '../entities/tipo_material.dart';
import '../repositories/inventario_repository.dart';

class ListMateriales {
  final InventarioRepository _repository;

  const ListMateriales(this._repository);

  Future<Result<MaterialesPage>> call({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoInventario? estado,
    TipoMaterial? tipo,
    String? categoria,
  }) {
    return _repository.listMaterial(
      skip: skip,
      limit: limit,
      query: query,
      estado: estado,
      tipo: tipo,
      categoria: categoria,
    );
  }
}
