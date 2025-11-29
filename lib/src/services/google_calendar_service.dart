import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// User info from Google Sign-In
class GoogleUserInfo {

  GoogleUserInfo({
    required this.email,
    this.displayName,
    this.photoUrl,
    this.id,
  });
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? id;

  String get firstName {
    if (displayName == null || displayName!.isEmpty) return '';
    final parts = displayName!.split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String get lastName {
    if (displayName == null || displayName!.isEmpty) return '';
    final parts = displayName!.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }
}

/// Service for managing Google Calendar integration
class GoogleCalendarService {
  static const String _connectedKey = 'google_calendar_connected';
  static const String _calendarIdKey = 'google_calendar_id';
  static const String _userEmailKey = 'google_user_email';
  static const String _userNameKey = 'google_user_name';
  static const String _userPhotoKey = 'google_user_photo';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      gcal.CalendarApi.calendarScope,
      gcal.CalendarApi.calendarEventsScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  gcal.CalendarApi? _calendarApi;
  
  // Stream controller for connection state changes
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Get current user info
  GoogleUserInfo? get currentUserInfo {
    if (_currentUser == null) return null;
    return GoogleUserInfo(
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      photoUrl: _currentUser!.photoUrl,
      id: _currentUser!.id,
    );
  }

  /// Check if already signed in
  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedKey) ?? false;
  }

  /// Get connected user email
  Future<String?> getConnectedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get connected user name
  Future<String?> getConnectedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Get connected user photo URL
  Future<String?> getConnectedPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhotoKey);
  }

  /// Sign in to Google and authorize Calendar access
  /// Returns GoogleUserInfo on success, null on failure
  Future<GoogleUserInfo?> signInAndGetUserInfo() async {
    try {
      // Try silent sign in first
      _currentUser = await _googleSignIn.signInSilently();
      
      // If that fails, do interactive sign in
      _currentUser ??= await _googleSignIn.signIn();
      
      if (_currentUser == null) {
        return null;
      }

      // Get auth headers for API calls
      final authHeaders = await _currentUser!.authHeaders;
      final authenticatedClient = GoogleAuthClient(authHeaders);
      _calendarApi = gcal.CalendarApi(authenticatedClient);

      // Save connection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_connectedKey, true);
      await prefs.setString(_userEmailKey, _currentUser!.email);
      await prefs.setString(_userNameKey, _currentUser!.displayName ?? '');
      if (_currentUser!.photoUrl != null) {
        await prefs.setString(_userPhotoKey, _currentUser!.photoUrl!);
      }

      _connectionStateController.add(true);
      
      return GoogleUserInfo(
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        photoUrl: _currentUser!.photoUrl,
        id: _currentUser!.id,
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign in to Google and authorize Calendar access (legacy method)
  Future<bool> signIn() async {
    final userInfo = await signInAndGetUserInfo();
    return userInfo != null;
  }

  /// Sign out and disconnect Google Calendar
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_connectedKey, false);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userPhotoKey);
      await prefs.remove(_calendarIdKey);

      _connectionStateController.add(false);
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }
  }

  /// Ensure we have a valid API connection
  Future<gcal.CalendarApi?> _ensureApi() async {
    if (_calendarApi != null) return _calendarApi;

    _currentUser = await _googleSignIn.signInSilently();
    if (_currentUser == null) return null;

    final authHeaders = await _currentUser!.authHeaders;
    final authenticatedClient = GoogleAuthClient(authHeaders);
    _calendarApi = gcal.CalendarApi(authenticatedClient);
    return _calendarApi;
  }

  /// Get list of calendars
  Future<List<gcal.CalendarListEntry>> getCalendars() async {
    final api = await _ensureApi();
    if (api == null) return [];

    try {
      final calendarList = await api.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      debugPrint('Error fetching calendars: $e');
      return [];
    }
  }

  /// Get or set the selected calendar ID for appointments
  Future<String> getSelectedCalendarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_calendarIdKey) ?? 'primary';
  }

  Future<void> setSelectedCalendarId(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarIdKey, calendarId);
  }

  /// Get events for a specific date range
  Future<List<gcal.Event>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
    String? calendarId,
  }) async {
    final api = await _ensureApi();
    if (api == null) return [];

    final selectedCalendarId = calendarId ?? await getSelectedCalendarId();

    try {
      final events = await api.events.list(
        selectedCalendarId,
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  /// Get events for a specific day
  Future<List<gcal.Event>> getEventsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return getEvents(startDate: start, endDate: end);
  }

  /// Get free/busy information for a date range
  Future<List<TimeSlot>> getAvailableSlots({
    required DateTime date,
    required Duration slotDuration,
    CalendarTimeOfDay startTime = const CalendarTimeOfDay(hour: 9, minute: 0),
    CalendarTimeOfDay endTime = const CalendarTimeOfDay(hour: 17, minute: 0),
  }) async {
    final api = await _ensureApi();
    if (api == null) return [];

    final dayStart = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
    final dayEnd = DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

    try {
      // Get all events for the day
      final events = await getEvents(
        startDate: dayStart,
        endDate: dayEnd,
      );

      // Build list of busy periods
      final busyPeriods = <DateTimeRange>[];
      for (final event in events) {
        if (event.start?.dateTime != null && event.end?.dateTime != null) {
          busyPeriods.add(DateTimeRange(
            start: event.start!.dateTime!.toLocal(),
            end: event.end!.dateTime!.toLocal(),
          ),);
        }
      }

      // Generate available slots
      final slots = <TimeSlot>[];
      var currentSlotStart = dayStart;

      while (currentSlotStart.add(slotDuration).isBefore(dayEnd) ||
          currentSlotStart.add(slotDuration).isAtSameMomentAs(dayEnd)) {
        final slotEnd = currentSlotStart.add(slotDuration);
        
        // Check if this slot conflicts with any busy period
        bool isAvailable = true;
        for (final busy in busyPeriods) {
          if (!(slotEnd.isBefore(busy.start) || currentSlotStart.isAfter(busy.end) ||
              currentSlotStart.isAtSameMomentAs(busy.end))) {
            isAvailable = false;
            break;
          }
        }

        slots.add(TimeSlot(
          startTime: currentSlotStart,
          endTime: slotEnd,
          isAvailable: isAvailable,
        ),);

        currentSlotStart = slotEnd;
      }

      return slots;
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }

  /// Create a calendar event for an appointment
  Future<gcal.Event?> createAppointmentEvent({
    required String patientName,
    required DateTime startTime,
    required int durationMinutes,
    String? reason,
    String? notes,
    String? patientPhone,
    String? patientEmail,
  }) async {
    final api = await _ensureApi();
    if (api == null) return null;

    final selectedCalendarId = await getSelectedCalendarId();
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final event = gcal.Event()
      ..summary = 'Appointment: $patientName'
      ..description = _buildEventDescription(reason, notes, patientPhone, patientEmail)
      ..start = (gcal.EventDateTime()..dateTime = startTime.toUtc()..timeZone = 'UTC')
      ..end = (gcal.EventDateTime()..dateTime = endTime.toUtc()..timeZone = 'UTC')
      ..reminders = (gcal.EventReminders()
        ..useDefault = false
        ..overrides = [
          gcal.EventReminder()
            ..method = 'popup'
            ..minutes = 30,
          gcal.EventReminder()
            ..method = 'popup'
            ..minutes = 10,
        ]);

    // Add patient email as attendee if provided
    if (patientEmail != null && patientEmail.isNotEmpty) {
      event.attendees = [
        gcal.EventAttendee()
          ..email = patientEmail
          ..displayName = patientName,
      ];
    }

    try {
      final createdEvent = await api.events.insert(event, selectedCalendarId);
      return createdEvent;
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return null;
    }
  }

  /// Update an existing calendar event
  Future<gcal.Event?> updateAppointmentEvent({
    required String eventId,
    required String patientName,
    required DateTime startTime,
    required int durationMinutes,
    String? reason,
    String? notes,
    String? patientPhone,
    String? patientEmail,
  }) async {
    final api = await _ensureApi();
    if (api == null) return null;

    final selectedCalendarId = await getSelectedCalendarId();
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    try {
      final existingEvent = await api.events.get(selectedCalendarId, eventId);
      
      existingEvent
        ..summary = 'Appointment: $patientName'
        ..description = _buildEventDescription(reason, notes, patientPhone, patientEmail)
        ..start = (gcal.EventDateTime()..dateTime = startTime.toUtc()..timeZone = 'UTC')
        ..end = (gcal.EventDateTime()..dateTime = endTime.toUtc()..timeZone = 'UTC');

      final updatedEvent = await api.events.update(existingEvent, selectedCalendarId, eventId);
      return updatedEvent;
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteAppointmentEvent(String eventId) async {
    final api = await _ensureApi();
    if (api == null) return false;

    final selectedCalendarId = await getSelectedCalendarId();

    try {
      await api.events.delete(selectedCalendarId, eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }

  /// Build event description from appointment details
  String _buildEventDescription(String? reason, String? notes, String? phone, String? email) {
    final buffer = StringBuffer();
    
    if (reason != null && reason.isNotEmpty) {
      buffer.writeln('Reason: $reason');
    }
    if (notes != null && notes.isNotEmpty) {
      buffer.writeln('\nNotes: $notes');
    }
    if (phone != null && phone.isNotEmpty) {
      buffer.writeln('\nPhone: $phone');
    }
    if (email != null && email.isNotEmpty) {
      buffer.writeln('Email: $email');
    }
    
    buffer.writeln('\n---\nCreated by Doctor App');
    
    return buffer.toString();
  }

  void dispose() {
    _connectionStateController.close();
  }
}

/// HTTP client wrapper for Google API authentication
class GoogleAuthClient extends http.BaseClient {

  GoogleAuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Represents a time slot with availability status
class TimeSlot {

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  Duration get duration => endTime.difference(startTime);
}

/// Helper class for time of day (for slot generation)
class CalendarTimeOfDay {

  const CalendarTimeOfDay({required this.hour, required this.minute});
  final int hour;
  final int minute;
}

/// Date range helper
class DateTimeRange {

  DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
