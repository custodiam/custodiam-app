// App-wide GoRouter configuration. SplashPage owns '/' and decides
// where to send the user (see guide 26 §7); '/home' and '/login' are
// placeholders until the corresponding features land (EN-01-02 for
// login, the dashboard work for home).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/presentation/pages/splash_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const _LoginPagePlaceholder(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, __) => const _HomePagePlaceholder(),
    ),
  ],
);

class _LoginPagePlaceholder extends StatelessWidget {
  const _LoginPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Login (TBD — EN-01-02)'),
      ),
    );
  }
}

class _HomePagePlaceholder extends StatelessWidget {
  const _HomePagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custodiam')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 64),
            SizedBox(height: 16),
            Text(
              'Custodiam',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Protección Civil — MVP en desarrollo'),
          ],
        ),
      ),
    );
  }
}
