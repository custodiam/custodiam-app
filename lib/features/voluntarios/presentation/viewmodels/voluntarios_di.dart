// Voluntarios-feature DI: composes ApiClient -> DataSource -> Repository
// -> UseCase into Riverpod providers. Tests override these to swap
// fakes without touching the cross-cutting infrastructure providers.
// Per guide 26 §6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/roles_api.dart';
import '../../data/datasources/voluntarios_api.dart';
import '../../data/repositories/roles_repository_impl.dart';
import '../../data/repositories/voluntarios_repository_impl.dart';
import '../../domain/repositories/roles_repository.dart';
import '../../domain/repositories/voluntarios_repository.dart';
import '../../domain/usecases/anonimizar_voluntario.dart';
import '../../domain/usecases/asignar_rol.dart';
import '../../domain/usecases/create_voluntario.dart';
import '../../domain/usecases/dar_de_baja_voluntario.dart';
import '../../domain/usecases/get_my_profile.dart';
import '../../domain/usecases/get_voluntario_by_id.dart';
import '../../domain/usecases/list_roles_catalogo.dart';
import '../../domain/usecases/list_roles_voluntario.dart';
import '../../domain/usecases/list_voluntarios.dart';
import '../../domain/usecases/quitar_rol.dart';
import '../../domain/usecases/reenviar_invitacion.dart';
import '../../domain/usecases/update_my_profile.dart';
import '../../domain/usecases/update_voluntario_admin.dart';

final voluntariosApiProvider = Provider<VoluntariosApi>((ref) {
  return VoluntariosApi(ref.watch(apiClientProvider));
});

final voluntariosRepositoryProvider = Provider<VoluntariosRepository>((ref) {
  return VoluntariosRepositoryImpl(ref.watch(voluntariosApiProvider));
});

final listVoluntariosProvider = Provider<ListVoluntarios>((ref) {
  return ListVoluntarios(ref.watch(voluntariosRepositoryProvider));
});

final getMyProfileProvider = Provider<GetMyProfile>((ref) {
  return GetMyProfile(ref.watch(voluntariosRepositoryProvider));
});

final updateMyProfileProvider = Provider<UpdateMyProfile>((ref) {
  return UpdateMyProfile(ref.watch(voluntariosRepositoryProvider));
});

final createVoluntarioProvider = Provider<CreateVoluntario>((ref) {
  return CreateVoluntario(ref.watch(voluntariosRepositoryProvider));
});

final rolesApiProvider = Provider<RolesApi>((ref) {
  return RolesApi(ref.watch(apiClientProvider));
});

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepositoryImpl(ref.watch(rolesApiProvider));
});

final listRolesCatalogoProvider = Provider<ListRolesCatalogo>((ref) {
  return ListRolesCatalogo(ref.watch(rolesRepositoryProvider));
});

final getVoluntarioByIdProvider = Provider<GetVoluntarioById>((ref) {
  return GetVoluntarioById(ref.watch(voluntariosRepositoryProvider));
});

final updateVoluntarioAdminProvider = Provider<UpdateVoluntarioAdmin>((ref) {
  return UpdateVoluntarioAdmin(ref.watch(voluntariosRepositoryProvider));
});

final listRolesVoluntarioProvider = Provider<ListRolesVoluntario>((ref) {
  return ListRolesVoluntario(ref.watch(voluntariosRepositoryProvider));
});

final asignarRolProvider = Provider<AsignarRol>((ref) {
  return AsignarRol(ref.watch(voluntariosRepositoryProvider));
});

final quitarRolProvider = Provider<QuitarRol>((ref) {
  return QuitarRol(ref.watch(voluntariosRepositoryProvider));
});

final darDeBajaVoluntarioProvider = Provider<DarDeBajaVoluntario>((ref) {
  return DarDeBajaVoluntario(ref.watch(voluntariosRepositoryProvider));
});

final anonimizarVoluntarioProvider = Provider<AnonimizarVoluntario>((ref) {
  return AnonimizarVoluntario(ref.watch(voluntariosRepositoryProvider));
});

final reenviarInvitacionProvider = Provider<ReenviarInvitacion>((ref) {
  return ReenviarInvitacion(ref.watch(voluntariosRepositoryProvider));
});
