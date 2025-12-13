import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/patient_picker_dialog.dart';
import '../widgets/quick_vitals_dialog.dart';
import '../widgets/quick_note_dialog.dart';
import '../widgets/quick_checkin_dialog.dart';
import '../widgets/wait_time_stats.dart';
import 'add_appointment_screen.dart';
import 'add_patient_screen.dart';
import 'add_prescription_screen.dart';
import 'follow_ups_screen.dart';
import 'patients_screen.dart';
import 'notifications_screen.dart';
import 'workflow_wizard_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  
  const DashboardScreen({super.key, this.onMenuTap});
  final VoidCallback? onMenuTap;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    ref.invalidate(doctorDbProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    
    return Scaffold(
      body: SafeArea(
        child: dbAsync.when(
          data: (db) => _buildDashboard(context, db),
          loading: () => const LoadingState(),
          error: (err, stack) => ErrorState.generic(
            message: err.toString(),
            onRetry: () => ref.invalidate(doctorDbProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DoctorDatabase db) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDashboardData(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingState();
        }
        final data = snapshot.data!;
        return _buildContent(context, db, data);
      },
    );
  }

  Future<Map<String, dynamic>> _loadDashboardData(DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    final todayAppointments = await db.getAppointmentsForDay(DateTime.now());
    final overdueFollowUps = await db.getOverdueFollowUps();
    final pendingFollowUps = await db.getPendingFollowUps();
    final allInvoices = await db.getAllInvoices();
    
    // Calculate wait time statistics
    final waitTimeStats = await calculateWaitTimeStats(db);
    
    // Calculate statistics
    final pendingAppts = todayAppointments.where((a) => 
        a.status == 'pending' || a.status == 'scheduled').toList();
    final checkedInAppts = todayAppointments.where((a) => 
        a.status == 'checked_in').toList();
    final completedToday = todayAppointments.where((a) => 
        a.status == 'completed').length;
    final inProgressAppt = todayAppointments.where((a) => 
        a.status == 'in_progress').toList();
    
    // Calculate today's revenue
    final today = DateTime.now();
    final todayRevenue = allInvoices
        .where((inv) => 
            inv.invoiceDate.year == today.year &&
            inv.invoiceDate.month == today.month &&
            inv.invoiceDate.day == today.day &&
            inv.paymentStatus == 'Paid')
        .fold<double>(0, (sum, inv) => sum + inv.grandTotal);
    
    // Pending payments
    final pendingPayments = allInvoices
        .where((inv) => inv.paymentStatus != 'Paid')
        .fold<double>(0, (sum, inv) => sum + inv.grandTotal);
    
    // Recent patients (last 5 seen)
    final recentPatients = patients.take(5).toList();
    
    // Get upcoming follow-ups for next 7 days
    final upcomingFollowUps = pendingFollowUps
        .where((f) => f.scheduledDate.difference(DateTime.now()).inDays <= 7)
        .take(5)
        .toList();
    
    return {
      'patients': patients,
      'todayAppointments': todayAppointments,
      'pendingAppts': pendingAppts,
      'checkedInAppts': checkedInAppts,
      'completedToday': completedToday,
      'inProgressAppt': inProgressAppt,
      'overdueFollowUps': overdueFollowUps,
      'upcomingFollowUps': upcomingFollowUps,
      'todayRevenue': todayRevenue,
      'pendingPayments': pendingPayments,
      'recentPatients': recentPatients,
      'waitTimeStats': waitTimeStats,
    };
  }

  Widget _buildContent(BuildContext context, DoctorDatabase db, Map<String, dynamic> data) {
    final todayAppointments = data['todayAppointments'] as List<Appointment>;
    final pendingAppts = data['pendingAppts'] as List<Appointment>;
    final checkedInAppts = data['checkedInAppts'] as List<Appointment>;
    final completedToday = data['completedToday'] as int;
    final inProgressAppt = data['inProgressAppt'] as List<Appointment>;
    final overdueFollowUps = data['overdueFollowUps'] as List<ScheduledFollowUp>;
    final upcomingFollowUps = data['upcomingFollowUps'] as List<ScheduledFollowUp>;
    final todayRevenue = data['todayRevenue'] as double;
    final pendingPayments = data['pendingPayments'] as double;
    final recentPatients = data['recentPatients'] as List<Patient>;
    final waitTimeStats = data['waitTimeStats'] as WaitTimeStats;
    
    final isDark = context.isDarkMode;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = AppBreakpoint.isCompact(constraints.maxWidth);
        final isShort = context.isShortScreen;
        final padding = isCompact 
            ? (isShort ? 12.0 : 16.0) 
            : 24.0;
        final sectionSpacing = isCompact 
            ? (isShort ? 12.0 : 16.0) 
            : 20.0;
        
        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          displacement: 20,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Doctor Header with Greeting
              SliverToBoxAdapter(
                child: _buildDoctorHeader(context, isCompact, isShort: isShort),
              ),
              
              // Critical Alerts Banner (if any)
              if (overdueFollowUps.isNotEmpty || inProgressAppt.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildCriticalAlerts(
                      context,
                      overdueFollowUps.length, 
                      inProgressAppt.isNotEmpty,
                      isCompact, 
                      isDark,
                    ),
                  ),
                ),
              
              SliverToBoxAdapter(child: SizedBox(height: sectionSpacing)),
              
              // Today's Summary Cards
              SliverToBoxAdapter(
                child: _buildTodaySummaryCards(
                  context,
                  totalAppts: todayAppointments.length,
                  completedAppts: completedToday,
                  pendingAppts: pendingAppts.length,
                  overdueFollowUps: overdueFollowUps.length,
                  isCompact: isCompact,
                  isDark: isDark,
                  isShort: isShort,
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: sectionSpacing)),
              
              // Wait Time Statistics Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: WaitTimeCard(
                    stats: waitTimeStats,
                    isCompact: isCompact,
                    isDark: isDark,
                  ),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Current/Next Patient Card (Priority View)
              if (pendingAppts.isNotEmpty || checkedInAppts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildCurrentPatientCard(
                      context, 
                      db, 
                      [...checkedInAppts, ...pendingAppts], // Show checked-in first
                      isCompact, 
                      isDark,
                    ),
                  ),
                ),
              
              if (pendingAppts.isNotEmpty || checkedInAppts.isNotEmpty)
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Quick Clinical Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildQuickClinicalActions(context, db, isCompact, isDark),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Today's Patient Queue
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildPatientQueue(
                    context, 
                    db, 
                    todayAppointments, 
                    isCompact, 
                    isDark,
                  ),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Pending Tasks Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildPendingTasks(
                    context,
                    db,
                    overdueFollowUps: overdueFollowUps,
                    upcomingFollowUps: upcomingFollowUps,
                    isCompact: isCompact,
                    isDark: isDark,
                  ),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Revenue Summary (Collapsible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildRevenueSummary(
                    context,
                    todayRevenue: todayRevenue,
                    pendingPayments: pendingPayments,
                    isCompact: isCompact,
                    isDark: isDark,
                  ),
                ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 24)),
              
              // Recent Patients Quick Access
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildRecentPatientsSection(
                    context,
                    recentPatients,
                    isCompact,
                    isDark,
                  ),
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION 1: DOCTOR HEADER
  // ============================================================
  Widget _buildDoctorHeader(BuildContext context, bool isCompact, {bool isShort = false}) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final hour = DateTime.now().hour;
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');
    
    // Dynamic greeting based on time
    String greeting;
    IconData greetingIcon;
    Color greetingColor;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFFFBBF24);
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFFF97316);
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
      greetingColor = const Color(0xFF8B5CF6);
    }

    // Responsive sizes based on screen
    final headerPadding = isShort 
        ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
        : EdgeInsets.fromLTRB(
            isCompact ? 16 : 24, 
            isCompact ? 12 : 16, 
            isCompact ? 16 : 24, 
            isCompact ? 16 : 20,
          );
    final greetingSpacing = isShort ? 14.0 : (isCompact ? 20.0 : 28.0);
    final avatarRadius = isShort ? 20.0 : (isCompact ? 24.0 : 28.0);
    final nameSize = isShort ? 18.0 : (isCompact ? 22.0 : 26.0);
    
    return Container(
      padding: headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Menu, Date, Notifications
          Row(
            children: [
              // Menu Button
              GestureDetector(
                onTap: widget.onMenuTap,
                child: Container(
                  padding: EdgeInsets.all(isShort ? 8 : (isCompact ? 10 : 12)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.menu_rounded, color: AppColors.primary, size: isShort ? 18 : (isCompact ? 20 : 22)),
                ),
              ),
              const Spacer(),
              // Date Chip - hide on very short screens
              if (!isShort)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, 
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(now),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(width: isShort ? 6 : 10),
              // Notification Bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isShort ? 8 : (isCompact ? 10 : 12)),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.notifications_outlined, 
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: isShort ? 18 : (isCompact ? 20 : 22)),
                    ),
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkBackground : Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: greetingSpacing),
          // Greeting Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isShort ? 8 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [greetingColor.withValues(alpha: 0.2), greetingColor.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(isShort ? 12 : 16),
                ),
                child: Icon(greetingIcon, color: greetingColor, size: isShort ? 20 : (isCompact ? 24 : 28)),
              ),
              SizedBox(width: isShort ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                      style: TextStyle(
                        fontSize: isShort ? 11 : (isCompact ? 13 : 14),
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: isShort ? 1 : 2),
                    Text(
                      'Dr. ${profile.displayName}',
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Profile Avatar
              Container(
                padding: EdgeInsets.all(isShort ? 2 : 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: isShort ? 8 : 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: avatarRadius - 2,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile.initials,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isShort ? 12 : (isCompact ? 14 : 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 2: CRITICAL ALERTS BANNER
  // ============================================================
  Widget _buildCriticalAlerts(BuildContext context, int overdueCount, bool hasInProgress, bool isCompact, bool isDark) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withValues(alpha: 0.15),
            const Color(0xFFF97316).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention Required',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${overdueCount > 0 ? '$overdueCount overdue follow-ups' : ''}${overdueCount > 0 && hasInProgress ? ' • ' : ''}${hasInProgress ? 'Patient in progress' : ''}',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 3: TODAY'S SUMMARY CARDS
  // ============================================================
  Widget _buildTodaySummaryCards(
    BuildContext context, {
    required int totalAppts,
    required int completedAppts,
    required int pendingAppts,
    required int overdueFollowUps,
    required bool isCompact,
    required bool isDark,
    bool isShort = false,
  }) {
    final cardHeight = isShort ? 85.0 : (isCompact ? 100.0 : 110.0);
    final cardPadding = isShort ? 12.0 : (isCompact ? 16.0 : 24.0);
    
    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: cardPadding),
        children: [
          _buildMiniStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Today',
            value: '$totalAppts',
            subLabel: 'appointments',
            color: const Color(0xFF6366F1),
            isCompact: isCompact,
            isDark: isDark,
            isShort: isShort,
          ),
          SizedBox(width: isShort ? 8 : (isCompact ? 10 : 12)),
          _buildMiniStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '$completedAppts',
            subLabel: 'patients',
            color: const Color(0xFF10B981),
            isCompact: isCompact,
            isDark: isDark,
            isShort: isShort,
          ),
          SizedBox(width: isShort ? 8 : (isCompact ? 10 : 12)),
          _buildMiniStatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Waiting',
            value: '$pendingAppts',
            subLabel: 'in queue',
            color: const Color(0xFFF59E0B),
            isCompact: isCompact,
            isDark: isDark,
            isShort: isShort,
          ),
          SizedBox(width: isShort ? 8 : (isCompact ? 10 : 12)),
          _buildMiniStatCard(
            icon: Icons.event_busy_rounded,
            label: 'Overdue',
            value: '$overdueFollowUps',
            subLabel: 'follow-ups',
            color: const Color(0xFFEF4444),
            isCompact: isCompact,
            isDark: isDark,
            isShort: isShort,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subLabel,
    required Color color,
    required bool isCompact,
    required bool isDark,
    bool isShort = false,
  }) {
    final cardWidth = isShort ? 95.0 : (isCompact ? 110.0 : 125.0);
    final cardPadding = isShort ? 10.0 : (isCompact ? 12.0 : 14.0);
    final iconSize = isShort ? 16.0 : (isCompact ? 18.0 : 20.0);
    final valueSize = isShort ? 18.0 : (isCompact ? 20.0 : 24.0);
    final labelSize = isShort ? 10.0 : (isCompact ? 11.0 : 12.0);
    final subLabelSize = isShort ? 9.0 : (isCompact ? 10.0 : 11.0);
    
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(isShort ? 12 : 16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: isDark ? null : [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: iconSize),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: subLabelSize,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 4: CURRENT/NEXT PATIENT CARD
  // ============================================================
  Widget _buildCurrentPatientCard(
    BuildContext context, 
    DoctorDatabase db, 
    List<Appointment> pendingAppts, 
    bool isCompact, 
    bool isDark,
  ) {
    if (pendingAppts.isEmpty) return const SizedBox.shrink();
    
    final currentAppt = pendingAppts.first;
    final timeFormat = DateFormat('h:mm a');
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(currentAppt.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}' 
            : 'Patient #${currentAppt.patientId}';
        final age = patient?.age;        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NEXT PATIENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${pendingAppts.length} in queue',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Patient Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: isCompact ? 28 : 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            patient != null ? '${patient.firstName[0]}${patient.lastName[0]}' : 'P',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 18 : 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (age != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_outline, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$age yrs',
                                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeFormat.format(currentAppt.appointmentDateTime),
                                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reason for visit
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentAppt.reason.isNotEmpty ? currentAppt.reason : 'General Consultation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (patient != null) {
                              Navigator.pushNamed(context, '/patient/${patient.id}');
                            }
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: const Text('View Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Start consultation
                            if (patient != null) {
                              Navigator.pushNamed(context, '/patient/${patient.id}');
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTION 5: QUICK CLINICAL ACTIONS
  // ============================================================
  Widget _buildQuickClinicalActions(BuildContext context, DoctorDatabase db, bool isCompact, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isCompact ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        // Primary row
        Row(
          children: [
            Expanded(child: _buildActionTile(
              icon: Icons.play_circle_rounded,
              label: 'Start Visit',
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(context, AppRouter.route(const WorkflowWizardScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.medical_services_rounded,
              label: 'Clinical Visit',
              color: const Color(0xFFEC4899),
              onTap: () => _startNewEncounter(context, db),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.person_add_rounded,
              label: 'New Patient',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(context, AppRouter.route(const AddPatientScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.event_note_rounded,
              label: 'Appointment',
              color: const Color(0xFF14B8A6),
              onTap: () => Navigator.push(context, AppRouter.route(const AddAppointmentScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.medication_rounded,
              label: 'Prescribe',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, AppRouter.route(const AddPrescriptionScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
          ],
        ),
        SizedBox(height: isCompact ? 10 : 12),
        // Secondary row - Quick Vitals, Quick Note, Check-In
        Row(
          children: [
            Expanded(child: _buildActionTile(
              icon: Icons.how_to_reg_rounded,
              label: 'Check-In',
              color: const Color(0xFF10B981),
              onTap: () => _showQuickCheckIn(context, db),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.favorite_rounded,
              label: 'Quick Vitals',
              color: AppColors.error,
              onTap: () => _showQuickVitals(context, db),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.note_add_rounded,
              label: 'Quick Note',
              color: AppColors.info,
              onTap: () => _showQuickNote(context, db),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.repeat_rounded,
              label: 'Refill Rx',
              color: const Color(0xFF8B5CF6),
              onTap: () => _showRefillPrescription(context, db),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 12),
            Expanded(child: _buildActionTile(
              icon: Icons.schedule_rounded,
              label: 'Follow-ups',
              color: AppColors.warning,
              onTap: () => Navigator.push(context, AppRouter.route(const FollowUpsScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
          ],
        ),
        SizedBox(height: isCompact ? 10 : 12),
        // Third row - Patients access
        Row(
          children: [
            Expanded(child: _buildActionTile(
              icon: Icons.people_rounded,
              label: 'Patients',
              color: AppColors.patients,
              onTap: () => Navigator.push(context, AppRouter.route(const PatientsScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
          ],
        ),
      ],
    );
  }
  
  /// Show quick vitals dialog with patient picker
  Future<void> _showQuickVitals(BuildContext context, DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    if (!context.mounted) return;
    
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients found. Please add a patient first.')),
      );
      return;
    }
    
    final selectedPatient = await showDialog<Patient>(
      context: context,
      builder: (context) => PatientPickerDialog(
        patients: patients,
        title: 'Record Vitals',
        subtitle: 'Select patient to record vital signs',
        icon: Icons.favorite_rounded,
        iconColor: AppColors.error,
      ),
    );
    
    if (selectedPatient == null || !context.mounted) return;
    
    final result = await showQuickVitalsDialog(context, db, selectedPatient);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Vitals recorded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
  
  /// Show quick note dialog with patient picker
  Future<void> _showQuickNote(BuildContext context, DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    if (!context.mounted) return;
    
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients found. Please add a patient first.')),
      );
      return;
    }
    
    final selectedPatient = await showDialog<Patient>(
      context: context,
      builder: (context) => PatientPickerDialog(
        patients: patients,
        title: 'Add Note',
        subtitle: 'Select patient to add a clinical note',
        icon: Icons.note_add_rounded,
        iconColor: AppColors.info,
      ),
    );
    
    if (selectedPatient == null || !context.mounted) return;
    
    final result = await showQuickNoteDialog(context, db, selectedPatient);
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Note saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
  
  /// Show refill prescription dialog
  Future<void> _showRefillPrescription(BuildContext context, DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    if (!context.mounted) return;
    
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patients found. Please add a patient first.')),
      );
      return;
    }
    
    final selectedPatient = await showDialog<Patient>(
      context: context,
      builder: (context) => PatientPickerDialog(
        patients: patients,
        title: 'Refill Prescription',
        subtitle: 'Select patient for prescription refill',
        icon: Icons.repeat_rounded,
        iconColor: const Color(0xFF8B5CF6),
      ),
    );
    
    if (selectedPatient == null || !context.mounted) return;
    
    // Navigate to prescription screen with refill mode
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: selectedPatient),
      ),
    );
  }
  
  /// Show quick check-in dialog for scheduled appointments
  Future<void> _showQuickCheckIn(BuildContext context, DoctorDatabase db) async {
    // Get today's pending appointments
    final todayAppts = await db.getAppointmentsForDay(DateTime.now());
    final pendingAppts = todayAppts.where((a) => 
        a.status == 'scheduled' || a.status == 'pending'
    ).toList();
    
    if (!context.mounted) return;
    
    if (pendingAppts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending appointments to check in.')),
      );
      return;
    }
    
    // Build a list of patients for pending appointments
    final patientsWithAppts = <Map<String, dynamic>>[];
    for (final appt in pendingAppts) {
      final patient = await db.getPatientById(appt.patientId);
      if (patient != null) {
        patientsWithAppts.add({
          'patient': patient,
          'appointment': appt,
        });
      }
    }
    
    if (!context.mounted || patientsWithAppts.isEmpty) return;
    
    // Show appointment picker
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AppointmentPickerDialog(
        appointments: patientsWithAppts,
      ),
    );
    
    if (selected == null || !context.mounted) return;
    
    final patient = selected['patient'] as Patient;
    final appointment = selected['appointment'] as Appointment;
    
    // Show check-in dialog
    final result = await showQuickCheckInDialog(context, db, appointment, patient);
    if (result != null && result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Patient checked in'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); // Refresh dashboard
    }
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isCompact,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 14 : 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: isDark ? null : [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isCompact ? 22 : 24),
            ),
            SizedBox(height: isCompact ? 8 : 10),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows patient picker dialog and creates a new encounter
  Future<void> _startNewEncounter(BuildContext context, DoctorDatabase db) async {
    await startNewEncounterWithPicker(context, db);
  }

  // ============================================================
  // SECTION 6: PATIENT QUEUE
  // ============================================================
  Widget _buildPatientQueue(
    BuildContext context, 
    DoctorDatabase db, 
    List<Appointment> appointments, 
    bool isCompact, 
    bool isDark,
  ) {
    final queuedAppts = appointments.where((a) => 
        a.status == 'scheduled' || a.status == 'pending').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Queue",
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${queuedAppts.length} waiting',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 12 : 16),
        if (queuedAppts.isEmpty)
          _buildEmptyQueueState(isDark, isCompact)
        else
          ...queuedAppts.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final appt = entry.value;
            return _buildQueueItem(context, db, appt, index + 1, isCompact, isDark);
          }),
      ],
    );
  }

  Widget _buildEmptyQueueState(bool isDark, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            'No patients waiting',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your queue is clear for now',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context, 
    DoctorDatabase db, 
    Appointment appt, 
    int position, 
    bool isCompact, 
    bool isDark,
  ) {
    final timeFormat = DateFormat('h:mm a');
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(appt.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}' 
            : 'Patient #${appt.patientId}';
        
        return GestureDetector(
          onTap: () {
            if (patient != null) {
              // Navigate to patient view
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
          },
          child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: position == 1 
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row: Position, Patient Info, Time
              Row(
                children: [
                  // Position Number
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: position == 1 
                          ? const Color(0xFF6366F1) 
                          : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: position == 1 ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appt.reason.isNotEmpty ? appt.reason : 'Consultation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeFormat.format(appt.appointmentDateTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              // Action buttons row (shown below main row)
              if (appt.status.toLowerCase() == 'in_progress' || (position == 1 && patient != null && appt.status.toLowerCase() != 'in_progress')) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Status indicator
                    if (appt.status.toLowerCase() == 'in_progress')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pending_rounded, color: Color(0xFFFBBF24), size: 12),
                            SizedBox(width: 4),
                            Text('In Progress', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    // Complete button for in_progress appointments
                    if (appt.status.toLowerCase() == 'in_progress')
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await db.updateAppointmentStatus(appt.id, 'completed');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Visit completed for $patientName'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            setState(() {}); // Refresh the list
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Complete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Start button for first in queue
                    if (position == 1 && patient != null && appt.status.toLowerCase() != 'in_progress')
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await db.updateAppointmentStatus(appt.id, 'in_progress');
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
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Start',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        );
      },
    );
  }

  // ============================================================
  // SECTION 7: PENDING TASKS
  // ============================================================
  Widget _buildPendingTasks(
    BuildContext context,
    DoctorDatabase db, {
    required List<ScheduledFollowUp> overdueFollowUps,
    required List<ScheduledFollowUp> upcomingFollowUps,
    required bool isCompact,
    required bool isDark,
  }) {
    final hasOverdue = overdueFollowUps.isNotEmpty;
    final hasUpcoming = upcomingFollowUps.isNotEmpty;
    
    if (!hasOverdue && !hasUpcoming) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Tasks',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppRouter.route(const FollowUpsScreen())),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 12 : 16),
        
        // Overdue Follow-ups (Priority)
        if (hasOverdue) ...[
          _buildTaskCategory(
            title: 'Overdue Follow-ups',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            count: overdueFollowUps.length,
            isCompact: isCompact,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          ...overdueFollowUps.take(3).map((f) => _buildFollowUpItem(context, db, f, true, isCompact, isDark)),
          const SizedBox(height: 16),
        ],
        
        // Upcoming Follow-ups
        if (hasUpcoming) ...[
          _buildTaskCategory(
            title: 'Due This Week',
            icon: Icons.event_rounded,
            color: const Color(0xFF3B82F6),
            count: upcomingFollowUps.length,
            isCompact: isCompact,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          ...upcomingFollowUps.take(3).map((f) => _buildFollowUpItem(context, db, f, false, isCompact, isDark)),
        ],
      ],
    );
  }

  Widget _buildTaskCategory({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool isCompact,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpItem(
    BuildContext context, 
    DoctorDatabase db, 
    ScheduledFollowUp followUp, 
    bool isOverdue, 
    bool isCompact, 
    bool isDark,
  ) {
    final daysAway = followUp.scheduledDate.difference(DateTime.now()).inDays;
    final color = isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(followUp.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  patient != null ? patient.firstName[0] : 'P',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient != null ? '${patient.firstName} ${patient.lastName}' : 'Unknown Patient',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      followUp.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOverdue 
                      ? '${-daysAway}d overdue' 
                      : (daysAway == 0 ? 'Today' : '${daysAway}d'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SECTION 8: REVENUE SUMMARY
  // ============================================================
  Widget _buildRevenueSummary(
    BuildContext context, {
    required double todayRevenue,
    required double pendingPayments,
    required bool isCompact,
    required bool isDark,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF14B8A6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: const Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Today's Revenue",
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collected',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(todayRevenue),
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1, height: 50,
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(pendingPayments),
                        style: TextStyle(
                          fontSize: isCompact ? 22 : 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 9: RECENT PATIENTS
  // ============================================================
  Widget _buildRecentPatientsSection(
    BuildContext context,
    List<Patient> patients,
    bool isCompact,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Patients',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, AppRouter.route(const PatientsScreen())),
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 12 : 16),
        if (patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded, size: 40, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'No patients yet',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100, // Increased height for better text accommodation
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/patient/${patient.id}'),
                  child: Container(
                    width: 75,
                    margin: EdgeInsets.only(right: index < patients.length - 1 ? 12 : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _getPatientColor(index),
                          child: Text(
                            '${patient.firstName[0]}${patient.lastName[0]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            patient.firstName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _getPatientColor(int index) {
    return PatientColors.getColor(index);
  }
}

/// Dialog for picking an appointment for check-in
class _AppointmentPickerDialog extends StatelessWidget {
  const _AppointmentPickerDialog({required this.appointments});

  final List<Map<String, dynamic>> appointments;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                    const Color(0xFF059669).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Appointment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointments.length} waiting to check in',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            // Appointments List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = appointments[index];
                  final patient = item['patient'] as Patient;
                  final appt = item['appointment'] as Appointment;
                  final patientName = '${patient.firstName} ${patient.lastName}';

                  return InkWell(
                    onTap: () => Navigator.pop(context, item),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            child: Text(
                              '${patient.firstName[0]}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeFormat.format(appt.appointmentDateTime),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                    if (appt.reason.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          appt.reason,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
