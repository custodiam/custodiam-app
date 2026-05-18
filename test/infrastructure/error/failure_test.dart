import 'package:flutter_test/flutter_test.dart';
import 'package:custodiam/infrastructure/error/failure.dart';

void main() {
  group('AuthFailure', () {
    test('invalidCredentials has expected message', () {
      const f = AuthFailure.invalidCredentials();
      expect(f, isA<AuthFailure>());
      expect(f.message, 'Credenciales inválidas');
    });

    test('sessionExpired has expected message', () {
      const f = AuthFailure.sessionExpired();
      expect(f.message, 'Sesión expirada');
    });

    test('refreshFailed has expected message', () {
      const f = AuthFailure.refreshFailed();
      expect(f.message, 'No se pudo refrescar la sesión');
    });
  });

  group('NetworkFailure', () {
    test('serverError carries status code', () {
      const f = NetworkFailure.serverError(500);
      expect(f, isA<NetworkFailure>());
      expect(f.message, 'Error del servidor');
    });

    test('timeout, noConnection, unknown have expected messages', () {
      expect(const NetworkFailure.timeout().message, 'Tiempo de espera agotado');
      expect(const NetworkFailure.noConnection().message, 'Sin conexión');
      expect(const NetworkFailure.unknown().message, 'Error desconocido');
    });
  });

  group('ValidationFailure', () {
    test('invalidField wraps the field name', () {
      const f = ValidationFailure.invalidField('email');
      expect(f, isA<ValidationFailure>());
      expect(f.message, 'Campo inválido');
    });

    test('missingField wraps the field name', () {
      const f = ValidationFailure.missingField('password');
      expect(f, isA<ValidationFailure>());
      expect(f.message, 'Campo requerido');
    });
  });

  group('Failure base', () {
    test('all concrete failures extend Failure', () {
      const auth = AuthFailure.invalidCredentials();
      const network = NetworkFailure.timeout();
      const validation = ValidationFailure.missingField('x');
      expect(auth, isA<Failure>());
      expect(network, isA<Failure>());
      expect(validation, isA<Failure>());
    });
  });
}
