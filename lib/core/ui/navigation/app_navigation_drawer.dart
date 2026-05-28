// Drawer lateral principal de la app. Compone una cabecera
// (`AppDrawerHeader`), la lista de destinos navegables y un footer
// opcional (típicamente "Cerrar sesión" o "Acerca de").
//
// El contenido principal va en `destinations` como lista de
// `ListTile` (por ejemplo). El componente añade `SafeArea`,
// `Expanded` con `ListView` y los `Divider` entre header / lista /
// footer para garantizar una estética consistente sin que cada
// consumidor reescriba la estructura.
//
// Ver guía 27 §5 y ADR-018.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.header,
    required this.destinations,
    this.footer,
  });

  /// Cabecera (normalmente `AppDrawerHeader`).
  final Widget header;

  /// Lista de destinos navegables. Cada uno suele ser un `ListTile`.
  /// Recomendado envolver en `AppPermissionGate` para los que dependen
  /// de RBAC.
  final List<Widget> destinations;

  /// Widget opcional al pie del drawer, por debajo de la lista y
  /// separado por un `Divider`. Típicamente la entrada de "Cerrar
  /// sesión" para que viva separada de los destinos.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            header,
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                children: destinations,
              ),
            ),
            if (footer != null) ...[
              const Divider(height: 1),
              footer!,
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
