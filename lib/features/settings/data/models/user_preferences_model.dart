// Serialisation boundary for UserPreferences. Stored as a single
// shared_preferences key per field (not as one JSON blob) so adding a
// new preference does not need a migration — the read just falls back
// to the default for any key that does not exist yet.

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/user_preferences.dart';

class UserPreferencesModel {
  // Single stored key for now. Listed here so the data source has a
  // stable contract; do not rename without a migration path.
  static const String themeModeKey = 'settings.theme_mode';

  static String themeModeToString(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };
  }

  static AppThemeMode themeModeFromString(String? raw) {
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  /// Rebuild the domain entity from raw stored values. Missing keys
  /// fall back to the entity's own defaults via the constructor.
  static UserPreferences fromRaw({String? rawThemeMode}) {
    return UserPreferences(
      themeMode: themeModeFromString(rawThemeMode),
    );
  }
}
