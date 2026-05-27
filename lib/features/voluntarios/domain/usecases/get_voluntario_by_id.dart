import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class GetVoluntarioById {
  final VoluntariosRepository _repository;

  const GetVoluntarioById(this._repository);

  Future<Result<Voluntario>> call(String id) => _repository.getById(id);
}
