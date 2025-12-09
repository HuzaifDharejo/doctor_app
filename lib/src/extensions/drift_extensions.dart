/// Extension methods on Drift-generated types for screen compatibility
/// 
/// These extensions provide property aliases that screens expect,
/// mapping them to the actual Drift-generated property names.

import '../db/doctor_db.dart';
import '../models/consent.dart';
import '../models/family_history.dart';
import '../models/lab_order.dart';
import '../models/problem_list.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSENT EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension PatientConsentExtension on PatientConsent {
  /// Alias for consentDescription (screens use 'description')
  String? get description => consentDescription.isEmpty ? null : consentDescription;
  
  /// Alias for effectiveDate (screens use 'consentDate')
  DateTime get consentDate => effectiveDate;
  
  /// Get consent type enum
  ConsentType get type => ConsentType.fromValue(consentType);
}

extension ConsentModelExtension on ConsentModel {
  /// Alias for consentType (screens use 'type')
  ConsentType get type => consentType;
}

extension ConsentStatusExtension on ConsentStatus {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

extension ConsentTypeExtension on ConsentType {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// FAMILY HISTORY EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension FamilyMedicalHistoryDataExtension on FamilyMedicalHistoryData {
  /// Alias for conditions (screens use 'condition')
  String get condition => conditions;
  
  /// Alias for relativeAge (screens sometimes use 'ageAtOnset')
  int? get ageAtOnset => relativeAge;
}

extension FamilyRelationshipExtension on FamilyRelationship {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

extension FamilyHistoryModelExtension on FamilyHistoryModel {
  /// Computed risk based on family history conditions
  bool get isHighRisk {
    return hasHeartDisease || 
           hasDiabetes || 
           hasCancer || 
           hasHypertension ||
           hasStroke ||
           hasGeneticDisorder ||
           (relationship.isFirstDegree && isDeceased && (ageAtDeath ?? 100) < 60);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GROWTH MEASUREMENT EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension GrowthMeasurementExtension on GrowthMeasurement {
  /// Alias for headCircumferencePercentile (screens use 'headPercentile')
  double? get headPercentile => headCircumferencePercentile;
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMMUNIZATION EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension ImmunizationExtension on Immunization {
  /// Alias for administeredDate (screens use 'dateAdministered')
  DateTime get dateAdministered => administeredDate;
  
  /// Alias for nextDoseDate (screens use 'nextDueDate')
  DateTime? get nextDueDate => nextDoseDate;
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSURANCE EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension InsuranceInfoDataExtension on InsuranceInfoData {
  /// Alias for payerName (screens use 'insurerName')
  String get insurerName => payerName;
  
  /// Alias for memberId (screens use 'policyNumber')
  String get policyNumber => memberId;
  
  /// Alias for insuranceType == 'primary' (screens use 'isPrimary')
  bool get isPrimary => insuranceType.toLowerCase() == 'primary';
}

// ═══════════════════════════════════════════════════════════════════════════════
// LAB ORDER EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension LabOrderExtension on LabOrder {
  /// Alias for testNames (screens use 'testName')
  String get testName => testNames;
  
  /// Alias for testCodes (screens use 'testCode')
  String get testCode => testCodes;
  
  /// Alias for orderedDate (screens use 'orderDate')
  DateTime get orderDate => orderedDate;
  
  /// Alias for resultedDate (screens use 'resultDate')
  DateTime? get resultDate => resultedDate;
  
  /// Alias for priority (screens use 'urgency')
  String get urgency => priority;
  
  /// Alias for hasAbnormal (screens use 'isAbnormal')
  bool get isAbnormal => hasAbnormal;
  
  /// Alias for specialInstructions (screens use 'clinicalIndication')
  String get clinicalIndication => specialInstructions;
  
  /// Alias for notes (screens use 'resultSummary')
  String get resultSummary => notes;
}

/// Extension on LabOrderModel to provide urgency alias (model uses priority)
extension LabOrderModelExtension on LabOrderModel {
  /// Alias for priority (screens use 'urgency')
  LabPriority get urgency => priority;
}

/// Extension on LabPriority for displayName
extension LabPriorityExtension on LabPriority {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROBLEM LIST EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension ProblemListDataExtension on ProblemListData {
  /// ProblemListData already has icdCode
  /// ProblemListData already has onsetDate
}

/// Extension on ProblemStatus for displayName
extension ProblemStatusExtension on ProblemStatus {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

/// Extension on ProblemSeverity for displayName
extension ProblemSeverityExtension on ProblemSeverity {
  /// Alias for label (screens use 'displayName')
  String get displayName => label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECURRING APPOINTMENT EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension RecurringAppointmentExtension on RecurringAppointment {
  /// Alias for daysOfWeek (screens use 'preferredDay')
  String get preferredDay => daysOfWeek;
  
  /// Alias for intervalDays (screens use 'intervalValue')
  int? get intervalValue => intervalDays;
  
  /// Alias for durationMinutes (screens use 'duration')
  int get duration => durationMinutes;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REFERRAL EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension ReferralExtension on Referral {
  /// Alias for reasonForReferral (screens use 'reason')
  String get reason => reasonForReferral;
  
  /// Alias for clinicalHistory (screens use 'clinicalNotes')
  String get clinicalNotes => clinicalHistory;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WAITLIST EXTENSIONS
// ═══════════════════════════════════════════════════════════════════════════════

extension AppointmentWaitlistDataExtension on AppointmentWaitlistData {
  /// Alias for urgency (screens use 'priority')
  String get priority => urgency;
  
  /// Alias for requestedDate (screens use 'requestDate')
  DateTime get requestDate => requestedDate;
  
  /// Alias for preferredTimeStart (screens use 'preferredTimeSlot')
  String get preferredTimeSlot => '$preferredTimeStart - $preferredTimeEnd';
}
