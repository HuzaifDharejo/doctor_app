import 'dart:convert';

/// Referral urgency levels
enum ReferralUrgency {
  stat('stat', 'STAT', 'Immediate/Emergency'),
  urgent('urgent', 'Urgent', 'Within 24-48 hours'),
  routine('routine', 'Routine', 'Standard scheduling'),
  elective('elective', 'Elective', 'When convenient');

  const ReferralUrgency(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static ReferralUrgency fromValue(String value) {
    return ReferralUrgency.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ReferralUrgency.routine,
    );
  }
}

/// Referral status
enum ReferralStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending'),
  sent('sent', 'Sent'),
  accepted('accepted', 'Accepted'),
  scheduled('scheduled', 'Scheduled'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  rejected('rejected', 'Rejected');

  const ReferralStatus(this.value, this.label);
  final String value;
  final String label;

  static ReferralStatus fromValue(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ReferralStatus.pending,
    );
  }
}

/// Referral type
enum ReferralType {
  specialist('specialist', 'Specialist Consultation'),
  diagnostic('diagnostic', 'Diagnostic Testing'),
  therapy('therapy', 'Therapy/Rehabilitation'),
  surgery('surgery', 'Surgical Evaluation'),
  emergency('emergency', 'Emergency Transfer'),
  secondOpinion('second_opinion', 'Second Opinion');

  const ReferralType(this.value, this.label);
  final String value;
  final String label;

  static ReferralType fromValue(String value) {
    return ReferralType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ReferralType.specialist,
    );
  }
}

/// Common medical specialties for referrals
class MedicalSpecialties {
  static const List<String> all = [
    'Allergy & Immunology',
    'Anesthesiology',
    'Cardiology',
    'Dermatology',
    'Emergency Medicine',
    'Endocrinology',
    'Family Medicine',
    'Gastroenterology',
    'General Surgery',
    'Geriatrics',
    'Hematology/Oncology',
    'Infectious Disease',
    'Internal Medicine',
    'Nephrology',
    'Neurology',
    'Neurosurgery',
    'OB/GYN',
    'Ophthalmology',
    'Orthopedics',
    'Otolaryngology (ENT)',
    'Pain Management',
    'Pathology',
    'Pediatrics',
    'Physical Medicine & Rehab',
    'Plastic Surgery',
    'Podiatry',
    'Psychiatry',
    'Psychology',
    'Pulmonology',
    'Radiation Oncology',
    'Radiology',
    'Rheumatology',
    'Sleep Medicine',
    'Sports Medicine',
    'Thoracic Surgery',
    'Urology',
    'Vascular Surgery',
  ];
}

/// Referral data model
class ReferralModel {
  const ReferralModel({
    required this.patientId,
    required this.specialty,
    required this.reasonForReferral,
    required this.referralDate,
    this.id,
    this.encounterId,
    this.referralType = ReferralType.specialist,
    this.referredToName = '',
    this.referredToFacility = '',
    this.referredToPhone = '',
    this.referredToEmail = '',
    this.referredToAddress = '',
    this.clinicalHistory = '',
    this.diagnosisIds = const [],
    this.urgency = ReferralUrgency.routine,
    this.status = ReferralStatus.pending,
    this.appointmentDate,
    this.completedDate,
    this.consultationNotes = '',
    this.recommendations = '',
    this.attachments = const [],
    this.preAuthRequired = 'unknown',
    this.preAuthStatus = '',
    this.preAuthNumber = '',
    this.notes = '',
    this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      referralType: ReferralType.fromValue(
        json['referralType'] as String? ?? json['referral_type'] as String? ?? 'specialist',
      ),
      specialty: json['specialty'] as String? ?? '',
      referredToName: json['referredToName'] as String? ?? json['referred_to_name'] as String? ?? '',
      referredToFacility: json['referredToFacility'] as String? ?? json['referred_to_facility'] as String? ?? '',
      referredToPhone: json['referredToPhone'] as String? ?? json['referred_to_phone'] as String? ?? '',
      referredToEmail: json['referredToEmail'] as String? ?? json['referred_to_email'] as String? ?? '',
      referredToAddress: json['referredToAddress'] as String? ?? json['referred_to_address'] as String? ?? '',
      reasonForReferral: json['reasonForReferral'] as String? ?? json['reason_for_referral'] as String? ?? '',
      clinicalHistory: json['clinicalHistory'] as String? ?? json['clinical_history'] as String? ?? '',
      diagnosisIds: _parseIntList(json['diagnosisIds'] ?? json['diagnosis_ids']),
      urgency: ReferralUrgency.fromValue(json['urgency'] as String? ?? 'routine'),
      status: ReferralStatus.fromValue(json['status'] as String? ?? 'pending'),
      referralDate: _parseDateTime(json['referralDate'] ?? json['referral_date']) ?? DateTime.now(),
      appointmentDate: _parseDateTime(json['appointmentDate'] ?? json['appointment_date']),
      completedDate: _parseDateTime(json['completedDate'] ?? json['completed_date']),
      consultationNotes: json['consultationNotes'] as String? ?? json['consultation_notes'] as String? ?? '',
      recommendations: json['recommendations'] as String? ?? '',
      attachments: _parseStringList(json['attachments']),
      preAuthRequired: json['preAuthRequired'] as String? ?? json['pre_auth_required'] as String? ?? 'unknown',
      preAuthStatus: json['preAuthStatus'] as String? ?? json['pre_auth_status'] as String? ?? '',
      preAuthNumber: json['preAuthNumber'] as String? ?? json['pre_auth_number'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final ReferralType referralType;
  final String specialty;
  final String referredToName;
  final String referredToFacility;
  final String referredToPhone;
  final String referredToEmail;
  final String referredToAddress;
  final String reasonForReferral;
  final String clinicalHistory;
  final List<int> diagnosisIds;
  final ReferralUrgency urgency;
  final ReferralStatus status;
  final DateTime referralDate;
  final DateTime? appointmentDate;
  final DateTime? completedDate;
  final String consultationNotes;
  final String recommendations;
  final List<String> attachments;
  final String preAuthRequired;
  final String preAuthStatus;
  final String preAuthNumber;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'referralType': referralType.value,
      'specialty': specialty,
      'referredToName': referredToName,
      'referredToFacility': referredToFacility,
      'referredToPhone': referredToPhone,
      'referredToEmail': referredToEmail,
      'referredToAddress': referredToAddress,
      'reasonForReferral': reasonForReferral,
      'clinicalHistory': clinicalHistory,
      'diagnosisIds': jsonEncode(diagnosisIds),
      'urgency': urgency.value,
      'status': status.value,
      'referralDate': referralDate.toIso8601String(),
      'appointmentDate': appointmentDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'consultationNotes': consultationNotes,
      'recommendations': recommendations,
      'attachments': jsonEncode(attachments),
      'preAuthRequired': preAuthRequired,
      'preAuthStatus': preAuthStatus,
      'preAuthNumber': preAuthNumber,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ReferralModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    ReferralType? referralType,
    String? specialty,
    String? referredToName,
    String? referredToFacility,
    String? referredToPhone,
    String? referredToEmail,
    String? referredToAddress,
    String? reasonForReferral,
    String? clinicalHistory,
    List<int>? diagnosisIds,
    ReferralUrgency? urgency,
    ReferralStatus? status,
    DateTime? referralDate,
    DateTime? appointmentDate,
    DateTime? completedDate,
    String? consultationNotes,
    String? recommendations,
    List<String>? attachments,
    String? preAuthRequired,
    String? preAuthStatus,
    String? preAuthNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      referralType: referralType ?? this.referralType,
      specialty: specialty ?? this.specialty,
      referredToName: referredToName ?? this.referredToName,
      referredToFacility: referredToFacility ?? this.referredToFacility,
      referredToPhone: referredToPhone ?? this.referredToPhone,
      referredToEmail: referredToEmail ?? this.referredToEmail,
      referredToAddress: referredToAddress ?? this.referredToAddress,
      reasonForReferral: reasonForReferral ?? this.reasonForReferral,
      clinicalHistory: clinicalHistory ?? this.clinicalHistory,
      diagnosisIds: diagnosisIds ?? this.diagnosisIds,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      referralDate: referralDate ?? this.referralDate,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      completedDate: completedDate ?? this.completedDate,
      consultationNotes: consultationNotes ?? this.consultationNotes,
      recommendations: recommendations ?? this.recommendations,
      attachments: attachments ?? this.attachments,
      preAuthRequired: preAuthRequired ?? this.preAuthRequired,
      preAuthStatus: preAuthStatus ?? this.preAuthStatus,
      preAuthNumber: preAuthNumber ?? this.preAuthNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if referral is pending action
  bool get isPending => status == ReferralStatus.pending || status == ReferralStatus.sent;

  /// Check if referral is active (not completed or cancelled)
  bool get isActive => status != ReferralStatus.completed && 
                       status != ReferralStatus.cancelled && 
                       status != ReferralStatus.rejected;

  /// Get referral recipient display name
  String get recipientDisplayName {
    if (referredToName.isNotEmpty && referredToFacility.isNotEmpty) {
      return '$referredToName at $referredToFacility';
    }
    return referredToName.isNotEmpty ? referredToName : referredToFacility;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<int>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.cast<int>();
      } catch (_) {}
    }
    return [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
    }
    return [];
  }
}
