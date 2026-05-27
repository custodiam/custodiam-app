import '../../../../infrastructure/error/result.dart';
import '../entities/fichaje.dart';
import '../repositories/fichaje_repository.dart';

class GetMisFichajes {
  final FichajeRepository _repository;

  const GetMisFichajes(this._repository);

  Future<Result<List<Fichaje>>> call() => _repository.misFichajes();
}
