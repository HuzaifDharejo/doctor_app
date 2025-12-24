import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/components/app_button.dart';
import '../../services/patient_status_service.dart';
import 'patient_status_badge.dart';
import '../screens/workflow_wizard_screen.dart';
import '../screens/follow_ups_screen.dart';
import '../screens/patient_view/patient_view_screen.dart';

/// Enhanced Today's Agenda Widget
/// Shows prioritized view of today's tasks with one-tap actions
class TodaysAgendaWidget extends ConsumerWidget {
  const TodaysAgendaWidget({
    super.key,
    required this.todayAppointments,
    required this.overdueFollowUps,
    required this.checkedInAppts,
    required this.pendingAppts,
    required this.inProgressAppt,
  });

  final List<Appointment> todayAppointments;
  final List<ScheduledFollowUp> overdueFollowUps;
  final List<Appointment> checkedInAppts;
  final List<Appointment> pendingAppts;
  final List<Appointment> inProgressAppt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => _buildAgenda(context, ref, db, isDark),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAgenda(BuildContext context, WidgetRef ref, DoctorDatabase db, bool isDark) {
    return FutureBuilder<_AgendaData>(
      future: _loadAgendaData(ref, db),
      builder: (context, snapshot) {
        // Handle error state - return empty to prevent breaking UI
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final agendaData = snapshot.data!;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_view_day_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Agenda",
                            style: TextStyle(
                              fontSize: AppFontSize.xl,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getAgendaSummary(agendaData),
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Next Patients Section
              if (agendaData.nextPatients.isNotEmpty) ...[
                _buildSectionHeader('Next Patients', agendaData.nextPatients.length, isDark),
                ...agendaData.nextPatients.take(3).map((item) => _buildPatientItem(
                      context,
                      db,
                      item.patient,
                      item.appointment,
                      item.waitTime,
                      isDark,
                    )),
              ],

              // Urgent Items Section
              if (agendaData.urgentItems.isNotEmpty) ...[
                if (agendaData.nextPatients.isNotEmpty)
                  Divider(
                    height: 32,
                    thickness: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                _buildSectionHeader(
                  'Urgent Items',
                  agendaData.urgentItems.length,
                  isDark,
                  color: AppColors.error,
                ),
                ...agendaData.urgentItems.map((item) => _buildUrgentItem(
                      context,
                      item,
                      isDark,
                    )),
              ],

              // Overdue Tasks Section
              if (agendaData.overdueTasks.isNotEmpty) ...[
                if (agendaData.nextPatients.isNotEmpty || agendaData.urgentItems.isNotEmpty)
                  Divider(
                    height: 32,
                    thickness: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                _buildSectionHeader(
                  'Overdue Tasks',
                  agendaData.overdueTasks.length,
                  isDark,
                  color: AppColors.warning,
                ),
                ...agendaData.overdueTasks.map((item) => _buildTaskItem(
                      context,
                      item,
                      isDark,
                    )),
              ],

              // Empty State
              if (agendaData.nextPatients.isEmpty &&
                  agendaData.urgentItems.isEmpty &&
                  agendaData.overdueTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments scheduled today',
                          style: TextStyle(
                            fontSize: AppFontSize.md,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<_AgendaData> _loadAgendaData(WidgetRef ref, DoctorDatabase db) async {
    final now = DateTime.now();

    // Get next patients (checked in first, then pending, sorted by time)
    final nextPatients = <_PatientAgendaItem>[];
    
    // Prioritize: In Progress > Checked In > Pending/Scheduled
    final priorityAppts = [
      ...inProgressAppt,
      ...checkedInAppts,
      ...pendingAppts,
    ]..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));

    for (final appt in priorityAppts.take(3)) {
      final patient = await db.getPatientById(appt.patientId);
      if (patient != null) {
        final waitTime = now.difference(appt.appointmentDateTime).inMinutes;
        nextPatients.add(_PatientAgendaItem(
          patient: patient,
          appointment: appt,
          waitTime: waitTime,
        ));
      }
    }

    // Get urgent items (overdue follow-ups)
    final urgentItems = <_UrgentItem>[];
    for (final followUp in overdueFollowUps.take(5)) {
      final patient = await db.getPatientById(followUp.patientId);
      if (patient != null) {
        final daysOverdue =
            now.difference(followUp.scheduledDate).inDays;
        urgentItems.add(_UrgentItem(
          type: 'follow_up',
          title: 'Overdue Follow-up',
          subtitle: '${patient.firstName} ${patient.lastName}',
          daysOverdue: daysOverdue,
          followUp: followUp,
          patient: patient,
        ));
      }
    }

    // Get overdue tasks (lab results pending review, etc.)
    final overdueTasks = <_TaskItem>[];
    
    // Add overdue follow-ups as tasks
    for (final followUp in overdueFollowUps.skip(5).take(5)) {
      final patient = await db.getPatientById(followUp.patientId);
      if (patient != null) {
        overdueTasks.add(_TaskItem(
          type: 'follow_up',
          title: 'Overdue Follow-up',
          subtitle: '${patient.firstName} ${patient.lastName}',
          followUp: followUp,
          patient: patient,
        ));
      }
    }

    return _AgendaData(
      nextPatients: nextPatients,
      urgentItems: urgentItems,
      overdueTasks: overdueTasks,
    );
  }

  String _getAgendaSummary(_AgendaData data) {
    final parts = <String>[];
    if (data.nextPatients.isNotEmpty) {
      parts.add('${data.nextPatients.length} patient${data.nextPatients.length > 1 ? 's' : ''}');
    }
    if (data.urgentItems.isNotEmpty) {
      parts.add('${data.urgentItems.length} urgent');
    }
    if (data.overdueTasks.isNotEmpty) {
      parts.add('${data.overdueTasks.length} overdue');
    }
    return parts.isEmpty ? 'No items scheduled' : parts.join(' • ');
  }

  Widget _buildSectionHeader(String title, int count, bool isDark, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.lg,
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(
    BuildContext context,
    DoctorDatabase db,
    Patient patient,
    Appointment appointment,
    int waitTimeMinutes,
    bool isDark,
  ) {
    final timeFormat = DateFormat('h:mm a');
    final isOverdue = waitTimeMinutes > 0;
    final status = appointment.status;

    return InkWell(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PatientViewScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : (status == 'checked_in' || status == 'in_progress'
                  ? AppColors.quickActionGreen.withValues(alpha: 0.05)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == 'checked_in' || status == 'in_progress'
                ? AppColors.quickActionGreen.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkDivider : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Patient Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                patient.firstName.isNotEmpty
                    ? patient.firstName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${patient.firstName} ${patient.lastName}',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(appointment.appointmentDateTime),
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${waitTimeMinutes}m wait',
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
                  // Patient Status Badges
                  FutureBuilder<List<PatientStatus>>(
                    future: PatientStatusService(db: db).getPatientStatuses(
                      patient: patient,
                      appointment: appointment,
                    ),
                    builder: (context, statusSnapshot) {
                      if (!statusSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final statuses = statusSnapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: PatientStatusBadges(
                          statuses: statuses,
                          size: BadgeSize.small,
                          maxBadges: 2,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Action Button
            AppButton.primary(
              label: status == 'checked_in' || status == 'in_progress'
                  ? 'Continue'
                  : 'Start',
              icon: Icons.play_arrow_rounded,
              size: AppButtonSize.small,
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WorkflowWizardScreen(
                      existingPatient: patient,
                      existingAppointment: appointment,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentItem(BuildContext context, _UrgentItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.subtitle} • ${item.daysOverdue} day${item.daysOverdue > 1 ? 's' : ''} overdue',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            color: AppColors.error,
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const FollowUpsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, _TaskItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            color: AppColors.warning,
            onPressed: () {
              if (item.type == 'follow_up') {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FollowUpsScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AgendaData {
  const _AgendaData({
    required this.nextPatients,
    required this.urgentItems,
    required this.overdueTasks,
  });

  final List<_PatientAgendaItem> nextPatients;
  final List<_UrgentItem> urgentItems;
  final List<_TaskItem> overdueTasks;
}

class _PatientAgendaItem {
  const _PatientAgendaItem({
    required this.patient,
    required this.appointment,
    required this.waitTime,
  });

  final Patient patient;
  final Appointment appointment;
  final int waitTime;
}

class _UrgentItem {
  const _UrgentItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.daysOverdue,
    this.followUp,
    this.patient,
  });

  final String type;
  final String title;
  final String subtitle;
  final int daysOverdue;
  final ScheduledFollowUp? followUp;
  final Patient? patient;
}

class _TaskItem {
  const _TaskItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.followUp,
    this.patient,
  });

  final String type;
  final String title;
  final String subtitle;
  final ScheduledFollowUp? followUp;
  final Patient? patient;
}

