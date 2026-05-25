// Renders [child] only if the current authenticated user holds the
// required permission (or any of the required permissions, with
// [anyOf]). Otherwise renders [fallback] — by default an empty widget.
//
// Used for UI-level enforcement of the RBAC matrix
// (docs/trabajo/backlog/RBAC_v0.1.0.md). The server still re-validates
// every protected request; this gate is purely a UX layer that avoids
// surfacing buttons that would result in 403.
//
// The widget watches the live AuthService through Riverpod, so a logout
// or a refresh that drops the session also collapses the gate.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/auth/permissions.dart';
import '../../../infrastructure/di/providers.dart';

class AppPermissionGate extends ConsumerWidget {
  const AppPermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : anyOf = null;

  /// Render [child] if the user has any of the listed permissions.
  /// Useful for surfaces that aggregate several actions ("gestión de
  /// inventario": material registrar OR vehículo registrar OR …).
  const AppPermissionGate.anyOf({
    super.key,
    required List<Permission> this.anyOf,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : permission = null;

  final Permission? permission;
  final List<Permission>? anyOf;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return fallback;

    final allowed = anyOf != null
        ? user.hasAnyPermission(anyOf!)
        : user.hasPermission(permission!);

    return allowed ? child : fallback;
  }
}
