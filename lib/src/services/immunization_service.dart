import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/immunization.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef ImmunizationData = Immunization;

/// Service for managing immunizations
class ImmunizationService {
  ImmunizationService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create immunization record
  Future<int> createImmunization({
    required int patientId,
    required String vaccineName,
    required DateTime administeredDate,
    int? encounterId,
    String? vaccineCode,
    String? manufacturer,
    String? lotNumber,
    DateTime? expirationDate,
    String? administeredBy,
    String? administrationSite,
    String? route,
    String? dose,
    int? doseNumber,
    int? seriesTotal,
    String? status,
    String? refusalReason,
    String? contraindication,
    bool? hadReaction,
    String? reactionDetails,
    String? reactionSeverity,
    DateTime? nextDoseDate,
    bool? reminderSent,
    String? notes,
  }) async {
    final id = await _db.into(_db.immunizations).insert(
      ImmunizationsCompanion.insert(
        patientId: patientId,
        vaccineName: vaccineName,
        administeredDate: administeredDate,
        encounterId: Value(encounterId),
        vaccineCode: Value(vaccineCode ?? ''),
        manufacturer: Value(manufacturer ?? ''),
        lotNumber: Value(lotNumber ?? ''),
        expirationDate: Value(expirationDate),
        administeredBy: Value(administeredBy ?? ''),
        administrationSite: Value(administrationSite ?? ''),
        route: Value(route ?? 'IM'),
        dose: Value(dose ?? ''),
        doseNumber: Value(doseNumber ?? 1),
        seriesTotal: Value(seriesTotal),
        status: Value(status ?? 'administered'),
        refusalReason: Value(refusalReason ?? ''),
        contraindication: Value(contraindication ?? ''),
        hadReaction: Value(hadReaction ?? false),
        reactionDetails: Value(reactionDetails ?? ''),
        reactionSeverity: Value(reactionSeverity ?? ''),
        nextDoseDate: Value(nextDoseDate),
        reminderSent: Value(reminderSent ?? false),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.immunization,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_immunization', 'vaccine': vaccineName},
    );

    if (kDebugMode) {
      print('[ImmunizationService] Created immunization $id for patient $patientId');
    }

    return id;
  }

  /// Get all immunizations for a patient
  Future<List<Immunization>> getImmunizationsForPatient(int patientId) async {
    return (_db.select(_db.immunizations)
          ..where((i) => i.patientId.equals(patientId))
          ..orderBy([(i) => OrderingTerm.desc(i.administeredDate)]))
        .get();
  }

  /// Get immunization by ID
  Future<Immunization?> getImmunizationById(int id) async {
    return (_db.select(_db.immunizations)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get immunizations by vaccine name
  Future<List<Immunization>> getImmunizationsByVaccine(int patientId, String vaccineName) async {
    return (_db.select(_db.immunizations)
          ..where((i) => i.patientId.equals(patientId) & i.vaccineName.equals(vaccineName))
          ..orderBy([(i) => OrderingTerm.asc(i.doseNumber)]))
        .get();
  }

  /// Get due immunizations
  Future<List<Immunization>> getDueImmunizations(int patientId) async {
    final now = DateTime.now();
    return (_db.select(_db.immunizations)
          ..where((i) =>
              i.patientId.equals(patientId) &
              i.nextDoseDate.isSmallerOrEqualValue(now) &
              i.status.equals('pending'))
          ..orderBy([(i) => OrderingTerm.asc(i.nextDoseDate)]))
        .get();
  }

  /// Update immunization
  Future<bool> updateImmunization({
    required int id,
    String? status,
    DateTime? administeredDate,
    String? administeredBy,
    bool? hadReaction,
    String? reactionDetails,
    String? notes,
  }) async {
    final existing = await getImmunizationById(id);
    if (existing == null) return false;

    await (_db.update(_db.immunizations)..where((i) => i.id.equals(id)))
        .write(ImmunizationsCompanion(
          status: status != null ? Value(status) : const Value.absent(),
          administeredDate: administeredDate != null ? Value(administeredDate) : const Value.absent(),
          administeredBy: administeredBy != null ? Value(administeredBy) : const Value.absent(),
          hadReaction: hadReaction != null ? Value(hadReaction) : const Value.absent(),
          reactionDetails: reactionDetails != null ? Value(reactionDetails) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.immunization,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_immunization'},
    );

    return true;
  }

  /// Delete immunization
  Future<bool> deleteImmunization(int id) async {
    final existing = await getImmunizationById(id);
    if (existing == null) return false;

    await (_db.delete(_db.immunizations)..where((i) => i.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.immunization,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_immunization'},
    );

    return true;
  }

  /// Get immunization summary
  Future<Map<String, dynamic>> getImmunizationSummary(int patientId) async {
    final immunizations = await getImmunizationsForPatient(patientId);
    
    final administered = immunizations.where((i) => i.status == 'administered').length;
    final pending = immunizations.where((i) => i.status == 'pending').length;
    final refused = immunizations.where((i) => i.status == 'refused').length;
    
    return {
      'total': immunizations.length,
      'administered': administered,
      'pending': pending,
      'refused': refused,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Record immunization (screen compatibility)
  Future<int> recordImmunization({
    required int patientId,
    required String vaccineName,
    DateTime? administeredDate,
    DateTime? dateAdministered,
    String? vaccineCode,
    String? manufacturer,
    String? lotNumber,
    String? administeredBy,
    String? administrationSite,
    String? dose,
    int? doseNumber,
    String? notes,
  }) async {
    final date = administeredDate ?? dateAdministered ?? DateTime.now();
    return createImmunization(
      patientId: patientId,
      vaccineName: vaccineName,
      administeredDate: date,
      vaccineCode: vaccineCode,
      manufacturer: manufacturer,
      lotNumber: lotNumber,
      administeredBy: administeredBy,
      administrationSite: administrationSite,
      dose: dose,
      doseNumber: doseNumber,
      notes: notes,
    );
  }

  /// Convert to model (screen compatibility)
  ImmunizationModel toModel(ImmunizationData immunization) {
    return ImmunizationModel(
      id: immunization.id,
      patientId: immunization.patientId,
      vaccineName: immunization.vaccineName,
      administeredDate: immunization.administeredDate,
      vaccineCode: immunization.vaccineCode,
      manufacturer: immunization.manufacturer,
      lotNumber: immunization.lotNumber,
      administeredBy: immunization.administeredBy,
      administrationSite: immunization.administrationSite,
      dose: immunization.dose,
      doseNumber: immunization.doseNumber,
      notes: immunization.notes,
      status: ImmunizationStatus.fromValue(immunization.status),
    );
  }
}
