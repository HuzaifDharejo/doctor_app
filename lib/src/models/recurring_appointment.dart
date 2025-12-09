/// Recurrence pattern type
enum RecurrencePattern {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  biweekly('biweekly', 'Every 2 Weeks'),
  monthly('monthly', 'Monthly'),
  quarterly('quarterly', 'Quarterly'),
  custom('custom', 'Custom');

  const RecurrencePattern(this.value, this.label);
  final String value;
  final String label;

  static RecurrencePattern fromValue(String value) {
    return RecurrencePattern.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => RecurrencePattern.weekly,
    );
  }
}

/// Recurring appointment status
enum RecurringAppointmentStatus {
  active('active', 'Active'),
  paused('paused', 'Paused'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const RecurringAppointmentStatus(this.value, this.label);
  final String value;
  final String label;

  static RecurringAppointmentStatus fromValue(String value) {
    return RecurringAppointmentStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => RecurringAppointmentStatus.active,
    );
  }
}

/// Recurring appointment model for chronic care and regular follow-ups
class RecurringAppointmentModel {
  const RecurringAppointmentModel({
    required this.patientId,
    required this.appointmentType,
    required this.recurrencePattern,
    required this.startDate,
    this.id,
    this.providerId,
    this.intervalValue = 1,
    this.preferredDayOfWeek,
    this.preferredTimeOfDay = '09:00',
    this.durationMinutes = 30,
    this.endDate,
    this.maxOccurrences,
    this.occurrencesGenerated = 0,
    this.status = RecurringAppointmentStatus.active,
    this.reason = '',
    this.linkedDiagnosisId,
    this.linkedMedicationId,
    this.notes = '',
    this.autoConfirm = false,
    this.reminderDaysBefore = 3,
    this.lastGeneratedDate,
    this.nextGenerationDate,
    this.skipHolidays = true,
    this.alternateIfConflict = true,
    this.createdAt,
    this.updatedAt,
  });

  factory RecurringAppointmentModel.fromJson(Map<String, dynamic> json) {
    return RecurringAppointmentModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      providerId: json['providerId'] as int? ?? json['provider_id'] as int?,
      appointmentType: json['appointmentType'] as String? ?? json['appointment_type'] as String? ?? '',
      recurrencePattern: RecurrencePattern.fromValue(json['recurrencePattern'] as String? ?? json['recurrence_pattern'] as String? ?? 'weekly'),
      intervalValue: json['intervalValue'] as int? ?? json['interval_value'] as int? ?? 1,
      preferredDayOfWeek: json['preferredDayOfWeek'] as int? ?? json['preferred_day_of_week'] as int?,
      preferredTimeOfDay: json['preferredTimeOfDay'] as String? ?? json['preferred_time_of_day'] as String? ?? '09:00',
      durationMinutes: json['durationMinutes'] as int? ?? json['duration_minutes'] as int? ?? 30,
      startDate: _parseDateTime(json['startDate'] ?? json['start_date']) ?? DateTime.now(),
      endDate: _parseDateTime(json['endDate'] ?? json['end_date']),
      maxOccurrences: json['maxOccurrences'] as int? ?? json['max_occurrences'] as int?,
      occurrencesGenerated: json['occurrencesGenerated'] as int? ?? json['occurrences_generated'] as int? ?? 0,
      status: RecurringAppointmentStatus.fromValue(json['status'] as String? ?? 'active'),
      reason: json['reason'] as String? ?? '',
      linkedDiagnosisId: json['linkedDiagnosisId'] as int? ?? json['linked_diagnosis_id'] as int?,
      linkedMedicationId: json['linkedMedicationId'] as int? ?? json['linked_medication_id'] as int?,
      notes: json['notes'] as String? ?? '',
      autoConfirm: json['autoConfirm'] as bool? ?? json['auto_confirm'] as bool? ?? false,
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? json['reminder_days_before'] as int? ?? 3,
      lastGeneratedDate: _parseDateTime(json['lastGeneratedDate'] ?? json['last_generated_date']),
      nextGenerationDate: _parseDateTime(json['nextGenerationDate'] ?? json['next_generation_date']),
      skipHolidays: json['skipHolidays'] as bool? ?? json['skip_holidays'] as bool? ?? true,
      alternateIfConflict: json['alternateIfConflict'] as bool? ?? json['alternate_if_conflict'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? providerId;
  final String appointmentType;
  final RecurrencePattern recurrencePattern;
  final int intervalValue;
  final int? preferredDayOfWeek;
  final String preferredTimeOfDay;
  final int durationMinutes;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int occurrencesGenerated;
  final RecurringAppointmentStatus status;
  final String reason;
  final int? linkedDiagnosisId;
  final int? linkedMedicationId;
  final String notes;
  final bool autoConfirm;
  final int reminderDaysBefore;
  final DateTime? lastGeneratedDate;
  final DateTime? nextGenerationDate;
  final bool skipHolidays;
  final bool alternateIfConflict;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'providerId': providerId,
      'appointmentType': appointmentType,
      'recurrencePattern': recurrencePattern.value,
      'intervalValue': intervalValue,
      'preferredDayOfWeek': preferredDayOfWeek,
      'preferredTimeOfDay': preferredTimeOfDay,
      'durationMinutes': durationMinutes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'occurrencesGenerated': occurrencesGenerated,
      'status': status.value,
      'reason': reason,
      'linkedDiagnosisId': linkedDiagnosisId,
      'linkedMedicationId': linkedMedicationId,
      'notes': notes,
      'autoConfirm': autoConfirm,
      'reminderDaysBefore': reminderDaysBefore,
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'nextGenerationDate': nextGenerationDate?.toIso8601String(),
      'skipHolidays': skipHolidays,
      'alternateIfConflict': alternateIfConflict,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  RecurringAppointmentModel copyWith({
    int? id,
    int? patientId,
    int? providerId,
    String? appointmentType,
    RecurrencePattern? recurrencePattern,
    int? intervalValue,
    int? preferredDayOfWeek,
    String? preferredTimeOfDay,
    int? durationMinutes,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? occurrencesGenerated,
    RecurringAppointmentStatus? status,
    String? reason,
    int? linkedDiagnosisId,
    int? linkedMedicationId,
    String? notes,
    bool? autoConfirm,
    int? reminderDaysBefore,
    DateTime? lastGeneratedDate,
    DateTime? nextGenerationDate,
    bool? skipHolidays,
    bool? alternateIfConflict,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringAppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      providerId: providerId ?? this.providerId,
      appointmentType: appointmentType ?? this.appointmentType,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      intervalValue: intervalValue ?? this.intervalValue,
      preferredDayOfWeek: preferredDayOfWeek ?? this.preferredDayOfWeek,
      preferredTimeOfDay: preferredTimeOfDay ?? this.preferredTimeOfDay,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      occurrencesGenerated: occurrencesGenerated ?? this.occurrencesGenerated,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      linkedDiagnosisId: linkedDiagnosisId ?? this.linkedDiagnosisId,
      linkedMedicationId: linkedMedicationId ?? this.linkedMedicationId,
      notes: notes ?? this.notes,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      nextGenerationDate: nextGenerationDate ?? this.nextGenerationDate,
      skipHolidays: skipHolidays ?? this.skipHolidays,
      alternateIfConflict: alternateIfConflict ?? this.alternateIfConflict,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if recurring appointment is still active
  bool get isActive {
    if (status != RecurringAppointmentStatus.active) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    if (maxOccurrences != null && occurrencesGenerated >= maxOccurrences!) return false;
    return true;
  }

  /// Get remaining occurrences
  int? get remainingOccurrences {
    if (maxOccurrences == null) return null;
    return maxOccurrences! - occurrencesGenerated;
  }

  /// Get formatted recurrence description
  String get recurrenceDescription {
    switch (recurrencePattern) {
      case RecurrencePattern.daily:
        return intervalValue == 1 ? 'Every day' : 'Every $intervalValue days';
      case RecurrencePattern.weekly:
        final dayName = preferredDayOfWeek != null ? _getDayName(preferredDayOfWeek!) : '';
        if (intervalValue == 1) {
          return dayName.isNotEmpty ? 'Every $dayName' : 'Every week';
        }
        return dayName.isNotEmpty 
            ? 'Every $intervalValue weeks on $dayName' 
            : 'Every $intervalValue weeks';
      case RecurrencePattern.biweekly:
        final dayName = preferredDayOfWeek != null ? _getDayName(preferredDayOfWeek!) : '';
        return dayName.isNotEmpty ? 'Every 2 weeks on $dayName' : 'Every 2 weeks';
      case RecurrencePattern.monthly:
        return intervalValue == 1 ? 'Every month' : 'Every $intervalValue months';
      case RecurrencePattern.quarterly:
        return 'Every 3 months';
      case RecurrencePattern.custom:
        return 'Custom schedule';
    }
  }

  /// Calculate next occurrence date from a given date
  DateTime calculateNextOccurrence(DateTime fromDate) {
    DateTime next = fromDate;
    
    switch (recurrencePattern) {
      case RecurrencePattern.daily:
        next = fromDate.add(Duration(days: intervalValue));
        break;
      case RecurrencePattern.weekly:
        next = fromDate.add(Duration(days: 7 * intervalValue));
        if (preferredDayOfWeek != null) {
          while (next.weekday != preferredDayOfWeek) {
            next = next.add(const Duration(days: 1));
          }
        }
        break;
      case RecurrencePattern.biweekly:
        next = fromDate.add(const Duration(days: 14));
        if (preferredDayOfWeek != null) {
          while (next.weekday != preferredDayOfWeek) {
            next = next.add(const Duration(days: 1));
          }
        }
        break;
      case RecurrencePattern.monthly:
        next = DateTime(
          fromDate.year,
          fromDate.month + intervalValue,
          fromDate.day,
          fromDate.hour,
          fromDate.minute,
        );
        break;
      case RecurrencePattern.quarterly:
        next = DateTime(
          fromDate.year,
          fromDate.month + 3,
          fromDate.day,
          fromDate.hour,
          fromDate.minute,
        );
        break;
      case RecurrencePattern.custom:
        next = fromDate.add(Duration(days: intervalValue));
        break;
    }

    // Parse and apply preferred time
    final timeParts = preferredTimeOfDay.split(':');
    if (timeParts.length == 2) {
      final hour = int.tryParse(timeParts[0]) ?? 9;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      next = DateTime(next.year, next.month, next.day, hour, minute);
    }

    return next;
  }

  /// Generate multiple future occurrences
  List<DateTime> generateOccurrences({
    required int count,
    DateTime? startingFrom,
    List<DateTime>? holidays,
  }) {
    final List<DateTime> occurrences = [];
    DateTime current = startingFrom ?? startDate;

    while (occurrences.length < count) {
      current = calculateNextOccurrence(current);
      
      // Check if end date is exceeded
      if (endDate != null && current.isAfter(endDate!)) break;
      
      // Check if max occurrences would be exceeded
      if (maxOccurrences != null && 
          (occurrencesGenerated + occurrences.length) >= maxOccurrences!) break;
      
      // Skip holidays if configured
      if (skipHolidays && holidays != null) {
        final isHoliday = holidays.any((h) => 
          h.year == current.year && 
          h.month == current.month && 
          h.day == current.day
        );
        if (isHoliday) {
          // Move to next weekday
          current = current.add(const Duration(days: 1));
          while (current.weekday == DateTime.saturday || 
                 current.weekday == DateTime.sunday) {
            current = current.add(const Duration(days: 1));
          }
        }
      }
      
      occurrences.add(current);
    }

    return occurrences;
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
}

/// Common recurring appointment templates
class RecurringAppointmentTemplates {
  static const List<RecurringAppointmentTemplate> templates = [
    // Chronic disease management
    RecurringAppointmentTemplate(
      name: 'Diabetes Follow-up',
      appointmentType: 'Diabetes Management',
      recurrencePattern: RecurrencePattern.quarterly,
      durationMinutes: 30,
      reason: 'Quarterly diabetes management and A1C check',
    ),
    RecurringAppointmentTemplate(
      name: 'Hypertension Follow-up',
      appointmentType: 'Blood Pressure Check',
      recurrencePattern: RecurrencePattern.monthly,
      durationMinutes: 15,
      reason: 'Monthly blood pressure monitoring',
    ),
    RecurringAppointmentTemplate(
      name: 'CHF Management',
      appointmentType: 'Heart Failure Follow-up',
      recurrencePattern: RecurrencePattern.monthly,
      durationMinutes: 30,
      reason: 'Monthly heart failure management',
    ),
    RecurringAppointmentTemplate(
      name: 'COPD Follow-up',
      appointmentType: 'Pulmonary Follow-up',
      recurrencePattern: RecurrencePattern.quarterly,
      durationMinutes: 30,
      reason: 'Quarterly COPD management',
    ),
    RecurringAppointmentTemplate(
      name: 'CKD Monitoring',
      appointmentType: 'Kidney Disease Follow-up',
      recurrencePattern: RecurrencePattern.quarterly,
      durationMinutes: 30,
      reason: 'Quarterly kidney function monitoring',
    ),
    
    // Mental health
    RecurringAppointmentTemplate(
      name: 'Therapy Session',
      appointmentType: 'Mental Health',
      recurrencePattern: RecurrencePattern.weekly,
      durationMinutes: 45,
      reason: 'Weekly therapy session',
    ),
    RecurringAppointmentTemplate(
      name: 'Medication Management',
      appointmentType: 'Psychiatric Follow-up',
      recurrencePattern: RecurrencePattern.monthly,
      durationMinutes: 20,
      reason: 'Monthly medication review',
    ),
    
    // Preventive care
    RecurringAppointmentTemplate(
      name: 'Annual Physical',
      appointmentType: 'Wellness Visit',
      recurrencePattern: RecurrencePattern.custom,
      intervalValue: 365,
      durationMinutes: 45,
      reason: 'Annual comprehensive physical examination',
    ),
    RecurringAppointmentTemplate(
      name: 'Pediatric Well-Child',
      appointmentType: 'Well-Child Visit',
      recurrencePattern: RecurrencePattern.custom,
      intervalValue: 90,
      durationMinutes: 30,
      reason: 'Routine well-child examination',
    ),
    
    // Specialty follow-ups
    RecurringAppointmentTemplate(
      name: 'INR Check',
      appointmentType: 'Lab Work',
      recurrencePattern: RecurrencePattern.weekly,
      durationMinutes: 15,
      reason: 'Weekly INR monitoring for anticoagulation',
    ),
    RecurringAppointmentTemplate(
      name: 'Allergy Shots',
      appointmentType: 'Immunotherapy',
      recurrencePattern: RecurrencePattern.weekly,
      durationMinutes: 30,
      reason: 'Weekly allergy immunotherapy',
    ),
  ];
}

/// Template for creating recurring appointments
class RecurringAppointmentTemplate {
  const RecurringAppointmentTemplate({
    required this.name,
    required this.appointmentType,
    required this.recurrencePattern,
    required this.durationMinutes,
    required this.reason,
    this.intervalValue = 1,
  });

  final String name;
  final String appointmentType;
  final RecurrencePattern recurrencePattern;
  final int intervalValue;
  final int durationMinutes;
  final String reason;

  /// Create a recurring appointment from this template
  RecurringAppointmentModel toRecurringAppointment({
    required int patientId,
    required DateTime startDate,
    int? providerId,
    int? preferredDayOfWeek,
    String? preferredTimeOfDay,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    return RecurringAppointmentModel(
      patientId: patientId,
      providerId: providerId,
      appointmentType: appointmentType,
      recurrencePattern: recurrencePattern,
      intervalValue: intervalValue,
      preferredDayOfWeek: preferredDayOfWeek,
      preferredTimeOfDay: preferredTimeOfDay ?? '09:00',
      durationMinutes: durationMinutes,
      startDate: startDate,
      endDate: endDate,
      maxOccurrences: maxOccurrences,
      reason: reason,
    );
  }
}
