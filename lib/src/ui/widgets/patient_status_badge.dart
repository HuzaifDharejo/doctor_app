import 'package:flutter/material.dart';
import '../../services/patient_status_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Visual status badge widget for patient cards
class PatientStatusBadge extends StatelessWidget {
  const PatientStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.medium,
    this.showIcon = true,
    this.showLabel = true,
  });

  final PatientStatus status;
  final BadgeSize size;
  final bool showIcon;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == BadgeSize.small ? 6 : 8,
        vertical: size == BadgeSize.small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size == BadgeSize.small ? 8 : 12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: size == BadgeSize.small ? 12 : 14,
              color: config.color,
            ),
            if (showLabel) const SizedBox(width: 4),
          ],
          if (showLabel)
            Text(
              config.label,
              style: TextStyle(
                fontSize: size == BadgeSize.small ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: config.color,
              ),
            ),
        ],
      ),
    );
  }

  StatusConfig _getStatusConfig(PatientStatus status) {
    switch (status) {
      case PatientStatus.inRoom:
        return StatusConfig(
          label: 'In Room',
          icon: Icons.meeting_room_rounded,
          color: const Color(0xFFEF4444), // Red
        );
      case PatientStatus.consulted:
        return StatusConfig(
          label: 'Consulted',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981), // Green
        );
      case PatientStatus.labPending:
        return StatusConfig(
          label: 'Lab Pending',
          icon: Icons.science_rounded,
          color: const Color(0xFFF59E0B), // Yellow/Orange
        );
      case PatientStatus.followUpDue:
        return StatusConfig(
          label: 'Follow-up Due',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF3B82F6), // Blue
        );
      case PatientStatus.highRisk:
        return StatusConfig(
          label: 'High Risk',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFEF4444), // Red
        );
      case PatientStatus.none:
        return StatusConfig(
          label: '',
          icon: Icons.circle,
          color: Colors.transparent,
        );
    }
  }
}

/// Badge size options
enum BadgeSize {
  small,
  medium,
  large,
}

/// Status configuration
class StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Multiple status badges widget (for showing all statuses)
class PatientStatusBadges extends StatelessWidget {
  const PatientStatusBadges({
    super.key,
    required this.statuses,
    this.size = BadgeSize.medium,
    this.maxBadges = 3,
  });

  final List<PatientStatus> statuses;
  final BadgeSize size;
  final int maxBadges;

  @override
  Widget build(BuildContext context) {
    // Filter out 'none' status and limit to maxBadges
    final displayStatuses = statuses
        .where((s) => s != PatientStatus.none)
        .take(maxBadges)
        .toList();

    if (displayStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: displayStatuses
          .map((status) => PatientStatusBadge(
                status: status,
                size: size,
              ))
          .toList(),
    );
  }
}


