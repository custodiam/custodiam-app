// Voluntarios-feature DI: composes ApiClient -> DataSource -> Repository
// -> UseCase into Riverpod providers. Tests override these to swap
// fakes without touching the cross-cutting infrastructure providers.
// Per guide 26 §6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/voluntarios_api.dart';
import '../../data/repositories/voluntarios_repository_impl.dart';
import '../../domain/repositories/voluntarios_repository.dart';
import '../../domain/usecases/create_voluntario.dart';
import '../../domain/usecases/get_my_profile.dart';
import '../../domain/usecases/list_voluntarios.dart';
import '../../domain/usecases/update_my_profile.dart';

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
