import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../db/doctor_db.dart';
import 'logger_service.dart';

/// Local notification service for scheduling and displaying push notifications
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Notification channel IDs
  static const String appointmentChannelId = 'appointment_reminders';
  static const String followUpChannelId = 'follow_up_reminders';
  static const String medicationChannelId = 'medication_reminders';
  static const String alertChannelId = 'clinical_alerts';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
    log.i('NOTIFICATIONS', 'Local notification service initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Appointment reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        appointmentChannelId,
        'Appointment Reminders',
        description: 'Notifications for upcoming appointments',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Follow-up reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        followUpChannelId,
        'Follow-up Reminders',
        description: 'Notifications for scheduled follow-ups',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Medication reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        medicationChannelId,
        'Medication Reminders',
        description: 'Notifications for medication schedules',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // Clinical alerts channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        alertChannelId,
        'Clinical Alerts',
        description: 'Important clinical alerts and warnings',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    log.d('NOTIFICATIONS', 'Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific screen
    // based on payload (e.g., appointment details)
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final darwinPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await darwinPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    // iOS permissions are checked during request
    return true;
  }

  /// Schedule an appointment reminder notification
  Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String patientName,
    required DateTime appointmentTime,
    required String reason,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    if (!_isInitialized) await initialize();

    final scheduledTime = appointmentTime.subtract(reminderBefore);
    if (scheduledTime.isBefore(DateTime.now())) {
      log.w('NOTIFICATIONS', 'Cannot schedule notification in the past');
      return;
    }

    final reminderText = reminderBefore.inHours >= 24
        ? '${reminderBefore.inDays} day(s)'
        : '${reminderBefore.inHours} hour(s)';

    await _notifications.zonedSchedule(
      appointmentId,
      'Upcoming Appointment',
      '$patientName - ${reason.isEmpty ? "General Visit" : reason} in $reminderText',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          appointmentChannelId,
          'Appointment Reminders',
          channelDescription: 'Notifications for upcoming appointments',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'appointment:$appointmentId',
    );

    log.d('NOTIFICATIONS', 'Scheduled appointment reminder for $patientName at $scheduledTime');
  }

  /// Schedule a follow-up reminder notification
  Future<void> scheduleFollowUpReminder({
    required int followUpId,
    required String patientName,
    required DateTime followUpDate,
    required String reason,
    Duration reminderBefore = const Duration(days: 1),
  }) async {
    if (!_isInitialized) await initialize();

    final scheduledTime = followUpDate.subtract(reminderBefore);
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      followUpId + 100000, // Offset to avoid ID conflicts
      'Follow-up Reminder',
      '$patientName needs a follow-up for: $reason',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          followUpChannelId,
          'Follow-up Reminders',
          channelDescription: 'Notifications for scheduled follow-ups',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'followup:$followUpId',
    );

    log.d('NOTIFICATIONS', 'Scheduled follow-up reminder for $patientName');
  }

  /// Show immediate notification (for alerts)
  Future<void> showClinicalAlert({
    required int alertId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      alertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          alertChannelId,
          'Clinical Alerts',
          channelDescription: 'Important clinical alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFDC2626), // Red for alerts
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    log.d('NOTIFICATIONS', 'Cancelled notification $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    log.d('NOTIFICATIONS', 'Cancelled all notifications');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule reminders for all upcoming appointments
  Future<int> scheduleAllAppointmentReminders(
    DoctorDatabase db, {
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final appointments = await db.getAllAppointments();
    int scheduled = 0;

    for (final apt in appointments) {
      if (apt.appointmentDateTime.isAfter(now) && apt.status == 'scheduled') {
        final patient = await db.getPatientById(apt.patientId);
        if (patient != null) {
          await scheduleAppointmentReminder(
            appointmentId: apt.id,
            patientName: '${patient.firstName} ${patient.lastName}'.trim(),
            appointmentTime: apt.appointmentDateTime,
            reason: apt.reason,
            reminderBefore: reminderBefore,
          );
          scheduled++;
        }
      }    }

    log.i('NOTIFICATIONS', 'Scheduled $scheduled appointment reminders');
    return scheduled;
  }

  /// Schedule reminders for all upcoming follow-ups
  Future<int> scheduleAllFollowUpReminders(
    DoctorDatabase db, {
    Duration reminderBefore = const Duration(days: 1),
  }) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    final followUps = await db.getAllScheduledFollowUps();
    int scheduled = 0;

    for (final followUp in followUps) {
      if (followUp.scheduledDate.isAfter(now) && followUp.status == 'pending') {
        final patient = await db.getPatientById(followUp.patientId);
        if (patient != null) {
          await scheduleFollowUpReminder(
            followUpId: followUp.id,
            patientName: '${patient.firstName} ${patient.lastName}'.trim(),
            followUpDate: followUp.scheduledDate,
            reason: followUp.reason,
            reminderBefore: reminderBefore,
          );
          scheduled++;
        }
      }
    }

    log.i('NOTIFICATIONS', 'Scheduled $scheduled follow-up reminders');
    return scheduled;
  }
}

/// Global instance for easy access
final localNotifications = LocalNotificationService();
