import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/family_history.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef FamilyHistoryData = FamilyMedicalHistoryData;

/// Service for managing family medical history
class FamilyHistoryService {
  FamilyHistoryService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create family history entry
  Future<int> createFamilyHistory({
    required int patientId,
    required String relationship,
    String? relativeName,
    int? relativeAge,
    bool? isDeceased,
    int? ageAtDeath,
    String? causeOfDeath,
    String? conditions,
    String? conditionDetails,
    bool? hasHeartDisease,
    bool? hasDiabetes,
    bool? hasCancer,
    String? cancerTypes,
    bool? hasHypertension,
    bool? hasStroke,
    bool? hasMentalIllness,
    String? mentalIllnessTypes,
    bool? hasSubstanceAbuse,
    bool? hasGeneticDisorder,
    String? geneticDisorderTypes,
    String? notes,
  }) async {
    final id = await _db.into(_db.familyMedicalHistory).insert(
      FamilyMedicalHistoryCompanion.insert(
        patientId: patientId,
        relationship: relationship,
        relativeName: Value(relativeName ?? ''),
        relativeAge: Value(relativeAge),
        isDeceased: Value(isDeceased ?? false),
        ageAtDeath: Value(ageAtDeath),
        causeOfDeath: Value(causeOfDeath ?? ''),
        conditions: Value(conditions ?? ''),
        conditionDetails: Value(conditionDetails ?? ''),
        hasHeartDisease: Value(hasHeartDisease ?? false),
        hasDiabetes: Value(hasDiabetes ?? false),
        hasCancer: Value(hasCancer ?? false),
        cancerTypes: Value(cancerTypes ?? ''),
        hasHypertension: Value(hasHypertension ?? false),
        hasStroke: Value(hasStroke ?? false),
        hasMentalIllness: Value(hasMentalIllness ?? false),
        mentalIllnessTypes: Value(mentalIllnessTypes ?? ''),
        hasSubstanceAbuse: Value(hasSubstanceAbuse ?? false),
        hasGeneticDisorder: Value(hasGeneticDisorder ?? false),
        geneticDisorderTypes: Value(geneticDisorderTypes ?? ''),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.familyHistory,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_family_history', 'relationship': relationship},
    );

    if (kDebugMode) {
      print('[FamilyHistoryService] Created family history $id for patient $patientId');
    }

    return id;
  }

  /// Get all family history for a patient
  Future<List<FamilyMedicalHistoryData>> getFamilyHistoryForPatient(int patientId) async {
    return (_db.select(_db.familyMedicalHistory)
          ..where((f) => f.patientId.equals(patientId))
          ..orderBy([(f) => OrderingTerm.asc(f.relationship)]))
        .get();
  }

  /// Get family history by ID
  Future<FamilyMedicalHistoryData?> getFamilyHistoryById(int id) async {
    return (_db.select(_db.familyMedicalHistory)..where((f) => f.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get family history by relationship
  Future<List<FamilyMedicalHistoryData>> getFamilyHistoryByRelationship(
    int patientId,
    String relationship,
  ) async {
    return (_db.select(_db.familyMedicalHistory)
          ..where((f) => f.patientId.equals(patientId) & f.relationship.equals(relationship)))
        .get();
  }

  /// Get family history with specific condition
  Future<List<FamilyMedicalHistoryData>> getFamilyHistoryWithCondition(
    int patientId,
    String condition,
  ) async {
    return (_db.select(_db.familyMedicalHistory)
          ..where((f) => f.patientId.equals(patientId) & f.conditions.contains(condition)))
        .get();
  }

  /// Update family history
  Future<bool> updateFamilyHistory({
    required int id,
    String? relationship,
    String? relativeName,
    int? relativeAge,
    bool? isDeceased,
    int? ageAtDeath,
    String? causeOfDeath,
    String? conditions,
    String? notes,
  }) async {
    final existing = await getFamilyHistoryById(id);
    if (existing == null) return false;

    await (_db.update(_db.familyMedicalHistory)..where((f) => f.id.equals(id)))
        .write(FamilyMedicalHistoryCompanion(
          relationship: relationship != null ? Value(relationship) : const Value.absent(),
          relativeName: relativeName != null ? Value(relativeName) : const Value.absent(),
          relativeAge: relativeAge != null ? Value(relativeAge) : const Value.absent(),
          isDeceased: isDeceased != null ? Value(isDeceased) : const Value.absent(),
          ageAtDeath: ageAtDeath != null ? Value(ageAtDeath) : const Value.absent(),
          causeOfDeath: causeOfDeath != null ? Value(causeOfDeath) : const Value.absent(),
          conditions: conditions != null ? Value(conditions) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.familyHistory,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_family_history'},
    );

    return true;
  }

  /// Delete family history entry
  Future<bool> deleteFamilyHistory(int id) async {
    final existing = await getFamilyHistoryById(id);
    if (existing == null) return false;

    await (_db.delete(_db.familyMedicalHistory)..where((f) => f.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.familyHistory,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_family_history'},
    );

    return true;
  }

  /// Check for hereditary risk factors
  Future<Map<String, List<String>>> getHereditaryRiskFactors(int patientId) async {
    final history = await getFamilyHistoryForPatient(patientId);
    
    final risks = <String, List<String>>{
      'heart_disease': [],
      'diabetes': [],
      'cancer': [],
      'hypertension': [],
      'stroke': [],
      'mental_illness': [],
      'substance_abuse': [],
      'genetic_disorder': [],
    };

    for (final entry in history) {
      if (entry.hasHeartDisease) risks['heart_disease']!.add(entry.relationship);
      if (entry.hasDiabetes) risks['diabetes']!.add(entry.relationship);
      if (entry.hasCancer) risks['cancer']!.add(entry.relationship);
      if (entry.hasHypertension) risks['hypertension']!.add(entry.relationship);
      if (entry.hasStroke) risks['stroke']!.add(entry.relationship);
      if (entry.hasMentalIllness) risks['mental_illness']!.add(entry.relationship);
      if (entry.hasSubstanceAbuse) risks['substance_abuse']!.add(entry.relationship);
      if (entry.hasGeneticDisorder) risks['genetic_disorder']!.add(entry.relationship);
    }

    return risks;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get hereditary risk assessment (screen compatibility alias)
  Future<Map<String, List<String>>> getHereditaryRiskAssessment(int patientId) async {
    return getHereditaryRiskFactors(patientId);
  }

  /// Delete family history entry (screen compatibility)
  Future<bool> deleteFamilyHistoryEntry(int id) async {
    return deleteFamilyHistory(id);
  }

  /// Update family history entry (screen compatibility)
  /// Accepts `condition`, `ageAtOnset`, `relativeAge` as screen aliases
  Future<bool> updateFamilyHistoryEntry({
    required int id,
    String? relationship,
    String? condition,  // alias for conditions
    int? ageAtOnset,    // alias for relativeAge
    int? relativeAge,   // direct
    String? notes,
    bool? isDeceased,
    int? ageAtDeath,
    String? causeOfDeath,
  }) async {
    return updateFamilyHistory(
      id: id,
      relationship: relationship,
      conditions: condition,
      relativeAge: ageAtOnset ?? relativeAge,
      notes: notes,
      isDeceased: isDeceased,
      ageAtDeath: ageAtDeath,
      causeOfDeath: causeOfDeath,
    );
  }

  /// Add family history entry (screen compatibility)
  /// Accepts `condition`, `ageAtOnset`, `relativeAge` as screen aliases
  Future<int> addFamilyHistoryEntry({
    required int patientId,
    required String relationship,
    String? condition,  // alias for conditions
    int? ageAtOnset,    // alias for relativeAge
    int? relativeAge,   // direct
    String? notes,
    bool? isDeceased,
    int? ageAtDeath,
    String? causeOfDeath,
  }) async {
    final familyHistoryId = await createFamilyHistory(
      patientId: patientId,
      relationship: relationship,
      conditions: '', // V5: Use FamilyConditions table instead
      relativeAge: ageAtOnset ?? relativeAge,
      notes: notes,
      isDeceased: isDeceased,
      ageAtDeath: ageAtDeath,
      causeOfDeath: causeOfDeath,
    );
    
    // V5: Save condition to normalized FamilyConditions table
    if (condition != null && condition.isNotEmpty) {
      await _db.insertFamilyCondition(
        FamilyConditionsCompanion.insert(
          familyHistoryId: familyHistoryId,
          patientId: patientId,
          conditionName: condition,
          ageAtOnset: Value(ageAtOnset),
        ),
      );
    }
    
    return familyHistoryId;
  }

  /// Convert to model (screen compatibility)
  FamilyHistoryModel toModel(FamilyHistoryData entry) {
    return FamilyHistoryModel(
      id: entry.id,
      patientId: entry.patientId,
      relationship: FamilyRelationship.fromValue(entry.relationship),
      notes: entry.notes,
      isDeceased: entry.isDeceased,
      ageAtDeath: entry.ageAtDeath,
      causeOfDeath: entry.causeOfDeath,
      createdAt: entry.createdAt,
    );
  }
}
