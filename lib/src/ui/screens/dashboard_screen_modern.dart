// Unified Dashboard Screen - Best of Both Designs
// Features: Tutorial, Wait Stats, Patient Queue, Pending Tasks, Modern UI

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/skeleton_loading.dart';
import '../../core/utils/appointment_types.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/patient_picker_dialog.dart';
import '../widgets/quick_vitals_dialog.dart';
import '../widgets/quick_note_dialog.dart';
import '../widgets/quick_checkin_dialog.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/wait_time_stats.dart';
import 'add_appointment_screen.dart';
import 'add_patient_screen.dart';
import 'add_prescription_screen.dart';
import 'appointments_screen.dart';
import 'billing_screen.dart';
import 'clinical_calculators_screen.dart';
import 'follow_ups_screen.dart';
import 'patient_view/patient_view_screen.dart';
import 'notifications_screen.dart';
import 'workflow_wizard_screen.dart';

class DashboardScreenModern extends ConsumerStatefulWidget {
  const DashboardScreenModern({super.key, this.onMenuTap});
  final VoidCallback? onMenuTap;

  @override
  ConsumerState<DashboardScreenModern> createState() => _DashboardScreenModernState();
}

class _DashboardScreenModernState extends ConsumerState<DashboardScreenModern>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // Tutorial target keys
  final _quickActionsKey = GlobalKey();
  final _statsOverviewKey = GlobalKey();
  final _todayScheduleKey = GlobalKey();
  final _startVisitKey = GlobalKey();
  
  bool _tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    ref.invalidate(doctorDbProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _showDashboardTutorial() async {
    if (_tutorialShown) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_dashboard_tutorial') ?? false;
    if (hasSeenTutorial) return;
    
    _tutorialShown = true;
    
    // Wait longer for widgets to be fully rendered after data loads
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    // Check if the target keys are actually rendered before showing tutorial
    bool keysReady = false;
    int attempts = 0;
    while (!keysReady && attempts < 10 && mounted) {
      final hasStatsKey = _statsOverviewKey.currentContext != null;
      final hasStartVisitKey = _startVisitKey.currentContext != null;
      final hasQuickActionsKey = _quickActionsKey.currentContext != null;
      
      keysReady = hasStatsKey || hasStartVisitKey || hasQuickActionsKey;
      
      if (!keysReady) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
    }
    
    if (!mounted || !keysReady) return;
    
    // Build steps only for keys that are actually rendered
    final allSteps = <TutorialStep>[];
    
    if (_statsOverviewKey.currentContext != null) {
      allSteps.add(TutorialStep(
        title: 'Welcome to Your Dashboard!',
        description: 'This is your command center. Let\'s take a quick tour of the key features to help you get started.',
        targetKey: _statsOverviewKey,
        icon: Icons.dashboard_rounded,
      ));
    }
    
    if (_startVisitKey.currentContext != null) {
      allSteps.add(TutorialStep(
        title: 'Start a Visit',
        description: 'Begin a new patient visit with our guided workflow wizard. It helps you through registration, vitals, and clinical notes.',
        targetKey: _startVisitKey,
        icon: Icons.play_circle_filled_rounded,
      ));
    }
    
    if (_quickActionsKey.currentContext != null) {
      allSteps.add(TutorialStep(
        title: 'Quick Actions',
        description: 'Access common tasks quickly: add patients, schedule appointments, create prescriptions, and more.',
        targetKey: _quickActionsKey,
        icon: Icons.flash_on_rounded,
      ));
    }
    
    if (_todayScheduleKey.currentContext != null) {
      allSteps.add(TutorialStep(
        title: 'Today\'s Schedule',
        description: 'View and manage your appointments for today. Tap any appointment to see details or start the visit.',
        targetKey: _todayScheduleKey,
        icon: Icons.calendar_today_rounded,
      ));
    }
    
    // Only show tutorial if we have at least one valid step
    if (allSteps.isEmpty) return;
    
    TutorialOverlay.show(
      context,
      allSteps,
      onComplete: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_dashboard_tutorial', true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);

    return Scaffold(
      backgroundColor: context.isDarkMode ? AppColors.darkSurfaceDeep : AppColors.background,
      body: SafeArea(
        child: dbAsync.when(
          data: (db) => _buildDashboard(context, db),
          loading: () => const DashboardSkeleton(),
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
          return const DashboardSkeleton();
        }
        return _buildContent(context, db, snapshot.data!);
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

    final pendingAppts = todayAppointments
        .where((a) => a.status == 'pending' || a.status == 'scheduled')
        .toList();
    final checkedInAppts = todayAppointments
        .where((a) => a.status == 'checked_in')
        .toList();
    final completedToday = todayAppointments
        .where((a) => a.status == 'completed')
        .length;
    final inProgressAppt = todayAppointments
        .where((a) => a.status == 'in_progress')
        .toList();

    final today = DateTime.now();
    final todayRevenue = allInvoices
        .where((inv) =>
            inv.invoiceDate.year == today.year &&
            inv.invoiceDate.month == today.month &&
            inv.invoiceDate.day == today.day &&
            inv.paymentStatus == 'Paid')
        .fold<double>(0, (sum, inv) => sum + inv.grandTotal);

    final pendingPayments = allInvoices
        .where((inv) => inv.paymentStatus != 'Paid')
        .fold<double>(0, (sum, inv) => sum + inv.grandTotal);

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
      'totalPatients': patients.length,
      'waitTimeStats': waitTimeStats,
    };
  }

  Widget _buildContent(
      BuildContext context, DoctorDatabase db, Map<String, dynamic> data) {
    final isDark = context.isDarkMode;
    final todayAppointments = data['todayAppointments'] as List<Appointment>;
    final pendingAppts = data['pendingAppts'] as List<Appointment>;
    final checkedInAppts = data['checkedInAppts'] as List<Appointment>;
    final completedToday = data['completedToday'] as int;
    final inProgressAppt = data['inProgressAppt'] as List<Appointment>;
    final overdueFollowUps = data['overdueFollowUps'] as List<ScheduledFollowUp>;
    final upcomingFollowUps = data['upcomingFollowUps'] as List<ScheduledFollowUp>;
    final todayRevenue = data['todayRevenue'] as double;
    final pendingPayments = data['pendingPayments'] as double;
    final totalPatients = data['totalPatients'] as int;
    final waitTimeStats = data['waitTimeStats'] as WaitTimeStats;

    // Show tutorial on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDashboardTutorial();
    });

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context, isDark),
          ),

          // Alert Banner (if needed)
          if (overdueFollowUps.isNotEmpty || inProgressAppt.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildAlertBanner(
                context,
                overdueFollowUps.length,
                inProgressAppt.isNotEmpty,
                isDark,
              ),
            ),

          // Stats Overview
          SliverToBoxAdapter(
            child: Container(
              key: _statsOverviewKey,
              child: _buildStatsOverview(
                context,
                isDark,
                todayAppts: todayAppointments.length,
                completed: completedToday,
                waiting: pendingAppts.length + checkedInAppts.length,
                totalPatients: totalPatients,
              ),
            ),
          ),

          // Wait Time Statistics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: WaitTimeCard(
                stats: waitTimeStats,
                isCompact: false,
                isDark: isDark,
              ),
            ),
          ),

          // Next Patient Card
          if (checkedInAppts.isNotEmpty || pendingAppts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildNextPatientCard(
                context,
                db,
                [...checkedInAppts, ...pendingAppts].first,
                isDark,
              ),
            ),

          // Quick Actions Grid
          SliverToBoxAdapter(
            child: Container(
              key: _quickActionsKey,
              child: _buildQuickActionsGrid(context, db, isDark),
            ),
          ),

          // Patient Queue (detailed list)
          SliverToBoxAdapter(
            child: Container(
              key: _todayScheduleKey,
              child: _buildPatientQueue(context, db, todayAppointments, isDark),
            ),
          ),

          // Pending Tasks (Follow-ups)
          if (overdueFollowUps.isNotEmpty || upcomingFollowUps.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPendingTasks(
                context,
                db,
                overdueFollowUps: overdueFollowUps,
                upcomingFollowUps: upcomingFollowUps,
                isDark: isDark,
              ),
            ),

          // Recent Patients
          SliverToBoxAdapter(
            child: _buildRecentPatients(context, db, isDark),
          ),

          // Revenue Card (with pending)
          SliverToBoxAdapter(
            child: _buildRevenueCard(context, todayRevenue, pendingPayments, isDark),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, bool isDark) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final hour = DateTime.now().hour;
    final now = DateTime.now();

    String greeting;
    IconData greetingIcon;
    List<Color> greetingGradient;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingGradient = [AppColors.warning, AppColors.warning];
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.light_mode_rounded;
      greetingGradient = [AppColors.quickActionOrange, AppColors.quickActionOrangeDark];
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_rounded;
      greetingGradient = [AppColors.billing, AppColors.primaryDark];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurfaceMid, AppColors.darkSurfaceDeep]
              : [AppColors.surface, AppColors.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            children: [
              // Menu Button
              _buildIconButton(
                icon: Icons.menu_rounded,
                onTap: widget.onMenuTap,
                isDark: isDark,
              ),
              const Spacer(),
              // Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, MMM d').format(now),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Notifications
              _buildIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                isDark: isDark,
                showBadge: true,
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Greeting
          Row(
            children: [
              // Greeting Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: greetingGradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: greetingGradient[0].withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(greetingIcon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. ${profile.displayName}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? AppColors.darkSurfaceMid : AppColors.surface,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : Colors.grey[700],
              size: 22,
            ),
          ),
          if (showBadge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALERT BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAlertBanner(
      BuildContext context, int overdueCount, bool hasInProgress, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEF4444).withValues(alpha: 0.15),
              const Color(0xFFF97316).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attention Required',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${overdueCount > 0 ? '$overdueCount overdue follow-ups' : ''}${overdueCount > 0 && hasInProgress ? ' • ' : ''}${hasInProgress ? 'Patient in progress' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsOverview(
    BuildContext context,
    bool isDark, {
    required int todayAppts,
    required int completed,
    required int waiting,
    required int totalPatients,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today_rounded,
              label: 'Today',
              value: '$todayAppts',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              label: 'Done',
              value: '$completed',
              color: AppColors.quickActionGreen,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.hourglass_top_rounded,
              label: 'Waiting',
              value: '$waiting',
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.people_rounded,
              label: 'Patients',
              value: '$totalPatients',
              color: AppColors.quickActionPink,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEXT PATIENT CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNextPatientCard(
      BuildContext context, DoctorDatabase db, Appointment appt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: FutureBuilder<Patient?>(
        future: db.getPatientById(appt.patientId),
        builder: (context, snapshot) {
          final patient = snapshot.data;
          final timeFormat = DateFormat('h:mm a');
          final isCheckedIn = appt.status == 'checked_in';

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCheckedIn
                    ? [AppColors.quickActionGreen, AppColors.quickActionGreenDark]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isCheckedIn
                          ? AppColors.quickActionGreen
                          : AppColors.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCheckedIn
                                ? Icons.how_to_reg_rounded
                                : Icons.schedule_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCheckedIn ? 'CHECKED IN' : 'NEXT UP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeFormat.format(appt.appointmentDateTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        patient != null
                            ? '${patient.firstName[0]}${patient.lastName[0]}'
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient != null
                                ? '${patient.firstName} ${patient.lastName}'
                                : 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appt.reason ?? 'General consultation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isCheckedIn
                          ? AppColors.quickActionGreen
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheckedIn
                              ? Icons.play_arrow_rounded
                              : Icons.login_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCheckedIn ? 'Start Consultation' : 'Check In & Start',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickActionsGrid(
      BuildContext context, DoctorDatabase db, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.darkSurfaceMid,
            ),
          ),
          const SizedBox(height: 16),
          // Row 1: Main clinical actions
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.play_circle_filled_rounded,
                  label: 'Start Visit',
                  color: AppColors.quickActionGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorkflowWizardScreen()),
                  ),
                  isDark: isDark,
                  cardKey: _startVisitKey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.person_add_rounded,
                  label: 'New Patient',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddPatientScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.event_note_rounded,
                  label: 'Appointment',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddAppointmentScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.medication_rounded,
                  label: 'Prescribe',
                  color: AppColors.warning,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddPrescriptionScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Quick utilities
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Check-In',
                  color: AppColors.quickActionGreenDark,
                  onTap: () => _showQuickCheckIn(context, db),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.favorite_rounded,
                  label: 'Vitals',
                  color: AppColors.error,
                  onTap: () => _showQuickVitals(context, db),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.note_add_rounded,
                  label: 'Quick Note',
                  color: AppColors.blue,
                  onTap: () => _showQuickNote(context, db),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.event_repeat_rounded,
                  label: 'Follow-ups',
                  color: AppColors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FollowUpsScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Tools
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.calculate_rounded,
                  label: 'Calculators',
                  color: AppColors.skyBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClinicalCalculatorsScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Billing',
                  color: AppColors.quickActionPink,
                  onTap: () => Navigator.push(
                    context,
                    AppRouter.route(const BillingScreen()),
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Placeholder
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Placeholder
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    Key? cardKey,
  }) {
    return GestureDetector(
      key: cardKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODAY'S SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodaySchedule(BuildContext context, DoctorDatabase db,
      List<Appointment> appointments, bool isDark) {
    final upcomingAppts = appointments
        .where((a) =>
            a.status == 'scheduled' ||
            a.status == 'pending' ||
            a.status == 'checked_in')
        .take(4)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.darkSurfaceMid,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppointmentsScreen()),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingAppts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 48,
                      color: isDark ? Colors.white30 : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No more appointments today',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                children: upcomingAppts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final appt = entry.value;
                  return _buildScheduleItem(
                    context,
                    db,
                    appt,
                    isDark,
                    isLast: index == upcomingAppts.length - 1,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, DoctorDatabase db,
      Appointment appt, bool isDark,
      {bool isLast = false}) {
    final timeFormat = DateFormat('h:mm a');
    final isCheckedIn = appt.status == 'checked_in';

    Color statusColor;
    String statusText;

    switch (appt.status) {
      case 'checked_in':
        statusColor = AppColors.quickActionGreen;
        statusText = 'Ready';
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusText = 'In Progress';
        break;
      default:
        statusColor = AppColors.primary;
        statusText = 'Scheduled';
    }

    return FutureBuilder<Patient?>(
      future: db.getPatientById(appt.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
          ),
          child: Row(
            children: [
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeFormat.format(appt.appointmentDateTime),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkSurfaceMid,
                    ),
                  ),
                  Text(
                    '${appt.durationMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Patient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient != null
                          ? '${patient.firstName} ${patient.lastName}'
                          : 'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkSurfaceMid,
                      ),
                    ),
                    Text(
                      appt.reason ?? 'General',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT PATIENTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentPatients(
      BuildContext context, DoctorDatabase db, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Patients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.darkSurfaceMid,
                ),
              ),
              Icon(
                Icons.history_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Patient>>(
            future: db.getRecentPatients(limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 40,
                          color: isDark ? Colors.white30 : Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent patients',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final recentPatients = snapshot.data!;
              return SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentPatients.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final patient = recentPatients[index];
                    return _buildRecentPatientCard(context, patient, isDark);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatientCard(
      BuildContext context, Patient patient, bool isDark) {
    final fullName = '${patient.firstName} ${patient.lastName ?? ''}'.trim();
    final initials = fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final age = patient.age;

    final colors = [
      AppColors.primary,
      AppColors.quickActionGreen,
      AppColors.warning,
      AppColors.error,
      AppColors.purple,
      AppColors.accent,
    ];
    final color = colors[patient.id % colors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientViewScreen(patient: patient),
            settings: const RouteSettings(name: '/patient-view'),
          ),
        );
      },
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              patient.firstName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (age != null)
              Text(
                '${age}y',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white60 : Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATIENT QUEUE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPatientQueue(
    BuildContext context,
    DoctorDatabase db,
    List<Appointment> appointments,
    bool isDark,
  ) {
    final queuedAppts = appointments.where((a) => 
        a.status == 'scheduled' || a.status == 'pending').toList();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Queue",
                style: TextStyle(
                  fontSize: 18,
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
          const SizedBox(height: 12),
          if (queuedAppts.isEmpty)
            _buildEmptyQueueState(isDark)
          else
            ...queuedAppts.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final appt = entry.value;
              return _buildQueueItem(context, db, appt, index + 1, isDark);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyQueueState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
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
    bool isDark,
  ) {
    final timeFormat = DateFormat('h:mm a');
    // Get appointment type color based on reason
    final appointmentType = AppointmentTypes.inferType(appt.reason);
    final typeColor = AppointmentTypes.getColor(appointmentType);
    
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
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: position == 1 
                    ? typeColor.withValues(alpha: 0.3)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                // Colored type strip
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppointmentTypes.getGradient(appointmentType),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                              fontSize: 14,
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
                // Action buttons row for first in queue or in_progress
                if (appt.status.toLowerCase() == 'in_progress' || (position == 1 && patient != null && appt.status.toLowerCase() != 'in_progress')) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Status indicator for in_progress
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
                              setState(() {});
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
                                Text('Complete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                Text('Start', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING TASKS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPendingTasks(
    BuildContext context,
    DoctorDatabase db, {
    required List<ScheduledFollowUp> overdueFollowUps,
    required List<ScheduledFollowUp> upcomingFollowUps,
    required bool isDark,
  }) {
    final hasOverdue = overdueFollowUps.isNotEmpty;
    final hasUpcoming = upcomingFollowUps.isNotEmpty;
    
    if (!hasOverdue && !hasUpcoming) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Tasks',
                style: TextStyle(
                  fontSize: 18,
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
          const SizedBox(height: 12),
          
          // Overdue Follow-ups (Priority)
          if (hasOverdue) ...[
            _buildTaskCategory(
              title: 'Overdue Follow-ups',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
              count: overdueFollowUps.length,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            ...overdueFollowUps.take(3).map((f) => _buildFollowUpItem(context, db, f, true, isDark)),
            const SizedBox(height: 16),
          ],
          
          // Upcoming Follow-ups
          if (hasUpcoming) ...[
            _buildTaskCategory(
              title: 'Due This Week',
              icon: Icons.event_rounded,
              color: const Color(0xFF3B82F6),
              count: upcomingFollowUps.length,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            ...upcomingFollowUps.take(3).map((f) => _buildFollowUpItem(context, db, f, false, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCategory({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
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
              fontSize: 14,
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
          padding: const EdgeInsets.all(12),
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
                        fontSize: 13,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // REVENUE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRevenueCard(
      BuildContext context, double todayRevenue, double pendingPayments, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          AppRouter.route(const BillingScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E3A5F), const Color(0xFF0F1F33)]
                  : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.skyBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.skyBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Revenue",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(todayRevenue),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isDark ? Colors.white60 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _showQuickCheckIn(BuildContext context, DoctorDatabase db) async {
    final todayAppointments = await db.getAppointmentsForDay(DateTime.now());
    final pendingAppts = todayAppointments
        .where((a) => a.status == 'scheduled' || a.status == 'pending')
        .toList();

    if (!context.mounted) return;

    if (pendingAppts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending appointments to check in'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show dialog to select appointment
    final selectedAppt = await showDialog<Appointment>(
      context: context,
      builder: (context) => _AppointmentPickerDialog(
        appointments: pendingAppts,
        db: db,
      ),
    );

    if (selectedAppt != null && context.mounted) {
      final patient = await db.getPatientById(selectedAppt.patientId);
      if (patient != null && context.mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => QuickCheckInDialog(
            appointment: selectedAppt,
            patient: patient,
            db: db,
          ),
        );
        await _onRefresh();
      }
    }
  }

  Future<void> _showQuickVitals(BuildContext context, DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    if (!context.mounted) return;

    final patient = await showDialog<Patient>(
      context: context,
      builder: (context) => PatientPickerDialog(patients: patients),
    );

    if (patient != null && context.mounted) {
      final result = await showQuickVitalsDialog(context, db, patient);
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Vitals saved'),
            backgroundColor: AppColors.quickActionGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showQuickNote(BuildContext context, DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    if (!context.mounted) return;

    final patient = await showDialog<Patient>(
      context: context,
      builder: (context) => PatientPickerDialog(patients: patients),
    );

    if (patient != null && context.mounted) {
      final result = await showQuickNoteDialog(context, db, patient);
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Note saved'),
            backgroundColor: AppColors.quickActionGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Simple appointment picker dialog for check-in
class _AppointmentPickerDialog extends StatelessWidget {
  const _AppointmentPickerDialog({
    required this.appointments,
    required this.db,
  });

  final List<Appointment> appointments;
  final DoctorDatabase db;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.quickActionGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_reg_rounded,
                    color: AppColors.quickActionGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return FutureBuilder<Patient?>(
                    future: db.getPatientById(appt.patientId),
                    builder: (context, snapshot) {
                      final patient = snapshot.data;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            patient != null
                                ? '${patient.firstName[0]}${patient.lastName[0]}'
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          patient != null
                              ? '${patient.firstName} ${patient.lastName}'
                              : 'Loading...',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${timeFormat.format(appt.appointmentDateTime)} • ${appt.reason ?? "General"}',
                        ),
                        onTap: () => Navigator.pop(context, appt),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
