// Assertion helpers for Result<T>. Keep test bodies short and avoid
// repeating switch statements. See guide 22 §5.
//
// Usage:
//   expectSuccess<List<Voluntario>>(result, expectedList);
//   expectFailure<List<Voluntario>>(result, NetworkFailure);

import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/infrastructure/error/result.dart';

/// Asserts that [result] is a [Success] whose value equals [expected].
void expectSuccess<T>(Result<T> result, T expected) {
  switch (result) {
    case Success(:final value):
      expect(value, equals(expected));
    case Fail(:final failure):
      fail('Expected Success, got Fail: $failure');
  }
}

/// Asserts that [result] is a [Fail] whose failure runtimeType is a
/// subtype of [expectedFailureType].
void expectFailure<T>(Result<T> result, Type expectedFailureType) {
  switch (result) {
    case Success(:final value):
      fail('Expected Fail<$expectedFailureType>, got Success: $value');
    case Fail(:final failure):
      expect(
        failure.runtimeType.toString(),
        anyOf(equals(expectedFailureType.toString()), contains(expectedFailureType.toString())),
        reason: 'Failure type mismatch: got ${failure.runtimeType}, '
            'expected $expectedFailureType (or subtype)',
      );
  }
}
