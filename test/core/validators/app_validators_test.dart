import 'package:custodiam/core/validators/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('requerido', () {
    final validar = AppValidators.requerido('Nombre');

    test('null y vacío dan error con el nombre del campo', () {
      expect(validar(null), 'Nombre obligatorio');
      expect(validar(''), 'Nombre obligatorio');
      expect(validar('   '), 'Nombre obligatorio');
    });

    test('valor no vacío es válido', () {
      expect(validar('Ana'), isNull);
    });
  });

  group('email (opcional)', () {
    test('vacío o null es válido (opcional)', () {
      expect(AppValidators.email(null), isNull);
      expect(AppValidators.email(''), isNull);
      expect(AppValidators.email('  '), isNull);
    });

    test('formato válido pasa', () {
      expect(AppValidators.email('ana@example.com'), isNull);
    });

    test('formato inválido falla', () {
      expect(AppValidators.email('no-es-email'), 'Email no válido');
      expect(AppValidators.email('a@b'), 'Email no válido');
      expect(AppValidators.email('a @b.com'), 'Email no válido');
    });
  });

  group('emailRequerido', () {
    test('vacío o null da error de obligatorio', () {
      expect(AppValidators.emailRequerido(null), 'Email obligatorio');
      expect(AppValidators.emailRequerido(''), 'Email obligatorio');
      expect(AppValidators.emailRequerido('  '), 'Email obligatorio');
    });

    test('formato inválido falla', () {
      expect(AppValidators.emailRequerido('no-es-email'), 'Email no válido');
    });

    test('formato válido pasa', () {
      expect(AppValidators.emailRequerido('ana@example.com'), isNull);
    });
  });

  group('combinar', () {
    test('devuelve el primer error encontrado', () {
      final validar = AppValidators.combinar([
        AppValidators.requerido('Email'),
        AppValidators.email,
      ]);
      expect(validar(''), 'Email obligatorio');
      expect(validar('malo'), 'Email no válido');
      expect(validar('ana@example.com'), isNull);
    });
  });
}
