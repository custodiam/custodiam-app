// Login page. Built exclusively with App* design-system components
// (guía 27 §10 hard rule). On mobile the navigation to /home happens
// here when login() returns Success, because KeycloakAuthService
// already awaited the deep-link callback before returning. On web
// the redirect goes through /callback, which is handled in
// app/router.dart by the dedicated _CallbackHandler.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/error/failure.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_failure_feedback.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AsyncValue<void>>(authViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is AuthFailure) {
            showAuthFailure(context, error);
          }
        },
        data: (_) {
          if (!kIsWeb) {
            context.go('/home');
          }
        },
      );
    });

    final theme = Theme.of(context);

    return AppPageScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Custodiam',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Protección Civil',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(
                label: 'Iniciar sesión',
                icon: Icons.login,
                expanded: true,
                isLoading: authState.isLoading,
                onPressed: authState.isLoading
                    ? null
                    : () => ref
                        .read(authViewModelProvider.notifier)
                        .login(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
