import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Clinical flag type
enum ClinicalFlagType {
  allergy,
  overdueImmunization,
  fallRisk,
  pregnancy,
  dnr,
  isolation,
  chronicPain,
  mentalHealth,
  custom,
}

/// Clinical flag data
class ClinicalFlag {
  const ClinicalFlag({
    required this.type,
    required this.label,
    this.details,
    this.severity = FlagSeverity.medium,
    this.onTap,
  });

  final ClinicalFlagType type;
  final String label;
  final String? details;
  final FlagSeverity severity;
  final VoidCallback? onTap;

  Color get color {
    switch (type) {
      case ClinicalFlagType.allergy:
        return const Color(0xFFEF4444);
      case ClinicalFlagType.overdueImmunization:
        return const Color(0xFFF59E0B);
      case ClinicalFlagType.fallRisk:
        return const Color(0xFF8B5CF6);
      case ClinicalFlagType.pregnancy:
        return const Color(0xFFEC4899);
      case ClinicalFlagType.dnr:
        return const Color(0xFF1F2937);
      case ClinicalFlagType.isolation:
        return const Color(0xFF10B981);
      case ClinicalFlagType.chronicPain:
        return const Color(0xFFF97316);
      case ClinicalFlagType.mentalHealth:
        return const Color(0xFF3B82F6);
      case ClinicalFlagType.custom:
        return const Color(0xFF6B7280);
    }
  }

  IconData get icon {
    switch (type) {
      case ClinicalFlagType.allergy:
        return Icons.warning_amber_rounded;
      case ClinicalFlagType.overdueImmunization:
        return Icons.vaccines_rounded;
      case ClinicalFlagType.fallRisk:
        return Icons.accessibility_new_rounded;
      case ClinicalFlagType.pregnancy:
        return Icons.pregnant_woman_rounded;
      case ClinicalFlagType.dnr:
        return Icons.do_not_disturb_alt_rounded;
      case ClinicalFlagType.isolation:
        return Icons.shield_rounded;
      case ClinicalFlagType.chronicPain:
        return Icons.healing_rounded;
      case ClinicalFlagType.mentalHealth:
        return Icons.psychology_rounded;
      case ClinicalFlagType.custom:
        return Icons.flag_rounded;
    }
  }
}

enum FlagSeverity { low, medium, high, critical }

/// Horizontal clinical flags ribbon
class ClinicalFlagsRibbon extends StatelessWidget {
  const ClinicalFlagsRibbon({
    super.key,
    required this.flags,
    this.onViewAll,
  });

  final List<ClinicalFlag> flags;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sort by severity
    final sortedFlags = List<ClinicalFlag>.from(flags)
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical Alerts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${flags.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Scrollable flags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: sortedFlags.map((flag) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ClinicalFlagChip(flag: flag, isDark: isDark),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ClinicalFlagChip extends StatelessWidget {
  const _ClinicalFlagChip({
    required this.flag,
    required this.isDark,
  });

  final ClinicalFlag flag;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isCritical = flag.severity == FlagSeverity.critical;

    return GestureDetector(
      onTap: flag.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isCritical
              ? LinearGradient(
                  colors: [flag.color, flag.color.withValues(alpha: 0.8)],
                )
              : null,
          color: isCritical ? null : flag.color.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: flag.color.withValues(alpha: isCritical ? 0.6 : 0.4),
            width: isCritical ? 1.5 : 1,
          ),
          boxShadow: isCritical
              ? [
                  BoxShadow(
                    color: flag.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              flag.icon,
              size: 16,
              color: isCritical ? Colors.white : flag.color,
            ),
            const SizedBox(width: 6),
            Text(
              flag.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCritical 
                    ? Colors.white 
                    : (isDark ? AppColors.darkTextPrimary : flag.color),
              ),
            ),
            if (flag.details != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isCritical 
                      ? Colors.white.withValues(alpha: 0.2)
                      : flag.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  flag.details!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isCritical ? Colors.white : flag.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact clinical flag badge for tight spaces
class ClinicalFlagBadge extends StatelessWidget {
  const ClinicalFlagBadge({
    super.key,
    required this.flag,
    this.showLabel = true,
    this.size = 24,
  });

  final ClinicalFlag flag;
  final bool showLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: flag.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: flag.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(flag.icon, size: 12, color: flag.color),
            const SizedBox(width: 4),
            Text(
              flag.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: flag.color,
              ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: flag.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: flag.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: flag.color.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          flag.icon,
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Stacked clinical flags indicator
class ClinicalFlagsStack extends StatelessWidget {
  const ClinicalFlagsStack({
    super.key,
    required this.flags,
    this.maxVisible = 3,
    this.onTap,
  });

  final List<ClinicalFlag> flags;
  final int maxVisible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();

    final visibleFlags = flags.take(maxVisible).toList();
    final remaining = flags.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked icons
          SizedBox(
            width: 20.0 + (visibleFlags.length - 1) * 14,
            height: 24,
            child: Stack(
              children: List.generate(visibleFlags.length, (index) {
                return Positioned(
                  left: index * 14.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: visibleFlags[index].color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: visibleFlags[index].color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      visibleFlags[index].icon,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ),
          ),
          // Remaining count
          if (remaining > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
