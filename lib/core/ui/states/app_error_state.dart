// Error placeholder with icon, title, optional description and an
// optional retry CTA wired to AppPrimaryButton. See guide 27 §5.9.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../buttons/app_primary_button.dart';
import '../tokens/app_spacing.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    this.title = 'Algo ha ido mal',
    this.description,
    this.icon = Symbols.error,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Symbols.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
