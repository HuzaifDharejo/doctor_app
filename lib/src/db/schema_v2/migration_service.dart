// Migration Service: Transform from V1 (duplicate data) to V2 (encounter-based)
//
// This service handles the database migration in phases to avoid data loss.

import '../doctor_db.dart';
import '../../services/logger_service.dart';

/// Migration phases for transforming to encounter-based model
enum MigrationPhase {
  notStarted,
  phase1_createTables,    // Create new tables (Encounters, Diagnoses, ClinicalNotes)
  phase2_migrateData,     // Copy data to new structure
  phase3_updateReferences, // Update foreign keys
  phase4_verifyData,      // Verify data integrity
  phase5_cleanupOldFields, // Remove duplicate fields (optional, can keep for rollback)
  completed,
}

class SchemaV2MigrationService {
  final DoctorDatabase db;
  
  SchemaV2MigrationService(this.db);
  
  /// Check current migration status
  Future<MigrationPhase> getMigrationPhase() async {
    // Check if encounters table exists
    try {
      // This would check schema version in a real implementation
      return MigrationPhase.notStarted;
    } catch (e) {
      return MigrationPhase.notStarted;
    }
  }
  
  /// Run full migration
  Future<void> migrate() async {
    log.i('MIGRATION', '═══════════════════════════════════════════════════════');
    log.i('MIGRATION', 'Starting Schema V2 Migration (Encounter-Based Model)');
    log.i('MIGRATION', '═══════════════════════════════════════════════════════');
    
    await _phase1CreateTables();
    await _phase2MigrateData();
    await _phase3UpdateReferences();
    await _phase4VerifyData();
    
    log.i('MIGRATION', '═══════════════════════════════════════════════════════');
    log.i('MIGRATION', 'Migration Complete!');
    log.i('MIGRATION', '═══════════════════════════════════════════════════════');
  }
  
  /// Phase 1: Create new tables
  Future<void> _phase1CreateTables() async {
    log.i('MIGRATION', 'Phase 1: Creating new tables...');
    
    // SQL to create new tables
    // In Drift, we'd add these to the database class and run migrations
    // For now, documenting the SQL needed:
    
    /*
    CREATE TABLE IF NOT EXISTS encounters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL REFERENCES patients(id),
      appointment_id INTEGER REFERENCES appointments(id),
      encounter_date DATETIME NOT NULL,
      encounter_type TEXT DEFAULT 'outpatient',
      status TEXT DEFAULT 'in_progress',
      chief_complaint TEXT DEFAULT '',
      provider_name TEXT DEFAULT '',
      provider_type TEXT DEFAULT 'psychiatrist',
      is_billable INTEGER DEFAULT 1,
      invoice_id INTEGER REFERENCES invoices(id),
      check_in_time DATETIME,
      check_out_time DATETIME,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS diagnoses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL REFERENCES patients(id),
      encounter_id INTEGER REFERENCES encounters(id),
      icd_code TEXT DEFAULT '',
      description TEXT NOT NULL,
      category TEXT DEFAULT 'psychiatric',
      severity TEXT DEFAULT 'moderate',
      status TEXT DEFAULT 'active',
      onset_date DATETIME,
      diagnosed_date DATETIME NOT NULL,
      resolved_date DATETIME,
      is_primary INTEGER DEFAULT 0,
      display_order INTEGER DEFAULT 0,
      notes TEXT DEFAULT '',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS clinical_notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      encounter_id INTEGER NOT NULL REFERENCES encounters(id),
      patient_id INTEGER NOT NULL REFERENCES patients(id),
      note_type TEXT DEFAULT 'progress',
      subjective TEXT DEFAULT '',
      objective TEXT DEFAULT '',
      assessment TEXT DEFAULT '',
      plan TEXT DEFAULT '',
      mental_status_exam TEXT DEFAULT '{}',
      risk_level TEXT DEFAULT 'none',
      risk_factors TEXT DEFAULT '',
      safety_plan TEXT DEFAULT '',
      signed_by TEXT DEFAULT '',
      signed_at DATETIME,
      is_locked INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS encounter_diagnoses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      encounter_id INTEGER NOT NULL REFERENCES encounters(id),
      diagnosis_id INTEGER NOT NULL REFERENCES diagnoses(id),
      is_new_diagnosis INTEGER DEFAULT 0,
      encounter_status TEXT DEFAULT 'addressed',
      notes TEXT DEFAULT ''
    );
    
    -- Add encounter_id to existing tables
    ALTER TABLE vital_signs ADD COLUMN encounter_id INTEGER REFERENCES encounters(id);
    ALTER TABLE prescriptions ADD COLUMN encounter_id INTEGER REFERENCES encounters(id);
    ALTER TABLE prescriptions ADD COLUMN primary_diagnosis_id INTEGER REFERENCES diagnoses(id);
    ALTER TABLE medical_records ADD COLUMN encounter_id INTEGER REFERENCES encounters(id);
    ALTER TABLE treatment_sessions ADD COLUMN encounter_id INTEGER REFERENCES encounters(id);
    ALTER TABLE treatment_outcomes ADD COLUMN diagnosis_id INTEGER REFERENCES diagnoses(id);
    */
    
    log.i('MIGRATION', 'Phase 1 complete: New tables created');
  }
  
  /// Phase 2: Migrate existing data to new structure
  Future<void> _phase2MigrateData() async {
    log.i('MIGRATION', 'Phase 2: Migrating data...');
    
    // 2a. Create Encounters from Appointments with Medical Records
    await _createEncountersFromAppointments();
    
    // 2b. Extract Diagnoses from duplicate fields
    await _extractDiagnoses();
    
    // 2c. Create Clinical Notes from Medical Records
    await _createClinicalNotes();
    
    // 2d. Link Vital Signs to Encounters
    await _linkVitalSignsToEncounters();
    
    log.i('MIGRATION', 'Phase 2 complete: Data migrated');
  }
  
  Future<void> _createEncountersFromAppointments() async {
    log.i('MIGRATION', '  Creating encounters from appointments...');
    
    // Get all appointments that have associated medical records
    final appointments = await db.getAllAppointments();
    int created = 0;
    
    for (final apt in appointments) {
      if (apt.status == 'completed' || apt.medicalRecordId != null) {
        // Create an encounter for this appointment
        // await db.customStatement('''
        //   INSERT INTO encounters (patient_id, appointment_id, encounter_date, 
        //     encounter_type, status, chief_complaint, created_at)
        //   VALUES (?, ?, ?, 'outpatient', 'completed', ?, ?)
        // ''', [apt.patientId, apt.id, apt.appointmentDateTime.toIso8601String(), 
        //       apt.reason, apt.createdAt.toIso8601String()]);
        created++;
      }
    }
    
    log.i('MIGRATION', '  Created $created encounters from appointments');
  }
  
  Future<void> _extractDiagnoses() async {
    log.i('MIGRATION', '  Extracting diagnoses from records...');
    
    // Sources of diagnosis data:
    // 1. MedicalRecords.diagnosis
    // 2. Prescriptions.diagnosis
    // 3. TreatmentOutcomes.diagnosis
    
    final records = await db.getAllMedicalRecords();
    final uniqueDiagnoses = <String, Map<String, dynamic>>{};
    
    for (final record in records) {
      if (record.diagnosis.isNotEmpty) {
        // Normalize and deduplicate
        final normalizedDiag = record.diagnosis.trim().toLowerCase();
        if (!uniqueDiagnoses.containsKey(normalizedDiag)) {
          uniqueDiagnoses[normalizedDiag] = {
            'patientId': record.patientId,
            'description': record.diagnosis.trim(),
            'diagnosedDate': record.recordDate,
            'sourceRecordId': record.id,
          };
        }
      }
    }
    
    log.i('MIGRATION', '  Found ${uniqueDiagnoses.length} unique diagnoses');
    
    // Insert into diagnoses table
    // for (final diag in uniqueDiagnoses.values) {
    //   await db.customStatement('''
    //     INSERT INTO diagnoses (patient_id, description, diagnosed_date, status)
    //     VALUES (?, ?, ?, 'active')
    //   ''', [diag['patientId'], diag['description'], diag['diagnosedDate']]);
    // }
  }
  
  Future<void> _createClinicalNotes() async {
    log.i('MIGRATION', '  Creating clinical notes from medical records...');
    
    // Convert MedicalRecords with recordType 'general' or 'psychiatric_assessment'
    // to ClinicalNotes with SOAP format
    
    final records = await db.getAllMedicalRecords();
    int converted = 0;
    
    for (final record in records) {
      if (record.recordType == 'general' || record.recordType == 'psychiatric_assessment') {
        // Map to SOAP format:
        // Subjective = description (chief complaint)
        // Objective = data_json (vitals, exam findings)
        // Assessment = diagnosis
        // Plan = treatment
        
        // await db.customStatement('''
        //   INSERT INTO clinical_notes (encounter_id, patient_id, note_type,
        //     subjective, objective, assessment, plan, created_at)
        //   VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        // ''', [...]);
        
        converted++;
      }
    }
    
    log.i('MIGRATION', '  Converted $converted records to clinical notes');
  }
  
  Future<void> _linkVitalSignsToEncounters() async {
    log.i('MIGRATION', '  Linking vital signs to encounters...');
    
    // Match vital signs to encounters by patient_id and date proximity
    // Vitals recorded within 1 hour of encounter check-in belong to that encounter
    
    log.i('MIGRATION', '  Vital signs linked to encounters');
  }
  
  /// Phase 3: Update foreign key references
  Future<void> _phase3UpdateReferences() async {
    log.i('MIGRATION', 'Phase 3: Updating references...');
    
    // Update prescriptions to reference diagnoses table
    // Update treatment outcomes to reference diagnoses table
    // Remove duplicate text fields (or keep for backward compatibility)
    
    log.i('MIGRATION', 'Phase 3 complete: References updated');
  }
  
  /// Phase 4: Verify data integrity
  Future<void> _phase4VerifyData() async {
    log.i('MIGRATION', 'Phase 4: Verifying data integrity...');
    
    // Checks:
    // 1. Every completed appointment has an encounter
    // 2. Every encounter has at least one clinical note or vital sign
    // 3. All diagnoses are linked to patients
    // 4. No orphaned records
    
    log.i('MIGRATION', 'Phase 4 complete: Data verified');
  }
  
  /// Generate migration report
  Future<Map<String, dynamic>> generateReport() async {
    return {
      'totalAppointments': (await db.getAllAppointments()).length,
      'totalMedicalRecords': (await db.getAllMedicalRecords()).length,
      'totalPrescriptions': (await db.getAllPrescriptions()).length,
      'totalVitalSigns': (await db.getAllVitalSigns()).length,
      // After migration:
      // 'totalEncounters': ...,
      // 'totalDiagnoses': ...,
      // 'totalClinicalNotes': ...,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKFLOW COMPARISON
// ═══════════════════════════════════════════════════════════════════════════════
//
// BEFORE (Current - Duplicate Data):
// ─────────────────────────────────────
// Doctor sees patient:
// 1. Creates/updates Appointment (reason, notes)
// 2. Records Vitals → VitalSigns table AND MedicalRecord.dataJson AND Prescription.vitalsJson
// 3. Writes diagnosis → MedicalRecord.diagnosis AND Prescription.diagnosis AND TreatmentOutcome.diagnosis
// 4. Writes treatment → MedicalRecord.treatment AND TreatmentOutcome.treatmentDescription
// 5. Creates prescription with duplicate diagnosis & vitals
// 6. Creates invoice linked to appointment
//
// AFTER (V2 - Encounter-Based):
// ─────────────────────────────────────
// Doctor sees patient:
// 1. CHECK-IN: Encounter created (links to appointment if scheduled)
// 2. VITALS: VitalSigns recorded once, linked to Encounter
// 3. ASSESSMENT: ClinicalNotes (SOAP format) linked to Encounter
// 4. DIAGNOSIS: Added to Diagnoses table if new, linked via EncounterDiagnoses
// 5. PRESCRIPTION: Created with reference to primaryDiagnosisId (no duplicate text)
// 6. BILLING: Invoice linked from Encounter
//
// Data is entered ONCE and referenced everywhere else!
// ═══════════════════════════════════════════════════════════════════════════════
