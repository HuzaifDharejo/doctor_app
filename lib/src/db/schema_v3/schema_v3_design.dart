// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V3: FULLY NORMALIZED DATABASE DESIGN
// ═══════════════════════════════════════════════════════════════════════════════
// 
// This file contains the redesigned schema that properly normalizes all JSON fields
// into separate, queryable tables with proper relationships.
//
// KEY CHANGES FROM V1/V2:
// 1. Prescriptions → PrescriptionMedications (separate table for each medication)
// 2. itemsJson → InvoiceLineItems (separate table for invoice items)
// 3. vitalsJson → VitalSigns (already exists, but now properly linked)
// 4. Lab tests in Rx → LabOrders (already fixed)
// 5. Family conditions → FamilyConditions (new junction table)
// 6. Treatment symptoms → TreatmentSymptoms (new table)
// 7. Side effects → SideEffects (new table)
// 8. Attachments → Attachments (new table)
// 9. Mental status → MentalStatusExams (new structured table)
//
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../doctor_db.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. PRESCRIPTION MEDICATIONS - Individual medications linked to prescriptions
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual medications in a prescription
/// Replaces: Prescriptions.itemsJson (medications part)
class PrescriptionMedications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prescriptionId => integer().references(Prescriptions, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Medication details
  TextColumn get medicationName => text()();
  TextColumn get genericName => text().withDefault(const Constant(''))();
  TextColumn get brandName => text().withDefault(const Constant(''))();
  TextColumn get drugCode => text().withDefault(const Constant(''))(); // RxNorm, NDC
  TextColumn get drugClass => text().withDefault(const Constant(''))(); // e.g., 'SSRI', 'Antipsychotic'
  
  // Dosage
  TextColumn get strength => text().withDefault(const Constant(''))(); // e.g., '500mg', '10ml'
  TextColumn get dosageForm => text().withDefault(const Constant('tablet'))(); // 'tablet', 'capsule', 'syrup', 'injection'
  TextColumn get route => text().withDefault(const Constant('oral'))(); // 'oral', 'topical', 'IM', 'IV', 'SC'
  
  // Frequency & Duration
  TextColumn get frequency => text().withDefault(const Constant(''))(); // 'once daily', 'twice daily', 'TID', 'QID', 'PRN'
  TextColumn get timing => text().withDefault(const Constant(''))(); // 'morning', 'evening', 'with meals', 'before bed'
  IntColumn get durationDays => integer().nullable()();
  TextColumn get durationText => text().withDefault(const Constant(''))(); // '7 days', '2 weeks', 'ongoing'
  
  // Quantity
  RealColumn get quantity => real().nullable()();
  TextColumn get quantityUnit => text().withDefault(const Constant('tablets'))();
  IntColumn get refills => integer().withDefault(const Constant(0))();
  
  // Instructions
  BoolColumn get beforeFood => boolean().withDefault(const Constant(false))();
  BoolColumn get afterFood => boolean().withDefault(const Constant(false))();
  BoolColumn get withFood => boolean().withDefault(const Constant(false))();
  TextColumn get specialInstructions => text().withDefault(const Constant(''))();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'completed', 'discontinued', 'on_hold', 'cancelled'
  TextColumn get discontinueReason => text().withDefault(const Constant(''))();
  DateTimeColumn get discontinuedAt => dateTime().nullable()();
  
  // Ordering
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. INVOICE LINE ITEMS - Individual items in an invoice
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual line items in an invoice
/// Replaces: Invoices.itemsJson
class InvoiceLineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Item details
  TextColumn get itemType => text().withDefault(const Constant('service'))();
  // Types: 'service', 'medication', 'procedure', 'lab', 'supply', 'other'
  
  TextColumn get description => text()();
  TextColumn get cptCode => text().withDefault(const Constant(''))();
  TextColumn get hcpcsCode => text().withDefault(const Constant(''))();
  TextColumn get modifier => text().withDefault(const Constant(''))();
  
  // Linked entities
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)();
  IntColumn get prescriptionId => integer().nullable().references(Prescriptions, #id)();
  IntColumn get labOrderId => integer().nullable().references(LabOrders, #id)();
  IntColumn get treatmentSessionId => integer().nullable().references(TreatmentSessions, #id)();
  
  // Pricing
  RealColumn get unitPrice => real().withDefault(const Constant(0))();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  
  // Ordering
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. FAMILY MEDICAL CONDITIONS - Normalized family history conditions
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual conditions for family members
/// Replaces: FamilyMedicalHistory.conditions (JSON) and conditionDetails (JSON)
class FamilyConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get familyHistoryId => integer().references(FamilyMedicalHistory, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Condition details
  TextColumn get conditionName => text()();
  TextColumn get icdCode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('medical'))();
  // Categories: 'cardiovascular', 'cancer', 'diabetes', 'psychiatric', 'neurological', 
  //             'autoimmune', 'genetic', 'respiratory', 'gastrointestinal', 'other'
  
  // Details
  IntColumn get ageAtOnset => integer().nullable()();
  TextColumn get severity => text().withDefault(const Constant(''))(); // 'mild', 'moderate', 'severe'
  TextColumn get outcome => text().withDefault(const Constant(''))(); // 'ongoing', 'resolved', 'deceased'
  BoolColumn get confirmedDiagnosis => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. TREATMENT SYMPTOMS - Track symptoms being treated
// ═══════════════════════════════════════════════════════════════════════════════

/// Symptoms being tracked for a treatment
/// Replaces: MedicationResponses.targetSymptoms (JSON) and symptomImprovement (JSON)
class TreatmentSymptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationResponseId => integer().nullable().references(MedicationResponses, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Symptom details
  TextColumn get symptomName => text()();
  TextColumn get symptomCategory => text().withDefault(const Constant(''))();
  // Categories: 'mood', 'anxiety', 'cognitive', 'sleep', 'appetite', 'energy', 
  //             'social', 'psychotic', 'physical', 'other'
  
  // Severity tracking (1-10 scale)
  IntColumn get baselineSeverity => integer().nullable()();
  IntColumn get currentSeverity => integer().nullable()();
  IntColumn get targetSeverity => integer().nullable()();
  
  // Improvement
  TextColumn get improvementLevel => text().withDefault(const Constant('unchanged'))();
  // Levels: 'much_worse', 'worse', 'unchanged', 'improved', 'much_improved', 'resolved'
  IntColumn get improvementPercent => integer().nullable()(); // -100 to +100
  
  // Dates
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. SIDE EFFECTS - Track medication/treatment side effects
// ═══════════════════════════════════════════════════════════════════════════════

/// Side effects reported for medications/treatments
/// Replaces: MedicationResponses.sideEffects (JSON) and TreatmentOutcomes.sideEffects
class SideEffects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationResponseId => integer().nullable().references(MedicationResponses, #id)();
  IntColumn get prescriptionMedicationId => integer().nullable().references(PrescriptionMedications, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Side effect details
  TextColumn get effectName => text()();
  TextColumn get effectCategory => text().withDefault(const Constant('other'))();
  // Categories: 'gastrointestinal', 'neurological', 'cardiovascular', 'dermatological',
  //             'metabolic', 'sexual', 'psychiatric', 'musculoskeletal', 'other'
  
  // Severity
  TextColumn get severity => text().withDefault(const Constant('mild'))();
  // Severity: 'mild', 'moderate', 'severe', 'life_threatening'
  IntColumn get severityScore => integer().nullable()(); // 1-10
  
  // Timing
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get resolvedDate => dateTime().nullable()();
  TextColumn get frequency => text().withDefault(const Constant(''))(); // 'constant', 'intermittent', 'occasional'
  
  // Management
  TextColumn get managementAction => text().withDefault(const Constant(''))();
  // Actions: 'none', 'monitoring', 'dose_reduced', 'timing_changed', 'discontinued', 'added_medication'
  BoolColumn get causedDiscontinuation => boolean().withDefault(const Constant(false))();
  BoolColumn get reportedToProvider => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. ATTACHMENTS - Centralized file attachments
// ═══════════════════════════════════════════════════════════════════════════════

/// File attachments linked to various entities
/// Replaces: ClinicalNotes.attachments (JSON), Referrals.attachments (JSON), etc.
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Linked entity (polymorphic)
  TextColumn get entityType => text()();
  // Types: 'clinical_note', 'referral', 'medical_record', 'lab_order', 'consent', 
  //        'insurance_claim', 'pre_auth', 'patient_document', 'prescription'
  IntColumn get entityId => integer()();
  
  // File details
  TextColumn get fileName => text()();
  TextColumn get originalFileName => text().withDefault(const Constant(''))();
  TextColumn get filePath => text()();
  TextColumn get fileType => text().withDefault(const Constant(''))(); // MIME type
  TextColumn get fileExtension => text().withDefault(const Constant(''))();
  IntColumn get fileSizeBytes => integer().nullable()();
  
  // Metadata
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  // Categories: 'report', 'image', 'consent', 'lab_result', 'referral_letter', 
  //             'insurance_card', 'id_document', 'prescription', 'other'
  
  // Security
  BoolColumn get isConfidential => boolean().withDefault(const Constant(false))();
  TextColumn get uploadedBy => text().withDefault(const Constant(''))();
  
  // Ordering
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. MENTAL STATUS EXAM - Structured mental status components
// ═══════════════════════════════════════════════════════════════════════════════

/// Structured mental status exam findings
/// Replaces: ClinicalNotes.mentalStatusExam (JSON) and Encounters.mentalStatusExam (JSON)
class MentalStatusExams extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  IntColumn get clinicalNoteId => integer().nullable().references(ClinicalNotes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Appearance
  TextColumn get appearance => text().withDefault(const Constant(''))();
  // e.g., 'well-groomed', 'disheveled', 'appropriate', 'bizarre'
  TextColumn get grooming => text().withDefault(const Constant('appropriate'))();
  TextColumn get attire => text().withDefault(const Constant('appropriate'))();
  TextColumn get eyeContact => text().withDefault(const Constant('appropriate'))();
  // 'appropriate', 'poor', 'intense', 'avoidant'
  
  // Behavior
  TextColumn get behavior => text().withDefault(const Constant(''))();
  TextColumn get psychomotorActivity => text().withDefault(const Constant('normal'))();
  // 'normal', 'retarded', 'agitated', 'restless', 'tremulous'
  TextColumn get attitude => text().withDefault(const Constant('cooperative'))();
  // 'cooperative', 'guarded', 'hostile', 'suspicious', 'withdrawn'
  
  // Speech
  TextColumn get speechRate => text().withDefault(const Constant('normal'))();
  // 'slow', 'normal', 'rapid', 'pressured'
  TextColumn get speechVolume => text().withDefault(const Constant('normal'))();
  // 'soft', 'normal', 'loud'
  TextColumn get speechTone => text().withDefault(const Constant('normal'))();
  TextColumn get speechQuality => text().withDefault(const Constant(''))();
  // 'clear', 'slurred', 'mumbled', 'monotone'
  
  // Mood & Affect
  TextColumn get mood => text().withDefault(const Constant(''))();
  // Patient's reported: 'good', 'sad', 'anxious', 'irritable', 'angry', 'euphoric'
  TextColumn get affect => text().withDefault(const Constant(''))();
  // Observed: 'euthymic', 'depressed', 'anxious', 'flat', 'blunted', 'labile'
  TextColumn get affectRange => text().withDefault(const Constant('full'))();
  // 'full', 'restricted', 'blunted', 'flat'
  TextColumn get affectCongruence => text().withDefault(const Constant('congruent'))();
  // 'congruent', 'incongruent'
  
  // Thought Process
  TextColumn get thoughtProcess => text().withDefault(const Constant('linear'))();
  // 'linear', 'circumstantial', 'tangential', 'loose', 'flight_of_ideas', 'thought_blocking'
  TextColumn get thoughtContent => text().withDefault(const Constant(''))();
  // Any notable content: 'unremarkable', 'preoccupied', 'obsessive', 'paranoid'
  
  // Perceptions
  BoolColumn get hallucinationsAuditory => boolean().withDefault(const Constant(false))();
  BoolColumn get hallucinationsVisual => boolean().withDefault(const Constant(false))();
  BoolColumn get hallucinationsOther => boolean().withDefault(const Constant(false))();
  TextColumn get hallucinationsDetails => text().withDefault(const Constant(''))();
  BoolColumn get delusions => boolean().withDefault(const Constant(false))();
  TextColumn get delusionsType => text().withDefault(const Constant(''))();
  // 'paranoid', 'grandiose', 'somatic', 'referential', 'erotomanic'
  
  // Suicidal/Homicidal
  BoolColumn get suicidalIdeation => boolean().withDefault(const Constant(false))();
  TextColumn get suicidalDetails => text().withDefault(const Constant(''))();
  BoolColumn get homicidalIdeation => boolean().withDefault(const Constant(false))();
  TextColumn get homicidalDetails => text().withDefault(const Constant(''))();
  BoolColumn get selfHarmIdeation => boolean().withDefault(const Constant(false))();
  
  // Cognition
  TextColumn get orientation => text().withDefault(const Constant('oriented_x4'))();
  // 'oriented_x4', 'oriented_x3', 'oriented_x2', 'oriented_x1', 'disoriented'
  TextColumn get attention => text().withDefault(const Constant('intact'))();
  // 'intact', 'impaired', 'distractible'
  TextColumn get concentration => text().withDefault(const Constant('intact'))();
  TextColumn get memory => text().withDefault(const Constant('intact'))();
  // 'intact', 'impaired_recent', 'impaired_remote', 'impaired_both'
  
  // Insight & Judgment
  TextColumn get insight => text().withDefault(const Constant('good'))();
  // 'good', 'fair', 'poor', 'absent'
  TextColumn get judgment => text().withDefault(const Constant('good'))();
  // 'good', 'fair', 'poor', 'impaired'
  
  TextColumn get additionalNotes => text().withDefault(const Constant(''))();
  DateTimeColumn get examinedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. LAB TEST RESULTS - Individual test results within a lab order
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual lab test results
/// Replaces: LabOrders.testCodes (JSON) and testNames (JSON) for results
class LabTestResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get labOrderId => integer().references(LabOrders, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Test details
  TextColumn get testName => text()();
  TextColumn get testCode => text().withDefault(const Constant(''))(); // LOINC code
  TextColumn get category => text().withDefault(const Constant(''))();
  // Categories: 'hematology', 'chemistry', 'urinalysis', 'microbiology', 'immunology', etc.
  
  // Result
  TextColumn get resultValue => text().withDefault(const Constant(''))();
  TextColumn get resultUnit => text().withDefault(const Constant(''))();
  TextColumn get resultType => text().withDefault(const Constant('numeric'))();
  // Types: 'numeric', 'text', 'ratio', 'titer', 'positive_negative'
  
  // Reference range
  TextColumn get referenceRange => text().withDefault(const Constant(''))();
  RealColumn get referenceLow => real().nullable()();
  RealColumn get referenceHigh => real().nullable()();
  
  // Flags
  TextColumn get flag => text().withDefault(const Constant('normal'))();
  // Flags: 'normal', 'low', 'high', 'critical_low', 'critical_high', 'abnormal'
  BoolColumn get isAbnormal => boolean().withDefault(const Constant(false))();
  BoolColumn get isCritical => boolean().withDefault(const Constant(false))();
  
  // Comparison to previous
  TextColumn get previousValue => text().withDefault(const Constant(''))();
  DateTimeColumn get previousDate => dateTime().nullable()();
  TextColumn get trend => text().withDefault(const Constant(''))();
  // Trend: 'increasing', 'decreasing', 'stable', 'new'
  
  TextColumn get interpretation => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  // Ordering
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get resultedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. PROGRESS NOTES - Individual progress entries
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual progress note entries
/// Replaces: TreatmentGoals.progressNotes (JSON)
class ProgressNoteEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get treatmentGoalId => integer().nullable().references(TreatmentGoals, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Entry details
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get note => text()();
  
  // Progress metrics
  IntColumn get progressRating => integer().nullable()(); // 1-10
  TextColumn get progressStatus => text().withDefault(const Constant(''))();
  // Status: 'on_track', 'ahead', 'behind', 'stalled', 'regressed'
  
  TextColumn get barriers => text().withDefault(const Constant(''))();
  TextColumn get interventionsUsed => text().withDefault(const Constant(''))();
  TextColumn get nextSteps => text().withDefault(const Constant(''))();
  
  TextColumn get recordedBy => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 10. TREATMENT INTERVENTIONS - Track interventions used
// ═══════════════════════════════════════════════════════════════════════════════

/// Interventions used in treatment sessions
/// Replaces: TreatmentSessions.interventionsUsed (JSON) and TreatmentGoals.interventions (JSON)
class TreatmentInterventions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get treatmentSessionId => integer().nullable().references(TreatmentSessions, #id)();
  IntColumn get treatmentGoalId => integer().nullable().references(TreatmentGoals, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Intervention details
  TextColumn get interventionName => text()();
  TextColumn get interventionType => text().withDefault(const Constant('therapeutic'))();
  // Types: 'therapeutic', 'behavioral', 'cognitive', 'pharmacological', 
  //        'psychoeducation', 'supportive', 'crisis', 'other'
  
  TextColumn get modality => text().withDefault(const Constant(''))();
  // Modality: 'CBT', 'DBT', 'ACT', 'MI', 'psychodynamic', 'supportive', 'EMDR', etc.
  
  // Effectiveness
  TextColumn get effectiveness => text().withDefault(const Constant(''))();
  // 'very_effective', 'effective', 'somewhat_effective', 'not_effective', 'too_early'
  IntColumn get effectivenessRating => integer().nullable()(); // 1-10
  
  TextColumn get patientResponse => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get usedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 11. BILLING CODES - Diagnosis and procedure codes for claims
// ═══════════════════════════════════════════════════════════════════════════════

/// Billing codes for insurance claims
/// Replaces: InsuranceClaims.diagnosisCodes (JSON), procedureCodes (JSON), modifiers (JSON)
class ClaimBillingCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get claimId => integer().references(InsuranceClaims, #id)();
  
  // Code details
  TextColumn get codeType => text()();
  // Types: 'diagnosis', 'procedure', 'modifier'
  TextColumn get code => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  
  // For procedure codes
  RealColumn get chargedAmount => real().nullable()();
  IntColumn get units => integer().withDefault(const Constant(1))();
  TextColumn get placeOfService => text().withDefault(const Constant(''))();
  
  // For modifiers
  IntColumn get linkedProcedureId => integer().nullable()(); // Link modifier to procedure
  
  // Ordering (for primary/secondary diagnosis)
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 12. PATIENT ALLERGIES - Normalized allergy tracking
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual patient allergies
/// Replaces: Patients.allergies (comma-separated text)
class PatientAllergies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Allergy details
  TextColumn get allergen => text()();
  TextColumn get allergenType => text().withDefault(const Constant('medication'))();
  // Types: 'medication', 'food', 'environmental', 'latex', 'contrast', 'other'
  TextColumn get allergenCode => text().withDefault(const Constant(''))(); // RxNorm for meds
  
  // Reaction
  TextColumn get reactionType => text().withDefault(const Constant(''))();
  // Types: 'rash', 'hives', 'anaphylaxis', 'nausea', 'swelling', 'breathing_difficulty', 'other'
  TextColumn get reactionSeverity => text().withDefault(const Constant('moderate'))();
  // Severity: 'mild', 'moderate', 'severe', 'life_threatening'
  TextColumn get reactionDescription => text().withDefault(const Constant(''))();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'inactive', 'resolved', 'entered_in_error'
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  
  // Dates
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get recordedDate => dateTime()();
  
  TextColumn get source => text().withDefault(const Constant('patient'))();
  // Source: 'patient', 'family', 'medical_record', 'provider'
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 13. PATIENT CHRONIC CONDITIONS - Normalized chronic conditions
// ═══════════════════════════════════════════════════════════════════════════════

/// Individual patient chronic conditions
/// Replaces: Patients.chronicConditions (comma-separated text)
class PatientChronicConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get diagnosisId => integer().nullable().references(Diagnoses, #id)();
  
  // Condition details
  TextColumn get conditionName => text()();
  TextColumn get icdCode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('medical'))();
  // Categories: 'cardiovascular', 'respiratory', 'endocrine', 'neurological', 
  //             'psychiatric', 'musculoskeletal', 'gastrointestinal', 'renal', 'other'
  
  // Status
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'controlled', 'uncontrolled', 'in_remission', 'resolved'
  TextColumn get severity => text().withDefault(const Constant('moderate'))();
  
  // Dates
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get diagnosedDate => dateTime().nullable()();
  
  // Management
  TextColumn get currentTreatment => text().withDefault(const Constant(''))();
  TextColumn get managingProvider => text().withDefault(const Constant(''))();
  DateTimeColumn get lastReviewDate => dateTime().nullable()();
  DateTimeColumn get nextReviewDate => dateTime().nullable()();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUMMARY OF CHANGES
// ═══════════════════════════════════════════════════════════════════════════════
//
// New Tables Created:
// 1.  PrescriptionMedications - Individual meds (was itemsJson)
// 2.  InvoiceLineItems - Invoice items (was itemsJson)
// 3.  FamilyConditions - Family conditions (was conditions JSON)
// 4.  TreatmentSymptoms - Target symptoms (was targetSymptoms JSON)
// 5.  SideEffects - Side effects (was sideEffects JSON)
// 6.  Attachments - File attachments (was attachments JSON)
// 7.  MentalStatusExams - MSE data (was mentalStatusExam JSON)
// 8.  LabTestResults - Lab results (was in testCodes/testNames JSON)
// 9.  ProgressNoteEntries - Progress entries (was progressNotes JSON)
// 10. TreatmentInterventions - Interventions (was interventionsUsed JSON)
// 11. ClaimBillingCodes - Billing codes (was diagnosisCodes/procedureCodes JSON)
// 12. PatientAllergies - Allergies (was comma-separated text)
// 13. PatientChronicConditions - Chronic conditions (was comma-separated text)
//
// Benefits:
// - Full SQL querying capability on all data
// - Better reporting and analytics
// - Drug interaction checking across all prescriptions
// - Trend analysis for symptoms, side effects, lab results
// - Proper referential integrity
// - Faster searches
// - Easier data migration and backup
//
// ═══════════════════════════════════════════════════════════════════════════════
