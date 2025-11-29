/// Reusable screen header widget
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../extensions/context_extensions.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final padding = context.responsivePadding;

    return Padding(
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
              onPressed: onBackPressed ?? () => context.pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.onSurfaceColor,
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
                    color: context.onSurfaceColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isCompact ? AppFontSize.smCompact : AppFontSize.md,
                      color: context.isDarkMode 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
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
          else if (icon != null)
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
  }
}
