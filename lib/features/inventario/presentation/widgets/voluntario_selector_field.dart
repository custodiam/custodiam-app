// Campo de selección de voluntario para los diálogos de asignar/prestar y
// devolver material. Reemplaza al antiguo campo de "UUID del voluntario" a
// mano. Reutiliza el patrón del UbicacionSelectorField:
//   - campo de solo lectura con rol real de botón (a11y, guía 28 §WCAG 4.1.2);
//   - al pulsarlo abre el `AppCatalogSearchPicker` contra el catálogo de
//     voluntarios (búsqueda por nombre, DNI o teléfono);
//   - sin footer "crear": los voluntarios no se dan de alta desde aquí.
//
// Es un widget controlado: la selección vive en el padre (`value` +
// `onChanged`), que construye el payload con el `id` del voluntario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/ui/inputs/app_catalog_search_picker.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../infrastructure/catalogo/catalogo_recurso.dart';
import '../../../../infrastructure/di/providers.dart';

class VoluntarioSelectorField extends ConsumerStatefulWidget {
  final CatalogoRecurso? value;
  final ValueChanged<CatalogoRecurso?> onChanged;
  final String label;

  /// Key del contenedor tappable, para localizarlo en widget tests.
  final Key? fieldKey;

  const VoluntarioSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Voluntario',
    this.fieldKey,
  });

  @override
  ConsumerState<VoluntarioSelectorField> createState() =>
      _VoluntarioSelectorFieldState();
}

class _VoluntarioSelectorFieldState
    extends ConsumerState<VoluntarioSelectorField> {
  late final TextEditingController _displayCtrl;

  @override
  void initState() {
    super.initState();
    _displayCtrl = TextEditingController(text: widget.value?.label ?? '');
  }

  @override
  void didUpdateWidget(covariant VoluntarioSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.value?.label ?? '') == _displayCtrl.text) return;
    // Diferir al final del frame: asignar `controller.text` durante el build
    // de un ancestro dispararía "setState() called during build" (mismo
    // patrón defensivo que UbicacionSelectorField).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = widget.value?.label ?? '';
      if (_displayCtrl.text != text) _displayCtrl.text = text;
    });
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirPicker() async {
    final catalogo = ref.read(voluntariosCatalogoServiceProvider);
    final elegido = await AppCatalogSearchPicker.show<CatalogoRecurso>(
      context,
      title: 'Voluntarios',
      searchHint: 'Buscar por nombre, DNI o teléfono…',
      onLoadPage: catalogo.buscarVoluntarios,
      labelOf: (r) => r.label,
    );
    if (elegido != null) widget.onChanged(elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        key: widget.fieldKey,
        onTap: _abrirPicker,
        child: AbsorbPointer(
          child: AppTextField(
            label: widget.label,
            controller: _displayCtrl,
            prefixIcon: Symbols.person,
          ),
        ),
      ),
    );
  }
}
