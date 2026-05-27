// Callable use case for US-02-01 (CU-10).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../entities/voluntario_create.dart';
import '../repositories/voluntarios_repository.dart';

class CreateVoluntario {
  final VoluntariosRepository _repository;

  const CreateVoluntario(this._repository);

  Future<Result<Voluntario>> call(VoluntarioCreate data) =>
      _repository.create(data);
}
