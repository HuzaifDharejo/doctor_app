import 'package:flutter/material.dart';

import '../db/doctor_db.dart';

/// Smart notification service for appointment reminders, follow-ups, and alerts
/// Supports SMS, Email, WhatsApp, and in-app push notifications
class NotificationService {
  const NotificationService();

  /// Create appointment reminder notification
  Future<NotificationMessage> createAppointmentReminder(
    Appointment appointment,
    Patient patient, {
    required String doctorPhone,
    required String doctorEmail,
    int minutesBefore = 24 * 60, // 24 hours before
  }) async {
    final reminderTime = appointment.appointmentDateTime
        .subtract(Duration(minutes: minutesBefore));

    final message = _buildAppointmentReminderMessage(
      appointment,
      patient,
      minutesBefore,
    );

    return NotificationMessage(
      id: '${appointment.id}_reminder',
      type: 'appointment_reminder',
      status: 'pending',
      createdAt: DateTime.now(),
      scheduledFor: reminderTime,
      priority: _calculatePriority(appointment),
      channels: _getPreferredChannels(minutesBefore),
      subject: 'Appointment Reminder: ${appointment.reason}',
      body: message,
      metadata: {
        'appointmentId': appointment.id.toString(),
        'patientId': patient.id.toString(),
        'patientName': patient.firstName,
      },
    );
  }

  /// Create follow-up reminder notification
  Future<NotificationMessage> createFollowUpReminder(
    ScheduledFollowUp followUp,
    Patient patient, {
    int hoursBefore = 24,
  }) async {
    final reminderTime = followUp.scheduledDate
        .subtract(Duration(hours: hoursBefore));

    return NotificationMessage(
      id: '${followUp.id}_followup',
      type: 'follow_up_reminder',
      status: 'pending',
      createdAt: DateTime.now(),
      scheduledFor: reminderTime,
      priority: 'high',
      channels: ['email', 'sms', 'whatsapp'],
      subject: 'Follow-up Reminder: ${followUp.reason}',
      body: _buildFollowUpReminderMessage(followUp, patient, hoursBefore),
      metadata: {
        'followUpId': followUp.id.toString(),
        'patientId': patient.id.toString(),
        'type': followUp.reason,
      },
    );
  }

  /// Create medication reminder notification
  Future<NotificationMessage> createMedicationReminder(
    Prescription prescription,
    Patient patient, {
    required String medicationName,
    required String frequency,
  }) async {
    return NotificationMessage(
      id: '${prescription.id}_med_reminder',
      type: 'medication_reminder',
      status: 'pending',
      createdAt: DateTime.now(),
      scheduledFor: DateTime.now().add(const Duration(minutes: 30)),
      priority: 'normal',
      channels: ['in_app', 'sms'],
      subject: 'Medication Reminder: $medicationName',
      body: _buildMedicationReminderMessage(
        patient,
        medicationName,
        frequency,
        prescription.instructions,
      ),
      metadata: {
        'prescriptionId': prescription.id.toString(),
        'patientId': patient.id.toString(),
        'medicationName': medicationName,
      },
    );
  }

  /// Create urgent clinical alert notification
  Future<NotificationMessage> createClinicalAlert(
    Patient patient, {
    required String alertType, // 'high_risk_allergy', 'critical_vital', 'medication_interaction'
    required String title,
    required String description,
    required String severity, // 'critical', 'high', 'medium'
  }) async {
    return NotificationMessage(
      id: '${patient.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'clinical_alert',
      status: 'pending',
      createdAt: DateTime.now(),
      scheduledFor: DateTime.now(),
      priority: severity,
      channels: ['in_app', 'email', 'sms'],
      subject: '$title - $severity',
      body: description,
      metadata: {
        'patientId': patient.id.toString(),
        'alertType': alertType,
        'severity': severity,
      },
    );
  }

  /// Get pending notifications for doctor
  Future<List<NotificationMessage>> getPendingNotifications(
    DoctorDatabase db, {
    int limitDays = 7,
  }) async {
    final startDate = DateTime.now();
    final endDate = DateTime.now().add(Duration(days: limitDays));

    final appointments = await db.getAllAppointments();
    final followUps = await db.getAllScheduledFollowUps();

    final notifications = <NotificationMessage>[];

    // Appointment reminders
    for (final apt in appointments) {
      final patient = await db.getPatientById(apt.patientId);
      if (patient != null &&
          apt.appointmentDateTime.isAfter(startDate) &&
          apt.appointmentDateTime.isBefore(endDate)) {
        final reminder = await createAppointmentReminder(apt, patient, doctorPhone: 'system', doctorEmail: 'system@doctor.local');
        notifications.add(reminder);
      }
    }

    // Follow-up reminders
    for (final followUp in followUps) {
      if (followUp.status == 'pending' &&
          followUp.scheduledDate.isAfter(startDate) &&
          followUp.scheduledDate.isBefore(endDate)) {
        final patient = await db.getPatientById(followUp.patientId);
        if (patient != null) {
          final reminder = await createFollowUpReminder(followUp, patient);
          notifications.add(reminder);
        }
      }
    }

    return notifications;
  }

  /// Get overdue notifications
  Future<List<NotificationMessage>> getOverdueNotifications(
    DoctorDatabase db,
  ) async {
    final followUps = await db.getOverdueFollowUps();
    final notifications = <NotificationMessage>[];

    for (final followUp in followUps) {
      final patient = await db.getPatientById(followUp.patientId);
      if (patient != null) {
        notifications.add(
          NotificationMessage(
            id: '${followUp.id}_overdue',
            type: 'overdue_followup',
            status: 'overdue',
            createdAt: DateTime.now(),
            scheduledFor: followUp.scheduledDate,
            priority: 'high',
            channels: ['in_app', 'email'],
            subject: 'Overdue: ${followUp.reason}',
            body: 'Follow-up scheduled for ${followUp.scheduledDate.toString().split(' ')[0]} is now overdue for ${patient.firstName}',
            metadata: {
              'followUpId': followUp.id.toString(),
              'patientId': patient.id.toString(),
            },
          ),
        );
      }
    }

    return notifications;
  }

  // Helper methods
  String _buildAppointmentReminderMessage(
    Appointment appointment,
    Patient patient,
    int minutesBefore,
  ) {
    final days = (minutesBefore / (60 * 24)).toStringAsFixed(0);
    final time = appointment.appointmentDateTime.toString().split(' ')[1].substring(0, 5);
    final date = appointment.appointmentDateTime.toString().split(' ')[0];

    return '''Hello ${patient.firstName},

This is a reminder that you have an appointment scheduled:

Reason: ${appointment.reason}
Date: $date
Time: $time
Duration: ${appointment.durationMinutes} minutes

Notes: ${appointment.notes.isEmpty ? 'None' : appointment.notes}

Please arrive 5-10 minutes early. If you need to reschedule, please contact us as soon as possible.

Thank you,
Doctor''';
  }

  String _buildFollowUpReminderMessage(
    ScheduledFollowUp followUp,
    Patient patient,
    int hoursBefore,
  ) {
    return '''Hello ${patient.firstName},

This is a reminder about your upcoming follow-up:

Type: ${followUp.reason}
Scheduled Date: ${followUp.scheduledDate.toString().split(' ')[0]}
Instructions: ${followUp.notes}

Please make sure to complete this follow-up as scheduled.

Contact us if you have any questions.

Thank you,
Doctor''';
  }

  String _buildMedicationReminderMessage(
    Patient patient,
    String medicationName,
    String frequency,
    String instructions,
  ) {
    return '''Hello ${patient.firstName},

Time to take your medication:

Medication: $medicationName
Frequency: $frequency
Instructions: ${instructions.isEmpty ? 'As prescribed' : instructions}

Please take this medication as directed. If you experience any side effects, contact us immediately.

Thank you,
Doctor''';
  }

  String _calculatePriority(Appointment appointment) {
    final hoursUntil = appointment.appointmentDateTime.difference(DateTime.now()).inHours;

    if (hoursUntil <= 2) return 'urgent';
    if (hoursUntil <= 24) return 'high';
    return 'normal';
  }

  List<String> _getPreferredChannels(int minutesBefore) {
    // For urgent reminders (< 24 hours), include SMS and in-app
    if (minutesBefore < 24 * 60) {
      return ['in_app', 'sms', 'email'];
    }
    // For longer range reminders, email is sufficient
    return ['email'];
  }
}

/// Model for a notification message with multi-channel support
class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.scheduledFor,
    required this.priority,
    required this.channels,
    required this.subject,
    required this.body,
    required this.metadata,
    this.sentAt,
    this.failureReason,
    this.retryCount = 0,
  });

  final String id;
  final String type; // 'appointment_reminder', 'follow_up_reminder', 'medication_reminder', 'clinical_alert', 'overdue_followup'
  final String status; // 'pending', 'sent', 'failed', 'overdue'
  final DateTime createdAt;
  final DateTime scheduledFor;
  final String priority; // 'urgent', 'high', 'normal'
  final List<String> channels; // ['sms', 'email', 'whatsapp', 'in_app']
  final String subject;
  final String body;
  final Map<String, String> metadata;
  final DateTime? sentAt;
  final String? failureReason;
  final int retryCount;

  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';
  bool get isOverdue => status == 'overdue';
  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high' || isUrgent;

  Color get priorityColor => priority == 'urgent'
      ? const Color(0xFFDC2626)
      : priority == 'high'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);

  String get displayStatus => status.replaceAll('_', ' ').toUpperCase();

  /// Check if notification should be sent now
  bool get shouldSendNow =>
      isPending && scheduledFor.isBefore(DateTime.now());

  /// Get retry deadline (max 3 retries with exponential backoff)
  bool get canRetry => retryCount < 3;

  /// Get next retry time (exponential backoff: 5 min, 15 min, 60 min)
  Duration get retryDelay {
    switch (retryCount) {
      case 0:
        return const Duration(minutes: 5);
      case 1:
        return const Duration(minutes: 15);
      case 2:
        return const Duration(minutes: 60);
      default:
        return const Duration(hours: 24);
    }
  }
}

/// Model for notification preferences per patient/doctor
class NotificationPreferences {
  const NotificationPreferences({
    required this.id,
    required this.patientId,
    required this.appointmentReminderEnabled,
    required this.appointmentReminderMinutesBefore,
    required this.followUpReminderEnabled,
    required this.followUpReminderHoursBefore,
    required this.medicationReminderEnabled,
    required this.clinicalAlertEnabled,
    required this.preferredChannels,
    required this.doNotDisturbStart,
    required this.doNotDisturbEnd,
    required this.createdAt,
  });

  final int id;
  final int patientId;
  final bool appointmentReminderEnabled;
  final int appointmentReminderMinutesBefore; // default 24*60 = 1440 (24 hours)
  final bool followUpReminderEnabled;
  final int followUpReminderHoursBefore; // default 24
  final bool medicationReminderEnabled;
  final bool clinicalAlertEnabled;
  final List<String> preferredChannels; // ['sms', 'email', 'whatsapp', 'in_app']
  final String doNotDisturbStart; // HH:MM format, e.g., "22:00"
  final String doNotDisturbEnd; // HH:MM format, e.g., "08:00"
  final DateTime createdAt;

  /// Check if currently in do-not-disturb hours
  bool get isInQuietHours {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final start = _parseTime(doNotDisturbStart);
    final end = _parseTime(doNotDisturbEnd);

    // Handle overnight quiet hours (e.g., 22:00 - 08:00)
    if (start.hour > end.hour) {
      return currentTime.hour >= start.hour || currentTime.hour < end.hour;
    }
    return currentTime.hour >= start.hour && currentTime.hour < end.hour;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

/// Model for notification queue item (for offline support)
class NotificationQueueItem {
  const NotificationQueueItem({
    required this.id,
    required this.message,
    required this.channel,
    required this.createdAt,
    required this.attempts,
    this.lastAttemptAt,
    this.nextRetryAt,
  });

  final String id;
  final NotificationMessage message;
  final String channel; // 'sms', 'email', 'whatsapp'
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;

  bool get shouldRetry => attempts < 3 && (nextRetryAt == null || nextRetryAt!.isBefore(DateTime.now()));
}

/// Model for notification statistics
class NotificationStats {
  const NotificationStats({
    required this.totalSent,
    required this.totalFailed,
    required this.totalPending,
    required this.totalOverdue,
    required this.smsSuccessRate,
    required this.emailSuccessRate,
    required this.whatsappSuccessRate,
    required this.avgDeliveryTime,
  });

  final int totalSent;
  final int totalFailed;
  final int totalPending;
  final int totalOverdue;
  final double smsSuccessRate; // 0-1.0
  final double emailSuccessRate; // 0-1.0
  final double whatsappSuccessRate; // 0-1.0
  final Duration avgDeliveryTime;

  double get overallSuccessRate =>
      (smsSuccessRate + emailSuccessRate + whatsappSuccessRate) / 3;
}
