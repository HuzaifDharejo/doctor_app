import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/db_provider.dart';
import '../../services/notification_service.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../db/doctor_db.dart';

/// Widget showing pending notifications
class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbFuture = ref.watch(doctorDbProvider);

    return dbFuture.when(
      data: (db) {
        return FutureBuilder<List<NotificationMessage>>(
          future: const NotificationService().getPendingNotifications(db),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            // Categorize by priority: Critical, Important, Informational
            final critical = notifications.where((n) => 
              n.priority == 'critical' || 
              n.isOverdue ||
              n.type == 'clinical_alert'
            ).toList();
            
            final important = notifications.where((n) => 
              n.priority == 'high' || 
              n.priority == 'important' ||
              (n.type == 'appointment_reminder' && n.priority != 'critical') ||
              n.type == 'follow_up_reminder'
            ).toList();
            
            final informational = notifications.where((n) => 
              !critical.contains(n) && !important.contains(n)
            ).toList();

            return ListView(
              // Use primary: false when inside NestedScrollView to avoid ScrollController conflicts
              primary: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (critical.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Critical (${critical.length})', const Color(0xFFDC2626)),
                  const SizedBox(height: 8),
                  ...critical.map((n) => _buildNotificationCard(context, ref, n, isActionable: true)),
                  const SizedBox(height: 24),
                ],
                if (important.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Important (${important.length})', const Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  ...important.map((n) => _buildNotificationCard(context, ref, n, isActionable: true)),
                  const SizedBox(height: 24),
                ],
                if (informational.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Informational (${informational.length})', const Color(0xFF3B82F6)),
                  const SizedBox(height: 8),
                  ...informational.map((n) => _buildNotificationCard(context, ref, n, isActionable: true)),
                ],
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No pending notifications',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, NotificationMessage notification, {bool isActionable = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.xs),
      elevation: notification.priority == 'critical' ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: notification.priority == 'critical'
            ? BorderSide(color: notification.priorityColor, width: 2)
            : BorderSide.none,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActionable ? () => _handleNotificationTap(context, ref, notification) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: notification.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: notification.priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.subject,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDateTime(notification.scheduledFor),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: notification.priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    notification.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: notification.priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...notification.channels.map((channel) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Chip(
                          label: Text(
                            channel.toUpperCase(),
                            style: const TextStyle(fontSize: 9),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }),
                    const Spacer(),
                    if (isActionable)
                      TextButton.icon(
                        onPressed: () => _handleNotificationTap(context, ref, notification),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('View', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationMessage notification) async {
    final db = await ref.read(doctorDbProvider.future);
    
    // Navigate based on notification type
    switch (notification.type) {
      case 'appointment_reminder':
        if (notification.metadata.containsKey('appointmentId')) {
          final appointmentId = int.tryParse(notification.metadata['appointmentId'] ?? '');
          if (appointmentId != null) {
            final appointment = await db.getAppointmentById(appointmentId);
            if (appointment != null) {
              final patient = await db.getPatientById(appointment.patientId);
              if (patient != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.patientView,
                  arguments: PatientViewArgs(patient: patient),
                );
              }
            }
          }
        }
        break;
        
      case 'follow_up_reminder':
      case 'overdue_followup':
        if (notification.metadata.containsKey('patientId')) {
          final patientId = int.tryParse(notification.metadata['patientId'] ?? '');
          if (patientId != null) {
            final patient = await db.getPatientById(patientId);
            if (patient != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.followUps,
                arguments: FollowUpsArgs(patientId: patientId, patientName: '${patient.firstName} ${patient.lastName}'),
              );
            }
          }
        }
        break;
        
      case 'clinical_alert':
        if (notification.metadata.containsKey('patientId')) {
          final patientId = int.tryParse(notification.metadata['patientId'] ?? '');
          if (patientId != null) {
            final patient = await db.getPatientById(patientId);
            if (patient != null) {
              // Navigate to patient view, could also navigate to specific tab based on alertType
              final alertType = notification.metadata['alertType'] ?? '';
              if (alertType == 'overdue_lab_result') {
                Navigator.pushNamed(
                  context,
                  AppRoutes.labResults,
                  arguments: LabResultsArgs(patientId: patientId, patientName: '${patient.firstName} ${patient.lastName}'),
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.patientView,
                  arguments: PatientViewArgs(patient: patient),
                );
              }
            }
          }
        }
        break;
        
      case 'prescription_summary':
        Navigator.pushNamed(context, AppRoutes.prescriptions);
        break;
        
      default:
        // For other types, try to navigate to patient view if patientId exists
        if (notification.metadata.containsKey('patientId')) {
          final patientId = int.tryParse(notification.metadata['patientId'] ?? '');
          if (patientId != null) {
            final patient = await db.getPatientById(patientId);
            if (patient != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.patientView,
                arguments: PatientViewArgs(patient: patient),
              );
            }
          }
        }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'appointment_reminder':
        return Icons.event_rounded;
      case 'follow_up_reminder':
        return Icons.event_repeat_rounded;
      case 'medication_reminder':
        return Icons.medical_services_rounded;
      case 'clinical_alert':
        return Icons.warning_rounded;
      case 'overdue_followup':
        return Icons.schedule_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inMinutes < 0) {
      return 'Overdue by ${(-difference.inMinutes)} minutes';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }
}

/// Notification preferences dialog
class NotificationPreferencesDialog extends ConsumerStatefulWidget {
  const NotificationPreferencesDialog({
    super.key,
  });

  @override
  ConsumerState<NotificationPreferencesDialog> createState() =>
      _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState
    extends ConsumerState<NotificationPreferencesDialog> {
  late bool appointmentReminders;
  late int appointmentMinutesBefore;
  late bool followUpReminders;
  late int followUpHoursBefore;
  late bool medicationReminders;
  late bool clinicalAlerts;
  late String quietHourStart;
  late String quietHourEnd;
  late List<String> preferredChannels;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    appointmentReminders = true;
    appointmentMinutesBefore = 24 * 60;
    followUpReminders = true;
    followUpHoursBefore = 24;
    medicationReminders = true;
    clinicalAlerts = true;
    quietHourStart = '22:00';
    quietHourEnd = '08:00';
    preferredChannels = ['email', 'sms'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              'Appointment Reminders',
              appointmentReminders,
              (value) => setState(() => appointmentReminders = value),
            ),
            if (appointmentReminders)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: _buildDropdown(
                  'Remind me',
                  appointmentMinutesBefore,
                  {
                    30: '30 minutes before',
                    60: '1 hour before',
                    240: '4 hours before',
                    1440: '24 hours before',
                    2880: '2 days before',
                  },
                  (value) => setState(() => appointmentMinutesBefore = value ?? 1440),
                ),
              ),
            const Divider(),
            _buildSwitchTile(
              'Follow-up Reminders',
              followUpReminders,
              (value) => setState(() => followUpReminders = value),
            ),
            if (followUpReminders)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: _buildDropdown(
                  'Remind me',
                  followUpHoursBefore,
                  {
                    1: '1 hour before',
                    4: '4 hours before',
                    12: '12 hours before',
                    24: '24 hours before',
                  },
                  (value) => setState(() => followUpHoursBefore = value ?? 24),
                ),
              ),
            const Divider(),
            _buildSwitchTile(
              'Medication Reminders',
              medicationReminders,
              (value) => setState(() => medicationReminders = value),
            ),
            const Divider(),
            _buildSwitchTile(
              'Clinical Alerts',
              clinicalAlerts,
              (value) => setState(() => clinicalAlerts = value),
            ),
            const Divider(),
            const Text(
              'Preferred Channels',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['sms', 'email', 'whatsapp', 'in_app'].map((channel) {
                return FilterChip(
                  label: Text(channel.toUpperCase()),
                  selected: preferredChannels.contains(channel),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        preferredChannels.add(channel);
                      } else {
                        preferredChannels.remove(channel);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Do Not Disturb Hours',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    'From',
                    quietHourStart,
                    (value) => setState(() => quietHourStart = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeField(
                    'To',
                    quietHourEnd,
                    (value) => setState(() => quietHourEnd = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppButton.tertiary(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'Save',
          onPressed: () {
            Navigator.pop(context, {
              'appointmentReminders': appointmentReminders,
              'appointmentMinutesBefore': appointmentMinutesBefore,
              'followUpReminders': followUpReminders,
              'followUpHoursBefore': followUpHoursBefore,
              'medicationReminders': medicationReminders,
              'clinicalAlerts': clinicalAlerts,
              'preferredChannels': preferredChannels,
              'quietHourStart': quietHourStart,
              'quietHourEnd': quietHourEnd,
            });
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    int value,
    Map<int, String> options,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButton<int>(
      value: value,
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildTimeField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AppInput.text(
          controller: TextEditingController(text: value),
          hint: 'HH:MM',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Notification badge widget
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (count == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

