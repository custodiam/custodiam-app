// lib/app/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    // Se añadirán rutas según se desarrollen features:
    // /login, /servicios, /voluntarios, /inventario, /perfil
  ],
);

/// Pantalla placeholder — se reemplazará con el dashboard real
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custodiam'),
      ),
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
