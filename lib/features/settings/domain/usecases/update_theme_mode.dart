// Use case: persist a new theme mode and return the up-to-date
// UserPreferences. The repository owns the merge so the use case stays
// a thin pass-through (see GetUserPreferences for the rationale).

import '../../../../infrastructure/error/result.dart';
import '../entities/app_theme_mode.dart';
import '../entities/user_preferences.dart';
import '../repositories/preferences_repository.dart';

class UpdateThemeMode {
  final PreferencesRepository _repository;

  const UpdateThemeMode(this._repository);

  Future<Result<UserPreferences>> call(AppThemeMode mode) =>
      _repository.updateThemeMode(mode);
}
