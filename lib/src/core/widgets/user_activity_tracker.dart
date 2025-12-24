/// User Activity Tracker Widget
/// Wraps widgets to track user interactions for session management
library;

import 'package:flutter/material.dart';
import '../../services/session_manager.dart';

/// Widget that tracks user activity (taps, scrolls, etc.)
class UserActivityTracker extends StatelessWidget {
  const UserActivityTracker({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => sessionManager.onUserActivity(),
      child: GestureDetector(
        onTap: () => sessionManager.onUserActivity(),
        onPanStart: (_) => sessionManager.onUserActivity(),
        child: child,
      ),
    );
  }
}

