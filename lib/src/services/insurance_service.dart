import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/insurance.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef InsuranceData = InsuranceInfoData;
typedef InsuranceInfoDataAlias = InsuranceInfoData;

/// Stub class for insurance claims (no DB table)
class InsuranceClaimData {
  final int id;
  final int patientId;
  final int insuranceId;
  final String claimNumber;
  final String status;
  final double amount;
  final DateTime claimDate;
  final DateTime? serviceDate;
  final double? billedAmount;
  final double? paidAmount;
  final double? patientResponsibility;
  final String? denialReason;
  final String? notes;

  const InsuranceClaimData({
    required this.id,
    required this.patientId,
    required this.insuranceId,
    required this.claimNumber,
    required this.status,
    required this.amount,
    required this.claimDate,
    this.serviceDate,
    this.billedAmount,
    this.paidAmount,
    this.patientResponsibility,
    this.denialReason,
    this.notes,
  });
}

/// Stub class for pre-authorizations (no DB table)
class PreAuthorizationData {
  final int id;
  final int patientId;
  final int insuranceId;
  final String authNumber;
  final String? authorizationNumber;
  final String status;
  final String procedureCode;
  final String? procedureDescription;
  final DateTime requestDate;
  final DateTime? expirationDate;
  final String? notes;

  const PreAuthorizationData({
    required this.id,
    required this.patientId,
    required this.insuranceId,
    required this.authNumber,
    this.authorizationNumber,
    required this.status,
    required this.procedureCode,
    this.procedureDescription,
    required this.requestDate,
    this.expirationDate,
    this.notes,
  });
}

/// Service for managing insurance information
class InsuranceService {
  InsuranceService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create insurance record
  Future<int> createInsurance({
    required int patientId,
    required String payerName,
    required String memberId,
    required DateTime effectiveDate,
    String? insuranceType,
    String? payerId,
    String? planName,
    String? planType,
    String? groupNumber,
    String? subscriberName,
    String? subscriberDob,
    String? subscriberRelationship,
    DateTime? terminationDate,
    double? copay,
    double? deductible,
    double? deductibleMet,
    double? outOfPocketMax,
    double? outOfPocketMet,
    String? payerPhone,
    String? payerAddress,
    String? notes,
  }) async {
    final id = await _db.into(_db.insuranceInfo).insert(
      InsuranceInfoCompanion.insert(
        patientId: patientId,
        payerName: payerName,
        memberId: memberId,
        effectiveDate: effectiveDate,
        insuranceType: Value(insuranceType ?? 'primary'),
        payerId: Value(payerId ?? ''),
        planName: Value(planName ?? ''),
        planType: Value(planType ?? ''),
        groupNumber: Value(groupNumber ?? ''),
        subscriberName: Value(subscriberName ?? ''),
        subscriberDob: Value(subscriberDob ?? ''),
        subscriberRelationship: Value(subscriberRelationship ?? 'self'),
        terminationDate: Value(terminationDate),
        copay: copay != null ? Value(copay) : const Value.absent(),
        deductible: deductible != null ? Value(deductible) : const Value.absent(),
        deductibleMet: deductibleMet != null ? Value(deductibleMet) : const Value.absent(),
        outOfPocketMax: outOfPocketMax != null ? Value(outOfPocketMax) : const Value.absent(),
        outOfPocketMet: outOfPocketMet != null ? Value(outOfPocketMet) : const Value.absent(),
        payerPhone: Value(payerPhone ?? ''),
        payerAddress: Value(payerAddress ?? ''),
        notes: Value(notes ?? ''),
        isActive: const Value(true),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.insurance,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_insurance', 'payer': payerName},
    );

    if (kDebugMode) {
      print('[InsuranceService] Created insurance $id for patient $patientId');
    }

    return id;
  }

  /// Get all insurance for a patient
  Future<List<InsuranceInfoData>> getInsuranceForPatient(int patientId) async {
    return (_db.select(_db.insuranceInfo)
          ..where((i) => i.patientId.equals(patientId))
          ..orderBy([(i) => OrderingTerm.asc(i.insuranceType)]))
        .get();
  }

  /// Get active insurance for a patient
  Future<List<InsuranceInfoData>> getActiveInsurance(int patientId) async {
    return (_db.select(_db.insuranceInfo)
          ..where((i) => i.patientId.equals(patientId) & i.isActive.equals(true))
          ..orderBy([(i) => OrderingTerm.asc(i.insuranceType)]))
        .get();
  }

  /// Get primary insurance
  Future<InsuranceInfoData?> getPrimaryInsurance(int patientId) async {
    return (_db.select(_db.insuranceInfo)
          ..where((i) =>
              i.patientId.equals(patientId) &
              i.isActive.equals(true) &
              i.insuranceType.equals('primary'))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get insurance by ID
  Future<InsuranceInfoData?> getInsuranceById(int id) async {
    return (_db.select(_db.insuranceInfo)..where((i) => i.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update insurance
  Future<bool> updateInsurance({
    required int id,
    String? payerName,
    String? memberId,
    String? groupNumber,
    DateTime? effectiveDate,
    DateTime? terminationDate,
    double? copay,
    double? deductible,
    bool? isActive,
    String? notes,
  }) async {
    final existing = await getInsuranceById(id);
    if (existing == null) return false;

    await (_db.update(_db.insuranceInfo)..where((i) => i.id.equals(id)))
        .write(InsuranceInfoCompanion(
          payerName: payerName != null ? Value(payerName) : const Value.absent(),
          memberId: memberId != null ? Value(memberId) : const Value.absent(),
          groupNumber: groupNumber != null ? Value(groupNumber) : const Value.absent(),
          effectiveDate: effectiveDate != null ? Value(effectiveDate) : const Value.absent(),
          terminationDate: terminationDate != null ? Value(terminationDate) : const Value.absent(),
          copay: copay != null ? Value(copay) : const Value.absent(),
          deductible: deductible != null ? Value(deductible) : const Value.absent(),
          isActive: isActive != null ? Value(isActive) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.insurance,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_insurance'},
    );

    return true;
  }

  /// Delete insurance
  Future<bool> deleteInsurance(int id) async {
    final existing = await getInsuranceById(id);
    if (existing == null) return false;

    await (_db.delete(_db.insuranceInfo)..where((i) => i.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.insurance,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_insurance'},
    );

    return true;
  }

  /// Verify insurance is active
  Future<bool> isInsuranceActive(int insuranceId) async {
    final insurance = await getInsuranceById(insuranceId);
    if (insurance == null) return false;
    
    final now = DateTime.now();
    if (insurance.terminationDate != null && insurance.terminationDate!.isBefore(now)) {
      return false;
    }
    
    return insurance.isActive;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get all insurance info (screen compatibility)
  Future<List<InsuranceData>> getAllInsuranceInfo() async {
    return (_db.select(_db.insuranceInfo)
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .get();
  }

  /// Get all claims (stub - no DB table)
  Future<List<InsuranceClaimData>> getAllClaims() async {
    return []; // No claims table in Drift schema
  }

  /// Get all pre-authorizations (stub - no DB table)
  Future<List<PreAuthorizationData>> getAllPreAuthorizations() async {
    return []; // No pre-auth table in Drift schema
  }

  /// Add insurance info (screen compatibility)
  Future<int> addInsuranceInfo({
    required int patientId,
    String? payerName,
    String? memberId,
    DateTime? effectiveDate,
    String? insurerName, // alias for payerName
    String? policyNumber, // alias for memberId
    String? insuranceType,
    String? groupNumber,
    bool? isPrimary,
    String? notes,
  }) async {
    final payer = insurerName ?? payerName ?? '';
    final member = policyNumber ?? memberId ?? '';
    final type = isPrimary == true ? 'primary' : (insuranceType ?? 'primary');
    return createInsurance(
      patientId: patientId,
      payerName: payer,
      memberId: member,
      effectiveDate: effectiveDate ?? DateTime.now(),
      insuranceType: type,
      groupNumber: groupNumber,
      notes: notes,
    );
  }

  /// Submit claim (stub - no DB table)
  Future<int> submitClaim({
    required int patientId,
    required int insuranceId,
    String? claimNumber,
    double? amount,
    DateTime? serviceDate,
    double? billedAmount,
    String? diagnosisCodes,
    String? procedureCodes,
    String? notes,
  }) async {
    // No claims table - return dummy ID
    if (kDebugMode) {
      print('[InsuranceService] submitClaim called (no-op, no claims table)');
    }
    return 0;
  }

  /// Request pre-authorization (stub - no DB table)
  Future<int> requestPreAuthorization({
    required int patientId,
    required int insuranceId,
    String? procedureCode,
    String? procedureDescription,
    String? clinicalReason,
    String? notes,
  }) async {
    // No pre-auth table - return dummy ID
    if (kDebugMode) {
      print('[InsuranceService] requestPreAuthorization called (no-op, no pre-auth table)');
    }
    return 0;
  }

  /// Convert to model (screen compatibility)
  InsuranceModel insuranceToModel(InsuranceData insurance) {
    return InsuranceModel(
      id: insurance.id,
      patientId: insurance.patientId,
      payerName: insurance.payerName,
      memberId: insurance.memberId,
      effectiveDate: insurance.effectiveDate,
      insuranceType: InsuranceLevel.fromValue(insurance.insuranceType),
      groupNumber: insurance.groupNumber,
      isActive: insurance.isActive,
      notes: insurance.notes,
    );
  }

  /// Convert claim to model (stub)
  InsuranceClaimData claimToModel(InsuranceClaimData claim) => claim;

  /// Convert pre-auth to model (stub)
  PreAuthorizationData preAuthToModel(PreAuthorizationData preAuth) => preAuth;
}
