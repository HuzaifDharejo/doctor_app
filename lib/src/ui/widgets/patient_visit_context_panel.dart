import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/components/app_button.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import '../screens/add_appointment_screen.dart';
import '../screens/vital_signs_screen.dart';
import '../screens/workflow_wizard_screen.dart';
import '../screens/encounter_screen.dart';

/// Patient Visit Context Panel
/// Shows today's visit information and quick actions
class PatientVisitContextPanel extends ConsumerWidget {
  const PatientVisitContextPanel({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => _buildPanel(context, ref, db, isDark),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPanel(BuildContext context, WidgetRef ref, DoctorDatabase db, bool isDark) {
    return FutureBuilder<_VisitContext>(
      future: _loadVisitContext(ref, db),
      builder: (context, snapshot) {
        // Handle error state - return empty to prevent breaking UI
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final visitContext = snapshot.data!;
        if (visitContext.todayAppointment == null && visitContext.currentEncounter == null) {
          // No visit today, show quick start option
          return _buildNoVisitPanel(context, ref, isDark);
        }

        return _buildVisitPanel(context, ref, visitContext, isDark);
      },
    );
  }

  Future<_VisitContext> _loadVisitContext(WidgetRef ref, DoctorDatabase db) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get today's appointments using the existing helper method with timeout
    final allTodayAppointments = await db.getAppointmentsForDay(today)
        .timeout(const Duration(seconds: 10), onTimeout: () => <Appointment>[]);
    final appointments = allTodayAppointments.where((a) => a.patientId == patient.id).toList()
      ..sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

    Appointment? todayAppointment;
    if (appointments.isNotEmpty) {
      todayAppointment = appointments.first;
    }

    // Get current encounter (in progress)
    Encounter? currentEncounter;
    if (todayAppointment != null) {
      final allEncounters = await db.getEncountersForPatient(patient.id);
      final todayEncounters = allEncounters.where((e) => 
        e.encounterDate.year == today.year &&
        e.encounterDate.month == today.month &&
        e.encounterDate.day == today.day &&
        e.status == 'in_progress'
      ).toList();
      
      if (todayEncounters.isNotEmpty) {
        todayEncounters.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
        currentEncounter = todayEncounters.first;
      }
    }

    // Get latest vitals
    final vitals = await db.getVitalSignsForPatient(patient.id);
    VitalSign? latestVitals;
    if (vitals.isNotEmpty) {
      latestVitals = vitals.first;
    }

    // Get allergies
    final allergies = await db.getAllergiesForPatient(patient.id);

    return _VisitContext(
      todayAppointment: todayAppointment,
      currentEncounter: currentEncounter,
      latestVitals: latestVitals,
      allergies: allergies,
    );
  }

  Widget _buildNoVisitPanel(BuildContext context, WidgetRef ref, bool isDark) {
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? AppSpacing.xl : AppSpacing.xxl;
    final iconSize = isCompact ? 28.0 : 32.0;
    final titleSize = isCompact ? AppFontSize.xl : AppFontSize.displaySmall;
    final subtitleSize = isCompact ? AppFontSize.md : AppFontSize.lg;
    
    return Container(
      margin: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: AppColors.primary,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isCompact ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No Visit Today',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 4 : 6),
                    Text(
                      'Start a new consultation',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 24),
          SizedBox(
            height: isCompact ? 48 : 52,
            child: Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    label: 'Start Visit',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkflowWizardScreen(
                            existingPatient: patient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: AppButton.secondary(
                    label: 'Schedule',
                    icon: Icons.calendar_today_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddAppointmentScreen(
                            preselectedPatient: patient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitPanel(
    BuildContext context,
    WidgetRef ref,
    _VisitContext visitContext,
    bool isDark,
  ) {
    final appointment = visitContext.todayAppointment!;
    final encounter = visitContext.currentEncounter;
    final appointmentTime = DateFormat('h:mm a').format(appointment.appointmentDateTime);
    final status = encounter != null ? 'In Progress' : _getAppointmentStatus(appointment.status);
    
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? AppSpacing.xl : AppSpacing.xxl;
    final iconSize = isCompact ? 28.0 : 32.0;
    final titleSize = isCompact ? AppFontSize.xl : AppFontSize.displaySmall;
    final subtitleSize = isCompact ? AppFontSize.md : AppFontSize.lg;

    return Container(
      margin: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isCompact ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's Visit",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 4 : 6),
                    Text(
                      '$appointmentTime • $status',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 12,
                    vertical: isCompact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? AppFontSize.sm : subtitleSize * 0.85,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 24),

          // Allergy Warning
          if (visitContext.allergies.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isCompact ? 14 : 16),
              margin: EdgeInsets.only(bottom: isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: isCompact ? 28 : 32,
                  ),
                  SizedBox(width: isCompact ? 14 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Allergy Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: isCompact ? AppFontSize.md : AppFontSize.lg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Text(
                          visitContext.allergies.map((a) => a.allergen).join(', '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: isCompact ? AppFontSize.sm : AppFontSize.md,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Actions
          SizedBox(
            height: isCompact ? 48 : 52,
            child: Row(
              children: [
              if (encounter == null)
                Expanded(
                  child: AppButton.secondary(
                    label: 'Start Consultation',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      // Navigate to workflow wizard for new encounter
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkflowWizardScreen(
                            existingPatient: patient,
                            existingAppointment: appointment,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: AppButton.secondary(
                    label: 'Continue Visit',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      // Navigate to encounter screen with encounter ID
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EncounterScreen(
                            encounterId: encounter!.id!,
                            patient: patient,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: AppButton.secondary(
                    label: visitContext.latestVitals != null ? 'Update Vitals' : 'Add Vitals',
                    icon: Icons.monitor_heart_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VitalSignsScreen(
                            patientId: patient.id,
                            patientName: '${patient.firstName} ${patient.lastName}'.trim(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppointmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'checked_in':
        return 'Checked In';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class _VisitContext {
  const _VisitContext({
    this.todayAppointment,
    this.currentEncounter,
    this.latestVitals,
    this.allergies = const [],
  });

  final Appointment? todayAppointment;
  final Encounter? currentEncounter;
  final VitalSign? latestVitals;
    final List<PatientAllergy> allergies;
}

