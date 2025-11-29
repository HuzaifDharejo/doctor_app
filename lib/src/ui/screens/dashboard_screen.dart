import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/core.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/patient_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/global_search_bar.dart';
import '../widgets/dashboard_charts.dart';
import 'patients_screen.dart';
import 'add_patient_screen.dart';
import 'add_appointment_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onMenuTap;
  
  const DashboardScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final doctorSettings = ref.watch(doctorSettingsProvider);
    
    return Scaffold(
      body: SafeArea(
        child: dbAsync.when(
          data: (db) => _buildDashboard(context, db, ref),
          loading: () => const LoadingState(),
          error: (err, stack) => ErrorState.generic(
            message: err.toString(),
            onRetry: () => ref.invalidate(doctorDbProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DoctorDatabase db, WidgetRef ref) {
    return FutureBuilder<List<Patient>>(
      future: db.getAllPatients(),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];
        return _buildContent(context, db, patients, ref);
      },
    );
  }

  Widget _buildContent(BuildContext context, DoctorDatabase db, List<Patient> patients, WidgetRef ref) {
    return FutureBuilder<List<Appointment>>(
      future: db.getAppointmentsForDay(DateTime.now()),
      builder: (context, apptSnapshot) {
        final todayAppointments = apptSnapshot.data ?? [];
        final pendingCount = todayAppointments.where((a) => a.status == 'pending' || a.status == 'scheduled').length;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = AppBreakpoint.isCompact(constraints.maxWidth);
            final padding = isCompact ? 16.0 : 24.0;
            
            return CustomScrollView(
              slivers: [
                // Modern Header
                SliverToBoxAdapter(
                  child: _buildModernHeader(context, ref, isCompact),
                ),
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: const GlobalSearchBar(),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 16 : 24)),
                
                // Stats Cards - Horizontal scroll
                SliverToBoxAdapter(
                  child: _buildStatsSection(patients.length, todayAppointments.length, pendingCount, isCompact, context),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
            
                // Quick Actions - Modern Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildModernQuickActions(context, isCompact),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
                
                // Today's Schedule Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildTodaySchedule(context, todayAppointments, isCompact),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
                
                // Analytics Charts
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildAnalyticsSection(context, db, isCompact),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? 16 : 24)),
                
                // Recent Patients Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildSectionHeader(context, AppStrings.recentPatients, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
                    }, isCompact),
                  ),
                ),
                
                // Patient List
                if (patients.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState.patients(
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPatientScreen()),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: isCompact ? 10 : 12),
                          child: PatientCard(patient: patients[index]),
                        ),
                        childCount: patients.length > 5 ? 5 : patients.length,
                      ),
                    ),
                  ),
                
                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModernHeader(BuildContext context, WidgetRef ref, [bool isCompact = false]) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny_rounded;
    Color greetingColor = const Color(0xFFFBBF24);
    
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingColor = const Color(0xFFF97316);
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
      greetingColor = const Color(0xFF8B5CF6);
    }
    
    final isDark = context.isDarkMode;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');
    
    return Container(
      padding: EdgeInsets.fromLTRB(isCompact ? 16 : 24, isCompact ? 12 : 16, isCompact ? 16 : 24, isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Menu Button
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                    size: isCompact ? 20 : 22,
                  ),
                ),
              ),
              const Spacer(),
              // Date Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
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
              const SizedBox(width: 10),
              // Notification Button
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 10 : 12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      size: isCompact ? 20 : 22,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 28),
          // Greeting Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      greetingColor.withValues(alpha: 0.2),
                      greetingColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(greetingIcon, color: greetingColor, size: isCompact ? 24 : 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 26,
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
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isCompact ? 24 : 28,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: isCompact ? 22 : 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 14 : 16,
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

  Widget _buildStatsSection(int patientCount, int todayAppts, int pendingAppts, bool isCompact, BuildContext context) {
    final isDark = context.isDarkMode;
    
    return SizedBox(
      height: isCompact ? 130 : 145,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
        children: [
          _buildModernStatCard(
            icon: Icons.people_alt_rounded,
            title: 'Total Patients',
            value: '$patientCount',
            trend: '+12%',
            trendUp: true,
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            isCompact: isCompact,
            isDark: isDark,
          ),
          SizedBox(width: isCompact ? 12 : 16),
          _buildModernStatCard(
            icon: Icons.calendar_month_rounded,
            title: "Today's Appointments",
            value: '$todayAppts',
            trend: '$pendingAppts pending',
            trendUp: null,
            gradient: const [Color(0xFF14B8A6), Color(0xFF06B6D4)],
            isCompact: isCompact,
            isDark: isDark,
          ),
          SizedBox(width: isCompact ? 12 : 16),
          _buildModernStatCard(
            icon: Icons.trending_up_rounded,
            title: 'This Month',
            value: '87%',
            trend: '+5%',
            trendUp: true,
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            isCompact: isCompact,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required bool? trendUp,
    required List<Color> gradient,
    required bool isCompact,
    required bool isDark,
  }) {
    return Container(
      width: isCompact ? 155 : 175,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: isCompact ? 20 : 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trendUp != null)
                      Icon(
                        trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    if (trendUp != null) const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickActions(BuildContext context, [bool isCompact = false]) {
    final isDark = context.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Fast access',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 16 : 20),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard(
              icon: Icons.person_add_rounded,
              label: 'Add Patient',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
            SizedBox(width: isCompact ? 10 : 14),
            Expanded(child: _buildQuickActionCard(
              icon: Icons.event_note_rounded,
              label: 'New Appointment',
              color: const Color(0xFF14B8A6),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAppointmentScreen())),
              isCompact: isCompact,
              isDark: isDark,
            )),
          ],
        ),

      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isCompact,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 18,
            vertical: isCompact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.15),
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: isCompact ? 22 : 24),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(BuildContext context, List<Appointment> appointments, bool isCompact) {
    final isDark = context.isDarkMode;
    final upcomingAppts = appointments.where((a) => a.status == 'scheduled' || a.status == 'pending').take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Today's Schedule", () {}, isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        if (upcomingAppts.isEmpty)
          Container(
            padding: EdgeInsets.all(isCompact ? 20 : 28),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No appointments today',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enjoy your free time!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ...upcomingAppts.asMap().entries.map((entry) {
            final appt = entry.value;
            final timeFormat = DateFormat('h:mm a');
            final isLast = entry.key == upcomingAppts.length - 1;
            
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: EdgeInsets.all(isCompact ? 14 : 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.15),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeFormat.format(appt.appointmentDateTime),
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient #${appt.patientId}',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appt.reason.isNotEmpty ? appt.reason : 'Consultation',
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: appt.status == 'pending' 
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appt.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: appt.status == 'pending' ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll, bool isCompact) {
    final isDark = context.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Text(
            'See All',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, DoctorDatabase db, [bool isCompact = false]) {
    final isDark = context.isDarkMode;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAnalyticsData(db),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {
          'weeklyRevenue': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
          'totalRevenue': 0.0,
          'completed': 0,
          'scheduled': 0,
          'cancelled': 0,
          'noShow': 0,
        };
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_graph_rounded,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            RevenueChart(
              weeklyRevenue: List<double>.from(data['weeklyRevenue']),
              totalRevenue: data['totalRevenue'],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            AppointmentsPieChart(
              completed: data['completed'],
              scheduled: data['scheduled'],
              cancelled: data['cancelled'],
              noShow: data['noShow'],
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getAnalyticsData(DoctorDatabase db) async {
    // Get weekly revenue from invoices
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final invoices = await db.getAllInvoices();
    
    final weeklyRevenue = List<double>.filled(7, 0.0);
    double totalRevenue = 0;
    
    for (final invoice in invoices) {
      if (invoice.paymentStatus == 'Paid') {
        totalRevenue += invoice.grandTotal;
        
        // Check if invoice is from this week
        final daysDiff = invoice.invoiceDate.difference(weekStart).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          weeklyRevenue[daysDiff] += invoice.grandTotal;
        }
      }
    }
    
    // Get appointment stats for this month
    final appointments = await db.select(db.appointments).get();
    int completed = 0, scheduled = 0, cancelled = 0, noShow = 0;
    
    for (final appt in appointments) {
      if (appt.appointmentDateTime.month == now.month && 
          appt.appointmentDateTime.year == now.year) {
        switch (appt.status.toLowerCase()) {
          case 'completed':
            completed++;
            break;
          case 'scheduled':
          case 'pending':
            scheduled++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'no-show':
          case 'noshow':
            noShow++;
            break;
        }
      }
    }
    
    return {
      'weeklyRevenue': weeklyRevenue,
      'totalRevenue': totalRevenue,
      'completed': completed,
      'scheduled': scheduled,
      'cancelled': cancelled,
      'noShow': noShow,
    };
  }
}
