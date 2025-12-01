import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/db_provider.dart';
import '../widgets/notifications_panel.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing notifications and preferences
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reminders'),
            Tab(text: 'Preferences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const NotificationsPanel(),
          _buildPreferencesTab(),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreferenceCard(
            'Appointment Reminders',
            'Receive reminders for upcoming appointments',
            Icons.event_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          _buildPreferenceCard(
            'Follow-up Reminders',
            'Get notified about scheduled follow-ups',
            Icons.event_repeat_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          _buildPreferenceCard(
            'Medication Reminders',
            'Reminder to take prescribed medications',
            Icons.medical_services_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          _buildPreferenceCard(
            'Clinical Alerts',
            'Critical notifications for patient safety',
            Icons.warning_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          _buildPreferenceCard(
            'Notification Channels',
            'SMS, Email, WhatsApp, In-App',
            Icons.phone_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          _buildPreferenceCard(
            'Quiet Hours',
            'Set times to reduce notification interruptions',
            Icons.schedule_rounded,
            onTap: () => _showPreferencesDialog(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save All Preferences'),
              onPressed: () => _showPreferencesDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPreferencesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NotificationPreferencesDialog(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

