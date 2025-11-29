import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? trend;
  final bool? trendUp;
  final bool useGradient;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.trend,
    this.trendUp,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: useGradient 
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: useGradient ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: useGradient ? null : Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: useGradient 
                ? color.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  color: useGradient 
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon, 
                  color: useGradient ? Colors.white : color, 
                  size: isCompact ? 22 : 24,
                ),
              ),
              if (trend != null)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: useGradient 
                          ? Colors.white.withValues(alpha: 0.2)
                          : trendUp == true
                              ? AppColors.success.withValues(alpha: 0.12)
                              : trendUp == false
                                  ? AppColors.error.withValues(alpha: 0.12)
                                  : AppColors.textSecondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trendUp != null)
                          Icon(
                            trendUp! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: isCompact ? 11 : 12,
                            color: useGradient 
                                ? Colors.white 
                                : trendUp! ? AppColors.success : AppColors.error,
                          ),
                        if (trendUp != null) const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            trend!,
                            style: TextStyle(
                              fontSize: isCompact ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              color: useGradient 
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : trendUp == true
                                      ? AppColors.success
                                      : trendUp == false
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w800,
                color: useGradient 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: useGradient 
                  ? Colors.white.withValues(alpha: 0.85)
                  : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
