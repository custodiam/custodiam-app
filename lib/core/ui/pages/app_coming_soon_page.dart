// Placeholder page for capabilities that have a permission in the RBAC
// matrix but no implemented screen yet. Surfaced from gated drawer
// entries so the user discovers the capability exists and learns the
// phase in which it will land, instead of the action being invisible.
//
// Composes AppPageScaffold (title + AppBar) + AppEmptyState (icon +
// "Próximamente" + the phase description). The body is wrapped in a
// Semantics container with an explicit label so a screen reader
// announces the page as a single unit ("<title> — Próximamente").
// `excludeSemantics: true` drops the inner icon + text nodes from the
// a11y tree so the icon is treated as decorative and the title is not
// read twice; the description copy is still visible to sighted users.

import 'package:flutter/material.dart';

import '../containers/app_page_scaffold.dart';
import '../states/app_empty_state.dart';

class AppComingSoonPage extends StatelessWidget {
  const AppComingSoonPage({
    super.key,
    required this.title,
    required this.phase,
    required this.icon,
  });

  /// Title shown in the AppBar and announced as part of the Semantics
  /// label (e.g. "Administración").
  final String title;

  /// User-facing phase in which the capability is planned to ship
  /// (e.g. "Fase 2", "Fase 3"). Rendered inside the description.
  final String phase;

  /// Decorative icon for the empty state. Not announced by screen
  /// readers.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      body: Semantics(
        container: true,
        excludeSemantics: true,
        label: '$title — Próximamente',
        child: AppEmptyState(
          icon: icon,
          title: 'Próximamente',
          description: 'Esta funcionalidad estará disponible en la $phase.',
        ),
      ),
    );
  }
}
