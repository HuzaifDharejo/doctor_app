/// Loading state widget with customizable appearance
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class LoadingState extends StatelessWidget {

  const LoadingState({
    super.key,
    this.message,
    this.color,
    this.size = 36,
    this.showMessage = true,
  });

  /// Creates a compact loading indicator
  const LoadingState.compact({
    super.key,
    this.color,
  })  : message = null,
        size = 24,
        showMessage = false;

  /// Creates an inline loading indicator
  const LoadingState.inline({
    super.key,
    this.color,
  })  : message = null,
        size = 20,
        showMessage = false;
  final String? message;
  final Color? color;
  final double size;
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: indicatorColor,
              strokeWidth: size > 30 ? 3 : 2,
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? AppStrings.loading,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: AppFontSize.lg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay that covers the entire screen
class LoadingOverlay extends StatelessWidget {

  const LoadingOverlay({
    required this.isLoading, required this.child, super.key,
    this.message,
    this.barrierColor,
  });
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          ColoredBox(
            color: barrierColor ?? Colors.black.withValues(alpha: 0.3),
            child: LoadingState(message: message),
          ),
      ],
    );
  }
}
