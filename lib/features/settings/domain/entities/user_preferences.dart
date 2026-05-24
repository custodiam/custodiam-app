// User-facing preferences persisted locally. MVP only stores the theme
// mode; the entity is shaped so future preferences (notifications,
// fontScale, sound, ...) can land without migrating the persisted
// payload — just copyWith a new field and bump the model JSON keys.

import 'app_theme_mode.dart';

class UserPreferences {
  final AppThemeMode themeMode;

  const UserPreferences({this.themeMode = AppThemeMode.system});

  UserPreferences copyWith({AppThemeMode? themeMode}) {
    return UserPreferences(themeMode: themeMode ?? this.themeMode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences && other.themeMode == themeMode;

  @override
  int get hashCode => themeMode.hashCode;
}
