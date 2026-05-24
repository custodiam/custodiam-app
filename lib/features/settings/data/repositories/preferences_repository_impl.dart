// Concrete PreferencesRepository backed by the local data source. Any
// exception leaking from the data source is converted to a Failure so
// nothing throws cross-layer (guide 26 §4).

import 'dart:developer' as dev;

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_local_datasource.dart';
import '../models/user_preferences_model.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesLocalDataSource _dataSource;

  const PreferencesRepositoryImpl(this._dataSource);

  @override
  Future<Result<UserPreferences>> get() async {
    try {
      final raw = await _dataSource.readThemeMode();
      return Success(UserPreferencesModel.fromRaw(rawThemeMode: raw));
    } catch (e, stack) {
      dev.log(
        'Could not read preferences: $e',
        name: 'Storage',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }

  @override
  Future<Result<UserPreferences>> updateThemeMode(AppThemeMode mode) async {
    try {
      await _dataSource.writeThemeMode(
        UserPreferencesModel.themeModeToString(mode),
      );
      return Success(UserPreferences(themeMode: mode));
    } catch (e, stack) {
      dev.log(
        'Could not write theme mode: $e',
        name: 'Storage',
        error: e,
        stackTrace: stack,
      );
      return const Fail(NetworkFailure.unknown());
    }
  }
}
