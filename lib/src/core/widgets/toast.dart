/// Modern Toast Notification System
/// Provides beautiful, non-intrusive toast notifications
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Toast notification types
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Toast notification widget
class Toast extends StatelessWidget {
  const Toast({
    required this.message,
    required this.type,
    super.key,
    this.icon,
    this.action,
    this.duration = const Duration(seconds: 3),
  });

  final String message;
  final ToastType type;
  final IconData? icon;
  final ToastAction? action;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(type, isDark);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colors['background'] as Color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors['border'] as Color,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors['background'] as Color).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: colors['iconBackground'] as Color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon ?? _getDefaultIcon(type),
              size: AppIconSize.sm,
              color: colors['icon'] as Color,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Message
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppFontSize.bodyMedium,
                fontWeight: FontWeight.w600,
                color: colors['text'] as Color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Action button
          if (action != null) ...[
            SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: action!.onTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!.label,
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: FontWeight.w700,
                  color: colors['icon'] as Color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, Color> _getColors(ToastType type, bool isDark) {
    switch (type) {
      case ToastType.success:
        return {
          'background': isDark
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.surface,
          'border': AppColors.success.withValues(alpha: 0.3),
          'icon': AppColors.success,
          'iconBackground': AppColors.success.withValues(alpha: 0.15),
          'text': isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        };
      case ToastType.error:
        return {
          'background': isDark
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.surface,
          'border': AppColors.error.withValues(alpha: 0.3),
          'icon': AppColors.error,
          'iconBackground': AppColors.error.withValues(alpha: 0.15),
          'text': isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        };
      case ToastType.warning:
        return {
          'background': isDark
              ? AppColors.warning.withValues(alpha: 0.2)
              : AppColors.surface,
          'border': AppColors.warning.withValues(alpha: 0.3),
          'icon': AppColors.warning,
          'iconBackground': AppColors.warning.withValues(alpha: 0.15),
          'text': isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        };
      case ToastType.info:
        return {
          'background': isDark
              ? AppColors.info.withValues(alpha: 0.2)
              : AppColors.surface,
          'border': AppColors.info.withValues(alpha: 0.3),
          'icon': AppColors.info,
          'iconBackground': AppColors.info.withValues(alpha: 0.15),
          'text': isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        };
    }
  }

  IconData _getDefaultIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }
}

/// Toast action button
class ToastAction {
  const ToastAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;
}

/// Toast overlay entry manager
class ToastOverlay {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message,
    ToastType type, {
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Hide existing toast
    hide();

    final overlay = Overlay.of(context);
    final toast = Toast(
      message: message,
      type: type,
      icon: icon,
      action: action,
      duration: duration,
    );

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: toast,
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto-hide after duration
    Future.delayed(duration, () => hide());
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// Extension for easy toast usage
extension ToastExtension on BuildContext {
  /// Show a success toast
  void showSuccessToast(
    String message, {
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ToastOverlay.show(
      this,
      message,
      ToastType.success,
      icon: icon,
      action: action,
      duration: duration,
    );
  }

  /// Show an error toast
  void showErrorToast(
    String message, {
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    ToastOverlay.show(
      this,
      message,
      ToastType.error,
      icon: icon,
      action: action,
      duration: duration,
    );
  }

  /// Show a warning toast
  void showWarningToast(
    String message, {
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ToastOverlay.show(
      this,
      message,
      ToastType.warning,
      icon: icon,
      action: action,
      duration: duration,
    );
  }

  /// Show an info toast
  void showInfoToast(
    String message, {
    IconData? icon,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    ToastOverlay.show(
      this,
      message,
      ToastType.info,
      icon: icon,
      action: action,
      duration: duration,
    );
  }
}

