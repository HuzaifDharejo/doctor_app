import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/date_time_picker.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/app_card.dart';
import '../../core/components/app_button.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/quick_checkin_dialog.dart';
import 'add_appointment_screen.dart';
import 'edit_appointment_screen.dart';
import 'workflow_wizard_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  
  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = context.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildModernSliverAppBar(context, isDark),
          SliverToBoxAdapter(
            child: AnimatedCrossFade(
              firstChild: _buildDateSelector(context),
              secondChild: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isCompact ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.xs,
                ),
                child: CalendarWidget(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
              crossFadeState: _showCalendar 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: AppDuration.normal,
            ),
          ),
          dbAsync.when(
            data: (db) => _buildAppointmentsSliverList(context, db),
            loading: () => const SliverFillRemaining(
              child: LoadingState(),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: ErrorState.generic(
                message: err.toString(),
                onRetry: () => ref.invalidate(doctorDbProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddAppointment(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Appointment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: _showCalendar 
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      )
                    : null,
                color: _showCalendar ? null : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showCalendar ? Icons.view_week_rounded : Icons.calendar_month_rounded,
                    color: _showCalendar ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showCalendar ? 'Week' : 'Month',
                    style: TextStyle(
                      color: _showCalendar ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.6) 
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddAppointment(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AddAppointmentScreen(initialDate: _selectedDate),
      ),
    );
    if (result ?? false) {
      setState(() {}); // Refresh the list
    }
  }

  Widget _buildDateSelector(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i - 1)));
    final isDark = context.isDarkMode;
    final isCompact = context.isCompact;
    
    return Container(
      height: isCompact ? 100 : 115,
      margin: EdgeInsets.symmetric(vertical: isCompact ? AppSpacing.sm : AppSpacing.lg),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.sm : AppSpacing.lg),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              width: isCompact ? 56 : 68,
              margin: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.xxs : AppSpacing.xs),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isToday 
                            ? const Color(0xFF10B981)
                            : (isDark ? AppColors.darkDivider : AppColors.divider),
                        width: isToday ? 2 : 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : AppShadow.small,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: isCompact ? AppFontSize.xxs : AppFontSize.xxs,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.85) 
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.xs),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: isCompact ? AppFontSize.xl : AppFontSize.xxl,
                      fontWeight: FontWeight.w800,
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (isToday)
                    Container(
                      width: isSelected ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsSliverList(BuildContext context, DoctorDatabase db) {
    return FutureBuilder<List<Appointment>>(
      future: db.getAppointmentsForDay(_selectedDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            child: LoadingState(),
          );
        }
        
        final appointments = snapshot.data!;
        
        if (appointments.isEmpty) {
          return SliverFillRemaining(
            child: _buildModernEmptyState(context),
          );
        }
        
        final isCompact = context.isCompact;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.md : AppSpacing.xl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildAppointmentCard(context, db, appointments[index]),
                );
              },
              childCount: appointments.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    final isDark = context.isDarkMode;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 64,
                color: const Color(0xFF10B981).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No appointments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your schedule is clear for ${DateFormat('MMMM d').format(_selectedDate)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _navigateToAddAppointment(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Schedule Appointment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, DoctorDatabase db, Appointment appt) {
    final time = DateFormat('h:mm a').format(appt.appointmentDateTime);
    final statusColor = _getStatusColor(appt.status);
    final isDark = context.isDarkMode;
    final isCompact = context.isCompact;
    final isUpcoming = appt.appointmentDateTime.isAfter(DateTime.now());
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(appt.patientId),
      builder: (context, patientSnapshot) {
        final patient = patientSnapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}'
            : 'Patient #${appt.patientId}';
    
        return Dismissible(
          key: Key('appt_${appt.id}'),
          direction: isUpcoming ? DismissDirection.horizontal : DismissDirection.none,
          background: Container(
            margin: EdgeInsets.only(bottom: isCompact ? AppSpacing.sm : AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text(
                  'Confirm',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            margin: EdgeInsets.only(bottom: isCompact ? AppSpacing.sm : AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.cancel, color: AppColors.error, size: 28),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            unawaited(HapticFeedback.mediumImpact());
            if (direction == DismissDirection.startToEnd) {
              // Confirm appointment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment confirmed'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              // Cancel appointment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appointment cancelled'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return false; // Don't actually dismiss
          },
          child: AppCard(
            margin: EdgeInsets.only(bottom: isCompact ? AppSpacing.sm : AppSpacing.lg),
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderColor: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
            borderWidth: 1,
            boxShadow: [
              BoxShadow(
                color: AppColors.appointments.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            onTap: () => _showAppointmentDetails(context, appt, patient),
            child: Column(
                  children: [
                    Row(
                      children: [
                        // Time indicator with gradient
                        Container(
                          width: isCompact ? 75 : 90,
                          padding: EdgeInsets.symmetric(vertical: isCompact ? AppSpacing.xl : AppSpacing.xxl),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.appointments,
                                AppColors.appointments.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppRadius.xl),
                              bottomLeft: Radius.circular(AppRadius.xl),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                time.split(' ')[0],
                                style: TextStyle(
                                  fontSize: isCompact ? AppFontSize.lg : AppFontSize.xl,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                time.split(' ')[1],
                                style: TextStyle(
                                  fontSize: isCompact ? AppFontSize.xxs : AppFontSize.xs,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  '${appt.durationMinutes}m',
                                  style: TextStyle(
                                    fontSize: AppFontSize.xxs,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                
                        // Appointment details
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        patientName,
                                        style: TextStyle(
                                          fontSize: isCompact ? AppFontSize.sm : AppFontSize.md,
                                          fontWeight: FontWeight.w700,
                                          color: context.colorScheme.onSurface,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            statusColor.withValues(alpha: 0.2),
                                            statusColor.withValues(alpha: 0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        appt.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: AppFontSize.xxs,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.prescriptions.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.prescriptions),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        appt.reason.isNotEmpty ? appt.reason : 'General Checkup',
                                        style: TextStyle(
                                          fontSize: isCompact ? AppFontSize.xxs : AppFontSize.xs,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Quick action buttons
                    if (patient != null && isUpcoming)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppRadius.xl),
                            bottomRight: Radius.circular(AppRadius.xl),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            if (patient.phone.isNotEmpty) ...[
                              _buildQuickAction(
                                context,
                                icon: Icons.phone_rounded,
                                label: 'Call',
                                color: AppColors.success,
                                onTap: () => _callPatient(patient.phone),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildQuickAction(
                                context,
                                icon: Icons.message_rounded,
                                label: 'SMS',
                                color: AppColors.info,
                                onTap: () => _messagePatient(patient.phone),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            _buildQuickAction(
                              context,
                              icon: Icons.edit_calendar_rounded,
                              label: 'Reschedule',
                              color: AppColors.warning,
                              onTap: () => _showRescheduleDialog(context, db, appt),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildQuickAction(
                              context,
                              icon: Icons.how_to_reg_rounded,
                              label: 'Check-In',
                              color: const Color(0xFF10B981),
                              onTap: () => _quickCheckIn(context, db, appt, patient),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildQuickAction(
                              context,
                              icon: Icons.play_circle_rounded,
                              label: 'Start',
                              color: const Color(0xFF059669),
                              onTap: () => _startConsultation(context, db, appt, patient),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          ),
        );
      },
    );
  }
  
  void _startConsultation(BuildContext context, DoctorDatabase db, Appointment appt, Patient? patient) async {
    if (patient == null) return;
    
    HapticFeedback.mediumImpact();
    
    // Update appointment status to in_progress
    await db.updateAppointmentStatus(appt.id, 'in_progress');
    
    // Navigate to workflow wizard with the patient and appointment
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkflowWizardScreen(
            existingPatient: patient,
            existingAppointment: appt,
          ),
        ),
      );
    }
  }
  
  /// Quick check-in for appointment with auto-encounter option
  Future<void> _quickCheckIn(BuildContext context, DoctorDatabase db, Appointment appt, Patient? patient) async {
    if (patient == null) return;
    
    HapticFeedback.mediumImpact();
    
    final result = await showQuickCheckInDialog(context, db, appt, patient);
    if (result != null && result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '${patient.firstName} checked in'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // Refresh appointments list
    }
  }
  
  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _callPatient(String phone) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
  
  Future<void> _messagePatient(String phone) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _showRescheduleDialog(BuildContext context, DoctorDatabase db, Appointment appt) async {
    HapticFeedback.lightImpact();
    DateTime selectedDate = appt.appointmentDateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(appt.appointmentDateTime);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reschedule Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${DateFormat('EEE, MMM d').format(appt.appointmentDateTime)} at ${DateFormat('h:mm a').format(appt.appointmentDateTime)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                AppDateTimePicker(
                  label: 'New Date & Time',
                  initialDate: selectedDate,
                  initialTime: selectedTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  showDatePresets: true,
                  showTimePresets: true,
                  onDateSelected: (date) {
                    setDialogState(() => selectedDate = date);
                  },
                  onTimeSelected: (time) {
                    setDialogState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      
      // Update the appointment with all existing data plus new datetime and status
      await db.updateAppointment(AppointmentsCompanion(
        id: Value(appt.id),
        patientId: Value(appt.patientId),
        appointmentDateTime: Value(newDateTime),
        durationMinutes: Value(appt.durationMinutes),
        reason: Value(appt.reason),
        status: const Value('rescheduled'),
        notes: Value(appt.notes),
        reminderAt: Value(appt.reminderAt),
        medicalRecordId: Value(appt.medicalRecordId),
      ));
      
      // Trigger a rebuild to refresh the appointments list
      setState(() {
        // Update selected date to show the rescheduled appointment
        _selectedDate = newDateTime;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment rescheduled to ${DateFormat('EEE, MMM d').format(newDateTime)} at ${DateFormat('h:mm a').format(newDateTime)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAppointmentDetails(BuildContext context, Appointment appointment, Patient? patient) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUpcoming = appointment.appointmentDateTime.isAfter(DateTime.now());
    final isPast = appointment.appointmentDateTime.isBefore(DateTime.now());
    final db = ref.read(doctorDbProvider).value;

    Color statusColor;
    IconData statusIcon;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
      case 'no-show':
        statusColor = AppColors.warning;
        statusIcon = Icons.person_off;
      case 'confirmed':
        statusColor = AppColors.primary;
        statusIcon = Icons.verified;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.schedule;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isUpcoming ? AppColors.primary : statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Patient info
                      if (patient != null)
                        Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                patient.firstName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${patient.firstName} ${patient.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                if (patient.phone.isNotEmpty)
                                  Text(
                                    patient.phone,
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Date & Time Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.1),
                            (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.calendar_month, color: isUpcoming ? AppColors.primary : statusColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(appointment.appointmentDateTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.access_time, color: isUpcoming ? AppColors.primary : statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          timeFormat.format(appointment.appointmentDateTime),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.timer_outlined, color: isUpcoming ? AppColors.primary : statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Duration',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${appointment.durationMinutes} min',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reason for visit
                    if (appointment.reason.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.medical_services_outlined, size: 18, color: AppColors.accent),
                                SizedBox(width: 8),
                                Text(
                                  'Reason for Visit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              appointment.reason,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (appointment.reason.isNotEmpty) const SizedBox(height: 16),
                    // Notes
                    if (appointment.notes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.note_alt_outlined, size: 18, color: AppColors.info),
                                SizedBox(width: 8),
                                Text(
                                  'Notes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              appointment.notes,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Action buttons
                    if (isUpcoming && appointment.status.toLowerCase() != 'cancelled' && patient != null && db != null) ...[
                      // Complete Visit button for in_progress appointments
                      if (appointment.status.toLowerCase() == 'in_progress') ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await db!.updateAppointmentStatus(appointment.id, 'completed');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Visit completed for ${patient.firstName} ${patient.lastName}'),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 22),
                            label: const Text('Complete Visit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Start Consultation button - prominent for doctors
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _startConsultation(context, db!, appointment, patient);
                            },
                            icon: const Icon(Icons.play_circle_rounded, size: 22),
                            label: const Text('Start Consultation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.tertiary(
                              label: 'Edit',
                              icon: Icons.edit,
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAppointmentScreen(
                                      appointment: appointment,
                                      patient: patient,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton.danger(
                              label: 'Cancel',
                              icon: Icons.cancel_outlined,
                              onPressed: () {
                                Navigator.pop(context);
                                _showCancelConfirmation(context, appointment, patient);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isPast && appointment.status.toLowerCase() != 'completed' && patient != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.tertiary(
                              label: 'Edit',
                              icon: Icons.edit,
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAppointmentScreen(
                                      appointment: appointment,
                                      patient: patient,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Complete',
                              icon: Icons.check,
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              onPressed: () {
                                Navigator.pop(context);
                                _markAsCompleted(context, appointment);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isPast && appointment.status.toLowerCase() == 'completed' && patient != null)
                      AppButton.tertiary(
                        label: 'Edit',
                        icon: Icons.edit,
                        fullWidth: true,
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAppointmentScreen(
                                appointment: appointment,
                                patient: patient,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                    // Delete button - always available
                    AppButton.danger(
                      label: 'Delete Appointment',
                      icon: Icons.delete_outline,
                      fullWidth: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteAppointmentConfirmation(context, appointment, patient);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmation(BuildContext parentContext, Appointment appointment, Patient? patient) async {
    final patientName = patient != null ? '${patient.firstName} ${patient.lastName}' : 'this patient';
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel the appointment with $patientName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        final updatedAppointment = AppointmentsCompanion(
          id: Value(appointment.id),
          patientId: Value(appointment.patientId),
          appointmentDateTime: Value(appointment.appointmentDateTime),
          durationMinutes: Value(appointment.durationMinutes),
          reason: Value(appointment.reason),
          status: const Value('cancelled'),
          notes: Value(appointment.notes),
          reminderAt: Value(appointment.reminderAt),
          medicalRecordId: Value(appointment.medicalRecordId),
          createdAt: Value(appointment.createdAt),
        );
        await db.updateAppointment(updatedAppointment);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel appointment: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsCompleted(BuildContext parentContext, Appointment appointment) async {
    try {
      final db = await ref.read(doctorDbProvider.future);
      final updatedAppointment = AppointmentsCompanion(
        id: Value(appointment.id),
        patientId: Value(appointment.patientId),
        appointmentDateTime: Value(appointment.appointmentDateTime),
        durationMinutes: Value(appointment.durationMinutes),
        reason: Value(appointment.reason),
        status: const Value('completed'),
        notes: Value(appointment.notes),
        reminderAt: Value(appointment.reminderAt),
        medicalRecordId: Value(appointment.medicalRecordId),
        createdAt: Value(appointment.createdAt),
      );
      await db.updateAppointment(updatedAppointment);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Appointment marked as completed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Failed to update appointment: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAppointmentConfirmation(BuildContext parentContext, Appointment appointment, Patient? patient) async {
    final patientName = patient != null ? '${patient.firstName} ${patient.lastName}' : 'this patient';
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Appointment'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete the appointment with $patientName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        await db.deleteAppointment(appointment.id);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(
              content: Text('Appointment deleted successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Failed to delete appointment: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

}

