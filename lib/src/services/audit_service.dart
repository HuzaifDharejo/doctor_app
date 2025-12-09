import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';

/// Actions that can be logged in the audit trail
enum AuditAction {
  // Authentication
  login('LOGIN'),
  logout('LOGOUT'),
  lockScreen('LOCK_SCREEN'),
  unlockScreen('UNLOCK_SCREEN'),
  failedLogin('FAILED_LOGIN'),
  
  // Patient actions
  createPatient('CREATE_PATIENT'),
  viewPatient('VIEW_PATIENT'),
  updatePatient('UPDATE_PATIENT'),
  deletePatient('DELETE_PATIENT'),
  searchPatients('SEARCH_PATIENTS'),
  
  // Vital signs
  createVitalSign('CREATE_VITAL_SIGN'),
  viewVitalSign('VIEW_VITAL_SIGN'),
  updateVitalSign('UPDATE_VITAL_SIGN'),
  deleteVitalSign('DELETE_VITAL_SIGN'),
  
  // Appointments
  createAppointment('CREATE_APPOINTMENT'),
  viewAppointment('VIEW_APPOINTMENT'),
  updateAppointment('UPDATE_APPOINTMENT'),
  deleteAppointment('DELETE_APPOINTMENT'),
  cancelAppointment('CANCEL_APPOINTMENT'),
  completeAppointment('COMPLETE_APPOINTMENT'),
  
  // Prescriptions
  createPrescription('CREATE_PRESCRIPTION'),
  viewPrescription('VIEW_PRESCRIPTION'),
  updatePrescription('UPDATE_PRESCRIPTION'),
  deletePrescription('DELETE_PRESCRIPTION'),
  
  // Medical records
  createMedicalRecord('CREATE_MEDICAL_RECORD'),
  viewMedicalRecord('VIEW_MEDICAL_RECORD'),
  updateMedicalRecord('UPDATE_MEDICAL_RECORD'),
  deleteMedicalRecord('DELETE_MEDICAL_RECORD'),
  
  // Invoices
  createInvoice('CREATE_INVOICE'),
  viewInvoice('VIEW_INVOICE'),
  updateInvoice('UPDATE_INVOICE'),
  deleteInvoice('DELETE_INVOICE'),
  
  // Data export/import
  exportData('EXPORT_DATA'),
  importData('IMPORT_DATA'),
  exportPdf('EXPORT_PDF'),
  backupData('BACKUP_DATA'),
  restoreData('RESTORE_DATA'),
  
  // Settings
  changeSettings('CHANGE_SETTINGS'),
  changeSecuritySettings('CHANGE_SECURITY_SETTINGS'),
  
  // Generic CRUD actions for clinical features
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE'),
  signDocument('SIGN_DOCUMENT');

  final String value;
  const AuditAction(this.value);
}

/// Entity types for audit logging
enum AuditEntityType {
  patient('PATIENT'),
  vitalSign('VITAL_SIGN'),
  appointment('APPOINTMENT'),
  prescription('PRESCRIPTION'),
  medicalRecord('MEDICAL_RECORD'),
  invoice('INVOICE'),
  treatmentSession('TREATMENT_SESSION'),
  treatmentGoal('TREATMENT_GOAL'),
  followUp('FOLLOW_UP'),
  settings('SETTINGS'),
  none(''),
  
  // Additional entity types for clinical features
  clinicalNote('CLINICAL_NOTE'),
  clinicalLetter('CLINICAL_LETTER'),
  clinicalReminder('CLINICAL_REMINDER'),
  consent('CONSENT'),
  familyHistory('FAMILY_HISTORY'),
  growthMeasurement('GROWTH_MEASUREMENT'),
  immunization('IMMUNIZATION'),
  insurance('INSURANCE'),
  labOrder('LAB_ORDER'),
  problemList('PROBLEM_LIST'),
  recurringAppointment('RECURRING_APPOINTMENT'),
  referral('REFERRAL'),
  waitlist('WAITLIST');

  final String value;
  const AuditEntityType(this.value);
}

/// Result of an audited action
enum AuditResult {
  success('SUCCESS'),
  failure('FAILURE'),
  denied('DENIED');

  final String value;
  const AuditResult(this.value);
}

/// Service for logging audit trails for HIPAA compliance
class AuditService {
  final DoctorDatabase _db;
  
  // Current doctor info - should be set when doctor logs in
  String _currentDoctorName = 'Unknown';
  String _currentDoctorRole = 'doctor';
  
  AuditService(this._db);
  
  /// Set the current doctor information
  void setCurrentDoctor(String name, {String role = 'doctor'}) {
    _currentDoctorName = name;
    _currentDoctorRole = role;
  }
  
  /// Get device information string
  String _getDeviceInfo() {
    try {
      if (kIsWeb) {
        return 'Web Browser';
      }
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Unknown Device';
    }
  }
  
  /// Log an action to the audit trail
  Future<void> log({
    required AuditAction action,
    int? patientId,
    String patientName = '',
    AuditEntityType entityType = AuditEntityType.none,
    int? entityId,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    AuditResult result = AuditResult.success,
    String notes = '',
  }) async {
    try {
      // Build action details JSON
      final details = <String, dynamic>{};
      if (beforeData != null) {
        details['before'] = beforeData;
      }
      if (afterData != null) {
        details['after'] = afterData;
      }
      
      final companion = AuditLogsCompanion(
        action: Value(action.value),
        doctorName: Value(_currentDoctorName),
        doctorRole: Value(_currentDoctorRole),
        patientId: Value(patientId),
        patientName: Value(patientName),
        entityType: Value(entityType.value),
        entityId: Value(entityId),
        actionDetails: Value(details.isNotEmpty ? jsonEncode(details) : ''),
        ipAddress: const Value(''), // Not typically available in mobile apps
        deviceInfo: Value(_getDeviceInfo()),
        result: Value(result.value),
        notes: Value(notes),
      );
      
      await _db.insertAuditLog(companion);
      
      if (kDebugMode) {
        print('[AUDIT] ${action.value} by $_currentDoctorName - ${result.value}');
      }
    } catch (e) {
      // Don't let audit logging failures crash the app
      if (kDebugMode) {
        print('[AUDIT ERROR] Failed to log: $e');
      }
    }
  }
  
  // Convenience methods for common operations
  
  /// Log patient creation
  Future<void> logPatientCreated(int patientId, String patientName, {Map<String, dynamic>? data}) async {
    await log(
      action: AuditAction.createPatient,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.patient,
      entityId: patientId,
      afterData: data,
    );
  }
  
  /// Log patient view
  Future<void> logPatientViewed(int patientId, String patientName) async {
    await log(
      action: AuditAction.viewPatient,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.patient,
      entityId: patientId,
    );
  }
  
  /// Log patient update
  Future<void> logPatientUpdated(int patientId, String patientName, {Map<String, dynamic>? before, Map<String, dynamic>? after}) async {
    await log(
      action: AuditAction.updatePatient,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.patient,
      entityId: patientId,
      beforeData: before,
      afterData: after,
    );
  }
  
  /// Log patient deletion
  Future<void> logPatientDeleted(int patientId, String patientName) async {
    await log(
      action: AuditAction.deletePatient,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.patient,
      entityId: patientId,
    );
  }
  
  /// Log vital sign creation
  Future<void> logVitalSignCreated(int patientId, String patientName, int vitalSignId) async {
    await log(
      action: AuditAction.createVitalSign,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.vitalSign,
      entityId: vitalSignId,
    );
  }
  
  /// Log appointment creation
  Future<void> logAppointmentCreated(int? patientId, String patientName, int appointmentId) async {
    await log(
      action: AuditAction.createAppointment,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.appointment,
      entityId: appointmentId,
    );
  }
  
  /// Log appointment update
  Future<void> logAppointmentUpdated(int? patientId, String patientName, int appointmentId, {String? notes}) async {
    await log(
      action: AuditAction.updateAppointment,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.appointment,
      entityId: appointmentId,
      notes: notes ?? '',
    );
  }
  
  /// Log appointment cancellation
  Future<void> logAppointmentCancelled(int? patientId, String patientName, int appointmentId) async {
    await log(
      action: AuditAction.cancelAppointment,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.appointment,
      entityId: appointmentId,
    );
  }
  
  /// Log prescription creation
  Future<void> logPrescriptionCreated(int patientId, String patientName, int prescriptionId) async {
    await log(
      action: AuditAction.createPrescription,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.prescription,
      entityId: prescriptionId,
    );
  }
  
  /// Log medical record creation
  Future<void> logMedicalRecordCreated(int patientId, String patientName, int recordId) async {
    await log(
      action: AuditAction.createMedicalRecord,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.medicalRecord,
      entityId: recordId,
    );
  }
  
  /// Log invoice creation
  Future<void> logInvoiceCreated(int patientId, String patientName, int invoiceId) async {
    await log(
      action: AuditAction.createInvoice,
      patientId: patientId,
      patientName: patientName,
      entityType: AuditEntityType.invoice,
      entityId: invoiceId,
    );
  }
  
  /// Log login
  Future<void> logLogin({AuditResult result = AuditResult.success, String notes = ''}) async {
    await log(
      action: AuditAction.login,
      result: result,
      notes: notes,
    );
  }
  
  /// Log logout
  Future<void> logLogout() async {
    await log(action: AuditAction.logout);
  }
  
  /// Log screen lock
  Future<void> logScreenLocked() async {
    await log(action: AuditAction.lockScreen);
  }
  
  /// Log screen unlock
  Future<void> logScreenUnlocked({AuditResult result = AuditResult.success}) async {
    await log(
      action: AuditAction.unlockScreen,
      result: result,
    );
  }
  
  /// Log data export
  Future<void> logDataExport({String notes = ''}) async {
    await log(
      action: AuditAction.exportData,
      notes: notes,
    );
  }
  
  /// Log PDF export
  Future<void> logPdfExport(int? patientId, String patientName, {String notes = ''}) async {
    await log(
      action: AuditAction.exportPdf,
      patientId: patientId,
      patientName: patientName,
      notes: notes,
    );
  }
  
  /// Log security settings change
  Future<void> logSecuritySettingsChanged({String notes = ''}) async {
    await log(
      action: AuditAction.changeSecuritySettings,
      entityType: AuditEntityType.settings,
      notes: notes,
    );
  }
  
  // Query methods
  
  /// Get audit logs for a specific patient
  Future<List<AuditLog>> getLogsForPatient(int patientId, {int limit = 100}) {
    return _db.getAuditLogsForPatient(patientId, limit: limit);
  }
  
  /// Get audit logs by doctor
  Future<List<AuditLog>> getLogsByDoctor(String doctorName, {int limit = 100}) {
    return _db.getAuditLogsByDoctor(doctorName, limit: limit);
  }
  
  /// Get audit logs by action type
  Future<List<AuditLog>> getLogsByAction(AuditAction action, {int limit = 100}) {
    return _db.getAuditLogsByAction(action.value, limit: limit);
  }
  
  /// Get recent audit logs
  Future<List<AuditLog>> getRecentLogs({int days = 7, int limit = 200}) {
    return _db.getRecentAuditLogs(days: days, limit: limit);
  }
}
