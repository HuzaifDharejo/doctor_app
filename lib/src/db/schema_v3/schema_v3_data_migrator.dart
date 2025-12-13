// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V3 DATA MIGRATOR - Migrate JSON data to normalized tables
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import '../doctor_db.dart';

/// Service to migrate existing JSON data to normalized tables
class SchemaV3DataMigrator {
  final DoctorDatabase _db;

  SchemaV3DataMigrator(this._db);

  /// Run all data migrations
  Future<MigrationResult> migrateAll() async {
    final result = MigrationResult();

    try {
      // 1. Migrate Prescription items
      result.prescriptionMedications = await _migratePrescriptionItems();

      // 2. Migrate Invoice items
      result.invoiceLineItems = await _migrateInvoiceItems();

      // 3. Migrate Family conditions
      result.familyConditions = await _migrateFamilyConditions();

      // 4. Migrate Treatment symptoms and side effects
      result.treatmentSymptoms = await _migrateMedicationResponseSymptoms();
      result.sideEffects = await _migrateSideEffects();

      // 5. Migrate Attachments from clinical notes
      result.attachments = await _migrateAttachments();

      // 6. Migrate Mental status exams
      result.mentalStatusExams = await _migrateMentalStatusExams();

      // 7. Migrate Lab test results
      result.labTestResults = await _migrateLabTestResults();

      // 8. Migrate Progress notes
      result.progressNotes = await _migrateProgressNotes();

      // 9. Migrate Treatment interventions
      result.treatmentInterventions = await _migrateTreatmentInterventions();

      // 10. Migrate Insurance claim codes
      result.claimBillingCodes = await _migrateClaimBillingCodes();

      // 11. Migrate Patient allergies from comma-separated text
      result.patientAllergies = await _migratePatientAllergies();

      // 12. Migrate Patient chronic conditions from comma-separated text
      result.chronicConditions = await _migrateChronicConditions();

      result.success = true;
    } catch (e, stack) {
      result.success = false;
      result.error = e.toString();
      result.stackTrace = stack.toString();
    }

    return result;
  }

  /// Migrate itemsJson from Prescriptions to PrescriptionMedications
  Future<int> _migratePrescriptionItems() async {
    int migrated = 0;

    // Get all prescriptions with itemsJson
    final prescriptions = await _db.customSelect(
      'SELECT id, patient_id, items_json FROM prescriptions WHERE items_json IS NOT NULL AND items_json != ""',
    ).get();

    for (final row in prescriptions) {
      final prescriptionId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final itemsJson = row.read<String?>('items_json');

      if (itemsJson == null || itemsJson.isEmpty) continue;

      try {
        final items = jsonDecode(itemsJson);
        if (items is! List) continue;

        int order = 0;
        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);

          // Only migrate medications (skip lab tests as they go to LabOrders)
          if (map['type'] == 'labTest') continue;

          await _db.customStatement('''
            INSERT INTO prescription_medications (
              prescription_id, patient_id, medication_name, generic_name, brand_name,
              drug_code, drug_class, strength, dosage_form, route,
              frequency, timing, duration_days, duration_text,
              quantity, quantity_unit, refills,
              before_food, after_food, with_food,
              special_instructions, status, display_order, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            prescriptionId,
            patientId,
            map['name'] ?? map['medicationName'] ?? '',
            map['genericName'] ?? '',
            map['brandName'] ?? '',
            map['drugCode'] ?? map['code'] ?? '',
            map['drugClass'] ?? '',
            map['strength'] ?? map['dose'] ?? '',
            map['dosageForm'] ?? map['form'] ?? 'tablet',
            map['route'] ?? 'oral',
            map['frequency'] ?? '',
            map['timing'] ?? '',
            map['durationDays'] ?? map['days'],
            map['duration'] ?? '',
            map['quantity'],
            map['quantityUnit'] ?? map['unit'] ?? 'tablets',
            map['refills'] ?? 0,
            (map['beforeFood'] == true || map['timing']?.toString().contains('before') == true) ? 1 : 0,
            (map['afterFood'] == true || map['timing']?.toString().contains('after') == true) ? 1 : 0,
            (map['withFood'] == true || map['timing']?.toString().contains('with') == true) ? 1 : 0,
            map['instructions'] ?? map['specialInstructions'] ?? '',
            'active',
            order++,
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        }
      } catch (e) {
        // Log error but continue with other prescriptions
        print('Error migrating prescription $prescriptionId: $e');
      }
    }

    return migrated;
  }

  /// Migrate itemsJson from Invoices to InvoiceLineItems
  Future<int> _migrateInvoiceItems() async {
    int migrated = 0;

    final invoices = await _db.customSelect(
      'SELECT id, patient_id, items_json FROM invoices WHERE items_json IS NOT NULL AND items_json != ""',
    ).get();

    for (final row in invoices) {
      final invoiceId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final itemsJson = row.read<String?>('items_json');

      if (itemsJson == null || itemsJson.isEmpty) continue;

      try {
        final items = jsonDecode(itemsJson);
        if (items is! List) continue;

        int order = 0;
        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);

          final unitPrice = (map['unitPrice'] ?? map['price'] ?? 0).toDouble();
          final quantity = (map['quantity'] ?? 1).toDouble();
          final discount = (map['discount'] ?? map['discountAmount'] ?? 0).toDouble();
          final tax = (map['tax'] ?? map['taxAmount'] ?? 0).toDouble();
          final total = map['total'] ?? map['amount'] ?? (unitPrice * quantity - discount + tax);

          await _db.customStatement('''
            INSERT INTO invoice_line_items (
              invoice_id, patient_id, item_type, description,
              cpt_code, hcpcs_code, modifier,
              appointment_id, prescription_id, lab_order_id, treatment_session_id,
              unit_price, quantity, discount_percent, discount_amount,
              tax_percent, tax_amount, total_amount,
              display_order, notes, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            invoiceId,
            patientId,
            map['type'] ?? 'service',
            map['description'] ?? map['name'] ?? '',
            map['cptCode'] ?? '',
            map['hcpcsCode'] ?? '',
            map['modifier'] ?? '',
            map['appointmentId'],
            map['prescriptionId'],
            map['labOrderId'],
            map['treatmentSessionId'],
            unitPrice,
            quantity,
            map['discountPercent'] ?? 0.0,
            discount,
            map['taxPercent'] ?? 0.0,
            tax,
            total,
            order++,
            map['notes'] ?? '',
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        }
      } catch (e) {
        print('Error migrating invoice $invoiceId: $e');
      }
    }

    return migrated;
  }

  /// Migrate conditions from FamilyMedicalHistory to FamilyConditions
  Future<int> _migrateFamilyConditions() async {
    int migrated = 0;

    final histories = await _db.customSelect(
      'SELECT id, patient_id, conditions, condition_details FROM family_medical_history WHERE conditions IS NOT NULL',
    ).get();

    for (final row in histories) {
      final historyId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final conditionsJson = row.read<String?>('conditions');
      final detailsJson = row.read<String?>('condition_details');

      if (conditionsJson == null || conditionsJson.isEmpty) continue;

      try {
        final conditions = jsonDecode(conditionsJson);
        Map<String, dynamic>? details;
        if (detailsJson != null && detailsJson.isNotEmpty) {
          details = jsonDecode(detailsJson) as Map<String, dynamic>?;
        }

        if (conditions is List) {
          for (final condition in conditions) {
            final conditionName = condition.toString();
            final conditionDetail = details?[conditionName] as Map<String, dynamic>? ?? {};

            await _db.customStatement('''
              INSERT INTO family_conditions (
                family_history_id, patient_id, condition_name, icd_code, category,
                age_at_onset, severity, outcome, confirmed_diagnosis, notes, created_at
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [
              historyId,
              patientId,
              conditionName,
              conditionDetail['icdCode'] ?? '',
              conditionDetail['category'] ?? _categorizeCondition(conditionName),
              conditionDetail['ageAtOnset'],
              conditionDetail['severity'] ?? '',
              conditionDetail['outcome'] ?? '',
              1,
              conditionDetail['notes'] ?? '',
              DateTime.now().millisecondsSinceEpoch,
            ]);
            migrated++;
          }
        }
      } catch (e) {
        print('Error migrating family history $historyId: $e');
      }
    }

    return migrated;
  }

  /// Migrate targetSymptoms and symptomImprovement from MedicationResponses
  Future<int> _migrateMedicationResponseSymptoms() async {
    int migrated = 0;

    final responses = await _db.customSelect(
      'SELECT id, patient_id, target_symptoms, symptom_improvement, recorded_at FROM medication_responses WHERE target_symptoms IS NOT NULL',
    ).get();

    for (final row in responses) {
      final responseId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final targetSymptomsJson = row.read<String?>('target_symptoms');
      final symptomImprovementJson = row.read<String?>('symptom_improvement');
      final recordedAt = row.read<int?>('recorded_at') ?? DateTime.now().millisecondsSinceEpoch;

      if (targetSymptomsJson == null || targetSymptomsJson.isEmpty) continue;

      try {
        final targetSymptoms = jsonDecode(targetSymptomsJson);
        Map<String, dynamic>? improvements;
        if (symptomImprovementJson != null && symptomImprovementJson.isNotEmpty) {
          improvements = jsonDecode(symptomImprovementJson) as Map<String, dynamic>?;
        }

        if (targetSymptoms is List) {
          for (final symptom in targetSymptoms) {
            final symptomName = symptom.toString();
            final improvement = improvements?[symptomName];

            await _db.customStatement('''
              INSERT INTO treatment_symptoms (
                medication_response_id, patient_id, symptom_name, symptom_category,
                baseline_severity, current_severity, target_severity,
                improvement_level, improvement_percent, recorded_at, created_at
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [
              responseId,
              patientId,
              symptomName,
              _categorizeSymptom(symptomName),
              null,
              null,
              null,
              improvement is Map ? improvement['level'] ?? 'unchanged' : 'unchanged',
              improvement is Map ? improvement['percent'] : null,
              recordedAt,
              DateTime.now().millisecondsSinceEpoch,
            ]);
            migrated++;
          }
        }
      } catch (e) {
        print('Error migrating medication response $responseId: $e');
      }
    }

    return migrated;
  }

  /// Migrate sideEffects from MedicationResponses
  Future<int> _migrateSideEffects() async {
    int migrated = 0;

    final responses = await _db.customSelect(
      'SELECT id, patient_id, side_effects FROM medication_responses WHERE side_effects IS NOT NULL AND side_effects != ""',
    ).get();

    for (final row in responses) {
      final responseId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final sideEffectsJson = row.read<String?>('side_effects');

      if (sideEffectsJson == null || sideEffectsJson.isEmpty) continue;

      try {
        final sideEffects = jsonDecode(sideEffectsJson);

        if (sideEffects is List) {
          for (final effect in sideEffects) {
            String effectName;
            String severity = 'mild';
            String notes = '';

            if (effect is String) {
              effectName = effect;
            } else if (effect is Map) {
              effectName = (effect['name'] ?? effect['effect'] ?? '').toString();
              severity = (effect['severity'] ?? 'mild').toString();
              notes = (effect['notes'] ?? '').toString();
            } else {
              continue;
            }

            await _db.customStatement('''
              INSERT INTO side_effects (
                medication_response_id, patient_id, effect_name, effect_category,
                severity, severity_score, onset_date, resolved_date,
                frequency, management_action, caused_discontinuation,
                reported_to_provider, notes, created_at
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [
              responseId,
              patientId,
              effectName,
              _categorizeSideEffect(effectName),
              severity,
              null,
              null,
              null,
              '',
              '',
              0,
              1,
              notes,
              DateTime.now().millisecondsSinceEpoch,
            ]);
            migrated++;
          }
        }
      } catch (e) {
        print('Error migrating side effects for response $responseId: $e');
      }
    }

    return migrated;
  }

  /// Migrate attachments from ClinicalNotes and Referrals
  Future<int> _migrateAttachments() async {
    int migrated = 0;

    // Migrate from clinical notes
    final notes = await _db.customSelect(
      'SELECT id, patient_id, attachments FROM clinical_notes WHERE attachments IS NOT NULL AND attachments != "" AND attachments != "[]"',
    ).get();

    for (final row in notes) {
      final noteId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final attachmentsJson = row.read<String?>('attachments');

      migrated += await _migrateAttachmentList(
        attachmentsJson,
        patientId,
        'clinical_note',
        noteId,
      );
    }

    // Migrate from referrals
    final referrals = await _db.customSelect(
      'SELECT id, patient_id, attachments FROM referrals WHERE attachments IS NOT NULL AND attachments != "" AND attachments != "[]"',
    ).get();

    for (final row in referrals) {
      final referralId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final attachmentsJson = row.read<String?>('attachments');

      migrated += await _migrateAttachmentList(
        attachmentsJson,
        patientId,
        'referral',
        referralId,
      );
    }

    return migrated;
  }

  Future<int> _migrateAttachmentList(
    String? attachmentsJson,
    int patientId,
    String entityType,
    int entityId,
  ) async {
    if (attachmentsJson == null || attachmentsJson.isEmpty) return 0;
    int migrated = 0;

    try {
      final attachments = jsonDecode(attachmentsJson);
      if (attachments is! List) return 0;

      int order = 0;
      for (final attachment in attachments) {
        String filePath;
        String fileName;
        String fileType = '';
        String title = '';

        if (attachment is String) {
          filePath = attachment;
          fileName = attachment.split('/').last;
        } else if (attachment is Map) {
          filePath = (attachment['path'] ?? attachment['filePath'] ?? '').toString();
          fileName = (attachment['name'] ?? attachment['fileName'] ?? filePath.split('/').last).toString();
          fileType = (attachment['type'] ?? attachment['mimeType'] ?? '').toString();
          title = (attachment['title'] ?? '').toString();
        } else {
          continue;
        }

        final extension = fileName.contains('.') ? fileName.split('.').last : '';

        await _db.customStatement('''
          INSERT INTO attachments (
            patient_id, entity_type, entity_id, file_name, original_file_name,
            file_path, file_type, file_extension, file_size_bytes,
            title, description, category, is_confidential, uploaded_by,
            display_order, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          patientId,
          entityType,
          entityId,
          fileName,
          fileName,
          filePath,
          fileType,
          extension,
          null,
          title,
          '',
          _categorizeAttachment(extension, entityType),
          0,
          '',
          order++,
          DateTime.now().millisecondsSinceEpoch,
        ]);
        migrated++;
      }
    } catch (e) {
      print('Error migrating attachments for $entityType $entityId: $e');
    }

    return migrated;
  }

  /// Migrate mentalStatusExam from ClinicalNotes and Encounters
  Future<int> _migrateMentalStatusExams() async {
    int migrated = 0;

    // From clinical notes
    final notes = await _db.customSelect(
      'SELECT id, patient_id, mental_status_exam, created_at FROM clinical_notes WHERE mental_status_exam IS NOT NULL AND mental_status_exam != "" AND mental_status_exam != "{}"',
    ).get();

    for (final row in notes) {
      final noteId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final mseJson = row.read<String?>('mental_status_exam');
      final createdAt = row.read<int?>('created_at') ?? DateTime.now().millisecondsSinceEpoch;

      if (await _migrateMSE(mseJson, patientId, null, noteId, createdAt)) {
        migrated++;
      }
    }

    // From encounters
    final encounters = await _db.customSelect(
      'SELECT id, patient_id, mental_status_exam, encounter_date FROM encounters WHERE mental_status_exam IS NOT NULL AND mental_status_exam != "" AND mental_status_exam != "{}"',
    ).get();

    for (final row in encounters) {
      final encounterId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final mseJson = row.read<String?>('mental_status_exam');
      final encounterDate = row.read<int?>('encounter_date') ?? DateTime.now().millisecondsSinceEpoch;

      if (await _migrateMSE(mseJson, patientId, encounterId, null, encounterDate)) {
        migrated++;
      }
    }

    return migrated;
  }

  Future<bool> _migrateMSE(
    String? mseJson,
    int patientId,
    int? encounterId,
    int? clinicalNoteId,
    int examinedAt,
  ) async {
    if (mseJson == null || mseJson.isEmpty) return false;

    try {
      final mse = jsonDecode(mseJson);
      if (mse is! Map) return false;

      final map = Map<String, dynamic>.from(mse);

      await _db.customStatement('''
        INSERT INTO mental_status_exams (
          encounter_id, clinical_note_id, patient_id,
          appearance, grooming, attire, eye_contact,
          behavior, psychomotor_activity, attitude,
          speech_rate, speech_volume, speech_tone, speech_quality,
          mood, affect, affect_range, affect_congruence,
          thought_process, thought_content,
          hallucinations_auditory, hallucinations_visual, hallucinations_other, hallucinations_details,
          delusions, delusions_type,
          suicidal_ideation, suicidal_details,
          homicidal_ideation, homicidal_details, self_harm_ideation,
          orientation, attention, concentration, memory,
          insight, judgment, additional_notes,
          examined_at, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        encounterId,
        clinicalNoteId,
        patientId,
        map['appearance'] ?? '',
        map['grooming'] ?? 'appropriate',
        map['attire'] ?? 'appropriate',
        map['eyeContact'] ?? 'appropriate',
        map['behavior'] ?? '',
        map['psychomotorActivity'] ?? 'normal',
        map['attitude'] ?? 'cooperative',
        map['speechRate'] ?? 'normal',
        map['speechVolume'] ?? 'normal',
        map['speechTone'] ?? 'normal',
        map['speechQuality'] ?? '',
        map['mood'] ?? '',
        map['affect'] ?? '',
        map['affectRange'] ?? 'full',
        map['affectCongruence'] ?? 'congruent',
        map['thoughtProcess'] ?? 'linear',
        map['thoughtContent'] ?? '',
        (map['hallucinationsAuditory'] == true) ? 1 : 0,
        (map['hallucinationsVisual'] == true) ? 1 : 0,
        (map['hallucinationsOther'] == true) ? 1 : 0,
        map['hallucinationsDetails'] ?? '',
        (map['delusions'] == true) ? 1 : 0,
        map['delusionsType'] ?? '',
        (map['suicidalIdeation'] == true) ? 1 : 0,
        map['suicidalDetails'] ?? '',
        (map['homicidalIdeation'] == true) ? 1 : 0,
        map['homicidalDetails'] ?? '',
        (map['selfHarmIdeation'] == true) ? 1 : 0,
        map['orientation'] ?? 'oriented_x4',
        map['attention'] ?? 'intact',
        map['concentration'] ?? 'intact',
        map['memory'] ?? 'intact',
        map['insight'] ?? 'good',
        map['judgment'] ?? 'good',
        map['additionalNotes'] ?? map['notes'] ?? '',
        examinedAt,
        DateTime.now().millisecondsSinceEpoch,
      ]);
      return true;
    } catch (e) {
      print('Error migrating MSE: $e');
      return false;
    }
  }

  /// Migrate testCodes/testNames from LabOrders to LabTestResults
  Future<int> _migrateLabTestResults() async {
    int migrated = 0;

    final orders = await _db.customSelect(
      'SELECT id, patient_id, test_codes, test_names, results, result_date FROM lab_orders WHERE test_codes IS NOT NULL OR test_names IS NOT NULL',
    ).get();

    for (final row in orders) {
      final orderId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final testCodesJson = row.read<String?>('test_codes');
      final testNamesJson = row.read<String?>('test_names');
      final resultsJson = row.read<String?>('results');
      final resultDate = row.read<int?>('result_date');

      try {
        List<String> testCodes = [];
        List<String> testNames = [];
        Map<String, dynamic>? results;

        if (testCodesJson != null && testCodesJson.isNotEmpty) {
          final decoded = jsonDecode(testCodesJson);
          if (decoded is List) testCodes = decoded.cast<String>();
        }

        if (testNamesJson != null && testNamesJson.isNotEmpty) {
          final decoded = jsonDecode(testNamesJson);
          if (decoded is List) testNames = decoded.cast<String>();
        }

        if (resultsJson != null && resultsJson.isNotEmpty) {
          results = jsonDecode(resultsJson) as Map<String, dynamic>?;
        }

        // Merge codes and names
        final maxLength = testCodes.length > testNames.length ? testCodes.length : testNames.length;

        for (int i = 0; i < maxLength; i++) {
          final code = i < testCodes.length ? testCodes[i] : '';
          final name = i < testNames.length ? testNames[i] : code;
          final result = results?[code] ?? results?[name];

          String resultValue = '';
          String resultUnit = '';
          String referenceRange = '';
          String flag = 'normal';
          bool isAbnormal = false;

          if (result is Map) {
            resultValue = result['value']?.toString() ?? '';
            resultUnit = (result['unit'] ?? '').toString();
            referenceRange = (result['referenceRange'] ?? '').toString();
            flag = (result['flag'] ?? 'normal').toString();
            isAbnormal = result['isAbnormal'] == true || flag != 'normal';
          } else if (result != null) {
            resultValue = result.toString();
          }

          await _db.customStatement('''
            INSERT INTO lab_test_results (
              lab_order_id, patient_id, test_name, test_code, category,
              result_value, result_unit, result_type, reference_range,
              reference_low, reference_high, flag, is_abnormal, is_critical,
              previous_value, previous_date, trend, interpretation, notes,
              display_order, resulted_at, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            orderId,
            patientId,
            name,
            code,
            '',
            resultValue,
            resultUnit,
            'numeric',
            referenceRange,
            null,
            null,
            flag,
            isAbnormal ? 1 : 0,
            0,
            '',
            null,
            '',
            '',
            '',
            i,
            resultDate,
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        }
      } catch (e) {
        print('Error migrating lab order $orderId: $e');
      }
    }

    return migrated;
  }

  /// Migrate progressNotes from TreatmentGoals
  Future<int> _migrateProgressNotes() async {
    int migrated = 0;

    final goals = await _db.customSelect(
      'SELECT id, patient_id, progress_notes FROM treatment_goals WHERE progress_notes IS NOT NULL AND progress_notes != "" AND progress_notes != "[]"',
    ).get();

    for (final row in goals) {
      final goalId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final notesJson = row.read<String?>('progress_notes');

      if (notesJson == null || notesJson.isEmpty) continue;

      try {
        final notes = jsonDecode(notesJson);
        if (notes is! List) continue;

        for (final note in notes) {
          if (note is! Map) continue;
          final map = Map<String, dynamic>.from(note);

          await _db.customStatement('''
            INSERT INTO progress_note_entries (
              treatment_goal_id, patient_id, encounter_id,
              entry_date, note, progress_rating, progress_status,
              barriers, interventions_used, next_steps, recorded_by, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            goalId,
            patientId,
            map['encounterId'],
            map['date'] ?? DateTime.now().millisecondsSinceEpoch,
            map['note'] ?? map['content'] ?? '',
            map['rating'] ?? map['progressRating'],
            map['status'] ?? map['progressStatus'] ?? '',
            map['barriers'] ?? '',
            map['interventions'] ?? '',
            map['nextSteps'] ?? '',
            map['recordedBy'] ?? '',
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        }
      } catch (e) {
        print('Error migrating progress notes for goal $goalId: $e');
      }
    }

    return migrated;
  }

  /// Migrate interventionsUsed from TreatmentSessions and TreatmentGoals
  Future<int> _migrateTreatmentInterventions() async {
    int migrated = 0;

    // From treatment sessions
    final sessions = await _db.customSelect(
      'SELECT id, patient_id, interventions_used, session_date FROM treatment_sessions WHERE interventions_used IS NOT NULL AND interventions_used != "" AND interventions_used != "[]"',
    ).get();

    for (final row in sessions) {
      final sessionId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final interventionsJson = row.read<String?>('interventions_used');
      final sessionDate = row.read<int?>('session_date') ?? DateTime.now().millisecondsSinceEpoch;

      migrated += await _migrateInterventionList(
        interventionsJson,
        patientId,
        sessionId,
        null,
        sessionDate,
      );
    }

    // From treatment goals
    final goals = await _db.customSelect(
      'SELECT id, patient_id, interventions FROM treatment_goals WHERE interventions IS NOT NULL AND interventions != "" AND interventions != "[]"',
    ).get();

    for (final row in goals) {
      final goalId = row.read<int>('id');
      final patientId = row.read<int>('patient_id');
      final interventionsJson = row.read<String?>('interventions');

      migrated += await _migrateInterventionList(
        interventionsJson,
        patientId,
        null,
        goalId,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    return migrated;
  }

  Future<int> _migrateInterventionList(
    String? interventionsJson,
    int patientId,
    int? sessionId,
    int? goalId,
    int usedAt,
  ) async {
    if (interventionsJson == null || interventionsJson.isEmpty) return 0;
    int migrated = 0;

    try {
      final interventions = jsonDecode(interventionsJson);
      if (interventions is! List) return 0;

      for (final intervention in interventions) {
        String name;
        String type = 'therapeutic';
        String modality = '';
        String effectiveness = '';
        String notes = '';

        if (intervention is String) {
          name = intervention;
        } else if (intervention is Map) {
          name = (intervention['name'] ?? '').toString();
          type = (intervention['type'] ?? 'therapeutic').toString();
          modality = (intervention['modality'] ?? '').toString();
          effectiveness = (intervention['effectiveness'] ?? '').toString();
          notes = (intervention['notes'] ?? '').toString();
        } else {
          continue;
        }

        await _db.customStatement('''
          INSERT INTO treatment_interventions (
            treatment_session_id, treatment_goal_id, patient_id,
            intervention_name, intervention_type, modality,
            effectiveness, effectiveness_rating, patient_response,
            notes, used_at, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          sessionId,
          goalId,
          patientId,
          name,
          type,
          modality,
          effectiveness,
          null,
          '',
          notes,
          usedAt,
          DateTime.now().millisecondsSinceEpoch,
        ]);
        migrated++;
      }
    } catch (e) {
      print('Error migrating interventions: $e');
    }

    return migrated;
  }

  /// Migrate diagnosisCodes/procedureCodes from InsuranceClaims
  Future<int> _migrateClaimBillingCodes() async {
    int migrated = 0;

    final claims = await _db.customSelect(
      'SELECT id, diagnosis_codes, procedure_codes, modifiers FROM insurance_claims WHERE diagnosis_codes IS NOT NULL OR procedure_codes IS NOT NULL',
    ).get();

    for (final row in claims) {
      final claimId = row.read<int>('id');
      final diagnosisCodesJson = row.read<String?>('diagnosis_codes');
      final procedureCodesJson = row.read<String?>('procedure_codes');
      final modifiersJson = row.read<String?>('modifiers');

      try {
        // Migrate diagnosis codes
        if (diagnosisCodesJson != null && diagnosisCodesJson.isNotEmpty) {
          final codes = jsonDecode(diagnosisCodesJson);
          if (codes is List) {
            int order = 0;
            for (final code in codes) {
              await _db.customStatement('''
                INSERT INTO claim_billing_codes (
                  claim_id, code_type, code, description, charged_amount,
                  units, place_of_service, linked_procedure_id, display_order,
                  is_primary, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''', [
                claimId,
                'diagnosis',
                code.toString(),
                '',
                null,
                1,
                '',
                null,
                order,
                order == 0 ? 1 : 0,
                DateTime.now().millisecondsSinceEpoch,
              ]);
              order++;
              migrated++;
            }
          }
        }

        // Migrate procedure codes
        if (procedureCodesJson != null && procedureCodesJson.isNotEmpty) {
          final codes = jsonDecode(procedureCodesJson);
          if (codes is List) {
            int order = 0;
            for (final code in codes) {
              String codeStr;
              double? amount;
              int units = 1;

              if (code is String) {
                codeStr = code;
              } else if (code is Map) {
                codeStr = code['code']?.toString() ?? '';
                final dynamic amountValue = code['amount'] ?? code['chargedAmount'];
                amount = amountValue != null ? (amountValue as num).toDouble() : null;
                units = (code['units'] as int?) ?? 1;
              } else {
                continue;
              }

              await _db.customStatement('''
                INSERT INTO claim_billing_codes (
                  claim_id, code_type, code, description, charged_amount,
                  units, place_of_service, linked_procedure_id, display_order,
                  is_primary, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''', [
                claimId,
                'procedure',
                codeStr,
                '',
                amount,
                units,
                '',
                null,
                order,
                0,
                DateTime.now().millisecondsSinceEpoch,
              ]);
              order++;
              migrated++;
            }
          }
        }

        // Migrate modifiers
        if (modifiersJson != null && modifiersJson.isNotEmpty) {
          final modifiers = jsonDecode(modifiersJson);
          if (modifiers is List) {
            for (final modifier in modifiers) {
              await _db.customStatement('''
                INSERT INTO claim_billing_codes (
                  claim_id, code_type, code, description, charged_amount,
                  units, place_of_service, linked_procedure_id, display_order,
                  is_primary, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ''', [
                claimId,
                'modifier',
                modifier.toString(),
                '',
                null,
                1,
                '',
                null,
                0,
                0,
                DateTime.now().millisecondsSinceEpoch,
              ]);
              migrated++;
            }
          }
        }
      } catch (e) {
        print('Error migrating claim $claimId: $e');
      }
    }

    return migrated;
  }

  /// Migrate allergies from Patients.allergies (comma-separated)
  Future<int> _migratePatientAllergies() async {
    int migrated = 0;

    final patients = await _db.customSelect(
      'SELECT id, allergies FROM patients WHERE allergies IS NOT NULL AND allergies != ""',
    ).get();

    for (final row in patients) {
      final patientId = row.read<int>('id');
      final allergiesText = row.read<String?>('allergies');

      if (allergiesText == null || allergiesText.isEmpty) continue;

      // Split by comma, semicolon, or newline
      final allergies = allergiesText
          .split(RegExp(r'[,;\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final allergen in allergies) {
        try {
          await _db.customStatement('''
            INSERT INTO patient_allergies (
              patient_id, allergen, allergen_type, allergen_code,
              reaction_type, reaction_severity, reaction_description,
              status, verified, verified_at, onset_date,
              recorded_date, source, notes, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            patientId,
            allergen,
            _categorizeAllergen(allergen),
            '',
            '',
            'moderate',
            '',
            'active',
            0,
            null,
            null,
            DateTime.now().millisecondsSinceEpoch,
            'patient',
            '',
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        } catch (e) {
          print('Error migrating allergy "$allergen" for patient $patientId: $e');
        }
      }
    }

    return migrated;
  }

  /// Migrate chronic conditions from Patients.chronicConditions (comma-separated)
  Future<int> _migrateChronicConditions() async {
    int migrated = 0;

    final patients = await _db.customSelect(
      'SELECT id, chronic_conditions FROM patients WHERE chronic_conditions IS NOT NULL AND chronic_conditions != ""',
    ).get();

    for (final row in patients) {
      final patientId = row.read<int>('id');
      final conditionsText = row.read<String?>('chronic_conditions');

      if (conditionsText == null || conditionsText.isEmpty) continue;

      final conditions = conditionsText
          .split(RegExp(r'[,;\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final condition in conditions) {
        try {
          await _db.customStatement('''
            INSERT INTO patient_chronic_conditions (
              patient_id, diagnosis_id, condition_name, icd_code, category,
              status, severity, onset_date, diagnosed_date,
              current_treatment, managing_provider, last_review_date,
              next_review_date, notes, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            patientId,
            null,
            condition,
            '',
            _categorizeCondition(condition),
            'active',
            'moderate',
            null,
            null,
            '',
            '',
            null,
            null,
            '',
            DateTime.now().millisecondsSinceEpoch,
          ]);
          migrated++;
        } catch (e) {
          print('Error migrating condition "$condition" for patient $patientId: $e');
        }
      }
    }

    return migrated;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS - Auto-categorization
  // ═══════════════════════════════════════════════════════════════════════════

  String _categorizeCondition(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('diabet') || lower.contains('thyroid') || lower.contains('hormone')) {
      return 'endocrine';
    }
    if (lower.contains('heart') || lower.contains('hypertension') || lower.contains('cardiac') || lower.contains('bp')) {
      return 'cardiovascular';
    }
    if (lower.contains('cancer') || lower.contains('tumor') || lower.contains('malignant')) {
      return 'cancer';
    }
    if (lower.contains('depress') || lower.contains('anxiety') || lower.contains('bipolar') || lower.contains('schizo')) {
      return 'psychiatric';
    }
    if (lower.contains('asthma') || lower.contains('copd') || lower.contains('lung')) {
      return 'respiratory';
    }
    if (lower.contains('kidney') || lower.contains('renal')) {
      return 'renal';
    }
    if (lower.contains('liver') || lower.contains('hepat')) {
      return 'gastrointestinal';
    }
    if (lower.contains('stroke') || lower.contains('epilep') || lower.contains('parkinson') || lower.contains('alzheimer')) {
      return 'neurological';
    }
    if (lower.contains('arthritis') || lower.contains('osteo')) {
      return 'musculoskeletal';
    }
    return 'other';
  }

  String _categorizeSymptom(String symptom) {
    final lower = symptom.toLowerCase();
    if (lower.contains('depress') || lower.contains('mood') || lower.contains('sad')) {
      return 'mood';
    }
    if (lower.contains('anxi') || lower.contains('worry') || lower.contains('panic')) {
      return 'anxiety';
    }
    if (lower.contains('sleep') || lower.contains('insomnia')) {
      return 'sleep';
    }
    if (lower.contains('appetite') || lower.contains('eat') || lower.contains('weight')) {
      return 'appetite';
    }
    if (lower.contains('energy') || lower.contains('fatigue') || lower.contains('tired')) {
      return 'energy';
    }
    if (lower.contains('concentra') || lower.contains('focus') || lower.contains('memory')) {
      return 'cognitive';
    }
    if (lower.contains('social') || lower.contains('isolat')) {
      return 'social';
    }
    if (lower.contains('halluc') || lower.contains('delus') || lower.contains('paranoi')) {
      return 'psychotic';
    }
    return 'other';
  }

  String _categorizeSideEffect(String effect) {
    final lower = effect.toLowerCase();
    if (lower.contains('nausea') || lower.contains('vomit') || lower.contains('diarrhea') || lower.contains('constip')) {
      return 'gastrointestinal';
    }
    if (lower.contains('dizz') || lower.contains('headache') || lower.contains('sedation') || lower.contains('drowsy')) {
      return 'neurological';
    }
    if (lower.contains('rash') || lower.contains('itch') || lower.contains('skin')) {
      return 'dermatological';
    }
    if (lower.contains('heart') || lower.contains('palpitation') || lower.contains('bp')) {
      return 'cardiovascular';
    }
    if (lower.contains('weight') || lower.contains('appetite') || lower.contains('metabol')) {
      return 'metabolic';
    }
    if (lower.contains('sexual') || lower.contains('libido') || lower.contains('erectile')) {
      return 'sexual';
    }
    if (lower.contains('muscle') || lower.contains('joint') || lower.contains('pain')) {
      return 'musculoskeletal';
    }
    return 'other';
  }

  String _categorizeAllergen(String allergen) {
    final lower = allergen.toLowerCase();
    // Check for common drug names/classes
    final drugKeywords = [
      'penicillin', 'amoxicillin', 'aspirin', 'ibuprofen', 'sulfa', 'codeine',
      'morphine', 'nsaid', 'antibiotic', 'cillin', 'mycin', 'statin'
    ];
    if (drugKeywords.any((d) => lower.contains(d))) {
      return 'medication';
    }
    // Check for food allergens
    final foodKeywords = [
      'peanut', 'nut', 'shellfish', 'fish', 'milk', 'egg', 'wheat', 'soy',
      'gluten', 'dairy', 'lactose'
    ];
    if (foodKeywords.any((f) => lower.contains(f))) {
      return 'food';
    }
    // Check for environmental
    final envKeywords = [
      'pollen', 'dust', 'mite', 'mold', 'pet', 'cat', 'dog', 'grass', 'ragweed'
    ];
    if (envKeywords.any((e) => lower.contains(e))) {
      return 'environmental';
    }
    if (lower.contains('latex')) return 'latex';
    if (lower.contains('contrast') || lower.contains('dye')) return 'contrast';
    return 'other';
  }

  String _categorizeAttachment(String extension, String entityType) {
    final lower = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(lower)) {
      return 'image';
    }
    if (['pdf'].contains(lower)) {
      if (entityType == 'referral') return 'referral_letter';
      if (entityType == 'clinical_note') return 'report';
      return 'report';
    }
    if (['doc', 'docx'].contains(lower)) {
      return 'report';
    }
    return 'other';
  }
}

/// Result of the migration process
class MigrationResult {
  bool success = false;
  String? error;
  String? stackTrace;

  int prescriptionMedications = 0;
  int invoiceLineItems = 0;
  int familyConditions = 0;
  int treatmentSymptoms = 0;
  int sideEffects = 0;
  int attachments = 0;
  int mentalStatusExams = 0;
  int labTestResults = 0;
  int progressNotes = 0;
  int treatmentInterventions = 0;
  int claimBillingCodes = 0;
  int patientAllergies = 0;
  int chronicConditions = 0;

  int get totalMigrated =>
      prescriptionMedications +
      invoiceLineItems +
      familyConditions +
      treatmentSymptoms +
      sideEffects +
      attachments +
      mentalStatusExams +
      labTestResults +
      progressNotes +
      treatmentInterventions +
      claimBillingCodes +
      patientAllergies +
      chronicConditions;

  @override
  String toString() {
    return '''
MigrationResult:
  Success: $success
  ${error != null ? 'Error: $error\n' : ''}
  Records Migrated:
    - Prescription Medications: $prescriptionMedications
    - Invoice Line Items: $invoiceLineItems
    - Family Conditions: $familyConditions
    - Treatment Symptoms: $treatmentSymptoms
    - Side Effects: $sideEffects
    - Attachments: $attachments
    - Mental Status Exams: $mentalStatusExams
    - Lab Test Results: $labTestResults
    - Progress Notes: $progressNotes
    - Treatment Interventions: $treatmentInterventions
    - Claim Billing Codes: $claimBillingCodes
    - Patient Allergies: $patientAllergies
    - Chronic Conditions: $chronicConditions
  ─────────────────────────────
  Total Migrated: $totalMigrated
''';
  }
}
