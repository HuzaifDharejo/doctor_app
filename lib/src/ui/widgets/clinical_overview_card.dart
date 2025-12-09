import 'package:flutter/material.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/components/app_button.dart';

/// Clinical Overview Card for Doctor Workflow
/// Displays critical patient information prominently for quick clinical assessment
class ClinicalOverviewCard extends StatelessWidget {
  final Patient patient;
  final List<String> allergies;
  final String? latestBP;
  final String? latestTemperature;
  final VoidCallback onViewFullHistory;
  final VoidCallback onAddVitals;

  const ClinicalOverviewCard({
    Key? key,
    required this.patient,
    this.allergies = const [],
    this.latestBP,
    this.latestTemperature,
    required this.onViewFullHistory,
    required this.onAddVitals,
  }) : super(key: key);

  int? _getAge() {
    return patient.age;
  }

  Color _getRiskLevelColor() {
    switch (patient.riskLevel) {
      case 2:
        return AppColors.error;
      case 1:
        return AppColors.warning;
      case 0:
      default:
        return AppColors.success;
    }
  }

  IconData _getRiskLevelIcon() {
    switch (patient.riskLevel) {
      case 2:
        return Icons.priority_high;
      case 1:
        return Icons.warning_amber;
      case 0:
      default:
        return Icons.check_circle;
    }
  }
  
  String _getRiskLevelLabel(int level) {
    switch (level) {
      case 2:
        return 'High Risk';
      case 1:
        return 'Medium Risk';
      case 0:
      default:
        return 'Low Risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _getAge();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = _getRiskLevelColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Risk Level
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age != null ? '$age years old' : 'Age not set',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Risk Level Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRiskLevelIcon(),
                        color: riskColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getRiskLevelLabel(patient.riskLevel),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Critical Allergies Section (if any)
            if (allergies.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KNOWN ALLERGIES',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergies.map((allergy) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            allergy,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Latest Vitals Section
            if (latestBP != null || latestTemperature != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Vitals',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (latestBP != null) ...[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BP',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        latestBP!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (latestTemperature != null) ...[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Temp',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        latestTemperature!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: onAddVitals,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Update'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.tertiary(
                    label: 'Full History',
                    icon: Icons.history,
                    size: AppButtonSize.small,
                    onPressed: onViewFullHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    label: 'Prescribe',
                    icon: Icons.medication,
                    size: AppButtonSize.small,
                    onPressed: () {
                      // Trigger prescription workflow
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


