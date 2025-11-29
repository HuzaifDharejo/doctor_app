/// Custom app card with consistent styling
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../extensions/context_extensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasBorder;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.onLongPress,
    this.hasBorder = true,
    this.gradient,
  });

  /// Creates a card with primary accent
  const AppCard.primary({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  })  : color = null,
        borderColor = AppColors.primary,
        borderWidth = 1.5,
        borderRadius = null,
        boxShadow = null,
        hasBorder = true,
        gradient = null;

  /// Creates an elevated card with shadow
  AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.onLongPress,
  })  : borderColor = null,
        borderWidth = null,
        borderRadius = null,
        boxShadow = AppShadow.medium,
        hasBorder = false,
        gradient = null;

  /// Creates a gradient card
  const AppCard.gradient({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  })  : color = null,
        borderColor = null,
        borderWidth = null,
        borderRadius = null,
        boxShadow = null,
        hasBorder = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppRadius.cardRadius;
    final effectivePadding = padding ?? EdgeInsets.all(context.responsiveCardPadding);
    final isDark = context.isDarkMode;
    
    final effectiveColor = color ?? (isDark ? AppColors.darkCardBg : AppColors.cardBg);
    final effectiveBorderColor = borderColor ?? 
        (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        border: hasBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: boxShadow,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Section card with title and optional actions
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onSeeAll,
    this.padding,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return AppCard(
      padding: padding ?? EdgeInsets.all(context.responsiveCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? AppFontSize.lgCompact : AppFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: context.onSurfaceColor,
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: isCompact ? AppFontSize.smCompact : AppFontSize.md,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          // Content
          Padding(
            padding: contentPadding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}
