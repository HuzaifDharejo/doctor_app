import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Unified button component with multiple variants and states
/// Provides consistent button styling across the entire app
class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Gradient? gradient;
  final bool fullWidth;

  const AppButton({
    Key? key,
    this.label,
    required this.onPressed,
    this.child,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.gradient,
    this.fullWidth = false,
  }) : super(key: key);

  /// Primary button variant - Main actions
  factory AppButton.primary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool isLoading = false,
    bool isDisabled = false,
    AppButtonSize size = AppButtonSize.medium,
    Key? key,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.primary,
        size: size,
        fullWidth: fullWidth,
        isLoading: isLoading,
        isDisabled: isDisabled,
      );

  /// Secondary button variant - Alternative actions
  factory AppButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool isLoading = false,
    bool isDisabled = false,
    AppButtonSize size = AppButtonSize.medium,
    Key? key,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.secondary,
        size: size,
        fullWidth: fullWidth,
        isLoading: isLoading,
        isDisabled: isDisabled,
      );

  /// Tertiary button variant - Minimal actions
  factory AppButton.tertiary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool isDisabled = false,
    AppButtonSize size = AppButtonSize.medium,
    Key? key,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.tertiary,
        size: size,
        fullWidth: fullWidth,
        isDisabled: isDisabled,
      );

  /// Danger button variant - Destructive actions
  factory AppButton.danger({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool isLoading = false,
    bool isDisabled = false,
    AppButtonSize size = AppButtonSize.medium,
    Key? key,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.danger,
        size: size,
        fullWidth: fullWidth,
        isLoading: isLoading,
        isDisabled: isDisabled,
      );

  /// Icon-only button variant
  factory AppButton.icon({
    required IconData icon,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isDisabled = false,
    bool isLoading = false,
    Key? key,
  }) =>
      AppButton(
        key: key,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.primary,
        size: size,
        isDisabled: isDisabled,
        isLoading: isLoading,
      );

  /// Gradient button variant
  factory AppButton.gradient({
    required String label,
    required VoidCallback? onPressed,
    required Gradient gradient,
    IconData? icon,
    bool fullWidth = false,
    bool isLoading = false,
    bool isDisabled = false,
    AppButtonSize size = AppButtonSize.medium,
    Key? key,
  }) =>
      AppButton(
        key: key,
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.gradient,
        size: size,
        gradient: gradient,
        fullWidth: fullWidth,
        isLoading: isLoading,
        isDisabled: isDisabled,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine button styling based on variant
    Color? bgColor = backgroundColor;
    Color? fgColor = foregroundColor;
    Color? bdrColor = borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = isDisabled ? colorScheme.primary.withValues(alpha: 0.38) : colorScheme.primary;
        fgColor = isDisabled ? colorScheme.onPrimary.withValues(alpha: 0.38) : colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        bgColor = isDisabled
            ? colorScheme.secondary.withValues(alpha: 0.38)
            : colorScheme.secondary;
        fgColor = isDisabled
            ? colorScheme.onSecondary.withValues(alpha: 0.38)
            : colorScheme.onSecondary;
        break;
      case AppButtonVariant.tertiary:
        bgColor = Colors.transparent;
        fgColor = isDisabled ? colorScheme.primary.withValues(alpha: 0.38) : colorScheme.primary;
        bdrColor = isDisabled ? colorScheme.outline.withValues(alpha: 0.38) : colorScheme.outline;
        break;
      case AppButtonVariant.danger:
        bgColor = isDisabled ? colorScheme.error.withValues(alpha: 0.38) : colorScheme.error;
        fgColor = isDisabled ? colorScheme.onError.withValues(alpha: 0.38) : colorScheme.onError;
        break;
      case AppButtonVariant.gradient:
        bgColor = null; // Gradient will be applied separately
        fgColor = Colors.white;
        break;
    }

    // Get button size properties
    final (buttonHeight, buttonPadding, fontSize) = _getSizeProperties();

    // Build button content
    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: buttonHeight * 0.5,
        width: buttonHeight * 0.5,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else if (icon != null && label != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppIconSize.button, color: fgColor),
          SizedBox(width: AppSpacing.sm),
          Text(label!),
        ],
      );
    } else if (icon != null) {
      buttonChild = Icon(icon, size: AppIconSize.button, color: fgColor);
    } else if (child != null) {
      buttonChild = child!;
    } else {
      buttonChild = Text(label ?? 'Button');
    }

    // Build actual button based on variant
    Widget button;

    if (variant == AppButtonVariant.gradient && gradient != null) {
      button = Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          gradient: isDisabled ? null : gradient,
          color: isDisabled ? colorScheme.primary.withValues(alpha: 0.38) : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Center(
              child: Padding(
                padding: buttonPadding,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: fgColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (variant == AppButtonVariant.tertiary) {
      button = OutlinedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: BorderSide(
            color: bdrColor ?? colorScheme.outline,
            width: 1.5,
          ),
          padding: buttonPadding,
          minimumSize: Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          child: buttonChild,
        ),
      );
    } else {
      button = ElevatedButton(
        onPressed: isDisabled || isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: buttonPadding,
          minimumSize: Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 2,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          child: buttonChild,
        ),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }

  /// Get size-specific properties (height, padding, font size)
  (double height, EdgeInsetsGeometry padding, double fontSize) _getSizeProperties() {
    switch (size) {
      case AppButtonSize.small:
        return (
          32,
          EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          AppFontSize.labelMedium
        );
      case AppButtonSize.medium:
        return (
          40,
          EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          AppFontSize.titleMedium
        );
      case AppButtonSize.large:
        return (
          48,
          EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          AppFontSize.titleLarge
        );
    }
  }
}

/// Button size variants
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Button style variants
enum AppButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
  gradient,
}
