// Result<T> sealed class for cross-layer error handling.
//
// Repository methods return Future<Result<T>>; consumers use exhaustive
// switch (Dart 3) to handle Success/Fail without throwing exceptions
// across layers. See guide 26 §4 for rationale and patterns.

import 'failure.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Fail<T> extends Result<T> {
  final Failure failure;
  const Fail(this.failure);
}
