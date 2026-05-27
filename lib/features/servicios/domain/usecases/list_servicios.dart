// Callable use case for US-03-07.

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_servicio.dart';
import '../entities/servicios_page.dart';
import '../entities/tipo_servicio.dart';
import '../repositories/servicios_repository.dart';

class ListServicios {
  final ServiciosRepository _repository;

  const ListServicios(this._repository);

  Future<Result<ServiciosPage>> call({
    int skip = 0,
    int limit = 50,
    String? query,
    EstadoServicio? estado,
    TipoServicio? tipo,
  }) {
    return _repository.list(
      skip: skip,
      limit: limit,
      query: query,
      estado: estado,
      tipo: tipo,
    );
  }
}
