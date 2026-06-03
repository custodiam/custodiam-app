// Standard modal dialog with title, content and actions. Wraps Material's
// AlertDialog so the look stays consistent and consumers never call
// showDialog directly. See guide 27 §5.11.

import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  /// Muestra un diálogo modal estándar.
  ///
  /// Las acciones pueden pasarse de dos formas:
  ///
  /// - [actions]: lista de widgets ya construidos. Válido cuando los botones
  ///   NO hacen `Navigator.pop` (o cuando el contenido es un widget propio que
  ///   cierra el diálogo desde su propio `BuildContext`).
  /// - [actionsBuilder]: builder que recibe el `dialogContext` del propio
  ///   diálogo. **Es la forma obligatoria cuando las acciones hacen
  ///   `Navigator.pop`.** `showDialog` monta el diálogo en el navigator raíz;
  ///   si una acción capturase el `context` externo de la página (que en una
  ///   app con `StatefulShellRoute` resuelve al navigator de la rama, no al
  ///   raíz), el `pop` cerraría la ruta de la rama en lugar del diálogo,
  ///   dejándolo huérfano e inerte. Usando `Navigator.of(dialogContext).pop`
  ///   el cierre va siempre al navigator correcto.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
    List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
    bool barrierDismissible = true,
  }) {
    assert(
      actions != null || actionsBuilder != null,
      'AppDialog.show requiere actions o actionsBuilder.',
    );
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog(
        title: title,
        content: content,
        actions: actionsBuilder?.call(dialogContext) ?? actions ?? const [],
      ),
    );
  }

  /// Abre un diálogo cuyo contenido es un widget propio del consumidor
  /// (normalmente un StatefulWidget que posee sus TextEditingController y
  /// los libera en `State.dispose()`). Encapsula `showDialog` para que las
  /// features no lo invoquen directamente (guía 27 §8) y, a la vez, permite
  /// que el diálogo tenga estado y ciclo de vida propios — lo que [show], al
  /// recibir el contenido ya construido, no cubre. El `builder` debería
  /// devolver un [AppDialog] para conservar el aspecto del Design System.
  static Future<T?> showBuilder<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
    );
  }
}
