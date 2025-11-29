/// Error state widget with retry functionality
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class ErrorState extends StatelessWidget {

  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel,
    this.action,
  });

  /// Creates a network error state
  const ErrorState.network({
    super.key,
    this.onRetry,
    this.retryLabel,
  })  : title = 'Connection Error',
        message = AppStrings.noInternet,
        icon = Icons.wifi_off_rounded,
        action = null;

  /// Creates a generic error state
  const ErrorState.generic({
    super.key,
    this.message,
    this.onRetry,
  })  : title = AppStrings.somethingWentWrong,
        icon = Icons.error_outline_rounded,
        retryLabel = null,
        action = null;

  /// Creates a not found error state
  const ErrorState.notFound({
    super.key,
    this.message,
  })  : title = 'Not Found',
        icon = Icons.search_off_rounded,
        onRetry = null,
        retryLabel = null,
        action = null;
  final String? title;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppIconSize.xxl,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Title
            Text(
              title ?? AppStrings.error,
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Message
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Retry button or custom action
            if (action != null)
              action!
            else if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? AppStrings.retry),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline error widget for forms and smaller sections
class InlineError extends StatelessWidget {

  const InlineError({
    required this.message, super.key,
    this.onDismiss,
  });
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: AppIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: AppFontSize.md,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
