import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Activity type for timeline
enum ActivityType {
  appointment,
  prescription,
  labOrder,
  vitalSigns,
  medicalRecord,
  invoice,
  note,
  call,
  message,
  other,
}

/// Activity item for mini timeline
class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.onTap,
  });

  final ActivityType type;
  final String title;
  final DateTime timestamp;
  final String? subtitle;
  final VoidCallback? onTap;

  Color get color {
    switch (type) {
      case ActivityType.appointment:
        return const Color(0xFF3B82F6);
      case ActivityType.prescription:
        return const Color(0xFF8B5CF6);
      case ActivityType.labOrder:
        return const Color(0xFFF59E0B);
      case ActivityType.vitalSigns:
        return const Color(0xFFEC4899);
      case ActivityType.medicalRecord:
        return const Color(0xFF10B981);
      case ActivityType.invoice:
        return const Color(0xFF6366F1);
      case ActivityType.note:
        return const Color(0xFF14B8A6);
      case ActivityType.call:
        return const Color(0xFF22C55E);
      case ActivityType.message:
        return const Color(0xFF0EA5E9);
      case ActivityType.other:
        return const Color(0xFF6B7280);
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.appointment:
        return Icons.event_rounded;
      case ActivityType.prescription:
        return Icons.medication_rounded;
      case ActivityType.labOrder:
        return Icons.science_rounded;
      case ActivityType.vitalSigns:
        return Icons.monitor_heart_rounded;
      case ActivityType.medicalRecord:
        return Icons.description_rounded;
      case ActivityType.invoice:
        return Icons.receipt_long_rounded;
      case ActivityType.note:
        return Icons.sticky_note_2_rounded;
      case ActivityType.call:
        return Icons.phone_rounded;
      case ActivityType.message:
        return Icons.chat_rounded;
      case ActivityType.other:
        return Icons.circle_rounded;
    }
  }
}

/// Recent activity mini timeline
class RecentActivityTimeline extends StatelessWidget {
  const RecentActivityTimeline({
    super.key,
    required this.activities,
    this.maxItems = 5,
    this.onViewAll,
  });

  final List<ActivityItem> activities;
  final int maxItems;
  final VoidCallback? onViewAll;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayActivities = activities.take(maxItems).toList();

    if (displayActivities.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline items
          ...List.generate(displayActivities.length, (index) {
            final activity = displayActivities[index];
            final isLast = index == displayActivities.length - 1;
            return _ActivityTimelineItem(
              activity: activity,
              isLast: isLast,
              isDark: isDark,
              formatTimestamp: _formatTimestamp,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 40,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activities will appear here',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  const _ActivityTimelineItem({
    required this.activity,
    required this.isLast,
    required this.isDark,
    required this.formatTimestamp,
  });

  final ActivityItem activity;
  final bool isLast;
  final bool isDark;
  final String Function(DateTime) formatTimestamp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: activity.onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: activity.color.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activity.color,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      activity.icon,
                      size: 12,
                      color: activity.color,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isDark 
                            ? AppColors.darkDivider 
                            : AppColors.divider,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: isDark ? 0.08 : 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activity.color.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (activity.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              activity.subtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTimestamp(activity.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: activity.color,
                      ),
                    ),
                    if (activity.onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: activity.color,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact activity indicator showing count of recent items
class RecentActivityBadge extends StatelessWidget {
  const RecentActivityBadge({
    super.key,
    required this.count,
    this.latestType,
    this.onTap,
  });

  final int count;
  final ActivityType? latestType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = latestType != null
        ? ActivityItem(type: latestType!, title: '', timestamp: DateTime.now()).color
        : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              '$count items',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
