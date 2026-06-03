// Regresión del bug "el modal de asignar recurso se queda inerte y el fondo
// retrocede a la lista" (F2). Reproduce la topología real de la app:
// StatefulShellRoute.indexedStack con una rama que apila una ruta hija (la
// ficha) sobre la ruta padre (la lista). Un AppDialog abierto desde la ficha
// se monta en el navigator RAÍZ; si sus acciones hicieran pop sobre el context
// de la página (navigator de la rama), cerrarían la ficha en vez del diálogo.
//
// Con `actionsBuilder` el pop va al `dialogContext` (raíz) y el bug no ocurre.
// Este test pasa con el fix y fallaría con el patrón anterior (actions +
// Navigator.of(contextDeLaPagina)).

import 'package:custodiam/core/ui/buttons/app_text_button.dart';
import 'package:custodiam/core/ui/feedback/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'AppDialog.show con actionsBuilder cierra el diálogo sin hacer pop de la '
    'rama del StatefulShellRoute',
    (tester) async {
      String? resultado;

      final router = GoRouter(
        initialLocation: '/servicios',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => navigationShell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/servicios',
                    builder: (context, state) => Scaffold(
                      body: Center(
                        child: ElevatedButton(
                          onPressed: () => context.go('/servicios/1'),
                          child: const Text('ir a ficha'),
                        ),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: '1',
                        builder: (context, state) => Scaffold(
                          body: Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                resultado = await AppDialog.show<String>(
                                  context,
                                  title: 'Asignar recurso',
                                  content: const Text('¿Qué tipo?'),
                                  actionsBuilder: (dialogContext) => [
                                    AppTextButton(
                                      label: 'Material',
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop('material'),
                                    ),
                                  ],
                                );
                              },
                              child: const Text('abrir'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/otra',
                    builder: (context, state) => const Scaffold(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Apilar la ficha (ruta hija) sobre la lista en el navigator de la rama.
      await tester.tap(find.text('ir a ficha'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('ir a ficha'), findsNothing);

      // Abrir el diálogo (se monta en el navigator raíz).
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Asignar recurso'), findsOneWidget);

      // Pulsar la acción: debe cerrar el diálogo y devolver 'material'.
      await tester.tap(find.text('Material'));
      await tester.pumpAndSettle();

      // El diálogo resolvió con el valor…
      expect(resultado, 'material');
      // …el diálogo se cerró…
      expect(find.text('Asignar recurso'), findsNothing);
      // …y la rama NO retrocedió: seguimos en la ficha, no en la lista.
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('ir a ficha'), findsNothing);
    },
  );
}
