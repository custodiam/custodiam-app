// Repository contract for the voluntarios feature. Returns Result<T>;
// implementations never throw across layers (guide 26 §4).

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_voluntario.dart';
import '../entities/mi_perfil_update.dart';
import '../entities/voluntario.dart';
import '../entities/voluntario_create.dart';
import '../entities/voluntario_rol_asignacion.dart';
import '../entities/voluntario_update_admin.dart';
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

  /// POST /voluntarios — create a new volunteer (US-02-01). 409 may
  /// be either DNI or email duplicate; both surface as
  /// VoluntariosFailure.dniOrEmailDuplicado.
  Future<Result<Voluntario>> create(VoluntarioCreate data);

  /// GET /voluntarios/{id} — full profile of any voluntario (US-02-02).
  /// Gated server-side by `voluntarios.ver_ficha`.
  Future<Result<Voluntario>> getById(String id);

  /// PATCH /voluntarios/{id} — admin update (US-02-02). 409 on
  /// DNI/email duplicate surfaces as VoluntariosFailure.dniOrEmailDuplicado.
  Future<Result<Voluntario>> updateAdmin(
    String id,
    VoluntarioUpdateAdmin patch,
  );

  /// GET /voluntarios/{id}/roles — active role assignments of the
  /// voluntario (each item includes `rolNombre`).
  Future<Result<List<VoluntarioRolAsignacion>>> listRolesAsignados(
    String voluntarioId,
  );

  /// POST /voluntarios/{id}/roles — assign a role.
  /// 409 if the role is already active for that voluntario.
  Future<Result<VoluntarioRolAsignacion>> asignarRol(
    String voluntarioId,
    String rolId,
  );

  /// DELETE /voluntarios/{id}/roles/{rol_id} — soft-close an assignment.
  /// 404 if no active assignment exists for that pair.
  Future<Result<VoluntarioRolAsignacion>> quitarRol(
    String voluntarioId,
    String rolId,
  );
}
