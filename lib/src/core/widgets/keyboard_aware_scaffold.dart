/// Keyboard-aware scaffold wrapper
/// Ensures keyboard doesn't overlay content on mobile screens
library;

import 'package:flutter/material.dart';

/// A Scaffold wrapper that handles keyboard properly
/// - Automatically scrolls to focused TextField
/// - Adds bottom padding when keyboard is visible
/// - Works with both regular body and CustomScrollView
class KeyboardAwareScaffold extends StatelessWidget {
  const KeyboardAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// A scrollable form container that handles keyboard visibility
/// Use this inside a Scaffold body for forms
class KeyboardAwareForm extends StatelessWidget {
  const KeyboardAwareForm({
    super.key,
    required this.child,
    this.padding,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      keyboardDismissBehavior: keyboardDismissBehavior,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: padding?.horizontal ?? 0,
        right: padding?.horizontal ?? 0,
        top: padding?.vertical ?? 0,
        // Add extra bottom padding when keyboard is visible
        bottom: (padding?.vertical ?? 0) + bottomInset + bottomPadding + 20,
      ),
      child: child,
    );
  }
}

/// Extension to add keyboard bottom padding to any widget
extension KeyboardPaddingExtension on Widget {
  /// Wraps the widget with keyboard-aware bottom padding
  Widget withKeyboardPadding(BuildContext context, {double extraPadding = 20}) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + extraPadding : 0),
      child: this,
    );
  }
}

/// A SliverToBoxAdapter that adds keyboard-aware bottom padding
/// Use this as the last sliver in a CustomScrollView with forms
class SliverKeyboardPadding extends StatelessWidget {
  const SliverKeyboardPadding({
    super.key,
    this.minPadding = 100,
  });

  final double minPadding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: bottomInset > 0 
            ? bottomInset + 20 
            : minPadding + bottomPadding,
      ),
    );
  }
}
