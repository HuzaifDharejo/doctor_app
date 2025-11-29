import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import '../services/google_calendar_service.dart';

/// State class for Google Calendar connection
class GoogleCalendarState {
  final bool isConnected;
  final bool isLoading;
  final String? userEmail;
  final String? userName;
  final String? userPhotoUrl;
  final String? error;
  final List<gcal.CalendarListEntry> calendars;
  final String selectedCalendarId;

  const GoogleCalendarState({
    this.isConnected = false,
    this.isLoading = false,
    this.userEmail,
    this.userName,
    this.userPhotoUrl,
    this.error,
    this.calendars = const [],
    this.selectedCalendarId = 'primary',
  });

  GoogleCalendarState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? userEmail,
    String? userName,
    String? userPhotoUrl,
    String? error,
    List<gcal.CalendarListEntry>? calendars,
    String? selectedCalendarId,
  }) {
    return GoogleCalendarState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      error: error,
      calendars: calendars ?? this.calendars,
      selectedCalendarId: selectedCalendarId ?? this.selectedCalendarId,
    );
  }
}

/// Notifier for managing Google Calendar state
class GoogleCalendarNotifier extends StateNotifier<GoogleCalendarState> {
  final GoogleCalendarService _service;

  GoogleCalendarNotifier(this._service) : super(const GoogleCalendarState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    final isConnected = await _service.isConnected();
    if (isConnected) {
      final email = await _service.getConnectedEmail();
      final name = await _service.getConnectedName();
      final photoUrl = await _service.getConnectedPhotoUrl();
      final calendarId = await _service.getSelectedCalendarId();
      
      // Try to get calendars
      final calendars = await _service.getCalendars();
      
      state = state.copyWith(
        isConnected: true,
        isLoading: false,
        userEmail: email,
        userName: name,
        userPhotoUrl: photoUrl,
        calendars: calendars,
        selectedCalendarId: calendarId,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sign in with Google and return user info for SSO
  Future<GoogleUserInfo?> signInAndGetUserInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final userInfo = await _service.signInAndGetUserInfo();
    
    if (userInfo != null) {
      final calendars = await _service.getCalendars();
      final calendarId = await _service.getSelectedCalendarId();
      
      state = state.copyWith(
        isConnected: true,
        isLoading: false,
        userEmail: userInfo.email,
        userName: userInfo.displayName,
        userPhotoUrl: userInfo.photoUrl,
        calendars: calendars,
        selectedCalendarId: calendarId,
      );
      return userInfo;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in with Google',
      );
      return null;
    }
  }

  Future<bool> signIn() async {
    final userInfo = await signInAndGetUserInfo();
    return userInfo != null;
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _service.signOut();
    state = const GoogleCalendarState();
  }

  Future<void> setSelectedCalendar(String calendarId) async {
    await _service.setSelectedCalendarId(calendarId);
    state = state.copyWith(selectedCalendarId: calendarId);
  }

  Future<void> refreshCalendars() async {
    final calendars = await _service.getCalendars();
    state = state.copyWith(calendars: calendars);
  }

  /// Get events for a specific day
  Future<List<gcal.Event>> getEventsForDay(DateTime day) async {
    if (!state.isConnected) return [];
    return _service.getEventsForDay(day);
  }

  /// Get available time slots for a day
  Future<List<TimeSlot>> getAvailableSlots({
    required DateTime date,
    Duration slotDuration = const Duration(minutes: 30),
    CalendarTimeOfDay startTime = const CalendarTimeOfDay(hour: 9, minute: 0),
    CalendarTimeOfDay endTime = const CalendarTimeOfDay(hour: 17, minute: 0),
  }) async {
    if (!state.isConnected) return [];
    return _service.getAvailableSlots(
      date: date,
      slotDuration: slotDuration,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Create an appointment event
  Future<gcal.Event?> createAppointmentEvent({
    required String patientName,
    required DateTime startTime,
    required int durationMinutes,
    String? reason,
    String? notes,
    String? patientPhone,
    String? patientEmail,
  }) async {
    if (!state.isConnected) return null;
    return _service.createAppointmentEvent(
      patientName: patientName,
      startTime: startTime,
      durationMinutes: durationMinutes,
      reason: reason,
      notes: notes,
      patientPhone: patientPhone,
      patientEmail: patientEmail,
    );
  }

  /// Update an appointment event
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
    if (!state.isConnected) return null;
    return _service.updateAppointmentEvent(
      eventId: eventId,
      patientName: patientName,
      startTime: startTime,
      durationMinutes: durationMinutes,
      reason: reason,
      notes: notes,
      patientPhone: patientPhone,
      patientEmail: patientEmail,
    );
  }

  /// Delete an appointment event
  Future<bool> deleteAppointmentEvent(String eventId) async {
    if (!state.isConnected) return false;
    return _service.deleteAppointmentEvent(eventId);
  }
}

/// Provider for Google Calendar service
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

/// Provider for Google Calendar state
final googleCalendarProvider = StateNotifierProvider<GoogleCalendarNotifier, GoogleCalendarState>((ref) {
  final service = ref.watch(googleCalendarServiceProvider);
  return GoogleCalendarNotifier(service);
});

/// Provider to check if calendar sync is enabled
final isCalendarSyncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(googleCalendarProvider).isConnected;
});
