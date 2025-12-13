// Minimal Drift DB. Run `flutter pub run build_runner build` to generate code.
import 'dart:convert';
import 'package:drift/drift.dart';

// Conditional imports for platform-specific code
import 'doctor_db_native.dart' if (dart.library.html) 'doctor_db_web.dart' as impl;

part 'doctor_db.g.dart';

class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  IntColumn get age => integer().nullable()();  // Age in years
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get medicalHistory => text().withDefault(const Constant(''))();
  TextColumn get allergies => text().withDefault(const Constant(''))(); // comma-separated allergies
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated
  IntColumn get riskLevel => integer().withDefault(const Constant(0))();
  TextColumn get gender => text().withDefault(const Constant(''))();
  TextColumn get bloodType => text().withDefault(const Constant(''))();
  TextColumn get emergencyContactName => text().withDefault(const Constant(''))();
  TextColumn get emergencyContactPhone => text().withDefault(const Constant(''))();
  RealColumn get height => real().nullable()(); // in cm
  RealColumn get weight => real().nullable()(); // in kg
  TextColumn get chronicConditions => text().withDefault(const Constant(''))(); // comma-separated
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  DateTimeColumn get appointmentDateTime => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(15))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get medicalRecordId => integer().nullable().references(MedicalRecords, #id)(); // Link to assessment done during visit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)(); // V2: Link to encounter
  IntColumn get primaryDiagnosisId => integer().nullable().references(Diagnoses, #id)(); // V2: Primary diagnosis
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get itemsJson => text()();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  BoolColumn get isRefillable => boolean().withDefault(const Constant(false))();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)(); // Link to appointment where prescribed
  IntColumn get medicalRecordId => integer().nullable().references(MedicalRecords, #id)(); // Link to diagnosis/assessment
  // DEPRECATED in V2 - Use Encounters.chiefComplaint and VitalSigns table instead
  @Deprecated('Use primaryDiagnosisId instead - links to Diagnoses table')
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  @Deprecated('Use Encounters.chiefComplaint instead')
  TextColumn get chiefComplaint => text().withDefault(const Constant(''))();
  @Deprecated('Use VitalSigns table with encounterId instead')
  TextColumn get vitalsJson => text().withDefault(const Constant('{}'))();
}

class MedicalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)(); // V2: Link to encounter
  TextColumn get recordType => text()(); // 'general', 'psychiatric_assessment', 'lab_result', 'imaging', 'procedure'
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get dataJson => text().withDefault(const Constant('{}'))(); // Stores form data as JSON
  @Deprecated('Use Diagnoses table via encounterId and EncounterDiagnoses instead')
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get treatment => text().withDefault(const Constant(''))();
  TextColumn get doctorNotes => text().withDefault(const Constant(''))();
  DateTimeColumn get recordDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get itemsJson => text()(); // JSON array of items
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('Pending'))(); // 'Pending', 'Partial', 'Paid', 'Overdue'
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)(); // Link to appointment for which billing
  IntColumn get prescriptionId => integer().nullable().references(Prescriptions, #id)(); // Link to prescription items
  IntColumn get treatmentSessionId => integer().nullable().references(TreatmentSessions, #id)(); // Link to treatment session
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Vital Signs tracking for patients
class VitalSigns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)(); // V2: Link to encounter
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get systolicBp => real().nullable()(); // mmHg
  RealColumn get diastolicBp => real().nullable()(); // mmHg
  IntColumn get heartRate => integer().nullable()(); // bpm
  RealColumn get temperature => real().nullable()(); // Celsius
  IntColumn get respiratoryRate => integer().nullable()(); // breaths/min
  RealColumn get oxygenSaturation => real().nullable()(); // SpO2 %
  RealColumn get weight => real().nullable()(); // kg
  RealColumn get height => real().nullable()(); // cm
  RealColumn get bmi => real().nullable()(); // calculated
  IntColumn get painLevel => integer().nullable()(); // 0-10 scale
  TextColumn get bloodGlucose => text().withDefault(const Constant(''))(); // mg/dL
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get recordedByAppointmentId => integer().nullable()(); // Link to appointment
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Treatment outcomes for tracking effectiveness
class TreatmentOutcomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get prescriptionId => integer().nullable()(); // Link to prescription
  IntColumn get medicalRecordId => integer().nullable()(); // Link to record
  TextColumn get treatmentType => text()(); // 'medication', 'therapy', 'procedure', 'lifestyle', 'combination'
  TextColumn get treatmentDescription => text()();
  TextColumn get providerType => text().withDefault(const Constant('psychiatrist'))(); // 'psychiatrist', 'therapist', 'counselor', 'primary_care'
  TextColumn get providerName => text().withDefault(const Constant(''))();
  @Deprecated('Use Diagnoses table - link via prescriptionId or medicalRecordId to encounter')
  TextColumn get diagnosis => text().withDefault(const Constant(''))(); // Primary diagnosis being treated
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get outcome => text().withDefault(const Constant('ongoing'))(); // 'improved', 'stable', 'worsened', 'resolved', 'ongoing'
  IntColumn get effectivenessScore => integer().nullable()(); // 1-10 scale
  TextColumn get sideEffects => text().withDefault(const Constant(''))();
  TextColumn get patientFeedback => text().withDefault(const Constant(''))();
  TextColumn get treatmentPhase => text().withDefault(const Constant('acute'))(); // 'acute', 'continuation', 'maintenance'
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get lastReviewDate => dateTime().nullable()();
  DateTimeColumn get nextReviewDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Scheduled follow-ups for automation
class ScheduledFollowUps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get sourceAppointmentId => integer().nullable()(); // Original appointment
  IntColumn get sourcePrescriptionId => integer().nullable()(); // If follow-up for prescription
  DateTimeColumn get scheduledDate => dateTime()();
  TextColumn get reason => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'scheduled', 'completed', 'cancelled'
  IntColumn get createdAppointmentId => integer().nullable()(); // When converted to appointment
  BoolColumn get reminderSent => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Treatment Sessions - Session notes linked to assessments
class TreatmentSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)(); // V2: Link to encounter
  IntColumn get treatmentOutcomeId => integer().nullable()(); // Link to treatment being tracked
  IntColumn get appointmentId => integer().nullable()(); // Link to appointment
  IntColumn get medicalRecordId => integer().nullable()(); // Link to assessment/record
  DateTimeColumn get sessionDate => dateTime()();
  TextColumn get providerType => text().withDefault(const Constant('psychiatrist'))(); // 'psychiatrist', 'therapist', 'counselor', 'nurse'
  TextColumn get providerName => text().withDefault(const Constant(''))();
  TextColumn get sessionType => text().withDefault(const Constant('individual'))(); // 'individual', 'group', 'family', 'couples'
  IntColumn get durationMinutes => integer().withDefault(const Constant(50))();
  TextColumn get presentingConcerns => text().withDefault(const Constant(''))();
  TextColumn get sessionNotes => text().withDefault(const Constant(''))();
  TextColumn get interventionsUsed => text().withDefault(const Constant(''))(); // JSON array
  TextColumn get patientMood => text().withDefault(const Constant(''))(); // e.g., 'anxious', 'depressed', 'stable'
  IntColumn get moodRating => integer().nullable()(); // 1-10 scale
  TextColumn get progressNotes => text().withDefault(const Constant(''))();
  TextColumn get homeworkAssigned => text().withDefault(const Constant(''))();
  TextColumn get homeworkReview => text().withDefault(const Constant(''))(); // Review of previous homework
  TextColumn get riskAssessment => text().withDefault(const Constant(''))(); // 'none', 'low', 'moderate', 'high'
  TextColumn get planForNextSession => text().withDefault(const Constant(''))();
  BoolColumn get isBillable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Medication Responses - Track medication effectiveness and side effects
class MedicationResponses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get prescriptionId => integer().nullable()(); // Link to prescription
  IntColumn get treatmentOutcomeId => integer().nullable()(); // Link to treatment outcome
  TextColumn get medicationName => text()();
  TextColumn get dosage => text().withDefault(const Constant(''))();
  TextColumn get frequency => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get responseStatus => text().withDefault(const Constant('monitoring'))(); // 'effective', 'partial', 'ineffective', 'monitoring', 'discontinued'
  IntColumn get effectivenessScore => integer().nullable()(); // 1-10 scale
  TextColumn get targetSymptoms => text().withDefault(const Constant(''))(); // JSON array of symptoms being treated
  TextColumn get symptomImprovement => text().withDefault(const Constant(''))(); // JSON: symptom -> improvement level
  TextColumn get sideEffects => text().withDefault(const Constant(''))(); // JSON array of side effects
  TextColumn get sideEffectSeverity => text().withDefault(const Constant('none'))(); // 'none', 'mild', 'moderate', 'severe'
  BoolColumn get adherent => boolean().withDefault(const Constant(true))();
  TextColumn get adherenceNotes => text().withDefault(const Constant(''))();
  TextColumn get labsRequired => text().withDefault(const Constant(''))(); // Labs needed for monitoring
  DateTimeColumn get nextLabDate => dateTime().nullable()();
  TextColumn get providerNotes => text().withDefault(const Constant(''))();
  TextColumn get patientFeedback => text().withDefault(const Constant(''))();
  DateTimeColumn get lastReviewDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Treatment Goals - Track progress toward treatment goals
class TreatmentGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable()(); // Link to overall treatment
  TextColumn get goalCategory => text().withDefault(const Constant('symptom'))(); // 'symptom', 'functional', 'behavioral', 'cognitive', 'interpersonal'
  TextColumn get goalDescription => text()();
  TextColumn get targetBehavior => text().withDefault(const Constant(''))(); // Specific measurable behavior
  TextColumn get baselineMeasure => text().withDefault(const Constant(''))(); // Starting point
  TextColumn get targetMeasure => text().withDefault(const Constant(''))(); // Goal to achieve
  TextColumn get currentMeasure => text().withDefault(const Constant(''))(); // Current progress
  IntColumn get progressPercent => integer().withDefault(const Constant(0))(); // 0-100%
  TextColumn get status => text().withDefault(const Constant('active'))(); // 'active', 'achieved', 'modified', 'discontinued'
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get interventions => text().withDefault(const Constant(''))(); // JSON array of interventions used
  TextColumn get barriers => text().withDefault(const Constant(''))(); // Barriers to progress
  TextColumn get progressNotes => text().withDefault(const Constant(''))(); // JSON array of progress entries
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 1=high, 2=medium, 3=low
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get achievedAt => dateTime().nullable()();
}

/// Model to hold a medical record with its associated patient
class MedicalRecordWithPatient {

  MedicalRecordWithPatient({required this.record, required this.patient});
  final MedicalRecord record;
  final Patient patient;
}

/// Audit Log - HIPAA compliance tracking of all data access and modifications
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // 'LOGIN', 'LOGOUT', 'VIEW_PATIENT', 'UPDATE_PATIENT', 'CREATE_RECORD', 'UPDATE_RECORD', 'DELETE_RECORD', 'VIEW_VITALS', 'EXPORT_DATA', etc.
  TextColumn get doctorName => text()(); // Doctor performing the action
  TextColumn get doctorRole => text().withDefault(const Constant('doctor'))(); // 'doctor', 'staff', 'admin'
  IntColumn get patientId => integer().nullable()(); // Patient affected by the action
  TextColumn get patientName => text().withDefault(const Constant(''))(); // Patient name for quick reference
  TextColumn get entityType => text().withDefault(const Constant(''))(); // 'PATIENT', 'VITAL_SIGN', 'PRESCRIPTION', 'APPOINTMENT', etc.
  IntColumn get entityId => integer().nullable()(); // ID of the entity being accessed/modified
  TextColumn get actionDetails => text().withDefault(const Constant(''))(); // JSON: before/after values for changes
  TextColumn get ipAddress => text().withDefault(const Constant(''))(); // IP address if available
  TextColumn get deviceInfo => text().withDefault(const Constant(''))(); // Device info (platform, browser, etc.)
  TextColumn get result => text().withDefault(const Constant('SUCCESS'))(); // 'SUCCESS', 'FAILURE', 'DENIED'
  TextColumn get notes => text().withDefault(const Constant(''))(); // Any additional notes
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V2: ENCOUNTER-BASED CLINICAL DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Encounters - Central hub for each patient visit
/// Every clinical interaction starts with an Encounter. All other data references it.
class Encounters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)();
  
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
  IntColumn get invoiceId => integer().nullable().references(Invoices, #id)();
  
  // Timestamps
  DateTimeColumn get checkInTime => dateTime().nullable()();
  DateTimeColumn get checkOutTime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Diagnoses - Normalized diagnosis tracking
/// Single source of truth for all diagnoses. Referenced by other tables, not duplicated.
class Diagnoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Diagnosis details
  TextColumn get icdCode => text().withDefault(const Constant(''))(); // ICD-10 code
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('psychiatric'))();
  // Categories: 'psychiatric', 'medical', 'substance', 'developmental', 'neurological'
  
  TextColumn get severity => text().withDefault(const Constant('moderate'))();
  // Severity: 'mild', 'moderate', 'severe', 'in_remission', 'resolved'
  
  TextColumn get diagnosisStatus => text().withDefault(const Constant('active'))();
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

/// Clinical Notes - SOAP notes and assessments
/// Structured SOAP format for clinical documentation.
class ClinicalNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer().references(Encounters, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get noteType => text().withDefault(const Constant('progress'))();
  // Types: 'initial_assessment', 'progress', 'psychiatric_eval', 'therapy_note', 
  //        'medication_review', 'procedure_note', 'discharge_summary'
  
  // SOAP Format
  TextColumn get subjective => text().withDefault(const Constant(''))(); // Patient's complaints
  TextColumn get objective => text().withDefault(const Constant(''))(); // Exam findings
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

/// Encounter Diagnoses - Links encounters to diagnoses addressed during the visit
class EncounterDiagnoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer().references(Encounters, #id)();
  IntColumn get diagnosisId => integer().references(Diagnoses, #id)();
  
  BoolColumn get isNewDiagnosis => boolean().withDefault(const Constant(false))();
  TextColumn get encounterStatus => text().withDefault(const Constant('addressed'))();
  // Status: 'addressed', 'monitored', 'worsened', 'improved', 'resolved'
  
  TextColumn get notes => text().withDefault(const Constant(''))();
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V3: COMPREHENSIVE CLINICAL FEATURES
// ═══════════════════════════════════════════════════════════════════════════════

/// Referrals - Track patient referrals to specialists
class Referrals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Referral details
  TextColumn get referralType => text().withDefault(const Constant('specialist'))();
  // Types: 'specialist', 'diagnostic', 'therapy', 'surgery', 'emergency', 'second_opinion'
  
  TextColumn get specialty => text()(); // e.g., 'Cardiology', 'Neurology', 'Orthopedics'
  TextColumn get referredToName => text().withDefault(const Constant(''))();
  TextColumn get referredToFacility => text().withDefault(const Constant(''))();
  TextColumn get referredToPhone => text().withDefault(const Constant(''))();
  TextColumn get referredToEmail => text().withDefault(const Constant(''))();
  TextColumn get referredToAddress => text().withDefault(const Constant(''))();
  
  // Clinical info
  TextColumn get reasonForReferral => text()();
  TextColumn get clinicalHistory => text().withDefault(const Constant(''))();
  TextColumn get diagnosisIds => text().withDefault(const Constant(''))(); // JSON array of diagnosis IDs
  TextColumn get urgency => text().withDefault(const Constant('routine'))();
  // Urgency: 'stat', 'urgent', 'routine', 'elective'
  
  // Status tracking
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // Status: 'draft', 'pending', 'sent', 'accepted', 'scheduled', 'completed', 'cancelled', 'rejected'
  
  DateTimeColumn get referralDate => dateTime()();
  DateTimeColumn get appointmentDate => dateTime().nullable()();
  DateTimeColumn get completedDate => dateTime().nullable()();
  
  // Outcome
  TextColumn get consultationNotes => text().withDefault(const Constant(''))();
  TextColumn get recommendations => text().withDefault(const Constant(''))();
  TextColumn get attachments => text().withDefault(const Constant(''))(); // JSON array of file paths
  
  // Insurance
  TextColumn get preAuthRequired => text().withDefault(const Constant('unknown'))();
  TextColumn get preAuthStatus => text().withDefault(const Constant(''))();
  TextColumn get preAuthNumber => text().withDefault(const Constant(''))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Immunizations - Vaccination records and schedules
class Immunizations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Vaccine details
  TextColumn get vaccineName => text()();
  TextColumn get vaccineCode => text().withDefault(const Constant(''))(); // CVX code
  TextColumn get manufacturer => text().withDefault(const Constant(''))();
  TextColumn get lotNumber => text().withDefault(const Constant(''))();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  
  // Administration
  DateTimeColumn get administeredDate => dateTime()();
  TextColumn get administeredBy => text().withDefault(const Constant(''))();
  TextColumn get administrationSite => text().withDefault(const Constant(''))(); // e.g., 'Left deltoid'
  TextColumn get route => text().withDefault(const Constant('IM'))(); // 'IM', 'SC', 'PO', 'IN'
  TextColumn get dose => text().withDefault(const Constant(''))();
  IntColumn get doseNumber => integer().withDefault(const Constant(1))(); // Which dose in series
  IntColumn get seriesTotal => integer().nullable()(); // Total doses in series
  
  // Status
  TextColumn get status => text().withDefault(const Constant('completed'))();
  // Status: 'scheduled', 'completed', 'refused', 'contraindicated', 'deferred'
  
  TextColumn get refusalReason => text().withDefault(const Constant(''))();
  TextColumn get contraindication => text().withDefault(const Constant(''))();
  
  // Reaction tracking
  BoolColumn get hadReaction => boolean().withDefault(const Constant(false))();
  TextColumn get reactionDetails => text().withDefault(const Constant(''))();
  TextColumn get reactionSeverity => text().withDefault(const Constant(''))(); // 'mild', 'moderate', 'severe'
  
  // Next dose
  DateTimeColumn get nextDoseDate => dateTime().nullable()();
  BoolColumn get reminderSent => boolean().withDefault(const Constant(false))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// FamilyMedicalHistory - Structured family history tracking
class FamilyMedicalHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Family member
  TextColumn get relationship => text()(); // 'father', 'mother', 'sibling', 'grandparent_paternal', etc.
  TextColumn get relativeName => text().withDefault(const Constant(''))();
  IntColumn get relativeAge => integer().nullable()();
  BoolColumn get isDeceased => boolean().withDefault(const Constant(false))();
  IntColumn get ageAtDeath => integer().nullable()();
  TextColumn get causeOfDeath => text().withDefault(const Constant(''))();
  
  // Medical conditions
  TextColumn get conditions => text().withDefault(const Constant(''))(); // JSON array of conditions
  TextColumn get conditionDetails => text().withDefault(const Constant(''))(); // JSON: condition -> details
  
  // Specific conditions flags for quick queries
  BoolColumn get hasHeartDisease => boolean().withDefault(const Constant(false))();
  BoolColumn get hasDiabetes => boolean().withDefault(const Constant(false))();
  BoolColumn get hasCancer => boolean().withDefault(const Constant(false))();
  TextColumn get cancerTypes => text().withDefault(const Constant(''))();
  BoolColumn get hasHypertension => boolean().withDefault(const Constant(false))();
  BoolColumn get hasStroke => boolean().withDefault(const Constant(false))();
  BoolColumn get hasMentalIllness => boolean().withDefault(const Constant(false))();
  TextColumn get mentalIllnessTypes => text().withDefault(const Constant(''))();
  BoolColumn get hasSubstanceAbuse => boolean().withDefault(const Constant(false))();
  BoolColumn get hasGeneticDisorder => boolean().withDefault(const Constant(false))();
  TextColumn get geneticDisorderTypes => text().withDefault(const Constant(''))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// PatientConsents - Manage consent forms and documentation
class PatientConsents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Consent details
  TextColumn get consentType => text()();
  // Types: 'treatment', 'procedure', 'hipaa', 'research', 'medication', 'telehealth', 
  //        'photo_video', 'information_release', 'financial', 'advance_directive'
  
  TextColumn get consentTitle => text()();
  TextColumn get consentDescription => text().withDefault(const Constant(''))();
  TextColumn get consentText => text().withDefault(const Constant(''))(); // Full consent text
  TextColumn get templateId => text().withDefault(const Constant(''))(); // Link to template
  
  // For procedure consent
  TextColumn get procedureName => text().withDefault(const Constant(''))();
  TextColumn get procedureRisks => text().withDefault(const Constant(''))();
  TextColumn get procedureBenefits => text().withDefault(const Constant(''))();
  TextColumn get procedureAlternatives => text().withDefault(const Constant(''))();
  
  // Signature
  TextColumn get signatureData => text().withDefault(const Constant(''))(); // Base64 signature image
  TextColumn get signedByName => text().withDefault(const Constant(''))();
  TextColumn get signedByRelationship => text().withDefault(const Constant('self'))(); // 'self', 'guardian', 'power_of_attorney'
  DateTimeColumn get signedAt => dateTime().nullable()();
  
  // Witness
  TextColumn get witnessName => text().withDefault(const Constant(''))();
  TextColumn get witnessSignature => text().withDefault(const Constant(''))();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // Status: 'pending', 'signed', 'refused', 'revoked', 'expired'
  
  DateTimeColumn get effectiveDate => dateTime()();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// InsuranceInfo - Patient insurance information
class InsuranceInfo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Insurance details
  TextColumn get insuranceType => text().withDefault(const Constant('primary'))(); // 'primary', 'secondary', 'tertiary'
  TextColumn get payerName => text()();
  TextColumn get payerId => text().withDefault(const Constant(''))();
  TextColumn get planName => text().withDefault(const Constant(''))();
  TextColumn get planType => text().withDefault(const Constant(''))(); // 'HMO', 'PPO', 'EPO', 'POS', 'HDHP'
  TextColumn get memberId => text()();
  TextColumn get groupNumber => text().withDefault(const Constant(''))();
  
  // Subscriber info
  TextColumn get subscriberName => text().withDefault(const Constant(''))();
  TextColumn get subscriberDob => text().withDefault(const Constant(''))();
  TextColumn get subscriberRelationship => text().withDefault(const Constant('self'))();
  
  // Coverage details
  DateTimeColumn get effectiveDate => dateTime()();
  DateTimeColumn get terminationDate => dateTime().nullable()();
  RealColumn get copay => real().withDefault(const Constant(0))();
  RealColumn get deductible => real().withDefault(const Constant(0))();
  RealColumn get deductibleMet => real().withDefault(const Constant(0))();
  RealColumn get outOfPocketMax => real().withDefault(const Constant(0))();
  RealColumn get outOfPocketMet => real().withDefault(const Constant(0))();
  
  // Contact
  TextColumn get payerPhone => text().withDefault(const Constant(''))();
  TextColumn get payerAddress => text().withDefault(const Constant(''))();
  TextColumn get claimsAddress => text().withDefault(const Constant(''))();
  
  // Card images
  TextColumn get frontCardImage => text().withDefault(const Constant(''))();
  TextColumn get backCardImage => text().withDefault(const Constant(''))();
  
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// InsuranceClaims - Track insurance claims
class InsuranceClaims extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get insuranceId => integer().references(InsuranceInfo, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  IntColumn get invoiceId => integer().nullable().references(Invoices, #id)();
  
  // Claim details
  TextColumn get claimNumber => text()();
  TextColumn get claimType => text().withDefault(const Constant('professional'))(); // 'professional', 'institutional'
  DateTimeColumn get serviceDate => dateTime()();
  DateTimeColumn get submittedDate => dateTime().nullable()();
  
  // Billing codes
  TextColumn get diagnosisCodes => text().withDefault(const Constant(''))(); // JSON array of ICD-10 codes
  TextColumn get procedureCodes => text().withDefault(const Constant(''))(); // JSON array of CPT codes
  TextColumn get modifiers => text().withDefault(const Constant(''))(); // JSON: CPT -> modifiers
  TextColumn get placeOfService => text().withDefault(const Constant('11'))(); // POS code
  
  // Amounts
  RealColumn get billedAmount => real().withDefault(const Constant(0))();
  RealColumn get allowedAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get patientResponsibility => real().withDefault(const Constant(0))();
  RealColumn get adjustmentAmount => real().withDefault(const Constant(0))();
  TextColumn get adjustmentReason => text().withDefault(const Constant(''))();
  
  // Status tracking
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // Status: 'draft', 'submitted', 'acknowledged', 'pending', 'approved', 'denied', 
  //         'partially_paid', 'paid', 'appealed', 'void'
  
  TextColumn get denialReason => text().withDefault(const Constant(''))();
  TextColumn get denialCode => text().withDefault(const Constant(''))();
  DateTimeColumn get processedDate => dateTime().nullable()();
  DateTimeColumn get paidDate => dateTime().nullable()();
  
  // ERA/EOB info
  TextColumn get checkNumber => text().withDefault(const Constant(''))();
  TextColumn get eobDocument => text().withDefault(const Constant(''))(); // File path
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// PreAuthorizations - Track pre-authorization requests
class PreAuthorizations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get insuranceId => integer().references(InsuranceInfo, #id)();
  IntColumn get referralId => integer().nullable().references(Referrals, #id)();
  
  // Auth details
  TextColumn get authNumber => text().withDefault(const Constant(''))();
  TextColumn get authType => text()(); // 'procedure', 'medication', 'dme', 'imaging', 'therapy', 'admission'
  TextColumn get serviceDescription => text()();
  TextColumn get procedureCodes => text().withDefault(const Constant(''))(); // JSON array of CPT codes
  TextColumn get diagnosisCodes => text().withDefault(const Constant(''))(); // JSON array of ICD-10 codes
  
  // Request info
  DateTimeColumn get requestedDate => dateTime()();
  TextColumn get requestedBy => text().withDefault(const Constant(''))();
  IntColumn get unitsRequested => integer().withDefault(const Constant(1))();
  TextColumn get clinicalJustification => text().withDefault(const Constant(''))();
  TextColumn get supportingDocuments => text().withDefault(const Constant(''))(); // JSON array of file paths
  
  // Status
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // Status: 'draft', 'submitted', 'pending', 'approved', 'denied', 'partial', 'expired', 'cancelled'
  
  IntColumn get unitsApproved => integer().nullable()();
  IntColumn get unitsUsed => integer().withDefault(const Constant(0))();
  DateTimeColumn get approvedDate => dateTime().nullable()();
  DateTimeColumn get effectiveDate => dateTime().nullable()();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  
  TextColumn get denialReason => text().withDefault(const Constant(''))();
  TextColumn get appealInfo => text().withDefault(const Constant(''))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// LabOrders - Track lab orders
class LabOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Order details
  TextColumn get orderNumber => text()();
  TextColumn get orderType => text().withDefault(const Constant('lab'))(); // 'lab', 'imaging', 'pathology', 'genetic'
  TextColumn get testCodes => text()(); // JSON array of test codes (LOINC)
  TextColumn get testNames => text()(); // JSON array of test names
  TextColumn get diagnosisCodes => text().withDefault(const Constant(''))(); // Supporting ICD-10 codes
  
  // Order info
  TextColumn get orderingProvider => text()();
  DateTimeColumn get orderedDate => dateTime()();
  TextColumn get priority => text().withDefault(const Constant('routine'))(); // 'stat', 'urgent', 'routine'
  TextColumn get fasting => text().withDefault(const Constant('no'))(); // 'yes', 'no', 'preferred'
  TextColumn get specialInstructions => text().withDefault(const Constant(''))();
  
  // Lab info
  TextColumn get labName => text().withDefault(const Constant(''))();
  TextColumn get labAddress => text().withDefault(const Constant(''))();
  TextColumn get labPhone => text().withDefault(const Constant(''))();
  TextColumn get labFax => text().withDefault(const Constant(''))();
  
  // Collection
  DateTimeColumn get collectionDate => dateTime().nullable()();
  TextColumn get collectionSite => text().withDefault(const Constant(''))(); // 'in-office', 'lab', 'home'
  TextColumn get specimenType => text().withDefault(const Constant(''))();
  TextColumn get specimenId => text().withDefault(const Constant(''))();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // Status: 'draft', 'pending', 'sent', 'received', 'in_progress', 'resulted', 'cancelled'
  
  // Results
  IntColumn get medicalRecordId => integer().nullable().references(MedicalRecords, #id)();
  DateTimeColumn get resultedDate => dateTime().nullable()();
  BoolColumn get hasAbnormal => boolean().withDefault(const Constant(false))();
  BoolColumn get hasCritical => boolean().withDefault(const Constant(false))();
  BoolColumn get reviewed => boolean().withDefault(const Constant(false))();
  TextColumn get reviewedBy => text().withDefault(const Constant(''))();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ProblemList - Active problems for the patient
class ProblemList extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get diagnosisId => integer().nullable().references(Diagnoses, #id)();
  
  // Problem details
  TextColumn get problemName => text()();
  TextColumn get icdCode => text().withDefault(const Constant(''))();
  TextColumn get snomedCode => text().withDefault(const Constant(''))();
  
  TextColumn get category => text().withDefault(const Constant('medical'))();
  // Categories: 'medical', 'surgical', 'psychiatric', 'social', 'functional'
  
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'chronic', 'resolved', 'inactive', 'ruled_out'
  
  TextColumn get severity => text().withDefault(const Constant('moderate'))();
  // Severity: 'mild', 'moderate', 'severe', 'life_threatening'
  
  TextColumn get clinicalStatus => text().withDefault(const Constant('confirmed'))();
  // Clinical: 'confirmed', 'provisional', 'differential', 'rule_out'
  
  IntColumn get priority => integer().withDefault(const Constant(5))(); // 1-10, lower = higher priority
  
  // Dates
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get diagnosedDate => dateTime().nullable()();
  DateTimeColumn get resolvedDate => dateTime().nullable()();
  DateTimeColumn get lastReviewedDate => dateTime().nullable()();
  
  // Goals
  TextColumn get treatmentGoal => text().withDefault(const Constant(''))();
  TextColumn get currentTreatment => text().withDefault(const Constant(''))();
  
  BoolColumn get isChiefConcern => boolean().withDefault(const Constant(false))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// GrowthMeasurements - Pediatric growth tracking
class GrowthMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  DateTimeColumn get measurementDate => dateTime()();
  IntColumn get ageMonths => integer()(); // Age at measurement in months
  
  // Measurements
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get headCircumferenceCm => real().nullable()();
  RealColumn get bmi => real().nullable()();
  
  // Percentiles (WHO/CDC)
  RealColumn get weightPercentile => real().nullable()();
  RealColumn get heightPercentile => real().nullable()();
  RealColumn get headCircumferencePercentile => real().nullable()();
  RealColumn get bmiPercentile => real().nullable()();
  
  // Z-scores
  RealColumn get weightZScore => real().nullable()();
  RealColumn get heightZScore => real().nullable()();
  RealColumn get headCircumferenceZScore => real().nullable()();
  RealColumn get bmiZScore => real().nullable()();
  
  TextColumn get chartStandard => text().withDefault(const Constant('WHO'))(); // 'WHO', 'CDC'
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ClinicalReminders - Preventive care and screening reminders
class ClinicalReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Reminder details
  TextColumn get reminderType => text()();
  // Types: 'screening', 'immunization', 'lab', 'follow_up', 'medication', 'referral', 'wellness'
  
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get guidelineSource => text().withDefault(const Constant(''))(); // e.g., 'USPSTF', 'CDC', 'ACS'
  TextColumn get recommendation => text().withDefault(const Constant(''))();
  
  // Timing
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get frequency => text().withDefault(const Constant(''))(); // e.g., 'annual', 'every_3_years'
  DateTimeColumn get lastCompletedDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('due'))();
  // Status: 'upcoming', 'due', 'overdue', 'completed', 'declined', 'not_applicable'
  
  TextColumn get declinedReason => text().withDefault(const Constant(''))();
  IntColumn get completedEncounterId => integer().nullable()();
  
  // Priority
  IntColumn get priority => integer().withDefault(const Constant(2))(); // 1=high, 2=medium, 3=low
  BoolColumn get notificationSent => boolean().withDefault(const Constant(false))();
  
  // Age/gender based
  IntColumn get applicableMinAge => integer().nullable()();
  IntColumn get applicableMaxAge => integer().nullable()();
  TextColumn get applicableGender => text().withDefault(const Constant('all'))(); // 'all', 'male', 'female'
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// AppointmentWaitlist - Track patients waiting for appointments
class AppointmentWaitlist extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Request details
  TextColumn get reason => text()();
  TextColumn get preferredProvider => text().withDefault(const Constant(''))();
  TextColumn get preferredDays => text().withDefault(const Constant(''))(); // JSON array: ['monday', 'wednesday']
  TextColumn get preferredTimeStart => text().withDefault(const Constant(''))(); // HH:MM
  TextColumn get preferredTimeEnd => text().withDefault(const Constant(''))(); // HH:MM
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();
  
  // Urgency
  TextColumn get urgency => text().withDefault(const Constant('routine'))();
  // Urgency: 'stat', 'urgent', 'soon', 'routine'
  
  // Status
  TextColumn get status => text().withDefault(const Constant('waiting'))();
  // Status: 'waiting', 'contacted', 'scheduled', 'cancelled', 'expired'
  
  DateTimeColumn get requestedDate => dateTime()();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  IntColumn get scheduledAppointmentId => integer().nullable()();
  
  // Contact preferences
  TextColumn get contactMethod => text().withDefault(const Constant('phone'))(); // 'phone', 'sms', 'email'
  IntColumn get contactAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastContactedAt => dateTime().nullable()();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// RecurringAppointments - Manage recurring appointment patterns
class RecurringAppointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Recurrence pattern
  TextColumn get frequency => text()(); // 'daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'custom'
  IntColumn get intervalDays => integer().nullable()(); // For custom frequency
  TextColumn get daysOfWeek => text().withDefault(const Constant(''))(); // JSON array for weekly: ['monday', 'thursday']
  IntColumn get dayOfMonth => integer().nullable()(); // For monthly
  
  // Time
  TextColumn get preferredTime => text()(); // HH:MM
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();
  
  // Appointment details
  TextColumn get reason => text()();
  TextColumn get appointmentType => text().withDefault(const Constant('follow_up'))();
  TextColumn get provider => text().withDefault(const Constant(''))();
  
  // Date range
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()(); // null = indefinite
  IntColumn get maxOccurrences => integer().nullable()(); // null = no limit
  IntColumn get occurrencesCreated => integer().withDefault(const Constant(0))();
  
  // Status
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  // Status: 'active', 'paused', 'completed', 'cancelled'
  
  // Last generated
  DateTimeColumn get lastGeneratedDate => dateTime().nullable()();
  IntColumn get lastGeneratedAppointmentId => integer().nullable()();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ClinicalLetters - Medical letters and forms
class ClinicalLetters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  // Letter type
  TextColumn get letterType => text()();
  // Types: 'referral_letter', 'disability_form', 'fmla', 'work_excuse', 'school_excuse',
  //        'medical_clearance', 'insurance_letter', 'prior_auth', 'to_whom_it_may_concern',
  //        'specialist_summary', 'transfer_summary', 'consultation_reply', 'custom'
  
  TextColumn get title => text()();
  TextColumn get templateId => text().withDefault(const Constant(''))();
  
  // Recipient
  TextColumn get recipientName => text().withDefault(const Constant(''))();
  TextColumn get recipientFacility => text().withDefault(const Constant(''))();
  TextColumn get recipientAddress => text().withDefault(const Constant(''))();
  TextColumn get recipientFax => text().withDefault(const Constant(''))();
  
  // Content
  TextColumn get content => text()(); // Full letter content
  TextColumn get formData => text().withDefault(const Constant('{}'))(); // JSON for form-based letters
  
  // Dates
  DateTimeColumn get letterDate => dateTime()();
  DateTimeColumn get effectiveFrom => dateTime().nullable()();
  DateTimeColumn get effectiveTo => dateTime().nullable()();
  
  // Status
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // Status: 'draft', 'final', 'sent', 'faxed', 'printed', 'void'
  
  TextColumn get signedBy => text().withDefault(const Constant(''))();
  DateTimeColumn get signedAt => dateTime().nullable()();
  TextColumn get signatureData => text().withDefault(const Constant(''))();
  
  // Delivery tracking
  DateTimeColumn get sentAt => dateTime().nullable()();
  TextColumn get sentMethod => text().withDefault(const Constant(''))(); // 'fax', 'email', 'mail', 'portal'
  TextColumn get deliveryStatus => text().withDefault(const Constant(''))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// CPTCodes - Reference table for procedure codes
class CptCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text()();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  RealColumn get defaultFee => real().withDefault(const Constant(0))();
  IntColumn get defaultDuration => integer().withDefault(const Constant(15))(); // minutes
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════════
// DOCTOR PRODUCTIVITY FEATURES
// ═══════════════════════════════════════════════════════════════════════════════

/// FavoritePrescriptions - Save commonly used prescription templates
class FavoritePrescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // Template name, e.g., "Diabetes Standard", "Hypertension Basic"
  TextColumn get category => text().withDefault(const Constant('general'))(); // 'general', 'diabetes', 'hypertension', 'infection', etc.
  TextColumn get diagnosis => text().withDefault(const Constant(''))(); // Associated diagnosis
  TextColumn get medicationsJson => text()(); // JSON array of medications with dosage, frequency, duration
  TextColumn get instructions => text().withDefault(const Constant(''))(); // General instructions
  TextColumn get advice => text().withDefault(const Constant(''))(); // Patient advice
  TextColumn get labTests => text().withDefault(const Constant(''))(); // JSON array of lab tests
  IntColumn get usageCount => integer().withDefault(const Constant(0))(); // Track usage for sorting
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// QuickPhrases - Text expansion shortcuts for clinical notes
class QuickPhrases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shortcut => text()(); // e.g., ".dm", ".htn", ".nad"
  TextColumn get expansion => text()(); // Full text expansion
  TextColumn get category => text().withDefault(const Constant('general'))(); // 'diagnosis', 'exam', 'plan', 'history', 'general'
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// RecentPatients - Track recently viewed patients for quick access
class RecentPatients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  DateTimeColumn get accessedAt => dateTime()();
  TextColumn get accessType => text().withDefault(const Constant('view'))(); // 'view', 'edit', 'prescription', 'appointment'
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V5: FULLY NORMALIZED DATA - NO MORE JSON STORAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// PrescriptionMedications - Individual medications in a prescription (replaces itemsJson)
class PrescriptionMedications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prescriptionId => integer().references(Prescriptions, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Medication details
  TextColumn get medicationName => text()();
  TextColumn get genericName => text().withDefault(const Constant(''))();
  TextColumn get brandName => text().withDefault(const Constant(''))();
  TextColumn get drugCode => text().withDefault(const Constant(''))(); // RxNorm, NDC
  TextColumn get drugClass => text().withDefault(const Constant(''))();
  
  // Dosage
  TextColumn get strength => text().withDefault(const Constant(''))();
  TextColumn get dosageForm => text().withDefault(const Constant('tablet'))();
  TextColumn get route => text().withDefault(const Constant('oral'))();
  
  // Frequency & Duration
  TextColumn get frequency => text().withDefault(const Constant(''))();
  TextColumn get timing => text().withDefault(const Constant(''))();
  IntColumn get durationDays => integer().nullable()();
  TextColumn get durationText => text().withDefault(const Constant(''))();
  
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
  TextColumn get discontinueReason => text().withDefault(const Constant(''))();
  DateTimeColumn get discontinuedAt => dateTime().nullable()();
  
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// InvoiceLineItems - Individual items in an invoice (replaces itemsJson)
class InvoiceLineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get itemType => text().withDefault(const Constant('service'))();
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
  
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// FamilyConditions - Normalized family conditions (replaces FamilyMedicalHistory.conditions JSON)
class FamilyConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get familyHistoryId => integer().references(FamilyMedicalHistory, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get conditionName => text()();
  TextColumn get icdCode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('medical'))();
  IntColumn get ageAtOnset => integer().nullable()();
  TextColumn get severity => text().withDefault(const Constant(''))();
  TextColumn get outcome => text().withDefault(const Constant(''))();
  BoolColumn get confirmedDiagnosis => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// TreatmentSymptoms - Track symptoms being treated (replaces JSON arrays)
class TreatmentSymptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationResponseId => integer().nullable().references(MedicationResponses, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get symptomName => text()();
  TextColumn get symptomCategory => text().withDefault(const Constant(''))();
  IntColumn get baselineSeverity => integer().nullable()();
  IntColumn get currentSeverity => integer().nullable()();
  IntColumn get targetSeverity => integer().nullable()();
  TextColumn get improvementLevel => text().withDefault(const Constant('unchanged'))();
  IntColumn get improvementPercent => integer().nullable()();
  
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// SideEffects - Track medication/treatment side effects (replaces JSON)
class SideEffects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationResponseId => integer().nullable().references(MedicationResponses, #id)();
  IntColumn get prescriptionMedicationId => integer().nullable().references(PrescriptionMedications, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get effectName => text()();
  TextColumn get effectCategory => text().withDefault(const Constant('other'))();
  TextColumn get severity => text().withDefault(const Constant('mild'))();
  IntColumn get severityScore => integer().nullable()();
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get resolvedDate => dateTime().nullable()();
  TextColumn get frequency => text().withDefault(const Constant(''))();
  TextColumn get managementAction => text().withDefault(const Constant(''))();
  BoolColumn get causedDiscontinuation => boolean().withDefault(const Constant(false))();
  BoolColumn get reportedToProvider => boolean().withDefault(const Constant(true))();
  
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Attachments - Centralized file attachments (replaces JSON arrays)
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer()();
  
  TextColumn get fileName => text()();
  TextColumn get originalFileName => text().withDefault(const Constant(''))();
  TextColumn get filePath => text()();
  TextColumn get fileType => text().withDefault(const Constant(''))();
  TextColumn get fileExtension => text().withDefault(const Constant(''))();
  IntColumn get fileSizeBytes => integer().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  BoolColumn get isConfidential => boolean().withDefault(const Constant(false))();
  TextColumn get uploadedBy => text().withDefault(const Constant(''))();
  
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// MentalStatusExams - Structured MSE (replaces mentalStatusExam JSON)
class MentalStatusExams extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  IntColumn get clinicalNoteId => integer().nullable().references(ClinicalNotes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  // Appearance & Behavior
  TextColumn get appearance => text().withDefault(const Constant(''))();
  TextColumn get grooming => text().withDefault(const Constant('appropriate'))();
  TextColumn get attire => text().withDefault(const Constant('appropriate'))();
  TextColumn get eyeContact => text().withDefault(const Constant('appropriate'))();
  TextColumn get behavior => text().withDefault(const Constant(''))();
  TextColumn get psychomotorActivity => text().withDefault(const Constant('normal'))();
  TextColumn get attitude => text().withDefault(const Constant('cooperative'))();
  
  // Speech
  TextColumn get speechRate => text().withDefault(const Constant('normal'))();
  TextColumn get speechVolume => text().withDefault(const Constant('normal'))();
  TextColumn get speechTone => text().withDefault(const Constant('normal'))();
  TextColumn get speechQuality => text().withDefault(const Constant(''))();
  
  // Mood & Affect
  TextColumn get mood => text().withDefault(const Constant(''))();
  TextColumn get affect => text().withDefault(const Constant(''))();
  TextColumn get affectRange => text().withDefault(const Constant('full'))();
  TextColumn get affectCongruence => text().withDefault(const Constant('congruent'))();
  
  // Thought
  TextColumn get thoughtProcess => text().withDefault(const Constant('linear'))();
  TextColumn get thoughtContent => text().withDefault(const Constant(''))();
  
  // Perceptions
  BoolColumn get hallucinationsAuditory => boolean().withDefault(const Constant(false))();
  BoolColumn get hallucinationsVisual => boolean().withDefault(const Constant(false))();
  BoolColumn get hallucinationsOther => boolean().withDefault(const Constant(false))();
  TextColumn get hallucinationsDetails => text().withDefault(const Constant(''))();
  BoolColumn get delusions => boolean().withDefault(const Constant(false))();
  TextColumn get delusionsType => text().withDefault(const Constant(''))();
  
  // Safety
  BoolColumn get suicidalIdeation => boolean().withDefault(const Constant(false))();
  TextColumn get suicidalDetails => text().withDefault(const Constant(''))();
  BoolColumn get homicidalIdeation => boolean().withDefault(const Constant(false))();
  TextColumn get homicidalDetails => text().withDefault(const Constant(''))();
  BoolColumn get selfHarmIdeation => boolean().withDefault(const Constant(false))();
  
  // Cognition
  TextColumn get orientation => text().withDefault(const Constant('oriented_x4'))();
  TextColumn get attention => text().withDefault(const Constant('intact'))();
  TextColumn get concentration => text().withDefault(const Constant('intact'))();
  TextColumn get memory => text().withDefault(const Constant('intact'))();
  TextColumn get insight => text().withDefault(const Constant('good'))();
  TextColumn get judgment => text().withDefault(const Constant('good'))();
  
  TextColumn get additionalNotes => text().withDefault(const Constant(''))();
  DateTimeColumn get examinedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// LabTestResults - Individual test results (replaces testCodes/testNames JSON)
class LabTestResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get labOrderId => integer().references(LabOrders, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get testName => text()();
  TextColumn get testCode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get resultValue => text().withDefault(const Constant(''))();
  TextColumn get resultUnit => text().withDefault(const Constant(''))();
  TextColumn get resultType => text().withDefault(const Constant('numeric'))();
  TextColumn get referenceRange => text().withDefault(const Constant(''))();
  RealColumn get referenceLow => real().nullable()();
  RealColumn get referenceHigh => real().nullable()();
  TextColumn get flag => text().withDefault(const Constant('normal'))();
  BoolColumn get isAbnormal => boolean().withDefault(const Constant(false))();
  BoolColumn get isCritical => boolean().withDefault(const Constant(false))();
  TextColumn get previousValue => text().withDefault(const Constant(''))();
  DateTimeColumn get previousDate => dateTime().nullable()();
  TextColumn get trend => text().withDefault(const Constant(''))();
  TextColumn get interpretation => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get resultedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ProgressNoteEntries - Individual progress entries (replaces progressNotes JSON)
class ProgressNoteEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get treatmentGoalId => integer().nullable().references(TreatmentGoals, #id)();
  IntColumn get treatmentOutcomeId => integer().nullable().references(TreatmentOutcomes, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get encounterId => integer().nullable().references(Encounters, #id)();
  
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get note => text()();
  IntColumn get progressRating => integer().nullable()();
  TextColumn get progressStatus => text().withDefault(const Constant(''))();
  TextColumn get barriers => text().withDefault(const Constant(''))();
  TextColumn get interventionsUsed => text().withDefault(const Constant(''))();
  TextColumn get nextSteps => text().withDefault(const Constant(''))();
  TextColumn get recordedBy => text().withDefault(const Constant(''))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// TreatmentInterventions - Interventions used (replaces interventionsUsed JSON)
class TreatmentInterventions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get treatmentSessionId => integer().nullable().references(TreatmentSessions, #id)();
  IntColumn get treatmentGoalId => integer().nullable().references(TreatmentGoals, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get interventionName => text()();
  TextColumn get interventionType => text().withDefault(const Constant('therapeutic'))();
  TextColumn get modality => text().withDefault(const Constant(''))();
  TextColumn get effectiveness => text().withDefault(const Constant(''))();
  IntColumn get effectivenessRating => integer().nullable()();
  TextColumn get patientResponse => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get usedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ClaimBillingCodes - Billing codes for insurance claims (replaces JSON)
class ClaimBillingCodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get claimId => integer().references(InsuranceClaims, #id)();
  
  TextColumn get codeType => text()();
  TextColumn get code => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get chargedAmount => real().nullable()();
  IntColumn get units => integer().withDefault(const Constant(1))();
  TextColumn get placeOfService => text().withDefault(const Constant(''))();
  IntColumn get linkedProcedureId => integer().nullable()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// PatientAllergies - Normalized allergies (replaces comma-separated text)
class PatientAllergies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get allergen => text()();
  TextColumn get allergenType => text().withDefault(const Constant('medication'))();
  TextColumn get allergenCode => text().withDefault(const Constant(''))();
  TextColumn get reactionType => text().withDefault(const Constant(''))();
  TextColumn get reactionSeverity => text().withDefault(const Constant('moderate'))();
  TextColumn get reactionDescription => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get recordedDate => dateTime()();
  TextColumn get source => text().withDefault(const Constant('patient'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// PatientChronicConditions - Normalized chronic conditions (replaces comma-separated text)
class PatientChronicConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get diagnosisId => integer().nullable().references(Diagnoses, #id)();
  
  TextColumn get conditionName => text()();
  TextColumn get icdCode => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('medical'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get severity => text().withDefault(const Constant('moderate'))();
  DateTimeColumn get onsetDate => dateTime().nullable()();
  DateTimeColumn get diagnosedDate => dateTime().nullable()();
  TextColumn get currentTreatment => text().withDefault(const Constant(''))();
  TextColumn get managingProvider => text().withDefault(const Constant(''))();
  DateTimeColumn get lastReviewDate => dateTime().nullable()();
  DateTimeColumn get nextReviewDate => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// MedicalRecordFields - Key-value pairs for dynamic form data (replaces dataJson)
/// This table stores structured data from various medical record types:
/// - pulmonary_evaluation: chief complaint, symptoms, chest auscultation, investigations
/// - imaging: imaging type, findings
/// - procedure: procedure name, notes
/// - follow_up: notes
/// For psychiatric_assessment, use MentalStatusExams table instead
/// For lab_result, use LabTestResults table instead
class MedicalRecordFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicalRecordId => integer().references(MedicalRecords, #id)();
  IntColumn get patientId => integer().references(Patients, #id)();
  
  TextColumn get fieldGroup => text().withDefault(const Constant(''))(); // 'vitals', 'chest_auscultation', 'symptoms', etc.
  TextColumn get fieldName => text()(); // 'chief_complaint', 'bp', 'breath_sounds', etc.
  TextColumn get fieldValue => text()(); // The actual value
  TextColumn get fieldType => text().withDefault(const Constant('text'))(); // 'text', 'number', 'list', 'boolean'
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// ClinicalCalculatorHistory - Save calculator results for reference
class ClinicalCalculatorHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().nullable().references(Patients, #id)();
  TextColumn get calculatorType => text()(); // 'bmi', 'gfr', 'chadsvasc', 'wells', 'pediatric_dose', etc.
  TextColumn get inputsJson => text()(); // JSON of input values
  TextColumn get resultJson => text()(); // JSON of calculated results
  TextColumn get interpretation => text().withDefault(const Constant(''))();
  DateTimeColumn get calculatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Model class for patient with insurance
class PatientWithInsurance {
  PatientWithInsurance({required this.patient, required this.insurances});
  final Patient patient;
  final List<InsuranceInfoData> insurances;
}

/// Model class for referral with patient info
class ReferralWithPatient {
  ReferralWithPatient({required this.referral, required this.patient});
  final Referral referral;
  final Patient patient;
}

/// Model class for lab order with patient info
class LabOrderWithPatient {
  LabOrderWithPatient({required this.labOrder, required this.patient});
  final LabOrder labOrder;
  final Patient patient;
}

@DriftDatabase(tables: [
  Patients, Appointments, Prescriptions, MedicalRecords, Invoices, 
  VitalSigns, TreatmentOutcomes, ScheduledFollowUps, TreatmentSessions, 
  MedicationResponses, TreatmentGoals, AuditLogs, 
  Encounters, Diagnoses, ClinicalNotes, EncounterDiagnoses,
  // V3: New comprehensive clinical tables
  Referrals, Immunizations, FamilyMedicalHistory, PatientConsents,
  InsuranceInfo, InsuranceClaims, PreAuthorizations, LabOrders,
  ProblemList, GrowthMeasurements, ClinicalReminders, 
  AppointmentWaitlist, RecurringAppointments, ClinicalLetters, CptCodes,
  // V4: Doctor productivity features
  FavoritePrescriptions, QuickPhrases, RecentPatients, ClinicalCalculatorHistory,
  // V5: Normalized tables - NO MORE JSON STORAGE
  PrescriptionMedications, InvoiceLineItems, FamilyConditions,
  TreatmentSymptoms, SideEffects, Attachments, MentalStatusExams,
  LabTestResults, ProgressNoteEntries, TreatmentInterventions,
  ClaimBillingCodes, PatientAllergies, PatientChronicConditions,
  MedicalRecordFields
])
class DoctorDatabase extends _$DoctorDatabase {
  /// Singleton instance
  static DoctorDatabase? _instance;
  
  /// Get the singleton instance of the database
  static DoctorDatabase get instance {
    _instance ??= DoctorDatabase._internal();
    return _instance!;
  }
  
  /// Private constructor for singleton
  DoctorDatabase._internal() : super(impl.openConnection());
  
  /// Factory constructor that returns the singleton
  factory DoctorDatabase() => instance;
  
  /// Constructor for testing with a custom executor.
  /// Use this with NativeDatabase.memory() for in-memory testing.
  DoctorDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new tables for clinical decision support
        await m.createTable(vitalSigns);
        await m.createTable(treatmentOutcomes);
        await m.createTable(scheduledFollowUps);
        
        // Add allergies column to patients table if not exists
        await m.addColumn(patients, patients.allergies);
      }
      if (from < 3) {
        // Add new tables for enhanced treatment tracking
        await m.createTable(treatmentSessions);
        await m.createTable(medicationResponses);
        await m.createTable(treatmentGoals);
        
        // Add new columns to treatment outcomes
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.providerType);
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.providerName);
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.diagnosis);
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.treatmentPhase);
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.lastReviewDate);
        await m.addColumn(treatmentOutcomes, treatmentOutcomes.nextReviewDate);
      }
      if (from < 4) {
        // Add relationship columns for data integrity
        // Appointments now link to medical records
        await m.addColumn(appointments, appointments.medicalRecordId);
        
        // Prescriptions now link to appointments and medical records with diagnosis context
        await m.addColumn(prescriptions, prescriptions.appointmentId);
        await m.addColumn(prescriptions, prescriptions.medicalRecordId);
        await m.addColumn(prescriptions, prescriptions.diagnosis);
        await m.addColumn(prescriptions, prescriptions.chiefComplaint);
        await m.addColumn(prescriptions, prescriptions.vitalsJson);
        
        // Invoices now link to appointments, prescriptions, and treatment sessions
        await m.addColumn(invoices, invoices.appointmentId);
        await m.addColumn(invoices, invoices.prescriptionId);
        await m.addColumn(invoices, invoices.treatmentSessionId);
      }
      if (from < 5) {
        // Add audit logging table for HIPAA compliance
        await m.createTable(auditLogs);
      }
      if (from < 6) {
        // Schema V2: Encounter-based clinical data model
        // Add new tables for unified workflow
        await m.createTable(encounters);
        await m.createTable(diagnoses);
        await m.createTable(clinicalNotes);
        await m.createTable(encounterDiagnoses);
        
        // Add encounterId to VitalSigns for linking vitals to encounters
        await m.addColumn(vitalSigns, vitalSigns.encounterId);
      }
      if (from < 7) {
        // Schema V2.1: Normalize data by linking more tables to Encounters
        // Add encounterId to Prescriptions, MedicalRecords, TreatmentSessions
        await m.addColumn(prescriptions, prescriptions.encounterId);
        await m.addColumn(prescriptions, prescriptions.primaryDiagnosisId);
        await m.addColumn(medicalRecords, medicalRecords.encounterId);
        await m.addColumn(treatmentSessions, treatmentSessions.encounterId);
        // Note: Old duplicate fields (diagnosis, chiefComplaint, vitalsJson) kept for compatibility
        // but marked @Deprecated - use Encounters/Diagnoses/VitalSigns tables instead
      }
      if (from < 8) {
        // Schema V3: Comprehensive clinical features
        await m.createTable(referrals);
        await m.createTable(immunizations);
        await m.createTable(familyMedicalHistory);
        await m.createTable(patientConsents);
        await m.createTable(insuranceInfo);
        await m.createTable(insuranceClaims);
        await m.createTable(preAuthorizations);
        await m.createTable(labOrders);
        await m.createTable(problemList);
        await m.createTable(growthMeasurements);
        await m.createTable(clinicalReminders);
        await m.createTable(appointmentWaitlist);
        await m.createTable(recurringAppointments);
        await m.createTable(clinicalLetters);
        await m.createTable(cptCodes);
      }
      if (from < 9) {
        // Schema V4: Doctor productivity features
        await m.createTable(favoritePrescriptions);
        await m.createTable(quickPhrases);
        await m.createTable(recentPatients);
        await m.createTable(clinicalCalculatorHistory);
      }
      if (from < 10) {
        // Schema V5: Fully normalized tables - NO MORE JSON STORAGE
        await m.createTable(prescriptionMedications);
        await m.createTable(invoiceLineItems);
        await m.createTable(familyConditions);
        await m.createTable(treatmentSymptoms);
        await m.createTable(sideEffects);
        await m.createTable(attachments);
        await m.createTable(mentalStatusExams);
        await m.createTable(labTestResults);
        await m.createTable(progressNoteEntries);
        await m.createTable(treatmentInterventions);
        await m.createTable(claimBillingCodes);
        await m.createTable(patientAllergies);
        await m.createTable(patientChronicConditions);
      }
      if (from < 11) {
        // Schema V6: MedicalRecordFields - normalize MedicalRecords.dataJson
        await m.createTable(medicalRecordFields);
      }
    },
  );

  // Patient CRUD
  Future<int> insertPatient(Insertable<Patient> p) => into(patients).insert(p);
  Future<List<Patient>> getAllPatients() => select(patients).get();
  Future<Patient?> getPatientById(int id) => (select(patients)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<bool> updatePatient(Insertable<Patient> p) => update(patients).replace(p);
  Future<int> deletePatient(int id) => (delete(patients)..where((t) => t.id.equals(id))).go();

  /// Get paginated patients with optional search and filter
  /// Returns a tuple of (patients, totalCount)
  Future<(List<Patient>, int)> getPatientsPaginated({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    int? riskLevel, // null = all, 1 = low, 2 = medium, 3 = high
  }) async {
    // Build query
    var query = select(patients);
    
    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = '%${searchQuery.toLowerCase()}%';
      query = query..where((p) =>
          p.firstName.lower().like(lowerQuery) |
          p.lastName.lower().like(lowerQuery) |
          p.phone.lower().like(lowerQuery));
    }
    
    if (riskLevel != null) {
      switch (riskLevel) {
        case 1: // Low Risk: 0-2
          query = query..where((p) => p.riskLevel.isSmallerOrEqualValue(2));
        case 2: // Medium Risk: 3-4
          query = query..where((p) => p.riskLevel.isBiggerThanValue(2) & p.riskLevel.isSmallerOrEqualValue(4));
        case 3: // High Risk: 5+
          query = query..where((p) => p.riskLevel.isBiggerThanValue(4));
      }
    }

    // Get total count (without limit/offset)
    final allMatchingPatients = await query.get();
    final totalCount = allMatchingPatients.length;

    // Apply pagination
    query = query
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
      ..limit(limit, offset: offset);

    final paginatedPatients = await query.get();
    
    return (paginatedPatients, totalCount);
  }
  
  /// Find potential duplicate patients by name or phone
  Future<List<Patient>> findPotentialDuplicates({
    required String firstName,
    required String lastName,
    String? phone,
    int? excludePatientId,
  }) async {
    final allPatients = await getAllPatients();
    final lowerFirst = firstName.toLowerCase().trim();
    final lowerLast = lastName.toLowerCase().trim();
    final cleanPhone = phone?.replaceAll(RegExp(r'[^\d]'), '');
    
    return allPatients.where((p) {
      // Exclude current patient when editing
      if (excludePatientId != null && p.id == excludePatientId) return false;
      
      // Check for name match
      final nameMatch = p.firstName.toLowerCase().trim() == lowerFirst &&
                        p.lastName.toLowerCase().trim() == lowerLast;
      
      // Check for phone match (if phone provided)
      bool phoneMatch = false;
      if (cleanPhone != null && cleanPhone.length >= 7) {
        final patientPhone = p.phone.replaceAll(RegExp(r'[^\d]'), '');
        phoneMatch = patientPhone.isNotEmpty && patientPhone == cleanPhone;
      }
      
      return nameMatch || phoneMatch;
    }).toList();
  }
  
  /// Quick patient lookup by phone number
  Future<Patient?> findPatientByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 7) return null;
    
    final allPatients = await getAllPatients();
    for (final p in allPatients) {
      final patientPhone = p.phone.replaceAll(RegExp(r'[^\d]'), '');
      if (patientPhone == cleanPhone) return p;
    }
    return null;
  }

  // Appointment CRUD
  Future<int> insertAppointment(Insertable<Appointment> a) => into(appointments).insert(a);
  Future<List<Appointment>> getAllAppointments() => select(appointments).get();
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(appointments)..where((a) => a.appointmentDateTime.isBetweenValues(start, end))).get();
  }
  Future<Appointment?> getAppointmentById(int id) =>
    (select(appointments)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<bool> updateAppointment(Insertable<Appointment> a) => update(appointments).replace(a);
  Future<int> deleteAppointment(int id) => (delete(appointments)..where((t) => t.id.equals(id))).go();
  
  /// Quick method to update appointment status
  Future<void> updateAppointmentStatus(int id, String status) async {
    final appt = await getAppointmentById(id);
    if (appt != null) {
      await updateAppointment(AppointmentsCompanion(
        id: Value(appt.id),
        patientId: Value(appt.patientId),
        appointmentDateTime: Value(appt.appointmentDateTime),
        durationMinutes: Value(appt.durationMinutes),
        reason: Value(appt.reason),
        status: Value(status),
        notes: Value(appt.notes),
        reminderAt: Value(appt.reminderAt),
        medicalRecordId: Value(appt.medicalRecordId),
      ));
    }
  }

  // Prescription CRUD
  Future<int> insertPrescription(Insertable<Prescription> p) => into(prescriptions).insert(p);
  Future<List<Prescription>> getAllPrescriptions() => select(prescriptions).get();
  Future<List<Prescription>> getPrescriptionsForPatient(int patientId) {
    return (select(prescriptions)..where((p) => p.patientId.equals(patientId))).get();
  }
  Future<Prescription?> getLastPrescriptionForPatient(int patientId) {
    return (select(prescriptions)
      ..where((p) => p.patientId.equals(patientId))
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
      ..limit(1))
      .getSingleOrNull();
  }
  Future<Prescription?> getPrescriptionById(int id) =>
    (select(prescriptions)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<bool> updatePrescription(Insertable<Prescription> p) => update(prescriptions).replace(p);
  Future<int> deletePrescription(int id) => (delete(prescriptions)..where((t) => t.id.equals(id))).go();

  // Medical Record CRUD
  Future<int> insertMedicalRecord(Insertable<MedicalRecord> r) => into(medicalRecords).insert(r);
  Future<List<MedicalRecord>> getAllMedicalRecords() => select(medicalRecords).get();
  Future<List<MedicalRecord>> getMedicalRecordsForPatient(int patientId) {
    return (select(medicalRecords)
      ..where((r) => r.patientId.equals(patientId))
      ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
      .get();
  }
  Future<MedicalRecord?> getMedicalRecordById(int id) => 
    (select(medicalRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<bool> updateMedicalRecord(Insertable<MedicalRecord> r) => update(medicalRecords).replace(r);
  Future<int> deleteMedicalRecord(int id) => (delete(medicalRecords)..where((t) => t.id.equals(id))).go();
  
  /// Get all medical records with associated patient info
  Future<List<MedicalRecordWithPatient>> getAllMedicalRecordsWithPatients() async {
    final allRecords = await getAllMedicalRecords();
    final List<MedicalRecordWithPatient> result = [];
    
    for (final record in allRecords) {
      final patient = await getPatientById(record.patientId);
      if (patient != null) {
        result.add(MedicalRecordWithPatient(record: record, patient: patient));
      }
    }
    
    return result;
  }

  // Invoice CRUD
  Future<int> insertInvoice(Insertable<Invoice> i) => into(invoices).insert(i);
  Future<List<Invoice>> getAllInvoices() {
    return (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)])).get();
  }
  Future<List<Invoice>> getInvoicesForPatient(int patientId) {
    return (select(invoices)
      ..where((i) => i.patientId.equals(patientId))
      ..orderBy([(i) => OrderingTerm.desc(i.invoiceDate)]))
      .get();
  }
  Future<Invoice?> getInvoiceById(int id) =>
    (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();
  Future<bool> updateInvoice(Insertable<Invoice> i) => update(invoices).replace(i);
  Future<int> deleteInvoice(int id) => (delete(invoices)..where((t) => t.id.equals(id))).go();
  
  // Get invoice statistics
  Future<Map<String, double>> getInvoiceStats() async {
    final allInvoices = await getAllInvoices();
    double totalRevenue = 0;
    double pending = 0;
    double paid = 0;
    int pendingCount = 0;
    
    for (final inv in allInvoices) {
      if (inv.paymentStatus == 'Paid') {
        paid += inv.grandTotal;
        totalRevenue += inv.grandTotal;
      } else {
        pending += inv.grandTotal;
        pendingCount++;
      }
    }
    
    return {
      'totalRevenue': totalRevenue,
      'pending': pending,
      'paid': paid,
      'pendingCount': pendingCount.toDouble(),
    };
  }

  // Vital Signs CRUD
  Future<int> insertVitalSigns(Insertable<VitalSign> v) => into(vitalSigns).insert(v);
  Future<List<VitalSign>> getAllVitalSigns() => select(vitalSigns).get();
  Future<List<VitalSign>> getVitalSignsForPatient(int patientId) {
    return (select(vitalSigns)
      ..where((v) => v.patientId.equals(patientId))
      ..orderBy([(v) => OrderingTerm.desc(v.recordedAt)]))
      .get();
  }
  Future<VitalSign?> getVitalSignById(int id) =>
    (select(vitalSigns)..where((v) => v.id.equals(id))).getSingleOrNull();
  Future<VitalSign?> getLatestVitalSignsForPatient(int patientId) {
    return (select(vitalSigns)
      ..where((v) => v.patientId.equals(patientId))
      ..orderBy([(v) => OrderingTerm.desc(v.recordedAt)])
      ..limit(1))
      .getSingleOrNull();
  }
  Future<bool> updateVitalSigns(Insertable<VitalSign> v) => update(vitalSigns).replace(v);
  Future<int> deleteVitalSigns(int id) => (delete(vitalSigns)..where((v) => v.id.equals(id))).go();

  // Treatment Outcome CRUD
  Future<int> insertTreatmentOutcome(Insertable<TreatmentOutcome> t) => into(treatmentOutcomes).insert(t);
  Future<List<TreatmentOutcome>> getAllTreatmentOutcomes() => select(treatmentOutcomes).get();
  Future<List<TreatmentOutcome>> getTreatmentOutcomesForPatient(int patientId) {
    return (select(treatmentOutcomes)
      ..where((t) => t.patientId.equals(patientId))
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
      .get();
  }
  Future<TreatmentOutcome?> getTreatmentOutcomeById(int id) =>
    (select(treatmentOutcomes)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<List<TreatmentOutcome>> getOngoingTreatmentsForPatient(int patientId) {
    return (select(treatmentOutcomes)
      ..where((t) => t.patientId.equals(patientId) & t.outcome.equals('ongoing')))
      .get();
  }
  Future<bool> updateTreatmentOutcome(Insertable<TreatmentOutcome> t) => update(treatmentOutcomes).replace(t);
  Future<int> deleteTreatmentOutcome(int id) => (delete(treatmentOutcomes)..where((t) => t.id.equals(id))).go();

  // Scheduled Follow-Up CRUD
  Future<int> insertScheduledFollowUp(Insertable<ScheduledFollowUp> f) => into(scheduledFollowUps).insert(f);
  Future<List<ScheduledFollowUp>> getAllScheduledFollowUps() => select(scheduledFollowUps).get();
  Future<List<ScheduledFollowUp>> getScheduledFollowUpsForPatient(int patientId) {
    return (select(scheduledFollowUps)
      ..where((f) => f.patientId.equals(patientId))
      ..orderBy([(f) => OrderingTerm.asc(f.scheduledDate)]))
      .get();
  }
  Future<ScheduledFollowUp?> getScheduledFollowUpById(int id) =>
    (select(scheduledFollowUps)..where((f) => f.id.equals(id))).getSingleOrNull();
  Future<List<ScheduledFollowUp>> getPendingFollowUps() {
    return (select(scheduledFollowUps)
      ..where((f) => f.status.equals('pending'))
      ..orderBy([(f) => OrderingTerm.asc(f.scheduledDate)]))
      .get();
  }
  Future<List<ScheduledFollowUp>> getOverdueFollowUps() {
    final now = DateTime.now();
    return (select(scheduledFollowUps)
      ..where((f) => f.status.equals('pending') & f.scheduledDate.isSmallerThanValue(now)))
      .get();
  }
  Future<bool> updateScheduledFollowUp(Insertable<ScheduledFollowUp> f) => update(scheduledFollowUps).replace(f);
  Future<int> deleteScheduledFollowUp(int id) => (delete(scheduledFollowUps)..where((f) => f.id.equals(id))).go();

  // Treatment Session CRUD
  Future<int> insertTreatmentSession(Insertable<TreatmentSession> s) => into(treatmentSessions).insert(s);
  Future<List<TreatmentSession>> getAllTreatmentSessions() => select(treatmentSessions).get();
  Future<List<TreatmentSession>> getTreatmentSessionsForPatient(int patientId) {
    return (select(treatmentSessions)
      ..where((s) => s.patientId.equals(patientId))
      ..orderBy([(s) => OrderingTerm.desc(s.sessionDate)]))
      .get();
  }
  Future<List<TreatmentSession>> getTreatmentSessionsForTreatment(int treatmentOutcomeId) {
    return (select(treatmentSessions)
      ..where((s) => s.treatmentOutcomeId.equals(treatmentOutcomeId))
      ..orderBy([(s) => OrderingTerm.desc(s.sessionDate)]))
      .get();
  }
  Future<List<TreatmentSession>> getSessionsByProvider(String providerType) {
    return (select(treatmentSessions)
      ..where((s) => s.providerType.equals(providerType))
      ..orderBy([(s) => OrderingTerm.desc(s.sessionDate)]))
      .get();
  }
  Future<TreatmentSession?> getTreatmentSessionById(int id) =>
    (select(treatmentSessions)..where((s) => s.id.equals(id))).getSingleOrNull();
  Future<bool> updateTreatmentSession(Insertable<TreatmentSession> s) => update(treatmentSessions).replace(s);
  Future<int> deleteTreatmentSession(int id) => (delete(treatmentSessions)..where((s) => s.id.equals(id))).go();

  // Medication Response CRUD
  Future<int> insertMedicationResponse(Insertable<MedicationResponse> m) => into(medicationResponses).insert(m);
  Future<List<MedicationResponse>> getAllMedicationResponses() => select(medicationResponses).get();
  Future<List<MedicationResponse>> getMedicationResponsesForPatient(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId))
      ..orderBy([(m) => OrderingTerm.desc(m.startDate)]))
      .get();
  }
  Future<List<MedicationResponse>> getActiveMedicationResponses(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId) & m.endDate.isNull())
      ..orderBy([(m) => OrderingTerm.desc(m.startDate)]))
      .get();
  }
  Future<List<MedicationResponse>> getMedicationsWithSideEffects(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId) & m.sideEffectSeverity.isNotIn(['none', ''])))
      .get();
  }
  Future<MedicationResponse?> getMedicationResponseById(int id) =>
    (select(medicationResponses)..where((m) => m.id.equals(id))).getSingleOrNull();
  Future<bool> updateMedicationResponse(Insertable<MedicationResponse> m) => update(medicationResponses).replace(m);
  Future<int> deleteMedicationResponse(int id) => (delete(medicationResponses)..where((m) => m.id.equals(id))).go();

  // Treatment Goal CRUD
  Future<int> insertTreatmentGoal(Insertable<TreatmentGoal> g) => into(treatmentGoals).insert(g);
  Future<List<TreatmentGoal>> getAllTreatmentGoals() => select(treatmentGoals).get();
  Future<List<TreatmentGoal>> getTreatmentGoalsForPatient(int patientId) {
    return (select(treatmentGoals)
      ..where((g) => g.patientId.equals(patientId))
      ..orderBy([(g) => OrderingTerm.asc(g.priority), (g) => OrderingTerm.desc(g.createdAt)]))
      .get();
  }
  Future<List<TreatmentGoal>> getActiveGoalsForPatient(int patientId) {
    return (select(treatmentGoals)
      ..where((g) => g.patientId.equals(patientId) & g.status.equals('active'))
      ..orderBy([(g) => OrderingTerm.asc(g.priority)]))
      .get();
  }
  Future<List<TreatmentGoal>> getGoalsForTreatment(int treatmentOutcomeId) {
    return (select(treatmentGoals)
      ..where((g) => g.treatmentOutcomeId.equals(treatmentOutcomeId))
      ..orderBy([(g) => OrderingTerm.asc(g.priority)]))
      .get();
  }
  Future<TreatmentGoal?> getTreatmentGoalById(int id) =>
    (select(treatmentGoals)..where((g) => g.id.equals(id))).getSingleOrNull();
  Future<bool> updateTreatmentGoal(Insertable<TreatmentGoal> g) => update(treatmentGoals).replace(g);
  Future<int> deleteTreatmentGoal(int id) => (delete(treatmentGoals)..where((g) => g.id.equals(id))).go();

  // Aggregate queries for treatment progress
  Future<Map<String, dynamic>> getTreatmentProgressSummary(int patientId) async {
    final sessions = await getTreatmentSessionsForPatient(patientId);
    final medications = await getActiveMedicationResponses(patientId);
    final goals = await getActiveGoalsForPatient(patientId);
    final outcomes = await getOngoingTreatmentsForPatient(patientId);
    
    int totalGoals = goals.length;
    int achievedGoals = goals.where((g) => g.status == 'achieved').length;
    double avgProgress = goals.isEmpty ? 0 : goals.map((g) => g.progressPercent).reduce((a, b) => a + b) / goals.length;
    
    int effectiveMeds = medications.where((m) => m.responseStatus == 'effective').length;
    int withSideEffects = medications.where((m) => m.sideEffectSeverity != 'none' && m.sideEffectSeverity.isNotEmpty).length;
    
    return {
      'totalSessions': sessions.length,
      'recentSessions': sessions.take(5).toList(),
      'activeMedications': medications.length,
      'effectiveMedications': effectiveMeds,
      'medicationsWithSideEffects': withSideEffects,
      'activeGoals': totalGoals,
      'achievedGoals': achievedGoals,
      'averageProgress': avgProgress,
      'ongoingTreatments': outcomes.length,
    };
  }

  // ============================================================================
  // PATIENT-CENTRIC COMPREHENSIVE QUERIES
  // All data revolves around the patient - these methods provide complete views
  // ============================================================================

  /// Get complete patient profile with all related data
  Future<Map<String, dynamic>> getCompletePatientProfile(int patientId) async {
    final patient = await getPatientById(patientId);
    if (patient == null) return {};

    final appointments = await getAppointmentsForPatient(patientId);
    final prescriptions = await getPrescriptionsForPatient(patientId);
    final medicalRecords = await getMedicalRecordsForPatient(patientId);
    final invoices = await getInvoicesForPatient(patientId);
    final vitals = await getVitalSignsForPatient(patientId);
    final latestVitals = await getLatestVitalSignsForPatient(patientId);
    final treatments = await getTreatmentOutcomesForPatient(patientId);
    final followUps = await getScheduledFollowUpsForPatient(patientId);
    final sessions = await getTreatmentSessionsForPatient(patientId);
    final medications = await getMedicationResponsesForPatient(patientId);
    final goals = await getTreatmentGoalsForPatient(patientId);

    // Calculate patient statistics
    final totalSpent = invoices.fold<double>(0, (sum, inv) => sum + inv.grandTotal);
    final paidAmount = invoices.where((i) => i.paymentStatus == 'Paid').fold<double>(0, (sum, inv) => sum + inv.grandTotal);
    final pendingAmount = totalSpent - paidAmount;

    final completedAppointments = appointments.where((a) => a.status == 'completed').length;
    final upcomingAppointments = appointments.where((a) => 
      a.status == 'scheduled' && a.appointmentDateTime.isAfter(DateTime.now())).toList();
    
    final activeMedications = medications.where((m) => m.endDate == null).toList();
    final activeGoals = goals.where((g) => g.status == 'active').toList();
    final pendingFollowUps = followUps.where((f) => f.status == 'pending').toList();

    return {
      'patient': patient,
      'appointments': {
        'all': appointments,
        'completed': completedAppointments,
        'upcoming': upcomingAppointments,
        'total': appointments.length,
      },
      'prescriptions': {
        'all': prescriptions,
        'total': prescriptions.length,
        'latest': prescriptions.isNotEmpty ? prescriptions.first : null,
      },
      'medicalRecords': {
        'all': medicalRecords,
        'total': medicalRecords.length,
        'byType': _groupRecordsByType(medicalRecords),
      },
      'billing': {
        'invoices': invoices,
        'totalSpent': totalSpent,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'invoiceCount': invoices.length,
      },
      'vitals': {
        'history': vitals,
        'latest': latestVitals,
        'total': vitals.length,
      },
      'treatments': {
        'outcomes': treatments,
        'ongoing': treatments.where((t) => t.outcome == 'ongoing').toList(),
        'completed': treatments.where((t) => t.outcome != 'ongoing').toList(),
      },
      'sessions': {
        'all': sessions,
        'total': sessions.length,
        'byProvider': _groupSessionsByProvider(sessions),
      },
      'medications': {
        'all': medications,
        'active': activeMedications,
        'withSideEffects': medications.where((m) => m.sideEffectSeverity != 'none').toList(),
      },
      'goals': {
        'all': goals,
        'active': activeGoals,
        'achieved': goals.where((g) => g.status == 'achieved').toList(),
        'averageProgress': activeGoals.isEmpty ? 0 : 
          activeGoals.map((g) => g.progressPercent).reduce((a, b) => a + b) / activeGoals.length,
      },
      'followUps': {
        'all': followUps,
        'pending': pendingFollowUps,
        'overdue': pendingFollowUps.where((f) => f.scheduledDate.isBefore(DateTime.now())).toList(),
      },
    };
  }

  /// Get patient's appointments with full details
  Future<List<Appointment>> getAppointmentsForPatient(int patientId) {
    return (select(appointments)
      ..where((a) => a.patientId.equals(patientId))
      ..orderBy([(a) => OrderingTerm.desc(a.appointmentDateTime)]))
      .get();
  }

  /// Get patient's upcoming appointments
  Future<List<Appointment>> getUpcomingAppointmentsForPatient(int patientId) {
    final now = DateTime.now();
    return (select(appointments)
      ..where((a) => a.patientId.equals(patientId) & 
        a.appointmentDateTime.isBiggerThanValue(now) &
        a.status.equals('scheduled'))
      ..orderBy([(a) => OrderingTerm.asc(a.appointmentDateTime)]))
      .get();
  }

  /// Get patient's next appointment
  Future<Appointment?> getNextAppointmentForPatient(int patientId) async {
    final upcoming = await getUpcomingAppointmentsForPatient(patientId);
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Get patient's last visit date
  Future<DateTime?> getLastVisitDateForPatient(int patientId) async {
    final result = await (select(appointments)
      ..where((a) => a.patientId.equals(patientId) & a.status.equals('completed'))
      ..orderBy([(a) => OrderingTerm.desc(a.appointmentDateTime)])
      ..limit(1))
      .getSingleOrNull();
    return result?.appointmentDateTime;
  }

  /// Get patient's active medications with responses
  Future<List<MedicationResponse>> getActivePatientMedications(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId) & m.endDate.isNull())
      ..orderBy([(m) => OrderingTerm.desc(m.startDate)]))
      .get();
  }

  /// Get patient's medication history
  Future<List<MedicationResponse>> getPatientMedicationHistory(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId))
      ..orderBy([(m) => OrderingTerm.desc(m.startDate)]))
      .get();
  }

  /// Get all side effects for a patient
  Future<List<MedicationResponse>> getPatientSideEffects(int patientId) {
    return (select(medicationResponses)
      ..where((m) => m.patientId.equals(patientId) & 
        m.sideEffects.length.isBiggerThanValue(0)))
      .get();
  }

  /// Get patient's treatment timeline (all events chronologically)
  Future<List<Map<String, dynamic>>> getPatientTimeline(int patientId) async {
    final List<Map<String, dynamic>> timeline = [];

    // Add appointments
    final appointments = await getAppointmentsForPatient(patientId);
    for (final apt in appointments) {
      timeline.add({
        'type': 'appointment',
        'date': apt.appointmentDateTime,
        'title': apt.reason.isNotEmpty ? apt.reason : 'Appointment',
        'status': apt.status,
        'data': apt,
      });
    }

    // Add prescriptions
    final prescriptions = await getPrescriptionsForPatient(patientId);
    for (final rx in prescriptions) {
      timeline.add({
        'type': 'prescription',
        'date': rx.createdAt,
        'title': 'Prescription Created',
        'data': rx,
      });
    }

    // Add medical records
    final records = await getMedicalRecordsForPatient(patientId);
    for (final rec in records) {
      timeline.add({
        'type': 'record',
        'date': rec.recordDate,
        'title': rec.title,
        'recordType': rec.recordType,
        'data': rec,
      });
    }

    // Add sessions
    final sessions = await getTreatmentSessionsForPatient(patientId);
    for (final session in sessions) {
      timeline.add({
        'type': 'session',
        'date': session.sessionDate,
        'title': '${session.sessionType} session with ${session.providerType}',
        'data': session,
      });
    }

    // Add vital signs
    final vitals = await getVitalSignsForPatient(patientId);
    for (final vital in vitals) {
      timeline.add({
        'type': 'vitals',
        'date': vital.recordedAt,
        'title': 'Vital Signs Recorded',
        'data': vital,
      });
    }

    // Sort by date descending
    timeline.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return timeline;
  }

  /// Get patient's billing summary
  Future<Map<String, dynamic>> getPatientBillingSummary(int patientId) async {
    final invoices = await getInvoicesForPatient(patientId);
    
    double totalBilled = 0;
    double totalPaid = 0;
    double totalPending = 0;
    int paidCount = 0;
    int pendingCount = 0;

    for (final inv in invoices) {
      totalBilled += inv.grandTotal;
      if (inv.paymentStatus == 'Paid') {
        totalPaid += inv.grandTotal;
        paidCount++;
      } else {
        totalPending += inv.grandTotal;
        pendingCount++;
      }
    }

    return {
      'totalBilled': totalBilled,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
      'invoiceCount': invoices.length,
      'recentInvoices': invoices.take(5).toList(),
    };
  }

  /// Get patient's clinical summary for quick overview
  Future<Map<String, dynamic>> getPatientClinicalSummary(int patientId) async {
    final patient = await getPatientById(patientId);
    final latestVitals = await getLatestVitalSignsForPatient(patientId);
    final activeMeds = await getActivePatientMedications(patientId);
    final activeGoals = await getActiveGoalsForPatient(patientId);
    final ongoingTreatments = await getOngoingTreatmentsForPatient(patientId);
    final pendingFollowUps = await getPendingFollowUpsForPatient(patientId);
    final lastVisit = await getLastVisitDateForPatient(patientId);
    final nextAppointment = await getNextAppointmentForPatient(patientId);

    // Get recent records
    final recentRecords = await (select(medicalRecords)
      ..where((r) => r.patientId.equals(patientId))
      ..orderBy([(r) => OrderingTerm.desc(r.recordDate)])
      ..limit(3))
      .get();

    return {
      'patient': patient,
      'riskLevel': patient?.riskLevel ?? 0,
      'allergies': patient?.allergies ?? '',
      'latestVitals': latestVitals,
      'activeMedications': activeMeds,
      'activeMedicationCount': activeMeds.length,
      'activeGoals': activeGoals,
      'activeGoalCount': activeGoals.length,
      'ongoingTreatments': ongoingTreatments,
      'ongoingTreatmentCount': ongoingTreatments.length,
      'pendingFollowUps': pendingFollowUps,
      'pendingFollowUpCount': pendingFollowUps.length,
      'lastVisit': lastVisit,
      'nextAppointment': nextAppointment,
      'recentRecords': recentRecords,
    };
  }

  /// Get pending follow-ups for a specific patient
  Future<List<ScheduledFollowUp>> getPendingFollowUpsForPatient(int patientId) {
    return (select(scheduledFollowUps)
      ..where((f) => f.patientId.equals(patientId) & f.status.equals('pending'))
      ..orderBy([(f) => OrderingTerm.asc(f.scheduledDate)]))
      .get();
  }

  /// Search patients by name, phone, or email
  Future<List<Patient>> searchPatients(String query) {
    final searchTerm = '%$query%';
    return (select(patients)
      ..where((p) => 
        p.firstName.like(searchTerm) | 
        p.lastName.like(searchTerm) | 
        p.phone.like(searchTerm) |
        p.email.like(searchTerm) |
        p.tags.like(searchTerm)))
      .get();
  }

  /// Get patients by risk level
  Future<List<Patient>> getPatientsByRiskLevel(int riskLevel) {
    return (select(patients)
      ..where((p) => p.riskLevel.equals(riskLevel))
      ..orderBy([(p) => OrderingTerm.asc(p.lastName)]))
      .get();
  }

  /// Get high-risk patients
  Future<List<Patient>> getHighRiskPatients() {
    return (select(patients)
      ..where((p) => p.riskLevel.equals(2))
      ..orderBy([(p) => OrderingTerm.asc(p.lastName)]))
      .get();
  }

  /// Get patients with pending follow-ups
  Future<List<Patient>> getPatientsWithPendingFollowUps() async {
    final followUps = await getPendingFollowUps();
    final patientIds = followUps.map((f) => f.patientId).toSet();
    
    if (patientIds.isEmpty) return [];
    
    return (select(patients)
      ..where((p) => p.id.isIn(patientIds)))
      .get();
  }

  /// Get patients with overdue follow-ups
  Future<List<Patient>> getPatientsWithOverdueFollowUps() async {
    final overdueFollowUps = await getOverdueFollowUps();
    final patientIds = overdueFollowUps.map((f) => f.patientId).toSet();
    
    if (patientIds.isEmpty) return [];
    
    return (select(patients)
      ..where((p) => p.id.isIn(patientIds)))
      .get();
  }

  /// Get patients with appointments today
  Future<List<Patient>> getPatientsWithAppointmentsToday() async {
    final todayAppointments = await getAppointmentsForDay(DateTime.now());
    final patientIds = todayAppointments.map((a) => a.patientId).toSet();
    
    if (patientIds.isEmpty) return [];
    
    return (select(patients)
      ..where((p) => p.id.isIn(patientIds)))
      .get();
  }

  /// Get recently active patients (had activity in last N days)
  Future<List<Patient>> getRecentlyActivePatients({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    // Get patients with recent appointments
    final recentAppointments = await (select(appointments)
      ..where((a) => a.appointmentDateTime.isBiggerThanValue(cutoffDate)))
      .get();
    
    final patientIds = recentAppointments.map((a) => a.patientId).toSet();
    
    if (patientIds.isEmpty) return [];
    
    return (select(patients)
      ..where((p) => p.id.isIn(patientIds))
      ..orderBy([(p) => OrderingTerm.asc(p.lastName)]))
      .get();
  }

  /// Get patient count statistics
  Future<Map<String, int>> getPatientStatistics() async {
    final allPatients = await getAllPatients();
    final highRisk = allPatients.where((p) => p.riskLevel == 2).length;
    final mediumRisk = allPatients.where((p) => p.riskLevel == 1).length;
    final lowRisk = allPatients.where((p) => p.riskLevel == 0).length;
    
    final patientsToday = await getPatientsWithAppointmentsToday();
    final patientsWithOverdue = await getPatientsWithOverdueFollowUps();

    return {
      'total': allPatients.length,
      'highRisk': highRisk,
      'mediumRisk': mediumRisk,
      'lowRisk': lowRisk,
      'withAppointmentsToday': patientsToday.length,
      'withOverdueFollowUps': patientsWithOverdue.length,
    };
  }

  // Helper method to group records by type
  Map<String, List<MedicalRecord>> _groupRecordsByType(List<MedicalRecord> records) {
    final Map<String, List<MedicalRecord>> grouped = {};
    for (final record in records) {
      grouped.putIfAbsent(record.recordType, () => []);
      grouped[record.recordType]!.add(record);
    }
    return grouped;
  }

  // Helper method to group sessions by provider
  Map<String, List<TreatmentSession>> _groupSessionsByProvider(List<TreatmentSession> sessions) {
    final Map<String, List<TreatmentSession>> grouped = {};
    for (final session in sessions) {
      grouped.putIfAbsent(session.providerType, () => []);
      grouped[session.providerType]!.add(session);
    }
    return grouped;
  }

  // Audit Log CRUD
  Future<int> insertAuditLog(Insertable<AuditLog> log) => into(auditLogs).insert(log);

  Future<List<AuditLog>> getAllAuditLogs() => select(auditLogs).get();

  Future<List<AuditLog>> getAuditLogsForPatient(int patientId, {int limit = 100}) {
    return (select(auditLogs)
      ..where((log) => log.patientId.equals(patientId))
      ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<List<AuditLog>> getAuditLogsByDoctor(String doctorName, {int limit = 100}) {
    return (select(auditLogs)
      ..where((log) => log.doctorName.equals(doctorName))
      ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<List<AuditLog>> getAuditLogsByAction(String action, {int limit = 100}) {
    return (select(auditLogs)
      ..where((log) => log.action.equals(action))
      ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<List<AuditLog>> getRecentAuditLogs({int days = 7, int limit = 200}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return (select(auditLogs)
      ..where((log) => log.createdAt.isBiggerThanValue(cutoffDate))
      ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<List<AuditLog>> getFailedAccessAttempts({int limit = 100}) {
    return (select(auditLogs)
      ..where((log) => log.result.equals('DENIED') | log.result.equals('FAILURE'))
      ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
      ..limit(limit))
      .get();
  }

  Future<Map<String, int>> getAuditStatistics(DateTime startDate, DateTime endDate) async {
    final logs = await (select(auditLogs)
      ..where((log) => log.createdAt.isBetweenValues(startDate, endDate)))
      .get();

    return {
      'totalActions': logs.length,
      'logins': logs.where((l) => l.action == 'LOGIN').length,
      'logouts': logs.where((l) => l.action == 'LOGOUT').length,
      'dataAccess': logs.where((l) => l.action.contains('VIEW')).length,
      'dataModifications': logs.where((l) => l.action.contains('UPDATE') | l.action.contains('CREATE') | l.action.contains('DELETE')).length,
      'failedAttempts': logs.where((l) => l.result == 'DENIED' || l.result == 'FAILURE').length,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ENCOUNTER CRUD - Central hub for patient visits
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertEncounter(Insertable<Encounter> e) => into(encounters).insert(e);
  
  Future<List<Encounter>> getAllEncounters() => select(encounters).get();
  
  Future<Encounter?> getEncounterById(int id) => 
      (select(encounters)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<bool> updateEncounter(Insertable<Encounter> e) => update(encounters).replace(e);
  
  Future<int> deleteEncounter(int id) => 
      (delete(encounters)..where((t) => t.id.equals(id))).go();

  /// Get encounters for a specific patient
  Future<List<Encounter>> getEncountersForPatient(int patientId) {
    return (select(encounters)
      ..where((e) => e.patientId.equals(patientId))
      ..orderBy([(e) => OrderingTerm.desc(e.encounterDate)]))
      .get();
  }

  /// Get encounters by status (in_progress, completed, etc.)
  Future<List<Encounter>> getEncountersByStatus(String status) {
    return (select(encounters)
      ..where((e) => e.status.equals(status))
      ..orderBy([(e) => OrderingTerm.desc(e.encounterDate)]))
      .get();
  }

  /// Get today's encounters
  Future<List<Encounter>> getTodaysEncounters() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(encounters)
      ..where((e) => e.encounterDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(e) => OrderingTerm.asc(e.encounterDate)]))
      .get();
  }

  /// Get active/in-progress encounters
  Future<List<Encounter>> getActiveEncounters() {
    return (select(encounters)
      ..where((e) => e.status.equals('in_progress') | e.status.equals('checked_in'))
      ..orderBy([(e) => OrderingTerm.desc(e.encounterDate)]))
      .get();
  }

  /// Get encounter with all related data (joins)
  Future<Encounter?> getEncounterByAppointmentId(int appointmentId) {
    return (select(encounters)
      ..where((e) => e.appointmentId.equals(appointmentId)))
      .getSingleOrNull();
  }

  /// Start an encounter from an appointment
  Future<int> startEncounterFromAppointment(int appointmentId, int patientId, {String? chiefComplaint}) async {
    final now = DateTime.now();
    return into(encounters).insert(EncountersCompanion.insert(
      patientId: patientId,
      appointmentId: Value(appointmentId),
      encounterDate: now,
      encounterType: const Value('outpatient'),
      status: const Value('in_progress'),
      chiefComplaint: Value(chiefComplaint ?? ''),
      checkInTime: Value(now),
    ));
  }

  /// Complete an encounter
  Future<bool> completeEncounter(int encounterId) async {
    final encounter = await getEncounterById(encounterId);
    if (encounter == null) return false;
    
    return update(encounters).replace(
      EncountersCompanion(
        id: Value(encounterId),
        patientId: Value(encounter.patientId),
        appointmentId: Value(encounter.appointmentId),
        encounterDate: Value(encounter.encounterDate),
        encounterType: Value(encounter.encounterType),
        status: const Value('completed'),
        chiefComplaint: Value(encounter.chiefComplaint),
        providerName: Value(encounter.providerName),
        providerType: Value(encounter.providerType),
        isBillable: Value(encounter.isBillable),
        invoiceId: Value(encounter.invoiceId),
        checkInTime: Value(encounter.checkInTime),
        checkOutTime: Value(DateTime.now()),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // DIAGNOSIS CRUD - Normalized diagnosis tracking
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertDiagnosis(Insertable<Diagnose> d) => into(diagnoses).insert(d);
  
  Future<List<Diagnose>> getAllDiagnoses() => select(diagnoses).get();
  
  Future<Diagnose?> getDiagnosisById(int id) => 
      (select(diagnoses)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<bool> updateDiagnosis(Insertable<Diagnose> d) => update(diagnoses).replace(d);
  
  Future<int> deleteDiagnosis(int id) => 
      (delete(diagnoses)..where((t) => t.id.equals(id))).go();

  /// Get diagnoses for a specific patient
  Future<List<Diagnose>> getDiagnosesForPatient(int patientId) {
    return (select(diagnoses)
      ..where((d) => d.patientId.equals(patientId))
      ..orderBy([
        (d) => OrderingTerm.desc(d.isPrimary),
        (d) => OrderingTerm.asc(d.displayOrder),
      ]))
      .get();
  }

  /// Get active diagnoses for a patient
  Future<List<Diagnose>> getActiveDiagnosesForPatient(int patientId) {
    return (select(diagnoses)
      ..where((d) => d.patientId.equals(patientId) & d.diagnosisStatus.equals('active'))
      ..orderBy([
        (d) => OrderingTerm.desc(d.isPrimary),
        (d) => OrderingTerm.asc(d.displayOrder),
      ]))
      .get();
  }

  /// Get primary diagnosis for a patient
  Future<Diagnose?> getPrimaryDiagnosisForPatient(int patientId) {
    return (select(diagnoses)
      ..where((d) => d.patientId.equals(patientId) & d.isPrimary.equals(true) & d.diagnosisStatus.equals('active')))
      .getSingleOrNull();
  }

  /// Search diagnoses by ICD code or description
  Future<List<Diagnose>> searchDiagnoses(String query) {
    return (select(diagnoses)
      ..where((d) => d.icdCode.like('%$query%') | d.description.like('%$query%'))
      ..orderBy([(d) => OrderingTerm.asc(d.description)]))
      .get();
  }

  /// Get diagnoses by category
  Future<List<Diagnose>> getDiagnosesByCategory(int patientId, String category) {
    return (select(diagnoses)
      ..where((d) => d.patientId.equals(patientId) & d.category.equals(category)))
      .get();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // CLINICAL NOTES CRUD - SOAP notes and assessments
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertClinicalNote(Insertable<ClinicalNote> n) => into(clinicalNotes).insert(n);
  
  Future<List<ClinicalNote>> getAllClinicalNotes() => select(clinicalNotes).get();
  
  Future<ClinicalNote?> getClinicalNoteById(int id) => 
      (select(clinicalNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<bool> updateClinicalNote(Insertable<ClinicalNote> n) => update(clinicalNotes).replace(n);
  
  Future<int> deleteClinicalNote(int id) => 
      (delete(clinicalNotes)..where((t) => t.id.equals(id))).go();

  /// Get clinical notes for a specific encounter
  Future<List<ClinicalNote>> getClinicalNotesForEncounter(int encounterId) {
    return (select(clinicalNotes)
      ..where((n) => n.encounterId.equals(encounterId))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .get();
  }

  /// Get clinical notes for a specific patient
  Future<List<ClinicalNote>> getClinicalNotesForPatient(int patientId) {
    return (select(clinicalNotes)
      ..where((n) => n.patientId.equals(patientId))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .get();
  }

  /// Get clinical notes by type
  Future<List<ClinicalNote>> getClinicalNotesByType(int patientId, String noteType) {
    return (select(clinicalNotes)
      ..where((n) => n.patientId.equals(patientId) & n.noteType.equals(noteType))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .get();
  }

  /// Get unsigned clinical notes
  Future<List<ClinicalNote>> getUnsignedClinicalNotes() {
    return (select(clinicalNotes)
      ..where((n) => n.signedBy.equals(''))
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
      .get();
  }

  /// Sign a clinical note
  Future<bool> signClinicalNote(int noteId, String signedBy) async {
    final note = await getClinicalNoteById(noteId);
    if (note == null) return false;
    
    return update(clinicalNotes).replace(
      ClinicalNotesCompanion(
        id: Value(noteId),
        encounterId: Value(note.encounterId),
        patientId: Value(note.patientId),
        noteType: Value(note.noteType),
        subjective: Value(note.subjective),
        objective: Value(note.objective),
        assessment: Value(note.assessment),
        plan: Value(note.plan),
        mentalStatusExam: Value(note.mentalStatusExam),
        riskLevel: Value(note.riskLevel),
        riskFactors: Value(note.riskFactors),
        safetyPlan: Value(note.safetyPlan),
        signedBy: Value(signedBy),
        signedAt: Value(DateTime.now()),
        isLocked: const Value(true),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ENCOUNTER DIAGNOSES CRUD - Links encounters to diagnoses
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertEncounterDiagnosis(Insertable<EncounterDiagnose> ed) => 
      into(encounterDiagnoses).insert(ed);
  
  Future<List<EncounterDiagnose>> getAllEncounterDiagnoses() => 
      select(encounterDiagnoses).get();
  
  Future<EncounterDiagnose?> getEncounterDiagnosisById(int id) => 
      (select(encounterDiagnoses)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<bool> updateEncounterDiagnosis(Insertable<EncounterDiagnose> ed) => 
      update(encounterDiagnoses).replace(ed);
  
  Future<int> deleteEncounterDiagnosis(int id) => 
      (delete(encounterDiagnoses)..where((t) => t.id.equals(id))).go();

  /// Get diagnoses addressed in a specific encounter
  Future<List<EncounterDiagnose>> getDiagnosesForEncounter(int encounterId) {
    return (select(encounterDiagnoses)
      ..where((ed) => ed.encounterId.equals(encounterId)))
      .get();
  }

  /// Get encounters where a specific diagnosis was addressed
  Future<List<EncounterDiagnose>> getEncountersForDiagnosis(int diagnosisId) {
    return (select(encounterDiagnoses)
      ..where((ed) => ed.diagnosisId.equals(diagnosisId)))
      .get();
  }

  /// Link a diagnosis to an encounter
  Future<int> linkDiagnosisToEncounter(int encounterId, int diagnosisId, {bool isNew = false, String status = 'addressed'}) {
    return into(encounterDiagnoses).insert(EncounterDiagnosesCompanion.insert(
      encounterId: encounterId,
      diagnosisId: diagnosisId,
      isNewDiagnosis: Value(isNew),
      encounterStatus: Value(status),
    ));
  }

  /// Get all diagnoses with full details for an encounter
  Future<List<Diagnose>> getFullDiagnosesForEncounter(int encounterId) async {
    final links = await getDiagnosesForEncounter(encounterId);
    final diagnosisIds = links.map((l) => l.diagnosisId).toList();
    
    if (diagnosisIds.isEmpty) return [];
    
    return (select(diagnoses)
      ..where((d) => d.id.isIn(diagnosisIds)))
      .get();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // VITAL SIGNS - Updated to support encounter linking
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get vital signs for a specific encounter
  Future<List<VitalSign>> getVitalSignsForEncounter(int encounterId) {
    return (select(vitalSigns)
      ..where((v) => v.encounterId.equals(encounterId))
      ..orderBy([(v) => OrderingTerm.desc(v.recordedAt)]))
      .get();
  }

  /// Get latest vital signs for an encounter
  Future<VitalSign?> getLatestVitalSignsForEncounter(int encounterId) {
    return (select(vitalSigns)
      ..where((v) => v.encounterId.equals(encounterId))
      ..orderBy([(v) => OrderingTerm.desc(v.recordedAt)])
      ..limit(1))
      .getSingleOrNull();
  }

  /// Record vital signs for an encounter
  Future<int> recordVitalSignsForEncounter(int encounterId, int patientId, Insertable<VitalSign> vitals) async {
    // Create a companion with the encounter ID
    final companion = vitals as VitalSignsCompanion;
    return into(vitalSigns).insert(VitalSignsCompanion(
      patientId: companion.patientId,
      encounterId: Value(encounterId),
      recordedAt: companion.recordedAt,
      systolicBp: companion.systolicBp,
      diastolicBp: companion.diastolicBp,
      heartRate: companion.heartRate,
      temperature: companion.temperature,
      respiratoryRate: companion.respiratoryRate,
      oxygenSaturation: companion.oxygenSaturation,
      weight: companion.weight,
      height: companion.height,
      bmi: companion.bmi,
      painLevel: companion.painLevel,
      bloodGlucose: companion.bloodGlucose,
      notes: companion.notes,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // FAVORITE PRESCRIPTIONS - Quick prescription templates
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertFavoritePrescription(Insertable<FavoritePrescription> fp) =>
      into(favoritePrescriptions).insert(fp);

  Future<List<FavoritePrescription>> getAllFavoritePrescriptions() =>
      (select(favoritePrescriptions)
        ..where((f) => f.isActive.equals(true))
        ..orderBy([
          (f) => OrderingTerm.desc(f.usageCount),
          (f) => OrderingTerm.desc(f.lastUsedAt),
        ]))
      .get();

  Future<List<FavoritePrescription>> getFavoritePrescriptionsByCategory(String category) =>
      (select(favoritePrescriptions)
        ..where((f) => f.isActive.equals(true) & f.category.equals(category))
        ..orderBy([(f) => OrderingTerm.desc(f.usageCount)]))
      .get();

  Future<FavoritePrescription?> getFavoritePrescriptionById(int id) =>
      (select(favoritePrescriptions)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<bool> updateFavoritePrescription(Insertable<FavoritePrescription> fp) =>
      update(favoritePrescriptions).replace(fp);

  Future<void> incrementFavoritePrescriptionUsage(int id) async {
    final fp = await getFavoritePrescriptionById(id);
    if (fp != null) {
      await (update(favoritePrescriptions)..where((f) => f.id.equals(id)))
          .write(FavoritePrescriptionsCompanion(
            usageCount: Value(fp.usageCount + 1),
            lastUsedAt: Value(DateTime.now()),
          ));
    }
  }

  Future<int> deleteFavoritePrescription(int id) =>
      (update(favoritePrescriptions)..where((f) => f.id.equals(id)))
          .write(const FavoritePrescriptionsCompanion(isActive: Value(false)));

  // ═══════════════════════════════════════════════════════════════════════════════
  // QUICK PHRASES - Text expansion for clinical notes
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> insertQuickPhrase(Insertable<QuickPhrase> qp) =>
      into(quickPhrases).insert(qp);

  Future<List<QuickPhrase>> getAllQuickPhrases() =>
      (select(quickPhrases)
        ..where((q) => q.isActive.equals(true))
        ..orderBy([(q) => OrderingTerm.desc(q.usageCount)]))
      .get();

  Future<List<QuickPhrase>> getQuickPhrasesByCategory(String category) =>
      (select(quickPhrases)
        ..where((q) => q.isActive.equals(true) & q.category.equals(category))
        ..orderBy([(q) => OrderingTerm.desc(q.usageCount)]))
      .get();

  Future<QuickPhrase?> getQuickPhraseByShortcut(String shortcut) =>
      (select(quickPhrases)
        ..where((q) => q.isActive.equals(true) & q.shortcut.equals(shortcut)))
      .getSingleOrNull();

  Future<QuickPhrase?> getQuickPhraseById(int id) =>
      (select(quickPhrases)..where((q) => q.id.equals(id))).getSingleOrNull();

  Future<bool> updateQuickPhrase(Insertable<QuickPhrase> qp) =>
      update(quickPhrases).replace(qp);

  Future<void> incrementQuickPhraseUsage(int id) async {
    final qp = await getQuickPhraseById(id);
    if (qp != null) {
      await (update(quickPhrases)..where((q) => q.id.equals(id)))
          .write(QuickPhrasesCompanion(
            usageCount: Value(qp.usageCount + 1),
          ));
    }
  }

  Future<int> deleteQuickPhrase(int id) =>
      (update(quickPhrases)..where((q) => q.id.equals(id)))
          .write(const QuickPhrasesCompanion(isActive: Value(false)));

  // ═══════════════════════════════════════════════════════════════════════════════
  // RECENT PATIENTS - Track recently accessed patients
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> trackRecentPatient(int patientId, {String accessType = 'view'}) async {
    // Remove old entry for this patient if exists
    await (delete(recentPatients)..where((r) => r.patientId.equals(patientId))).go();
    
    // Add new entry
    await into(recentPatients).insert(RecentPatientsCompanion.insert(
      patientId: patientId,
      accessedAt: DateTime.now(),
      accessType: Value(accessType),
    ));
    
    // Keep only last 20 recent patients
    final all = await (select(recentPatients)
      ..orderBy([(r) => OrderingTerm.desc(r.accessedAt)]))
      .get();
    
    if (all.length > 20) {
      final toDelete = all.skip(20).map((r) => r.id).toList();
      await (delete(recentPatients)..where((r) => r.id.isIn(toDelete))).go();
    }
  }

  Future<List<Patient>> getRecentPatients({int limit = 10}) async {
    final recent = await (select(recentPatients)
      ..orderBy([(r) => OrderingTerm.desc(r.accessedAt)])
      ..limit(limit))
      .get();
    
    if (recent.isEmpty) return [];
    
    final patientIds = recent.map((r) => r.patientId).toList();
    return (select(patients)..where((p) => p.id.isIn(patientIds))).get();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // CLINICAL CALCULATOR HISTORY - Save calculator results
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<int> saveCalculatorResult(Insertable<ClinicalCalculatorHistoryData> calc) =>
      into(clinicalCalculatorHistory).insert(calc);

  Future<List<ClinicalCalculatorHistoryData>> getCalculatorHistoryForPatient(int patientId) =>
      (select(clinicalCalculatorHistory)
        ..where((c) => c.patientId.equals(patientId))
        ..orderBy([(c) => OrderingTerm.desc(c.calculatedAt)])
        ..limit(50))
      .get();

  Future<List<ClinicalCalculatorHistoryData>> getRecentCalculations({int limit = 20}) =>
      (select(clinicalCalculatorHistory)
        ..orderBy([(c) => OrderingTerm.desc(c.calculatedAt)])
        ..limit(limit))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // TODAY'S PATIENTS - Quick access to today's schedule
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<List<Patient>> getTodaysPatients() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayAppointments = await (select(appointments)
      ..where((a) => 
        a.appointmentDateTime.isBiggerOrEqualValue(startOfDay) &
        a.appointmentDateTime.isSmallerThanValue(endOfDay) &
        a.status.isNotIn(['cancelled', 'no_show'])
      )
      ..orderBy([(a) => OrderingTerm.asc(a.appointmentDateTime)]))
      .get();
    
    if (todayAppointments.isEmpty) return [];
    
    final patientIds = todayAppointments.map((a) => a.patientId).toSet().toList();
    return (select(patients)..where((p) => p.id.isIn(patientIds))).get();
  }

  Future<List<Map<String, dynamic>>> getTodaysScheduleWithPatients() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todayAppointments = await (select(appointments)
      ..where((a) => 
        a.appointmentDateTime.isBiggerOrEqualValue(startOfDay) &
        a.appointmentDateTime.isSmallerThanValue(endOfDay) &
        a.status.isNotIn(['cancelled', 'no_show'])
      )
      ..orderBy([(a) => OrderingTerm.asc(a.appointmentDateTime)]))
      .get();
    
    final result = <Map<String, dynamic>>[];
    for (final appt in todayAppointments) {
      final patient = await getPatientById(appt.patientId);
      if (patient != null) {
        result.add({
          'appointment': appt,
          'patient': patient,
        });
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: PRESCRIPTION MEDICATIONS - Normalized medication storage
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a medication for a prescription
  Future<int> insertPrescriptionMedication(Insertable<PrescriptionMedication> med) =>
      into(prescriptionMedications).insert(med);

  /// Get all medications for a prescription
  Future<List<PrescriptionMedication>> getMedicationsForPrescription(int prescriptionId) =>
      (select(prescriptionMedications)
        ..where((m) => m.prescriptionId.equals(prescriptionId))
        ..orderBy([(m) => OrderingTerm.asc(m.displayOrder)]))
      .get();

  /// Get all active medications for a patient
  Future<List<PrescriptionMedication>> getActiveMedicationsForPatient(int patientId) =>
      (select(prescriptionMedications)
        ..where((m) => m.patientId.equals(patientId) & m.status.equals('active'))
        ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
      .get();

  /// Get medication by ID
  Future<PrescriptionMedication?> getPrescriptionMedicationById(int id) =>
      (select(prescriptionMedications)..where((m) => m.id.equals(id))).getSingleOrNull();

  /// Update a medication
  Future<bool> updatePrescriptionMedication(Insertable<PrescriptionMedication> med) =>
      update(prescriptionMedications).replace(med);

  /// Delete medications for a prescription
  Future<int> deleteMedicationsForPrescription(int prescriptionId) =>
      (delete(prescriptionMedications)..where((m) => m.prescriptionId.equals(prescriptionId))).go();

  /// Find patients on a specific medication
  Future<List<int>> findPatientsOnMedication(String medicationName) async {
    final meds = await (select(prescriptionMedications)
      ..where((m) => m.medicationName.like('%$medicationName%') & m.status.equals('active')))
      .get();
    return meds.map((m) => m.patientId).toSet().toList();
  }

  /// V5: Get medications for a prescription with backwards compatibility
  /// First tries to get from normalized PrescriptionMedications table,
  /// falls back to parsing itemsJson for old records
  Future<List<Map<String, dynamic>>> getMedicationsForPrescriptionCompat(int prescriptionId) async {
    // First try normalized table (V5)
    final normalizedMeds = await getMedicationsForPrescription(prescriptionId);
    if (normalizedMeds.isNotEmpty) {
      return normalizedMeds.map((m) => {
        'name': m.medicationName,
        'dosage': m.strength,
        'frequency': m.frequency,
        'duration': m.durationText,
        'timing': m.timing,
        'instructions': m.specialInstructions,
      }).toList();
    }
    
    // Fallback to itemsJson for old records
    final prescription = await getPrescriptionById(prescriptionId);
    if (prescription == null) return [];
    
    try {
      final parsed = jsonDecode(prescription.itemsJson);
      if (parsed is List) {
        return parsed.cast<Map<String, dynamic>>();
      } else if (parsed is Map<String, dynamic>) {
        return ((parsed['medications'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: INVOICE LINE ITEMS - Normalized invoice items
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert an invoice line item
  Future<int> insertInvoiceLineItem(Insertable<InvoiceLineItem> item) =>
      into(invoiceLineItems).insert(item);

  /// Get all line items for an invoice
  Future<List<InvoiceLineItem>> getLineItemsForInvoice(int invoiceId) =>
      (select(invoiceLineItems)
        ..where((i) => i.invoiceId.equals(invoiceId))
        ..orderBy([(i) => OrderingTerm.asc(i.displayOrder)]))
      .get();

  /// Delete line items for an invoice
  Future<int> deleteLineItemsForInvoice(int invoiceId) =>
      (delete(invoiceLineItems)..where((i) => i.invoiceId.equals(invoiceId))).go();

  /// V5: Get line items for an invoice with backwards compatibility
  /// First tries normalized InvoiceLineItems table, falls back to itemsJson
  Future<List<Map<String, dynamic>>> getLineItemsForInvoiceCompat(int invoiceId) async {
    // First try normalized table (V5)
    final normalizedItems = await getLineItemsForInvoice(invoiceId);
    if (normalizedItems.isNotEmpty) {
      return normalizedItems.map((item) => {
        'description': item.description,
        'type': item.itemType,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'total': item.totalAmount,
        'cptCode': item.cptCode,
        'notes': item.notes,
      }).toList();
    }
    
    // Fallback to itemsJson for old records
    final invoice = await getInvoiceById(invoiceId);
    if (invoice == null) return [];
    
    try {
      final items = jsonDecode(invoice.itemsJson) as List<dynamic>;
      return items.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: PATIENT ALLERGIES - Normalized allergy storage
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a patient allergy
  Future<int> insertPatientAllergy(Insertable<PatientAllergy> allergy) =>
      into(patientAllergies).insert(allergy);

  /// Get all allergies for a patient
  Future<List<PatientAllergy>> getAllergiesForPatient(int patientId) =>
      (select(patientAllergies)
        ..where((a) => a.patientId.equals(patientId) & a.status.equals('active'))
        ..orderBy([(a) => OrderingTerm.asc(a.allergen)]))
      .get();

  /// Check if patient has a specific allergy
  Future<bool> patientHasAllergy(int patientId, String allergen) async {
    final allergy = await (select(patientAllergies)
      ..where((a) => a.patientId.equals(patientId) & 
          a.allergen.lower().like('%${allergen.toLowerCase()}%') &
          a.status.equals('active')))
      .getSingleOrNull();
    return allergy != null;
  }

  /// Update a patient allergy
  Future<bool> updatePatientAllergy(Insertable<PatientAllergy> allergy) =>
      update(patientAllergies).replace(allergy);

  /// Delete a patient allergy
  Future<int> deletePatientAllergy(int id) =>
      (delete(patientAllergies)..where((a) => a.id.equals(id))).go();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: PATIENT CHRONIC CONDITIONS - Normalized condition storage
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a patient chronic condition
  Future<int> insertPatientChronicCondition(Insertable<PatientChronicCondition> condition) =>
      into(patientChronicConditions).insert(condition);

  /// Get all chronic conditions for a patient
  Future<List<PatientChronicCondition>> getChronicConditionsForPatient(int patientId) =>
      (select(patientChronicConditions)
        ..where((c) => c.patientId.equals(patientId) & c.status.isIn(['active', 'chronic']))
        ..orderBy([(c) => OrderingTerm.asc(c.conditionName)]))
      .get();

  /// Update a chronic condition
  Future<bool> updatePatientChronicCondition(Insertable<PatientChronicCondition> condition) =>
      update(patientChronicConditions).replace(condition);

  /// Delete a chronic condition
  Future<int> deletePatientChronicCondition(int id) =>
      (delete(patientChronicConditions)..where((c) => c.id.equals(id))).go();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: SIDE EFFECTS - Normalized side effect tracking
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a side effect
  Future<int> insertSideEffect(Insertable<SideEffect> effect) =>
      into(sideEffects).insert(effect);

  /// Get side effects for a patient
  Future<List<SideEffect>> getSideEffectsForPatient(int patientId) =>
      (select(sideEffects)
        ..where((s) => s.patientId.equals(patientId))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
      .get();

  /// Get side effects for a medication
  Future<List<SideEffect>> getSideEffectsForMedication(int medicationId) =>
      (select(sideEffects)
        ..where((s) => s.prescriptionMedicationId.equals(medicationId)))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: LAB TEST RESULTS - Normalized lab results
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a lab test result
  Future<int> insertLabTestResult(Insertable<LabTestResult> result) =>
      into(labTestResults).insert(result);

  /// Get test results for a lab order
  Future<List<LabTestResult>> getResultsForLabOrder(int labOrderId) =>
      (select(labTestResults)
        ..where((r) => r.labOrderId.equals(labOrderId))
        ..orderBy([(r) => OrderingTerm.asc(r.displayOrder)]))
      .get();

  /// Get all lab results for a patient
  Future<List<LabTestResult>> getLabResultsForPatient(int patientId) =>
      (select(labTestResults)
        ..where((r) => r.patientId.equals(patientId))
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .get();

  /// Get abnormal lab results for a patient
  Future<List<LabTestResult>> getAbnormalLabResultsForPatient(int patientId) =>
      (select(labTestResults)
        ..where((r) => r.patientId.equals(patientId) & r.isAbnormal.equals(true))
        ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: MENTAL STATUS EXAMS - Normalized MSE storage
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a mental status exam
  Future<int> insertMentalStatusExam(Insertable<MentalStatusExam> mse) =>
      into(mentalStatusExams).insert(mse);

  /// Get MSEs for a patient
  Future<List<MentalStatusExam>> getMentalStatusExamsForPatient(int patientId) =>
      (select(mentalStatusExams)
        ..where((m) => m.patientId.equals(patientId))
        ..orderBy([(m) => OrderingTerm.desc(m.examinedAt)]))
      .get();

  /// Get MSE for an encounter
  Future<MentalStatusExam?> getMentalStatusExamForEncounter(int encounterId) =>
      (select(mentalStatusExams)..where((m) => m.encounterId.equals(encounterId)))
      .getSingleOrNull();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: ATTACHMENTS - Centralized file management
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert an attachment
  Future<int> insertAttachment(Insertable<Attachment> attachment) =>
      into(attachments).insert(attachment);

  /// Get attachments for an entity
  Future<List<Attachment>> getAttachmentsForEntity(String entityType, int entityId) =>
      (select(attachments)
        ..where((a) => a.entityType.equals(entityType) & a.entityId.equals(entityId))
        ..orderBy([(a) => OrderingTerm.asc(a.displayOrder)]))
      .get();

  /// Get all attachments for a patient
  Future<List<Attachment>> getAttachmentsForPatient(int patientId) =>
      (select(attachments)
        ..where((a) => a.patientId.equals(patientId))
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
      .get();

  /// Delete an attachment
  Future<int> deleteAttachment(int id) =>
      (delete(attachments)..where((a) => a.id.equals(id))).go();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: FAMILY CONDITIONS - Normalized family history
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a family condition
  Future<int> insertFamilyCondition(Insertable<FamilyCondition> condition) =>
      into(familyConditions).insert(condition);

  /// Get conditions for a family history record
  Future<List<FamilyCondition>> getConditionsForFamilyHistory(int familyHistoryId) =>
      (select(familyConditions)
        ..where((c) => c.familyHistoryId.equals(familyHistoryId)))
      .get();

  /// Get all family conditions for a patient
  Future<List<FamilyCondition>> getFamilyConditionsForPatient(int patientId) =>
      (select(familyConditions)
        ..where((c) => c.patientId.equals(patientId)))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: TREATMENT INTERVENTIONS - Normalized intervention tracking
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a treatment intervention
  Future<int> insertTreatmentIntervention(Insertable<TreatmentIntervention> intervention) =>
      into(treatmentInterventions).insert(intervention);

  /// Get interventions for a treatment session
  Future<List<TreatmentIntervention>> getInterventionsForSession(int sessionId) =>
      (select(treatmentInterventions)
        ..where((i) => i.treatmentSessionId.equals(sessionId)))
      .get();

  /// Get interventions for a patient
  Future<List<TreatmentIntervention>> getInterventionsForPatient(int patientId) =>
      (select(treatmentInterventions)
        ..where((i) => i.patientId.equals(patientId))
        ..orderBy([(i) => OrderingTerm.desc(i.usedAt)]))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: PROGRESS NOTE ENTRIES - Normalized progress tracking
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a progress note entry
  Future<int> insertProgressNoteEntry(Insertable<ProgressNoteEntry> entry) =>
      into(progressNoteEntries).insert(entry);

  /// Get progress entries for a treatment goal
  Future<List<ProgressNoteEntry>> getProgressEntriesForGoal(int goalId) =>
      (select(progressNoteEntries)
        ..where((p) => p.treatmentGoalId.equals(goalId))
        ..orderBy([(p) => OrderingTerm.desc(p.entryDate)]))
      .get();

  /// Get recent progress entries for a patient
  Future<List<ProgressNoteEntry>> getRecentProgressEntriesForPatient(int patientId, {int limit = 20}) =>
      (select(progressNoteEntries)
        ..where((p) => p.patientId.equals(patientId))
        ..orderBy([(p) => OrderingTerm.desc(p.entryDate)])
        ..limit(limit))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: TREATMENT SYMPTOMS - Normalized symptom tracking
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a treatment symptom
  Future<int> insertTreatmentSymptom(Insertable<TreatmentSymptom> symptom) =>
      into(treatmentSymptoms).insert(symptom);

  /// Get symptoms for a patient
  Future<List<TreatmentSymptom>> getSymptomsForPatient(int patientId) =>
      (select(treatmentSymptoms)
        ..where((s) => s.patientId.equals(patientId))
        ..orderBy([(s) => OrderingTerm.desc(s.recordedAt)]))
      .get();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V5: CLAIM BILLING CODES - Normalized billing
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a claim billing code
  Future<int> insertClaimBillingCode(Insertable<ClaimBillingCode> code) =>
      into(claimBillingCodes).insert(code);

  /// Get billing codes for a claim
  Future<List<ClaimBillingCode>> getBillingCodesForClaim(int claimId) =>
      (select(claimBillingCodes)
        ..where((c) => c.claimId.equals(claimId))
        ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
      .get();

  /// Delete billing codes for a claim
  Future<int> deleteBillingCodesForClaim(int claimId) =>
      (delete(claimBillingCodes)..where((c) => c.claimId.equals(claimId))).go();

  // ═══════════════════════════════════════════════════════════════════════════════
  // V6: MEDICAL RECORD FIELDS - Normalized form data (replaces dataJson)
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Insert a medical record field
  Future<int> insertMedicalRecordField(Insertable<MedicalRecordField> field) =>
      into(medicalRecordFields).insert(field);

  /// Insert multiple fields for a medical record
  Future<void> insertMedicalRecordFieldsBatch(int recordId, int patientId, Map<String, dynamic> data) async {
    int order = 0;
    
    void insertField(String group, String name, dynamic value, String type) async {
      if (value == null) return;
      String stringValue;
      if (value is List) {
        stringValue = jsonEncode(value);
        type = 'list';
      } else if (value is Map) {
        stringValue = jsonEncode(value);
        type = 'object';
      } else if (value is bool) {
        stringValue = value.toString();
        type = 'boolean';
      } else if (value is num) {
        stringValue = value.toString();
        type = 'number';
      } else {
        stringValue = value.toString();
      }
      
      await into(medicalRecordFields).insert(MedicalRecordFieldsCompanion.insert(
        medicalRecordId: recordId,
        patientId: patientId,
        fieldGroup: Value(group),
        fieldName: name,
        fieldValue: stringValue,
        fieldType: Value(type),
        displayOrder: Value(order++),
      ));
    }
    
    // Flatten nested data structure
    for (final entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        // Nested group (e.g., 'vitals', 'chest_auscultation', 'mse')
        for (final nested in (entry.value as Map<String, dynamic>).entries) {
          insertField(entry.key, nested.key, nested.value, 'text');
        }
      } else {
        insertField('', entry.key, entry.value, 'text');
      }
    }
  }

  /// Get all fields for a medical record
  Future<List<MedicalRecordField>> getFieldsForMedicalRecord(int recordId) =>
      (select(medicalRecordFields)
        ..where((f) => f.medicalRecordId.equals(recordId))
        ..orderBy([(f) => OrderingTerm.asc(f.displayOrder)]))
      .get();

  /// Get fields by group for a medical record
  Future<List<MedicalRecordField>> getFieldsByGroupForMedicalRecord(int recordId, String group) =>
      (select(medicalRecordFields)
        ..where((f) => f.medicalRecordId.equals(recordId) & f.fieldGroup.equals(group))
        ..orderBy([(f) => OrderingTerm.asc(f.displayOrder)]))
      .get();

  /// Delete all fields for a medical record
  Future<int> deleteFieldsForMedicalRecord(int recordId) =>
      (delete(medicalRecordFields)..where((f) => f.medicalRecordId.equals(recordId))).go();

  /// V6: Get medical record fields with backwards compatibility
  /// First tries normalized MedicalRecordFields table, falls back to dataJson
  Future<Map<String, dynamic>> getMedicalRecordFieldsCompat(int recordId) async {
    // First try normalized table (V6)
    final normalizedFields = await getFieldsForMedicalRecord(recordId);
    if (normalizedFields.isNotEmpty) {
      final result = <String, dynamic>{};
      final groups = <String, Map<String, dynamic>>{};
      
      for (final field in normalizedFields) {
        dynamic value = field.fieldValue;
        // Parse value based on type
        if (field.fieldType == 'list' || field.fieldType == 'object') {
          try { value = jsonDecode(field.fieldValue); } catch (_) {}
        } else if (field.fieldType == 'boolean') {
          value = field.fieldValue.toLowerCase() == 'true';
        } else if (field.fieldType == 'number') {
          value = num.tryParse(field.fieldValue) ?? field.fieldValue;
        }
        
        if (field.fieldGroup.isNotEmpty) {
          groups.putIfAbsent(field.fieldGroup, () => {});
          groups[field.fieldGroup]![field.fieldName] = value;
        } else {
          result[field.fieldName] = value;
        }
      }
      
      // Merge groups back into result
      result.addAll(groups);
      return result;
    }
    
    // Fallback to dataJson for old records
    final record = await getMedicalRecordById(recordId);
    if (record == null) return {};
    
    try {
      return jsonDecode(record.dataJson) as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }
}
