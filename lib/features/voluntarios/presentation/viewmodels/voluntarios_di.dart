// Voluntarios-feature DI: composes ApiClient -> DataSource -> Repository
// -> UseCase into Riverpod providers. Tests override these to swap
// fakes without touching the cross-cutting infrastructure providers.
// Per guide 26 §6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../data/datasources/voluntarios_api.dart';
import '../../data/repositories/voluntarios_repository_impl.dart';
import '../../domain/repositories/voluntarios_repository.dart';
import '../../domain/usecases/list_voluntarios.dart';

final voluntariosApiProvider = Provider<VoluntariosApi>((ref) {
  return VoluntariosApi(ref.watch(apiClientProvider));
});

final voluntariosRepositoryProvider = Provider<VoluntariosRepository>((ref) {
  return VoluntariosRepositoryImpl(ref.watch(voluntariosApiProvider));
});

final listVoluntariosProvider = Provider<ListVoluntarios>((ref) {
  return ListVoluntarios(ref.watch(voluntariosRepositoryProvider));
});
