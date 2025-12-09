import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/problem_list.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef ProblemData = ProblemListData;

/// Service for managing problem list
class ProblemListService {
  ProblemListService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create problem
  Future<int> createProblem({
    required int patientId,
    required String problemName,
    int? diagnosisId,
    String? icdCode,
    String? snomedCode,
    String? category,
    String? status,
    String? severity,
    String? clinicalStatus,
    int? priority,
    DateTime? onsetDate,
    DateTime? diagnosedDate,
    DateTime? resolvedDate,
    String? treatmentGoal,
    String? currentTreatment,
    bool? isChiefConcern,
    String? notes,
  }) async {
    final id = await _db.into(_db.problemList).insert(
      ProblemListCompanion.insert(
        patientId: patientId,
        problemName: problemName,
        diagnosisId: Value(diagnosisId),
        icdCode: Value(icdCode ?? ''),
        snomedCode: Value(snomedCode ?? ''),
        category: Value(category ?? 'medical'),
        status: Value(status ?? 'active'),
        severity: Value(severity ?? 'moderate'),
        clinicalStatus: Value(clinicalStatus ?? 'confirmed'),
        priority: Value(priority ?? 1),
        onsetDate: Value(onsetDate),
        diagnosedDate: Value(diagnosedDate),
        resolvedDate: Value(resolvedDate),
        treatmentGoal: Value(treatmentGoal ?? ''),
        currentTreatment: Value(currentTreatment ?? ''),
        isChiefConcern: Value(isChiefConcern ?? false),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.problemList,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_problem', 'problem': problemName},
    );

    if (kDebugMode) {
      print('[ProblemListService] Created problem $id for patient $patientId');
    }

    return id;
  }

  /// Get all problems for a patient
  Future<List<ProblemListData>> getProblemsForPatient(int patientId) async {
    return (_db.select(_db.problemList)
          ..where((p) => p.patientId.equals(patientId))
          ..orderBy([(p) => OrderingTerm.asc(p.priority), (p) => OrderingTerm.asc(p.problemName)]))
        .get();
  }

  /// Get active problems
  Future<List<ProblemListData>> getActiveProblems(int patientId) async {
    return (_db.select(_db.problemList)
          ..where((p) => p.patientId.equals(patientId) & p.status.equals('active'))
          ..orderBy([(p) => OrderingTerm.asc(p.priority)]))
        .get();
  }

  /// Get problem by ID
  Future<ProblemListData?> getProblemById(int id) async {
    return (_db.select(_db.problemList)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get problems by category
  Future<List<ProblemListData>> getProblemsByCategory(int patientId, String category) async {
    return (_db.select(_db.problemList)
          ..where((p) => p.patientId.equals(patientId) & p.category.equals(category))
          ..orderBy([(p) => OrderingTerm.asc(p.priority)]))
        .get();
  }

  /// Update problem
  Future<bool> updateProblem({
    required int id,
    String? problemName,
    String? icdCode,
    String? status,
    String? severity,
    String? clinicalStatus,
    int? priority,
    DateTime? onsetDate,
    DateTime? resolvedDate,
    String? treatmentGoal,
    String? currentTreatment,
    String? notes,
  }) async {
    final existing = await getProblemById(id);
    if (existing == null) return false;

    await (_db.update(_db.problemList)..where((p) => p.id.equals(id)))
        .write(ProblemListCompanion(
          problemName: problemName != null ? Value(problemName) : const Value.absent(),
          icdCode: icdCode != null ? Value(icdCode) : const Value.absent(),
          status: status != null ? Value(status) : const Value.absent(),
          severity: severity != null ? Value(severity) : const Value.absent(),
          clinicalStatus: clinicalStatus != null ? Value(clinicalStatus) : const Value.absent(),
          priority: priority != null ? Value(priority) : const Value.absent(),
          onsetDate: onsetDate != null ? Value(onsetDate) : const Value.absent(),
          resolvedDate: resolvedDate != null ? Value(resolvedDate) : const Value.absent(),
          treatmentGoal: treatmentGoal != null ? Value(treatmentGoal) : const Value.absent(),
          currentTreatment: currentTreatment != null ? Value(currentTreatment) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
          lastReviewedDate: Value(DateTime.now()),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.problemList,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_problem'},
    );

    return true;
  }

  /// Resolve problem
  Future<bool> resolveProblem(int id, {String? notes}) async {
    return updateProblem(
      id: id,
      status: 'resolved',
      resolvedDate: DateTime.now(),
      notes: notes,
    );
  }

  /// Delete problem
  Future<bool> deleteProblem(int id) async {
    final existing = await getProblemById(id);
    if (existing == null) return false;

    await (_db.delete(_db.problemList)..where((p) => p.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.problemList,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_problem'},
    );

    return true;
  }

  /// Get problem summary
  Future<Map<String, dynamic>> getProblemSummary(int patientId) async {
    final problems = await getProblemsForPatient(patientId);
    
    final byCategory = <String, int>{};
    for (final problem in problems) {
      byCategory[problem.category] = (byCategory[problem.category] ?? 0) + 1;
    }

    return {
      'total': problems.length,
      'active': problems.where((p) => p.status == 'active').length,
      'chronic': problems.where((p) => p.status == 'chronic').length,
      'resolved': problems.where((p) => p.status == 'resolved').length,
      'by_category': byCategory,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get chronic problems (screen compatibility)
  Future<List<ProblemData>> getChronicProblems(int patientId) async {
    return (_db.select(_db.problemList)
          ..where((p) => p.patientId.equals(patientId) & p.status.equals('chronic'))
          ..orderBy([(p) => OrderingTerm.asc(p.priority)]))
        .get();
  }

  /// Get resolved problems (screen compatibility)
  Future<List<ProblemData>> getResolvedProblems(int patientId) async {
    return (_db.select(_db.problemList)
          ..where((p) => p.patientId.equals(patientId) & p.status.equals('resolved'))
          ..orderBy([(p) => OrderingTerm.desc(p.resolvedDate)]))
        .get();
  }

  /// Get problem list for patient (screen compatibility alias)
  Future<List<ProblemData>> getProblemListForPatient(int patientId) async {
    return getProblemsForPatient(patientId);
  }

  /// Reactivate problem (screen compatibility)
  Future<bool> reactivateProblem(int id) async {
    return updateProblem(id: id, status: 'active', resolvedDate: null);
  }

  /// Add problem (screen compatibility alias)
  Future<int> addProblem({
    required int patientId,
    required String problemName,
    String? icdCode,
    DateTime? onsetDate,
    String? status,
    String? severity,
    String? notes,
  }) async {
    return createProblem(
      patientId: patientId,
      problemName: problemName,
      icdCode: icdCode,
      onsetDate: onsetDate,
      status: status,
      severity: severity,
      notes: notes,
    );
  }

  /// Convert to model (screen compatibility)
  ProblemModel toModel(ProblemData problem) {
    return ProblemModel(
      id: problem.id,
      patientId: problem.patientId,
      problemName: problem.problemName,
      icdCode: problem.icdCode,
      status: ProblemStatus.fromValue(problem.status),
      severity: ProblemSeverity.fromValue(problem.severity),
      onsetDate: problem.onsetDate,
      resolvedDate: problem.resolvedDate,
      notes: problem.notes,
    );
  }
}
