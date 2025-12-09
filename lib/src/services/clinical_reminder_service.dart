import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/clinical_reminder.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef ClinicalReminderData = ClinicalReminder;

/// Service for managing clinical reminders
class ClinicalReminderService {
  ClinicalReminderService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create clinical reminder
  Future<int> createReminder({
    required int patientId,
    required String reminderType,
    required String title,
    required DateTime dueDate,
    String? description,
    String? guidelineSource,
    String? recommendation,
    String? frequency,
    DateTime? nextDueDate,
    String? status,
    int? priority,
    int? applicableMinAge,
    int? applicableMaxAge,
    String? applicableGender,
    String? notes,
  }) async {
    final id = await _db.into(_db.clinicalReminders).insert(
      ClinicalRemindersCompanion.insert(
        patientId: patientId,
        reminderType: reminderType,
        title: title,
        dueDate: dueDate,
        description: Value(description ?? ''),
        guidelineSource: Value(guidelineSource ?? ''),
        recommendation: Value(recommendation ?? ''),
        frequency: Value(frequency ?? ''),
        nextDueDate: Value(nextDueDate),
        status: Value(status ?? 'due'),
        priority: Value(priority ?? 1),
        applicableMinAge: Value(applicableMinAge),
        applicableMaxAge: Value(applicableMaxAge),
        applicableGender: Value(applicableGender ?? ''),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.clinicalReminder,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_reminder', 'title': title},
    );

    if (kDebugMode) {
      print('[ClinicalReminderService] Created reminder $id for patient $patientId');
    }

    return id;
  }

  /// Get all reminders for a patient
  Future<List<ClinicalReminder>> getRemindersForPatient(int patientId) async {
    return (_db.select(_db.clinicalReminders)
          ..where((r) => r.patientId.equals(patientId))
          ..orderBy([(r) => OrderingTerm.asc(r.dueDate)]))
        .get();
  }

  /// Get due reminders
  Future<List<ClinicalReminder>> getDueReminders(int patientId) async {
    final now = DateTime.now();
    return (_db.select(_db.clinicalReminders)
          ..where((r) =>
              r.patientId.equals(patientId) &
              r.status.equals('due') &
              r.dueDate.isSmallerOrEqualValue(now))
          ..orderBy([(r) => OrderingTerm.asc(r.priority), (r) => OrderingTerm.asc(r.dueDate)]))
        .get();
  }

  /// Get upcoming reminders
  Future<List<ClinicalReminder>> getUpcomingReminders(int patientId, {int days = 30, int? daysAhead}) async {
    final effectiveDays = daysAhead ?? days;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: effectiveDays));
    return (_db.select(_db.clinicalReminders)
          ..where((r) =>
              r.patientId.equals(patientId) &
              r.status.equals('due') &
              r.dueDate.isBiggerThanValue(now) &
              r.dueDate.isSmallerOrEqualValue(futureDate))
          ..orderBy([(r) => OrderingTerm.asc(r.dueDate)]))
        .get();
  }

  /// Get reminder by ID
  Future<ClinicalReminder?> getReminderById(int id) async {
    return (_db.select(_db.clinicalReminders)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Complete reminder
  Future<bool> completeReminder({
    required int id,
    int? completedEncounterId,
    String? notes,
  }) async {
    final existing = await getReminderById(id);
    if (existing == null) return false;

    await (_db.update(_db.clinicalReminders)..where((r) => r.id.equals(id)))
        .write(ClinicalRemindersCompanion(
          status: const Value('completed'),
          lastCompletedDate: Value(DateTime.now()),
          completedEncounterId: completedEncounterId != null ? Value(completedEncounterId) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalReminder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'complete_reminder'},
    );

    return true;
  }

  /// Decline reminder
  Future<bool> declineReminder({
    required int id,
    required String reason,
  }) async {
    final existing = await getReminderById(id);
    if (existing == null) return false;

    await (_db.update(_db.clinicalReminders)..where((r) => r.id.equals(id)))
        .write(ClinicalRemindersCompanion(
          status: const Value('declined'),
          declinedReason: Value(reason),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalReminder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'decline_reminder', 'reason': reason},
    );

    return true;
  }

  /// Snooze reminder
  Future<bool> snoozeReminder({
    required int id,
    required DateTime newDueDate,
  }) async {
    final existing = await getReminderById(id);
    if (existing == null) return false;

    await (_db.update(_db.clinicalReminders)..where((r) => r.id.equals(id)))
        .write(ClinicalRemindersCompanion(
          dueDate: Value(newDueDate),
          status: const Value('due'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.clinicalReminder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'snooze_reminder', 'new_due_date': newDueDate.toIso8601String()},
    );

    return true;
  }

  /// Delete reminder
  Future<bool> deleteReminder(int id) async {
    final existing = await getReminderById(id);
    if (existing == null) return false;

    await (_db.delete(_db.clinicalReminders)..where((r) => r.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.clinicalReminder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_reminder'},
    );

    return true;
  }

  /// Get reminder statistics
  Future<Map<String, dynamic>> getReminderStats(int patientId) async {
    final reminders = await getRemindersForPatient(patientId);
    
    return {
      'total': reminders.length,
      'due': reminders.where((r) => r.status == 'due').length,
      'completed': reminders.where((r) => r.status == 'completed').length,
      'declined': reminders.where((r) => r.status == 'declined').length,
      'overdue': reminders.where((r) => r.status == 'due' && r.dueDate.isBefore(DateTime.now())).length,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get active reminders (screen compatibility)
  Future<List<ClinicalReminderData>> getActiveReminders(int patientId) async {
    return (_db.select(_db.clinicalReminders)
          ..where((r) => 
              r.patientId.equals(patientId) & 
              (r.status.equals('due') | r.status.equals('upcoming')))
          ..orderBy([(r) => OrderingTerm.asc(r.dueDate)]))
        .get();
  }

  /// Get completed reminders (screen compatibility)
  Future<List<ClinicalReminderData>> getCompletedReminders(int patientId) async {
    return (_db.select(_db.clinicalReminders)
          ..where((r) => 
              r.patientId.equals(patientId) & 
              r.status.equals('completed'))
          ..orderBy([(r) => OrderingTerm.desc(r.lastCompletedDate)]))
        .get();
  }

  /// Convert to model (screen compatibility)
  ClinicalReminderModel toModel(ClinicalReminderData reminder) {
    return ClinicalReminderModel(
      id: reminder.id,
      patientId: reminder.patientId,
      reminderType: ReminderType.fromValue(reminder.reminderType),
      title: reminder.title,
      description: reminder.description,
      guidelineSource: reminder.guidelineSource,
      recommendation: reminder.recommendation,
      frequency: reminder.frequency,
      dueDate: reminder.dueDate,
      lastCompletedDate: reminder.lastCompletedDate,
      nextDueDate: reminder.nextDueDate,
      status: ReminderStatus.fromValue(reminder.status),
      declinedReason: reminder.declinedReason,
      completedEncounterId: reminder.completedEncounterId,
      priority: reminder.priority,
      applicableMinAge: reminder.applicableMinAge,
      applicableMaxAge: reminder.applicableMaxAge,
      applicableGender: reminder.applicableGender,
      notes: reminder.notes,
      createdAt: reminder.createdAt,
    );
  }
}
