import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:custodiam/app/router.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/notificaciones/presentation/widgets/fcm_bootstrap.dart';
import 'package:custodiam/infrastructure/theme/app_theme_mode_provider.dart';

/// Root widget of the application.
///
/// Consumes [appThemeModeProvider] so the theme reflects the user's
/// persisted preference (EN-08-25 / US-01-05). Defaults to system mode
/// until the AsyncNotifier finishes its first read.
///
/// Wraps MaterialApp.router in [FcmBootstrap] so the FCM token gets
/// registered against the backend after login (US-06-04) and the
/// global handler for notifications can navigate to the right
/// `/servicios/{id}` when the user taps a banner (US-06-01 / US-06-02).
class CustodiamApp extends ConsumerWidget {
  const CustodiamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    return FcmBootstrap(
      child: MaterialApp.router(
        title: 'Custodiam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
