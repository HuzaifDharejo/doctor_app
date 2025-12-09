import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/consent.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef ConsentData = PatientConsent;

/// Service for managing patient consents
/// 
/// Handles informed consent documentation, HIPAA authorizations,
/// and other consent-related records.
class ConsentService {
  ConsentService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  // ═══════════════════════════════════════════════════════════════════════════════
  // CONSENT CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Create a new consent record
  Future<int> createConsent({
    required int patientId,
    required String consentType,
    required String consentTitle,
    required DateTime effectiveDate,
    int? encounterId,
    String? consentDescription,
    String? consentText,
    String? templateId,
    String? procedureName,
    String? procedureRisks,
    String? procedureBenefits,
    String? procedureAlternatives,
    String? signatureData,
    String? signedByName,
    String? signedByRelationship,
    DateTime? signedAt,
    String? witnessName,
    String? witnessSignature,
    DateTime? expirationDate,
    String? notes,
  }) async {
    final id = await _db.into(_db.patientConsents).insert(PatientConsentsCompanion.insert(
      patientId: patientId,
      consentType: consentType,
      consentTitle: consentTitle,
      effectiveDate: effectiveDate,
      encounterId: Value(encounterId),
      consentDescription: Value(consentDescription ?? ''),
      consentText: Value(consentText ?? ''),
      templateId: Value(templateId ?? ''),
      procedureName: Value(procedureName ?? ''),
      procedureRisks: Value(procedureRisks ?? ''),
      procedureBenefits: Value(procedureBenefits ?? ''),
      procedureAlternatives: Value(procedureAlternatives ?? ''),
      signatureData: Value(signatureData ?? ''),
      signedByName: Value(signedByName ?? ''),
      signedByRelationship: Value(signedByRelationship ?? ''),
      signedAt: Value(signedAt),
      witnessName: Value(witnessName ?? ''),
      witnessSignature: Value(witnessSignature ?? ''),
      status: const Value('active'),
      expirationDate: Value(expirationDate),
      isActive: const Value(true),
      notes: Value(notes ?? ''),
    ));

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.consent,
      entityId: id,
      patientId: patientId,
      afterData: {
        'action': 'create_consent',
        'type': consentType,
        'title': consentTitle,
      },
    );

    if (kDebugMode) {
      print('[ConsentService] Created consent $id: $consentType for patient $patientId');
    }

    return id;
  }

  /// Get all consents for a patient
  Future<List<PatientConsent>> getConsentsForPatient(int patientId) async {
    return (_db.select(_db.patientConsents)
          ..where((c) => c.patientId.equals(patientId))
          ..orderBy([(c) => OrderingTerm.desc(c.effectiveDate)]))
        .get();
  }

  /// Get active consents for a patient (or all active if no patientId)
  Future<List<PatientConsent>> getActiveConsents([int? patientId]) async {
    final now = DateTime.now();
    final query = _db.select(_db.patientConsents);
    if (patientId != null) {
      query.where((c) => 
          c.patientId.equals(patientId) & 
          c.isActive.equals(true) &
          (c.expirationDate.isNull() | c.expirationDate.isBiggerThanValue(now)));
    } else {
      query.where((c) => 
          c.isActive.equals(true) &
          (c.expirationDate.isNull() | c.expirationDate.isBiggerThanValue(now)));
    }
    return (query..orderBy([(c) => OrderingTerm.asc(c.consentType)])).get();
  }

  /// Get consent by ID
  Future<PatientConsent?> getConsentById(int id) async {
    return (_db.select(_db.patientConsents)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get consent by type
  Future<PatientConsent?> getConsentByType(int patientId, String consentType) async {
    final now = DateTime.now();
    return (_db.select(_db.patientConsents)
          ..where((c) => 
              c.patientId.equals(patientId) & 
              c.consentType.equals(consentType) &
              c.isActive.equals(true) &
              (c.expirationDate.isNull() | c.expirationDate.isBiggerThanValue(now)))
          ..orderBy([(c) => OrderingTerm.desc(c.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Check if patient has valid consent
  Future<bool> hasValidConsent(int patientId, String consentType) async {
    final consent = await getConsentByType(patientId, consentType);
    return consent != null && consent.isActive;
  }

  /// Get expiring consents (within specified days)
  Future<List<PatientConsent>> getExpiringConsents({int daysUntilExpiration = 30}) async {
    final now = DateTime.now();
    final expirationThreshold = now.add(Duration(days: daysUntilExpiration));
    
    return (_db.select(_db.patientConsents)
          ..where((c) => 
              c.isActive.equals(true) &
              c.expirationDate.isBiggerThanValue(now) &
              c.expirationDate.isSmallerOrEqualValue(expirationThreshold))
          ..orderBy([(c) => OrderingTerm.asc(c.expirationDate)]))
        .get();
  }

  /// Get expired consents (for a patient or all if no patientId)
  Future<List<PatientConsent>> getExpiredConsents([int? patientId]) async {
    final now = DateTime.now();
    final query = _db.select(_db.patientConsents);
    if (patientId != null) {
      query.where((c) => 
          c.patientId.equals(patientId) &
          c.expirationDate.isSmallerThanValue(now));
    } else {
      query.where((c) => c.expirationDate.isSmallerThanValue(now));
    }
    return (query..orderBy([(c) => OrderingTerm.desc(c.expirationDate)])).get();
  }

  /// Revoke consent
  Future<bool> revokeConsent({
    required int consentId,
    String revocationReason = '',
  }) async {
    final consent = await getConsentById(consentId);
    if (consent == null) return false;

    await (_db.update(_db.patientConsents)..where((c) => c.id.equals(consentId)))
        .write(PatientConsentsCompanion(
          status: const Value('revoked'),
          isActive: const Value(false),
          notes: Value('${consent.notes}\nRevoked: $revocationReason'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.consent,
      entityId: consentId,
      patientId: consent.patientId,
      afterData: {
        'action': 'revoke_consent',
        'type': consent.consentType,
        'reason': revocationReason,
      },
    );

    return true;
  }

  /// Renew consent
  Future<int> renewConsent({
    required int originalConsentId,
    DateTime? newExpirationDate,
    String? signatureData,
    String? witnessName,
    String? witnessSignature,
  }) async {
    final original = await getConsentById(originalConsentId);
    if (original == null) throw Exception('Original consent not found');

    // Mark original as superseded
    await (_db.update(_db.patientConsents)..where((c) => c.id.equals(originalConsentId)))
        .write(const PatientConsentsCompanion(
          status: Value('superseded'),
          isActive: Value(false),
        ));

    // Create new consent
    return createConsent(
      patientId: original.patientId,
      consentType: original.consentType,
      consentTitle: original.consentTitle,
      effectiveDate: DateTime.now(),
      consentDescription: original.consentDescription,
      consentText: original.consentText,
      expirationDate: newExpirationDate ?? DateTime.now().add(const Duration(days: 365)),
      signatureData: signatureData ?? '',
      witnessName: witnessName ?? '',
      witnessSignature: witnessSignature ?? '',
    );
  }

  /// Get consent types requiring renewal
  Future<Map<int, List<String>>> getPatientsRequiringConsentRenewal({
    int daysUntilExpiration = 30,
  }) async {
    final expiring = await getExpiringConsents(daysUntilExpiration: daysUntilExpiration);
    
    final byPatient = <int, List<String>>{};
    for (final consent in expiring) {
      byPatient.putIfAbsent(consent.patientId, () => []).add(consent.consentType);
    }
    
    return byPatient;
  }

  /// Check required consents for a procedure
  Future<ConsentCheckResult> checkRequiredConsents({
    required int patientId,
    required String procedureType,
  }) async {
    final requiredTypes = _getRequiredConsentTypes(procedureType);
    final activeConsents = await getActiveConsents(patientId);
    
    final activeTypes = activeConsents.map((c) => c.consentType).toSet();
    
    final missingConsents = <String>[];
    final validConsents = <String>[];
    
    for (final required in requiredTypes) {
      if (activeTypes.contains(required)) {
        validConsents.add(required);
      } else {
        missingConsents.add(required);
      }
    }
    
    return ConsentCheckResult(
      patientId: patientId,
      procedureType: procedureType,
      requiredConsents: requiredTypes,
      validConsents: validConsents,
      missingConsents: missingConsents,
      canProceed: missingConsents.isEmpty,
    );
  }

  /// Get required consent types for a procedure
  List<String> _getRequiredConsentTypes(String procedureType) {
    final procedureLower = procedureType.toLowerCase();
    
    // Always require general treatment consent
    final required = ['treatment'];
    
    // Add procedure-specific consents
    if (procedureLower.contains('surgery') || procedureLower.contains('procedure')) {
      required.add('procedure');
      required.add('anesthesia');
    }
    
    if (procedureLower.contains('research') || procedureLower.contains('study')) {
      required.add('research');
    }
    
    if (procedureLower.contains('photo') || procedureLower.contains('image')) {
      required.add('photo_video');
    }
    
    if (procedureLower.contains('release') || procedureLower.contains('disclosure')) {
      required.add('information_release');
    }
    
    if (procedureLower.contains('telehealth') || procedureLower.contains('telemedicine')) {
      required.add('telehealth');
    }
    
    return required;
  }

  /// Generate consent form content
  String generateConsentFormContent({
    required String consentType,
    required String patientName,
    required String providerName,
    String? procedureName,
    List<String>? risks,
    List<String>? benefits,
    List<String>? alternatives,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('CONSENT FORM');
    buffer.writeln('');
    buffer.writeln('Type: ${consentType.replaceAll('_', ' ').toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('Patient Name: $patientName');
    buffer.writeln('Provider: $providerName');
    buffer.writeln('Date: ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln('');
    
    if (procedureName != null && procedureName.isNotEmpty) {
      buffer.writeln('Procedure: $procedureName');
      buffer.writeln('');
    }
    
    if (risks != null && risks.isNotEmpty) {
      buffer.writeln('RISKS:');
      for (final risk in risks) {
        buffer.writeln('• $risk');
      }
      buffer.writeln('');
    }
    
    if (benefits != null && benefits.isNotEmpty) {
      buffer.writeln('BENEFITS:');
      for (final benefit in benefits) {
        buffer.writeln('• $benefit');
      }
      buffer.writeln('');
    }
    
    if (alternatives != null && alternatives.isNotEmpty) {
      buffer.writeln('ALTERNATIVES:');
      for (final alternative in alternatives) {
        buffer.writeln('• $alternative');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('I hereby consent to the above treatment/procedure.');
    buffer.writeln('');
    buffer.writeln('Patient Signature: _____________________  Date: _________');
    buffer.writeln('');
    buffer.writeln('Witness Signature: _____________________  Date: _________');
    
    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get all consents (screen compatibility)
  Future<List<ConsentData>> getAllConsents() async {
    return (_db.select(_db.patientConsents)
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Get expiring soon consents (screen compatibility)
  Future<List<ConsentData>> getExpiringSoonConsents({int days = 30}) async {
    return getExpiringConsents(daysUntilExpiration: days);
  }

  /// Record consent (screen compatibility)
  /// Accepts `consentDate` as alias for `effectiveDate`
  /// Accepts `description` as alias for `consentDescription`
  Future<int> recordConsent({
    required int patientId,
    required String consentType,
    String? consentTitle,
    DateTime? effectiveDate,
    DateTime? consentDate, // alias for effectiveDate
    String? notes,
    String? description, // alias for consentDescription
    DateTime? expirationDate,
    String? witnessName,
  }) async {
    return createConsent(
      patientId: patientId,
      consentType: consentType,
      consentTitle: consentTitle ?? consentType.replaceAll('_', ' '),
      effectiveDate: effectiveDate ?? consentDate ?? DateTime.now(),
      notes: notes,
      consentDescription: description,
      expirationDate: expirationDate,
      witnessName: witnessName,
    );
  }

  /// Convert to model (screen compatibility)
  ConsentModel toModel(ConsentData consent) {
    return ConsentModel(
      id: consent.id,
      patientId: consent.patientId,
      consentType: ConsentType.fromValue(consent.consentType),
      consentTitle: consent.consentTitle,
      effectiveDate: consent.effectiveDate,
      expirationDate: consent.expirationDate,
      isActive: consent.isActive,
      witnessName: consent.witnessName,
      signedAt: consent.signedAt,
      notes: consent.notes,
      createdAt: consent.createdAt,
    );
  }
}

/// Result of consent check
class ConsentCheckResult {
  const ConsentCheckResult({
    required this.patientId,
    required this.procedureType,
    required this.requiredConsents,
    required this.validConsents,
    required this.missingConsents,
    required this.canProceed,
  });

  final int patientId;
  final String procedureType;
  final List<String> requiredConsents;
  final List<String> validConsents;
  final List<String> missingConsents;
  final bool canProceed;
}
