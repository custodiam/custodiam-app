// Cabecera del NavigationDrawer principal de la app. Pinta el avatar
// del usuario activo, su nombre y la marca "Custodiam" sobre un fondo
// del color brand.
//
// El avatar muestra la inicial del nombre cuando hay sesión, o un
// icono genérico de persona si no hay datos del usuario. El texto y
// el avatar se pintan en blanco para contraste seguro (3.16:1 sobre
// brand naranja, WCAG 1.4.11 ≥3:1 cumplido para componentes UI).
//
// Ver guía 27 §5 y ADR-018.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../tokens/app_spacing.dart';

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({
    super.key,
    required this.displayName,
    this.subtitle = 'Custodiam',
  });

  /// Nombre completo del usuario activo. Si está vacío se muestra
  /// "Sesión activa" como texto neutro.
  final String displayName;

  /// Subtítulo bajo el nombre. Por defecto la marca "Custodiam"; se
  /// puede personalizar (por ejemplo, indicando el rol).
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasName = displayName.isNotEmpty;
    final initial =
        hasName ? displayName.substring(0, 1).toUpperCase() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      color: AppColors.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brand,
            child: initial != null
                ? Text(
                    initial,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.brand,
                    ),
                  )
                : const Icon(Icons.person, color: AppColors.brand),
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text(
            hasName ? displayName : 'Sesión activa',
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
