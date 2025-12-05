import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';

/// Service for managing clinical encounters
/// 
/// Encounters are the central hub for each patient visit. All clinical data
/// (vitals, notes, diagnoses, prescriptions) links to an encounter.
class EncounterService {
  EncounterService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  // ═══════════════════════════════════════════════════════════════════════════════
  // ENCOUNTER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Start a new encounter for a patient
  Future<int> startEncounter({
    required int patientId,
    int? appointmentId,
    String chiefComplaint = '',
    String encounterType = 'outpatient',
    String providerName = '',
    String providerType = 'psychiatrist',
  }) async {
    final now = DateTime.now();
    
    final encounterId = await _db.insertEncounter(EncountersCompanion.insert(
      patientId: patientId,
      appointmentId: Value(appointmentId),
      encounterDate: now,
      encounterType: Value(encounterType),
      status: const Value('in_progress'),
      chiefComplaint: Value(chiefComplaint),
      providerName: Value(providerName),
      providerType: Value(providerType),
      checkInTime: Value(now),
    ));

    // Update appointment status if linked
    if (appointmentId != null) {
      final appointment = await _db.getAppointmentById(appointmentId);
      if (appointment != null) {
        await _db.updateAppointment(AppointmentsCompanion(
          id: Value(appointment.id),
          patientId: Value(appointment.patientId),
          appointmentDateTime: Value(appointment.appointmentDateTime),
          status: const Value('in_progress'),
        ));
      }
    }

    await _auditService.log(
      action: AuditAction.createAppointment,
      entityType: AuditEntityType.appointment,
      entityId: encounterId,
      patientId: patientId,
      afterData: {'action': 'start_encounter', 'type': encounterType},
    );

    if (kDebugMode) {
      print('[EncounterService] Started encounter $encounterId for patient $patientId');
    }

    return encounterId;
  }

  /// Start an encounter from an existing appointment
  Future<int> startEncounterFromAppointment(int appointmentId) async {
    final appointment = await _db.getAppointmentById(appointmentId);
    if (appointment == null) {
      throw Exception('Appointment not found');
    }

    // Check if encounter already exists for this appointment
    final existingEncounter = await _db.getEncounterByAppointmentId(appointmentId);
    if (existingEncounter != null) {
      return existingEncounter.id;
    }

    return startEncounter(
      patientId: appointment.patientId,
      appointmentId: appointmentId,
      chiefComplaint: appointment.reason,
      encounterType: 'outpatient',
    );
  }

  /// Complete an encounter
  Future<bool> completeEncounter(int encounterId) async {
    final encounter = await _db.getEncounterById(encounterId);
    if (encounter == null) return false;

    final result = await _db.completeEncounter(encounterId);

    // Update linked appointment status
    if (encounter.appointmentId != null) {
      final appointment = await _db.getAppointmentById(encounter.appointmentId!);
      if (appointment != null) {
        await _db.updateAppointment(AppointmentsCompanion(
          id: Value(appointment.id),
          patientId: Value(appointment.patientId),
          appointmentDateTime: Value(appointment.appointmentDateTime),
          status: const Value('completed'),
        ));
      }
    }

    await _auditService.log(
      action: AuditAction.completeAppointment,
      entityType: AuditEntityType.appointment,
      entityId: encounterId,
      patientId: encounter.patientId,
      afterData: {'action': 'complete_encounter'},
    );

    return result;
  }

  /// Update encounter status
  Future<bool> updateEncounterStatus(int encounterId, String status) async {
    final encounter = await _db.getEncounterById(encounterId);
    if (encounter == null) return false;

    return _db.updateEncounter(EncountersCompanion(
      id: Value(encounterId),
      patientId: Value(encounter.patientId),
      appointmentId: Value(encounter.appointmentId),
      encounterDate: Value(encounter.encounterDate),
      encounterType: Value(encounter.encounterType),
      status: Value(status),
      chiefComplaint: Value(encounter.chiefComplaint),
      providerName: Value(encounter.providerName),
      providerType: Value(encounter.providerType),
      isBillable: Value(encounter.isBillable),
      invoiceId: Value(encounter.invoiceId),
      checkInTime: Value(encounter.checkInTime),
      checkOutTime: Value(status == 'completed' ? DateTime.now() : encounter.checkOutTime),
    ));
  }

  /// Get encounter by ID
  Future<Encounter?> getEncounter(int id) => _db.getEncounterById(id);

  /// Get all encounters for a patient
  Future<List<Encounter>> getPatientEncounters(int patientId) =>
      _db.getEncountersForPatient(patientId);

  /// Get today's encounters
  Future<List<Encounter>> getTodaysEncounters() => _db.getTodaysEncounters();

  /// Get active (in-progress) encounters
  Future<List<Encounter>> getActiveEncounters() => _db.getActiveEncounters();

  /// Get encounter for an appointment
  Future<Encounter?> getEncounterForAppointment(int appointmentId) =>
      _db.getEncounterByAppointmentId(appointmentId);

  // ═══════════════════════════════════════════════════════════════════════════════
  // VITAL SIGNS - Record vitals during encounter
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Record vital signs for an encounter
  Future<int> recordVitals({
    required int encounterId,
    required int patientId,
    double? systolicBp,
    double? diastolicBp,
    int? heartRate,
    double? temperature,
    int? respiratoryRate,
    double? oxygenSaturation,
    double? weight,
    double? height,
    int? painLevel,
    String? bloodGlucose,
    String? notes,
  }) async {
    final vitalId = await _db.into(_db.vitalSigns).insert(VitalSignsCompanion.insert(
      patientId: patientId,
      encounterId: Value(encounterId),
      recordedAt: DateTime.now(),
      systolicBp: Value(systolicBp),
      diastolicBp: Value(diastolicBp),
      heartRate: Value(heartRate),
      temperature: Value(temperature),
      respiratoryRate: Value(respiratoryRate),
      oxygenSaturation: Value(oxygenSaturation),
      weight: Value(weight),
      height: Value(height),
      bmi: Value(weight != null && height != null && height > 0 
          ? weight / ((height / 100) * (height / 100)) 
          : null),
      painLevel: Value(painLevel),
      bloodGlucose: Value(bloodGlucose ?? ''),
      notes: Value(notes ?? ''),
    ));

    await _auditService.log(
      action: AuditAction.createVitalSign,
      entityType: AuditEntityType.vitalSign,
      entityId: vitalId,
      patientId: patientId,
      afterData: {'encounterId': encounterId},
    );

    return vitalId;
  }

  /// Get vitals for an encounter
  Future<List<VitalSign>> getEncounterVitals(int encounterId) =>
      _db.getVitalSignsForEncounter(encounterId);

  /// Get latest vitals for an encounter
  Future<VitalSign?> getLatestVitals(int encounterId) =>
      _db.getLatestVitalSignsForEncounter(encounterId);

  // ═══════════════════════════════════════════════════════════════════════════════
  // CLINICAL NOTES - SOAP format documentation
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Add a clinical note to an encounter
  Future<int> addClinicalNote({
    required int encounterId,
    required int patientId,
    String noteType = 'progress',
    String subjective = '',
    String objective = '',
    String assessment = '',
    String plan = '',
    String? mentalStatusExam,
    String riskLevel = 'none',
    String riskFactors = '',
    String safetyPlan = '',
  }) async {
    final noteId = await _db.insertClinicalNote(ClinicalNotesCompanion.insert(
      encounterId: encounterId,
      patientId: patientId,
      noteType: Value(noteType),
      subjective: Value(subjective),
      objective: Value(objective),
      assessment: Value(assessment),
      plan: Value(plan),
      mentalStatusExam: Value(mentalStatusExam ?? '{}'),
      riskLevel: Value(riskLevel),
      riskFactors: Value(riskFactors),
      safetyPlan: Value(safetyPlan),
    ));

    await _auditService.log(
      action: AuditAction.createMedicalRecord,
      entityType: AuditEntityType.medicalRecord,
      entityId: noteId,
      patientId: patientId,
      afterData: {'encounterId': encounterId, 'noteType': noteType},
    );

    return noteId;
  }

  /// Update a clinical note
  Future<bool> updateClinicalNote(ClinicalNote note) async {
    if (note.isLocked) {
      throw Exception('Cannot edit a locked note');
    }
    return _db.updateClinicalNote(note);
  }

  /// Sign and lock a clinical note
  Future<bool> signClinicalNote(int noteId, String signedBy) =>
      _db.signClinicalNote(noteId, signedBy);

  /// Get clinical notes for an encounter
  Future<List<ClinicalNote>> getEncounterNotes(int encounterId) =>
      _db.getClinicalNotesForEncounter(encounterId);

  /// Get all clinical notes for a patient
  Future<List<ClinicalNote>> getPatientNotes(int patientId) =>
      _db.getClinicalNotesForPatient(patientId);

  // ═══════════════════════════════════════════════════════════════════════════════
  // DIAGNOSES - Manage patient diagnoses during encounter
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Add a diagnosis for a patient
  Future<int> addDiagnosis({
    required int patientId,
    required String description,
    int? encounterId,
    String icdCode = '',
    String category = 'psychiatric',
    String severity = 'moderate',
    String status = 'active',
    DateTime? onsetDate,
    bool isPrimary = false,
    String notes = '',
  }) async {
    final diagnosisId = await _db.insertDiagnosis(DiagnosesCompanion.insert(
      patientId: patientId,
      encounterId: Value(encounterId),
      icdCode: Value(icdCode),
      description: description,
      category: Value(category),
      severity: Value(severity),
      diagnosisStatus: Value(status),
      onsetDate: Value(onsetDate),
      diagnosedDate: DateTime.now(),
      isPrimary: Value(isPrimary),
      notes: Value(notes),
    ));

    // Link to encounter if provided
    if (encounterId != null) {
      await _db.linkDiagnosisToEncounter(encounterId, diagnosisId, isNew: true);
    }

    await _auditService.log(
      action: AuditAction.createMedicalRecord,
      entityType: AuditEntityType.medicalRecord,
      entityId: diagnosisId,
      patientId: patientId,
      afterData: {
        'action': 'add_diagnosis',
        'icdCode': icdCode,
        'description': description,
      },
    );

    return diagnosisId;
  }

  /// Link an existing diagnosis to an encounter
  Future<void> linkDiagnosisToEncounter({
    required int encounterId,
    required int diagnosisId,
    bool isNew = false,
    String status = 'addressed',
    String notes = '',
  }) async {
    await _db.into(_db.encounterDiagnoses).insert(EncounterDiagnosesCompanion.insert(
      encounterId: encounterId,
      diagnosisId: diagnosisId,
      isNewDiagnosis: Value(isNew),
      encounterStatus: Value(status),
      notes: Value(notes),
    ));
  }

  /// Get all diagnoses for a patient
  Future<List<Diagnose>> getPatientDiagnoses(int patientId) =>
      _db.getDiagnosesForPatient(patientId);

  /// Get active diagnoses for a patient
  Future<List<Diagnose>> getActiveDiagnoses(int patientId) =>
      _db.getActiveDiagnosesForPatient(patientId);

  /// Get primary diagnosis for a patient
  Future<Diagnose?> getPrimaryDiagnosis(int patientId) =>
      _db.getPrimaryDiagnosisForPatient(patientId);

  /// Get diagnoses addressed in an encounter
  Future<List<Diagnose>> getEncounterDiagnoses(int encounterId) =>
      _db.getFullDiagnosesForEncounter(encounterId);

  /// Update diagnosis status
  Future<bool> updateDiagnosisStatus(int diagnosisId, String status, {DateTime? resolvedDate}) async {
    final diagnosis = await _db.getDiagnosisById(diagnosisId);
    if (diagnosis == null) return false;

    return _db.updateDiagnosis(DiagnosesCompanion(
      id: Value(diagnosisId),
      patientId: Value(diagnosis.patientId),
      encounterId: Value(diagnosis.encounterId),
      icdCode: Value(diagnosis.icdCode),
      description: Value(diagnosis.description),
      category: Value(diagnosis.category),
      severity: Value(diagnosis.severity),
      diagnosisStatus: Value(status),
      onsetDate: Value(diagnosis.onsetDate),
      diagnosedDate: Value(diagnosis.diagnosedDate),
      resolvedDate: Value(status == 'resolved' ? (resolvedDate ?? DateTime.now()) : diagnosis.resolvedDate),
      isPrimary: Value(diagnosis.isPrimary),
      displayOrder: Value(diagnosis.displayOrder),
      notes: Value(diagnosis.notes),
    ));
  }

  /// Search diagnoses (for ICD lookup)
  Future<List<Diagnose>> searchDiagnoses(String query) =>
      _db.searchDiagnoses(query);

  // ═══════════════════════════════════════════════════════════════════════════════
  // ENCOUNTER SUMMARY - Get all data for an encounter
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get complete encounter data including vitals, notes, and diagnoses
  Future<EncounterSummary> getEncounterSummary(int encounterId) async {
    final encounter = await _db.getEncounterById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found');
    }

    final patient = await _db.getPatientById(encounter.patientId);
    final vitals = await _db.getVitalSignsForEncounter(encounterId);
    final notes = await _db.getClinicalNotesForEncounter(encounterId);
    final diagnoses = await _db.getFullDiagnosesForEncounter(encounterId);
    final diagnosisLinks = await _db.getDiagnosesForEncounter(encounterId);

    return EncounterSummary(
      encounter: encounter,
      patient: patient,
      vitals: vitals,
      notes: notes,
      diagnoses: diagnoses,
      diagnosisLinks: diagnosisLinks,
    );
  }
}

/// Data class containing all encounter information
class EncounterSummary {
  EncounterSummary({
    required this.encounter,
    required this.vitals,
    required this.notes,
    required this.diagnoses,
    required this.diagnosisLinks,
    this.patient,
  });

  final Encounter encounter;
  final Patient? patient;
  final List<VitalSign> vitals;
  final List<ClinicalNote> notes;
  final List<Diagnose> diagnoses;
  final List<EncounterDiagnose> diagnosisLinks;

  /// Get latest vital signs
  VitalSign? get latestVitals => vitals.isNotEmpty ? vitals.first : null;

  /// Get primary note
  ClinicalNote? get primaryNote => notes.isNotEmpty ? notes.first : null;

  /// Check if encounter has vitals recorded
  bool get hasVitals => vitals.isNotEmpty;

  /// Check if encounter has notes
  bool get hasNotes => notes.isNotEmpty;

  /// Check if encounter has diagnoses
  bool get hasDiagnoses => diagnoses.isNotEmpty;

  /// Get newly diagnosed conditions in this encounter
  List<Diagnose> get newDiagnoses {
    final newIds = diagnosisLinks
        .where((l) => l.isNewDiagnosis)
        .map((l) => l.diagnosisId)
        .toSet();
    return diagnoses.where((d) => newIds.contains(d.id)).toList();
  }
}
