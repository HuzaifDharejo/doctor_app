import 'package:flutter/material.dart';
import 'package:doctor_app/src/services/comprehensive_risk_assessment_service.dart';
import 'package:doctor_app/src/theme/app_theme.dart';

/// Widget to display critical alerts in a prominent, actionable way
class CriticalAlertsWidget extends StatelessWidget {
  final List<RiskFactor> riskFactors;
  final VoidCallback onDismiss;
  final Function(RiskFactor)? onTap;

  const CriticalAlertsWidget({
    super.key,
    required this.riskFactors,
    required this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final criticalFactors = riskFactors.where((f) => f.riskLevel == RiskLevel.critical).toList();
    final highFactors = riskFactors.where((f) => f.riskLevel == RiskLevel.high).toList();

    if (criticalFactors.isEmpty && highFactors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Critical Alerts Section
          if (criticalFactors.isNotEmpty)
            _buildAlertSection(
              context,
              'CRITICAL ALERTS',
              criticalFactors,
              Colors.red,
            ),
          if (criticalFactors.isNotEmpty && highFactors.isNotEmpty) const SizedBox(height: 8),
          // High Priority Section
          if (highFactors.isNotEmpty)
            _buildAlertSection(
              context,
              'High Priority',
              highFactors,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertSection(
    BuildContext context,
    String title,
    List<RiskFactor> factors,
    Color color,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${factors.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < factors.length; i++) ...[
              if (i > 0) const Divider(height: 12),
              _buildAlertItem(context, factors[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, RiskFactor factor) {
    return InkWell(
      onTap: () => onTap?.call(factor),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              factor.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (factor.recommendations.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...factor.recommendations.take(2).map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              rec,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
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

/// Widget to display risk assessment summary
class RiskSummaryCard extends StatelessWidget {
  final ComprehensiveRiskAssessment assessment;
  final VoidCallback onTap;

  const RiskSummaryCard({
    super.key,
    required this.assessment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(assessment.overallRiskLevel.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Assessment',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      Text(
                        assessment.overallRiskLevel.label,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  // Risk indicators
                  Column(
                    children: [
                      _buildRiskIndicator('🔴', assessment.criticalRiskCount, 'Critical'),
                      const SizedBox(height: 4),
                      _buildRiskIndicator('🟠', assessment.highRiskCount, 'High'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (assessment.followUpRequired)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Follow-up appointment required',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String emoji, int count, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Detailed risk assessment modal/dialog
class RiskAssessmentDetail extends StatelessWidget {
  final ComprehensiveRiskAssessment assessment;

  const RiskAssessmentDetail({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Color(assessment.overallRiskLevel.colorValue).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assessment,
                    color: Color(assessment.overallRiskLevel.colorValue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Assessment',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      Text(
                        assessment.overallRiskLevel.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(assessment.overallRiskLevel.colorValue),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Risk Summary
            _buildSummarySection(context),
            const SizedBox(height: 24),

            // Risk Factors by Category
            ..._buildRiskFactorSections(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCountBox(context, '🔴 Critical', assessment.criticalRiskCount),
            const SizedBox(width: 8),
            _buildCountBox(context, '🟠 High', assessment.highRiskCount),
            const SizedBox(width: 8),
            _buildCountBox(context, '🟡 Medium', assessment.mediumRiskCount),
          ],
        ),
        if (assessment.followUpRequired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Follow-up appointment is required',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCountBox(BuildContext context, String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRiskFactorSections(BuildContext context) {
    final sections = <Widget>[];
    final categories = <String, List<RiskFactor>>{};

    for (final factor in assessment.riskFactors) {
      categories.putIfAbsent(factor.category, () => []).add(factor);
    }

    for (final entry in categories.entries) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCategoryLabel(entry.key),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...entry.value.map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildRiskFactorCard(context, factor),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return sections;
  }

  Widget _buildRiskFactorCard(BuildContext context, RiskFactor factor) {
    final color = Color(factor.riskLevel.colorValue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  factor.riskLevel.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            factor.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (factor.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recommendations:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            ...factor.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        rec,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'allergy':
        return '⚠️ Allergy Risks';
      case 'drug_interaction':
        return '💊 Drug Interactions';
      case 'vital_sign':
        return '❤️ Vital Signs';
      case 'clinical':
        return '🏥 Clinical Risks';
      case 'appointment':
        return '📅 Appointment Issues';
      default:
        return category;
    }
  }
}


