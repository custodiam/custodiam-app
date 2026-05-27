// Callable use case for US-02-09. Keeps a single point of injection
// so the ViewModel does not depend on the repository directly and
// future logic (e.g. analytics around list opens) has a natural home.

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_voluntario.dart';
import '../entities/voluntarios_page.dart';
import '../repositories/voluntarios_repository.dart';

class ListVoluntarios {
  final VoluntariosRepository _repository;

  const ListVoluntarios(this._repository);

  Future<Result<VoluntariosPage>> call({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoVoluntario? estado,
  }) {
    return _repository.list(
      skip: skip,
      limit: limit,
      query: query,
      estado: estado,
    );
  }
}
