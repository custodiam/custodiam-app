// Use case: read the persisted preferences (or defaults on first run).
// Trivial pass-through in the MVP; lives in a class so it can be
// overridden in widget tests via Riverpod and so future side effects
// (telemetry, migration) have an obvious home.

import '../../../../infrastructure/error/result.dart';
import '../entities/user_preferences.dart';
import '../repositories/preferences_repository.dart';

class GetUserPreferences {
  final PreferencesRepository _repository;

  const GetUserPreferences(this._repository);

  Future<Result<UserPreferences>> call() => _repository.get();
}
