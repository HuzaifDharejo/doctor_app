import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/components/app_button.dart';
import 'patient_status_badge.dart';
import 'package:flutter/services.dart';

/// Patient Queue Management Widget
/// Shows checked-in patients in order with estimated wait times
class PatientQueueWidget extends ConsumerStatefulWidget {
  const PatientQueueWidget({
    super.key,
    this.onCallNext,
    this.onPatientTap,
  });

  final VoidCallback? onCallNext;
  final void Function(Patient patient)? onPatientTap;

  @override
  ConsumerState<PatientQueueWidget> createState() => _PatientQueueWidgetState();
}

class _PatientQueueWidgetState extends ConsumerState<PatientQueueWidget> {
  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = context.isDarkMode;

    return dbAsync.when(
      data: (db) => FutureBuilder<_QueueData>(
        future: _loadQueueData(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString(), isDark);
          }

          final queueData = snapshot.data ?? _QueueData.empty();
          return _buildQueueView(context, queueData, isDark);
        },
      ),
      loading: () => _buildLoadingState(isDark),
      error: (err, _) => _buildErrorState(context, err.toString(), isDark),
    );
  }

  Future<_QueueData> _loadQueueData(DoctorDatabase db) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get all appointments for today
    final appointments = await db.getAppointmentsForDay(today);

    // Filter checked-in and in-progress appointments
    final queueAppointments = appointments
        .where((a) => a.status == 'checked_in' || a.status == 'in_progress')
        .toList();

    // Sort by check-in time or appointment time
    queueAppointments.sort((a, b) {
      // In-progress first
      if (a.status == 'in_progress' && b.status != 'in_progress') return -1;
      if (a.status != 'in_progress' && b.status == 'in_progress') return 1;
      
      // Then by appointment time
      return a.appointmentDateTime.compareTo(b.appointmentDateTime);
    });

    // Load patient data
    final queueItems = <_QueueItem>[];
    for (final apt in queueAppointments) {
      final patient = await db.getPatientById(apt.patientId);
      if (patient != null) {
        // Calculate wait time
        final waitTime = _calculateWaitTime(apt, today);
        
        // Check if urgent based on reason or other indicators
        final isUrgent = apt.reason.toLowerCase().contains('urgent') ||
            apt.reason.toLowerCase().contains('emergency') ||
            apt.reason.toLowerCase().contains('stat');
        
        queueItems.add(_QueueItem(
          appointment: apt,
          patient: patient,
          waitTimeMinutes: waitTime,
          isUrgent: isUrgent,
        ));
      }
    }

    return _QueueData(
      queueItems: queueItems,
      totalWaiting: queueItems.length,
      averageWaitTime: queueItems.isEmpty
          ? 0
          : (queueItems.map((i) => i.waitTimeMinutes).reduce((a, b) => a + b) /
              queueItems.length).round(),
    );
  }

  int _calculateWaitTime(Appointment apt, DateTime now) {
    // If appointment time has passed, calculate wait time
    if (apt.appointmentDateTime.isBefore(now)) {
      return now.difference(apt.appointmentDateTime).inMinutes;
    }
    return 0;
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load queue',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueView(BuildContext context, _QueueData data, bool isDark) {
    if (data.queueItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.queue_rounded,
                size: 64,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No patients in queue',
                style: TextStyle(
                  fontSize: AppFontSize.titleMedium,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Patients will appear here when they check in',
                style: TextStyle(
                  fontSize: AppFontSize.bodyMedium,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Queue Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Queue',
                    style: TextStyle(
                      fontSize: AppFontSize.titleLarge,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.totalWaiting} waiting • Avg wait: ${data.averageWaitTime} min',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (widget.onCallNext != null)
                AppButton(
                  label: 'Call Next',
                  icon: Icons.volume_up_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onCallNext?.call();
                  },
                ),
            ],
          ),
        ),

        // Queue List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: data.queueItems.length,
            itemBuilder: (context, index) {
              final item = data.queueItems[index];
              return _buildQueueItem(context, item, index + 1, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    _QueueItem item,
    int position,
    bool isDark,
  ) {
    final patient = item.patient;
    final apt = item.appointment;
    final waitTime = item.waitTimeMinutes;
    final isOverdue = waitTime > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: item.isUrgent
              ? AppColors.error
              : isDark
                  ? AppColors.darkDivider
                  : Colors.grey.shade200,
          width: item.isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onPatientTap?.call(patient),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Position number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.isUrgent
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: TextStyle(
                        fontSize: AppFontSize.titleMedium,
                        fontWeight: FontWeight.w700,
                        color: item.isUrgent ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Patient info
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
                                fontSize: AppFontSize.bodyLarge,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'URGENT',
                                style: TextStyle(
                                  fontSize: AppFontSize.xs,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(apt.appointmentDateTime),
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${waitTime}m wait',
                                style: TextStyle(
                                  fontSize: AppFontSize.xs,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _QueueData {
  final List<_QueueItem> queueItems;
  final int totalWaiting;
  final int averageWaitTime;

  _QueueData({
    required this.queueItems,
    required this.totalWaiting,
    required this.averageWaitTime,
  });

  factory _QueueData.empty() {
    return _QueueData(
      queueItems: [],
      totalWaiting: 0,
      averageWaitTime: 0,
    );
  }
}

class _QueueItem {
  final Appointment appointment;
  final Patient patient;
  final int waitTimeMinutes;
  final bool isUrgent;

  _QueueItem({
    required this.appointment,
    required this.patient,
    required this.waitTimeMinutes,
    required this.isUrgent,
  });
}

