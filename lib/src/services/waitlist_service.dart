import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef WaitlistData = AppointmentWaitlistData;

/// Service for managing appointment waitlist
class WaitlistService {
  WaitlistService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Add to waitlist
  Future<int> addToWaitlist({
    required int patientId,
    required String reason,
    required DateTime requestedDate,
    String? preferredProvider,
    String? preferredDays,
    String? preferredTimeStart,
    String? preferredTimeEnd,
    int? durationMinutes,
    String? urgency,
    DateTime? expirationDate,
    String? contactMethod,
    String? notes,
  }) async {
    final id = await _db.into(_db.appointmentWaitlist).insert(
      AppointmentWaitlistCompanion.insert(
        patientId: patientId,
        reason: reason,
        requestedDate: requestedDate,
        preferredProvider: Value(preferredProvider ?? ''),
        preferredDays: Value(preferredDays ?? ''),
        preferredTimeStart: Value(preferredTimeStart ?? ''),
        preferredTimeEnd: Value(preferredTimeEnd ?? ''),
        durationMinutes: Value(durationMinutes ?? 30),
        urgency: Value(urgency ?? 'routine'),
        status: const Value('waiting'),
        expirationDate: Value(expirationDate),
        contactMethod: Value(contactMethod ?? ''),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.waitlist,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'add_to_waitlist', 'reason': reason},
    );

    if (kDebugMode) {
      print('[WaitlistService] Added patient $patientId to waitlist ($id)');
    }

    return id;
  }

  /// Get all waitlist entries
  Future<List<AppointmentWaitlistData>> getAllWaitlistEntries() async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) => w.status.equals('waiting'))
          ..orderBy([
            (w) => OrderingTerm.asc(w.urgency),
            (w) => OrderingTerm.asc(w.requestedDate),
          ]))
        .get();
  }

  /// Get waitlist entries for a patient
  Future<List<AppointmentWaitlistData>> getWaitlistForPatient(int patientId) async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) => w.patientId.equals(patientId))
          ..orderBy([(w) => OrderingTerm.desc(w.requestedDate)]))
        .get();
  }

  /// Get waitlist entry by ID
  Future<AppointmentWaitlistData?> getWaitlistEntryById(int id) async {
    return (_db.select(_db.appointmentWaitlist)..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get urgent waitlist entries
  Future<List<AppointmentWaitlistData>> getUrgentWaitlist() async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) =>
              w.status.equals('waiting') &
              (w.urgency.equals('stat') | w.urgency.equals('urgent')))
          ..orderBy([(w) => OrderingTerm.asc(w.requestedDate)]))
        .get();
  }

  /// Update waitlist entry status
  Future<bool> updateWaitlistStatus({
    required int id,
    required String status,
    int? scheduledAppointmentId,
    String? notes,
  }) async {
    final existing = await getWaitlistEntryById(id);
    if (existing == null) return false;

    await (_db.update(_db.appointmentWaitlist)..where((w) => w.id.equals(id)))
        .write(AppointmentWaitlistCompanion(
          status: Value(status),
          scheduledAppointmentId: scheduledAppointmentId != null
              ? Value(scheduledAppointmentId)
              : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.waitlist,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_waitlist_status', 'status': status},
    );

    return true;
  }

  /// Record contact attempt
  Future<bool> recordContactAttempt(int id) async {
    final existing = await getWaitlistEntryById(id);
    if (existing == null) return false;

    await (_db.update(_db.appointmentWaitlist)..where((w) => w.id.equals(id)))
        .write(AppointmentWaitlistCompanion(
          contactAttempts: Value(existing.contactAttempts + 1),
          lastContactedAt: Value(DateTime.now()),
          status: const Value('contacted'),
        ));

    return true;
  }

  /// Remove from waitlist
  Future<bool> removeFromWaitlist(int id, {String? reason}) async {
    final existing = await getWaitlistEntryById(id);
    if (existing == null) return false;

    await (_db.delete(_db.appointmentWaitlist)..where((w) => w.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.waitlist,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'remove_from_waitlist', 'reason': reason},
    );

    return true;
  }

  /// Get waitlist statistics
  Future<Map<String, dynamic>> getWaitlistStats() async {
    final entries = await getAllWaitlistEntries();
    
    final byUrgency = <String, int>{};
    for (final entry in entries) {
      byUrgency[entry.urgency] = (byUrgency[entry.urgency] ?? 0) + 1;
    }

    return {
      'total_waiting': entries.length,
      'by_urgency': byUrgency,
      'stat_count': byUrgency['stat'] ?? 0,
      'urgent_count': byUrgency['urgent'] ?? 0,
    };
  }

  /// Get total waitlist count
  Future<int> getWaitlistCount() async {
    final entries = await getAllWaitlistEntries();
    return entries.length;
  }

  /// Get waiting list entries (status = 'waiting')
  Future<List<AppointmentWaitlistData>> getWaitingList() async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) => w.status.equals('waiting'))
          ..orderBy([
            (w) => OrderingTerm.asc(w.urgency),
            (w) => OrderingTerm.asc(w.requestedDate),
          ]))
        .get();
  }

  /// Get contacted list entries (status = 'contacted')
  Future<List<AppointmentWaitlistData>> getContactedList() async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) => w.status.equals('contacted'))
          ..orderBy([(w) => OrderingTerm.desc(w.lastContactedAt)]))
        .get();
  }

  /// Get booked list entries (status = 'scheduled')
  Future<List<AppointmentWaitlistData>> getBookedList() async {
    return (_db.select(_db.appointmentWaitlist)
          ..where((w) => w.status.equals('scheduled'))
          ..orderBy([(w) => OrderingTerm.desc(w.requestedDate)]))
        .get();
  }

  /// Convert database entry to model (passthrough for compatibility)
  WaitlistData toModel(AppointmentWaitlistData entry) {
    return entry;
  }

  /// Mark entry as contacted
  Future<bool> markContacted(int id) async {
    return recordContactAttempt(id);
  }

  /// Mark entry as booked with appointment ID
  Future<bool> markBooked(int id, int appointmentId) async {
    return updateWaitlistStatus(
      id: id,
      status: 'scheduled',
      scheduledAppointmentId: appointmentId,
    );
  }
}
