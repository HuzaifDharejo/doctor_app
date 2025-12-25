/// Session Manager
/// Handles auto-logout on inactivity for security
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import '../core/theme/design_tokens.dart';
import '../theme/app_theme.dart';

/// Session manager singleton
class SessionManager {
  factory SessionManager() => _instance;
  SessionManager._internal();
  static final SessionManager _instance = SessionManager._internal();

  Timer? _inactivityTimer;
  Timer? _warningTimer;
  bool _isActive = true;
  
  // Configuration
  static const Duration _inactivityTimeout = Duration(minutes: 15);
  static const Duration _warningBeforeTimeout = Duration(minutes: 1);
  
  // Callbacks
  VoidCallback? _onSessionTimeout;
  VoidCallback? _onWarning;
  VoidCallback? _onLockApp;
  BuildContext? _context;

  /// Initialize session manager
  void initialize({
    required BuildContext context,
    VoidCallback? onSessionTimeout,
    VoidCallback? onWarning,
    VoidCallback? onLockApp,
  }) {
    _context = context;
    _onSessionTimeout = onSessionTimeout;
    _onWarning = onWarning;
    _onLockApp = onLockApp;
    resetInactivityTimer();
    log.i('SESSION', 'Session manager initialized');
  }

  /// Reset inactivity timer (call on user activity)
  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _isActive = true;

    // Set warning timer (1 minute before timeout)
    _warningTimer = Timer(_inactivityTimeout - _warningBeforeTimeout, () {
      if (_isActive) {
        _showWarning();
      }
    });

    // Set inactivity timer
    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (_isActive) {
        _handleSessionTimeout();
      }
    });

    log.d('SESSION', 'Inactivity timer reset');
  }

  /// Handle user activity
  void onUserActivity() {
    if (!_isActive) return;
    resetInactivityTimer();
  }

  /// Show warning before timeout
  void _showWarning() {
    if (!_isActive) return;

    log.w('SESSION', 'Session timeout warning');
    
    _onWarning?.call();
    
    // Show warning dialog if context is available and mounted
    final context = _context;
    if (context != null && context.mounted) {
      try {
        _showTimeoutWarningDialog(context);
      } catch (e) {
        // Context might have been disposed, ignore
        log.d('SESSION', 'Could not show warning dialog: $e');
      }
    }
  }

  /// Handle session timeout
  void _handleSessionTimeout() {
    if (!_isActive) return;

    _isActive = false;
    log.w('SESSION', 'Session timeout - locking app');

    _onSessionTimeout?.call();
    
    // Lock the app
    _onLockApp?.call();
  }

  /// Show timeout warning dialog
  void _showTimeoutWarningDialog(BuildContext context) {
    if (!context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Double-check context is still mounted inside builder
          if (!context.mounted) {
            return const SizedBox.shrink();
          }
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: AppSpacing.sm),
                Text('Session Timeout Warning'),
              ],
            ),
            content: const Text(
              'Your session will expire in 1 minute due to inactivity. '
              'Continue working to stay logged in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.pop(context);
                    resetInactivityTimer();
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Context was disposed during dialog creation, ignore
      log.d('SESSION', 'Could not show timeout warning: $e');
    }
  }

  /// Pause session tracking (e.g., when app goes to background)
  void pause() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    log.d('SESSION', 'Session tracking paused');
  }

  /// Resume session tracking (e.g., when app comes to foreground)
  void resume() {
    if (_isActive) {
      resetInactivityTimer();
      log.d('SESSION', 'Session tracking resumed');
    }
  }

  /// Dispose resources
  void dispose() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _context = null;
    _onSessionTimeout = null;
    _onWarning = null;
    log.i('SESSION', 'Session manager disposed');
  }

  /// Get remaining time until timeout
  Duration? getRemainingTime() {
    // This would require tracking start time
    // For now, return null as it's not critical
    return null;
  }

  /// Check if session is active
  bool get isActive => _isActive;
}

/// Global session manager instance
final sessionManager = SessionManager();

