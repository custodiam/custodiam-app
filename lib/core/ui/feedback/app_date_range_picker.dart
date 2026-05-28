// Helper único para abrir el date range picker nativo de Flutter con
// el branding del proyecto: locale es_ES, labels en castellano,
// `entryMode: calendar` con switch a input disponible para el caso
// accesibilidad / teclado.
//
// Vive en `core/ui/feedback/` (no en `core/ui/inputs/`) porque la
// llamada es modal: la página la dispara con un `Future<DateTimeRange?>`
// y consume el resultado sin renderizar nada inline. Mismo eje que
// `AppConfirmDialog.show()` o `AppSnackbar.show()`.
//
// Se devuelve una función pura, no un widget: el Material 3 nativo de
// `showDateRangePicker` ya cumple la guía 28 (semantics, textScaler
// 2.0x, contraste sin depender de color) y la guía 29 (full-screen
// móvil + modal centrado tablet/desktop) sin envoltorio adicional.
// Si el día de mañana se requiere un picker custom (p. ej. con
// `selectableDayPredicate` para bloquear días concretos), basta con
// añadir parámetros a esta función sin tocar los call sites.

import 'package:flutter/material.dart';

/// Abre el date range picker nativo con la configuración estándar del
/// proyecto. Devuelve `null` si el usuario cancela.
///
/// [firstDate] y [lastDate] acotan el rango seleccionable; típicamente
/// se enlazan a límites de dominio (fecha de alta del voluntario y
/// `DateTime.now()` para el caso del historial).
///
/// [initialDateRange] preselecciona un periodo si la pantalla ya tenía
/// un filtro activo; al volver a abrir el diálogo el usuario lo ve
/// reflejado.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
}) {
  return showDateRangePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    helpText: 'Selecciona el periodo',
    cancelText: 'Cancelar',
    confirmText: 'Aplicar',
    saveText: 'Guardar',
    fieldStartLabelText: 'Desde',
    fieldEndLabelText: 'Hasta',
    fieldStartHintText: 'dd/mm/aaaa',
    fieldEndHintText: 'dd/mm/aaaa',
    errorInvalidRangeText: 'Rango no válido',
    errorFormatText: 'Formato no válido',
    errorInvalidText: 'Fecha fuera de rango',
    initialEntryMode: DatePickerEntryMode.calendar,
    keyboardType: TextInputType.datetime,
  );
}
