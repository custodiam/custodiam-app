// Callable use case for US-02-08 (RGPD irreversible branch).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class AnonimizarVoluntario {
  final VoluntariosRepository _repository;

  const AnonimizarVoluntario(this._repository);

  Future<Result<Voluntario>> call(String id) => _repository.anonimizar(id);
}
