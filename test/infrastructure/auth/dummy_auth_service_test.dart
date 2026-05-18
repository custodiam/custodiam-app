import 'package:custodiam/infrastructure/auth/dummy_auth_service.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DummyAuthService', () {
    test('reports unauthenticated before init', () {
      final service = DummyAuthService();

      expect(service.isAuthenticated, isFalse);
      expect(service.isInitialised, isFalse);
    });

    test('flips isInitialised after init but stays unauthenticated',
        () async {
      final service = DummyAuthService();

      await service.init();

      expect(service.isInitialised, isTrue);
      expect(service.isAuthenticated, isFalse);
    });

    test('init is idempotent', () async {
      final service = DummyAuthService();

      await service.init();
      await service.init();

      expect(service.isInitialised, isTrue);
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken is always null', () {
      expect(DummyAuthService().accessToken, isNull);
    });

    test('login returns Fail with sessionExpired', () async {
      final result = await DummyAuthService().login();
      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<AuthFailure>());
    });

    test('logout returns Success', () async {
      final result = await DummyAuthService().logout();
      expect(result, isA<Success<void>>());
    });

    test('getValidAccessToken returns Fail with sessionExpired', () async {
      final result = await DummyAuthService().getValidAccessToken();
      expect(result, isA<Fail<String>>());
    });
  });
}
