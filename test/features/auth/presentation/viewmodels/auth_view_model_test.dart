import 'package:custodiam/features/auth/presentation/viewmodels/auth_di.dart';
import 'package:custodiam/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

ProviderContainer _container(_MockAuthService auth) {
  final container = ProviderContainer(
    overrides: [
      authServiceForViewModelProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AuthViewModel', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
    });

    test('initial state is AsyncData(null) so isLoading is false', () {
      final container = _container(auth);

      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncData<void>>());
      expect(state.isLoading, isFalse);
    });

    test('login() resolves to AsyncData on Success', () async {
      when(() => auth.login())
          .thenAnswer((_) async => const Success(null));
      final container = _container(auth);

      await container.read(authViewModelProvider.notifier).login();

      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncData<void>>());
      verify(() => auth.login()).called(1);
    });

    test('login() resolves to AsyncError carrying the AuthFailure on Fail',
        () async {
      when(() => auth.login())
          .thenAnswer((_) async => const Fail(AuthFailure.userCancelled()));
      final container = _container(auth);

      await container.read(authViewModelProvider.notifier).login();

      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, isA<AuthFailure>());
    });

    test('logout() resolves to AsyncData on Success', () async {
      when(() => auth.logout())
          .thenAnswer((_) async => const Success(null));
      final container = _container(auth);

      await container.read(authViewModelProvider.notifier).logout();

      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncData<void>>());
      verify(() => auth.logout()).called(1);
    });

    test('logout() resolves to AsyncError on Fail', () async {
      when(() => auth.logout())
          .thenAnswer((_) async => const Fail(AuthFailure.browserError()));
      final container = _container(auth);

      await container.read(authViewModelProvider.notifier).logout();

      final state = container.read(authViewModelProvider);
      expect(state, isA<AsyncError<void>>());
      expect(state.error, isA<AuthFailure>());
    });
  });
}
