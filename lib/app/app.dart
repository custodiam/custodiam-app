import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:custodiam/app/router.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';

/// Root widget of the application.
///
/// Is a [ConsumerWidget] so future providers (e.g. appThemeModeProvider
/// from feature settings — EN-08-25) can be consumed without rewriting
/// the widget tree. For now it does not read any provider.
class CustodiamApp extends ConsumerWidget {
  const CustodiamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Custodiam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
