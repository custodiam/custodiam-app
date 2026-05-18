import 'package:custodiam/infrastructure/auth/dummy_auth_service.dart';
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
  });
}
