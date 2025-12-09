import 'dart:convert';

/// Insurance plan type
enum InsurancePlanType {
  hmo('HMO', 'Health Maintenance Organization'),
  ppo('PPO', 'Preferred Provider Organization'),
  epo('EPO', 'Exclusive Provider Organization'),
  pos('POS', 'Point of Service'),
  hdhp('HDHP', 'High Deductible Health Plan'),
  medicare('Medicare', 'Medicare'),
  medicaid('Medicaid', 'Medicaid'),
  tricare('Tricare', 'Tricare'),
  other('Other', 'Other');

  const InsurancePlanType(this.value, this.label);
  final String value;
  final String label;

  static InsurancePlanType fromValue(String value) {
    return InsurancePlanType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InsurancePlanType.other,
    );
  }
}

/// Insurance type (primary, secondary, etc.)
enum InsuranceLevel {
  primary('primary', 'Primary'),
  secondary('secondary', 'Secondary'),
  tertiary('tertiary', 'Tertiary');

  const InsuranceLevel(this.value, this.label);
  final String value;
  final String label;

  static InsuranceLevel fromValue(String value) {
    return InsuranceLevel.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => InsuranceLevel.primary,
    );
  }
}

/// Claim status
enum ClaimStatus {
  draft('draft', 'Draft'),
  submitted('submitted', 'Submitted'),
  acknowledged('acknowledged', 'Acknowledged'),
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  denied('denied', 'Denied'),
  partiallyPaid('partially_paid', 'Partially Paid'),
  paid('paid', 'Paid'),
  appealed('appealed', 'Appealed'),
  voided('void', 'Void');

  const ClaimStatus(this.value, this.label);
  final String value;
  final String label;

  static ClaimStatus fromValue(String value) {
    return ClaimStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ClaimStatus.draft,
    );
  }
}

/// Pre-authorization status
enum PreAuthStatus {
  draft('draft', 'Draft'),
  submitted('submitted', 'Submitted'),
  pending('pending', 'Pending Review'),
  approved('approved', 'Approved'),
  denied('denied', 'Denied'),
  partial('partial', 'Partially Approved'),
  expired('expired', 'Expired'),
  cancelled('cancelled', 'Cancelled');

  const PreAuthStatus(this.value, this.label);
  final String value;
  final String label;

  static PreAuthStatus fromValue(String value) {
    return PreAuthStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => PreAuthStatus.pending,
    );
  }
}

/// Patient insurance information model
class InsuranceModel {
  const InsuranceModel({
    required this.patientId,
    required this.payerName,
    required this.memberId,
    required this.effectiveDate,
    this.id,
    this.insuranceType = InsuranceLevel.primary,
    this.payerId = '',
    this.planName = '',
    this.planType = InsurancePlanType.other,
    this.groupNumber = '',
    this.subscriberName = '',
    this.subscriberDob = '',
    this.subscriberRelationship = 'self',
    this.terminationDate,
    this.copay = 0,
    this.deductible = 0,
    this.deductibleMet = 0,
    this.outOfPocketMax = 0,
    this.outOfPocketMet = 0,
    this.payerPhone = '',
    this.payerAddress = '',
    this.claimsAddress = '',
    this.frontCardImage = '',
    this.backCardImage = '',
    this.isVerified = false,
    this.verifiedAt,
    this.isActive = true,
    this.notes = '',
    this.createdAt,
  });

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      insuranceType: InsuranceLevel.fromValue(json['insuranceType'] as String? ?? json['insurance_type'] as String? ?? 'primary'),
      payerName: json['payerName'] as String? ?? json['payer_name'] as String? ?? '',
      payerId: json['payerId'] as String? ?? json['payer_id'] as String? ?? '',
      planName: json['planName'] as String? ?? json['plan_name'] as String? ?? '',
      planType: InsurancePlanType.fromValue(json['planType'] as String? ?? json['plan_type'] as String? ?? ''),
      memberId: json['memberId'] as String? ?? json['member_id'] as String? ?? '',
      groupNumber: json['groupNumber'] as String? ?? json['group_number'] as String? ?? '',
      subscriberName: json['subscriberName'] as String? ?? json['subscriber_name'] as String? ?? '',
      subscriberDob: json['subscriberDob'] as String? ?? json['subscriber_dob'] as String? ?? '',
      subscriberRelationship: json['subscriberRelationship'] as String? ?? json['subscriber_relationship'] as String? ?? 'self',
      effectiveDate: _parseDateTime(json['effectiveDate'] ?? json['effective_date']) ?? DateTime.now(),
      terminationDate: _parseDateTime(json['terminationDate'] ?? json['termination_date']),
      copay: (json['copay'] as num?)?.toDouble() ?? 0,
      deductible: (json['deductible'] as num?)?.toDouble() ?? 0,
      deductibleMet: (json['deductibleMet'] as num?)?.toDouble() ?? (json['deductible_met'] as num?)?.toDouble() ?? 0,
      outOfPocketMax: (json['outOfPocketMax'] as num?)?.toDouble() ?? (json['out_of_pocket_max'] as num?)?.toDouble() ?? 0,
      outOfPocketMet: (json['outOfPocketMet'] as num?)?.toDouble() ?? (json['out_of_pocket_met'] as num?)?.toDouble() ?? 0,
      payerPhone: json['payerPhone'] as String? ?? json['payer_phone'] as String? ?? '',
      payerAddress: json['payerAddress'] as String? ?? json['payer_address'] as String? ?? '',
      claimsAddress: json['claimsAddress'] as String? ?? json['claims_address'] as String? ?? '',
      frontCardImage: json['frontCardImage'] as String? ?? json['front_card_image'] as String? ?? '',
      backCardImage: json['backCardImage'] as String? ?? json['back_card_image'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      verifiedAt: _parseDateTime(json['verifiedAt'] ?? json['verified_at']),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final InsuranceLevel insuranceType;
  final String payerName;
  final String payerId;
  final String planName;
  final InsurancePlanType planType;
  final String memberId;
  final String groupNumber;
  final String subscriberName;
  final String subscriberDob;
  final String subscriberRelationship;
  final DateTime effectiveDate;
  final DateTime? terminationDate;
  final double copay;
  final double deductible;
  final double deductibleMet;
  final double outOfPocketMax;
  final double outOfPocketMet;
  final String payerPhone;
  final String payerAddress;
  final String claimsAddress;
  final String frontCardImage;
  final String backCardImage;
  final bool isVerified;
  final DateTime? verifiedAt;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'insuranceType': insuranceType.value,
      'payerName': payerName,
      'payerId': payerId,
      'planName': planName,
      'planType': planType.value,
      'memberId': memberId,
      'groupNumber': groupNumber,
      'subscriberName': subscriberName,
      'subscriberDob': subscriberDob,
      'subscriberRelationship': subscriberRelationship,
      'effectiveDate': effectiveDate.toIso8601String(),
      'terminationDate': terminationDate?.toIso8601String(),
      'copay': copay,
      'deductible': deductible,
      'deductibleMet': deductibleMet,
      'outOfPocketMax': outOfPocketMax,
      'outOfPocketMet': outOfPocketMet,
      'payerPhone': payerPhone,
      'payerAddress': payerAddress,
      'claimsAddress': claimsAddress,
      'frontCardImage': frontCardImage,
      'backCardImage': backCardImage,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  InsuranceModel copyWith({
    int? id,
    int? patientId,
    InsuranceLevel? insuranceType,
    String? payerName,
    String? payerId,
    String? planName,
    InsurancePlanType? planType,
    String? memberId,
    String? groupNumber,
    String? subscriberName,
    String? subscriberDob,
    String? subscriberRelationship,
    DateTime? effectiveDate,
    DateTime? terminationDate,
    double? copay,
    double? deductible,
    double? deductibleMet,
    double? outOfPocketMax,
    double? outOfPocketMet,
    String? payerPhone,
    String? payerAddress,
    String? claimsAddress,
    String? frontCardImage,
    String? backCardImage,
    bool? isVerified,
    DateTime? verifiedAt,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return InsuranceModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      insuranceType: insuranceType ?? this.insuranceType,
      payerName: payerName ?? this.payerName,
      payerId: payerId ?? this.payerId,
      planName: planName ?? this.planName,
      planType: planType ?? this.planType,
      memberId: memberId ?? this.memberId,
      groupNumber: groupNumber ?? this.groupNumber,
      subscriberName: subscriberName ?? this.subscriberName,
      subscriberDob: subscriberDob ?? this.subscriberDob,
      subscriberRelationship: subscriberRelationship ?? this.subscriberRelationship,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      terminationDate: terminationDate ?? this.terminationDate,
      copay: copay ?? this.copay,
      deductible: deductible ?? this.deductible,
      deductibleMet: deductibleMet ?? this.deductibleMet,
      outOfPocketMax: outOfPocketMax ?? this.outOfPocketMax,
      outOfPocketMet: outOfPocketMet ?? this.outOfPocketMet,
      payerPhone: payerPhone ?? this.payerPhone,
      payerAddress: payerAddress ?? this.payerAddress,
      claimsAddress: claimsAddress ?? this.claimsAddress,
      frontCardImage: frontCardImage ?? this.frontCardImage,
      backCardImage: backCardImage ?? this.backCardImage,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if insurance is currently active
  bool get isCurrent {
    if (!isActive) return false;
    final now = DateTime.now();
    if (now.isBefore(effectiveDate)) return false;
    if (terminationDate != null && now.isAfter(terminationDate!)) return false;
    return true;
  }

  /// Get remaining deductible
  double get remainingDeductible => (deductible - deductibleMet).clamp(0, deductible);

  /// Get remaining out-of-pocket
  double get remainingOutOfPocket => (outOfPocketMax - outOfPocketMet).clamp(0, outOfPocketMax);

  /// Get deductible percentage met
  double get deductiblePercentMet => deductible > 0 ? (deductibleMet / deductible * 100).clamp(0, 100) : 0;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Insurance claim model
class ClaimModel {
  const ClaimModel({
    required this.patientId,
    required this.insuranceId,
    required this.claimNumber,
    required this.serviceDate,
    this.id,
    this.encounterId,
    this.invoiceId,
    this.claimType = 'professional',
    this.submittedDate,
    this.diagnosisCodes = const [],
    this.procedureCodes = const [],
    this.modifiers = const {},
    this.placeOfService = '11',
    this.billedAmount = 0,
    this.allowedAmount = 0,
    this.paidAmount = 0,
    this.patientResponsibility = 0,
    this.adjustmentAmount = 0,
    this.adjustmentReason = '',
    this.status = ClaimStatus.draft,
    this.denialReason = '',
    this.denialCode = '',
    this.processedDate,
    this.paidDate,
    this.checkNumber = '',
    this.eobDocument = '',
    this.notes = '',
    this.createdAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      insuranceId: json['insuranceId'] as int? ?? json['insurance_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      invoiceId: json['invoiceId'] as int? ?? json['invoice_id'] as int?,
      claimNumber: json['claimNumber'] as String? ?? json['claim_number'] as String? ?? '',
      claimType: json['claimType'] as String? ?? json['claim_type'] as String? ?? 'professional',
      serviceDate: _parseDateTime(json['serviceDate'] ?? json['service_date']) ?? DateTime.now(),
      submittedDate: _parseDateTime(json['submittedDate'] ?? json['submitted_date']),
      diagnosisCodes: _parseStringList(json['diagnosisCodes'] ?? json['diagnosis_codes']),
      procedureCodes: _parseStringList(json['procedureCodes'] ?? json['procedure_codes']),
      modifiers: _parseStringMap(json['modifiers']),
      placeOfService: json['placeOfService'] as String? ?? json['place_of_service'] as String? ?? '11',
      billedAmount: (json['billedAmount'] as num?)?.toDouble() ?? (json['billed_amount'] as num?)?.toDouble() ?? 0,
      allowedAmount: (json['allowedAmount'] as num?)?.toDouble() ?? (json['allowed_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? (json['paid_amount'] as num?)?.toDouble() ?? 0,
      patientResponsibility: (json['patientResponsibility'] as num?)?.toDouble() ?? (json['patient_responsibility'] as num?)?.toDouble() ?? 0,
      adjustmentAmount: (json['adjustmentAmount'] as num?)?.toDouble() ?? (json['adjustment_amount'] as num?)?.toDouble() ?? 0,
      adjustmentReason: json['adjustmentReason'] as String? ?? json['adjustment_reason'] as String? ?? '',
      status: ClaimStatus.fromValue(json['status'] as String? ?? 'draft'),
      denialReason: json['denialReason'] as String? ?? json['denial_reason'] as String? ?? '',
      denialCode: json['denialCode'] as String? ?? json['denial_code'] as String? ?? '',
      processedDate: _parseDateTime(json['processedDate'] ?? json['processed_date']),
      paidDate: _parseDateTime(json['paidDate'] ?? json['paid_date']),
      checkNumber: json['checkNumber'] as String? ?? json['check_number'] as String? ?? '',
      eobDocument: json['eobDocument'] as String? ?? json['eob_document'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int insuranceId;
  final int? encounterId;
  final int? invoiceId;
  final String claimNumber;
  final String claimType;
  final DateTime serviceDate;
  final DateTime? submittedDate;
  final List<String> diagnosisCodes;
  final List<String> procedureCodes;
  final Map<String, String> modifiers;
  final String placeOfService;
  final double billedAmount;
  final double allowedAmount;
  final double paidAmount;
  final double patientResponsibility;
  final double adjustmentAmount;
  final String adjustmentReason;
  final ClaimStatus status;
  final String denialReason;
  final String denialCode;
  final DateTime? processedDate;
  final DateTime? paidDate;
  final String checkNumber;
  final String eobDocument;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'insuranceId': insuranceId,
      'encounterId': encounterId,
      'invoiceId': invoiceId,
      'claimNumber': claimNumber,
      'claimType': claimType,
      'serviceDate': serviceDate.toIso8601String(),
      'submittedDate': submittedDate?.toIso8601String(),
      'diagnosisCodes': jsonEncode(diagnosisCodes),
      'procedureCodes': jsonEncode(procedureCodes),
      'modifiers': jsonEncode(modifiers),
      'placeOfService': placeOfService,
      'billedAmount': billedAmount,
      'allowedAmount': allowedAmount,
      'paidAmount': paidAmount,
      'patientResponsibility': patientResponsibility,
      'adjustmentAmount': adjustmentAmount,
      'adjustmentReason': adjustmentReason,
      'status': status.value,
      'denialReason': denialReason,
      'denialCode': denialCode,
      'processedDate': processedDate?.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'checkNumber': checkNumber,
      'eobDocument': eobDocument,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Check if claim is pending
  bool get isPending => status == ClaimStatus.submitted || 
                        status == ClaimStatus.acknowledged || 
                        status == ClaimStatus.pending;

  /// Check if claim can be appealed
  bool get canAppeal => status == ClaimStatus.denied;

  /// Get write-off amount
  double get writeOff => billedAmount - allowedAmount - adjustmentAmount;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return value.cast<String, String>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded.cast<String, String>();
      } catch (_) {}
    }
    return {};
  }
}

/// Pre-authorization model
class PreAuthModel {
  const PreAuthModel({
    required this.patientId,
    required this.insuranceId,
    required this.authType,
    required this.serviceDescription,
    required this.requestedDate,
    this.id,
    this.referralId,
    this.authNumber = '',
    this.procedureCodes = const [],
    this.diagnosisCodes = const [],
    this.requestedBy = '',
    this.unitsRequested = 1,
    this.clinicalJustification = '',
    this.supportingDocuments = const [],
    this.status = PreAuthStatus.pending,
    this.unitsApproved,
    this.unitsUsed = 0,
    this.approvedDate,
    this.effectiveDate,
    this.expirationDate,
    this.denialReason = '',
    this.appealInfo = '',
    this.notes = '',
    this.createdAt,
  });

  factory PreAuthModel.fromJson(Map<String, dynamic> json) {
    return PreAuthModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      insuranceId: json['insuranceId'] as int? ?? json['insurance_id'] as int? ?? 0,
      referralId: json['referralId'] as int? ?? json['referral_id'] as int?,
      authNumber: json['authNumber'] as String? ?? json['auth_number'] as String? ?? '',
      authType: json['authType'] as String? ?? json['auth_type'] as String? ?? '',
      serviceDescription: json['serviceDescription'] as String? ?? json['service_description'] as String? ?? '',
      procedureCodes: _parseStringList(json['procedureCodes'] ?? json['procedure_codes']),
      diagnosisCodes: _parseStringList(json['diagnosisCodes'] ?? json['diagnosis_codes']),
      requestedDate: _parseDateTime(json['requestedDate'] ?? json['requested_date']) ?? DateTime.now(),
      requestedBy: json['requestedBy'] as String? ?? json['requested_by'] as String? ?? '',
      unitsRequested: json['unitsRequested'] as int? ?? json['units_requested'] as int? ?? 1,
      clinicalJustification: json['clinicalJustification'] as String? ?? json['clinical_justification'] as String? ?? '',
      supportingDocuments: _parseStringList(json['supportingDocuments'] ?? json['supporting_documents']),
      status: PreAuthStatus.fromValue(json['status'] as String? ?? 'pending'),
      unitsApproved: json['unitsApproved'] as int? ?? json['units_approved'] as int?,
      unitsUsed: json['unitsUsed'] as int? ?? json['units_used'] as int? ?? 0,
      approvedDate: _parseDateTime(json['approvedDate'] ?? json['approved_date']),
      effectiveDate: _parseDateTime(json['effectiveDate'] ?? json['effective_date']),
      expirationDate: _parseDateTime(json['expirationDate'] ?? json['expiration_date']),
      denialReason: json['denialReason'] as String? ?? json['denial_reason'] as String? ?? '',
      appealInfo: json['appealInfo'] as String? ?? json['appeal_info'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int insuranceId;
  final int? referralId;
  final String authNumber;
  final String authType;
  final String serviceDescription;
  final List<String> procedureCodes;
  final List<String> diagnosisCodes;
  final DateTime requestedDate;
  final String requestedBy;
  final int unitsRequested;
  final String clinicalJustification;
  final List<String> supportingDocuments;
  final PreAuthStatus status;
  final int? unitsApproved;
  final int unitsUsed;
  final DateTime? approvedDate;
  final DateTime? effectiveDate;
  final DateTime? expirationDate;
  final String denialReason;
  final String appealInfo;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'insuranceId': insuranceId,
      'referralId': referralId,
      'authNumber': authNumber,
      'authType': authType,
      'serviceDescription': serviceDescription,
      'procedureCodes': jsonEncode(procedureCodes),
      'diagnosisCodes': jsonEncode(diagnosisCodes),
      'requestedDate': requestedDate.toIso8601String(),
      'requestedBy': requestedBy,
      'unitsRequested': unitsRequested,
      'clinicalJustification': clinicalJustification,
      'supportingDocuments': jsonEncode(supportingDocuments),
      'status': status.value,
      'unitsApproved': unitsApproved,
      'unitsUsed': unitsUsed,
      'approvedDate': approvedDate?.toIso8601String(),
      'effectiveDate': effectiveDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'denialReason': denialReason,
      'appealInfo': appealInfo,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Check if auth is currently valid
  bool get isValid {
    if (status != PreAuthStatus.approved && status != PreAuthStatus.partial) return false;
    if (expirationDate != null && DateTime.now().isAfter(expirationDate!)) return false;
    if (unitsApproved != null && unitsUsed >= unitsApproved!) return false;
    return true;
  }

  /// Get remaining units
  int get remainingUnits {
    if (unitsApproved == null) return 0;
    return (unitsApproved! - unitsUsed).clamp(0, unitsApproved!);
  }

  /// Check if auth is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

/// Common place of service codes
class PlaceOfServiceCodes {
  static const Map<String, String> codes = {
    '02': 'Telehealth (not in patient home)',
    '10': 'Telehealth (in patient home)',
    '11': 'Office',
    '12': 'Home',
    '19': 'Off Campus-Outpatient Hospital',
    '20': 'Urgent Care Facility',
    '21': 'Inpatient Hospital',
    '22': 'On Campus-Outpatient Hospital',
    '23': 'Emergency Room - Hospital',
    '31': 'Skilled Nursing Facility',
    '32': 'Nursing Facility',
    '33': 'Custodial Care Facility',
    '34': 'Hospice',
    '41': 'Ambulance - Land',
    '42': 'Ambulance - Air or Water',
    '49': 'Independent Clinic',
    '50': 'Federally Qualified Health Center',
    '51': 'Inpatient Psychiatric Facility',
    '52': 'Psychiatric Facility-Partial Hospitalization',
    '53': 'Community Mental Health Center',
    '54': 'Intermediate Care Facility',
    '55': 'Residential Substance Abuse Treatment Facility',
    '56': 'Psychiatric Residential Treatment Center',
    '57': 'Non-residential Substance Abuse Treatment Facility',
    '61': 'Comprehensive Inpatient Rehabilitation Facility',
    '62': 'Comprehensive Outpatient Rehabilitation Facility',
    '65': 'End-Stage Renal Disease Treatment Facility',
    '71': 'Public Health Clinic',
    '72': 'Rural Health Clinic',
    '81': 'Independent Laboratory',
    '99': 'Other Place of Service',
  };
}
