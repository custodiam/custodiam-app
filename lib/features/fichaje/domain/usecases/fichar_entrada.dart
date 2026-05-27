import '../../../../infrastructure/error/result.dart';
import '../entities/fichaje.dart';
import '../repositories/fichaje_repository.dart';

class FicharEntrada {
  final FichajeRepository _repository;

  const FicharEntrada(this._repository);

  Future<Result<Fichaje>> call(String servicioId) =>
      _repository.ficharEntrada(servicioId);
}
