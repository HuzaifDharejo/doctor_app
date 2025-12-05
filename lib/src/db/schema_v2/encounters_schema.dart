// Schema V2: Encounter-Based Clinical Data Model
// This eliminates data duplication by creating a central Encounter that links all clinical data
//
// MIGRATION PLAN:
// 1. Add new tables (Encounters, Diagnoses, ClinicalNotes)
// 2. Update existing tables to reference Encounter
// 3. Migrate existing data
// 4. Remove duplicate fields

import 'package:drift/drift.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NEW: ENCOUNTERS TABLE - Central hub for each patient visit
// ═══════════════════════════════════════════════════════════════════════════════
// Every clinical interaction starts with an Encounter. All other data references it.

class Encounters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()(); // References Patients
  IntColumn get appointmentId => integer().nullable()(); // References Appointments (if scheduled)
  
  // Encounter metadata
  DateTimeColumn get encounterDate => dateTime()();
  TextColumn get encounterType => text().withDefault(const Constant('outpatient'))(); 
  // Types: 'outpatient', 'follow_up', 'emergency', 'telehealth', 'inpatient', 'procedure'
  
  TextColumn get status => text().withDefault(const Constant('in_progress'))();
  // Status: 'scheduled', 'checked_in', 'in_progress', 'completed', 'cancelled', 'no_show'
  
  TextColumn get chiefComplaint => text().withDefault(const Constant(''))();
  TextColumn get providerName => text().withDefault(const Constant(''))();
  TextColumn get providerType => text().withDefault(const Constant('psychiatrist'))();
  
  // Billing info
  BoolColumn get isBillable => boolean().withDefault(const Constant(true))();
  IntColumn get invoiceId => integer().nullable()(); // Link to invoice when billed
  
  // Timestamps
  DateTimeColumn get checkInTime => dateTime().nullable()();
  DateTimeColumn get checkOutTime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEW: DIAGNOSES TABLE - Normalized diagnosis tracking
// ═══════════════════════════════════════════════════════════════════════════════
// Single source of truth for all diagnoses. Referenced by other tables, not duplicated.

class Diagnoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()(); // References Patients
  IntColumn get encounterId => integer().nullable()(); // References Encounters (when diagnosed)
  
  // Diagnosis details
  TextColumn get icdCode => text().withDefault(const Constant(''))(); // ICD-10 code
  TextColumn get description => text()(); // Diagnosis description
  TextColumn get category => text().withDefault(const Constant('psychiatric'))();
  // Categories: 'psychiatric', 'medical', 'substance', 'developmental', 'neurological'
  
  TextColumn get severity => text().withDefault(const Constant('moderate'))();
  // Severity: 'mild', 'moderate', 'severe', 'in_remission', 'resolved'
  
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'resolved', 'chronic', 'rule_out', 'history_of'
  
  // Clinical tracking
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get diagnosedDate => dateTime()();
  DateTimeColumn get resolvedDate => dateTime().nullable()();
  
  // Primary/Secondary
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEW: CLINICAL NOTES TABLE - SOAP notes and assessments
// ═══════════════════════════════════════════════════════════════════════════════
// Replaces free-text in MedicalRecords. Structured SOAP format.

class ClinicalNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer()(); // References Encounters
  IntColumn get patientId => integer()(); // References Patients
  
  TextColumn get noteType => text().withDefault(const Constant('progress'))();
  // Types: 'initial_assessment', 'progress', 'psychiatric_eval', 'therapy_note', 
  //        'medication_review', 'procedure_note', 'discharge_summary'
  
  // SOAP Format
  TextColumn get subjective => text().withDefault(const Constant(''))(); // Patient's complaints
  TextColumn get objective => text().withDefault(const Constant(''))(); // Exam findings, vitals reference
  TextColumn get assessment => text().withDefault(const Constant(''))(); // Clinical impression
  TextColumn get plan => text().withDefault(const Constant(''))(); // Treatment plan
  
  // Mental Status Exam (for psychiatric)
  TextColumn get mentalStatusExam => text().withDefault(const Constant('{}'))(); // JSON
  
  // Risk Assessment
  TextColumn get riskLevel => text().withDefault(const Constant('none'))();
  TextColumn get riskFactors => text().withDefault(const Constant(''))();
  TextColumn get safetyPlan => text().withDefault(const Constant(''))();
  
  // Signatures
  TextColumn get signedBy => text().withDefault(const Constant(''))();
  DateTimeColumn get signedAt => dateTime().nullable()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEW: ENCOUNTER_DIAGNOSES - Links encounters to diagnoses addressed
// ═══════════════════════════════════════════════════════════════════════════════

class EncounterDiagnoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer()(); // References Encounters
  IntColumn get diagnosisId => integer()(); // References Diagnoses
  
  BoolColumn get isNewDiagnosis => boolean().withDefault(const Constant(false))();
  TextColumn get encounterStatus => text().withDefault(const Constant('addressed'))();
  // Status: 'addressed', 'monitored', 'worsened', 'improved', 'resolved'
  
  TextColumn get notes => text().withDefault(const Constant(''))();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATED: VITAL SIGNS - Now linked to Encounter
// ═══════════════════════════════════════════════════════════════════════════════
// Remove duplicate vitals from Prescriptions and MedicalRecords

class VitalSignsV2 extends Table {
  @override
  String get tableName => 'vital_signs'; // Keep same table name for migration
  
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()();
  IntColumn get encounterId => integer().nullable()(); // NEW: Link to encounter
  
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get systolicBp => real().nullable()();
  RealColumn get diastolicBp => real().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get temperature => real().nullable()();
  IntColumn get respiratoryRate => integer().nullable()();
  RealColumn get oxygenSaturation => real().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get height => real().nullable()();
  RealColumn get bmi => real().nullable()();
  IntColumn get painLevel => integer().nullable()();
  TextColumn get bloodGlucose => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATED: PRESCRIPTIONS - Reference encounter and diagnoses, no duplicate data
// ═══════════════════════════════════════════════════════════════════════════════

class PrescriptionsV2 extends Table {
  @override
  String get tableName => 'prescriptions';
  
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()();
  IntColumn get encounterId => integer().nullable()(); // NEW: Link to encounter
  
  // Medications (keep as JSON for flexibility)
  TextColumn get itemsJson => text()();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  BoolColumn get isRefillable => boolean().withDefault(const Constant(false))();
  
  // REMOVED: diagnosis, chiefComplaint, vitalsJson (now in Encounter/ClinicalNotes/VitalSigns)
  // References instead:
  IntColumn get primaryDiagnosisId => integer().nullable()(); // References Diagnoses
  
  // Pharmacy info
  TextColumn get pharmacyName => text().withDefault(const Constant(''))();
  TextColumn get pharmacyPhone => text().withDefault(const Constant(''))();
  
  // Status tracking
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'completed', 'discontinued', 'expired'
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATED: MEDICAL RECORDS - Simplified, links to Encounter
// ═══════════════════════════════════════════════════════════════════════════════
// Becomes a container for specialized record types (labs, imaging, etc.)
// Clinical notes moved to ClinicalNotes table

class MedicalRecordsV2 extends Table {
  @override
  String get tableName => 'medical_records';
  
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()();
  IntColumn get encounterId => integer().nullable()(); // NEW: Link to encounter
  
  TextColumn get recordType => text()();
  // Simplified types: 'lab_result', 'imaging', 'procedure', 'external_record', 'document'
  // Note: 'general' and 'psychiatric_assessment' now go to ClinicalNotes
  
  TextColumn get title => text()();
  TextColumn get dataJson => text().withDefault(const Constant('{}'))();
  
  // REMOVED: diagnosis, treatment, doctorNotes, description (moved to ClinicalNotes)
  
  // External record info
  TextColumn get sourceProvider => text().withDefault(const Constant(''))();
  TextColumn get sourceLocation => text().withDefault(const Constant(''))();
  
  // File attachment
  TextColumn get attachmentPath => text().withDefault(const Constant(''))();
  
  DateTimeColumn get recordDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATED: TREATMENT SESSIONS - Link to Encounter
// ═══════════════════════════════════════════════════════════════════════════════

class TreatmentSessionsV2 extends Table {
  @override
  String get tableName => 'treatment_sessions';
  
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()();
  IntColumn get encounterId => integer().nullable()(); // NEW: Link to encounter
  IntColumn get treatmentOutcomeId => integer().nullable()();
  
  DateTimeColumn get sessionDate => dateTime()();
  TextColumn get sessionType => text().withDefault(const Constant('individual'))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(50))();
  
  // REMOVED: providerType, providerName, sessionNotes (in Encounter/ClinicalNotes)
  // Keep therapy-specific fields:
  TextColumn get interventionsUsed => text().withDefault(const Constant(''))();
  TextColumn get patientMood => text().withDefault(const Constant(''))();
  IntColumn get moodRating => integer().nullable()();
  TextColumn get homeworkAssigned => text().withDefault(const Constant(''))();
  TextColumn get homeworkReview => text().withDefault(const Constant(''))();
  TextColumn get planForNextSession => text().withDefault(const Constant(''))();
  
  BoolColumn get isBillable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATED: TREATMENT OUTCOMES - Reference Diagnoses instead of storing diagnosis text
// ═══════════════════════════════════════════════════════════════════════════════

class TreatmentOutcomesV2 extends Table {
  @override
  String get tableName => 'treatment_outcomes';
  
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer()();
  IntColumn get diagnosisId => integer().nullable()(); // NEW: Reference to Diagnoses table
  
  TextColumn get treatmentType => text()();
  TextColumn get treatmentDescription => text()();
  
  // REMOVED: diagnosis, providerType, providerName (in Diagnoses/Encounter)
  
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get outcome => text().withDefault(const Constant('ongoing'))();
  IntColumn get effectivenessScore => integer().nullable()();
  TextColumn get sideEffects => text().withDefault(const Constant(''))();
  TextColumn get patientFeedback => text().withDefault(const Constant(''))();
  TextColumn get treatmentPhase => text().withDefault(const Constant('acute'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get lastReviewDate => dateTime().nullable()();
  DateTimeColumn get nextReviewDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA FLOW DIAGRAM (After Migration)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Patient Visit Workflow:
//
// 1. APPOINTMENT (optional) ──────────────┐
//                                         │
// 2. ENCOUNTER (central hub) ◄────────────┘
//    │
//    ├──► VITAL SIGNS (encounterId)
//    │
//    ├──► CLINICAL NOTES (encounterId)
//    │    - SOAP format
//    │    - Mental status exam
//    │    - Risk assessment
//    │
//    ├──► ENCOUNTER_DIAGNOSES ◄──► DIAGNOSES (patient's diagnosis list)
//    │
//    ├──► PRESCRIPTIONS (encounterId, primaryDiagnosisId)
//    │
//    ├──► TREATMENT SESSIONS (encounterId) ──► TREATMENT OUTCOMES (diagnosisId)
//    │
//    ├──► MEDICAL RECORDS (labs, imaging - encounterId)
//    │
//    └──► INVOICE (linked from encounter.invoiceId)
//
// Benefits:
// ✓ No duplicate diagnosis text
// ✓ No duplicate vitals
// ✓ Single source of truth for chief complaint
// ✓ Proper ICD coding
// ✓ Diagnosis history tracking (resolved, active, etc.)
// ✓ Clean audit trail (all actions link to encounter)
// ✓ Proper clinical workflow support
// ═══════════════════════════════════════════════════════════════════════════════
