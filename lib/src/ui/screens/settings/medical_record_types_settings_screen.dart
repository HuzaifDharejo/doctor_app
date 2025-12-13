import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/db_provider.dart';
import '../../../services/doctor_settings_service.dart';
import '../../../theme/app_theme.dart';

/// Settings screen for managing enabled medical record types
class MedicalRecordTypesSettingsScreen extends ConsumerStatefulWidget {
  const MedicalRecordTypesSettingsScreen({super.key});

  @override
  ConsumerState<MedicalRecordTypesSettingsScreen> createState() =>
      _MedicalRecordTypesSettingsScreenState();
}

class _MedicalRecordTypesSettingsScreenState
    extends ConsumerState<MedicalRecordTypesSettingsScreen> {
  final Map<String, IconData> _typeIcons = {
    // Core types
    'general': Icons.medical_services_outlined,
    'follow_up': Icons.event_repeat,
    'lab_result': Icons.science_outlined,
    'imaging': Icons.image_outlined,
    'procedure': Icons.healing_outlined,
    // Mental health types
    'pulmonary_evaluation': Icons.air,
    'psychiatric_assessment': Icons.psychology,
    'therapy_session': Icons.self_improvement,
    'psychiatrist_note': Icons.psychology_alt,
    // Specialty examination types
    'cardiac_exam': Icons.favorite,
    'pediatric_checkup': Icons.child_care,
    'eye_exam': Icons.visibility,
    'skin_exam': Icons.face_retouching_natural,
    'ent_exam': Icons.hearing,
    'orthopedic_exam': Icons.accessibility_new,
    'gyn_exam': Icons.pregnant_woman,
    'neuro_exam': Icons.psychology_alt,
    'gi_exam': Icons.medical_information,
  };

  final Map<String, Color> _typeColors = {
    // Core types
    'general': AppColors.primary,
    'follow_up': const Color(0xFF14B8A6),
    'lab_result': const Color(0xFF10B981),
    'imaging': const Color(0xFFF59E0B),
    'procedure': const Color(0xFFEF4444),
    // Mental health types
    'pulmonary_evaluation': const Color(0xFF0EA5E9),
    'psychiatric_assessment': const Color(0xFF8B5CF6),
    'therapy_session': const Color(0xFFEC4899),
    'psychiatrist_note': const Color(0xFF6366F1),
    // Specialty examination types
    'cardiac_exam': const Color(0xFFEF4444),
    'pediatric_checkup': const Color(0xFFF59E0B),
    'eye_exam': const Color(0xFF06B6D4),
    'skin_exam': const Color(0xFFF97316),
    'ent_exam': const Color(0xFF8B5CF6),
    'orthopedic_exam': const Color(0xFF10B981),
    'gyn_exam': const Color(0xFFEC4899),
    'neuro_exam': const Color(0xFF6366F1),
    'gi_exam': const Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider).settings;
    final enabledTypes = settings.enabledMedicalRecordTypes;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Record Types'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final allEnabled =
                  enabledTypes.length == AppSettings.allMedicalRecordTypes.length;
              if (allEnabled) {
                ref.read(appSettingsProvider).setEnabledMedicalRecordTypes(['general']);
              } else {
                ref.read(appSettingsProvider).setEnabledMedicalRecordTypes(
                  List.from(AppSettings.allMedicalRecordTypes),
                );
              }
            },
            child: Text(
              enabledTypes.length == AppSettings.allMedicalRecordTypes.length
                  ? 'Disable All'
                  : 'Enable All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.folder_special_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${enabledTypes.length} of ${AppSettings.allMedicalRecordTypes.length} enabled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toggle record types to show/hide them in the app',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Record types list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: AppSettings.allMedicalRecordTypes.length,
              itemBuilder: (context, index) {
                final type = AppSettings.allMedicalRecordTypes[index];
                final isEnabled = enabledTypes.contains(type);
                final label = AppSettings.medicalRecordTypeLabels[type] ?? type;
                final description =
                    AppSettings.medicalRecordTypeDescriptions[type] ?? '';
                final icon = _typeIcons[type] ?? Icons.description;
                final color = _typeColors[type] ?? AppColors.primary;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isEnabled
                          ? color.withValues(alpha: 0.3)
                          : (isDark ? AppColors.darkDivider : AppColors.divider),
                      width: isEnabled ? 1.5 : 1,
                    ),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleType(type, !isEnabled, enabledTypes),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (isEnabled ? color : AppColors.textHint)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                icon,
                                color: isEnabled ? color : AppColors.textHint,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isEnabled
                                          ? (isDark ? Colors.white : AppColors.textPrimary)
                                          : AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Switch
                            Switch.adaptive(
                              value: isEnabled,
                              onChanged: (value) =>
                                  _toggleType(type, value, enabledTypes),
                              activeColor: color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleType(String type, bool value, List<String> enabledTypes) {
    // Ensure at least one type is always enabled
    if (!value && enabledTypes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('At least one record type must be enabled'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    ref.read(appSettingsProvider).toggleMedicalRecordType(type, value);
  }
}
