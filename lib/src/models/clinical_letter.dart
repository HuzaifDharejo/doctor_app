import 'dart:convert';

/// Clinical letter type
enum ClinicalLetterType {
  referralLetter('referral_letter', 'Referral Letter'),
  consultationReport('consultation_report', 'Consultation Report'),
  dischargeSummary('discharge_summary', 'Discharge Summary'),
  medicalCertificate('medical_certificate', 'Medical Certificate'),
  sickNote('sick_note', 'Sick Note'),
  fitnessForWork('fitness_for_work', 'Fitness for Work'),
  insuranceLetter('insurance_letter', 'Insurance Letter'),
  schoolLetter('school_letter', 'School/College Letter'),
  travelLetter('travel_letter', 'Travel Medical Letter'),
  prescriptionSummary('prescription_summary', 'Prescription Summary'),
  carePlanSummary('care_plan_summary', 'Care Plan Summary'),
  transferSummary('transfer_summary', 'Transfer Summary'),
  deathCertificate('death_certificate', 'Death Certificate'),
  custom('custom', 'Custom Letter');

  const ClinicalLetterType(this.value, this.label);
  final String value;
  final String label;

  static ClinicalLetterType fromValue(String value) {
    return ClinicalLetterType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ClinicalLetterType.custom,
    );
  }
}

/// Clinical letter status
enum ClinicalLetterStatus {
  draft('draft', 'Draft'),
  pendingReview('pending_review', 'Pending Review'),
  approved('approved', 'Approved'),
  signed('signed', 'Signed'),
  sent('sent', 'Sent'),
  cancelled('cancelled', 'Cancelled');

  const ClinicalLetterStatus(this.value, this.label);
  final String value;
  final String label;

  static ClinicalLetterStatus fromValue(String value) {
    return ClinicalLetterStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ClinicalLetterStatus.draft,
    );
  }
}

/// Delivery method for clinical letters
enum LetterDeliveryMethod {
  printed('printed', 'Printed'),
  email('email', 'Email'),
  fax('fax', 'Fax'),
  electronicHealthRecord('ehr', 'Electronic Health Record'),
  patientPortal('patient_portal', 'Patient Portal'),
  mail('mail', 'Postal Mail');

  const LetterDeliveryMethod(this.value, this.label);
  final String value;
  final String label;

  static LetterDeliveryMethod fromValue(String value) {
    return LetterDeliveryMethod.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => LetterDeliveryMethod.printed,
    );
  }
}

/// Clinical letter data model
class ClinicalLetterModel {
  const ClinicalLetterModel({
    required this.patientId,
    required this.letterType,
    required this.subject,
    required this.content,
    this.id,
    this.encounterId,
    this.authorProviderId,
    this.status = ClinicalLetterStatus.draft,
    this.recipientName = '',
    this.recipientOrganization = '',
    this.recipientAddress = '',
    this.recipientEmail = '',
    this.recipientFax = '',
    this.deliveryMethod = LetterDeliveryMethod.printed,
    this.templateId,
    this.signedAt,
    this.signedByProviderId,
    this.sentAt,
    this.sentTo = '',
    this.linkedReferralId,
    this.linkedDiagnosisIds = const [],
    this.linkedMedicationIds = const [],
    this.attachments = const [],
    this.notes = '',
    this.validFrom,
    this.validUntil,
    this.confidential = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ClinicalLetterModel.fromJson(Map<String, dynamic> json) {
    return ClinicalLetterModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      authorProviderId: json['authorProviderId'] as int? ?? json['author_provider_id'] as int?,
      letterType: ClinicalLetterType.fromValue(json['letterType'] as String? ?? json['letter_type'] as String? ?? 'custom'),
      status: ClinicalLetterStatus.fromValue(json['status'] as String? ?? 'draft'),
      subject: json['subject'] as String? ?? '',
      content: json['content'] as String? ?? '',
      recipientName: json['recipientName'] as String? ?? json['recipient_name'] as String? ?? '',
      recipientOrganization: json['recipientOrganization'] as String? ?? json['recipient_organization'] as String? ?? '',
      recipientAddress: json['recipientAddress'] as String? ?? json['recipient_address'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String? ?? json['recipient_email'] as String? ?? '',
      recipientFax: json['recipientFax'] as String? ?? json['recipient_fax'] as String? ?? '',
      deliveryMethod: LetterDeliveryMethod.fromValue(json['deliveryMethod'] as String? ?? json['delivery_method'] as String? ?? 'printed'),
      templateId: json['templateId'] as String? ?? json['template_id'] as String?,
      signedAt: _parseDateTime(json['signedAt'] ?? json['signed_at']),
      signedByProviderId: json['signedByProviderId'] as int? ?? json['signed_by_provider_id'] as int?,
      sentAt: _parseDateTime(json['sentAt'] ?? json['sent_at']),
      sentTo: json['sentTo'] as String? ?? json['sent_to'] as String? ?? '',
      linkedReferralId: json['linkedReferralId'] as int? ?? json['linked_referral_id'] as int?,
      linkedDiagnosisIds: _parseIntList(json['linkedDiagnosisIds'] ?? json['linked_diagnosis_ids']),
      linkedMedicationIds: _parseIntList(json['linkedMedicationIds'] ?? json['linked_medication_ids']),
      attachments: _parseStringList(json['attachments']),
      notes: json['notes'] as String? ?? '',
      validFrom: _parseDateTime(json['validFrom'] ?? json['valid_from']),
      validUntil: _parseDateTime(json['validUntil'] ?? json['valid_until']),
      confidential: json['confidential'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final int? authorProviderId;
  final ClinicalLetterType letterType;
  final ClinicalLetterStatus status;
  final String subject;
  final String content;
  final String recipientName;
  final String recipientOrganization;
  final String recipientAddress;
  final String recipientEmail;
  final String recipientFax;
  final LetterDeliveryMethod deliveryMethod;
  final String? templateId;
  final DateTime? signedAt;
  final int? signedByProviderId;
  final DateTime? sentAt;
  final String sentTo;
  final int? linkedReferralId;
  final List<int> linkedDiagnosisIds;
  final List<int> linkedMedicationIds;
  final List<String> attachments;
  final String notes;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool confidential;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'authorProviderId': authorProviderId,
      'letterType': letterType.value,
      'status': status.value,
      'subject': subject,
      'content': content,
      'recipientName': recipientName,
      'recipientOrganization': recipientOrganization,
      'recipientAddress': recipientAddress,
      'recipientEmail': recipientEmail,
      'recipientFax': recipientFax,
      'deliveryMethod': deliveryMethod.value,
      'templateId': templateId,
      'signedAt': signedAt?.toIso8601String(),
      'signedByProviderId': signedByProviderId,
      'sentAt': sentAt?.toIso8601String(),
      'sentTo': sentTo,
      'linkedReferralId': linkedReferralId,
      'linkedDiagnosisIds': linkedDiagnosisIds,
      'linkedMedicationIds': linkedMedicationIds,
      'attachments': attachments,
      'notes': notes,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'confidential': confidential,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ClinicalLetterModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    int? authorProviderId,
    ClinicalLetterType? letterType,
    ClinicalLetterStatus? status,
    String? subject,
    String? content,
    String? recipientName,
    String? recipientOrganization,
    String? recipientAddress,
    String? recipientEmail,
    String? recipientFax,
    LetterDeliveryMethod? deliveryMethod,
    String? templateId,
    DateTime? signedAt,
    int? signedByProviderId,
    DateTime? sentAt,
    String? sentTo,
    int? linkedReferralId,
    List<int>? linkedDiagnosisIds,
    List<int>? linkedMedicationIds,
    List<String>? attachments,
    String? notes,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? confidential,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalLetterModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      authorProviderId: authorProviderId ?? this.authorProviderId,
      letterType: letterType ?? this.letterType,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      recipientName: recipientName ?? this.recipientName,
      recipientOrganization: recipientOrganization ?? this.recipientOrganization,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientFax: recipientFax ?? this.recipientFax,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      templateId: templateId ?? this.templateId,
      signedAt: signedAt ?? this.signedAt,
      signedByProviderId: signedByProviderId ?? this.signedByProviderId,
      sentAt: sentAt ?? this.sentAt,
      sentTo: sentTo ?? this.sentTo,
      linkedReferralId: linkedReferralId ?? this.linkedReferralId,
      linkedDiagnosisIds: linkedDiagnosisIds ?? this.linkedDiagnosisIds,
      linkedMedicationIds: linkedMedicationIds ?? this.linkedMedicationIds,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      confidential: confidential ?? this.confidential,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if letter is editable
  bool get isEditable {
    return status == ClinicalLetterStatus.draft || 
           status == ClinicalLetterStatus.pendingReview;
  }

  /// Check if letter is signed
  bool get isSigned => signedAt != null && signedByProviderId != null;

  /// Check if letter has been sent
  bool get isSent => sentAt != null;

  /// Check if letter is currently valid
  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (validUntil == null) return null;
    return validUntil!.difference(DateTime.now()).inDays;
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

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}

/// Clinical letter template for generating standard letters
class LetterTemplate {
  const LetterTemplate({
    required this.id,
    required this.name,
    required this.letterType,
    required this.subject,
    required this.contentTemplate,
    this.description = '',
    this.placeholders = const [],
  });

  final String id;
  final String name;
  final ClinicalLetterType letterType;
  final String subject;
  final String contentTemplate;
  final String description;
  final List<String> placeholders;

  /// Generate letter content by replacing placeholders
  String generateContent(Map<String, String> values) {
    String result = contentTemplate;
    for (final placeholder in placeholders) {
      if (values.containsKey(placeholder)) {
        result = result.replaceAll('{{$placeholder}}', values[placeholder]!);
      }
    }
    return result;
  }
}

/// Standard letter templates
class ClinicalLetterTemplates {
  static const List<LetterTemplate> templates = [
    // Referral Letter
    LetterTemplate(
      id: 'referral_standard',
      name: 'Standard Referral',
      letterType: ClinicalLetterType.referralLetter,
      subject: 'Referral for {{patient_name}}',
      description: 'Standard referral letter to specialist',
      placeholders: [
        'patient_name',
        'patient_dob',
        'referring_provider',
        'recipient_name',
        'recipient_specialty',
        'reason_for_referral',
        'clinical_summary',
        'current_medications',
        'relevant_history',
        'urgency',
        'date',
      ],
      contentTemplate: '''
Dear Dr. {{recipient_name}},

I am writing to refer {{patient_name}} (DOB: {{patient_dob}}) for your expert opinion and management.

REASON FOR REFERRAL:
{{reason_for_referral}}

CLINICAL SUMMARY:
{{clinical_summary}}

RELEVANT MEDICAL HISTORY:
{{relevant_history}}

CURRENT MEDICATIONS:
{{current_medications}}

URGENCY: {{urgency}}

Thank you for seeing this patient. Please do not hesitate to contact me if you require any further information.

Yours sincerely,

{{referring_provider}}
Date: {{date}}
''',
    ),

    // Medical Certificate
    LetterTemplate(
      id: 'medical_certificate_standard',
      name: 'Standard Medical Certificate',
      letterType: ClinicalLetterType.medicalCertificate,
      subject: 'Medical Certificate - {{patient_name}}',
      description: 'Medical certificate for employment/insurance',
      placeholders: [
        'patient_name',
        'patient_dob',
        'date_examined',
        'condition_description',
        'recommendations',
        'valid_from',
        'valid_until',
        'provider_name',
        'provider_credentials',
        'date',
      ],
      contentTemplate: '''
MEDICAL CERTIFICATE

This is to certify that I have examined {{patient_name}} (DOB: {{patient_dob}}) on {{date_examined}}.

MEDICAL OPINION:
{{condition_description}}

RECOMMENDATIONS:
{{recommendations}}

This certificate is valid from {{valid_from}} to {{valid_until}}.

{{provider_name}}
{{provider_credentials}}
Date: {{date}}
''',
    ),

    // Sick Note
    LetterTemplate(
      id: 'sick_note_standard',
      name: 'Standard Sick Note',
      letterType: ClinicalLetterType.sickNote,
      subject: 'Sick Note - {{patient_name}}',
      description: 'Sick note for work absence',
      placeholders: [
        'patient_name',
        'date_examined',
        'absence_start',
        'absence_end',
        'able_to_work_date',
        'provider_name',
        'date',
      ],
      contentTemplate: '''
TO WHOM IT MAY CONCERN

This is to certify that {{patient_name}} was examined on {{date_examined}} and is unfit for work from {{absence_start}} to {{absence_end}}.

Expected return to work: {{able_to_work_date}}

{{provider_name}}
Date: {{date}}
''',
    ),

    // Fitness for Work
    LetterTemplate(
      id: 'fitness_for_work',
      name: 'Fitness for Work Certificate',
      letterType: ClinicalLetterType.fitnessForWork,
      subject: 'Fitness for Work - {{patient_name}}',
      description: 'Certificate confirming fitness to return to work',
      placeholders: [
        'patient_name',
        'patient_dob',
        'date_examined',
        'fitness_status',
        'restrictions',
        'duration_of_restrictions',
        'follow_up_required',
        'provider_name',
        'date',
      ],
      contentTemplate: '''
FITNESS FOR WORK CERTIFICATE

Patient: {{patient_name}} (DOB: {{patient_dob}})
Date of Examination: {{date_examined}}

FITNESS STATUS: {{fitness_status}}

RESTRICTIONS (if any):
{{restrictions}}

Duration of Restrictions: {{duration_of_restrictions}}

Follow-up Required: {{follow_up_required}}

{{provider_name}}
Date: {{date}}
''',
    ),

    // Consultation Report
    LetterTemplate(
      id: 'consultation_report',
      name: 'Consultation Report',
      letterType: ClinicalLetterType.consultationReport,
      subject: 'Consultation Report - {{patient_name}}',
      description: 'Report to referring physician after consultation',
      placeholders: [
        'patient_name',
        'patient_dob',
        'referring_provider',
        'consultation_date',
        'reason_for_consultation',
        'history',
        'examination_findings',
        'investigations',
        'diagnosis',
        'management_plan',
        'follow_up_plan',
        'consultant_name',
        'date',
      ],
      contentTemplate: '''
CONSULTATION REPORT

Dear Dr. {{referring_provider}},

Thank you for referring {{patient_name}} (DOB: {{patient_dob}}) whom I saw on {{consultation_date}}.

REASON FOR CONSULTATION:
{{reason_for_consultation}}

HISTORY:
{{history}}

EXAMINATION FINDINGS:
{{examination_findings}}

INVESTIGATIONS:
{{investigations}}

DIAGNOSIS:
{{diagnosis}}

MANAGEMENT PLAN:
{{management_plan}}

FOLLOW-UP:
{{follow_up_plan}}

Please do not hesitate to contact me if you have any questions.

Yours sincerely,

{{consultant_name}}
Date: {{date}}
''',
    ),

    // Travel Medical Letter
    LetterTemplate(
      id: 'travel_letter',
      name: 'Travel Medical Letter',
      letterType: ClinicalLetterType.travelLetter,
      subject: 'Travel Medical Letter - {{patient_name}}',
      description: 'Letter for traveling with medications or medical conditions',
      placeholders: [
        'patient_name',
        'patient_dob',
        'passport_number',
        'medical_conditions',
        'medications',
        'medical_equipment',
        'travel_dates',
        'destination',
        'provider_name',
        'provider_credentials',
        'date',
      ],
      contentTemplate: '''
TO WHOM IT MAY CONCERN

TRAVEL MEDICAL LETTER

This letter is to confirm that {{patient_name}} (DOB: {{patient_dob}}, Passport: {{passport_number}}) is a patient under my care.

MEDICAL CONDITIONS:
{{medical_conditions}}

MEDICATIONS REQUIRED FOR TRAVEL:
{{medications}}

MEDICAL EQUIPMENT:
{{medical_equipment}}

TRAVEL DETAILS:
Dates: {{travel_dates}}
Destination: {{destination}}

The medications and/or medical equipment listed above are prescribed for the patient's personal use and are medically necessary.

If you require any further information, please contact our office.

{{provider_name}}
{{provider_credentials}}
Date: {{date}}
''',
    ),
  ];

  /// Get templates by letter type
  static List<LetterTemplate> getByType(ClinicalLetterType type) {
    return templates.where((t) => t.letterType == type).toList();
  }

  /// Get template by ID
  static LetterTemplate? getById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
