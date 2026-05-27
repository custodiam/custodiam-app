// Repository contract for the voluntarios feature. Returns Result<T>;
// implementations never throw across layers (guide 26 §4).

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_voluntario.dart';
import '../entities/voluntarios_page.dart';

abstract class VoluntariosRepository {
  /// Paginated listing (US-02-09). Backend caps `limit` at 200.
  Future<Result<VoluntariosPage>> list({
    int skip,
    int limit,
    String? query,
    EstadoVoluntario? estado,
  });
}
