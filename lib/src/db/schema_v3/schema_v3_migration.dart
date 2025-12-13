// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V3 MIGRATION - Migrate JSON data to normalized tables
// ═══════════════════════════════════════════════════════════════════════════════
//
// This migration script creates the new normalized tables and migrates
// existing JSON data to the proper relational structure.
//
// Migration Strategy:
// 1. Create new tables (non-destructive)
// 2. Migrate existing JSON data to new tables
// 3. Keep original JSON columns for backward compatibility (marked deprecated)
// 4. In a future release, remove the deprecated JSON columns
//
// ═══════════════════════════════════════════════════════════════════════════════

/// Schema V3 Migration - Create normalized tables and migrate JSON data
class SchemaV3Migration {
  /// SQL statements to create new tables
  static List<String> get createTableStatements => [
    // 1. PrescriptionMedications
    '''
    CREATE TABLE IF NOT EXISTS prescription_medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prescription_id INTEGER NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      medication_name TEXT NOT NULL,
      generic_name TEXT NOT NULL DEFAULT '',
      brand_name TEXT NOT NULL DEFAULT '',
      drug_code TEXT NOT NULL DEFAULT '',
      drug_class TEXT NOT NULL DEFAULT '',
      strength TEXT NOT NULL DEFAULT '',
      dosage_form TEXT NOT NULL DEFAULT 'tablet',
      route TEXT NOT NULL DEFAULT 'oral',
      frequency TEXT NOT NULL DEFAULT '',
      timing TEXT NOT NULL DEFAULT '',
      duration_days INTEGER,
      duration_text TEXT NOT NULL DEFAULT '',
      quantity REAL,
      quantity_unit TEXT NOT NULL DEFAULT 'tablets',
      refills INTEGER NOT NULL DEFAULT 0,
      before_food INTEGER NOT NULL DEFAULT 0,
      after_food INTEGER NOT NULL DEFAULT 0,
      with_food INTEGER NOT NULL DEFAULT 0,
      special_instructions TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'active',
      discontinue_reason TEXT NOT NULL DEFAULT '',
      discontinued_at INTEGER,
      display_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 2. InvoiceLineItems
    '''
    CREATE TABLE IF NOT EXISTS invoice_line_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      item_type TEXT NOT NULL DEFAULT 'service',
      description TEXT NOT NULL,
      cpt_code TEXT NOT NULL DEFAULT '',
      hcpcs_code TEXT NOT NULL DEFAULT '',
      modifier TEXT NOT NULL DEFAULT '',
      appointment_id INTEGER REFERENCES appointments(id),
      prescription_id INTEGER REFERENCES prescriptions(id),
      lab_order_id INTEGER REFERENCES lab_orders(id),
      treatment_session_id INTEGER REFERENCES treatment_sessions(id),
      unit_price REAL NOT NULL DEFAULT 0,
      quantity REAL NOT NULL DEFAULT 1,
      discount_percent REAL NOT NULL DEFAULT 0,
      discount_amount REAL NOT NULL DEFAULT 0,
      tax_percent REAL NOT NULL DEFAULT 0,
      tax_amount REAL NOT NULL DEFAULT 0,
      total_amount REAL NOT NULL DEFAULT 0,
      display_order INTEGER NOT NULL DEFAULT 0,
      notes TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 3. FamilyConditions
    '''
    CREATE TABLE IF NOT EXISTS family_conditions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      family_history_id INTEGER NOT NULL REFERENCES family_medical_history(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      condition_name TEXT NOT NULL,
      icd_code TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'medical',
      age_at_onset INTEGER,
      severity TEXT NOT NULL DEFAULT '',
      outcome TEXT NOT NULL DEFAULT '',
      confirmed_diagnosis INTEGER NOT NULL DEFAULT 1,
      notes TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 4. TreatmentSymptoms
    '''
    CREATE TABLE IF NOT EXISTS treatment_symptoms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medication_response_id INTEGER REFERENCES medication_responses(id) ON DELETE CASCADE,
      treatment_outcome_id INTEGER REFERENCES treatment_outcomes(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      symptom_name TEXT NOT NULL,
      symptom_category TEXT NOT NULL DEFAULT '',
      baseline_severity INTEGER,
      current_severity INTEGER,
      target_severity INTEGER,
      improvement_level TEXT NOT NULL DEFAULT 'unchanged',
      improvement_percent INTEGER,
      recorded_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 5. SideEffects
    '''
    CREATE TABLE IF NOT EXISTS side_effects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medication_response_id INTEGER REFERENCES medication_responses(id) ON DELETE CASCADE,
      prescription_medication_id INTEGER REFERENCES prescription_medications(id) ON DELETE SET NULL,
      treatment_outcome_id INTEGER REFERENCES treatment_outcomes(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      effect_name TEXT NOT NULL,
      effect_category TEXT NOT NULL DEFAULT 'other',
      severity TEXT NOT NULL DEFAULT 'mild',
      severity_score INTEGER,
      onset_date INTEGER,
      resolved_date INTEGER,
      frequency TEXT NOT NULL DEFAULT '',
      management_action TEXT NOT NULL DEFAULT '',
      caused_discontinuation INTEGER NOT NULL DEFAULT 0,
      reported_to_provider INTEGER NOT NULL DEFAULT 1,
      notes TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 6. Attachments
    '''
    CREATE TABLE IF NOT EXISTS attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      entity_type TEXT NOT NULL,
      entity_id INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      original_file_name TEXT NOT NULL DEFAULT '',
      file_path TEXT NOT NULL,
      file_type TEXT NOT NULL DEFAULT '',
      file_extension TEXT NOT NULL DEFAULT '',
      file_size_bytes INTEGER,
      title TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'other',
      is_confidential INTEGER NOT NULL DEFAULT 0,
      uploaded_by TEXT NOT NULL DEFAULT '',
      display_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 7. MentalStatusExams
    '''
    CREATE TABLE IF NOT EXISTS mental_status_exams (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      encounter_id INTEGER REFERENCES encounters(id) ON DELETE CASCADE,
      clinical_note_id INTEGER REFERENCES clinical_notes(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      appearance TEXT NOT NULL DEFAULT '',
      grooming TEXT NOT NULL DEFAULT 'appropriate',
      attire TEXT NOT NULL DEFAULT 'appropriate',
      eye_contact TEXT NOT NULL DEFAULT 'appropriate',
      behavior TEXT NOT NULL DEFAULT '',
      psychomotor_activity TEXT NOT NULL DEFAULT 'normal',
      attitude TEXT NOT NULL DEFAULT 'cooperative',
      speech_rate TEXT NOT NULL DEFAULT 'normal',
      speech_volume TEXT NOT NULL DEFAULT 'normal',
      speech_tone TEXT NOT NULL DEFAULT 'normal',
      speech_quality TEXT NOT NULL DEFAULT '',
      mood TEXT NOT NULL DEFAULT '',
      affect TEXT NOT NULL DEFAULT '',
      affect_range TEXT NOT NULL DEFAULT 'full',
      affect_congruence TEXT NOT NULL DEFAULT 'congruent',
      thought_process TEXT NOT NULL DEFAULT 'linear',
      thought_content TEXT NOT NULL DEFAULT '',
      hallucinations_auditory INTEGER NOT NULL DEFAULT 0,
      hallucinations_visual INTEGER NOT NULL DEFAULT 0,
      hallucinations_other INTEGER NOT NULL DEFAULT 0,
      hallucinations_details TEXT NOT NULL DEFAULT '',
      delusions INTEGER NOT NULL DEFAULT 0,
      delusions_type TEXT NOT NULL DEFAULT '',
      suicidal_ideation INTEGER NOT NULL DEFAULT 0,
      suicidal_details TEXT NOT NULL DEFAULT '',
      homicidal_ideation INTEGER NOT NULL DEFAULT 0,
      homicidal_details TEXT NOT NULL DEFAULT '',
      self_harm_ideation INTEGER NOT NULL DEFAULT 0,
      orientation TEXT NOT NULL DEFAULT 'oriented_x4',
      attention TEXT NOT NULL DEFAULT 'intact',
      concentration TEXT NOT NULL DEFAULT 'intact',
      memory TEXT NOT NULL DEFAULT 'intact',
      insight TEXT NOT NULL DEFAULT 'good',
      judgment TEXT NOT NULL DEFAULT 'good',
      additional_notes TEXT NOT NULL DEFAULT '',
      examined_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 8. LabTestResults
    '''
    CREATE TABLE IF NOT EXISTS lab_test_results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lab_order_id INTEGER NOT NULL REFERENCES lab_orders(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      test_name TEXT NOT NULL,
      test_code TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT '',
      result_value TEXT NOT NULL DEFAULT '',
      result_unit TEXT NOT NULL DEFAULT '',
      result_type TEXT NOT NULL DEFAULT 'numeric',
      reference_range TEXT NOT NULL DEFAULT '',
      reference_low REAL,
      reference_high REAL,
      flag TEXT NOT NULL DEFAULT 'normal',
      is_abnormal INTEGER NOT NULL DEFAULT 0,
      is_critical INTEGER NOT NULL DEFAULT 0,
      previous_value TEXT NOT NULL DEFAULT '',
      previous_date INTEGER,
      trend TEXT NOT NULL DEFAULT '',
      interpretation TEXT NOT NULL DEFAULT '',
      notes TEXT NOT NULL DEFAULT '',
      display_order INTEGER NOT NULL DEFAULT 0,
      resulted_at INTEGER,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 9. ProgressNoteEntries
    '''
    CREATE TABLE IF NOT EXISTS progress_note_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      treatment_goal_id INTEGER REFERENCES treatment_goals(id) ON DELETE CASCADE,
      treatment_outcome_id INTEGER REFERENCES treatment_outcomes(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      encounter_id INTEGER REFERENCES encounters(id),
      entry_date INTEGER NOT NULL,
      note TEXT NOT NULL,
      progress_rating INTEGER,
      progress_status TEXT NOT NULL DEFAULT '',
      barriers TEXT NOT NULL DEFAULT '',
      interventions_used TEXT NOT NULL DEFAULT '',
      next_steps TEXT NOT NULL DEFAULT '',
      recorded_by TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 10. TreatmentInterventions
    '''
    CREATE TABLE IF NOT EXISTS treatment_interventions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      treatment_session_id INTEGER REFERENCES treatment_sessions(id) ON DELETE CASCADE,
      treatment_goal_id INTEGER REFERENCES treatment_goals(id) ON DELETE CASCADE,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      intervention_name TEXT NOT NULL,
      intervention_type TEXT NOT NULL DEFAULT 'therapeutic',
      modality TEXT NOT NULL DEFAULT '',
      effectiveness TEXT NOT NULL DEFAULT '',
      effectiveness_rating INTEGER,
      patient_response TEXT NOT NULL DEFAULT '',
      notes TEXT NOT NULL DEFAULT '',
      used_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 11. ClaimBillingCodes
    '''
    CREATE TABLE IF NOT EXISTS claim_billing_codes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      claim_id INTEGER NOT NULL REFERENCES insurance_claims(id) ON DELETE CASCADE,
      code_type TEXT NOT NULL,
      code TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      charged_amount REAL,
      units INTEGER NOT NULL DEFAULT 1,
      place_of_service TEXT NOT NULL DEFAULT '',
      linked_procedure_id INTEGER,
      display_order INTEGER NOT NULL DEFAULT 0,
      is_primary INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 12. PatientAllergies
    '''
    CREATE TABLE IF NOT EXISTS patient_allergies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      allergen TEXT NOT NULL,
      allergen_type TEXT NOT NULL DEFAULT 'medication',
      allergen_code TEXT NOT NULL DEFAULT '',
      reaction_type TEXT NOT NULL DEFAULT '',
      reaction_severity TEXT NOT NULL DEFAULT 'moderate',
      reaction_description TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'active',
      verified INTEGER NOT NULL DEFAULT 0,
      verified_at INTEGER,
      onset_date INTEGER,
      recorded_date INTEGER NOT NULL,
      source TEXT NOT NULL DEFAULT 'patient',
      notes TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // 13. PatientChronicConditions
    '''
    CREATE TABLE IF NOT EXISTS patient_chronic_conditions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id INTEGER NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
      diagnosis_id INTEGER REFERENCES diagnoses(id),
      condition_name TEXT NOT NULL,
      icd_code TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'medical',
      status TEXT NOT NULL DEFAULT 'active',
      severity TEXT NOT NULL DEFAULT 'moderate',
      onset_date INTEGER,
      diagnosed_date INTEGER,
      current_treatment TEXT NOT NULL DEFAULT '',
      managing_provider TEXT NOT NULL DEFAULT '',
      last_review_date INTEGER,
      next_review_date INTEGER,
      notes TEXT NOT NULL DEFAULT '',
      created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
    )
    ''',

    // Create indexes for better query performance
    'CREATE INDEX IF NOT EXISTS idx_prescription_medications_prescription ON prescription_medications(prescription_id)',
    'CREATE INDEX IF NOT EXISTS idx_prescription_medications_patient ON prescription_medications(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_invoice_line_items_invoice ON invoice_line_items(invoice_id)',
    'CREATE INDEX IF NOT EXISTS idx_invoice_line_items_patient ON invoice_line_items(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_family_conditions_history ON family_conditions(family_history_id)',
    'CREATE INDEX IF NOT EXISTS idx_family_conditions_patient ON family_conditions(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_treatment_symptoms_patient ON treatment_symptoms(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_side_effects_patient ON side_effects(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_attachments_entity ON attachments(entity_type, entity_id)',
    'CREATE INDEX IF NOT EXISTS idx_attachments_patient ON attachments(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_mental_status_exams_patient ON mental_status_exams(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_lab_test_results_order ON lab_test_results(lab_order_id)',
    'CREATE INDEX IF NOT EXISTS idx_lab_test_results_patient ON lab_test_results(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_progress_note_entries_patient ON progress_note_entries(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_treatment_interventions_patient ON treatment_interventions(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_claim_billing_codes_claim ON claim_billing_codes(claim_id)',
    'CREATE INDEX IF NOT EXISTS idx_patient_allergies_patient ON patient_allergies(patient_id)',
    'CREATE INDEX IF NOT EXISTS idx_patient_chronic_conditions_patient ON patient_chronic_conditions(patient_id)',
  ];
}
