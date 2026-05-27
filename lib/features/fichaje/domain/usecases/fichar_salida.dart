import '../../../../infrastructure/error/result.dart';
import '../entities/fichaje.dart';
import '../repositories/fichaje_repository.dart';

class FicharSalida {
  final FichajeRepository _repository;

  const FicharSalida(this._repository);

  Future<Result<Fichaje>> call(String servicioId) =>
      _repository.ficharSalida(servicioId);
}
