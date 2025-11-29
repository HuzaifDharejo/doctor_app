import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/core.dart';
import 'core/routing/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/db_provider.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/patients_screen.dart';
import 'ui/screens/appointments_screen.dart';
import 'ui/screens/prescriptions_screen.dart';
import 'ui/screens/billing_screen.dart';

class DoctorApp extends ConsumerWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final isDarkMode = appSettings.settings.darkModeEnabled;
    
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onMenuTap: _openDrawer),
      const PatientsScreen(),
      const AppointmentsScreen(),
      const PrescriptionsScreen(),
      const BillingScreen(),
    ];
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? context.colorScheme.surface 
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, AppStrings.navHome, AppColors.primary),
                _buildNavItem(1, Icons.people_rounded, Icons.people_outlined, AppStrings.navPatients, AppColors.patients),
                _buildNavItem(2, Icons.calendar_month_rounded, Icons.calendar_month_outlined, AppStrings.navAppointments, AppColors.appointments),
                _buildNavItem(3, Icons.medication_rounded, Icons.medication_outlined, AppStrings.navPrescriptions, AppColors.prescriptions),
                _buildNavItem(4, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, AppStrings.navBilling, AppColors.billing),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData icon, String label, Color activeColor) {
    final isSelected = _index == index;
    final isDarkMode = context.isDarkMode;
    final unselectedColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: AppDuration.short,
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? AppSpacing.md : AppSpacing.sm, 
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    activeColor.withValues(alpha: 0.2),
                    activeColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDuration.fast,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : unselectedColor,
                size: isSelected ? 26 : AppIconSize.md,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AnimatedDefaultTextStyle(
              duration: AppDuration.fast,
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : unselectedColor,
              ),
              child: Text(label),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.xxs),
              AnimatedContainer(
                duration: AppDuration.fast,
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final doctorSettings = ref.watch(doctorSettingsProvider);
    final profile = doctorSettings.profile;
    final isDarkMode = context.isDarkMode;
    
    return Drawer(
      child: Container(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 60, AppSpacing.lg, AppSpacing.xl),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with border
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: AppSpacing.sm,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        profile.initials,
                        style: const TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          profile.specialization.isNotEmpty ? profile.specialization : AppStrings.setupProfile,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: AppFontSize.xs,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildDrawerItem(Icons.person_outline_rounded, AppStrings.doctorProfile, () {
              context.pop();
              context.pushNamed(AppRoutes.doctorProfile);
            }, color: AppColors.primary),
            _buildDrawerItem(Icons.settings_rounded, AppStrings.settings, () {
              context.pop();
              context.pushNamed(AppRoutes.settings);
            }, color: AppColors.textSecondary),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.xs, bottom: AppSpacing.xs),
              child: Text(
                AppStrings.quickAccess,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? AppColors.darkTextHint : AppColors.textHint,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildDrawerItem(Icons.psychology_rounded, AppStrings.psychiatricAssessment, () {
              context.pop();
              context.pushNamed(AppRoutes.psychiatricAssessment);
            }, color: AppColors.info),
            _buildDrawerItem(Icons.medication_rounded, AppStrings.addPrescription, () {
              context.pop();
              context.pushNamed(AppRoutes.addPrescription);
            }, color: AppColors.prescriptions),
            _buildDrawerItem(Icons.receipt_long_rounded, AppStrings.createInvoice, () {
              context.pop();
              context.pushNamed(AppRoutes.addInvoice);
            }, color: AppColors.billing),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Divider(),
            ),
            _buildDrawerItem(Icons.notifications_rounded, AppStrings.notifications, () {}, color: AppColors.warning),
            _buildDrawerItem(Icons.cloud_sync_rounded, AppStrings.backupSync, () {}, color: AppColors.appointments),
            _buildDrawerItem(Icons.help_outline_rounded, AppStrings.helpSupport, () {}, color: AppColors.accent),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Divider(),
            ),
            _buildDrawerItem(Icons.logout_rounded, AppStrings.logout, () {}, color: AppColors.error, isDestructive: true),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color, bool isDestructive = false}) {
    final isDarkMode = context.isDarkMode;
    final itemColor = color ?? (isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(icon, color: itemColor, size: AppIconSize.sm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? AppColors.error : (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.sm,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? AppColors.darkTextHint : AppColors.textHint,
                  size: AppIconSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
