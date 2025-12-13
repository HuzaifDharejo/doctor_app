/// Appointment type utilities and color mappings
library;

import 'package:flutter/material.dart';

/// Appointment type configuration with colors
class AppointmentTypeConfig {
  const AppointmentTypeConfig({
    required this.type,
    required this.label,
    required this.color,
    required this.icon,
    this.gradientColors,
  });

  final String type;
  final String label;
  final Color color;
  final IconData icon;
  final List<Color>? gradientColors;

  List<Color> get gradient => gradientColors ?? [color, color.withValues(alpha: 0.8)];
}

/// Appointment types and their visual configurations
class AppointmentTypes {
  AppointmentTypes._();

  static const Color newPatientColor = Color(0xFF6366F1);
  static const Color followUpColor = Color(0xFF10B981);
  static const Color urgentColor = Color(0xFFEF4444);
  static const Color telemedicineColor = Color(0xFF8B5CF6);
  static const Color routineColor = Color(0xFF3B82F6);
  static const Color consultationColor = Color(0xFFF59E0B);
  static const Color procedureColor = Color(0xFFEC4899);
  static const Color labWorkColor = Color(0xFF14B8A6);

  static final Map<String, AppointmentTypeConfig> types = {
    'new_patient': const AppointmentTypeConfig(
      type: 'new_patient',
      label: 'New Patient',
      color: newPatientColor,
      icon: Icons.person_add_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    ),
    'follow_up': const AppointmentTypeConfig(
      type: 'follow_up',
      label: 'Follow-up',
      color: followUpColor,
      icon: Icons.event_repeat_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    'urgent': const AppointmentTypeConfig(
      type: 'urgent',
      label: 'Urgent',
      color: urgentColor,
      icon: Icons.priority_high_rounded,
      gradientColors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    'telemedicine': const AppointmentTypeConfig(
      type: 'telemedicine',
      label: 'Telemedicine',
      color: telemedicineColor,
      icon: Icons.videocam_rounded,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    'routine': const AppointmentTypeConfig(
      type: 'routine',
      label: 'Routine',
      color: routineColor,
      icon: Icons.event_rounded,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ),
    'consultation': const AppointmentTypeConfig(
      type: 'consultation',
      label: 'Consultation',
      color: consultationColor,
      icon: Icons.medical_services_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    'procedure': const AppointmentTypeConfig(
      type: 'procedure',
      label: 'Procedure',
      color: procedureColor,
      icon: Icons.healing_rounded,
      gradientColors: [Color(0xFFEC4899), Color(0xFFDB2777)],
    ),
    'lab_work': const AppointmentTypeConfig(
      type: 'lab_work',
      label: 'Lab Work',
      color: labWorkColor,
      icon: Icons.science_rounded,
      gradientColors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    ),
  };

  /// Get configuration for an appointment type
  static AppointmentTypeConfig getConfig(String? type) {
    if (type == null) return types['routine']!;
    return types[type.toLowerCase()] ?? types['routine']!;
  }

  /// Get color for an appointment type
  static Color getColor(String? type) {
    return getConfig(type).color;
  }

  /// Get icon for an appointment type
  static IconData getIcon(String? type) {
    return getConfig(type).icon;
  }

  /// Get gradient for an appointment type
  static List<Color> getGradient(String? type) {
    return getConfig(type).gradient;
  }

  /// Determine type from reason text (heuristic)
  static String inferType(String? reason) {
    if (reason == null || reason.isEmpty) return 'routine';

    final lowerReason = reason.toLowerCase();

    if (lowerReason.contains('new patient') || lowerReason.contains('first visit')) {
      return 'new_patient';
    }
    if (lowerReason.contains('follow') || lowerReason.contains('check-up') || lowerReason.contains('review')) {
      return 'follow_up';
    }
    if (lowerReason.contains('urgent') || lowerReason.contains('emergency') || lowerReason.contains('immediate')) {
      return 'urgent';
    }
    if (lowerReason.contains('tele') || lowerReason.contains('video') || lowerReason.contains('virtual') || lowerReason.contains('online')) {
      return 'telemedicine';
    }
    if (lowerReason.contains('consult')) {
      return 'consultation';
    }
    if (lowerReason.contains('procedure') || lowerReason.contains('surgery') || lowerReason.contains('operation')) {
      return 'procedure';
    }
    if (lowerReason.contains('lab') || lowerReason.contains('blood') || lowerReason.contains('test')) {
      return 'lab_work';
    }

    return 'routine';
  }
}

/// Widget to display appointment type badge
class AppointmentTypeBadge extends StatelessWidget {
  const AppointmentTypeBadge({
    super.key,
    this.type,
    this.reason,
    this.compact = false,
    this.showIcon = true,
  });

  final String? type;
  final String? reason;
  final bool compact;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final effectiveType = type ?? AppointmentTypes.inferType(reason);
    final config = AppointmentTypes.getConfig(effectiveType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config.icon,
              size: compact ? 12 : 14,
              color: config.color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored strip indicator for appointment type
class AppointmentTypeStrip extends StatelessWidget {
  const AppointmentTypeStrip({
    super.key,
    this.type,
    this.reason,
    this.width = 4,
    this.height,
    this.borderRadius = 2,
  });

  final String? type;
  final String? reason;
  final double width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveType = type ?? AppointmentTypes.inferType(reason);
    final colors = AppointmentTypes.getGradient(effectiveType);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
