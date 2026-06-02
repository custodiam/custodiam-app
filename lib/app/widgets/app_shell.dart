// Root responsive shell that dispatches by viewport width. MVP only
// ships the mobile layout (CustodiamShell) but the LayoutBuilder is
// already in place so adding the tablet (compact NavigationRail) and
// desktop (extended NavigationRail + multi-column) variants in F3 is
// additive instead of requiring a router refactor.
//
// Guide 29 §3 prescribes this exact dispatch shape: a single shell
// widget at the StatefulShellRoute builder, dispatching on the
// breakpoints from AppBreakpoints. Until tablet/desktop layouts exist,
// every viewport falls through to _MobileShell.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/tokens/app_breakpoints.dart';
import 'custodiam_shell.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppBreakpoints.desktop) {
          // TODO(responsive-f4): swap for _DesktopShell when the
          // extended NavigationRail + multi-column layout lands (F3 of
          // the roadmap). Today, falls through to mobile so behavior
          // is identical on every device.
          return _MobileShell(navigationShell: navigationShell);
        }
        if (width >= AppBreakpoints.mobile) {
          // TODO(responsive-f4): swap for _TabletShell when the
          // compact NavigationRail variant lands.
          return _MobileShell(navigationShell: navigationShell);
        }
        return _MobileShell(navigationShell: navigationShell);
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return CustodiamShell(navigationShell: navigationShell);
  }
}
