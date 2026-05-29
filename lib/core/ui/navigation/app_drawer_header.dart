// Cabecera del NavigationDrawer principal de la app. Pinta el avatar
// del usuario activo, su nombre y la marca "Custodiam" sobre un fondo
// del color brand.
//
// El texto del nombre y subtítulo se pintan en **negro** sobre el
// naranja brand para cumplir WCAG 1.4.3 (≥4.5:1 para texto normal): el
// blanco sobre `#FF6600` da 2.94:1, insuficiente; el negro da ~7.5:1
// con margen. Visualmente es coherente con la señalética hi-vis de
// Protección Civil (carteles y chalecos reflectantes usan tipografía
// negra sobre naranja).
//
// El avatar es blanco con la inicial / icono en negro (mismo
// argumento de contraste).
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
            foregroundColor: Colors.black,
            child: initial != null
                ? Text(
                    initial,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text(
            hasName ? displayName : 'Sesión activa',
            style: textTheme.titleMedium?.copyWith(color: Colors.black),
          ),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
