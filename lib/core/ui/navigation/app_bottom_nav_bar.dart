// Contenedor de la barra inferior de navegación principal de la app.
//
// Pintada con el naranja brand de Protección Civil (`AppColors.brand`,
// #FF6600) en ambos modos light/dark para preservar la identidad
// institucional consistente. El primary del scheme M3 polish-ea a
// #FF8533 en dark para contraste contra surfaces oscuras, pero la
// bottombar es un bloque grande pintado de un único color que no
// compite con surfaces — preferir el brand original mantiene la marca
// reconocible.
//
// Los hijos típicos son `AppNavBarIconButton` con `foregroundColor`
// blanco (contraste 3.16:1 sobre brand, WCAG 1.4.11 ≥3:1 cumplido).
//
// Ver guía 27 §5 y ADR-018.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../tokens/app_spacing.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.children,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  });

  /// Hijos de la fila. Normalmente una mezcla de `AppNavBarIconButton`,
  /// `Spacer` y el avatar circular.
  final List<Widget> children;

  /// Padding horizontal de la fila interna. Por defecto `AppSpacing.sm`
  /// a cada lado, lo que deja respiro frente a los bordes del display.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.brand,
      padding: padding,
      child: Row(children: children),
    );
  }
}
