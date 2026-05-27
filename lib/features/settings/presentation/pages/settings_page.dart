// Settings page. Only exposes the theme selector in the MVP; future
// preferences (notifications, fontScale, ...) drop in below the same
// AppSection header without restructuring the page. Built exclusively
// from App* components per guide 27 §10.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/misc/theme_mode_selector.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../viewmodels/user_preferences_view_model.dart';

AppThemeMode _fromFlutter(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => AppThemeMode.system,
    ThemeMode.light => AppThemeMode.light,
    ThemeMode.dark => AppThemeMode.dark,
  };
}

ThemeMode _toFlutter(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesViewModelProvider);

    ref.listen(userPreferencesViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message:
                  'No se pudo guardar la preferencia. Inténtalo de nuevo.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      title: 'Ajustes',
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error cargando ajustes')),
        data: (prefs) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tema de la aplicación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ThemeModeSelector(
                selected: _toFlutter(prefs.themeMode),
                onChanged: (mode) {
                  ref
                      .read(userPreferencesViewModelProvider.notifier)
                      .setThemeMode(_fromFlutter(mode));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
