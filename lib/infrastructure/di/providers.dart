// Cross-cutting Riverpod providers that any feature can read. Per
// guide 26 §1 / §6, infrastructure services live here as global
// providers and feature-level DI files compose them into the
// per-feature DataSource -> Repository -> UseCase chain.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../auth/dummy_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => DummyAuthService());
