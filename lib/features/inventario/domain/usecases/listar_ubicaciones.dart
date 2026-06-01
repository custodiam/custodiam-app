import '../../../../infrastructure/error/result.dart';
import '../entities/ubicaciones_page.dart';
import '../repositories/ubicaciones_repository.dart';

class ListarUbicaciones {
  final UbicacionesRepository _repository;

  const ListarUbicaciones(this._repository);

  Future<Result<UbicacionesPage>> call({
    int skip = 0,
    int limit = 50,
    String? query,
  }) {
    return _repository.listar(skip: skip, limit: limit, query: query);
  }
}
