// Settings selector for ThemeMode (system / light / dark). The wiring
// to the preferences feature lands later with EN-08-25; this component
// only renders the radio group. See guide 27 §5.14.

import 'package:flutter/material.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _handle(ThemeMode? value) {
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Sistema (automático)'),
          subtitle: const Text('Sigue el ajuste del dispositivo'),
          value: ThemeMode.system,
          groupValue: selected,
          onChanged: _handle,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Claro'),
          value: ThemeMode.light,
          groupValue: selected,
          onChanged: _handle,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Oscuro'),
          value: ThemeMode.dark,
          groupValue: selected,
          onChanged: _handle,
        ),
      ],
    );
  }
}
