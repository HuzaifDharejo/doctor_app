import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/clinical_letter.dart';
import 'audit_service.dart';

/// Type alias for compatibility with screen code
typedef ClinicalLetterData = ClinicalLetter;

/// Service for managing clinical letters and correspondence
/// 
/// Handles letter generation, templates, sending, and tracking.
class ClinicalLetterService {
  ClinicalLetterService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  // ═══════════════════════════════════════════════════════════════════════════════
  // CLINICAL LETTER CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Create a clinical letter
  Future<int> createLetter({
    required int patientId,
    required String letterType,
    required String title,
    required String content,
    required DateTime letterDate,
    int? encounterId,
    String? templateId,
    String? recipientName,
    String? recipientFacility,
    String? recipientAddress,
    String? recipientFax,
    String? formData,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? notes,
  }) async {
    final id = await _db.into(_db.clinicalLetters).insert(ClinicalLettersCompanion.insert(
      patientId: patientId,
      letterType: letterType,
      title: title,
      content: content,
      letterDate: letterDate,
      encounterId: Value(encounterId),
      templateId: Value(templateId ?? ''),
      recipientName: Value(recipientName ?? ''),
      recipientFacility: Value(recipientFacility ?? ''),
      recipientAddress: Value(recipientAddress ?? ''),
      recipientFax: Value(recipientFax ?? ''),
      formData: Value(formData ?? '{}'),
      effectiveFrom: Value(effectiveFrom),
      effectiveTo: Value(effectiveTo),
      status: const Value('draft'),
      notes: Value(notes ?? ''),
    ));

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: patientId,
      afterData: {
        'action': 'create_letter',
        'type': letterType,
        'title': title,
        'recipient': recipientName,
      },
    );

    if (kDebugMode) {
      print('[ClinicalLetterService] Created letter $id for patient $patientId');
    }

    return id;
  }

  /// Get all letters for a patient
  Future<List<ClinicalLetter>> getLettersForPatient(int patientId) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.patientId.equals(patientId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Get letters by type for a patient
  Future<List<ClinicalLetter>> getLettersByType(int patientId, String letterType) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.patientId.equals(patientId) & l.letterType.equals(letterType))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Get letter by ID
  Future<ClinicalLetter?> getLetterById(int id) async {
    return (_db.select(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get draft letters for a patient
  Future<List<ClinicalLetter>> getDraftLetters(int patientId) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.patientId.equals(patientId) & l.status.equals('draft'))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Get sent letters for a patient
  Future<List<ClinicalLetter>> getSentLetters(int patientId) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.patientId.equals(patientId) & l.status.equals('sent'))
          ..orderBy([(l) => OrderingTerm.desc(l.sentAt)]))
        .get();
  }

  /// Get letters for an encounter
  Future<List<ClinicalLetter>> getLettersForEncounter(int encounterId) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.encounterId.equals(encounterId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Update letter
  Future<bool> updateLetter({
    required int id,
    String? title,
    String? content,
    String? recipientName,
    String? recipientFacility,
    String? recipientAddress,
    String? recipientFax,
    String? notes,
  }) async {
    final letter = await getLetterById(id);
    if (letter == null) return false;

    // Can only update draft letters
    if (letter.status != 'draft') {
      if (kDebugMode) {
        print('[ClinicalLetterService] Cannot update non-draft letter $id');
      }
      return false;
    }

    await (_db.update(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .write(ClinicalLettersCompanion(
          title: title != null ? Value(title) : const Value.absent(),
          content: content != null ? Value(content) : const Value.absent(),
          recipientName: recipientName != null ? Value(recipientName) : const Value.absent(),
          recipientFacility: recipientFacility != null ? Value(recipientFacility) : const Value.absent(),
          recipientAddress: recipientAddress != null ? Value(recipientAddress) : const Value.absent(),
          recipientFax: recipientFax != null ? Value(recipientFax) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'update_letter'},
    );

    return true;
  }

  /// Finalize letter (mark as ready to send)
  Future<bool> finalizeLetter(int id) async {
    final letter = await getLetterById(id);
    if (letter == null || letter.status != 'draft') return false;

    await (_db.update(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .write(const ClinicalLettersCompanion(
          status: Value('finalized'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'finalize_letter'},
    );

    return true;
  }

  /// Sign letter
  Future<bool> signLetter(int id, String signerName, {String? signatureData}) async {
    final letter = await getLetterById(id);
    if (letter == null) return false;
    if (letter.status != 'draft' && letter.status != 'finalized') return false;

    await (_db.update(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .write(ClinicalLettersCompanion(
          status: const Value('signed'),
          signedBy: Value(signerName),
          signedAt: Value(DateTime.now()),
          signatureData: signatureData != null ? Value(signatureData) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.signDocument,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'sign_letter', 'signer': signerName},
    );

    return true;
  }

  /// Mark letter as sent
  Future<bool> markLetterAsSent({
    required int id,
    String? sentMethod,
    String? deliveryStatus,
  }) async {
    final letter = await getLetterById(id);
    if (letter == null) return false;

    await (_db.update(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .write(ClinicalLettersCompanion(
          status: const Value('sent'),
          sentAt: Value(DateTime.now()),
          sentMethod: sentMethod != null ? Value(sentMethod) : const Value.absent(),
          deliveryStatus: deliveryStatus != null ? Value(deliveryStatus) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {
        'action': 'send_letter',
        'sent_method': sentMethod,
      },
    );

    return true;
  }

  /// Mark letter as delivered
  Future<bool> markLetterAsDelivered(int id) async {
    final letter = await getLetterById(id);
    if (letter == null || letter.status != 'sent') return false;

    await (_db.update(_db.clinicalLetters)..where((l) => l.id.equals(id)))
        .write(const ClinicalLettersCompanion(
          deliveryStatus: Value('delivered'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'mark_delivered'},
    );

    return true;
  }

  /// Delete draft letter
  Future<bool> deleteDraftLetter(int id) async {
    final letter = await getLetterById(id);
    if (letter == null || letter.status != 'draft') return false;

    await (_db.delete(_db.clinicalLetters)..where((l) => l.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'delete_draft_letter'},
    );

    return true;
  }

  /// Duplicate letter (create new draft from existing)
  Future<int?> duplicateLetter(int id, {String? newRecipientName}) async {
    final letter = await getLetterById(id);
    if (letter == null) return null;

    return createLetter(
      patientId: letter.patientId,
      letterType: letter.letterType,
      title: letter.title,
      content: letter.content,
      letterDate: DateTime.now(),
      encounterId: letter.encounterId,
      recipientName: newRecipientName ?? letter.recipientName,
      recipientFacility: letter.recipientFacility,
      recipientAddress: letter.recipientAddress,
      recipientFax: letter.recipientFax,
      templateId: letter.templateId,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // LETTER GENERATION & TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Generate referral letter content
  Future<String> generateReferralLetterContent({
    required int patientId,
    required String referralReason,
    String? urgency,
    String? clinicalHistory,
    String? currentMedications,
    String? allergies,
    String? additionalNotes,
  }) async {
    // Get patient info
    final patient = await (_db.select(_db.patients)
      ..where((p) => p.id.equals(patientId))).getSingleOrNull();
    
    if (patient == null) return '';

    final buffer = StringBuffer();
    
    buffer.writeln('RE: ${patient.firstName} ${patient.lastName}');
    buffer.writeln('Age: ${patient.age ?? 'Unknown'}');
    buffer.writeln('');
    buffer.writeln('Dear Colleague,');
    buffer.writeln('');
    buffer.writeln('I am writing to refer the above patient for your opinion and management regarding:');
    buffer.writeln('');
    buffer.writeln(referralReason);
    buffer.writeln('');
    
    if (urgency != null && urgency.isNotEmpty) {
      buffer.writeln('Urgency: $urgency');
      buffer.writeln('');
    }

    if (clinicalHistory != null && clinicalHistory.isNotEmpty) {
      buffer.writeln('Clinical History:');
      buffer.writeln(clinicalHistory);
      buffer.writeln('');
    }

    if (currentMedications != null && currentMedications.isNotEmpty) {
      buffer.writeln('Current Medications:');
      buffer.writeln(currentMedications);
      buffer.writeln('');
    }

    if (allergies != null && allergies.isNotEmpty) {
      buffer.writeln('Allergies:');
      buffer.writeln(allergies);
      buffer.writeln('');
    }

    if (additionalNotes != null && additionalNotes.isNotEmpty) {
      buffer.writeln('Additional Notes:');
      buffer.writeln(additionalNotes);
      buffer.writeln('');
    }

    buffer.writeln('Thank you for seeing this patient. Please do not hesitate to contact me if you require any further information.');
    buffer.writeln('');
    buffer.writeln('Yours faithfully,');
    
    return buffer.toString();
  }

  /// Generate discharge summary letter content
  Future<String> generateDischargeSummaryContent({
    required int patientId,
    required int encounterId,
    String? admissionDate,
    String? dischargeDate,
    String? admissionDiagnosis,
    String? dischargeDiagnosis,
    String? treatmentSummary,
    String? dischargeMedications,
    String? followUpInstructions,
  }) async {
    final patient = await (_db.select(_db.patients)
      ..where((p) => p.id.equals(patientId))).getSingleOrNull();
    
    if (patient == null) return '';

    final buffer = StringBuffer();
    
    buffer.writeln('DISCHARGE SUMMARY');
    buffer.writeln('');
    buffer.writeln('Patient: ${patient.firstName} ${patient.lastName}');
    buffer.writeln('Age: ${patient.age ?? 'Unknown'}');
    buffer.writeln('');
    
    if (admissionDate != null) {
      buffer.writeln('Date of Admission: $admissionDate');
    }
    if (dischargeDate != null) {
      buffer.writeln('Date of Discharge: $dischargeDate');
    }
    buffer.writeln('');

    if (admissionDiagnosis != null && admissionDiagnosis.isNotEmpty) {
      buffer.writeln('Admission Diagnosis:');
      buffer.writeln(admissionDiagnosis);
      buffer.writeln('');
    }

    if (dischargeDiagnosis != null && dischargeDiagnosis.isNotEmpty) {
      buffer.writeln('Discharge Diagnosis:');
      buffer.writeln(dischargeDiagnosis);
      buffer.writeln('');
    }

    if (treatmentSummary != null && treatmentSummary.isNotEmpty) {
      buffer.writeln('Treatment Summary:');
      buffer.writeln(treatmentSummary);
      buffer.writeln('');
    }

    if (dischargeMedications != null && dischargeMedications.isNotEmpty) {
      buffer.writeln('Discharge Medications:');
      buffer.writeln(dischargeMedications);
      buffer.writeln('');
    }

    if (followUpInstructions != null && followUpInstructions.isNotEmpty) {
      buffer.writeln('Follow-up Instructions:');
      buffer.writeln(followUpInstructions);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Generate medical certificate content
  Future<String> generateMedicalCertificateContent({
    required int patientId,
    required DateTime fromDate,
    required DateTime toDate,
    String? reason,
    bool fitForWork = false,
  }) async {
    final patient = await (_db.select(_db.patients)
      ..where((p) => p.id.equals(patientId))).getSingleOrNull();
    
    if (patient == null) return '';

    final buffer = StringBuffer();
    
    buffer.writeln('MEDICAL CERTIFICATE');
    buffer.writeln('');
    buffer.writeln('This is to certify that ${patient.firstName} ${patient.lastName}');
    buffer.writeln('Age: ${patient.age ?? 'Unknown'}');
    buffer.writeln('');
    buffer.writeln('Was examined on ${DateTime.now().toString().split(' ')[0]} and');
    
    if (fitForWork) {
      buffer.writeln('is fit to return to work/normal activities.');
    } else {
      buffer.writeln('is unfit for work/normal activities from ${fromDate.toString().split(' ')[0]} to ${toDate.toString().split(' ')[0]} inclusive.');
    }
    
    if (reason != null && reason.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Reason: $reason');
    }
    
    buffer.writeln('');
    buffer.writeln('This certificate is issued upon request.');
    
    return buffer.toString();
  }

  /// Search letters
  Future<List<ClinicalLetter>> searchLetters({
    int? patientId,
    String? letterType,
    String? status,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var selectQuery = _db.select(_db.clinicalLetters);

    if (patientId != null) {
      selectQuery = selectQuery..where((l) => l.patientId.equals(patientId));
    }
    if (letterType != null) {
      selectQuery = selectQuery..where((l) => l.letterType.equals(letterType));
    }
    if (status != null) {
      selectQuery = selectQuery..where((l) => l.status.equals(status));
    }
    if (query != null && query.isNotEmpty) {
      selectQuery = selectQuery..where((l) => 
          l.title.contains(query) | 
          l.content.contains(query) |
          l.recipientName.contains(query));
    }
    if (fromDate != null) {
      selectQuery = selectQuery..where((l) => l.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      selectQuery = selectQuery..where((l) => l.createdAt.isSmallerOrEqualValue(toDate));
    }

    return (selectQuery..orderBy([(l) => OrderingTerm.desc(l.createdAt)])).get();
  }

  /// Get letter statistics for a patient
  Future<Map<String, dynamic>> getPatientLetterStats(int patientId) async {
    final letters = await getLettersForPatient(patientId);
    
    final typeBreakdown = <String, int>{};
    for (final letter in letters) {
      typeBreakdown[letter.letterType] = (typeBreakdown[letter.letterType] ?? 0) + 1;
    }

    return {
      'total_letters': letters.length,
      'draft_count': letters.where((l) => l.status == 'draft').length,
      'sent_count': letters.where((l) => l.status == 'sent').length,
      'signed_count': letters.where((l) => l.status == 'signed').length,
      'type_breakdown': typeBreakdown,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get all letters (screen compatibility)
  Future<List<ClinicalLetterData>> getAllLetters() async {
    return (_db.select(_db.clinicalLetters)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Get letters by status (screen compatibility)
  Future<List<ClinicalLetterData>> getLettersByStatus(String status) async {
    return (_db.select(_db.clinicalLetters)
          ..where((l) => l.status.equals(status))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  /// Delete letter (screen compatibility)
  Future<bool> deleteLetter(int id) async {
    final letter = await getLetterById(id);
    if (letter == null) return false;

    await (_db.delete(_db.clinicalLetters)..where((l) => l.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.clinicalLetter,
      entityId: id,
      patientId: letter.patientId,
      afterData: {'action': 'delete_letter'},
    );

    return true;
  }

  /// Submit for signature (screen compatibility)
  Future<bool> submitForSignature(int id) async {
    return finalizeLetter(id);
  }

  /// Send letter (screen compatibility)
  Future<bool> sendLetter({
    required int id,
    String? method,
    String? recipient,
  }) async {
    return markLetterAsSent(
      id: id,
      sentMethod: method,
    );
  }

  /// Convert ClinicalLetter to ClinicalLetterModel
  ClinicalLetterModel toModel(ClinicalLetterData letter) {
    return ClinicalLetterModel(
      id: letter.id,
      patientId: letter.patientId,
      encounterId: letter.encounterId,
      letterType: ClinicalLetterType.fromValue(letter.letterType),
      subject: letter.title,
      content: letter.content,
      status: ClinicalLetterStatus.fromValue(letter.status),
      recipientName: letter.recipientName,
      recipientOrganization: letter.recipientFacility,
      recipientAddress: letter.recipientAddress,
      recipientFax: letter.recipientFax,
      templateId: letter.templateId,
      signedAt: letter.signedAt,
      sentAt: letter.sentAt,
      notes: letter.notes,
      createdAt: letter.createdAt,
    );
  }
}
