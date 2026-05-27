// Callable use case for US-02-08 (soft delete branch).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class DarDeBajaVoluntario {
  final VoluntariosRepository _repository;

  const DarDeBajaVoluntario(this._repository);

  Future<Result<Voluntario>> call(String id) => _repository.darDeBaja(id);
}
