// Tarjeta de acceso rápido para dashboards (típicamente el Home).
// Muestra un icono dentro de un avatar circular a la izquierda, un
// título y un subtítulo apilados en el centro, y un chevron a la
// derecha que indica navegación.
//
// El conjunto es tappable (cumple WCAG 2.5.5 con el padding interno y
// la altura del row) y aparece anunciado como botón a lectores de
// pantalla vía `Semantics(button: true, label: ...)`.
//
// Ver guía 27 §5 y ADR-018.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppQuickActionCard extends StatelessWidget {
  const AppQuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// Icono representativo de la acción.
  final IconData icon;

  /// Título de la acción (1-3 palabras).
  final String title;

  /// Subtítulo descriptivo (frase corta que aclara qué hace).
  final String subtitle;

  /// Handler del tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: title,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
