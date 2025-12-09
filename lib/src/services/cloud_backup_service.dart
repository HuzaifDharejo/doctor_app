/// Cloud Backup Service for encrypted data backup and restore
/// 
/// Provides functionality to:
/// - Export database to encrypted JSON
/// - Backup to local storage
/// - Backup to Google Drive (using existing googleapis integration)
/// - Restore from backup
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/doctor_db.dart';
import 'encryption_service.dart';
import 'logger_service.dart';

/// Backup metadata
class BackupMetadata {
  final String version;
  final DateTime createdAt;
  final String deviceId;
  final int patientCount;
  final int appointmentCount;
  final int prescriptionCount;
  final int medicalRecordCount;
  final int invoiceCount;
  final bool isEncrypted;

  const BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.deviceId,
    required this.patientCount,
    required this.appointmentCount,
    required this.prescriptionCount,
    required this.medicalRecordCount,
    required this.invoiceCount,
    required this.isEncrypted,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      version: json['version'] as String? ?? '1.0',
      createdAt: DateTime.parse(json['createdAt'] as String),
      deviceId: json['deviceId'] as String? ?? 'unknown',
      patientCount: json['patientCount'] as int? ?? 0,
      appointmentCount: json['appointmentCount'] as int? ?? 0,
      prescriptionCount: json['prescriptionCount'] as int? ?? 0,
      medicalRecordCount: json['medicalRecordCount'] as int? ?? 0,
      invoiceCount: json['invoiceCount'] as int? ?? 0,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'deviceId': deviceId,
    'patientCount': patientCount,
    'appointmentCount': appointmentCount,
    'prescriptionCount': prescriptionCount,
    'medicalRecordCount': medicalRecordCount,
    'invoiceCount': invoiceCount,
    'isEncrypted': isEncrypted,
  };
}

/// Backup result
class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;
  final BackupMetadata? metadata;

  const BackupResult({
    required this.success,
    this.filePath,
    this.error,
    this.metadata,
  });
}

/// Restore result
class RestoreResult {
  final bool success;
  final String? error;
  final BackupMetadata? metadata;
  final int patientsRestored;
  final int appointmentsRestored;
  final int prescriptionsRestored;
  final int medicalRecordsRestored;
  final int invoicesRestored;

  const RestoreResult({
    required this.success,
    this.error,
    this.metadata,
    this.patientsRestored = 0,
    this.appointmentsRestored = 0,
    this.prescriptionsRestored = 0,
    this.medicalRecordsRestored = 0,
    this.invoicesRestored = 0,
  });

  factory RestoreResult.failure(String error) => RestoreResult(
    success: false,
    error: error,
  );
}

/// Cloud Backup Service
class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  static const String _backupVersion = '1.0';
  static const String _backupFilePrefix = 'doctor_app_backup_';
  static const String _backupFileExtension = '.dab'; // Doctor App Backup

  final EncryptionService _encryption = EncryptionService();

  /// Create a full database backup
  Future<BackupResult> createBackup({
    required DoctorDatabase db,
    bool encrypt = true,
  }) async {
    // Check if running on web - file system backup not supported
    if (kIsWeb) {
      log.w('BACKUP', 'File system backup not supported on web platform');
      return const BackupResult(
        success: false,
        error: 'Backup to file system is not supported on web. Please use a native app (Android/iOS/Desktop) for backup functionality.',
      );
    }

    try {
      log.i('BACKUP', 'Starting database backup (encrypted: $encrypt)');

      // Ensure encryption is initialized
      if (encrypt) {
        await _encryption.initialize();
      }

      // Export all data
      final patients = await db.getAllPatients();
      final appointments = await db.getAllAppointments();
      final prescriptions = await db.getAllPrescriptions();
      final medicalRecords = await db.getAllMedicalRecords();
      final invoices = await db.getAllInvoices();
      final vitalSigns = await db.getAllVitalSigns();
      final auditLogs = await db.getAllAuditLogs();

      // Create backup data structure
      final backupData = {
        'metadata': BackupMetadata(
          version: _backupVersion,
          createdAt: DateTime.now(),
          deviceId: await _getDeviceId(),
          patientCount: patients.length,
          appointmentCount: appointments.length,
          prescriptionCount: prescriptions.length,
          medicalRecordCount: medicalRecords.length,
          invoiceCount: invoices.length,
          isEncrypted: encrypt,
        ).toJson(),
        'patients': patients.map((p) => _patientToJson(p)).toList(),
        'appointments': appointments.map((a) => _appointmentToJson(a)).toList(),
        'prescriptions': prescriptions.map((p) => _prescriptionToJson(p)).toList(),
        'medicalRecords': medicalRecords.map((r) => _medicalRecordToJson(r)).toList(),
        'invoices': invoices.map((i) => _invoiceToJson(i)).toList(),
        'vitalSigns': vitalSigns.map((v) => _vitalSignToJson(v)).toList(),
        'auditLogs': auditLogs.map((l) => _auditLogToJson(l)).toList(),
      };

      // Convert to JSON string
      String jsonString = jsonEncode(backupData);

      // Encrypt if requested
      if (encrypt) {
        jsonString = _encryption.encrypt(jsonString);
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = '$_backupFilePrefix$timestamp$_backupFileExtension';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(jsonString);

      log.i('BACKUP', 'Backup created successfully: $fileName');

      return BackupResult(
        success: true,
        filePath: filePath,
        metadata: BackupMetadata.fromJson(backupData['metadata'] as Map<String, dynamic>),
      );
    } catch (e) {
      log.e('BACKUP', 'Error creating backup: $e');
      return BackupResult(
        success: false,
        error: 'Failed to create backup: $e',
      );
    }
  }

  /// Share backup file
  Future<bool> shareBackup(String filePath) async {
    try {
      if (kIsWeb) {
        log.w('BACKUP', 'File sharing not supported on web');
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        log.e('BACKUP', 'Backup file not found: $filePath');
        return false;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Doctor App Backup',
        text: 'Doctor App encrypted database backup',
      );

      log.i('BACKUP', 'Backup shared successfully');
      return true;
    } catch (e) {
      log.e('BACKUP', 'Error sharing backup: $e');
      return false;
    }
  }

  /// Restore from backup file
  Future<RestoreResult> restoreFromFile({
    required String filePath,
    required DoctorDatabase db,
  }) async {
    // Check if running on web
    if (kIsWeb) {
      log.w('BACKUP', 'File system restore not supported on web platform');
      return const RestoreResult(
        success: false,
        error: 'Restore from file system is not supported on web. Please use a native app (Android/iOS/Desktop).',
      );
    }

    try {
      log.i('BACKUP', 'Starting restore from: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        return const RestoreResult(
          success: false,
          error: 'Backup file not found',
        );
      }

      String jsonString = await file.readAsString();

      // Check if encrypted and decrypt
      if (_encryption.isEncrypted(jsonString)) {
        await _encryption.initialize();
        jsonString = _encryption.decrypt(jsonString);
      }

      // Parse backup data
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = BackupMetadata.fromJson(backupData['metadata'] as Map<String, dynamic>);

      // Verify version compatibility
      if (!_isVersionCompatible(metadata.version)) {
        return RestoreResult(
          success: false,
          error: 'Backup version ${metadata.version} is not compatible',
          metadata: metadata,
        );
      }

      // Restore data
      int patientsRestored = 0;
      int appointmentsRestored = 0;
      int prescriptionsRestored = 0;
      int medicalRecordsRestored = 0;
      int invoicesRestored = 0;

      // Restore patients first (other tables depend on patient IDs)
      final patients = backupData['patients'] as List<dynamic>? ?? [];
      for (final patientJson in patients) {
        try {
          await _restorePatient(db, patientJson as Map<String, dynamic>);
          patientsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring patient: $e');
        }
      }

      // Restore appointments
      final appointments = backupData['appointments'] as List<dynamic>? ?? [];
      for (final appointmentJson in appointments) {
        try {
          await _restoreAppointment(db, appointmentJson as Map<String, dynamic>);
          appointmentsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring appointment: $e');
        }
      }

      // Restore prescriptions
      final prescriptions = backupData['prescriptions'] as List<dynamic>? ?? [];
      for (final prescriptionJson in prescriptions) {
        try {
          await _restorePrescription(db, prescriptionJson as Map<String, dynamic>);
          prescriptionsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring prescription: $e');
        }
      }

      // Restore medical records
      final medicalRecords = backupData['medicalRecords'] as List<dynamic>? ?? [];
      for (final recordJson in medicalRecords) {
        try {
          await _restoreMedicalRecord(db, recordJson as Map<String, dynamic>);
          medicalRecordsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring medical record: $e');
        }
      }

      // Restore invoices
      final invoices = backupData['invoices'] as List<dynamic>? ?? [];
      for (final invoiceJson in invoices) {
        try {
          await _restoreInvoice(db, invoiceJson as Map<String, dynamic>);
          invoicesRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring invoice: $e');
        }
      }

      // Restore vital signs
      final vitalSigns = backupData['vitalSigns'] as List<dynamic>? ?? [];
      for (final vitalJson in vitalSigns) {
        try {
          await _restoreVitalSign(db, vitalJson as Map<String, dynamic>);
        } catch (e) {
          log.w('BACKUP', 'Error restoring vital sign: $e');
        }
      }

      log.i('BACKUP', 'Restore completed: $patientsRestored patients, $appointmentsRestored appointments');

      return RestoreResult(
        success: true,
        metadata: metadata,
        patientsRestored: patientsRestored,
        appointmentsRestored: appointmentsRestored,
        prescriptionsRestored: prescriptionsRestored,
        medicalRecordsRestored: medicalRecordsRestored,
        invoicesRestored: invoicesRestored,
      );
    } catch (e) {
      log.e('BACKUP', 'Error restoring backup: $e');
      return RestoreResult(
        success: false,
        error: 'Failed to restore backup: $e',
      );
    }
  }

  /// Restore from JSON string (for cloud restore)
  Future<RestoreResult> restoreFromJson({
    required String jsonString,
    required DoctorDatabase db,
  }) async {
    try {
      // Create temp file and use restoreFromFile
      final directory = await getApplicationDocumentsDirectory();
      final tempPath = '${directory.path}/temp_restore.dab';
      final file = File(tempPath);
      await file.writeAsString(jsonString);
      
      final result = await restoreFromFile(filePath: tempPath, db: db);
      
      // Clean up temp file
      try {
        await file.delete();
      } catch (_) {}
      
      return result;
    } catch (e) {
      return RestoreResult(
        success: false,
        error: 'Failed to restore from JSON: $e',
      );
    }
  }

  /// Generate backup data without saving to file (for cloud backup)
  Future<Map<String, dynamic>> generateBackupData(DoctorDatabase db) async {
    log.i('BACKUP', 'Generating backup data...');

    // Export all data
    final patients = await db.getAllPatients();
    final appointments = await db.getAllAppointments();
    final prescriptions = await db.getAllPrescriptions();
    final medicalRecords = await db.getAllMedicalRecords();
    final invoices = await db.getAllInvoices();
    final vitalSigns = await db.getAllVitalSigns();
    final auditLogs = await db.getAllAuditLogs();

    return {
      'metadata': BackupMetadata(
        version: _backupVersion,
        createdAt: DateTime.now(),
        deviceId: await _getDeviceId(),
        patientCount: patients.length,
        appointmentCount: appointments.length,
        prescriptionCount: prescriptions.length,
        medicalRecordCount: medicalRecords.length,
        invoiceCount: invoices.length,
        isEncrypted: true,
      ).toJson(),
      'patients': patients.map((p) => _patientToJson(p)).toList(),
      'appointments': appointments.map((a) => _appointmentToJson(a)).toList(),
      'prescriptions': prescriptions.map((p) => _prescriptionToJson(p)).toList(),
      'medicalRecords': medicalRecords.map((r) => _medicalRecordToJson(r)).toList(),
      'invoices': invoices.map((i) => _invoiceToJson(i)).toList(),
      'vitalSigns': vitalSigns.map((v) => _vitalSignToJson(v)).toList(),
      'auditLogs': auditLogs.map((l) => _auditLogToJson(l)).toList(),
    };
  }

  /// Restore from backup data (for cloud restore)
  Future<RestoreResult> restoreFromData({
    required Map<String, dynamic> backupData,
    required DoctorDatabase db,
  }) async {
    try {
      log.i('BACKUP', 'Starting restore from data...');

      final metadata = BackupMetadata.fromJson(backupData['metadata'] as Map<String, dynamic>);

      // Verify version compatibility
      if (!_isVersionCompatible(metadata.version)) {
        return RestoreResult(
          success: false,
          error: 'Backup version ${metadata.version} is not compatible',
          metadata: metadata,
        );
      }

      // Restore data
      int patientsRestored = 0;
      int appointmentsRestored = 0;
      int prescriptionsRestored = 0;
      int medicalRecordsRestored = 0;
      int invoicesRestored = 0;

      // Restore patients first
      final patients = backupData['patients'] as List<dynamic>? ?? [];
      for (final patientJson in patients) {
        try {
          await _restorePatient(db, patientJson as Map<String, dynamic>);
          patientsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring patient: $e');
        }
      }

      // Restore appointments
      final appointments = backupData['appointments'] as List<dynamic>? ?? [];
      for (final appointmentJson in appointments) {
        try {
          await _restoreAppointment(db, appointmentJson as Map<String, dynamic>);
          appointmentsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring appointment: $e');
        }
      }

      // Restore prescriptions
      final prescriptions = backupData['prescriptions'] as List<dynamic>? ?? [];
      for (final prescriptionJson in prescriptions) {
        try {
          await _restorePrescription(db, prescriptionJson as Map<String, dynamic>);
          prescriptionsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring prescription: $e');
        }
      }

      // Restore medical records
      final medicalRecords = backupData['medicalRecords'] as List<dynamic>? ?? [];
      for (final recordJson in medicalRecords) {
        try {
          await _restoreMedicalRecord(db, recordJson as Map<String, dynamic>);
          medicalRecordsRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring medical record: $e');
        }
      }

      // Restore invoices
      final invoices = backupData['invoices'] as List<dynamic>? ?? [];
      for (final invoiceJson in invoices) {
        try {
          await _restoreInvoice(db, invoiceJson as Map<String, dynamic>);
          invoicesRestored++;
        } catch (e) {
          log.w('BACKUP', 'Error restoring invoice: $e');
        }
      }

      // Restore vital signs
      final vitalSigns = backupData['vitalSigns'] as List<dynamic>? ?? [];
      for (final vitalJson in vitalSigns) {
        try {
          await _restoreVitalSign(db, vitalJson as Map<String, dynamic>);
        } catch (e) {
          log.w('BACKUP', 'Error restoring vital sign: $e');
        }
      }

      log.i('BACKUP', 'Restore from data completed: $patientsRestored patients');

      return RestoreResult(
        success: true,
        metadata: metadata,
        patientsRestored: patientsRestored,
        appointmentsRestored: appointmentsRestored,
        prescriptionsRestored: prescriptionsRestored,
        medicalRecordsRestored: medicalRecordsRestored,
        invoicesRestored: invoicesRestored,
      );
    } catch (e) {
      log.e('BACKUP', 'Error restoring from data: $e');
      return RestoreResult(
        success: false,
        error: 'Failed to restore from data: $e',
      );
    }
  }

  /// List available local backups
  Future<List<BackupInfo>> listLocalBackups() async {
    try {
      if (kIsWeb) return [];

      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>().where(
        (f) => f.path.endsWith(_backupFileExtension),
      ).toList();

      final backups = <BackupInfo>[];
      for (final file in files) {
        try {
          final stat = await file.stat();
          final name = file.path.split(Platform.pathSeparator).last;
          backups.add(BackupInfo(
            fileName: name,
            filePath: file.path,
            size: stat.size,
            createdAt: stat.modified,
          ));
        } catch (_) {}
      }

      // Sort by date, newest first
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      log.e('BACKUP', 'Error listing backups: $e');
      return [];
    }
  }

  /// Delete a local backup
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        log.i('BACKUP', 'Backup deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      log.e('BACKUP', 'Error deleting backup: $e');
      return false;
    }
  }

  /// Get backup file size formatted
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Helper methods

  bool _isVersionCompatible(String version) {
    // For now, accept version 1.x
    return version.startsWith('1.');
  }

  Future<String> _getDeviceId() async {
    // Simple device identifier (not unique, just for reference)
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  // Data serialization helpers

  Map<String, dynamic> _patientToJson(Patient p) => {
    'id': p.id,
    'firstName': p.firstName,
    'lastName': p.lastName,
    'age': p.age,
    'phone': p.phone,
    'email': p.email,
    'address': p.address,
    'medicalHistory': p.medicalHistory,
    'allergies': p.allergies,
    'tags': p.tags,
    'riskLevel': p.riskLevel,
    'gender': p.gender,
    'bloodType': p.bloodType,
    'emergencyContactName': p.emergencyContactName,
    'emergencyContactPhone': p.emergencyContactPhone,
    'height': p.height,
    'weight': p.weight,
    'chronicConditions': p.chronicConditions,
    'createdAt': p.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _appointmentToJson(Appointment a) => {
    'id': a.id,
    'patientId': a.patientId,
    'appointmentDateTime': a.appointmentDateTime.toIso8601String(),
    'durationMinutes': a.durationMinutes,
    'reason': a.reason,
    'status': a.status,
    'reminderAt': a.reminderAt?.toIso8601String(),
    'notes': a.notes,
    'medicalRecordId': a.medicalRecordId,
    'createdAt': a.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _prescriptionToJson(Prescription p) => {
    'id': p.id,
    'patientId': p.patientId,
    'createdAt': p.createdAt.toIso8601String(),
    'itemsJson': p.itemsJson,
    'instructions': p.instructions,
    'isRefillable': p.isRefillable,
    'appointmentId': p.appointmentId,
    'medicalRecordId': p.medicalRecordId,
    'diagnosis': p.diagnosis,
    'chiefComplaint': p.chiefComplaint,
    'vitalsJson': p.vitalsJson,
  };

  Map<String, dynamic> _medicalRecordToJson(MedicalRecord r) => {
    'id': r.id,
    'patientId': r.patientId,
    'recordType': r.recordType,
    'title': r.title,
    'description': r.description,
    'dataJson': r.dataJson,
    'diagnosis': r.diagnosis,
    'treatment': r.treatment,
    'doctorNotes': r.doctorNotes,
    'recordDate': r.recordDate.toIso8601String(),
    'createdAt': r.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _invoiceToJson(Invoice i) => {
    'id': i.id,
    'patientId': i.patientId,
    'invoiceNumber': i.invoiceNumber,
    'invoiceDate': i.invoiceDate.toIso8601String(),
    'dueDate': i.dueDate?.toIso8601String(),
    'itemsJson': i.itemsJson,
    'subtotal': i.subtotal,
    'discountPercent': i.discountPercent,
    'taxPercent': i.taxPercent,
    'grandTotal': i.grandTotal,
    'paymentStatus': i.paymentStatus,
    'paymentMethod': i.paymentMethod,
    'notes': i.notes,
    'appointmentId': i.appointmentId,
    'createdAt': i.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _vitalSignToJson(VitalSign v) => {
    'id': v.id,
    'patientId': v.patientId,
    'systolicBp': v.systolicBp,
    'diastolicBp': v.diastolicBp,
    'heartRate': v.heartRate,
    'temperature': v.temperature,
    'respiratoryRate': v.respiratoryRate,
    'oxygenSaturation': v.oxygenSaturation,
    'weight': v.weight,
    'height': v.height,
    'notes': v.notes,
    'recordedAt': v.recordedAt.toIso8601String(),
  };

  Map<String, dynamic> _auditLogToJson(AuditLog l) => {
    'id': l.id,
    'action': l.action,
    'doctorName': l.doctorName,
    'doctorRole': l.doctorRole,
    'patientId': l.patientId,
    'patientName': l.patientName,
    'entityType': l.entityType,
    'entityId': l.entityId,
    'actionDetails': l.actionDetails,
    'ipAddress': l.ipAddress,
    'deviceInfo': l.deviceInfo,
    'result': l.result,
    'notes': l.notes,
    'createdAt': l.createdAt.toIso8601String(),
  };

  // Restore helpers

  Future<void> _restorePatient(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertPatient(PatientsCompanion.insert(
      firstName: json['firstName'] as String,
      lastName: Value(json['lastName'] as String? ?? ''),
      age: Value(json['age'] as int?),
      phone: Value(json['phone'] as String? ?? ''),
      email: Value(json['email'] as String? ?? ''),
      address: Value(json['address'] as String? ?? ''),
      medicalHistory: Value(json['medicalHistory'] as String? ?? ''),
      allergies: Value(json['allergies'] as String? ?? ''),
      tags: Value(json['tags'] as String? ?? ''),
      riskLevel: Value(json['riskLevel'] as int? ?? 0),
      gender: Value(json['gender'] as String? ?? ''),
      bloodType: Value(json['bloodType'] as String? ?? ''),
      emergencyContactName: Value(json['emergencyContactName'] as String? ?? ''),
      emergencyContactPhone: Value(json['emergencyContactPhone'] as String? ?? ''),
      height: Value(json['height'] as double?),
      weight: Value(json['weight'] as double?),
      chronicConditions: Value(json['chronicConditions'] as String? ?? ''),
    ));
  }

  Future<void> _restoreAppointment(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertAppointment(AppointmentsCompanion.insert(
      patientId: json['patientId'] as int,
      appointmentDateTime: DateTime.parse(json['appointmentDateTime'] as String),
      durationMinutes: Value(json['durationMinutes'] as int? ?? 15),
      reason: Value(json['reason'] as String? ?? ''),
      status: Value(json['status'] as String? ?? 'scheduled'),
      reminderAt: Value(json['reminderAt'] != null ? DateTime.parse(json['reminderAt'] as String) : null),
      notes: Value(json['notes'] as String? ?? ''),
      medicalRecordId: Value(json['medicalRecordId'] as int?),
    ));
  }

  Future<void> _restorePrescription(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertPrescription(PrescriptionsCompanion.insert(
      patientId: json['patientId'] as int,
      itemsJson: json['itemsJson'] as String,
      instructions: Value(json['instructions'] as String? ?? ''),
      isRefillable: Value(json['isRefillable'] as bool? ?? false),
      appointmentId: Value(json['appointmentId'] as int?),
      medicalRecordId: Value(json['medicalRecordId'] as int?),
      diagnosis: Value(json['diagnosis'] as String? ?? ''),
      chiefComplaint: Value(json['chiefComplaint'] as String? ?? ''),
      vitalsJson: Value(json['vitalsJson'] as String? ?? '{}'),
    ));
  }

  Future<void> _restoreMedicalRecord(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertMedicalRecord(MedicalRecordsCompanion.insert(
      patientId: json['patientId'] as int,
      recordType: json['recordType'] as String,
      title: json['title'] as String,
      description: Value(json['description'] as String? ?? ''),
      dataJson: Value(json['dataJson'] as String? ?? '{}'),
      diagnosis: Value(json['diagnosis'] as String? ?? ''),
      treatment: Value(json['treatment'] as String? ?? ''),
      doctorNotes: Value(json['doctorNotes'] as String? ?? ''),
      recordDate: DateTime.parse(json['recordDate'] as String),
    ));
  }

  Future<void> _restoreInvoice(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertInvoice(InvoicesCompanion.insert(
      patientId: json['patientId'] as int,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: Value(json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null),
      itemsJson: json['itemsJson'] as String,
      subtotal: Value(json['subtotal'] as double? ?? 0),
      discountPercent: Value(json['discountPercent'] as double? ?? 0),
      taxPercent: Value(json['taxPercent'] as double? ?? 0),
      grandTotal: Value(json['grandTotal'] as double? ?? 0),
      paymentStatus: Value(json['paymentStatus'] as String? ?? 'Pending'),
      paymentMethod: Value(json['paymentMethod'] as String? ?? ''),
      notes: Value(json['notes'] as String? ?? ''),
      appointmentId: Value(json['appointmentId'] as int?),
    ));
  }

  Future<void> _restoreVitalSign(DoctorDatabase db, Map<String, dynamic> json) async {
    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: json['patientId'] as int,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      systolicBp: Value((json['systolicBp'] as num?)?.toDouble()),
      diastolicBp: Value((json['diastolicBp'] as num?)?.toDouble()),
      heartRate: Value(json['heartRate'] as int?),
      temperature: Value((json['temperature'] as num?)?.toDouble()),
      respiratoryRate: Value(json['respiratoryRate'] as int?),
      oxygenSaturation: Value((json['oxygenSaturation'] as num?)?.toDouble()),
      weight: Value((json['weight'] as num?)?.toDouble()),
      height: Value((json['height'] as num?)?.toDouble()),
      notes: Value(json['notes'] as String? ?? ''),
    ));
  }
}

/// Backup file info
class BackupInfo {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;

  const BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
  });
}
