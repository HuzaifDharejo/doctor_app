import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A user-friendly error display widget
/// 
/// Shows errors in a consistent, accessible way with optional retry action.
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    required this.message,
    super.key,
    this.title,
    this.icon,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.compact = false,
  });

  /// Creates an error display for network/connection issues
  factory ErrorDisplay.network({
    VoidCallback? onRetry,
    Key? key,
  }) {
    return ErrorDisplay(
      key: key,
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Creates an error display for data loading failures
  factory ErrorDisplay.loadFailed({
    String? message,
    VoidCallback? onRetry,
    Key? key,
  }) {
    return ErrorDisplay(
      key: key,
      title: 'Failed to Load',
      message: message ?? 'Something went wrong while loading data.',
      icon: Icons.error_outline_rounded,
      onRetry: onRetry,
    );
  }

  /// Creates an error display for empty states (not really an error)
  factory ErrorDisplay.empty({
    required String message,
    String? title,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
    Key? key,
  }) {
    return ErrorDisplay(
      key: key,
      title: title ?? 'Nothing Here',
      message: message,
      icon: icon ?? Icons.inbox_outlined,
      onRetry: onAction,
      retryLabel: actionLabel ?? 'Refresh',
    );
  }

  /// Creates a compact inline error
  factory ErrorDisplay.inline({
    required String message,
    VoidCallback? onRetry,
    Key? key,
  }) {
    return ErrorDisplay(
      key: key,
      message: message,
      onRetry: onRetry,
      compact: true,
    );
  }

  final String? title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps a child widget with error boundary functionality
/// 
/// Catches errors in the widget tree and displays a fallback UI.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    super.key,
    this.onError,
    this.fallback,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, VoidCallback reset)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
  }

  void _reset() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallback != null) {
        return widget.fallback!(_error!, _reset);
      }
      return ErrorDisplay.loadFailed(
        message: 'An unexpected error occurred.',
        onRetry: _reset,
      );
    }

    return widget.child;
  }
}

/// Extension to show error snackbars easily
extension ErrorSnackBarExtension on BuildContext {
  /// Shows an error snackbar with the given message
  void showErrorSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows a success snackbar with the given message
  void showSuccessSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows an info snackbar with the given message
  void showInfoSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
