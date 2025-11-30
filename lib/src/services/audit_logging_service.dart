import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../providers/db_provider.dart';

/// Audit Logging Service for HIPAA Compliance
/// Tracks all data access and modifications with doctor name, timestamp, and action details
class AuditLoggingService {
  static final AuditLoggingService _instance = AuditLoggingService._internal();

  factory AuditLoggingService() {
    return _instance;
  }

  AuditLoggingService._internal();

  // Get the database instance (will be injected by provider)
  late DoctorDatabase _database;

  void setDatabase(DoctorDatabase database) {
    _database = database;
  }

  /// Log a login action
  Future<void> logLogin({
    required String doctorName,
    required String doctorRole,
    String ipAddress = '',
    String deviceInfo = '',
  }) {
    return _logAction(
      action: 'LOGIN',
      doctorName: doctorName,
      doctorRole: doctorRole,
      entityType: 'DOCTOR',
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
      result: 'SUCCESS',
    );
  }

  /// Log a logout action
  Future<void> logLogout({
    required String doctorName,
    required String doctorRole,
    String ipAddress = '',
  }) {
    return _logAction(
      action: 'LOGOUT',
      doctorName: doctorName,
      doctorRole: doctorRole,
      entityType: 'DOCTOR',
      ipAddress: ipAddress,
      result: 'SUCCESS',
    );
  }

  /// Log patient view/access
  Future<void> logPatientAccess({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    String notes = '',
  }) {
    return _logAction(
      action: 'VIEW_PATIENT',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PATIENT',
      entityId: patientId,
      notes: notes,
      result: 'SUCCESS',
    );
  }

  /// Log patient creation
  Future<void> logPatientCreate({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required Map<String, dynamic> patientData,
  }) {
    return _logAction(
      action: 'CREATE_PATIENT',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PATIENT',
      entityId: patientId,
      actionDetails: jsonEncode({'created': patientData}),
      result: 'SUCCESS',
    );
  }

  /// Log patient update
  Future<void> logPatientUpdate({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required Map<String, dynamic> beforeValues,
    required Map<String, dynamic> afterValues,
  }) {
    return _logAction(
      action: 'UPDATE_PATIENT',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PATIENT',
      entityId: patientId,
      actionDetails: jsonEncode({
        'before': beforeValues,
        'after': afterValues,
      }),
      result: 'SUCCESS',
    );
  }

  /// Log vital sign access
  Future<void> logVitalSignAccess({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
  }) {
    return _logAction(
      action: 'VIEW_VITAL_SIGNS',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'VITAL_SIGN',
      result: 'SUCCESS',
    );
  }

  /// Log vital sign creation
  Future<void> logVitalSignCreate({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required int vitalSignId,
    required Map<String, dynamic> vitalData,
  }) {
    return _logAction(
      action: 'CREATE_VITAL_SIGN',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'VITAL_SIGN',
      entityId: vitalSignId,
      actionDetails: jsonEncode({'created': vitalData}),
      result: 'SUCCESS',
    );
  }

  /// Log prescription access
  Future<void> logPrescriptionAccess({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
  }) {
    return _logAction(
      action: 'VIEW_PRESCRIPTIONS',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PRESCRIPTION',
      result: 'SUCCESS',
    );
  }

  /// Log prescription creation
  Future<void> logPrescriptionCreate({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required int prescriptionId,
    required Map<String, dynamic> prescriptionData,
  }) {
    return _logAction(
      action: 'CREATE_PRESCRIPTION',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PRESCRIPTION',
      entityId: prescriptionId,
      actionDetails: jsonEncode({'created': prescriptionData}),
      result: 'SUCCESS',
    );
  }

  /// Log medical record access
  Future<void> logMedicalRecordAccess({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required int recordId,
    required String recordType,
  }) {
    return _logAction(
      action: 'VIEW_MEDICAL_RECORD',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'MEDICAL_RECORD',
      entityId: recordId,
      notes: 'Record Type: $recordType',
      result: 'SUCCESS',
    );
  }

  /// Log data export
  Future<void> logDataExport({
    required String doctorName,
    required String doctorRole,
    required int patientId,
    required String patientName,
    required String exportFormat,
    String exportReason = '',
  }) {
    return _logAction(
      action: 'EXPORT_DATA',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      entityType: 'PATIENT',
      entityId: patientId,
      actionDetails: jsonEncode({'format': exportFormat, 'reason': exportReason}),
      result: 'SUCCESS',
    );
  }

  /// Log access denial
  Future<void> logAccessDenial({
    required String doctorName,
    required String doctorRole,
    required int? patientId,
    required String patientName,
    required String action,
    required String reason,
  }) {
    return _logAction(
      action: 'ACCESS_DENIED',
      doctorName: doctorName,
      doctorRole: doctorRole,
      patientId: patientId,
      patientName: patientName,
      notes: 'Reason: $reason. Attempted action: $action',
      result: 'DENIED',
    );
  }

  /// Log failed access attempt
  Future<void> logFailedAccessAttempt({
    required String doctorName,
    required String doctorRole,
    required String action,
    required String reason,
  }) {
    return _logAction(
      action: 'FAILED_ACCESS_ATTEMPT',
      doctorName: doctorName,
      doctorRole: doctorRole,
      notes: reason,
      result: 'FAILURE',
    );
  }

  /// Internal method to log any action
  Future<void> _logAction({
    required String action,
    required String doctorName,
    required String doctorRole,
    int? patientId,
    String patientName = '',
    String entityType = '',
    int? entityId,
    String actionDetails = '',
    String ipAddress = '',
    String deviceInfo = '',
    required String result,
    String notes = '',
  }) async {
    try {
      final log = AuditLogsCompanion(
        action: Value(action),
        doctorName: Value(doctorName),
        doctorRole: Value(doctorRole),
        patientId: patientId != null ? Value(patientId) : const Value(null),
        patientName: Value(patientName),
        entityType: Value(entityType),
        entityId: entityId != null ? Value(entityId) : const Value(null),
        actionDetails: Value(actionDetails),
        ipAddress: Value(ipAddress),
        deviceInfo: Value(deviceInfo),
        result: Value(result),
        notes: Value(notes),
      );

      await _database.insertAuditLog(log);
    } catch (e) {
      // If audit logging fails, log to console but don't crash the app
      if (kDebugMode) {
        print('Audit logging error: $e');
      }
    }
  }

  /// Get audit logs for a specific patient
  Future<List<AuditLog>> getPatientAuditTrail(int patientId, {int limit = 100}) {
    return _database.getAuditLogsForPatient(patientId, limit: limit);
  }

  /// Get audit logs by doctor
  Future<List<AuditLog>> getDoctorAuditTrail(String doctorName, {int limit = 100}) {
    return _database.getAuditLogsByDoctor(doctorName, limit: limit);
  }

  /// Get audit logs by action type
  Future<List<AuditLog>> getAuditTrailByAction(String action, {int limit = 100}) {
    return _database.getAuditLogsByAction(action, limit: limit);
  }

  /// Get recent audit logs
  Future<List<AuditLog>> getRecentAuditTrail({int days = 7, int limit = 200}) {
    return _database.getRecentAuditLogs(days: days, limit: limit);
  }

  /// Get failed access attempts
  Future<List<AuditLog>> getFailedAccessAttempts({int limit = 100}) {
    return _database.getFailedAccessAttempts(limit: limit);
  }

  /// Get audit statistics for a date range
  Future<Map<String, int>> getAuditStatistics(DateTime startDate, DateTime endDate) {
    return _database.getAuditStatistics(startDate, endDate);
  }
}
