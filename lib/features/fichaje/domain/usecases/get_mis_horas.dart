import '../../../../infrastructure/error/result.dart';
import '../entities/horas_acumuladas.dart';
import '../repositories/fichaje_repository.dart';

class GetMisHoras {
  final FichajeRepository _repository;

  const GetMisHoras(this._repository);

  Future<Result<HorasAcumuladas>> call() => _repository.misHoras();
}
