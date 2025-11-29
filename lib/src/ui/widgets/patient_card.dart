import 'package:flutter/material.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';
import '../screens/patient_view_screen.dart';
import 'patient_avatar.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  const PatientCard({super.key, required this.patient});

  Color _getRiskColor(int riskLevel) {
    if (riskLevel <= 2) return AppColors.riskLow;
    if (riskLevel <= 4) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  String _getRiskLabel(int riskLevel) {
    if (riskLevel <= 2) return 'Low';
    if (riskLevel <= 4) return 'Medium';
    return 'High';
  }

  IconData _getRiskIcon(int riskLevel) {
    if (riskLevel <= 2) return Icons.check_circle_rounded;
    if (riskLevel <= 4) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = patient.riskLevel;
    final riskColor = _getRiskColor(riskLevel);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientViewScreen(patient: patient),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primaryLight.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: PatientAvatar(
                      patientId: patient.id,
                      firstName: patient.firstName,
                      lastName: patient.lastName,
                      size: isCompact ? 44 : 50,
                      editable: false,
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                            Expanded(
                            child: Text(
                              '${patient.firstName} ${patient.lastName}',
                              style: TextStyle(
                                fontSize: isCompact ? 13 : 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Risk Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  riskColor.withOpacity(0.2),
                                  riskColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRiskIcon(riskLevel),
                                  size: 12,
                                  color: riskColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRiskLabel(riskLevel),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: riskColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 6 : 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patient.phone.isNotEmpty ? patient.phone : 'No phone',
                              style: TextStyle(
                                fontSize: isCompact ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (patient.medicalHistory.isNotEmpty) ...[
                        SizedBox(height: isCompact ? 8 : 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: patient.medicalHistory
                              .split(',')
                              .take(2)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withOpacity(0.12),
                                          AppColors.primaryLight.withOpacity(0.08),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag.trim().length > 15 ? '${tag.trim().substring(0, 12)}...' : tag.trim(),
                                      style: TextStyle(
                                        fontSize: isCompact ? 9 : 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
