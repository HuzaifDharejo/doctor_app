import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/migration_provider.dart';
import '../../../services/data_migration_service.dart';
import '../../../theme/app_theme.dart';

/// Screen for running data migration to encounter-based system
class DataMigrationScreen extends ConsumerWidget {
  const DataMigrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final migrationState = ref.watch(migrationNotifierProvider);
    final previewAsync = ref.watch(migrationPreviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            _buildInfoCard(isDark),
            const SizedBox(height: 24),

            // Preview section
            previewAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorCard(e.toString(), isDark),
              data: (preview) => _buildPreviewCard(preview, isDark),
            ),
            const SizedBox(height: 24),

            // Migration status
            _buildMigrationStatus(context, ref, migrationState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encounter-Based Migration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This migration will:\n'
                  '• Create encounters for past completed appointments\n'
                  '• Link existing vital signs to encounters\n'
                  '• Extract diagnoses from medical records\n'
                  '• Create clinical notes from existing records\n\n'
                  'This process is safe and can be run multiple times.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(MigrationPreview preview, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.preview_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Migration Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreviewRow(
            icon: Icons.calendar_month_rounded,
            label: 'Appointments to migrate',
            value: preview.appointmentsToMigrate.toString(),
            color: AppColors.appointments,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            icon: Icons.monitor_heart_rounded,
            label: 'Vitals to link',
            value: preview.vitalsToLink.toString(),
            color: const Color(0xFFEC4899),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            icon: Icons.medical_information_rounded,
            label: 'Diagnoses to extract',
            value: preview.diagnosesToExtract.toString(),
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            icon: Icons.folder_rounded,
            label: 'Total records',
            value: preview.totalRecords.toString(),
            color: Colors.orange,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: preview.needsMigration
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  preview.needsMigration
                      ? Icons.pending_actions_rounded
                      : Icons.check_circle_rounded,
                  color: preview.needsMigration ? AppColors.warning : AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  preview.needsMigration
                      ? 'Migration recommended'
                      : 'No migration needed',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: preview.needsMigration ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMigrationStatus(
    BuildContext context,
    WidgetRef ref,
    MigrationState state,
    bool isDark,
  ) {
    return switch (state) {
      MigrationInitial() => _buildStartButton(context, ref, isDark),
      MigrationRunning(:final message, :final progress) =>
        _buildProgressCard(message, progress, isDark),
      MigrationCompleted(:final stats) => _buildCompletedCard(stats, ref, isDark),
      MigrationError(:final error) => _buildErrorCard(error, isDark),
    };
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmAndRun(context, ref),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Migration'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _confirmAndRun(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Migration?'),
        content: const Text(
          'This will migrate your existing data to the new encounter-based system. '
          'The process is safe and can be run multiple times.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run Migration'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(migrationNotifierProvider.notifier).runMigration();
    }
  }

  Widget _buildProgressCard(String message, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(MigrationStats stats, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stats.hasErrors
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              stats.hasErrors ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: stats.hasErrors ? AppColors.warning : AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            stats.hasErrors ? 'Migration Completed with Warnings' : 'Migration Completed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow('Appointments migrated', stats.appointmentsMigrated, isDark),
          _buildStatRow('Vitals linked', stats.vitalsLinked, isDark),
          _buildStatRow('Diagnoses extracted', stats.diagnosesExtracted, isDark),
          _buildStatRow('Records linked', stats.recordsLinked, isDark),
          if (stats.hasErrors) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.errors} error(s) occurred',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  if (stats.errorMessages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...stats.errorMessages.take(3).map((msg) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $msg',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    if (stats.errorMessages.length > 3)
                      Text(
                        '... and ${stats.errorMessages.length - 3} more',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(migrationNotifierProvider.notifier).reset();
                ref.invalidate(migrationPreviewProvider);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: value > 0 ? AppColors.success : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Migration Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
