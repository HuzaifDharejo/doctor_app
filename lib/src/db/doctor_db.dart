// Minimal Drift DB. Run `flutter pub run build_runner build` to generate code.
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

@DriftDatabase(tables: [Patients, Appointments, Prescriptions, MedicalRecords, Invoices, VitalSigns, TreatmentOutcomes, ScheduledFollowUps, TreatmentSessions, MedicationResponses, TreatmentGoals, AuditLogs, Encounters, Diagnoses, ClinicalNotes, EncounterDiagnoses])
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
  int get schemaVersion => 7;

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
}
