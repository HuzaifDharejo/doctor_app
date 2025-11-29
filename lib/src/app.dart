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
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D3F)]
                : [Colors.white, const Color(0xFFF8FAFF)],
          ),
        ),
        child: Column(
          children: [
            // Modern gradient header with profile
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar with glow effect
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            profile.initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      profile.specialization.isNotEmpty ? profile.specialization : AppStrings.setupProfile,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildModernDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: AppStrings.doctorProfile,
                    subtitle: 'Manage your profile',
                    onTap: () {
                      context.pop();
                      context.pushNamed(AppRoutes.doctorProfile);
                    },
                    color: const Color(0xFF6366F1),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.settings_outlined,
                    title: AppStrings.settings,
                    subtitle: 'App preferences',
                    onTap: () {
                      context.pop();
                      context.pushNamed(AppRoutes.settings);
                    },
                    color: const Color(0xFF64748B),
                    isDark: isDarkMode,
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionTitle('QUICK ACTIONS', isDarkMode),
                  const SizedBox(height: 8),
                  
                  _buildModernDrawerItem(
                    icon: Icons.psychology_rounded,
                    title: AppStrings.psychiatricAssessment,
                    subtitle: 'Patient assessment',
                    onTap: () {
                      context.pop();
                      context.pushNamed(AppRoutes.psychiatricAssessment);
                    },
                    color: const Color(0xFF0EA5E9),
                    isDark: isDarkMode,
                  ),

                  
                  const SizedBox(height: 16),
                  _buildSectionTitle('MORE', isDarkMode),
                  const SizedBox(height: 8),
                  
                  _buildModernDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: AppStrings.notifications,
                    subtitle: 'Alerts & reminders',
                    onTap: () {},
                    color: const Color(0xFFF59E0B),
                    isDark: isDarkMode,
                    badge: '3',
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.cloud_sync_outlined,
                    title: AppStrings.backupSync,
                    subtitle: 'Cloud backup',
                    onTap: () {},
                    color: const Color(0xFF14B8A6),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: AppStrings.helpSupport,
                    subtitle: 'Get help',
                    onTap: () {},
                    color: const Color(0xFF06B6D4),
                    isDark: isDarkMode,
                  ),
                ],
              ),
            ),
            
            // Bottom logout section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
                border: Border(
                  top: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.logout,
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
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
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark 
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark 
                        ? const Color(0xFF64748B)
                        : const Color(0xFFCBD5E1),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
