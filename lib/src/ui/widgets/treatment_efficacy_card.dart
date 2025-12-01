import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/treatment_efficacy_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Dashboard card showing treatment efficacy overview for a specific patient
class TreatmentEfficacyCard extends ConsumerWidget {
  const TreatmentEfficacyCard({
    required this.patient,
    super.key,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbFuture = ref.watch(doctorDbProvider);
    final efficacyService = const TreatmentEfficacyService();

    return dbFuture.when(
      data: (db) {
        return FutureBuilder<List<TreatmentMetrics>>(
          future: efficacyService.getPatientTreatmentMetrics(db, patient.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard(context);
            }

            final metrics = snapshot.data ?? [];

            if (metrics.isEmpty) {
              return _buildEmptyCard(context);
            }

            // Get the most recent treatment
            final recentTreatment = metrics.isNotEmpty ? metrics.last : null;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Treatment Efficacy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${metrics.length} Treatments',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (recentTreatment != null) ...[
                      _buildMetricsRow(context, recentTreatment),
                      const SizedBox(height: 12),
                      _buildEfficacyBar(context, metrics),
                      const SizedBox(height: 12),
                      _buildHistoryList(context, metrics),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, error.toString()),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading efficacy data...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'No treatments recorded',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Error loading data',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, TreatmentMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            context,
            title: 'Success Rate',
            value: '${(metrics.successRate * 100).toInt()}%',
            color: metrics.statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            context,
            title: 'Sessions',
            value: metrics.sessionsCompleted.toString(),
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            context,
            title: 'Duration',
            value: '${metrics.durationDays} days',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficacyBar(BuildContext context, List<TreatmentMetrics> metrics) {
    final avgSuccessRate = metrics.isEmpty
        ? 0.0
        : metrics.map((m) => m.successRate).reduce((a, b) => a + b) / metrics.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Success Rate',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(avgSuccessRate * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: avgSuccessRate >= 0.75
                    ? const Color(0xFF10B981)
                    : avgSuccessRate >= 0.5
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: avgSuccessRate,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              avgSuccessRate >= 0.75
                  ? const Color(0xFF10B981)
                  : avgSuccessRate >= 0.5
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, List<TreatmentMetrics> metrics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentMetrics = metrics.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Treatments',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...recentMetrics.asMap().entries.map((entry) {
          final index = entry.key;
          final metric = entry.value;
          final isLast = index == recentMetrics.length - 1;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: metric.statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.diagnosis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          metric.successStatus,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: metric.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(metric.successRate * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: metric.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 8),
                Divider(
                  color: isDark
                      ? Colors.white10
                      : Colors.grey[300],
                  height: 1,
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ],
    );
  }
}

/// Widget showing vital sign trending for a patient
class VitalSignTrendingWidget extends ConsumerWidget {
  const VitalSignTrendingWidget({
    required this.patient,
    this.vitalType = 'systolic_bp',
    this.days = 30,
    super.key,
  });

  final Patient patient;
  final String vitalType;
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbFuture = ref.watch(doctorDbProvider);
    final efficacyService = const TreatmentEfficacyService();

    return dbFuture.when(
      data: (db) {
        return FutureBuilder<VitalSignTrend?>(
          future: efficacyService.getVitalSignTrend(db, patient.id, vitalType, days: days),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final trend = snapshot.data;

            if (trend == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.trending_flat_rounded, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No vital data available'),
                  ],
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getVitalLabel(vitalType),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: trend.trendColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trend.isImproving
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_up_rounded,
                                size: 14,
                                color: trend.trendColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trend.trend,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: trend.trendColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildValueColumn(
                          'Initial',
                          trend.initialValue.toStringAsFixed(1),
                          Colors.grey,
                        ),
                        _buildValueColumn(
                          'Current',
                          trend.currentValue.toStringAsFixed(1),
                          trend.trendColor,
                        ),
                        _buildValueColumn(
                          'Avg',
                          trend.avgValue.toStringAsFixed(1),
                          AppColors.primary,
                        ),
                        _buildValueColumn(
                          'Change',
                          '${trend.percentChange.toStringAsFixed(1)}%',
                          trend.trendColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildValueColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getVitalLabel(String vitalType) {
    switch (vitalType) {
      case 'systolic_bp':
        return 'Systolic BP (mmHg)';
      case 'diastolic_bp':
        return 'Diastolic BP (mmHg)';
      case 'heart_rate':
        return 'Heart Rate (bpm)';
      case 'temperature':
        return 'Temperature (°C)';
      case 'oxygen_sat':
        return 'Oxygen Sat (%)';
      default:
        return 'Vital Sign';
    }
  }
}

