import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/core.dart';
import 'core/routing/app_router.dart';
import 'providers/db_provider.dart';
import 'services/localization_service.dart';
import 'services/logger_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/appointments_screen.dart';
import 'ui/screens/billing_screen.dart';
import 'ui/screens/clinical_dashboard.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/follow_ups_screen.dart';
import 'ui/screens/medical_records_list_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/patients_screen.dart';

class DoctorApp extends ConsumerWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final localization = ref.watch(localizationProvider);
    final isDarkMode = appSettings.settings.darkModeEnabled;
    final isOnboardingComplete = appSettings.settings.onboardingComplete;
    final isLoaded = appSettings.isLoaded;
    
    log.d('APP', 'Building app - loaded: $isLoaded, onboarding: $isOnboardingComplete, dark: $isDarkMode, locale: ${localization.languageCode}');
    
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: localization.currentLocale,
      supportedLocales: LocalizationService.supportedLocales,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorObservers: [_LoggingNavigatorObserver()],
      home: !isLoaded 
          ? const _SplashScreen()
          : isOnboardingComplete 
              ? const HomeShell() 
              : const OnboardingScreen(),
    );
  }
}

/// Navigator observer for logging screen transitions
class _LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name ?? route.runtimeType.toString();
    final prevName = previousRoute?.settings.name ?? 'none';
    log
      ..logNavigation(prevName, name)
      ..trackScreen(name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final name = previousRoute?.settings.name ?? 'back';
    log.d('NAV', 'Popped to: $name');
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
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
  int _pendingAppointments = 0;
  int _unpaidInvoices = 0;
  int _overdueFollowUps = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onMenuTap: _openDrawer),
      const PatientsScreen(),
      const AppointmentsScreen(),
    ];
    _loadBadgeCounts();
  }

  Future<void> _loadBadgeCounts() async {
    ref.read(doctorDbProvider).whenData((db) async {
      final todayAppts = await db.getAppointmentsForDay(DateTime.now());
      final pendingCount = todayAppts.where((a) => 
        a.status == 'pending' || a.status == 'scheduled',
      ).length;
      
      final invoices = await db.getAllInvoices();
      final unpaidCount = invoices.where((i) => 
        i.paymentStatus != 'Paid',
      ).length;
      
      final overdueFollowUps = await db.getOverdueFollowUps();
      final overdueCount = overdueFollowUps.length;
      
      if (mounted) {
        setState(() {
          _pendingAppointments = pendingCount;
          _unpaidInvoices = unpaidCount;
          _overdueFollowUps = overdueCount;
        });
      }
    });
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
      bottomNavigationBar: DecoratedBox(
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
                _buildNavItem(0, Icons.space_dashboard_rounded, Icons.space_dashboard_outlined, AppStrings.navHome, AppColors.primary, 0),
                _buildNavItem(1, Icons.people_rounded, Icons.people_outlined, AppStrings.navPatients, AppColors.patients, 0),
                _buildNavItem(2, Icons.calendar_month_rounded, Icons.calendar_month_outlined, AppStrings.navAppointments, AppColors.appointments, _pendingAppointments),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData icon, String label, Color activeColor, int badgeCount) {
    final isSelected = _index == index;
    final isDarkMode = context.isDarkMode;
    final unselectedColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _index = index);
        // Refresh badge counts when switching tabs
        _loadBadgeCounts();
      },
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: AppDuration.fast,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeColor : unselectedColor,
                    size: isSelected ? 26 : AppIconSize.md,
                  ),
                ),
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: AnimatedBadge(
                      count: badgeCount,
                      color: activeColor,
                      size: 16,
                    ),
                  ),
              ],
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
    final appSettings = ref.watch(appSettingsProvider);
    final profile = doctorSettings.profile;
    final isDarkMode = context.isDarkMode;
    final enabledRecordTypes = appSettings.settings.enabledMedicalRecordTypes;
    final isPsychiatricEnabled = enabledRecordTypes.contains('psychiatric_assessment');
    
    return Drawer(
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
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
                      context
                        ..pop<void>()
                        ..pushNamed<void>(AppRoutes.doctorProfile);
                    },
                    color: const Color(0xFF6366F1),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.settings_outlined,
                    title: AppStrings.settings,
                    subtitle: 'App preferences',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..pushNamed<void>(AppRoutes.settings);
                    },
                    color: const Color(0xFF64748B),
                    isDark: isDarkMode,
                  ),
                  
                  const SizedBox(height: 16),
                  _buildSectionTitle('QUICK ACTIONS', isDarkMode),
                  const SizedBox(height: 8),
                  
                  _buildModernDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Clinical Dashboard',
                    subtitle: 'Full clinical overview',
                    onTap: () {
                      context.pop<void>();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const ClinicalDashboard()),
                      );
                    },
                    color: const Color(0xFF8B5CF6),
                    isDark: isDarkMode,
                  ),
                  
                  _buildModernDrawerItem(
                    icon: Icons.folder_special_rounded,
                    title: 'Medical Records',
                    subtitle: 'View all records',
                    onTap: () {
                      context.pop<void>();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const MedicalRecordsListScreen()),
                      );
                    },
                    color: const Color(0xFF10B981),
                    isDark: isDarkMode,
                  ),
                  
                  _buildModernDrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: AppStrings.billing,
                    subtitle: 'Invoices & payments',
                    onTap: () {
                      context.pop<void>();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const BillingScreen()),
                      );
                    },
                    color: AppColors.billing,
                    isDark: isDarkMode,
                    badge: _unpaidInvoices > 0 ? '$_unpaidInvoices' : null,
                  ),
                  
                  _buildModernDrawerItem(
                    icon: Icons.event_repeat_rounded,
                    title: 'Follow-ups',
                    subtitle: 'Manage follow-ups',
                    onTap: () {
                      context.pop<void>();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const FollowUpsScreen()),
                      );
                    },
                    color: Colors.orange,
                    isDark: isDarkMode,
                    badge: _overdueFollowUps > 0 ? '$_overdueFollowUps' : null,
                  ),
                  
                  _buildModernDrawerItem(
                    icon: Icons.warning_rounded,
                    title: 'Allergy Management',
                    subtitle: 'Patient allergies',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToAllergyManagement();
                    },
                    color: const Color(0xFFDC2626),
                    isDark: isDarkMode,
                  ),
                  
                  if (isPsychiatricEnabled)
                    _buildModernDrawerItem(
                      icon: Icons.psychology_rounded,
                      title: AppStrings.psychiatricAssessment,
                      subtitle: 'Patient assessment',
                      onTap: () {
                        context
                          ..pop<void>()
                          ..pushNamed<void>(AppRoutes.psychiatricAssessment);
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
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToNotifications();
                    },
                    color: const Color(0xFFF59E0B),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.message_outlined,
                    title: 'Communications',
                    subtitle: 'Messages & calls',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToCommunications();
                    },
                    color: const Color(0xFF6366F1),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.menu_book_outlined,
                    title: 'Medical Reference',
                    subtitle: 'Drugs & warnings',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToMedicalReference();
                    },
                    color: const Color(0xFF8B5CF6),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    subtitle: 'Trends & insights',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToClinicalAnalytics();
                    },
                    color: const Color(0xFF3B82F6),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.cloud_done_outlined,
                    title: 'Offline Sync',
                    subtitle: 'Manage sync',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToOfflineSync();
                    },
                    color: const Color(0xFFEA580C),
                    isDark: isDarkMode,
                  ),
                  _buildModernDrawerItem(
                    icon: Icons.download_outlined,
                    title: 'Data Export',
                    subtitle: 'Reports & export',
                    onTap: () {
                      context
                        ..pop<void>()
                        ..goToDataExport();
                    },
                    color: const Color(0xFF8B5CF6),
                    isDark: isDarkMode,
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        SizedBox(width: 10),
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
