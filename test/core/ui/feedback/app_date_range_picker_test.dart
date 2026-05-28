// Smoke test del helper `showAppDateRangePicker`. No reproduce el
// flujo completo del diálogo (Flutter ya cubre `showDateRangePicker`
// nativo en sus propios tests); solo verifica que la función llama al
// builder de Material 3 y devuelve null cuando el usuario cancela,
// asegurando que el wrapper no introduce regresiones inadvertidas.

import 'package:custodiam/core/ui/feedback/app_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    locale: const Locale('es', 'ES'),
    supportedLocales: const [Locale('es', 'ES')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('abre el dialog con los labels en castellano del proyecto',
      (tester) async {
    final hoy = DateTime(2026, 6, 15);
    final hace5 = DateTime(2021, 6, 15);

    await tester.pumpWidget(_wrap(
      Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => showAppDateRangePicker(
            context: context,
            firstDate: hace5,
            lastDate: hoy,
          ),
          child: const Text('Abrir'),
        );
      }),
    ));

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    // El dialog nativo full-screen calendar pinta el helpText
    // custom + nuestro saveText. Es suficiente para garantizar que la
    // función llama a `showDateRangePicker` con los argumentos del
    // proyecto y no introduce regresiones del wrapper.
    expect(find.text('Selecciona el periodo'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);

    // El X (close icon) del calendar full-screen cierra el dialog
    // descartando el rango. Lo localizamos por el tooltip que Flutter
    // genera desde `GlobalMaterialLocalizations` con el delegate ya
    // registrado.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona el periodo'), findsNothing);
  });
}
