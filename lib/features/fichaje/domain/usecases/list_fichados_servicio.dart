import '../../../../infrastructure/error/result.dart';
import '../entities/fichaje_en_servicio.dart';
import '../repositories/fichaje_repository.dart';

class ListFichadosServicio {
  final FichajeRepository _repository;

  const ListFichadosServicio(this._repository);

  Future<Result<List<FichajeEnServicio>>> call(String servicioId) =>
      _repository.listFichadosServicio(servicioId);
}
