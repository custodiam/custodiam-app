// Settings-feature DI: composes the DataSource -> Repository -> UseCase
// chain into Riverpod providers so the ViewModel can read use cases
// via overridable providers. Per guide 26 §6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/preferences_local_datasource.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/usecases/get_user_preferences.dart';
import '../../domain/usecases/update_theme_mode.dart';

final preferencesLocalDataSourceProvider =
    Provider<PreferencesLocalDataSource>((ref) {
  return SharedPreferencesDataSource();
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepositoryImpl(
    ref.watch(preferencesLocalDataSourceProvider),
  );
});

final getUserPreferencesProvider = Provider<GetUserPreferences>((ref) {
  return GetUserPreferences(ref.watch(preferencesRepositoryProvider));
});

final updateThemeModeProvider = Provider<UpdateThemeMode>((ref) {
  return UpdateThemeMode(ref.watch(preferencesRepositoryProvider));
});
