// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:custodiam/app/router.dart';
import 'package:custodiam/core/theme/app_theme.dart';

class CustodiamApp extends StatelessWidget {
  const CustodiamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Custodiam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
