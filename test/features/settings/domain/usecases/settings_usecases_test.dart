// Thin unit tests for the settings use cases. They are pass-throughs
// onto the repository today; the tests ensure the wiring stays in
// place and that any future side effect added here is exercised.

import 'package:custodiam/features/settings/domain/entities/app_theme_mode.dart';
import 'package:custodiam/features/settings/domain/entities/user_preferences.dart';
import 'package:custodiam/features/settings/domain/repositories/preferences_repository.dart';
import 'package:custodiam/features/settings/domain/usecases/get_user_preferences.dart';
import 'package:custodiam/features/settings/domain/usecases/update_theme_mode.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements PreferencesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
  });

  group('GetUserPreferences', () {
    test('delegates to PreferencesRepository.get', () async {
      when(() => repository.get()).thenAnswer(
        (_) async => const Success(UserPreferences()),
      );

      final usecase = GetUserPreferences(repository);
      final result = await usecase();

      expect(result, isA<Success<UserPreferences>>());
      verify(() => repository.get()).called(1);
    });
  });

  group('UpdateThemeMode', () {
    test('forwards the mode to PreferencesRepository.updateThemeMode',
        () async {
      when(() => repository.updateThemeMode(any())).thenAnswer(
        (_) async => const Success(UserPreferences(themeMode: AppThemeMode.dark)),
      );

      final usecase = UpdateThemeMode(repository);
      final result = await usecase(AppThemeMode.dark);

      expect(result, isA<Success<UserPreferences>>());
      verify(() => repository.updateThemeMode(AppThemeMode.dark)).called(1);
    });
  });
}
