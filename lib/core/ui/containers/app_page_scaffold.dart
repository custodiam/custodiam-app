// Page-level scaffold that wraps every page with SafeArea and a maximum
// readable content width. Pages never use Scaffold directly. See guide 27
// §5.7 and the dura rule "no Material Scaffold in features/" in §10.

import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';

class AppPageScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  const AppPageScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxContentWidth = AppBreakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(title: Text(title!), actions: actions)
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
