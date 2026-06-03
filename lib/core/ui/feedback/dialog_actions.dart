// Lays out a dialog's action buttons evenly across its width instead of
// clustering them on the right. Each button gets an equal share (Expanded),
// separated by AppSpacing.sm. Used by AppDialog and AppConfirmDialog so the
// confirm/cancel pair reads as a balanced 50/50 row with larger, easier tap
// targets. See guide 27 §5.11/§5.12.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Wraps [actions] in a single full-width [Row] where every action takes an
/// equal fraction of the available width. Returns the value ready to hand to
/// `AlertDialog.actions`. With a single action it still spans the full width;
/// callers that want the default right-aligned layout (e.g. one-button info
/// dialogs) should simply pass the actions through unchanged.
List<Widget> dialogActionsAsRow(List<Widget> actions) {
  if (actions.isEmpty) return actions;

  final children = <Widget>[];
  for (var i = 0; i < actions.length; i++) {
    if (i > 0) {
      children.add(const SizedBox(width: AppSpacing.sm));
    }
    children.add(Expanded(child: actions[i]));
  }
  return [Row(children: children)];
}
