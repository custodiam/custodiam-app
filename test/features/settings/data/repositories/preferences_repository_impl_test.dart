// Unit tests for PreferencesRepositoryImpl. The data source is mocked
// so we do not depend on shared_preferences platform channels here.

import 'package:custodiam/features/settings/data/datasources/preferences_local_datasource.dart';
import 'package:custodiam/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:custodiam/features/settings/domain/entities/app_theme_mode.dart';
import 'package:custodiam/features/settings/domain/entities/user_preferences.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements PreferencesLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late PreferencesRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = PreferencesRepositoryImpl(dataSource);
  });

  group('get', () {
    test('returns the persisted theme when present', () async {
      when(() => dataSource.readThemeMode()).thenAnswer((_) async => 'dark');

      final result = await repository.get();

      expect(result, isA<Success<UserPreferences>>());
      final ok = result as Success<UserPreferences>;
      expect(ok.value.themeMode, AppThemeMode.dark);
    });

    test('falls back to system when nothing is persisted yet', () async {
      when(() => dataSource.readThemeMode()).thenAnswer((_) async => null);

      final result = await repository.get();

      expect(result, isA<Success<UserPreferences>>());
      final ok = result as Success<UserPreferences>;
      expect(ok.value.themeMode, AppThemeMode.system);
    });

    test('falls back to system when the stored value is unknown', () async {
      when(() => dataSource.readThemeMode())
          .thenAnswer((_) async => 'futureMode');

      final result = await repository.get();

      expect(result, isA<Success<UserPreferences>>());
      final ok = result as Success<UserPreferences>;
      expect(ok.value.themeMode, AppThemeMode.system);
    });

    test('returns a Fail when the data source throws', () async {
      when(() => dataSource.readThemeMode())
          .thenThrow(Exception('disk error'));

      final result = await repository.get();

      expect(result, isA<Fail<UserPreferences>>());
      final fail = result as Fail<UserPreferences>;
      expect(fail.failure, isA<Failure>());
    });
  });

  group('updateThemeMode', () {
    test('writes the canonical string and returns the new preferences',
        () async {
      when(() => dataSource.writeThemeMode(any())).thenAnswer((_) async {});

      final result = await repository.updateThemeMode(AppThemeMode.light);

      expect(result, isA<Success<UserPreferences>>());
      final ok = result as Success<UserPreferences>;
      expect(ok.value.themeMode, AppThemeMode.light);
      verify(() => dataSource.writeThemeMode('light')).called(1);
    });

    test('returns a Fail when the data source throws', () async {
      when(() => dataSource.writeThemeMode(any()))
          .thenThrow(Exception('disk full'));

      final result = await repository.updateThemeMode(AppThemeMode.dark);

      expect(result, isA<Fail<UserPreferences>>());
    });
  });
}
