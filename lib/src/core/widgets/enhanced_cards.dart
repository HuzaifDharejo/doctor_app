/// Glassmorphism and enhanced card widgets
library;

import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism effect container
class GlassmorphicContainer extends StatelessWidget {
  const GlassmorphicContainer({
    required this.child,
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderOpacity = 0.2,
    this.gradient,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: opacity),
                            Colors.white.withValues(alpha: opacity * 0.5),
                          ]
                        : [
                            Colors.white.withValues(alpha: opacity * 8),
                            Colors.white.withValues(alpha: opacity * 4),
                          ],
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: borderOpacity)
                    : Colors.white.withValues(alpha: borderOpacity * 3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Enhanced stat card with glassmorphism in dark mode
class EnhancedStatCard extends StatelessWidget {
  const EnhancedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
    this.onTap,
    this.trend,
    this.trendValue,
    this.statusLevel,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final String? trend; // 'up', 'down', 'neutral'
  final String? trendValue;
  final int? statusLevel; // 1 = good, 2 = warning, 3 = critical

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status indicator color
    Color? statusColor;
    if (statusLevel != null) {
      switch (statusLevel) {
        case 1:
          statusColor = const Color(0xFF10B981);
        case 2:
          statusColor = const Color(0xFFF59E0B);
        case 3:
          statusColor = const Color(0xFFEF4444);
      }
    }

    Widget card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status indicator pill
                    if (statusColor != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Trend indicator
              if (trend != null && trendValue != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend == 'up'
                          ? Icons.trending_up_rounded
                          : trend == 'down'
                              ? Icons.trending_down_rounded
                              : Icons.trending_flat_rounded,
                      size: 14,
                      color: trend == 'up'
                          ? const Color(0xFF10B981)
                          : trend == 'down'
                              ? const Color(0xFFEF4444)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trendValue!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trend == 'up'
                            ? const Color(0xFF10B981)
                            : trend == 'down'
                                ? const Color(0xFFEF4444)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    // Wrap with glassmorphism in dark mode
    if (isDark) {
      card = GlassmorphicContainer(
        blur: 8,
        opacity: 0.05,
        borderOpacity: 0.1,
        borderRadius: 16,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusColor != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white60,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (trend != null && trendValue != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend == 'up'
                              ? Icons.trending_up_rounded
                              : trend == 'down'
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_flat_rounded,
                          size: 14,
                          color: trend == 'up'
                              ? const Color(0xFF10B981)
                              : trend == 'down'
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trendValue!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: trend == 'up'
                                ? const Color(0xFF10B981)
                                : trend == 'down'
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Gradient section header
class GradientSectionHeader extends StatelessWidget {
  const GradientSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.action,
    this.onActionTap,
    this.gradient,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onActionTap;
  final Gradient? gradient;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => (gradient ??
                      const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ))
                  .createShader(bounds),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => (gradient ??
                          LinearGradient(
                            colors: isDark
                                ? [Colors.white, Colors.white70]
                                : [const Color(0xFF1E293B), const Color(0xFF475569)],
                          ))
                      .createShader(bounds),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: gradient ??
                      LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.1),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom refresh indicator with app branding
class BrandedRefreshIndicator extends StatelessWidget {
  const BrandedRefreshIndicator({
    required this.child,
    required this.onRefresh,
    super.key,
    this.color,
    this.backgroundColor,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? const Color(0xFF6366F1),
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1A1A1A) : Colors.white),
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}
