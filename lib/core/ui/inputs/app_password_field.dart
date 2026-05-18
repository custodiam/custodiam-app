// Password input with a visibility toggle. Delegates rendering to
// AppTextField so styling stays consistent. See guide 27 §5.6.

import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;
  final bool autofocus;

  const AppPasswordField({
    super.key,
    this.label = 'Contraseña',
    this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.autofocus = false,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final toggleTooltip =
        _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña';
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      autofocus: widget.autofocus,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscure,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        tooltip: toggleTooltip,
      ),
    );
  }
}
