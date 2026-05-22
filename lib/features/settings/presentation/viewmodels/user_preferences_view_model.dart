// AsyncNotifier that exposes the current UserPreferences and writes
// updates through UpdateThemeMode. State is AsyncValue<UserPreferences>
// so the UI can show a loading spinner on first read and surface
// failures via ref.listen the same way other features do.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_user_preferences.dart';
import '../../domain/usecases/update_theme_mode.dart';
import 'settings_di.dart';

class UserPreferencesViewModel extends AsyncNotifier<UserPreferences> {
  GetUserPreferences get _getPreferences =>
      ref.read(getUserPreferencesProvider);

  UpdateThemeMode get _updateThemeMode => ref.read(updateThemeModeProvider);

  @override
  Future<UserPreferences> build() async {
    final result = await _getPreferences();
    return switch (result) {
      Success(:final value) => value,
      Fail() => const UserPreferences(),
    };
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final previous = state.valueOrNull ?? const UserPreferences();
    state = AsyncData(previous.copyWith(themeMode: mode));

    final result = await _updateThemeMode(mode);
    if (result case Fail(:final failure)) {
      // Roll back the optimistic update and surface the failure so the
      // UI's ref.listen branch can show a snackbar.
      state = AsyncData(previous);
      state = AsyncError(failure, StackTrace.current);
    }
  }
}

final userPreferencesViewModelProvider =
    AsyncNotifierProvider<UserPreferencesViewModel, UserPreferences>(
  UserPreferencesViewModel.new,
);
