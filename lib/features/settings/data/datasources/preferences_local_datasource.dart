// Thin wrapper around SharedPreferences for the settings feature. The
// repository talks to this class through a narrow contract so unit
// tests can swap it for a mocktail double without dragging in the
// shared_preferences plugin (which needs platform channels).

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences_model.dart';

abstract class PreferencesLocalDataSource {
  Future<String?> readThemeMode();
  Future<void> writeThemeMode(String value);
}

class SharedPreferencesDataSource implements PreferencesLocalDataSource {
  final Future<SharedPreferences> _prefs;

  SharedPreferencesDataSource({Future<SharedPreferences>? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance();

  @override
  Future<String?> readThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(UserPreferencesModel.themeModeKey);
  }

  @override
  Future<void> writeThemeMode(String value) async {
    final prefs = await _prefs;
    await prefs.setString(UserPreferencesModel.themeModeKey, value);
  }
}
