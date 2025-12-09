/// Clinical reminder status
enum ReminderStatus {
  upcoming('upcoming', 'Upcoming'),
  due('due', 'Due'),
  overdue('overdue', 'Overdue'),
  completed('completed', 'Completed'),
  declined('declined', 'Declined'),
  notApplicable('not_applicable', 'Not Applicable');

  const ReminderStatus(this.value, this.label);
  final String value;
  final String label;

  static ReminderStatus fromValue(String value) {
    return ReminderStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ReminderStatus.due,
    );
  }
}

/// Clinical reminder type
enum ReminderType {
  screening('screening', 'Screening'),
  immunization('immunization', 'Immunization'),
  lab('lab', 'Lab Work'),
  followUp('follow_up', 'Follow-up'),
  medication('medication', 'Medication Review'),
  referral('referral', 'Referral'),
  wellness('wellness', 'Wellness Visit');

  const ReminderType(this.value, this.label);
  final String value;
  final String label;

  static ReminderType fromValue(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ReminderType.screening,
    );
  }
}

/// Clinical reminder data model
class ClinicalReminderModel {
  const ClinicalReminderModel({
    required this.patientId,
    required this.reminderType,
    required this.title,
    required this.dueDate,
    this.id,
    this.description = '',
    this.guidelineSource = '',
    this.recommendation = '',
    this.frequency = '',
    this.lastCompletedDate,
    this.nextDueDate,
    this.status = ReminderStatus.due,
    this.declinedReason = '',
    this.completedEncounterId,
    this.priority = 2,
    this.notificationSent = false,
    this.applicableMinAge,
    this.applicableMaxAge,
    this.applicableGender = 'all',
    this.notes = '',
    this.createdAt,
  });

  factory ClinicalReminderModel.fromJson(Map<String, dynamic> json) {
    return ClinicalReminderModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      reminderType: ReminderType.fromValue(json['reminderType'] as String? ?? json['reminder_type'] as String? ?? 'screening'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      guidelineSource: json['guidelineSource'] as String? ?? json['guideline_source'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
      dueDate: _parseDateTime(json['dueDate'] ?? json['due_date']) ?? DateTime.now(),
      frequency: json['frequency'] as String? ?? '',
      lastCompletedDate: _parseDateTime(json['lastCompletedDate'] ?? json['last_completed_date']),
      nextDueDate: _parseDateTime(json['nextDueDate'] ?? json['next_due_date']),
      status: ReminderStatus.fromValue(json['status'] as String? ?? 'due'),
      declinedReason: json['declinedReason'] as String? ?? json['declined_reason'] as String? ?? '',
      completedEncounterId: json['completedEncounterId'] as int? ?? json['completed_encounter_id'] as int?,
      priority: json['priority'] as int? ?? 2,
      notificationSent: json['notificationSent'] as bool? ?? json['notification_sent'] as bool? ?? false,
      applicableMinAge: json['applicableMinAge'] as int? ?? json['applicable_min_age'] as int?,
      applicableMaxAge: json['applicableMaxAge'] as int? ?? json['applicable_max_age'] as int?,
      applicableGender: json['applicableGender'] as String? ?? json['applicable_gender'] as String? ?? 'all',
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final ReminderType reminderType;
  final String title;
  final String description;
  final String guidelineSource;
  final String recommendation;
  final DateTime dueDate;
  final String frequency;
  final DateTime? lastCompletedDate;
  final DateTime? nextDueDate;
  final ReminderStatus status;
  final String declinedReason;
  final int? completedEncounterId;
  final int priority;
  final bool notificationSent;
  final int? applicableMinAge;
  final int? applicableMaxAge;
  final String applicableGender;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'reminderType': reminderType.value,
      'title': title,
      'description': description,
      'guidelineSource': guidelineSource,
      'recommendation': recommendation,
      'dueDate': dueDate.toIso8601String(),
      'frequency': frequency,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'status': status.value,
      'declinedReason': declinedReason,
      'completedEncounterId': completedEncounterId,
      'priority': priority,
      'notificationSent': notificationSent,
      'applicableMinAge': applicableMinAge,
      'applicableMaxAge': applicableMaxAge,
      'applicableGender': applicableGender,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ClinicalReminderModel copyWith({
    int? id,
    int? patientId,
    ReminderType? reminderType,
    String? title,
    String? description,
    String? guidelineSource,
    String? recommendation,
    DateTime? dueDate,
    String? frequency,
    DateTime? lastCompletedDate,
    DateTime? nextDueDate,
    ReminderStatus? status,
    String? declinedReason,
    int? completedEncounterId,
    int? priority,
    bool? notificationSent,
    int? applicableMinAge,
    int? applicableMaxAge,
    String? applicableGender,
    String? notes,
    DateTime? createdAt,
  }) {
    return ClinicalReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      reminderType: reminderType ?? this.reminderType,
      title: title ?? this.title,
      description: description ?? this.description,
      guidelineSource: guidelineSource ?? this.guidelineSource,
      recommendation: recommendation ?? this.recommendation,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      declinedReason: declinedReason ?? this.declinedReason,
      completedEncounterId: completedEncounterId ?? this.completedEncounterId,
      priority: priority ?? this.priority,
      notificationSent: notificationSent ?? this.notificationSent,
      applicableMinAge: applicableMinAge ?? this.applicableMinAge,
      applicableMaxAge: applicableMaxAge ?? this.applicableMaxAge,
      applicableGender: applicableGender ?? this.applicableGender,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if reminder is overdue
  bool get isOverdue {
    if (status == ReminderStatus.completed || status == ReminderStatus.declined) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if reminder is due soon (within 30 days)
  bool get isDueSoon {
    if (status == ReminderStatus.completed || status == ReminderStatus.declined) return false;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 30;
  }

  /// Get days until due (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Check if reminder is applicable for a patient
  bool isApplicableFor({required int patientAge, required String patientGender}) {
    // Check age
    if (applicableMinAge != null && patientAge < applicableMinAge!) return false;
    if (applicableMaxAge != null && patientAge > applicableMaxAge!) return false;
    
    // Check gender
    if (applicableGender != 'all') {
      if (applicableGender.toLowerCase() != patientGender.toLowerCase()) return false;
    }
    
    return true;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Standard screening recommendations based on USPSTF guidelines
class ScreeningRecommendations {
  static const List<ScreeningGuideline> guidelines = [
    // Cancer screenings
    ScreeningGuideline(
      title: 'Breast Cancer Screening (Mammogram)',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Biennial screening mammography for women aged 50-74',
      frequency: 'every_2_years',
      minAge: 50,
      maxAge: 74,
      gender: 'female',
    ),
    ScreeningGuideline(
      title: 'Cervical Cancer Screening (Pap Smear)',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Pap smear every 3 years for women 21-29, Pap + HPV every 5 years for 30-65',
      frequency: 'every_3_years',
      minAge: 21,
      maxAge: 65,
      gender: 'female',
    ),
    ScreeningGuideline(
      title: 'Colorectal Cancer Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Colonoscopy every 10 years or annual FIT starting at age 45',
      frequency: 'every_10_years',
      minAge: 45,
      maxAge: 75,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Lung Cancer Screening (Low-dose CT)',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Annual low-dose CT for adults 50-80 with 20+ pack-year smoking history',
      frequency: 'annual',
      minAge: 50,
      maxAge: 80,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Prostate Cancer Discussion (PSA)',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Discuss PSA screening with men aged 55-69',
      frequency: 'every_2_years',
      minAge: 55,
      maxAge: 69,
      gender: 'male',
    ),
    
    // Cardiovascular screenings
    ScreeningGuideline(
      title: 'Blood Pressure Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Annual blood pressure screening for adults 18+',
      frequency: 'annual',
      minAge: 18,
      maxAge: null,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Lipid Panel Screening',
      type: ReminderType.lab,
      guidelineSource: 'USPSTF',
      recommendation: 'Lipid screening every 5 years starting at age 40 (35 for high-risk)',
      frequency: 'every_5_years',
      minAge: 40,
      maxAge: 75,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Abdominal Aortic Aneurysm Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'One-time ultrasound for men 65-75 who have ever smoked',
      frequency: 'once',
      minAge: 65,
      maxAge: 75,
      gender: 'male',
    ),
    
    // Metabolic screenings
    ScreeningGuideline(
      title: 'Diabetes Screening',
      type: ReminderType.lab,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen for prediabetes and type 2 diabetes in adults 35-70 with overweight/obesity',
      frequency: 'every_3_years',
      minAge: 35,
      maxAge: 70,
      gender: 'all',
    ),
    
    // Infectious disease screenings
    ScreeningGuideline(
      title: 'HIV Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen all adolescents and adults 15-65 at least once',
      frequency: 'once',
      minAge: 15,
      maxAge: 65,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Hepatitis C Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'One-time screening for all adults 18-79',
      frequency: 'once',
      minAge: 18,
      maxAge: 79,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Hepatitis B Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen all adults 18+ at least once',
      frequency: 'once',
      minAge: 18,
      maxAge: null,
      gender: 'all',
    ),
    
    // Mental health screenings
    ScreeningGuideline(
      title: 'Depression Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen for depression in all adults',
      frequency: 'annual',
      minAge: 18,
      maxAge: null,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Anxiety Screening',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen for anxiety disorders in adults 18-64',
      frequency: 'annual',
      minAge: 18,
      maxAge: 64,
      gender: 'all',
    ),
    
    // Bone health
    ScreeningGuideline(
      title: 'Osteoporosis Screening (DEXA)',
      type: ReminderType.screening,
      guidelineSource: 'USPSTF',
      recommendation: 'Screen women 65+ and postmenopausal women under 65 at increased risk',
      frequency: 'every_2_years',
      minAge: 65,
      maxAge: null,
      gender: 'female',
    ),
    
    // Vision & Hearing
    ScreeningGuideline(
      title: 'Vision Screening',
      type: ReminderType.screening,
      guidelineSource: 'AAO',
      recommendation: 'Comprehensive eye exam every 1-2 years for adults 65+',
      frequency: 'every_2_years',
      minAge: 65,
      maxAge: null,
      gender: 'all',
    ),
    
    // Annual wellness
    ScreeningGuideline(
      title: 'Annual Wellness Visit',
      type: ReminderType.wellness,
      guidelineSource: 'CMS',
      recommendation: 'Annual wellness visit for preventive care planning',
      frequency: 'annual',
      minAge: 18,
      maxAge: null,
      gender: 'all',
    ),
    ScreeningGuideline(
      title: 'Annual Flu Vaccine',
      type: ReminderType.immunization,
      guidelineSource: 'CDC',
      recommendation: 'Annual influenza vaccination for all adults',
      frequency: 'annual',
      minAge: 6,
      maxAge: null,
      gender: 'all',
    ),
  ];

  /// Get applicable screenings for a patient
  static List<ScreeningGuideline> getApplicableFor({
    required int patientAge,
    required String patientGender,
  }) {
    return guidelines.where((g) {
      if (g.minAge != null && patientAge < g.minAge!) return false;
      if (g.maxAge != null && patientAge > g.maxAge!) return false;
      if (g.gender != 'all' && g.gender != patientGender.toLowerCase()) return false;
      return true;
    }).toList();
  }
}

/// Screening guideline definition
class ScreeningGuideline {
  const ScreeningGuideline({
    required this.title,
    required this.type,
    required this.guidelineSource,
    required this.recommendation,
    required this.frequency,
    this.minAge,
    this.maxAge,
    this.gender = 'all',
  });

  final String title;
  final ReminderType type;
  final String guidelineSource;
  final String recommendation;
  final String frequency;
  final int? minAge;
  final int? maxAge;
  final String gender;

  /// Calculate next due date based on frequency
  DateTime calculateNextDueDate(DateTime lastCompleted) {
    switch (frequency) {
      case 'annual':
        return lastCompleted.add(const Duration(days: 365));
      case 'every_2_years':
        return lastCompleted.add(const Duration(days: 730));
      case 'every_3_years':
        return lastCompleted.add(const Duration(days: 1095));
      case 'every_5_years':
        return lastCompleted.add(const Duration(days: 1825));
      case 'every_10_years':
        return lastCompleted.add(const Duration(days: 3650));
      case 'once':
        return DateTime(9999); // Never due again
      default:
        return lastCompleted.add(const Duration(days: 365));
    }
  }

  /// Create a reminder from this guideline
  ClinicalReminderModel toReminder({
    required int patientId,
    required DateTime dueDate,
  }) {
    return ClinicalReminderModel(
      patientId: patientId,
      reminderType: type,
      title: title,
      description: recommendation,
      guidelineSource: guidelineSource,
      recommendation: recommendation,
      dueDate: dueDate,
      frequency: frequency,
      applicableMinAge: minAge,
      applicableMaxAge: maxAge,
      applicableGender: gender,
      priority: 2,
    );
  }
}
