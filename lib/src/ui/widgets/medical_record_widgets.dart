import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// Design constants for medical record UI components
abstract class MedicalRecordConstants {
  // Spacing
  static const double paddingSmall = 8;
  static const double paddingMedium = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 20;
  
  // Border radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;
  static const double radiusHeader = 32;
  
  // Icon sizes
  static const double iconSmall = 14;
  static const double iconMedium = 18;
  static const double iconLarge = 20;
  static const double iconXLarge = 28;
  static const double iconHeader = 40;
  
  // Font sizes
  static const double fontSmall = 10;
  static const double fontBody = 12;
  static const double fontMedium = 13;
  static const double fontLarge = 14;
  static const double fontTitle = 16;
  static const double fontHeader = 20;
  static const double fontXLarge = 24;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  
  // Colors for record types
  static const Color pulmonaryColor = Color(0xFF00ACC1);
  static const Color psychiatricColor = AppColors.primary;
  static const Color labResultColor = AppColors.warning;
  static const Color imagingColor = AppColors.info;
  static const Color procedureColor = AppColors.accent;
  static const Color followUpColor = AppColors.success;
  static const Color generalColor = AppColors.primary;
}

// ============================================================================
// MODELS
// ============================================================================

/// Immutable model representing record type metadata
@immutable
class RecordTypeInfo {

  const RecordTypeInfo({
    required this.icon,
    required this.color,
    required this.label,
    required this.recordType,
  });

  /// Factory to create RecordTypeInfo from record type string
  factory RecordTypeInfo.fromType(String recordType) {
    return _recordTypeMap[recordType] ?? _defaultRecordType;
  }
  final IconData icon;
  final Color color;
  final String label;
  final String recordType;

  static const _defaultRecordType = RecordTypeInfo(
    icon: Icons.medical_services_outlined,
    color: MedicalRecordConstants.generalColor,
    label: 'General Consultation',
    recordType: 'general',
  );

  static const Map<String, RecordTypeInfo> _recordTypeMap = {
    'pulmonary_evaluation': RecordTypeInfo(
      icon: Icons.air,
      color: MedicalRecordConstants.pulmonaryColor,
      label: 'Pulmonary Evaluation',
      recordType: 'pulmonary_evaluation',
    ),
    'psychiatric_assessment': RecordTypeInfo(
      icon: Icons.psychology,
      color: MedicalRecordConstants.psychiatricColor,
      label: 'Psychiatric Assessment',
      recordType: 'psychiatric_assessment',
    ),
    'lab_result': RecordTypeInfo(
      icon: Icons.science_outlined,
      color: MedicalRecordConstants.labResultColor,
      label: 'Lab Result',
      recordType: 'lab_result',
    ),
    'imaging': RecordTypeInfo(
      icon: Icons.image_outlined,
      color: MedicalRecordConstants.imagingColor,
      label: 'Imaging/Radiology',
      recordType: 'imaging',
    ),
    'procedure': RecordTypeInfo(
      icon: Icons.healing_outlined,
      color: MedicalRecordConstants.procedureColor,
      label: 'Procedure',
      recordType: 'procedure',
    ),
    'follow_up': RecordTypeInfo(
      icon: Icons.event_repeat,
      color: MedicalRecordConstants.followUpColor,
      label: 'Follow-up Visit',
      recordType: 'follow_up',
    ),
    'general': _defaultRecordType,
  };

  /// Get all available record types for filtering
  static List<RecordTypeInfo> get allTypes => [
    const RecordTypeInfo(
      icon: Icons.grid_view_rounded,
      color: AppColors.primary,
      label: 'All Types',
      recordType: '',
    ),
    ..._recordTypeMap.values,
  ];
}

/// Mental State Examination item configuration
@immutable
class MseItemConfig {

  const MseItemConfig({
    required this.key,
    required this.label,
    required this.icon,
  });
  final String key;
  final String label;
  final IconData icon;

  static const List<MseItemConfig> allItems = [
    MseItemConfig(key: 'appearance', label: 'Appearance', icon: Icons.person_outline),
    MseItemConfig(key: 'behavior', label: 'Behavior', icon: Icons.directions_walk),
    MseItemConfig(key: 'speech', label: 'Speech', icon: Icons.record_voice_over),
    MseItemConfig(key: 'mood', label: 'Mood', icon: Icons.mood),
    MseItemConfig(key: 'affect', label: 'Affect', icon: Icons.sentiment_satisfied),
    MseItemConfig(key: 'thought_content', label: 'Thought Content', icon: Icons.psychology),
    MseItemConfig(key: 'thought_process', label: 'Thought Process', icon: Icons.account_tree),
    MseItemConfig(key: 'perception', label: 'Perception', icon: Icons.visibility),
    MseItemConfig(key: 'cognition', label: 'Cognition', icon: Icons.lightbulb_outline),
    MseItemConfig(key: 'insight', label: 'Insight', icon: Icons.self_improvement),
    MseItemConfig(key: 'judgment', label: 'Judgment', icon: Icons.balance),
  ];
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

/// A decorated icon button with semi-transparent background
class HeaderIconButton extends StatelessWidget {

  const HeaderIconButton({
    required this.icon, required this.onTap, super.key,
    this.semanticLabel,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x33FFFFFF), // white with 20% opacity
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
          ),
          child: Icon(icon, color: iconColor, size: MedicalRecordConstants.iconLarge),
        ),
      ),
    );
  }
}

/// A card with icon, title, and content
class InfoCard extends StatelessWidget {

  const InfoCard({
    required this.title, required this.content, required this.icon, required this.color, required this.isDark, super.key,
  });
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, icon: icon, color: color),
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          Text(
            content,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontLarge,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small statistic card with icon and value
class StatCard extends StatelessWidget {

  const StatCard({
    required this.label, required this.value, required this.icon, required this.color, required this.isDark, super.key,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: MedicalRecordConstants.iconMedium),
              const SizedBox(width: MedicalRecordConstants.paddingSmall),
              Text(
                label,
                style: TextStyle(
                  fontSize: MedicalRecordConstants.fontBody,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MedicalRecordConstants.paddingSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontTitle,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section displaying chips/tags
class ChipsSection extends StatelessWidget {

  const ChipsSection({
    required this.title, required this.items, required this.color, required this.icon, required this.isDark, super.key,
  });
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: title, icon: icon, color: color),
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          Wrap(
            spacing: MedicalRecordConstants.paddingSmall,
            runSpacing: MedicalRecordConstants.paddingSmall,
            children: items.map((item) => _Chip(text: item, color: color)).toList(),
          ),
        ],
      ),
    );
  }
}

/// A single vital sign display
class VitalItem extends StatelessWidget {

  const VitalItem({
    required this.label, required this.value, required this.unit, required this.icon, required this.color, super.key,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: MedicalRecordConstants.iconMedium, color: color),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: MedicalRecordConstants.fontSmall, color: color),
              ),
              Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: MedicalRecordConstants.fontLarge,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A risk level badge with color coding
class RiskBadge extends StatelessWidget {

  const RiskBadge({
    required this.label, required this.level, super.key,
  });
  final String label;
  final String level;

  Color get _color {
    switch (level.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: MedicalRecordConstants.fontBody - 1, color: _color),
          ),
          const SizedBox(height: 4),
          Text(
            level,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontTitle,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip for record type selection
class RecordTypeFilterChip extends StatelessWidget {

  const RecordTypeFilterChip({
    required this.recordType, required this.isSelected, required this.onTap, required this.isDark, super.key,
  });
  final RecordTypeInfo recordType;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = recordType.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MedicalRecordConstants.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: MedicalRecordConstants.paddingLarge,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recordType.icon,
              size: MedicalRecordConstants.iconMedium,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: MedicalRecordConstants.paddingSmall),
            Text(
              recordType.label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: MedicalRecordConstants.fontMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PRIVATE HELPER WIDGETS
// ============================================================================

class _CardHeader extends StatelessWidget {

  const _CardHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MedicalRecordConstants.fontLarge,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {

  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: MedicalRecordConstants.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================================
// EXTENSIONS
// ============================================================================

/// Extension for safely accessing map values with null handling
extension SafeMapAccess on Map<String, dynamic> {
  /// Get string value or empty string if null/invalid
  String getString(String key) {
    final value = this[key];
    return value?.toString() ?? '';
  }
  
  /// Get list value or empty list if null/invalid
  /// Also handles Map<String, bool> where we extract keys with true values
  List<String> getStringList(String key) {
    final value = this[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    // Handle Map<String, bool> - return keys with true values
    if (value is Map) {
      return value.entries
          .where((e) => e.value == true)
          .map((e) => e.key.toString())
          .toList();
    }
    return [];
  }
  
  /// Get nested map or empty map if null/invalid
  Map<String, dynamic> getMap(String key) {
    final value = this[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {};
  }
  
  /// Check if key exists and has non-empty value
  bool hasValue(String key) {
    final value = this[key];
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}

/// Extension for calculating age from DateTime
extension AgeCalculation on DateTime {
  /// Calculate age in years from this date
  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
}

