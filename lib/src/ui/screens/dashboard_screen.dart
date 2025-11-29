import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/pkr_currency.dart';
import '../widgets/stat_card.dart';
import '../widgets/patient_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/global_search_bar.dart';
import '../widgets/dashboard_charts.dart';
import 'patients_screen.dart';
import 'appointments_screen.dart';
import 'add_patient_screen.dart';
import 'add_appointment_screen.dart';
import 'add_prescription_screen.dart';

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
            final padding = isCompact ? AppSpacing.sm : AppSpacing.lg;
            
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, ref, isCompact),
                ),
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: const GlobalSearchBar(),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md)),
                
                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildStatsRow(patients.length, todayAppointments.length, pendingCount),
                  ),
                ),
            
                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: _buildQuickActions(context, isCompact),
                  ),
                ),
                
                // Analytics Charts
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: _buildAnalyticsSection(context, db, isCompact),
                  ),
                ),
                
                SliverToBoxAdapter(child: SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md)),
                
                // Recent Patients Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.recentPatients,
                          style: context.textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatientsScreen()),
                          ),
                          child: Text(AppStrings.seeAll, style: TextStyle(fontSize: isCompact ? 11 : 13)),
                        ),
                      ],
                    ),
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
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: AppSpacing.xxs),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: isCompact ? AppSpacing.xs : AppSpacing.sm),
                          child: PatientCard(patient: patients[index]),
                        ),
                        childCount: patients.length > 5 ? 5 : patients.length,
                      ),
                    ),
                  ),
                
                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, [bool isCompact = false]) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny_rounded;
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
    }
    
    final padding = isCompact ? AppSpacing.sm : AppSpacing.lg;
    final avatarSize = isCompact ? 26.0 : 32.0;
    final isDark = context.isDarkMode;
    
    return Container(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Hamburger Menu Button with gradient
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primaryLight.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primary,
                        size: isCompact ? AppIconSize.sm : 22,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            greetingIcon,
                            size: isCompact ? AppIconSize.xs : AppFontSize.sm,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.displayName,
                        style: TextStyle(
                          fontSize: isCompact ? AppSpacing.md : AppSpacing.lg,
                          fontWeight: FontWeight.w800,
                          color: context.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Notification bell
                  Container(
                    padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: AppSpacing.xs,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_rounded,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          size: isCompact ? AppIconSize.sm : 22,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: AppSpacing.sm,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: avatarSize - 2,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          profile.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? AppFontSize.xs : AppFontSize.sm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int patientCount, int todayAppts, int pendingAppts) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.people_alt_rounded,
            title: 'Total Patients',
            value: '$patientCount',
            color: AppColors.primary,
            trend: '+12%',
            trendUp: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatCard(
            icon: Icons.calendar_today_rounded,
            title: "Today's Appts",
            value: '$todayAppts',
            color: AppColors.accent,
            trend: '$pendingAppts pending',
            trendUp: null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, [bool isCompact = false]) {
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
                fontSize: isCompact ? 15 : AppFontSize.lg,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.flash_on_rounded, size: AppFontSize.sm, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Fast access',
                    style: TextStyle(
                      fontSize: AppFontSize.xxs,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionButton(
              icon: Icons.person_add_rounded,
              label: AppStrings.addPatient,
              color: AppColors.patients,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPatientScreen()),
              ),
            ),
            QuickActionButton(
              icon: Icons.event_note_rounded,
              label: 'New Appt',
              color: AppColors.appointments,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
              ),
            ),
            QuickActionButton(
              icon: Icons.medication_rounded,
              label: 'Prescribe',
              color: AppColors.prescriptions,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPrescriptionScreen()),
              ),
            ),
            QuickActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Invoice',
              color: AppColors.billing,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, DoctorDatabase db, [bool isCompact = false]) {
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
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: isCompact ? AppFontSize.sm : AppSpacing.md,
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md),
            RevenueChart(
              weeklyRevenue: List<double>.from(data['weeklyRevenue']),
              totalRevenue: data['totalRevenue'],
            ),
            SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md),
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
