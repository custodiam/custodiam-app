// Reads the persisted theme mode from the settings feature and maps it
// to Flutter's ThemeMode so MaterialApp.router can consume it directly.
//
// Lives in infrastructure (not in features/settings) because the
// MaterialApp.router consumer sits at the app root — outside any
// feature — and would otherwise pull in a feature import. The settings
// feature still owns the persistence and the use cases; this provider
// is the cross-cutting view of the same value.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/domain/entities/app_theme_mode.dart';
import '../../features/settings/presentation/viewmodels/user_preferences_view_model.dart';

ThemeMode _toFlutter(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

/// Flutter ThemeMode reflecting the current user preference. Defaults
/// to system while the AsyncNotifier resolves on first build.
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final prefs = ref.watch(userPreferencesViewModelProvider);
  return prefs.maybeWhen(
    data: (p) => _toFlutter(p.themeMode),
    orElse: () => ThemeMode.system,
  );
});
