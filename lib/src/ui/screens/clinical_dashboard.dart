import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/allergy_checking_service.dart';
import '../../theme/app_theme.dart';
import 'follow_ups_screen.dart';
import 'patients_screen.dart';
import 'notifications_screen.dart';
import 'vital_signs_screen.dart';

/// Comprehensive Clinical Dashboard
/// Provides real-time overview of patient care, alerts, and clinical decision support
class ClinicalDashboard extends ConsumerStatefulWidget {
  const ClinicalDashboard({super.key, this.onMenuTap});
  
  final VoidCallback? onMenuTap;

  @override
  ConsumerState<ClinicalDashboard> createState() => _ClinicalDashboardState();
}

class _ClinicalDashboardState extends ConsumerState<ClinicalDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // Dashboard data cache
  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isLoading = true);
    ref.invalidate(doctorDbProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
    return FutureBuilder<DashboardData>(
      future: _loadDashboardData(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _dashboardData == null) {
          return const LoadingState();
        }
        
        final data = snapshot.data ?? _dashboardData ?? DashboardData.empty();
        _dashboardData = data;
        
        return _buildContent(context, db, data);
      },
    );
  }

  Future<DashboardData> _loadDashboardData(DoctorDatabase db) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final yesterday = startOfDay.subtract(const Duration(days: 1));
    
    // Optimized parallel data loading - only load what's needed
    final results = await Future.wait([
      // Get patient counts and at-risk patients only
      db.getPatientCount(),
      db.getPatientsByRiskLevel(5), // High risk patients (riskLevel >= 4, but we'll filter)
      db.getAppointmentsForDay(today),
      // Only load recent vitals (last 24 hours) instead of all
      db.getVitalSignsForDateRange(yesterday, DateTime.now()),
      db.getPendingFollowUps(),
      db.getOverdueFollowUps(),
      // Only load ongoing treatments instead of all
      db.getOngoingTreatmentOutcomes(),
      // Only load recent prescriptions (last 30 days) for drug interaction checks
      db.getRecentPrescriptions(DateTime.now().subtract(const Duration(days: 30))),
    ]);
    
    final totalPatients = results[0] as int;
    final highRiskPatients = results[1] as List<Patient>;
    final todayAppointments = results[2] as List<Appointment>;
    final recentVitals = results[3] as List<VitalSign>;
    final pendingFollowUps = results[4] as List<ScheduledFollowUp>;
    final overdueFollowUps = results[5] as List<ScheduledFollowUp>;
    final ongoingTreatments = results[6] as List<TreatmentOutcome>;
    final recentPrescriptions = results[7] as List<Prescription>;
    
    // Get additional patient data only if needed
    final atRiskPatients = highRiskPatients.where((p) => p.riskLevel >= 4).toList();
    
    // Collect patient IDs needed for alerts and display
    final patientIdsForAlerts = <int>{};
    patientIdsForAlerts.addAll(recentVitals.map((v) => v.patientId));
    patientIdsForAlerts.addAll(recentPrescriptions.map((p) => p.patientId));
    patientIdsForAlerts.addAll(atRiskPatients.map((p) => p.id));
    
    // Load only patients needed for alerts and display
    final patients = <Patient>[];
    if (patientIdsForAlerts.isNotEmpty) {
      patients.addAll(await (db.select(db.patients)
        ..where((p) => p.id.isIn(patientIdsForAlerts)))
        .get());
    }
    // Add at-risk patients that might not be in the set
    for (final p in atRiskPatients) {
      if (!patients.any((patient) => patient.id == p.id)) {
        patients.add(p);
      }
    }
    
    final activePatients = patients.where((p) => p.riskLevel < 4).toList();
    
    // Process appointments
    final scheduledAppts = todayAppointments.where((a) => 
        a.status == 'scheduled' || a.status == 'pending').toList();
    final missedAppts = todayAppointments.where((a) => 
        a.status == 'missed' || a.status == 'cancelled').toList();
    final completedAppts = todayAppointments.where((a) => 
        a.status == 'completed').toList();
    
    // Process vital signs - already filtered to last 24 hours
    final abnormalVitals = _findAbnormalVitals(recentVitals, patients);
    
    // Get improved and worsened treatments (only if needed for display)
    final improvedTreatments = await db.getTreatmentOutcomesByOutcome('improved', limit: 10);
    final worsenedTreatments = await db.getTreatmentOutcomesByOutcome('worsened', limit: 10);
    
    // Process drug interactions and allergies (using optimized patient list)
    final alerts = await _checkClinicalAlerts(patients, recentPrescriptions, db);
    
    return DashboardData(
      patients: patients,
      atRiskPatients: atRiskPatients,
      activePatients: activePatients,
      todayAppointments: todayAppointments,
      scheduledAppointments: scheduledAppts,
      missedAppointments: missedAppts,
      completedAppointments: completedAppts,
      abnormalVitals: abnormalVitals,
      pendingFollowUps: pendingFollowUps,
      overdueFollowUps: overdueFollowUps,
      ongoingTreatments: ongoingTreatments,
      improvedTreatments: improvedTreatments,
      worsenedTreatments: worsenedTreatments,
      prescriptions: recentPrescriptions,
      clinicalAlerts: alerts,
    );
  }

  List<VitalSignAlert> _findAbnormalVitals(List<VitalSign> vitals, List<Patient> patients) {
    final alerts = <VitalSignAlert>[];
    final patientMap = {for (var p in patients) p.id: p};
    
    for (final vital in vitals) {
      final patient = patientMap[vital.patientId];
      if (patient == null) continue;
      
      // Check for abnormal readings
      if (vital.systolicBp != null && (vital.systolicBp! >= 140 || vital.systolicBp! < 90)) {
        alerts.add(VitalSignAlert(
          patient: patient,
          vital: vital,
          alertType: vital.systolicBp! >= 140 ? 'High Blood Pressure' : 'Low Blood Pressure',
          severity: vital.systolicBp! >= 180 ? AlertSeverity.critical : AlertSeverity.warning,
          value: '${vital.systolicBp?.toInt()}/${vital.diastolicBp?.toInt()} mmHg',
        ));
      }
      
      if (vital.oxygenSaturation != null && vital.oxygenSaturation! < 95) {
        alerts.add(VitalSignAlert(
          patient: patient,
          vital: vital,
          alertType: 'Low Oxygen Saturation',
          severity: vital.oxygenSaturation! < 90 ? AlertSeverity.critical : AlertSeverity.warning,
          value: '${vital.oxygenSaturation?.toInt()}%',
        ));
      }
      
      if (vital.temperature != null && (vital.temperature! >= 38.0 || vital.temperature! < 36.0)) {
        alerts.add(VitalSignAlert(
          patient: patient,
          vital: vital,
          alertType: vital.temperature! >= 38.0 ? 'Fever' : 'Hypothermia',
          severity: vital.temperature! >= 39.5 ? AlertSeverity.critical : AlertSeverity.warning,
          value: '${vital.temperature?.toStringAsFixed(1)}°C',
        ));
      }
      
      if (vital.heartRate != null && (vital.heartRate! > 100 || vital.heartRate! < 60)) {
        alerts.add(VitalSignAlert(
          patient: patient,
          vital: vital,
          alertType: vital.heartRate! > 100 ? 'Tachycardia' : 'Bradycardia',
          severity: (vital.heartRate! > 120 || vital.heartRate! < 50) 
              ? AlertSeverity.critical : AlertSeverity.warning,
          value: '${vital.heartRate} bpm',
        ));
      }
    }
    
    return alerts;
  }

  Future<List<ClinicalAlert>> _checkClinicalAlerts(
    List<Patient> patients, 
    List<Prescription> prescriptions,
    DoctorDatabase db,
  ) async {
    final alerts = <ClinicalAlert>[];
    
    for (final patient in patients) {
      // Check allergies
      if (patient.allergies.isNotEmpty) {
        final allergyList = patient.allergies.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
        if (allergyList.isNotEmpty) {
          alerts.add(ClinicalAlert(
            patient: patient,
            alertType: ClinicalAlertType.allergy,
            title: 'Known Allergies',
            message: allergyList.join(', '),
            severity: AlertSeverity.warning,
          ));
        }
      }
      
      // Check recent prescriptions for drug interactions
      final patientRx = prescriptions.where((p) => p.patientId == patient.id).toList();
      if (patientRx.length >= 2) {
        // Check for potential interactions between recent prescriptions
        for (int i = 0; i < patientRx.length && i < 3; i++) {
          try {
            // V5: Load medications from normalized table
            final items = await db.getMedicationsForPrescriptionCompat(patientRx[i].id);
            for (final item in items) {
              final drugName = (item['name'] ?? item['drug'] ?? '') as String;
              if (drugName.isNotEmpty && patient.allergies.isNotEmpty) {
                final result = AllergyCheckingService.checkDrugSafety(
                  allergyHistory: patient.allergies,
                  proposedDrug: drugName,
                );
                if (result.hasConcern) {
                  alerts.add(ClinicalAlert(
                    patient: patient,
                    alertType: ClinicalAlertType.drugAllergy,
                    title: 'Drug-Allergy Concern',
                    message: '${drugName} - ${result.message}',
                    severity: AlertSeverity.critical,
                  ));
                }
              }
            }
          } catch (_) {
            // Skip malformed prescription data
          }
        }
      }
    }
    
    return alerts;
  }

  Widget _buildContent(BuildContext context, DoctorDatabase db, DashboardData data) {
    final isDark = context.isDarkMode;
    final isCompact = context.isCompact;
    final padding = context.responsivePadding;

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(context, isCompact, data),
          ),
          
          // Alert Summary Bar
          if (data.hasAlerts)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildAlertSummaryBar(context, data, isCompact),
              ),
            ),
          
          SliverToBoxAdapter(child: SizedBox(height: isCompact ? 16 : 20)),
          
          // Patient Overview Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildPatientOverview(context, data, isCompact),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
          
          // Today's Appointments Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildAppointmentsSection(context, db, data, isCompact),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
          
          // Vital Signs Alerts
          if (data.abnormalVitals.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildVitalSignsAlerts(context, data, isCompact),
              ),
            ),
          
          if (data.abnormalVitals.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
          
          // Overdue Follow-ups
          if (data.overdueFollowUps.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildOverdueFollowUps(context, db, data, isCompact),
              ),
            ),
          
          if (data.overdueFollowUps.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
          
          // Treatment Progress
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildTreatmentProgress(context, data, isCompact),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: isCompact ? 20 : 28)),
          
          // Clinical Decision Support
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildClinicalDecisionSupport(context, data, isCompact),
            ),
          ),
          
          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompact, DashboardData data) {
    final isDark = context.isDarkMode;
    final profile = ref.watch(doctorSettingsProvider).profile;
    final now = DateTime.now();
    
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny_rounded;
    Color greetingColor = AppColors.warning;
    
    if (now.hour >= 12 && now.hour < 17) {
      greeting = 'Good Afternoon';
      greetingColor = AppColors.quickActionOrange;
    } else if (now.hour >= 17) {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
      greetingColor = AppColors.billing;
    }

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button (always show when navigated to this screen)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextPrimary.withValues(alpha: 0.08)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  ),
                  child: Icon(Icons.arrow_back_rounded, 
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Menu button (optional)
              if (widget.onMenuTap != null)
                GestureDetector(
                  onTap: widget.onMenuTap,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.menu_rounded, color: AppColors.primary, size: 22),
                  ),
                ),
              const Spacer(),
              // Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, 
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, MMM d').format(now),
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Alert indicator
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                        ? AppColors.darkTextPrimary.withValues(alpha: 0.08)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      ),
                      child: Icon(Icons.notifications_outlined, 
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 22),
                    ),
                    if (data.hasAlerts)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.surface,
                                width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 28),
          // Greeting
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [greetingColor.withValues(alpha: 0.2), greetingColor.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(greetingIcon, color: greetingColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    )),
                    Text(
                      'Dr. ${profile.name.isNotEmpty ? profile.name : "Doctor"}',
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 26, fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Patients', '${data.patients.length}', Icons.people_outline),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('Today', '${data.todayAppointments.length}', Icons.event_note_outlined),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('Alerts', '${data.totalAlerts}', Icons.warning_amber_rounded,
                    isAlert: data.totalAlerts > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, {bool isAlert = false}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isAlert ? AppColors.error : AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: isAlert ? AppColors.error : AppColors.primary,
        )),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildQuickStatDivider(bool isDark) {
    return Container(
      height: 40, width: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildAlertSummaryBar(BuildContext context, DashboardData data, bool isCompact) {
    final criticalCount = data.abnormalVitals.where((v) => v.severity == AlertSeverity.critical).length +
        data.clinicalAlerts.where((a) => a.severity == AlertSeverity.critical).length;
    final warningCount = data.abnormalVitals.where((v) => v.severity == AlertSeverity.warning).length +
        data.clinicalAlerts.where((a) => a.severity == AlertSeverity.warning).length;
    
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      gradient: LinearGradient(
        colors: criticalCount > 0 
            ? [
                AppColors.error.withValues(alpha: 0.15),
                AppColors.error.withValues(alpha: 0.05)
              ]
            : [
                AppColors.warning.withValues(alpha: 0.15),
                AppColors.warning.withValues(alpha: 0.05)
              ],
      ),
      borderRadius: BorderRadius.circular(16),
      borderColor: criticalCount > 0 
          ? AppColors.error.withValues(alpha: 0.3)
          : AppColors.warning.withValues(alpha: 0.3),
      borderWidth: 1,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: criticalCount > 0 ? AppColors.error : AppColors.warning,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: AppColors.surface,
              size: AppIconSize.sm,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criticalCount > 0 ? 'Critical Alerts Require Attention' : 'Warnings Need Review',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: criticalCount > 0
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                ),
                Text(
                  '$criticalCount critical • $warningCount warnings • ${data.overdueFollowUps.length} overdue follow-ups',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, 
              color: criticalCount > 0
                  ? AppColors.error
                  : AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildPatientOverview(BuildContext context, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Patient Overview', () {
          Navigator.push(context, AppRouter.route(const PatientsScreen()));
        }, isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        Row(
          children: [
            Expanded(child: _buildPatientCard(
              'Active', data.activePatients.length, Icons.person_outline,
              const Color(0xFF10B981), isDark, isCompact,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildPatientCard(
              'At Risk', data.atRiskPatients.length, Icons.warning_amber_rounded,
              const Color(0xFFEF4444), isDark, isCompact,
              highlight: data.atRiskPatients.isNotEmpty,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildPatientCard(
              'Total', data.patients.length, Icons.people_outline,
              const Color(0xFF6366F1), isDark, isCompact,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientCard(String label, int count, IconData icon, Color color, 
      bool isDark, bool isCompact, {bool highlight = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.5) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
          width: highlight ? 2 : 1,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text('$count', style: TextStyle(
            fontSize: isCompact ? 22 : 26, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(BuildContext context, DoctorDatabase db, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Today's Appointments", () {}, isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        // Stats row
        Row(
          children: [
            Expanded(child: _buildAppointmentStat('Scheduled', data.scheduledAppointments.length, 
                const Color(0xFF3B82F6), isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildAppointmentStat('Completed', data.completedAppointments.length, 
                const Color(0xFF10B981), isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildAppointmentStat('Missed', data.missedAppointments.length, 
                const Color(0xFFEF4444), isDark, highlight: data.missedAppointments.isNotEmpty)),
          ],
        ),
        if (data.scheduledAppointments.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Upcoming appointments list
          ...data.scheduledAppointments.take(3).map((appt) => 
              _buildAppointmentItem(context, db, appt, isDark, isCompact)),
        ],
        if (data.todayAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_rounded, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Text('No appointments today', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentStat(String label, int count, Color color, bool isDark, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? color : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15))),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: color,
          )),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, DoctorDatabase db, Appointment appt, bool isDark, bool isCompact) {
    return FutureBuilder<Patient?>(
      future: db.getPatientById(appt.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        final time = DateFormat('h:mm a').format(appt.appointmentDateTime);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient != null ? '${patient.firstName} ${patient.lastName}' : 'Patient #${appt.patientId}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, 
                          color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    Text(appt.reason.isNotEmpty ? appt.reason : 'General consultation',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalSignsAlerts(BuildContext context, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    final criticalAlerts = data.abnormalVitals.where((v) => v.severity == AlertSeverity.critical).toList();
    final warningAlerts = data.abnormalVitals.where((v) => v.severity == AlertSeverity.warning).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Vital Signs Alerts', () {
          // Show all vital alerts in the current list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigate to specific patient to view vital signs'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }, isCompact, 
            badgeCount: data.abnormalVitals.length, badgeColor: const Color(0xFFEF4444)),
        SizedBox(height: isCompact ? 12 : 16),
        // Critical alerts first
        ...criticalAlerts.take(3).map((alert) => _buildVitalAlertCard(context, alert, isDark, isCompact)),
        // Then warnings
        ...warningAlerts.take(2).map((alert) => _buildVitalAlertCard(context, alert, isDark, isCompact)),
        if (data.abnormalVitals.length > 5)
          Center(
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to specific patient to view all vital signs'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.expand_more),
              label: Text('View ${data.abnormalVitals.length - 5} more alerts'),
            ),
          ),
      ],
    );
  }

  Widget _buildVitalAlertCard(BuildContext context, VitalSignAlert alert, bool isDark, bool isCompact) {
    final isCritical = alert.severity == AlertSeverity.critical;
    final color = isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final timeAgo = _formatTimeAgo(alert.vital.recordedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCritical ? Icons.error_rounded : Icons.warning_rounded, 
              color: Colors.white, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(alert.alertType, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(alert.value, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: color,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.patient.firstName} ${alert.patient.lastName} • $timeAgo',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => VitalSignsScreen(patientId: alert.patient.id, patientName: '${alert.patient.firstName} ${alert.patient.lastName}'),
            )),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueFollowUps(BuildContext context, DoctorDatabase db, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Overdue Follow-ups', () {
          Navigator.push(context, AppRouter.route(const FollowUpsScreen()));
        }, isCompact, badgeCount: data.overdueFollowUps.length, badgeColor: const Color(0xFFEF4444)),
        SizedBox(height: isCompact ? 12 : 16),
        ...data.overdueFollowUps.take(4).map((followUp) => 
            _buildFollowUpItem(context, db, followUp, isDark, isCompact)),
      ],
    );
  }

  Widget _buildFollowUpItem(BuildContext context, DoctorDatabase db, ScheduledFollowUp followUp, bool isDark, bool isCompact) {
    final daysOverdue = DateTime.now().difference(followUp.scheduledDate).inDays;
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(followUp.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient != null ? '${patient.firstName} ${patient.lastName}' : 'Patient #${followUp.patientId}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, 
                          color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    Text(followUp.reason, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$daysOverdue days', style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444),
                )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreatmentProgress(BuildContext context, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    final total = data.ongoingTreatments.length + data.improvedTreatments.length + data.worsenedTreatments.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Treatment Progress', () {
          // Navigate to patients screen to view individual treatments
          Navigator.push(context, AppRouter.route(const PatientsScreen()));
        }, isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTreatmentStat('Ongoing', data.ongoingTreatments.length, const Color(0xFF3B82F6), Icons.autorenew_rounded),
                  _buildTreatmentStatDivider(isDark),
                  _buildTreatmentStat('Improved', data.improvedTreatments.length, const Color(0xFF10B981), Icons.trending_up_rounded),
                  _buildTreatmentStatDivider(isDark),
                  _buildTreatmentStat('Worsened', data.worsenedTreatments.length, const Color(0xFFEF4444), Icons.trending_down_rounded),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 16),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      if (data.improvedTreatments.isNotEmpty)
                        Expanded(
                          flex: data.improvedTreatments.length,
                          child: Container(height: 8, color: const Color(0xFF10B981)),
                        ),
                      if (data.ongoingTreatments.isNotEmpty)
                        Expanded(
                          flex: data.ongoingTreatments.length,
                          child: Container(height: 8, color: const Color(0xFF3B82F6)),
                        ),
                      if (data.worsenedTreatments.isNotEmpty)
                        Expanded(
                          flex: data.worsenedTreatments.length,
                          child: Container(height: 8, color: const Color(0xFFEF4444)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentStat(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTreatmentStatDivider(bool isDark) {
    return Container(
      height: 50, width: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildClinicalDecisionSupport(BuildContext context, DashboardData data, bool isCompact) {
    final isDark = context.isDarkMode;
    final allergyAlerts = data.clinicalAlerts.where((a) => a.alertType == ClinicalAlertType.allergy).toList();
    final drugAlerts = data.clinicalAlerts.where((a) => 
        a.alertType == ClinicalAlertType.drugInteraction || a.alertType == ClinicalAlertType.drugAllergy).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Clinical Decision Support', () {}, isCompact),
        SizedBox(height: isCompact ? 12 : 16),
        Row(
          children: [
            Expanded(child: _buildCDSCard(
              'Drug Interactions',
              '${drugAlerts.length} active',
              Icons.medication_rounded,
              const Color(0xFFEF4444),
              isDark,
              drugAlerts.isNotEmpty,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildCDSCard(
              'Allergy Alerts',
              '${allergyAlerts.length} patients',
              Icons.warning_amber_rounded,
              const Color(0xFFF59E0B),
              isDark,
              allergyAlerts.isNotEmpty,
            )),
          ],
        ),
        if (drugAlerts.isNotEmpty || allergyAlerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Alerts', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                )),
                const SizedBox(height: 10),
                ...data.clinicalAlerts.take(3).map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: alert.severity == AlertSeverity.critical 
                              ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${alert.patient.firstName} ${alert.patient.lastName}: ${alert.title}',
                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCDSCard(String title, String subtitle, IconData icon, Color color, bool isDark, bool hasAlerts) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: hasAlerts 
            ? LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)])
            : null,
        color: hasAlerts ? null : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAlerts ? color.withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: hasAlerts ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )),
          Text(subtitle, style: TextStyle(
            fontSize: 12, color: hasAlerts ? color : AppColors.textSecondary,
            fontWeight: hasAlerts ? FontWeight.w600 : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onViewAll, bool isCompact,
      {int? badgeCount, Color? badgeColor}) {
    final isDark = context.isDarkMode;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(
              fontSize: isCompact ? 18 : 20, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            )),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badgeCount', style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                )),
              ),
            ],
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
                )),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================================
// Data Models
// ============================================================================

class DashboardData {
  final List<Patient> patients;
  final List<Patient> atRiskPatients;
  final List<Patient> activePatients;
  final List<Appointment> todayAppointments;
  final List<Appointment> scheduledAppointments;
  final List<Appointment> missedAppointments;
  final List<Appointment> completedAppointments;
  final List<VitalSignAlert> abnormalVitals;
  final List<ScheduledFollowUp> pendingFollowUps;
  final List<ScheduledFollowUp> overdueFollowUps;
  final List<TreatmentOutcome> ongoingTreatments;
  final List<TreatmentOutcome> improvedTreatments;
  final List<TreatmentOutcome> worsenedTreatments;
  final List<Prescription> prescriptions;
  final List<ClinicalAlert> clinicalAlerts;

  DashboardData({
    required this.patients,
    required this.atRiskPatients,
    required this.activePatients,
    required this.todayAppointments,
    required this.scheduledAppointments,
    required this.missedAppointments,
    required this.completedAppointments,
    required this.abnormalVitals,
    required this.pendingFollowUps,
    required this.overdueFollowUps,
    required this.ongoingTreatments,
    required this.improvedTreatments,
    required this.worsenedTreatments,
    required this.prescriptions,
    required this.clinicalAlerts,
  });

  factory DashboardData.empty() => DashboardData(
    patients: [],
    atRiskPatients: [],
    activePatients: [],
    todayAppointments: [],
    scheduledAppointments: [],
    missedAppointments: [],
    completedAppointments: [],
    abnormalVitals: [],
    pendingFollowUps: [],
    overdueFollowUps: [],
    ongoingTreatments: [],
    improvedTreatments: [],
    worsenedTreatments: [],
    prescriptions: [],
    clinicalAlerts: [],
  );

  bool get hasAlerts => abnormalVitals.isNotEmpty || overdueFollowUps.isNotEmpty || 
      clinicalAlerts.any((a) => a.severity == AlertSeverity.critical);
  
  int get totalAlerts => abnormalVitals.length + overdueFollowUps.length + 
      clinicalAlerts.where((a) => a.severity == AlertSeverity.critical).length;
}

class VitalSignAlert {
  final Patient patient;
  final VitalSign vital;
  final String alertType;
  final AlertSeverity severity;
  final String value;

  VitalSignAlert({
    required this.patient,
    required this.vital,
    required this.alertType,
    required this.severity,
    required this.value,
  });
}

class ClinicalAlert {
  final Patient patient;
  final ClinicalAlertType alertType;
  final String title;
  final String message;
  final AlertSeverity severity;

  ClinicalAlert({
    required this.patient,
    required this.alertType,
    required this.title,
    required this.message,
    required this.severity,
  });
}

enum AlertSeverity { info, warning, critical }
enum ClinicalAlertType { allergy, drugInteraction, drugAllergy, labResult, vitalSign }

