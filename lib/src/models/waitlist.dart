import 'dart:convert';

/// Waitlist status
enum WaitlistStatus {
  waiting('waiting', 'Waiting'),
  contacted('contacted', 'Contacted'),
  scheduled('scheduled', 'Scheduled'),
  cancelled('cancelled', 'Cancelled'),
  expired('expired', 'Expired'),
  noShow('no_show', 'No Show');

  const WaitlistStatus(this.value, this.label);
  final String value;
  final String label;

  static WaitlistStatus fromValue(String value) {
    return WaitlistStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => WaitlistStatus.waiting,
    );
  }
}

/// Waitlist priority
enum WaitlistPriority {
  urgent(1, 'Urgent', 'High priority - needs to be seen ASAP'),
  high(2, 'High', 'Should be seen soon'),
  normal(3, 'Normal', 'Regular waitlist priority'),
  low(4, 'Low', 'Flexible scheduling');

  const WaitlistPriority(this.value, this.label, this.description);
  final int value;
  final String label;
  final String description;

  static WaitlistPriority fromValue(int value) {
    return WaitlistPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WaitlistPriority.normal,
    );
  }
}

/// Preferred time slot
enum PreferredTimeSlot {
  earlyMorning('early_morning', 'Early Morning', '7:00 AM - 9:00 AM'),
  morning('morning', 'Morning', '9:00 AM - 12:00 PM'),
  earlyAfternoon('early_afternoon', 'Early Afternoon', '12:00 PM - 3:00 PM'),
  lateAfternoon('late_afternoon', 'Late Afternoon', '3:00 PM - 5:00 PM'),
  evening('evening', 'Evening', '5:00 PM - 7:00 PM'),
  anyTime('any', 'Any Time', 'Flexible');

  const PreferredTimeSlot(this.value, this.label, this.timeRange);
  final String value;
  final String label;
  final String timeRange;

  static PreferredTimeSlot fromValue(String value) {
    return PreferredTimeSlot.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => PreferredTimeSlot.anyTime,
    );
  }
}

/// Appointment waitlist model
class WaitlistModel {
  const WaitlistModel({
    required this.patientId,
    required this.requestDate,
    required this.appointmentType,
    this.id,
    this.requestedProviderId,
    this.status = WaitlistStatus.waiting,
    this.priority = WaitlistPriority.normal,
    this.reason = '',
    this.preferredDays = const [],
    this.preferredTimeSlots = const [],
    this.minimumNoticeMinutes = 60,
    this.expirationDate,
    this.contactPhone = '',
    this.contactEmail = '',
    this.contactPreference = 'phone',
    this.lastContactDate,
    this.lastContactResult = '',
    this.contactAttempts = 0,
    this.scheduledAppointmentId,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory WaitlistModel.fromJson(Map<String, dynamic> json) {
    return WaitlistModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      requestedProviderId: json['requestedProviderId'] as int? ?? json['requested_provider_id'] as int?,
      requestDate: _parseDateTime(json['requestDate'] ?? json['request_date']) ?? DateTime.now(),
      appointmentType: json['appointmentType'] as String? ?? json['appointment_type'] as String? ?? '',
      status: WaitlistStatus.fromValue(json['status'] as String? ?? 'waiting'),
      priority: WaitlistPriority.fromValue(json['priority'] as int? ?? 3),
      reason: json['reason'] as String? ?? '',
      preferredDays: _parseStringList(json['preferredDays'] ?? json['preferred_days']),
      preferredTimeSlots: _parseTimeSlots(json['preferredTimeSlots'] ?? json['preferred_time_slots']),
      minimumNoticeMinutes: json['minimumNoticeMinutes'] as int? ?? json['minimum_notice_minutes'] as int? ?? 60,
      expirationDate: _parseDateTime(json['expirationDate'] ?? json['expiration_date']),
      contactPhone: json['contactPhone'] as String? ?? json['contact_phone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? json['contact_email'] as String? ?? '',
      contactPreference: json['contactPreference'] as String? ?? json['contact_preference'] as String? ?? 'phone',
      lastContactDate: _parseDateTime(json['lastContactDate'] ?? json['last_contact_date']),
      lastContactResult: json['lastContactResult'] as String? ?? json['last_contact_result'] as String? ?? '',
      contactAttempts: json['contactAttempts'] as int? ?? json['contact_attempts'] as int? ?? 0,
      scheduledAppointmentId: json['scheduledAppointmentId'] as int? ?? json['scheduled_appointment_id'] as int?,
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? requestedProviderId;
  final DateTime requestDate;
  final String appointmentType;
  final WaitlistStatus status;
  final WaitlistPriority priority;
  final String reason;
  final List<String> preferredDays;
  final List<PreferredTimeSlot> preferredTimeSlots;
  final int minimumNoticeMinutes;
  final DateTime? expirationDate;
  final String contactPhone;
  final String contactEmail;
  final String contactPreference;
  final DateTime? lastContactDate;
  final String lastContactResult;
  final int contactAttempts;
  final int? scheduledAppointmentId;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'requestedProviderId': requestedProviderId,
      'requestDate': requestDate.toIso8601String(),
      'appointmentType': appointmentType,
      'status': status.value,
      'priority': priority.value,
      'reason': reason,
      'preferredDays': preferredDays,
      'preferredTimeSlots': preferredTimeSlots.map((e) => e.value).toList(),
      'minimumNoticeMinutes': minimumNoticeMinutes,
      'expirationDate': expirationDate?.toIso8601String(),
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'contactPreference': contactPreference,
      'lastContactDate': lastContactDate?.toIso8601String(),
      'lastContactResult': lastContactResult,
      'contactAttempts': contactAttempts,
      'scheduledAppointmentId': scheduledAppointmentId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  WaitlistModel copyWith({
    int? id,
    int? patientId,
    int? requestedProviderId,
    DateTime? requestDate,
    String? appointmentType,
    WaitlistStatus? status,
    WaitlistPriority? priority,
    String? reason,
    List<String>? preferredDays,
    List<PreferredTimeSlot>? preferredTimeSlots,
    int? minimumNoticeMinutes,
    DateTime? expirationDate,
    String? contactPhone,
    String? contactEmail,
    String? contactPreference,
    DateTime? lastContactDate,
    String? lastContactResult,
    int? contactAttempts,
    int? scheduledAppointmentId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaitlistModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      requestedProviderId: requestedProviderId ?? this.requestedProviderId,
      requestDate: requestDate ?? this.requestDate,
      appointmentType: appointmentType ?? this.appointmentType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      preferredDays: preferredDays ?? this.preferredDays,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      minimumNoticeMinutes: minimumNoticeMinutes ?? this.minimumNoticeMinutes,
      expirationDate: expirationDate ?? this.expirationDate,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPreference: contactPreference ?? this.contactPreference,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      lastContactResult: lastContactResult ?? this.lastContactResult,
      contactAttempts: contactAttempts ?? this.contactAttempts,
      scheduledAppointmentId: scheduledAppointmentId ?? this.scheduledAppointmentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if waitlist entry is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Check if waitlist entry is active
  bool get isActive {
    return status == WaitlistStatus.waiting || status == WaitlistStatus.contacted;
  }

  /// Get days waiting
  int get daysWaiting => DateTime.now().difference(requestDate).inDays;

  /// Get formatted minimum notice
  String get formattedMinimumNotice {
    if (minimumNoticeMinutes < 60) {
      return '$minimumNoticeMinutes minutes';
    } else if (minimumNoticeMinutes < 1440) {
      final hours = minimumNoticeMinutes ~/ 60;
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      final days = minimumNoticeMinutes ~/ 1440;
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  /// Check if a slot matches preferences
  bool matchesSlot({
    required DateTime slotStart,
    required DateTime currentTime,
  }) {
    // Check minimum notice
    final noticeTime = slotStart.difference(currentTime).inMinutes;
    if (noticeTime < minimumNoticeMinutes) return false;

    // Check day preference
    if (preferredDays.isNotEmpty) {
      final dayName = _getDayName(slotStart.weekday);
      if (!preferredDays.contains(dayName)) return false;
    }

    // Check time slot preference
    if (preferredTimeSlots.isNotEmpty && !preferredTimeSlots.contains(PreferredTimeSlot.anyTime)) {
      final hour = slotStart.hour;
      bool timeMatches = false;
      for (final slot in preferredTimeSlots) {
        switch (slot) {
          case PreferredTimeSlot.earlyMorning:
            if (hour >= 7 && hour < 9) timeMatches = true;
            break;
          case PreferredTimeSlot.morning:
            if (hour >= 9 && hour < 12) timeMatches = true;
            break;
          case PreferredTimeSlot.earlyAfternoon:
            if (hour >= 12 && hour < 15) timeMatches = true;
            break;
          case PreferredTimeSlot.lateAfternoon:
            if (hour >= 15 && hour < 17) timeMatches = true;
            break;
          case PreferredTimeSlot.evening:
            if (hour >= 17 && hour < 19) timeMatches = true;
            break;
          case PreferredTimeSlot.anyTime:
            timeMatches = true;
            break;
        }
      }
      if (!timeMatches) return false;
    }

    return true;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  static List<PreferredTimeSlot> _parseTimeSlots(dynamic value) {
    if (value == null) return [];
    final List<String> strings;
    if (value is List) {
      strings = value.map((e) => e.toString()).toList();
    } else if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          strings = decoded.map((e) => e.toString()).toList();
        } else {
          return [];
        }
      } catch (_) {
        return [];
      }
    } else {
      return [];
    }
    return strings.map((s) => PreferredTimeSlot.fromValue(s)).toList();
  }
}
