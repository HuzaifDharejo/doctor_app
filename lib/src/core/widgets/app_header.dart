/// Reusable screen header widget with multiple variants
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../extensions/context_extensions.dart';

class AppHeader extends StatelessWidget {

  const AppHeader({
    required this.title, 
    super.key,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.trailing,
    this.variant = AppHeaderVariant.standard,
    this.gradient,
    this.backgroundColor,
    this.height = 80,
  });

  /// Creates a standard header without special styling
  const AppHeader.standard({
    required String title,
    String? subtitle,
    IconData? icon,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    Key? key,
  })  : this(
    title: title,
    subtitle: subtitle,
    icon: icon,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    actions: actions,
    variant: AppHeaderVariant.standard,
    key: key,
  );

  /// Creates a header with gradient background
  const AppHeader.gradient({
    required String title,
    String? subtitle,
    required Gradient gradient,
    IconData? icon,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    Key? key,
  })  : this(
    title: title,
    subtitle: subtitle,
    icon: icon,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    actions: actions,
    variant: AppHeaderVariant.gradient,
    gradient: gradient,
    key: key,
  );

  /// Creates a header with custom background color
  const AppHeader.colored({
    required String title,
    String? subtitle,
    required Color backgroundColor,
    IconData? icon,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    Key? key,
  })  : this(
    title: title,
    subtitle: subtitle,
    icon: icon,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    actions: actions,
    variant: AppHeaderVariant.colored,
    backgroundColor: backgroundColor,
    key: key,
  );

  /// Creates a minimal header with just title
  const AppHeader.minimal({
    required String title,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
    Key? key,
  })  : this(
    title: title,
    showBackButton: showBackButton,
    onBackPressed: onBackPressed,
    variant: AppHeaderVariant.minimal,
    key: key,
  );

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? trailing;
  final AppHeaderVariant variant;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final padding = context.responsivePadding;
    final isDark = context.isDarkMode;

    // Determine background based on variant
    BoxDecoration? decoration;
    Color? textColor;
    
    switch (variant) {
      case AppHeaderVariant.gradient:
        decoration = BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
        );
        textColor = Colors.white;
        break;
      case AppHeaderVariant.colored:
        decoration = BoxDecoration(
          color: backgroundColor ?? context.theme.primaryColor,
        );
        textColor = Colors.white;
        break;
      case AppHeaderVariant.minimal:
        decoration = null;
        textColor = context.onSurfaceColor;
        break;
      case AppHeaderVariant.standard:
        decoration = null;
        textColor = context.onSurfaceColor;
    }

    final headerContent = Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        isCompact ? 10 : 16,
        padding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Back button
          if (showBackButton) ...[
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: textColor,
                size: isCompact ? AppIconSize.mdCompact : AppIconSize.lg,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.md),
          ],
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? AppFontSize.xxlCompact : AppFontSize.xxxl,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (subtitle != null && variant != AppHeaderVariant.minimal) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isCompact ? AppFontSize.smCompact : AppFontSize.md,
                      color: variant == AppHeaderVariant.standard
                          ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                          : textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          if (actions != null) ...actions!,
          
          // Trailing icon or widget
          if (trailing != null)
            trailing!
          else if (icon != null && variant == AppHeaderVariant.standard)
            Container(
              padding: EdgeInsets.all(isCompact ? AppSpacing.sm : 10),
              decoration: BoxDecoration(
                color: (iconBackgroundColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: isCompact ? AppIconSize.smCompact : AppIconSize.md,
              ),
            ),
        ],
      ),
    );

    if (decoration != null) {
      return Container(
        decoration: decoration,
        child: headerContent,
      );
    }

    return headerContent;
  }
}

/// Header variants for different styling approaches
enum AppHeaderVariant {
  standard,    // Default styling
  gradient,    // With gradient background
  colored,     // With solid color background
  minimal,     // Minimal styling, just text
}
