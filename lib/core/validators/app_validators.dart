// Validadores de formulario reutilizables. Centraliza las reglas que
// antes vivían duplicadas como métodos privados en cada page (DRY) y las
// hace testeables de forma aislada. Las reglas espejan las del backend
// (la fuente de verdad): el backend revalida y es quien rechaza con 422.
//
// Estilo: los validadores son `FormFieldValidator<String>` (firma
// `String? Function(String?)`) para enchufarlos directo en
// `TextFormField.validator` / `AppTextField.validator`.

import 'package:flutter/widgets.dart';

class AppValidators {
  AppValidators._();

  // Formato de email laxo (sin espacios, exige `@` y un TLD). El backend
  // valida con EmailStr (más estricto); aquí es solo ayuda visual.
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Campo obligatorio: error si está vacío o solo espacios.
  static FormFieldValidator<String> requerido(String campo) {
    return (value) =>
        (value == null || value.trim().isEmpty) ? '$campo obligatorio' : null;
  }

  /// Email OPCIONAL: válido si está vacío; si hay texto, exige formato.
  /// Para campos donde el email no es obligatorio (p. ej. editar perfil).
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return _emailRegex.hasMatch(v) ? null : 'Email no válido';
  }

  /// Email OBLIGATORIO: no vacío y con formato válido. Para el alta de
  /// voluntario, donde el email es la llave del onboarding.
  static String? emailRequerido(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email obligatorio';
    return _emailRegex.hasMatch(v) ? null : 'Email no válido';
  }

  /// Combina varios validadores y devuelve el primer error encontrado.
  static FormFieldValidator<String> combinar(
    List<FormFieldValidator<String>> validadores,
  ) {
    return (value) {
      for (final validar in validadores) {
        final error = validar(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
