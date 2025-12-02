import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/app_button.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/app_header.dart';
import '../../core/theme/design_tokens.dart';
import '../../providers/db_provider.dart';
import '../../providers/google_calendar_provider.dart';
import '../../services/backup_service.dart';
import '../../services/doctor_settings_service.dart';
import '../../services/localization_service.dart';
import '../../services/logger_service.dart';
import '../../services/seed_data_service.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../theme/app_theme.dart';
import '../widgets/debug_console.dart';
import 'doctor_profile_screen.dart';
import 'user_manual_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final isDark = context.isDarkMode;
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    ),),
                    child: _buildProfileCard(context, ref),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 1),
                  ),
                  child: _buildSettingsSections(context, ref, appSettings),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = AppBreakpoint.isCompact(context.screenWidth);
    
    return AppHeader(
      title: AppStrings.settings,
      subtitle: AppStrings.manageSettings,
      showBackButton: true,
      trailing: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Icon(
          Icons.settings_rounded,
          color: AppColors.primary,
          size: isCompact ? AppIconSize.sm : AppIconSize.md,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final isCompact = AppBreakpoint.isCompact(context.screenWidth);
    final padding = isCompact ? AppSpacing.sm : AppSpacing.lg;
    
    return _AnimatedTapCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const DoctorProfileScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.all(padding),
        padding: EdgeInsets.all(isCompact ? AppSpacing.md : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: AppSpacing.lg,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with ring and pulse effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: Container(
                  width: isCompact ? 52 : 64,
                  height: isCompact ? 52 : 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? AppFontSize.lg : AppFontSize.xl,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 15 : AppFontSize.lg,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      profile.specialization.isNotEmpty ? profile.specialization : 'Tap to set up',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: isCompact ? AppFontSize.xxs : 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.email.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(Icons.email_rounded, size: AppFontSize.xs, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            profile.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: isCompact ? AppFontSize.xxs : 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: isCompact ? 16.0 : 18.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSections(BuildContext context, WidgetRef ref, AppSettingsService appSettings) {
    final settings = appSettings.settings;
    final lastBackup = settings.lastBackupDate;
    final backupText = lastBackup != null 
      ? DateTimeFormatter.formatRelative(lastBackup)
      : 'Never';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'General'),
          _buildSettingsGroup(context, [
            _SettingItem(
              icon: Icons.notifications_rounded,
              iconColor: AppColors.warning,
              title: AppStrings.notifications,
              subtitle: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: (v) {
                  ref.read(appSettingsProvider).setNotificationsEnabled(v);
                },
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeThumbColor: AppColors.primary,
              ),
            ),
            _SettingItem(
              icon: Icons.dark_mode_rounded,
              iconColor: AppColors.primaryDark,
              title: 'Dark Mode',
              subtitle: settings.darkModeEnabled ? 'On' : 'Off',
              trailing: Switch(
                value: settings.darkModeEnabled,
                onChanged: (v) {
                  ref.read(appSettingsProvider).setDarkModeEnabled(v);
                },
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeThumbColor: AppColors.primary,
              ),
            ),
            _SettingItem(
              icon: Icons.touch_app_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Exam Mode',
              subtitle: settings.examModeEnabled ? 'Large touch targets' : 'Standard layout',
              trailing: Switch(
                value: settings.examModeEnabled,
                onChanged: (v) {
                  ref.read(appSettingsProvider).setExamModeEnabled(v);
                },
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeThumbColor: AppColors.primary,
              ),
            ),
            _SettingItem(
              icon: Icons.language_rounded,
              iconColor: AppColors.info,
              title: 'Language',
              subtitle: settings.language,
              onTap: () => _showLanguageDialog(context, ref, settings.language),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle(context, 'Calendar Integration'),
          _buildGoogleCalendarSection(context, ref),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle(context, 'Medical Records'),
          _buildMedicalRecordTypesSection(context, ref, settings),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle(context, 'Data & Privacy'),
          _buildSettingsGroup(context, [
            _SettingItem(
              icon: Icons.backup_rounded,
              iconColor: AppColors.success,
              title: 'Backup & Restore',
              subtitle: 'Last backup: $backupText',
              onTap: () => _showBackupDialog(context, ref),
            ),
            _SettingItem(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: 'Clear All Data',
              subtitle: 'Delete all app data',
              onTap: () => _showClearDataDialog(context, ref),
            ),
            _SettingItem(
              icon: Icons.privacy_tip_rounded,
              iconColor: AppColors.accent,
              title: 'Privacy Policy',
              subtitle: 'Read our terms',
              onTap: () => _showPrivacyPolicy(context),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle(context, 'Support'),
          _buildSettingsGroup(context, [
            _SettingItem(
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.success,
              title: 'User Manual',
              subtitle: 'Complete app guide & tutorials',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const UserManualScreen()),
                );
              },
            ),
            _SettingItem(
              icon: Icons.help_outline_rounded,
              iconColor: AppColors.primary,
              title: 'Help Center',
              subtitle: 'FAQs & tutorials',
              onTap: () => _showHelpCenter(context),
            ),
            _SettingItem(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.accent,
              title: 'Contact Support',
              subtitle: 'Get help from our team',
              onTap: () => _showContactSupport(context),
            ),
            _SettingItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textSecondary,
              title: 'About',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(context),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          
          // Developer Section (Debug mode only)
          if (kDebugMode) ...[
            _buildSectionTitle(context, 'Developer'),
            _buildSettingsGroup(context, [
              _SettingItem(
                icon: Icons.bug_report_rounded,
                iconColor: Colors.purple,
                title: 'Debug Console',
                subtitle: '${log.errorCount} errors, ${log.warningCount} warnings',
                onTap: () {
                  log.trackScreen('DebugConsole');
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const DebugConsole()),
                  );
                },
              ),
              _SettingItem(
                icon: Icons.analytics_outlined,
                iconColor: Colors.teal,
                title: 'View Logs Summary',
                subtitle: '${log.logs.length} total log entries',
                onTap: () => _showLogsSummary(context),
              ),
              _SettingItem(
                icon: Icons.delete_sweep_rounded,
                iconColor: AppColors.error,
                title: 'Clear Logs',
                subtitle: 'Remove all debug logs',
                onTap: () {
                  log.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs cleared')),
                  );
                  setState(() {});
                },
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
          
          // Reset Profile Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: OutlinedButton.icon(
              onPressed: () => _showResetProfileDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppFontSize.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              icon: const Icon(Icons.person_off_rounded),
              label: const Text('Reset Profile'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogsSummary(BuildContext context) {
    final summary = log.getSummary();
    final errorsByTag = log.errorsByTag;
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.purple),
            SizedBox(width: 12),
            Text('Logs Summary'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Total Logs', '${summary['totalLogs']}'),
              _buildSummaryRow('Errors', '${summary['errors']}', color: AppColors.error),
              _buildSummaryRow('Warnings', '${summary['warnings']}', color: AppColors.warning),
              _buildSummaryRow('Performance Metrics', '${summary['metricsCount']}'),
              _buildSummaryRow('Analytics Events', '${summary['eventsCount']}'),
              if (errorsByTag.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors by Component:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...errorsByTag.entries.map((e) => _buildSummaryRow(e.key, '${e.value}', color: AppColors.error)),
              ],
              if (summary['lastError'] != null) ...[
                const SizedBox(height: 16),
                Text('Last Error: ${summary['lastError']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.tertiary(
            label: 'View Details',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const DebugConsole()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String currentLanguage) {
    final locService = LocalizationService();
    final languages = locService.getAvailableLanguages();
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            final isSelected = locService.languageCode == entry.key;
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              // ignore: deprecated_member_use
              groupValue: locService.languageCode,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  locService.setLocaleByCode(value);
                  ref.read(appSettingsProvider).setLanguage(entry.value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Backup & Restore'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: AppColors.success),
              title: const Text('Create Backup'),
              subtitle: const Text('Save data to file'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(appSettingsProvider).updateLastBackupDate();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Backup created successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download, color: AppColors.info),
              title: const Text('Restore Backup'),
              subtitle: const Text('Load data from file'),
              onTap: () {
                Navigator.pop(context);
                _showRestoreBackupDialog(context, ref);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dataset, color: AppColors.warning),
              title: const Text('Load Demo Data'),
              subtitle: const Text('Add sample patients & appointments'),
              onTap: () async {
                Navigator.pop(context);
                _showLoadDemoDataDialog(context, ref);
              },
            ),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showRestoreBackupDialog(BuildContext context, WidgetRef ref) async {
    // First show the list of available backups
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: AppColors.info),
            SizedBox(width: 12),
            Text('Restore Backup'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<_BackupItem>>(
            future: _getBackupList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final backups = snapshot.data ?? [];

              if (backups.isEmpty) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_off, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'No backups found',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create a backup first to restore later.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Restoring a backup will replace all current data.',
                            style: TextStyle(fontSize: 12, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select a backup to restore:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...backups.take(5).map((backup) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      backup.isAuto ? Icons.schedule : Icons.backup,
                      color: backup.isAuto ? AppColors.textSecondary : AppColors.primary,
                    ),
                    title: Text(backup.name),
                    subtitle: Text('${backup.date} • ${backup.size}'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmRestore(context, ref, backup);
                    },
                  )),
                ],
              );
            },
          ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<List<_BackupItem>> _getBackupList() async {
    try {
      final backupService = BackupService();
      final backups = await backupService.listBackups();
      return backups.map((b) => _BackupItem(
        name: b.fileName,
        date: b.formattedDate,
        size: b.formattedSize,
        isAuto: b.metadata.isAutoBackup,
        file: b.file,
      )).toList();
    } catch (e) {
      log.e('Settings', 'Error loading backups: $e');
      return [];
    }
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, _BackupItem backup) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 12),
            Text('Confirm Restore'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to restore this backup?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.backup, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(backup.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${backup.date} • ${backup.size}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Warning: This will replace all your current data. A backup of your current data will be created automatically.',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            label: 'Restore',
            icon: Icons.restore,
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore(context, ref, backup);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BuildContext context, WidgetRef ref, _BackupItem backup) async {
    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Restoring backup...'),
          ],
        ),
      ),
    );

    try {
      final backupService = BackupService();
      await backupService.importDatabase(backup.file);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Backup restored successfully! Please restart the app.'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _showLoadDemoDataDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dataset, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Load Demo Data'),
          ],
        ),
        content: const Text(
          'This will add sample patients, appointments, and prescriptions to your database. This is useful for testing or demonstration purposes.\n\nExisting data will NOT be affected.',
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.primary(
            label: 'Load Data',
            icon: Icons.add,
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dbAsync = ref.read(doctorDbProvider);
                final db = dbAsync.when(
                  data: (db) => db,
                  loading: () => throw Exception('Database loading'),
                  error: (e, _) => throw e,
                );
                await seedSampleDataForce(db);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Demo data loaded successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load demo data: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 12),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your data including patients, appointments, prescriptions, and invoices. This action cannot be undone.',
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.danger(
            label: 'Delete All',
            onPressed: () async {
              Navigator.pop(context);
              // Clear settings
              await ref.read(appSettingsProvider).clearSettings();
              await ref.read(doctorSettingsProvider).clearProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('All data cleared'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Doctor App Privacy Policy\n\n'
            '1. Data Collection\n'
            'We collect patient information, appointment data, and medical records solely for the purpose of providing healthcare services.\n\n'
            '2. Data Storage\n'
            'All data is stored locally on your device. We do not upload your data to any external servers without your explicit consent.\n\n'
            '3. Data Security\n'
            'We implement industry-standard security measures to protect your data from unauthorized access.\n\n'
            '4. Data Sharing\n'
            'We do not share your data with third parties unless required by law or with your explicit consent.\n\n'
            '5. Your Rights\n'
            'You have the right to access, modify, or delete your data at any time through the app settings.\n\n'
            'For questions, contact: support@doctorapp.com',
          ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Help Center'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('How to add a patient?', 'Go to Patients tab > Tap the + button > Fill in details'),
            _buildHelpItem('How to create prescription?', 'Open patient > Tap Add Prescription > Fill medications'),
            _buildHelpItem('How to generate invoice?', 'Go to Billing tab > Tap Create Invoice > Add items'),
            _buildHelpItem('How to backup data?', 'Settings > Backup & Restore > Create Backup'),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: AppColors.accent),
            SizedBox(width: 12),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('support@doctorapp.com'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: const Text('+92 300 1234567'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              subtitle: const Text('+92 300 1234567'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Doctor App'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              'A comprehensive clinic management solution for healthcare professionals.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildFeatureItem('Patient Management'),
            _buildFeatureItem('Appointment Scheduling'),
            _buildFeatureItem('Digital Prescriptions'),
            _buildFeatureItem('Billing & Invoicing'),
            _buildFeatureItem('Medical Records'),
            const SizedBox(height: 16),
            const Text('© 2024 Doctor App. All rights reserved.', 
              style: TextStyle(fontSize: 12, color: Colors.grey),),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showResetProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off, color: AppColors.error),
            SizedBox(width: 12),
            Text('Reset Profile'),
          ],
        ),
        content: const Text(
          'This will reset your doctor profile to default values. Your patients and other data will not be affected.',
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.danger(
            label: 'Reset',
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(doctorSettingsProvider).clearProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Profile reset successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<_SettingItem> items) {
    final isDark = context.isDarkMode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.xs,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(AppRadius.md) : Radius.zero,
                    bottom: isLast ? const Radius.circular(AppRadius.md) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: item.iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppFontSize.sm,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.trailing != null)
                          item.trailing!
                        else if (item.onTap != null)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoogleCalendarSection(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(googleCalendarProvider);
    final isDark = context.isDarkMode;

    if (calendarState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (calendarState.isConnected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Google Account Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: calendarState.userPhotoUrl != null
                        ? NetworkImage(calendarState.userPhotoUrl!)
                        : null,
                    child: calendarState.userPhotoUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Connected with Google',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calendarState.userEmail ?? '',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Sign Out',
                    onPressed: () => _showDisconnectCalendarDialog(context, ref),
                    variant: AppButtonVariant.tertiary,
                    foregroundColor: AppColors.error,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Calendar settings
            _buildSettingsItem(
              context,
              icon: Icons.calendar_month,
              iconColor: AppColors.info,
              title: 'Select Calendar',
              subtitle: _getCalendarName(calendarState),
              onTap: () => _showSelectCalendarDialog(context, ref, calendarState),
            ),
            _buildSettingsItem(
              context,
              icon: Icons.sync,
              iconColor: AppColors.accent,
              title: 'Sync Settings',
              subtitle: 'Configure appointment sync',
              onTap: () => _showSyncSettingsDialog(context, ref),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.xs,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connectGoogleCalendar(context, ref),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    'https://www.gstatic.com/images/branding/product/1x/calendar_2020q4_48dp.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF4285F4),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect Google Calendar',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sync appointments & show availability to patients',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRecordTypesSection(BuildContext context, WidgetRef ref, AppSettings settings) {
    final isDark = context.isDarkMode;
    final enabledTypes = settings.enabledMedicalRecordTypes;
    
    final Map<String, IconData> typeIcons = {
      'general': Icons.medical_services_outlined,
      'pulmonary_evaluation': Icons.air,
      'psychiatric_assessment': Icons.psychology,
      'lab_result': Icons.science_outlined,
      'imaging': Icons.image_outlined,
      'procedure': Icons.healing_outlined,
      'follow_up': Icons.event_repeat,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.xs,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enabled Record Types',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.sm,
                        ),
                      ),
                      Text(
                        '${enabledTypes.length} of ${AppSettings.allMedicalRecordTypes.length} types enabled',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton.tertiary(
                  label: enabledTypes.length == AppSettings.allMedicalRecordTypes.length 
                      ? 'Disable All' 
                      : 'Enable All',
                  onPressed: () {
                    // Toggle all on/off
                    final allEnabled = enabledTypes.length == AppSettings.allMedicalRecordTypes.length;
                    if (allEnabled) {
                      // Keep at least general enabled
                      ref.read(appSettingsProvider).setEnabledMedicalRecordTypes(['general']);
                    } else {
                      ref.read(appSettingsProvider).setEnabledMedicalRecordTypes(
                        List.from(AppSettings.allMedicalRecordTypes),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...AppSettings.allMedicalRecordTypes.map((type) {
            final isEnabled = enabledTypes.contains(type);
            final label = AppSettings.medicalRecordTypeLabels[type] ?? type;
            final description = AppSettings.medicalRecordTypeDescriptions[type] ?? '';
            final icon = typeIcons[type] ?? Icons.description;
            
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    value: isEnabled,
                    onChanged: (value) {
                      // Ensure at least one type is always enabled
                      if (!value! && enabledTypes.length <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('At least one record type must be enabled'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                        return;
                      }
                      ref.read(appSettingsProvider).toggleMedicalRecordType(type, value);
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (isEnabled ? AppColors.primary : AppColors.textHint).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isEnabled ? AppColors.primary : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: isEnabled 
                            ? (isDark ? Colors.white : Colors.black87) 
                            : AppColors.textHint,
                      ),
                    ),
                    subtitle: Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxs,
                    ),
                  ),
                ),
                if (type != AppSettings.allMedicalRecordTypes.last)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final isDark = context.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCalendarName(GoogleCalendarState state) {
    if (state.selectedCalendarId == 'primary') {
      return 'Primary Calendar';
    }
    final calendar = state.calendars.firstWhere(
      (c) => c.id == state.selectedCalendarId,
      orElse: () => state.calendars.isNotEmpty ? state.calendars.first : throw Exception('No calendar'),
    );
    return calendar.summary ?? 'Selected Calendar';
  }

  Future<void> _connectGoogleCalendar(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(googleCalendarProvider.notifier).signIn();
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Google Calendar connected successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to connect Google Calendar'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _showDisconnectCalendarDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_off, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Disconnect Calendar'),
          ],
        ),
        content: const Text(
          'Are you sure you want to disconnect your Google Calendar? '
          'Appointments will no longer sync automatically.',
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.danger(
            label: 'Disconnect',
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(googleCalendarProvider.notifier).signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Google Calendar disconnected'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSelectCalendarDialog(BuildContext context, WidgetRef ref, GoogleCalendarState state) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Select Calendar'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: state.calendars.isEmpty
              ? const Text('No calendars found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = state.calendars[index];
                    
                    return RadioListTile<String>(
                      title: Text(calendar.summary ?? 'Unnamed Calendar'),
                      subtitle: calendar.primary ?? false ? const Text('Primary') : null,
                      value: calendar.id ?? 'primary',
                      // ignore: deprecated_member_use
                      groupValue: state.selectedCalendarId,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(googleCalendarProvider.notifier).setSelectedCalendar(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSyncSettingsDialog(BuildContext context, WidgetRef ref) {
    final appSettings = ref.read(appSettingsProvider);
    var autoSync = appSettings.settings.autoSyncAppointments;
    var reminders = appSettings.settings.calendarReminders;
    
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.sync, color: AppColors.accent),
              SizedBox(width: 12),
              Text('Sync Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event_available, color: AppColors.success),
                title: const Text('Auto-sync new appointments'),
                subtitle: const Text('Create calendar events automatically'),
                trailing: Switch(
                  value: autoSync,
                  onChanged: (v) {
                    setDialogState(() => autoSync = v);
                    ref.read(appSettingsProvider).setAutoSyncAppointments(v);
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active, color: AppColors.warning),
                title: const Text('Calendar reminders'),
                subtitle: const Text('30 min and 10 min before'),
                trailing: Switch(
                  value: reminders,
                  onChanged: (v) {
                    setDialogState(() => reminders = v);
                    ref.read(appSettingsProvider).setCalendarReminders(v);
                  },
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: AppColors.info),
                title: const Text('Refresh Calendars'),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await ref.read(googleCalendarProvider.notifier).refreshCalendars();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Calendars refreshed'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            AppButton.tertiary(
              label: 'Close',
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem {

  _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

/// Animated tap card with scale effect
class _AnimatedTapCard extends StatefulWidget {

  const _AnimatedTapCard({
    required this.child,
    required this.onTap,
  });
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_AnimatedTapCard> createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<_AnimatedTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Backup item model for restore list
class _BackupItem {
  _BackupItem({
    required this.name,
    required this.date,
    required this.size,
    required this.isAuto,
    required this.file,
  });

  final String name;
  final String date;
  final String size;
  final bool isAuto;
  final File file;
}
