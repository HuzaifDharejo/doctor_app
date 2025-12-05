import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../core/theme/design_tokens.dart';

class UserManualScreen extends ConsumerStatefulWidget {
  const UserManualScreen({super.key});

  @override
  ConsumerState<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends ConsumerState<UserManualScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 7) {
      _fadeController.reverse().then((_) {
        _fadeController.forward();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _fadeController.reverse().then((_) {
        _fadeController.forward();
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D3F)]
                      : [Colors.white, const Color(0xFFF8FAFF)],
                ),
              ),
            ),
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFFF8FAFC), surfaceColor],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'User Manual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Complete Guide',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1}/8',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Page view
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _fadeController.forward(from: 0);
                _scaleController.forward(from: 0);
              },
              children: [
                _buildWelcomePage(isDark),
                _buildPatientManagementPage(isDark),
                _buildAppointmentsPage(isDark),
                _buildPrescriptionsPage(isDark),
                _buildBillingPage(isDark),
                _buildMedicalRecordsPage(isDark),
                _buildSettingsPage(isDark),
                _buildTipsPage(isDark),
              ],
            ),
          ),
          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0)
            .animate(_scaleController),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxxl),
            child: Column(
              children: [
                // Animated icon
                ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1.0)
                      .animate(_scaleController),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Welcome to Doctor App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your complete clinic management solution. This guide will help you master all features.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                _buildFeatureGrid(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      ('👥', 'Patients', 'Manage patient profiles'),
      ('📅', 'Appointments', 'Schedule & track visits'),
      ('💊', 'Prescriptions', 'Create & manage meds'),
      ('💰', 'Billing', 'Invoice & payments'),
      ('📋', 'Medical Records', 'Clinical documentation'),
      ('⚙️', 'Settings', 'App preferences'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features
          .map((f) => _buildFeatureCard(f.$1, f.$2, f.$3))
          .toList(),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String desc) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: context.isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      borderColor: context.isDarkMode
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.12),
      borderWidth: 1,
      boxShadow: context.isDarkMode
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              )
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: context.isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientManagementPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Patient Management',
        emoji: '👥',
        color: const Color(0xFF10B981),
        steps: [
          _buildStep(
            '1. Add New Patient',
            'Tap the + button on the Patients screen to create a new patient profile.',
            const Icon(Icons.person_add_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          _buildStep(
            '2. Fill Patient Details',
            'Enter name, phone, email, date of birth, and medical history. All fields support auto-suggestions.',
            const Icon(Icons.edit_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          _buildStep(
            '3. Assign Risk Level',
            'Set Low, Medium, or High risk based on patient condition for quick identification.',
            const Icon(Icons.flag_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          _buildStep(
            '4. Add Tags',
            'Tag patients (e.g., "VIP", "Follow-up", "High Priority") for easy filtering.',
            const Icon(Icons.label_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          _buildStep(
            '5. Search & Filter',
            'Use the search bar to find patients by name, phone, or email instantly.',
            const Icon(Icons.search_rounded, size: 48, color: Color(0xFF10B981)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildAppointmentsPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Appointments',
        emoji: '📅',
        color: const Color(0xFF3B82F6),
        steps: [
          _buildStep(
            '1. Create Appointment',
            'Select a patient and choose date/time. Duration defaults to 15 min but is adjustable.',
            const Icon(Icons.event_rounded, size: 48, color: Color(0xFF3B82F6)),
          ),
          _buildStep(
            '2. Set Appointment Status',
            'Choose from: Scheduled, Confirmed, In Progress, Completed, Cancelled, or No Show.',
            const Icon(Icons.playlist_add_check_rounded, size: 48, color: Color(0xFF3B82F6)),
          ),
          _buildStep(
            '3. Add Appointment Notes',
            'Include reason for visit, special requirements, or clinical notes before the appointment.',
            const Icon(Icons.note_add_rounded, size: 48, color: Color(0xFF3B82F6)),
          ),
          _buildStep(
            '4. Set Reminders',
            'Enable reminders to get notified before each appointment (set custom time).',
            const Icon(Icons.notifications_active_rounded, size: 48, color: Color(0xFF3B82F6)),
          ),
          _buildStep(
            '5. View Calendar',
            'Switch between list view and calendar view to manage your schedule efficiently.',
            const Icon(Icons.calendar_view_week_rounded, size: 48, color: Color(0xFF3B82F6)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildPrescriptionsPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Prescriptions',
        emoji: '💊',
        color: const Color(0xFFF59E0B),
        steps: [
          _buildStep(
            '1. Create New Prescription',
            'Select patient and tap "New Prescription" to start creating a medication plan.',
            const Icon(Icons.medication_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
          _buildStep(
            '2. Add Medications',
            'Add each medication with dosage, frequency, duration, and special instructions.',
            const Icon(Icons.medical_services_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
          _buildStep(
            '3. Use Templates',
            'Access pre-built prescription templates for common conditions to save time.',
            const Icon(Icons.description_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
          _buildStep(
            '4. Print or Export',
            'Generate a professional PDF prescription that can be printed or shared with patient.',
            const Icon(Icons.print_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
          _buildStep(
            '5. Refill Prescriptions',
            'Mark prescriptions as refillable and quickly duplicate them for follow-up visits.',
            const Icon(Icons.refresh_rounded, size: 48, color: Color(0xFFF59E0B)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildBillingPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Billing & Invoices',
        emoji: '💰',
        color: const Color(0xFF8B5CF6),
        steps: [
          _buildStep(
            '1. Create Invoice',
            'Select patient and add line items (consultations, procedures, tests, medications).',
            const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF8B5CF6)),
          ),
          _buildStep(
            '2. Add Discounts & Tax',
            'Apply flat discounts or percentages, and add tax calculations automatically.',
            const Icon(Icons.discount_rounded, size: 48, color: Color(0xFF8B5CF6)),
          ),
          _buildStep(
            '3. Track Payments',
            'Mark invoices as Pending, Partial, Paid, or Overdue and track payment methods.',
            const Icon(Icons.payment_rounded, size: 48, color: Color(0xFF8B5CF6)),
          ),
          _buildStep(
            '4. Generate Receipt',
            'Create professional PDF receipts with clinic branding and patient details.',
            const Icon(Icons.picture_as_pdf_rounded, size: 48, color: Color(0xFF8B5CF6)),
          ),
          _buildStep(
            '5. View Analytics',
            'Check revenue trends, payment status summary, and overdue invoices on dashboard.',
            const Icon(Icons.analytics_rounded, size: 48, color: Color(0xFF8B5CF6)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildMedicalRecordsPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Medical Records',
        emoji: '📋',
        color: const Color(0xFF06B6D4),
        steps: [
          _buildStep(
            '1. Create Medical Record',
            'Add records including general notes, lab results, imaging, or psychiatric assessments.',
            const Icon(Icons.folder_special_rounded, size: 48, color: Color(0xFF06B6D4)),
          ),
          _buildStep(
            '2. Fill Assessment Forms',
            'Use structured forms for psychiatric assessments with Mental State Examination (MSE).',
            const Icon(Icons.psychology_rounded, size: 48, color: Color(0xFF06B6D4)),
          ),
          _buildStep(
            '3. Add Clinical Notes',
            'Document diagnosis, treatment plan, and doctor\'s observations with full detail.',
            const Icon(Icons.note_rounded, size: 48, color: Color(0xFF06B6D4)),
          ),
          _buildStep(
            '4. Attach Photos/Files',
            'Upload images of medical documents, lab reports, or imaging files for reference.',
            const Icon(Icons.image_rounded, size: 48, color: Color(0xFF06B6D4)),
          ),
          _buildStep(
            '5. Search Records',
            'Quickly find any medical record by date, type, or keywords across all patients.',
            const Icon(Icons.manage_search_rounded, size: 48, color: Color(0xFF06B6D4)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildSettingsPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: _buildManualPage(
        title: 'Settings & Preferences',
        emoji: '⚙️',
        color: const Color(0xFF64748B),
        steps: [
          _buildStep(
            '1. Doctor Profile',
            'Set up your clinic name, license number, signature, and professional credentials.',
            const Icon(Icons.person_rounded, size: 48, color: Color(0xFF64748B)),
          ),
          _buildStep(
            '2. Theme & Appearance',
            'Toggle between light and dark modes based on your preference or time of day.',
            const Icon(Icons.brightness_4_rounded, size: 48, color: Color(0xFF64748B)),
          ),
          _buildStep(
            '3. Notifications',
            'Enable/disable appointment reminders, billing alerts, and other notifications.',
            const Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFF64748B)),
          ),
          _buildStep(
            '4. Backup & Restore',
            'Export database to backup important data, import from backup to restore.',
            const Icon(Icons.cloud_download_rounded, size: 48, color: Color(0xFF64748B)),
          ),
          _buildStep(
            '5. Security & Auth',
            'Enable biometric or PIN authentication to protect sensitive patient data.',
            const Icon(Icons.security_rounded, size: 48, color: Color(0xFF64748B)),
          ),
        ],
        isDark: isDark,
      ),
    );
  }

  Widget _buildTipsPage(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxxl),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pro Tips & Best Practices',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ...[
                ('💡', 'Auto-Suggestions', 'All text fields show smart suggestions based on your previous entries. Just tap to add!'),
                ('🔄', 'Quick Actions', 'Swipe left on patient/appointment cards for quick edit, delete, or share options.'),
                ('📊', 'Dashboard', 'Check your dashboard daily for upcoming appointments, pending invoices, and patient alerts.'),
                ('🔍', 'Advanced Search', 'Use filters in search to find patients by risk level, tags, or appointment status.'),
                ('📱', 'Offline Mode', 'The app works completely offline. All data syncs automatically when internet is available.'),
                ('🎯', 'Templates', 'Create reusable templates for prescriptions, invoices, and medical notes to save time.'),
                ('🔐', 'Data Security', 'Enable biometric lock in settings for added security. Your data is stored locally.'),
                ('⌨️', 'Keyboard Shortcuts', 'Use Tab to navigate between fields quickly, and Enter to confirm actions.'),
              ]
                  .map((tip) => _buildTipCard(tip.$1, tip.$2, tip.$3, isDark))
                  .toList(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String description, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPage({
    required String title,
    required String emoji,
    required Color color,
    required List<Widget> steps,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxxl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...steps,
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, String description, Icon icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            ElevatedButton.icon(
              onPressed: _currentPage > 0 ? _previousPage : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentPage > 0
                    ? const Color(0xFF6366F1)
                    : Colors.grey.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey,
              ),
            ),
            // Page indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    8,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF6366F1)
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentPage + 1}/8',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            // Next button
            ElevatedButton.icon(
              onPressed: _currentPage < 7 ? _nextPage : null,
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentPage < 7
                    ? const Color(0xFF6366F1)
                    : Colors.grey.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

