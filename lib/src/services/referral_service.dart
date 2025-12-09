import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef ReferralData = Referral;

/// Service for managing referrals
class ReferralService {
  ReferralService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create referral
  Future<int> createReferral({
    required int patientId,
    required String specialty,
    required String reasonForReferral,
    required DateTime referralDate,
    int? encounterId,
    String? referralType,
    String? referredToName,
    String? referredToFacility,
    String? referredToPhone,
    String? referredToEmail,
    String? referredToAddress,
    String? clinicalHistory,
    String? diagnosisIds,
    String? urgency,
    String? status,
    DateTime? appointmentDate,
    String? preAuthRequired,
    String? preAuthStatus,
    String? notes,
  }) async {
    final id = await _db.into(_db.referrals).insert(
      ReferralsCompanion.insert(
        patientId: patientId,
        specialty: specialty,
        reasonForReferral: reasonForReferral,
        referralDate: referralDate,
        encounterId: Value(encounterId),
        referralType: Value(referralType ?? 'standard'),
        referredToName: Value(referredToName ?? ''),
        referredToFacility: Value(referredToFacility ?? ''),
        referredToPhone: Value(referredToPhone ?? ''),
        referredToEmail: Value(referredToEmail ?? ''),
        referredToAddress: Value(referredToAddress ?? ''),
        clinicalHistory: Value(clinicalHistory ?? ''),
        diagnosisIds: Value(diagnosisIds ?? ''),
        urgency: Value(urgency ?? 'routine'),
        status: Value(status ?? 'pending'),
        appointmentDate: Value(appointmentDate),
        preAuthRequired: Value(preAuthRequired ?? ''),
        preAuthStatus: Value(preAuthStatus ?? ''),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.referral,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_referral', 'specialty': specialty},
    );

    if (kDebugMode) {
      print('[ReferralService] Created referral $id for patient $patientId');
    }

    return id;
  }

  /// Get all referrals for a patient
  Future<List<Referral>> getReferralsForPatient(int patientId) async {
    return (_db.select(_db.referrals)
          ..where((r) => r.patientId.equals(patientId))
          ..orderBy([(r) => OrderingTerm.desc(r.referralDate)]))
        .get();
  }

  /// Get referral by ID
  Future<Referral?> getReferralById(int id) async {
    return (_db.select(_db.referrals)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get pending referrals
  Future<List<Referral>> getPendingReferrals(int patientId) async {
    return (_db.select(_db.referrals)
          ..where((r) => r.patientId.equals(patientId) & r.status.equals('pending'))
          ..orderBy([(r) => OrderingTerm.asc(r.referralDate)]))
        .get();
  }

  /// Get referrals by status
  Future<List<Referral>> getReferralsByStatus(int patientId, String status) async {
    return (_db.select(_db.referrals)
          ..where((r) => r.patientId.equals(patientId) & r.status.equals(status))
          ..orderBy([(r) => OrderingTerm.desc(r.referralDate)]))
        .get();
  }

  /// Update referral status
  Future<bool> updateReferralStatus({
    required int id,
    required String status,
    DateTime? appointmentDate,
    DateTime? completedDate,
    String? consultationNotes,
    String? recommendations,
    String? notes,
  }) async {
    final existing = await getReferralById(id);
    if (existing == null) return false;

    await (_db.update(_db.referrals)..where((r) => r.id.equals(id)))
        .write(ReferralsCompanion(
          status: Value(status),
          appointmentDate: appointmentDate != null ? Value(appointmentDate) : const Value.absent(),
          completedDate: completedDate != null ? Value(completedDate) : const Value.absent(),
          consultationNotes: consultationNotes != null ? Value(consultationNotes) : const Value.absent(),
          recommendations: recommendations != null ? Value(recommendations) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.referral,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_referral_status', 'status': status},
    );

    return true;
  }

  /// Complete referral
  Future<bool> completeReferral({
    required int id,
    String? consultationNotes,
    String? recommendations,
  }) async {
    return updateReferralStatus(
      id: id,
      status: 'completed',
      completedDate: DateTime.now(),
      consultationNotes: consultationNotes,
      recommendations: recommendations,
    );
  }

  /// Cancel referral
  Future<bool> cancelReferral(int id, {String? reason}) async {
    return updateReferralStatus(
      id: id,
      status: 'cancelled',
      notes: reason,
    );
  }

  /// Delete referral
  Future<bool> deleteReferral(int id) async {
    final existing = await getReferralById(id);
    if (existing == null) return false;

    await (_db.delete(_db.referrals)..where((r) => r.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.referral,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_referral'},
    );

    return true;
  }

  /// Get referral statistics
  Future<Map<String, dynamic>> getReferralStats(int patientId) async {
    final referrals = await getReferralsForPatient(patientId);
    
    final bySpecialty = <String, int>{};
    for (final referral in referrals) {
      bySpecialty[referral.specialty] = (bySpecialty[referral.specialty] ?? 0) + 1;
    }

    return {
      'total': referrals.length,
      'pending': referrals.where((r) => r.status == 'pending').length,
      'scheduled': referrals.where((r) => r.status == 'scheduled').length,
      'completed': referrals.where((r) => r.status == 'completed').length,
      'cancelled': referrals.where((r) => r.status == 'cancelled').length,
      'by_specialty': bySpecialty,
    };
  }

  // ===== Screen compatibility methods =====

  /// Convert database entry to model (passthrough for compatibility)
  ReferralData toModel(Referral referral) {
    return referral;
  }

  /// Get referrals by status (single status filter, all patients)
  Future<List<Referral>> getAllReferralsByStatus(String status) async {
    return (_db.select(_db.referrals)
          ..where((r) => r.status.equals(status))
          ..orderBy([(r) => OrderingTerm.desc(r.referralDate)]))
        .get();
  }

  /// Update referral status with positional args (screen compatibility)
  Future<bool> updateStatus(int id, String status) async {
    return updateReferralStatus(id: id, status: status);
  }
}
