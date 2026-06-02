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

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    required List<Widget> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        title: title,
        content: content,
        actions: actions,
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
