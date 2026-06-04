// Callable use case for the onboarding invitation resend
// (POST /voluntarios/{id}/reenviar-invitacion).

import '../../../../infrastructure/error/result.dart';
import '../entities/voluntario.dart';
import '../repositories/voluntarios_repository.dart';

class ReenviarInvitacion {
  final VoluntariosRepository _repository;

  const ReenviarInvitacion(this._repository);

  Future<Result<Voluntario>> call(String id) =>
      _repository.reenviarInvitacion(id);
}
