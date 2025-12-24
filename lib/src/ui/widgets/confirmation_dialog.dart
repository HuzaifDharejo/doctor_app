import 'package:flutter/material.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// A reusable confirmation dialog for critical actions
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Show a confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Show a delete confirmation dialog
  static Future<bool?> showDelete(
    BuildContext context, {
    required String itemName,
    String? message,
  }) async {
    return show(
      context,
      title: 'Delete $itemName?',
      message: message ?? 'This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      title: Row(
        children: [
          if (isDestructive)
            Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 24,
            )
          else
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppFontSize.titleMedium,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: AppFontSize.bodyMedium,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      actions: [
        AppButton.tertiary(
          label: cancelLabel,
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
        ),
        const SizedBox(width: 8),
        AppButton(
          label: confirmLabel,
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
        ),
      ],
    );
  }
}

/// A snackbar with undo action
class UndoSnackBar extends StatelessWidget {
  const UndoSnackBar({
    super.key,
    required this.message,
    required this.onUndo,
    this.duration = const Duration(seconds: 4),
  });

  final String message;
  final VoidCallback onUndo;
  final Duration duration;

  /// Show an undo snackbar
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: onUndo,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is not directly built - use show() method instead
    throw UnimplementedError('Use UndoSnackBar.show() instead');
  }
}


