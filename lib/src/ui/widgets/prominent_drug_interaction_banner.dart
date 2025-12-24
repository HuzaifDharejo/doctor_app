import 'package:flutter/material.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../services/drug_interaction_service.dart';
import '../../services/allergy_checking_service.dart';

/// Prominent Drug Interaction Warning Banner
/// Cannot be dismissed without acknowledgment for critical interactions
class ProminentDrugInteractionBanner extends StatelessWidget {
  const ProminentDrugInteractionBanner({
    super.key,
    required this.drugInteractions,
    required this.allergyAlerts,
    required this.medicationNames,
    required this.patientAllergies,
    this.onViewDetails,
    this.onAcknowledge,
    this.acknowledged = false,
  });

  final List<DrugInteraction> drugInteractions;
  final List<AllergyCheckResult> allergyAlerts;
  final List<String> medicationNames;
  final String patientAllergies;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAcknowledge;
  final bool acknowledged;

  bool get hasCriticalInteractions =>
      drugInteractions.any((i) => i.severity == InteractionSeverity.severe);
  
  bool get hasSevereAllergies =>
      allergyAlerts.any((a) => a.severity == AllergySeverity.severe);

  bool get hasCritical => hasCriticalInteractions || hasSevereAllergies;

  bool get hasModerateInteractions =>
      drugInteractions.any((i) => i.severity == InteractionSeverity.moderate);
  
  bool get hasModerateAllergies =>
      allergyAlerts.any((a) => a.severity == AllergySeverity.moderate);

  bool get hasModerate => hasModerateInteractions || hasModerateAllergies;

  bool get hasMinor =>
      drugInteractions.any((i) => i.severity == InteractionSeverity.mild) ||
      allergyAlerts.any((a) => a.severity == AllergySeverity.mild);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (drugInteractions.isEmpty && allergyAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine severity and colors
    Color bannerColor;
    Color borderColor;
    Color textColor;
    Color backgroundColor;
    IconData icon;
    String severityLabel;

    if (hasCritical) {
      bannerColor = AppColors.error;
      borderColor = AppColors.error;
      textColor = Colors.white;
      backgroundColor = AppColors.error.withValues(alpha: 0.15);
      icon = Icons.error_outline_rounded;
      severityLabel = '🔴 CRITICAL';
    } else if (hasModerate) {
      bannerColor = AppColors.warning;
      borderColor = AppColors.warning;
      textColor = isDark ? Colors.white : AppColors.textPrimary;
      backgroundColor = AppColors.warning.withValues(alpha: 0.1);
      icon = Icons.warning_amber_rounded;
      severityLabel = '🟡 MODERATE';
    } else {
      bannerColor = AppColors.success;
      borderColor = AppColors.success.withValues(alpha: 0.5);
      textColor = isDark ? Colors.white : AppColors.textPrimary;
      backgroundColor = AppColors.success.withValues(alpha: 0.08);
      icon = Icons.info_outline_rounded;
      severityLabel = '🟢 MINOR';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: hasCritical ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.2),
            blurRadius: hasCritical ? 20 : 10,
            offset: const Offset(0, 4),
            spreadRadius: hasCritical ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasCritical
                  ? bannerColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bannerColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: bannerColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Title and Severity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            severityLabel,
                            style: TextStyle(
                              fontSize: AppFontSize.xs,
                              fontWeight: FontWeight.w900,
                              color: bannerColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (hasCritical) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'REQUIRES ACKNOWLEDGMENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasCritical
                            ? 'CRITICAL SAFETY ALERT'
                            : hasModerate
                                ? 'Safety Warning'
                                : 'Minor Interaction',
                        style: TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Interaction Summary
                if (drugInteractions.isNotEmpty) ...[
                  _buildSummaryItem(
                    context,
                    'Drug Interactions',
                    drugInteractions.length,
                    _getInteractionCounts(),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                ],

                // Allergy Summary
                if (allergyAlerts.isNotEmpty) ...[
                  _buildSummaryItem(
                    context,
                    'Allergy Conflicts',
                    allergyAlerts.length,
                    _getAllergyCounts(),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                ],

                // Warning Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bannerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        hasCritical ? Icons.block_rounded : Icons.warning_amber_rounded,
                        color: bannerColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasCritical
                              ? 'This prescription cannot be saved until the interaction is acknowledged. Please review the details and provide clinical justification if proceeding.'
                              : hasModerate
                                  ? 'Review the interaction details before saving this prescription. Consider alternative medications if appropriate.'
                                  : 'Minor interaction detected. Review details before proceeding.',
                          style: TextStyle(
                            fontSize: AppFontSize.md,
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'View Details',
                        icon: Icons.info_outline_rounded,
                        onPressed: onViewDetails ?? () {},
                      ),
                    ),
                    if (hasCritical) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: acknowledged
                            ? AppButton(
                                label: 'Acknowledged ✓',
                                icon: Icons.check_circle_rounded,
                                onPressed: null,
                                variant: AppButtonVariant.primary,
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                isDisabled: true,
                              )
                            : AppButton.danger(
                                label: 'Acknowledge Risk',
                                icon: Icons.verified_user_rounded,
                                onPressed: onAcknowledge,
                              ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    int totalCount,
    Map<String, int> counts,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (counts['critical'] != null && counts['critical']! > 0) ...[
            _buildCountBadge('Critical', counts['critical']!, AppColors.error),
            const SizedBox(width: 8),
          ],
          if (counts['moderate'] != null && counts['moderate']! > 0) ...[
            _buildCountBadge('Moderate', counts['moderate']!, AppColors.warning),
            const SizedBox(width: 8),
          ],
          if (counts['minor'] != null && counts['minor']! > 0)
            _buildCountBadge('Minor', counts['minor']!, AppColors.success),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.xs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getInteractionCounts() {
    return {
      'critical': drugInteractions
          .where((i) => i.severity == InteractionSeverity.severe)
          .length,
      'moderate': drugInteractions
          .where((i) => i.severity == InteractionSeverity.moderate)
          .length,
      'minor': drugInteractions
          .where((i) => i.severity == InteractionSeverity.mild)
          .length,
    };
  }

  Map<String, int> _getAllergyCounts() {
    return {
      'critical': allergyAlerts
          .where((a) => a.severity == AllergySeverity.severe)
          .length,
      'moderate': allergyAlerts
          .where((a) => a.severity == AllergySeverity.moderate)
          .length,
      'minor': allergyAlerts
          .where((a) => a.severity == AllergySeverity.mild)
          .length,
    };
  }
}

