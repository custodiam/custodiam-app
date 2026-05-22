// Repository contract for the settings feature. Implementations live
// in data/repositories/. All operations return Result<T> so the
// presentation layer can branch on failures without try/catch
// (guide 26 §4).

import '../../../../infrastructure/error/result.dart';
import '../entities/app_theme_mode.dart';
import '../entities/user_preferences.dart';

abstract class PreferencesRepository {
  /// Returns the persisted preferences. If no record exists yet, the
  /// implementation returns the defaults (system theme).
  Future<Result<UserPreferences>> get();

  /// Persist the new theme mode. Returns the full UserPreferences
  /// after the write so the caller can reuse it without re-reading.
  Future<Result<UserPreferences>> updateThemeMode(AppThemeMode mode);
}
