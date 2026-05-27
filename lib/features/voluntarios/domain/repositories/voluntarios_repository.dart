// Repository contract for the voluntarios feature. Returns Result<T>;
// implementations never throw across layers (guide 26 §4).

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_voluntario.dart';
import '../entities/mi_perfil_update.dart';
import '../entities/voluntario.dart';
import '../entities/voluntarios_page.dart';

abstract class VoluntariosRepository {
  /// Paginated listing (US-02-09). Backend caps `limit` at 200.
  Future<Result<VoluntariosPage>> list({
    int skip,
    int limit,
    String? query,
    EstadoVoluntario? estado,
  });

  /// GET /voluntarios/me — full profile of the authenticated user
  /// (US-02-05). 404 maps to VoluntariosFailure.notFound (the JWT
  /// holder has no row in the BD yet).
  Future<Result<Voluntario>> getMyProfile();

  /// PATCH /voluntarios/me — update contact data of the authenticated
  /// user (US-02-03). 409 maps to VoluntariosFailure.emailDuplicado.
  Future<Result<Voluntario>> updateMyProfile(MiPerfilUpdate patch);
}
