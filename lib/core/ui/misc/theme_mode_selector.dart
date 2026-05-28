// Selector de ThemeMode (sistema / claro / oscuro) materializado como
// un `SegmentedButton` Material 3 de tres opciones mutuamente
// exclusivas. Sustituye al patrón anterior de `RadioListTile` apilados
// porque visualmente ocupa una sola línea, permite ver las 3 opciones
// a la vez y deja claro qué está activo sin pedir lectura adicional.
//
// API pública compatible con consumidores previos: el caller pasa el
// `ThemeMode` activo y un `onChanged` que recibe el nuevo valor cada
// vez que el usuario cambia la selección.
//
// Ver guía 27 §5.

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
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          label: Text('Sistema'),
          icon: Icon(Icons.brightness_auto_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          label: Text('Claro'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          label: Text('Oscuro'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: <ThemeMode>{selected},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        if (newSelection.isNotEmpty) {
          onChanged(newSelection.first);
        }
      },
      showSelectedIcon: false,
    );
  }
}
