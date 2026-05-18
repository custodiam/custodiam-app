// Loading indicator with two variants:
//   - inline:     spinner + optional message rendered in-place
//   - fullScreen: same content centred over the entire viewport
// See guide 27 §5.8.

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  const AppLoadingIndicator.fullScreen({super.key, this.message})
      : fullScreen = true;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );

    return fullScreen ? Center(child: content) : content;
  }
}
