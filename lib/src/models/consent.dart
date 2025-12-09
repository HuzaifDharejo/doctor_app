/// Consent status
enum ConsentStatus {
  pending('pending', 'Pending'),
  signed('signed', 'Signed'),
  refused('refused', 'Refused'),
  revoked('revoked', 'Revoked'),
  expired('expired', 'Expired');

  const ConsentStatus(this.value, this.label);
  final String value;
  final String label;

  static ConsentStatus fromValue(String value) {
    return ConsentStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ConsentStatus.pending,
    );
  }
}

/// Consent type
enum ConsentType {
  treatment('treatment', 'General Treatment Consent'),
  procedure('procedure', 'Procedure Consent'),
  hipaa('hipaa', 'HIPAA Privacy Notice'),
  research('research', 'Research Participation'),
  medication('medication', 'Medication Consent'),
  telehealth('telehealth', 'Telehealth Consent'),
  photoVideo('photo_video', 'Photo/Video Consent'),
  informationRelease('information_release', 'Release of Information'),
  financial('financial', 'Financial Agreement'),
  advanceDirective('advance_directive', 'Advance Directive');

  const ConsentType(this.value, this.label);
  final String value;
  final String label;

  static ConsentType fromValue(String value) {
    return ConsentType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ConsentType.treatment,
    );
  }
}

/// Signer relationship to patient
enum SignerRelationship {
  self('self', 'Self'),
  parent('parent', 'Parent'),
  guardian('guardian', 'Legal Guardian'),
  spouse('spouse', 'Spouse'),
  powerOfAttorney('power_of_attorney', 'Power of Attorney'),
  healthcareProxy('healthcare_proxy', 'Healthcare Proxy'),
  other('other', 'Other');

  const SignerRelationship(this.value, this.label);
  final String value;
  final String label;

  static SignerRelationship fromValue(String value) {
    return SignerRelationship.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => SignerRelationship.self,
    );
  }
}

/// Patient consent data model
class ConsentModel {
  const ConsentModel({
    required this.patientId,
    required this.consentType,
    required this.consentTitle,
    required this.effectiveDate,
    this.id,
    this.encounterId,
    this.consentDescription = '',
    this.consentText = '',
    this.templateId = '',
    this.procedureName = '',
    this.procedureRisks = '',
    this.procedureBenefits = '',
    this.procedureAlternatives = '',
    this.signatureData = '',
    this.signedByName = '',
    this.signedByRelationship = SignerRelationship.self,
    this.signedAt,
    this.witnessName = '',
    this.witnessSignature = '',
    this.status = ConsentStatus.pending,
    this.expirationDate,
    this.isActive = true,
    this.notes = '',
    this.createdAt,
  });

  factory ConsentModel.fromJson(Map<String, dynamic> json) {
    return ConsentModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      consentType: ConsentType.fromValue(json['consentType'] as String? ?? json['consent_type'] as String? ?? 'treatment'),
      consentTitle: json['consentTitle'] as String? ?? json['consent_title'] as String? ?? '',
      consentDescription: json['consentDescription'] as String? ?? json['consent_description'] as String? ?? '',
      consentText: json['consentText'] as String? ?? json['consent_text'] as String? ?? '',
      templateId: json['templateId'] as String? ?? json['template_id'] as String? ?? '',
      procedureName: json['procedureName'] as String? ?? json['procedure_name'] as String? ?? '',
      procedureRisks: json['procedureRisks'] as String? ?? json['procedure_risks'] as String? ?? '',
      procedureBenefits: json['procedureBenefits'] as String? ?? json['procedure_benefits'] as String? ?? '',
      procedureAlternatives: json['procedureAlternatives'] as String? ?? json['procedure_alternatives'] as String? ?? '',
      signatureData: json['signatureData'] as String? ?? json['signature_data'] as String? ?? '',
      signedByName: json['signedByName'] as String? ?? json['signed_by_name'] as String? ?? '',
      signedByRelationship: SignerRelationship.fromValue(
        json['signedByRelationship'] as String? ?? json['signed_by_relationship'] as String? ?? 'self',
      ),
      signedAt: _parseDateTime(json['signedAt'] ?? json['signed_at']),
      witnessName: json['witnessName'] as String? ?? json['witness_name'] as String? ?? '',
      witnessSignature: json['witnessSignature'] as String? ?? json['witness_signature'] as String? ?? '',
      status: ConsentStatus.fromValue(json['status'] as String? ?? 'pending'),
      effectiveDate: _parseDateTime(json['effectiveDate'] ?? json['effective_date']) ?? DateTime.now(),
      expirationDate: _parseDateTime(json['expirationDate'] ?? json['expiration_date']),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final ConsentType consentType;
  final String consentTitle;
  final String consentDescription;
  final String consentText;
  final String templateId;
  final String procedureName;
  final String procedureRisks;
  final String procedureBenefits;
  final String procedureAlternatives;
  final String signatureData;
  final String signedByName;
  final SignerRelationship signedByRelationship;
  final DateTime? signedAt;
  final String witnessName;
  final String witnessSignature;
  final ConsentStatus status;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'consentType': consentType.value,
      'consentTitle': consentTitle,
      'consentDescription': consentDescription,
      'consentText': consentText,
      'templateId': templateId,
      'procedureName': procedureName,
      'procedureRisks': procedureRisks,
      'procedureBenefits': procedureBenefits,
      'procedureAlternatives': procedureAlternatives,
      'signatureData': signatureData,
      'signedByName': signedByName,
      'signedByRelationship': signedByRelationship.value,
      'signedAt': signedAt?.toIso8601String(),
      'witnessName': witnessName,
      'witnessSignature': witnessSignature,
      'status': status.value,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ConsentModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    ConsentType? consentType,
    String? consentTitle,
    String? consentDescription,
    String? consentText,
    String? templateId,
    String? procedureName,
    String? procedureRisks,
    String? procedureBenefits,
    String? procedureAlternatives,
    String? signatureData,
    String? signedByName,
    SignerRelationship? signedByRelationship,
    DateTime? signedAt,
    String? witnessName,
    String? witnessSignature,
    ConsentStatus? status,
    DateTime? effectiveDate,
    DateTime? expirationDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return ConsentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      consentType: consentType ?? this.consentType,
      consentTitle: consentTitle ?? this.consentTitle,
      consentDescription: consentDescription ?? this.consentDescription,
      consentText: consentText ?? this.consentText,
      templateId: templateId ?? this.templateId,
      procedureName: procedureName ?? this.procedureName,
      procedureRisks: procedureRisks ?? this.procedureRisks,
      procedureBenefits: procedureBenefits ?? this.procedureBenefits,
      procedureAlternatives: procedureAlternatives ?? this.procedureAlternatives,
      signatureData: signatureData ?? this.signatureData,
      signedByName: signedByName ?? this.signedByName,
      signedByRelationship: signedByRelationship ?? this.signedByRelationship,
      signedAt: signedAt ?? this.signedAt,
      witnessName: witnessName ?? this.witnessName,
      witnessSignature: witnessSignature ?? this.witnessSignature,
      status: status ?? this.status,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expirationDate: expirationDate ?? this.expirationDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if consent is currently valid
  bool get isValid {
    if (!isActive) return false;
    if (status != ConsentStatus.signed) return false;
    if (expirationDate != null && DateTime.now().isAfter(expirationDate!)) return false;
    return true;
  }

  /// Check if consent needs renewal
  bool get needsRenewal {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  /// Check if consent has a signature
  bool get isSigned => signatureData.isNotEmpty && signedAt != null;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Consent template for reusable consent forms
class ConsentTemplate {
  const ConsentTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.defaultExpirationDays,
    this.requiresWitness = false,
  });

  final String id;
  final ConsentType type;
  final String title;
  final String content;
  final int? defaultExpirationDays;
  final bool requiresWitness;

  /// Standard consent templates
  static const List<ConsentTemplate> standardTemplates = [
    ConsentTemplate(
      id: 'general_treatment',
      type: ConsentType.treatment,
      title: 'General Treatment Consent',
      content: '''I hereby consent to receive medical treatment and care from [PRACTICE_NAME] and its healthcare providers.

I understand that:
1. The practice of medicine is not an exact science and no guarantees have been made regarding the outcome of any examination or treatment.
2. I have the right to ask questions about any proposed treatment or procedure.
3. I have the right to refuse any treatment or procedure.
4. I will inform my healthcare provider of any changes in my condition.

I authorize the healthcare providers to perform examinations, tests, and procedures as deemed necessary for my diagnosis and treatment.

By signing below, I acknowledge that I have read and understand this consent form.''',
      defaultExpirationDays: 365,
    ),
    ConsentTemplate(
      id: 'hipaa_privacy',
      type: ConsentType.hipaa,
      title: 'HIPAA Privacy Notice Acknowledgment',
      content: '''NOTICE OF PRIVACY PRACTICES ACKNOWLEDGMENT

I acknowledge that I have received a copy of the Notice of Privacy Practices for [PRACTICE_NAME].

I understand that:
1. This notice describes how my medical information may be used and disclosed.
2. I have the right to review this notice before signing.
3. The practice reserves the right to change the privacy practices as described in the notice.
4. I may obtain a copy of any revised notice by contacting the practice.

By signing below, I acknowledge receipt of the Notice of Privacy Practices.''',
      defaultExpirationDays: null,
    ),
    ConsentTemplate(
      id: 'telehealth',
      type: ConsentType.telehealth,
      title: 'Telehealth Consent',
      content: '''TELEHEALTH INFORMED CONSENT

I consent to participate in telehealth services with [PRACTICE_NAME].

I understand that:
1. Telehealth involves the use of electronic communications to enable healthcare providers to diagnose, consult, treat, educate, and provide services at a distance.
2. The information exchanged may be used for diagnosis, therapy, follow-up, and/or education.
3. Technical difficulties may occur, and appointments may need to be rescheduled.
4. There are potential risks including technology failures and security breaches.
5. I have the right to refuse telehealth services at any time.
6. I must be located in the state where my provider is licensed during the telehealth session.

By signing below, I consent to receiving telehealth services.''',
      defaultExpirationDays: 365,
    ),
    ConsentTemplate(
      id: 'procedure',
      type: ConsentType.procedure,
      title: 'Procedure Consent',
      content: '''INFORMED CONSENT FOR [PROCEDURE_NAME]

I hereby authorize Dr. [PROVIDER_NAME] to perform the following procedure:
[PROCEDURE_DESCRIPTION]

I have been informed of:
1. The nature and purpose of the procedure
2. The potential risks and complications: [RISKS]
3. The expected benefits: [BENEFITS]
4. Alternative treatments: [ALTERNATIVES]
5. The consequences of not having the procedure

I have had the opportunity to ask questions and all my questions have been answered to my satisfaction.

I understand that no guarantees have been made regarding the outcome of this procedure.

By signing below, I voluntarily consent to the procedure described above.''',
      requiresWitness: true,
    ),
    ConsentTemplate(
      id: 'medication',
      type: ConsentType.medication,
      title: 'Medication Consent',
      content: '''CONSENT FOR MEDICATION TREATMENT

I consent to receive medication treatment as prescribed by my healthcare provider.

I understand that:
1. I will be provided information about each medication including its purpose, dosage, and potential side effects.
2. I agree to report any adverse reactions or concerns to my healthcare provider promptly.
3. I will not share my medications with others.
4. I will inform my provider of all other medications and supplements I am taking.
5. I will follow the prescribed dosage and schedule.

By signing below, I consent to medication treatment as prescribed.''',
      defaultExpirationDays: 365,
    ),
    ConsentTemplate(
      id: 'release_info',
      type: ConsentType.informationRelease,
      title: 'Authorization to Release Medical Information',
      content: '''AUTHORIZATION TO RELEASE MEDICAL INFORMATION

I authorize [PRACTICE_NAME] to release my medical information to:

Name/Organization: _______________________
Address: _______________________
Phone: _______________________
Fax: _______________________

Information to be released:
☐ Complete medical records
☐ Lab results
☐ Imaging reports
☐ Office notes
☐ Other: _______________________

Purpose of disclosure: _______________________

This authorization expires on: _______________________

I understand that:
1. I may revoke this authorization at any time in writing.
2. Information disclosed may be subject to redisclosure by the recipient.
3. I may refuse to sign this authorization and it will not affect my treatment.

By signing below, I authorize the release of my medical information as described above.''',
      defaultExpirationDays: 90,
    ),
  ];
}
