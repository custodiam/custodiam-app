// Settings selector for ThemeMode (system / light / dark). The wiring
// to the preferences feature lands later with EN-08-25; this component
// only renders the radio group. See guide 27 §5.14.
//
// Uses the RadioGroup ancestor API introduced in Flutter 3.32 — the
// per-tile groupValue/onChanged parameters were deprecated in that
// release.

import 'package:flutter/material.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ThemeMode>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioListTile<ThemeMode>(
            title: Text('Sistema (automático)'),
            subtitle: Text('Sigue el ajuste del dispositivo'),
            value: ThemeMode.system,
          ),
          RadioListTile<ThemeMode>(
            title: Text('Claro'),
            value: ThemeMode.light,
          ),
          RadioListTile<ThemeMode>(
            title: Text('Oscuro'),
            value: ThemeMode.dark,
          ),
        ],
      ),
    );
  }
}
