import 'dart:convert';

/// Appointment status enum
enum AppointmentStatus {
  scheduled('scheduled', 'Scheduled'),
  confirmed('confirmed', 'Confirmed'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  noShow('no_show', 'No Show'),
  rescheduled('rescheduled', 'Rescheduled');

  const AppointmentStatus(this.value, this.label);

  final String value;
  final String label;

  static AppointmentStatus fromValue(String value) {
    return AppointmentStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}

/// Appointment data model
class AppointmentModel {

  const AppointmentModel({
    required this.patientId, required this.appointmentDateTime, this.id,
    this.patientName,
    this.durationMinutes = 15,
    this.reason = '',
    this.status = AppointmentStatus.scheduled,
    this.reminderAt,
    this.notes = '',
    this.createdAt,
    this.medicalRecordId,
  });

  /// Create from JSON map
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? json['patient_name'] as String?,
      appointmentDateTime: json['appointmentDateTime'] != null
          ? DateTime.parse(json['appointmentDateTime'] as String)
          : json['appointment_date_time'] != null
              ? DateTime.parse(json['appointment_date_time'] as String)
              : DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? json['duration_minutes'] as int? ?? 15,
      reason: json['reason'] as String? ?? '',
      status: AppointmentStatus.fromValue(json['status'] as String? ?? 'scheduled'),
      reminderAt: json['reminderAt'] != null
          ? DateTime.tryParse(json['reminderAt'] as String)
          : json['reminder_at'] != null
              ? DateTime.tryParse(json['reminder_at'] as String)
              : null,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      medicalRecordId: json['medicalRecordId'] as int? ?? json['medical_record_id'] as int?,
    );
  }

  /// Create from JSON string
  factory AppointmentModel.fromJsonString(String jsonString) {
    return AppointmentModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
  final int? id;
  final int patientId;
  final String? patientName; // For display purposes (not stored in DB)
  final DateTime appointmentDateTime;
  final int durationMinutes;
  final String reason;
  final AppointmentStatus status;
  final DateTime? reminderAt;
  final String notes;
  final DateTime? createdAt;
  final int? medicalRecordId; // Link to assessment done during visit

  /// Get the end time of the appointment
  DateTime get endDateTime => appointmentDateTime.add(Duration(minutes: durationMinutes));

  /// Check if appointment is in the past
  bool get isPast => appointmentDateTime.isBefore(DateTime.now());

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDateTime.year == now.year &&
        appointmentDateTime.month == now.month &&
        appointmentDateTime.day == now.day;
  }

  /// Check if appointment is upcoming (within next hour)
  bool get isUpcoming {
    final now = DateTime.now();
    final diff = appointmentDateTime.difference(now);
    return diff.inMinutes > 0 && diff.inMinutes <= 60;
  }

  /// Get formatted time (e.g., "10:30 AM")
  String get formattedTime {
    final hour = appointmentDateTime.hour;
    final minute = appointmentDateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get formatted date (e.g., "Dec 25, 2024")
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[appointmentDateTime.month - 1]} ${appointmentDateTime.day}, ${appointmentDateTime.year}';
  }

  /// Get formatted duration (e.g., "30 min" or "1 hr 30 min")
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'reason': reason,
      'status': status.value,
      if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
      'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with modified fields
  AppointmentModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    DateTime? appointmentDateTime,
    int? durationMinutes,
    String? reason,
    AppointmentStatus? status,
    DateTime? reminderAt,
    String? notes,
    DateTime? createdAt,
    int? medicalRecordId,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      appointmentDateTime: appointmentDateTime ?? this.appointmentDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reminderAt: reminderAt ?? this.reminderAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel &&
        other.id == id &&
        other.patientId == patientId &&
        other.appointmentDateTime == appointmentDateTime &&
        other.durationMinutes == durationMinutes &&
        other.reason == reason &&
        other.status == status &&
        other.medicalRecordId == medicalRecordId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        patientId,
        appointmentDateTime,
        durationMinutes,
        reason,
        status,
        medicalRecordId,
      );

  @override
  String toString() => 'AppointmentModel(id: $id, patientId: $patientId, dateTime: $appointmentDateTime, status: ${status.label}, medicalRecordId: $medicalRecordId)';
}
