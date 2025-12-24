import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// A gradient save button for medical record forms
/// Provides consistent styling with loading state support
class RecordSaveButton extends StatelessWidget {
  const RecordSaveButton({
    super.key,
    required this.onPressed,
    this.label = 'Save Record',
    this.icon = Icons.save,
    this.isLoading = false,
    this.isSaving,  // Alias for isLoading
    this.enabled = true,
    this.gradient,
    this.gradientColors,  // Alternative to gradient
    this.fullWidth = true,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool? isSaving;  // Alias for isLoading
  final bool enabled;
  final LinearGradient? gradient;
  final List<Color>? gradientColors;  // Alternative to gradient
  final bool fullWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loading = isSaving ?? isLoading;  // Use isSaving if provided
    final isEnabled = enabled && !loading;

    // Build gradient from colors if provided
    LinearGradient effectiveGradient;
    if (gradient != null) {
      effectiveGradient = gradient!;
    } else if (gradientColors != null && gradientColors!.isNotEmpty) {
      effectiveGradient = LinearGradient(colors: gradientColors!);
    } else {
      effectiveGradient = LinearGradient(
        colors: isEnabled
            ? [AppColors.primary, AppColors.primaryDark]
            : [Colors.grey.shade400, Colors.grey.shade500],
      );
    }

    final button = Container(
      height: compact ? 44 : 52,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.md),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (gradientColors?.first ?? AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.md),
          child: Center(
            child: loading
                ? SizedBox(
                    width: AppIconSize.md,
                    height: AppIconSize.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: compact ? AppIconSize.sm : AppIconSize.sm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? AppFontSize.lg : AppFontSize.titleLarge,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return button;
    }
    
    return IntrinsicWidth(child: button);
  }
}

/// Cancel button for forms
class RecordCancelButton extends StatelessWidget {
  const RecordCancelButton({
    super.key,
    required this.onPressed,
    this.label = 'Cancel',
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: compact ? 44 : 52,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.md),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.md),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: compact ? AppFontSize.lg : AppFontSize.titleLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of action buttons (typically Cancel + Save)
class RecordActionButtons extends StatelessWidget {
  const RecordActionButtons({
    super.key,
    required this.onSave,
    this.onCancel,
    this.saveLabel = 'Save Record',
    this.cancelLabel = 'Cancel',
    this.isLoading = false,
    this.canSave = true,
    this.showCancel = true,
    this.spacing = AppSpacing.md,
    this.padding,
  });

  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final String cancelLabel;
  final bool isLoading;
  final bool canSave;
  final bool showCancel;
  final double spacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (showCancel) ...[
            Expanded(
              child: RecordCancelButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                label: cancelLabel,
              ),
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            flex: showCancel ? 2 : 1,
            child: RecordSaveButton(
              onPressed: canSave ? onSave : null,
              label: saveLabel,
              isLoading: isLoading,
              enabled: canSave,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action button for quick save
class RecordFloatingSaveButton extends StatelessWidget {
  const RecordFloatingSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.tooltip = 'Save Record',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: enabled && !isLoading ? onPressed : null,
      backgroundColor: enabled ? AppColors.primary : Colors.grey,
      icon: isLoading
          ? const SizedBox(
              width: AppIconSize.sm,
              height: AppIconSize.sm,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.save),
      label: Text(isLoading ? 'Saving...' : 'Save'),
      tooltip: tooltip,
    );
  }
}

/// A small icon button for inline actions
class RecordIconButton extends StatelessWidget {
  const RecordIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 20,
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ??
        (enabled
            ? (isDark ? Colors.white70 : AppColors.textSecondary)
            : Colors.grey);

    final button = IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: size, color: iconColor),
      padding: const EdgeInsets.all(AppSpacing.sm),
      constraints: const BoxConstraints(),
      splashRadius: AppIconSize.sm,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Chip-style action button
class RecordChipButton extends StatelessWidget {
  const RecordChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSelected = false,
    this.color,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSelected;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: enabled ? (_) => onPressed?.call() : null,
      avatar: icon != null ? Icon(icon, size: 18) : null,
      selectedColor: chipColor.withValues(alpha: 0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected
            ? chipColor
            : (isDark ? Colors.white70 : AppColors.textSecondary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? chipColor
            : (isDark ? Colors.white24 : Colors.grey.shade300),
      ),
    );
  }
}
