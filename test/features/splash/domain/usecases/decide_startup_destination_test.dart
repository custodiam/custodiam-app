import 'package:custodiam/features/splash/domain/usecases/decide_startup_destination.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('DecideStartupDestination', () {
    late _MockAuthService authService;
    late DecideStartupDestination usecase;

    setUp(() {
      authService = _MockAuthService();
      usecase = DecideStartupDestination(authService);
      when(() => authService.init()).thenAnswer((_) async {});
    });

    test('returns home when AuthService reports an active session',
        () async {
      when(() => authService.isAuthenticated).thenReturn(true);

      final result = await usecase();

      expect(result, StartupDestination.home);
      verify(() => authService.init()).called(1);
    });

    test('returns login when AuthService has no session', () async {
      when(() => authService.isAuthenticated).thenReturn(false);

      final result = await usecase();

      expect(result, StartupDestination.login);
      verify(() => authService.init()).called(1);
    });

    test('calls init before reading isAuthenticated', () async {
      when(() => authService.isAuthenticated).thenReturn(false);

      await usecase();

      verifyInOrder([
        () => authService.init(),
        () => authService.isAuthenticated,
      ]);
    });
  });
}
