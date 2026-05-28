// IconButton para barras de navegación (BottomBar / AppBar de
// navegación principal). Material 3 garantiza tap target 48dp por
// default (materialTapTargetSize: padded), de modo que el icono ocupa
// la mayor parte del área tappable sin padding artificial alrededor.
//
// El color blanco por defecto está pensado para uso encima del color
// brand de la app (#FF6600 naranja PC) — contraste 3.16:1 sobre brand,
// cumple WCAG 1.4.11 (componentes UI no-texto, mínimo 3:1). Si se usa
// sobre otro fondo, pasar `foregroundColor` explícito.
//
// Si el botón representa una pestaña/destino navegable que puede
// estar activo, pasar `iconSelected` para que el icono cambie a la
// variante rellena cuando `isSelected = true`.
//
// Ver guía 27 §5 y ADR-018.

import 'package:flutter/material.dart';

class AppNavBarIconButton extends StatelessWidget {
  const AppNavBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSelected,
    this.isSelected = false,
    this.foregroundColor,
  });

  /// Icono por defecto (estado no seleccionado, o estado único si el
  /// botón no representa un destino seleccionable).
  final IconData icon;

  /// Icono cuando `isSelected = true`. Si es null se usa siempre
  /// `icon` y el componente se comporta como un botón de acción
  /// simple.
  final IconData? iconSelected;

  /// Tooltip obligatorio para cumplir guía 28 (a11y) y dar contexto
  /// a los lectores de pantalla.
  final String tooltip;

  /// Handler del tap. Si es null el botón aparece deshabilitado.
  final VoidCallback? onPressed;

  /// Marca el icono como seleccionado (para barras tipo bottom nav).
  final bool isSelected;

  /// Color del icono. Si es null usa blanco (contraste seguro sobre
  /// el brand). Pasar el del scheme si el botón vive sobre otro fondo.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final IconData effectiveIcon =
        isSelected && iconSelected != null ? iconSelected! : icon;
    return IconButton(
      tooltip: tooltip,
      color: foregroundColor ?? Colors.white,
      iconSize: 36,
      icon: Icon(effectiveIcon),
      onPressed: onPressed,
    );
  }
}
