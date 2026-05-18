import 'package:flutter_test/flutter_test.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';

void main() {
  group('Result<T>', () {
    test('Success wraps a value', () {
      const result = Success<int>(42);
      expect(result, isA<Success<int>>());
      expect(result.value, 42);
    });

    test('Fail wraps a Failure', () {
      const failure = AuthFailure.sessionExpired();
      const result = Fail<int>(failure);
      expect(result, isA<Fail<int>>());
      expect(result.failure, isA<AuthFailure>());
    });

    test('Sealed switch is exhaustive for Success', () {
      const Result<String> result = Success('ok');
      final outcome = switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => failure.message ?? 'unknown',
      };
      expect(outcome, 'ok');
    });

    test('Sealed switch is exhaustive for Fail', () {
      const Result<String> result = Fail(NetworkFailure.timeout());
      final outcome = switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => failure.message ?? 'unknown',
      };
      expect(outcome, 'Tiempo de espera agotado');
    });
  });
}
