// SP-08 — smoke test mínimo viable de Patrol.
//
// Objetivo del spike (NO del MVP): verificar que el ciclo
//   patrol test → compila app → arranca runtime (web vía Playwright,
//   móvil vía instrumentation) → ejecuta una aserción sobre la UI
// funciona end-to-end. No prueba el flujo OAuth; el flujo OAuth
// completo (login feliz contra Keycloak) será trabajo del enabler
// EN-08-3X de migración si el spike concluye GO.

import 'package:custodiam/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'app boots and reaches the login page',
    ($) async {
      await $.pumpWidget(
        const ProviderScope(
          child: CustodiamApp(),
        ),
      );

      // Splash + AppStartupUseCase decide en milisegundos sin sesión
      // → debe llevarnos a /login.
      await $.pumpAndSettle();

      // LoginPage es la única página que muestra "Iniciar sesión".
      expect($('Iniciar sesión'), findsOneWidget);
    },
  );
}
