import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef RecurringAppointmentData = RecurringAppointment;

/// Service for managing recurring appointments
class RecurringAppointmentService {
  RecurringAppointmentService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create recurring appointment schedule
  Future<int> createRecurringSchedule({
    required int patientId,
    required String frequency,
    required String preferredTime,
    required String reason,
    required DateTime startDate,
    int? intervalDays,
    String? daysOfWeek,
    int? dayOfMonth,
    int? durationMinutes,
    String? appointmentType,
    String? provider,
    DateTime? endDate,
    int? maxOccurrences,
    String? notes,
  }) async {
    final id = await _db.into(_db.recurringAppointments).insert(
      RecurringAppointmentsCompanion.insert(
        patientId: patientId,
        frequency: frequency,
        preferredTime: preferredTime,
        reason: reason,
        startDate: startDate,
        intervalDays: Value(intervalDays),
        daysOfWeek: Value(daysOfWeek ?? ''),
        dayOfMonth: Value(dayOfMonth),
        durationMinutes: Value(durationMinutes ?? 30),
        appointmentType: Value(appointmentType ?? ''),
        provider: Value(provider ?? ''),
        endDate: Value(endDate),
        maxOccurrences: Value(maxOccurrences),
        isActive: const Value(true),
        status: const Value('active'),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_recurring_schedule', 'frequency': frequency},
    );

    if (kDebugMode) {
      print('[RecurringAppointmentService] Created recurring schedule $id for patient $patientId');
    }

    return id;
  }

  /// Get all recurring schedules for a patient
  Future<List<RecurringAppointment>> getRecurringSchedulesForPatient(int patientId) async {
    return (_db.select(_db.recurringAppointments)
          ..where((r) => r.patientId.equals(patientId))
          ..orderBy([(r) => OrderingTerm.asc(r.startDate)]))
        .get();
  }

  /// Get active recurring schedules
  Future<List<RecurringAppointment>> getActiveRecurringSchedules(int patientId) async {
    return (_db.select(_db.recurringAppointments)
          ..where((r) => r.patientId.equals(patientId) & r.isActive.equals(true))
          ..orderBy([(r) => OrderingTerm.asc(r.startDate)]))
        .get();
  }

  /// Get recurring schedule by ID
  Future<RecurringAppointment?> getRecurringScheduleById(int id) async {
    return (_db.select(_db.recurringAppointments)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update recurring schedule
  Future<bool> updateRecurringSchedule({
    required int id,
    String? frequency,
    String? preferredTime,
    int? durationMinutes,
    String? provider,
    DateTime? endDate,
    int? maxOccurrences,
    String? notes,
  }) async {
    final existing = await getRecurringScheduleById(id);
    if (existing == null) return false;

    await (_db.update(_db.recurringAppointments)..where((r) => r.id.equals(id)))
        .write(RecurringAppointmentsCompanion(
          frequency: frequency != null ? Value(frequency) : const Value.absent(),
          preferredTime: preferredTime != null ? Value(preferredTime) : const Value.absent(),
          durationMinutes: durationMinutes != null ? Value(durationMinutes) : const Value.absent(),
          provider: provider != null ? Value(provider) : const Value.absent(),
          endDate: endDate != null ? Value(endDate) : const Value.absent(),
          maxOccurrences: maxOccurrences != null ? Value(maxOccurrences) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_recurring_schedule'},
    );

    return true;
  }

  /// Pause recurring schedule
  Future<bool> pauseRecurringSchedule(int id) async {
    final existing = await getRecurringScheduleById(id);
    if (existing == null) return false;

    await (_db.update(_db.recurringAppointments)..where((r) => r.id.equals(id)))
        .write(const RecurringAppointmentsCompanion(
          isActive: Value(false),
          status: Value('paused'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'pause_recurring_schedule'},
    );

    return true;
  }

  /// Resume recurring schedule
  Future<bool> resumeRecurringSchedule(int id) async {
    final existing = await getRecurringScheduleById(id);
    if (existing == null) return false;

    await (_db.update(_db.recurringAppointments)..where((r) => r.id.equals(id)))
        .write(const RecurringAppointmentsCompanion(
          isActive: Value(true),
          status: Value('active'),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'resume_recurring_schedule'},
    );

    return true;
  }

  /// Cancel recurring schedule
  Future<bool> cancelRecurringSchedule(int id, {String? reason}) async {
    final existing = await getRecurringScheduleById(id);
    if (existing == null) return false;

    await (_db.update(_db.recurringAppointments)..where((r) => r.id.equals(id)))
        .write(RecurringAppointmentsCompanion(
          isActive: const Value(false),
          status: const Value('cancelled'),
          notes: reason != null ? Value('${existing.notes}\nCancelled: $reason') : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'cancel_recurring_schedule', 'reason': reason},
    );

    return true;
  }

  /// Delete recurring schedule
  Future<bool> deleteRecurringSchedule(int id) async {
    final existing = await getRecurringScheduleById(id);
    if (existing == null) return false;

    await (_db.delete(_db.recurringAppointments)..where((r) => r.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.recurringAppointment,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_recurring_schedule'},
    );

    return true;
  }

  /// Get due recurring schedules for generation
  Future<List<RecurringAppointment>> getDueForGeneration() async {
    return (_db.select(_db.recurringAppointments)
          ..where((r) => r.isActive.equals(true) & r.status.equals('active')))
        .get();
  }

  // ===== Screen compatibility methods =====

  /// Get active patterns
  Future<List<RecurringAppointment>> getActivePatterns() async {
    return (_db.select(_db.recurringAppointments)
          ..where((r) => r.isActive.equals(true) & r.status.equals('active'))
          ..orderBy([(r) => OrderingTerm.asc(r.startDate)]))
        .get();
  }

  /// Get paused or ended patterns
  Future<List<RecurringAppointment>> getPausedOrEndedPatterns() async {
    return (_db.select(_db.recurringAppointments)
          ..where((r) => 
              r.isActive.equals(false) | 
              r.status.equals('paused') | 
              r.status.equals('cancelled') |
              r.status.equals('completed'))
          ..orderBy([(r) => OrderingTerm.desc(r.startDate)]))
        .get();
  }

  /// Convert database entry to model (passthrough for compatibility)
  RecurringAppointmentData toModel(RecurringAppointment pattern) {
    return pattern;
  }

  /// Pause pattern (alias for pauseRecurringSchedule)
  Future<bool> pausePattern(int id) async {
    return pauseRecurringSchedule(id);
  }

  /// Resume pattern (alias for resumeRecurringSchedule)
  Future<bool> resumePattern(int id) async {
    return resumeRecurringSchedule(id);
  }

  /// Delete pattern (alias for deleteRecurringSchedule)
  Future<bool> deletePattern(int id) async {
    return deleteRecurringSchedule(id);
  }

  /// Generate appointment dates for a pattern
  Future<List<DateTime>> generateAppointmentDates(int id, {DateTime? endDate}) async {
    final pattern = await getRecurringScheduleById(id);
    if (pattern == null) return [];

    final end = endDate ?? DateTime.now().add(const Duration(days: 90));
    final dates = <DateTime>[];
    var current = pattern.startDate;

    while (current.isBefore(end)) {
      dates.add(current);
      switch (pattern.frequency.toLowerCase()) {
        case 'daily':
          current = current.add(Duration(days: pattern.intervalDays ?? 1));
          break;
        case 'weekly':
          current = current.add(Duration(days: (pattern.intervalDays ?? 1) * 7));
          break;
        case 'biweekly':
          current = current.add(const Duration(days: 14));
          break;
        case 'monthly':
          current = DateTime(current.year, current.month + 1, current.day);
          break;
        case 'quarterly':
          current = DateTime(current.year, current.month + 3, current.day);
          break;
        default:
          current = current.add(Duration(days: pattern.intervalDays ?? 7));
      }
    }

    return dates;
  }

  /// Create pattern (screen-compatible signature)
  Future<int> createPattern({
    required int patientId,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? appointmentType,
    String? preferredDay,
    String? preferredTime,
    int? duration,
    String? notes,
  }) async {
    return createRecurringSchedule(
      patientId: patientId,
      frequency: frequency,
      preferredTime: preferredTime ?? '09:00',
      reason: appointmentType ?? 'Recurring appointment',
      startDate: startDate,
      endDate: endDate,
      daysOfWeek: preferredDay,
      durationMinutes: duration,
      appointmentType: appointmentType,
      notes: notes,
    );
  }

  /// Update pattern (screen-compatible signature)
  Future<bool> updatePattern({
    required int id,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? appointmentType,
    String? preferredDay,
    String? preferredTime,
    int? duration,
    String? notes,
  }) async {
    return updateRecurringSchedule(
      id: id,
      frequency: frequency,
      preferredTime: preferredTime,
      durationMinutes: duration,
      endDate: endDate,
      notes: notes,
    );
  }
}
