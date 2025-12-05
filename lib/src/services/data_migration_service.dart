import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';

/// Service for migrating existing data to the new encounter-based system
/// 
/// This service handles:
/// - Creating encounters for completed appointments
/// - Linking existing vitals to encounters
/// - Extracting diagnoses from medical records
/// - Linking records to encounters
class DataMigrationService {
  DataMigrationService(this._db);

  final DoctorDatabase _db;

  /// Migration statistics
  int _appointmentsMigrated = 0;
  int _vitalsLinked = 0;
  int _diagnosesExtracted = 0;
  int _recordsLinked = 0;
  int _errors = 0;
  final List<String> _errorMessages = [];

  /// Get migration statistics
  MigrationStats get stats => MigrationStats(
    appointmentsMigrated: _appointmentsMigrated,
    vitalsLinked: _vitalsLinked,
    diagnosesExtracted: _diagnosesExtracted,
    recordsLinked: _recordsLinked,
    errors: _errors,
    errorMessages: List.unmodifiable(_errorMessages),
  );

  /// Reset statistics
  void _resetStats() {
    _appointmentsMigrated = 0;
    _vitalsLinked = 0;
    _diagnosesExtracted = 0;
    _recordsLinked = 0;
    _errors = 0;
    _errorMessages.clear();
  }

  /// Run full migration
  /// 
  /// Returns migration statistics after completion.
  /// This is idempotent - running it multiple times won't create duplicates.
  Future<MigrationStats> runFullMigration({
    void Function(String message, double progress)? onProgress,
  }) async {
    _resetStats();
    
    try {
      onProgress?.call('Starting migration...', 0.0);
      
      // Step 1: Migrate completed appointments to encounters
      onProgress?.call('Migrating appointments to encounters...', 0.1);
      await _migrateAppointmentsToEncounters();
      
      // Step 2: Link existing vitals to encounters
      onProgress?.call('Linking vitals to encounters...', 0.4);
      await _linkVitalsToEncounters();
      
      // Step 3: Extract diagnoses from medical records
      onProgress?.call('Extracting diagnoses...', 0.6);
      await _extractDiagnosesFromRecords();
      
      // Step 4: Link medical records to encounters
      onProgress?.call('Linking records to encounters...', 0.8);
      await _linkRecordsToEncounters();
      
      onProgress?.call('Migration complete!', 1.0);
      
      if (kDebugMode) {
        print('[DataMigration] Migration complete: ${stats.summary}');
      }
      
    } catch (e, stack) {
      _errors++;
      _errorMessages.add('Fatal error: $e');
      if (kDebugMode) {
        print('[DataMigration] Fatal error: $e');
        print(stack);
      }
    }
    
    return stats;
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // STEP 1: MIGRATE APPOINTMENTS TO ENCOUNTERS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Create encounters for completed appointments that don't have one
  Future<void> _migrateAppointmentsToEncounters() async {
    // Get all completed appointments
    final completedAppointments = await (_db.select(_db.appointments)
      ..where((a) => a.status.equals('completed')))
      .get();
    
    if (kDebugMode) {
      print('[DataMigration] Found ${completedAppointments.length} completed appointments');
    }
    
    for (final appointment in completedAppointments) {
      try {
        // Check if encounter already exists for this appointment
        final existingEncounter = await (_db.select(_db.encounters)
          ..where((e) => e.appointmentId.equals(appointment.id)))
          .getSingleOrNull();
        
        if (existingEncounter != null) {
          // Already migrated
          continue;
        }
        
        // Determine encounter type from appointment reason
        final encounterType = _inferEncounterType(appointment.reason);
        
        // Create encounter
        final encounterId = await _db.insertEncounter(EncountersCompanion.insert(
          patientId: appointment.patientId,
          appointmentId: Value(appointment.id),
          encounterDate: appointment.appointmentDateTime,
          encounterType: Value(encounterType),
          status: const Value('completed'),
          chiefComplaint: Value(appointment.reason),
          checkInTime: Value(appointment.appointmentDateTime),
          checkOutTime: Value(appointment.appointmentDateTime.add(
            Duration(minutes: appointment.durationMinutes),
          )),
        ));
        
        _appointmentsMigrated++;
        
        if (kDebugMode) {
          print('[DataMigration] Created encounter $encounterId for appointment ${appointment.id}');
        }
        
      } catch (e) {
        _errors++;
        _errorMessages.add('Failed to migrate appointment ${appointment.id}: $e');
        if (kDebugMode) {
          print('[DataMigration] Error migrating appointment ${appointment.id}: $e');
        }
      }
    }
  }

  String _inferEncounterType(String reason) {
    final lowerReason = reason.toLowerCase();
    if (lowerReason.contains('new') || lowerReason.contains('initial') || lowerReason.contains('first')) {
      return 'initial';
    } else if (lowerReason.contains('follow') || lowerReason.contains('review') || lowerReason.contains('check')) {
      return 'follow_up';
    } else if (lowerReason.contains('urgent') || lowerReason.contains('emergency')) {
      return 'urgent';
    } else if (lowerReason.contains('consult')) {
      return 'consultation';
    }
    return 'follow_up';
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // STEP 2: LINK VITALS TO ENCOUNTERS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Link existing vitals to encounters based on patient and date
  Future<void> _linkVitalsToEncounters() async {
    // Get all vitals without an encounter ID
    final unlinkedVitals = await (_db.select(_db.vitalSigns)
      ..where((v) => v.encounterId.isNull()))
      .get();
    
    if (kDebugMode) {
      print('[DataMigration] Found ${unlinkedVitals.length} unlinked vitals');
    }
    
    for (final vital in unlinkedVitals) {
      try {
        // Find encounter for same patient on same day
        final vitalDate = vital.recordedAt;
        final startOfDay = DateTime(vitalDate.year, vitalDate.month, vitalDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final matchingEncounter = await (_db.select(_db.encounters)
          ..where((e) => e.patientId.equals(vital.patientId))
          ..where((e) => e.encounterDate.isBiggerOrEqualValue(startOfDay))
          ..where((e) => e.encounterDate.isSmallerThanValue(endOfDay)))
          .getSingleOrNull();
        
        if (matchingEncounter != null) {
          // Link vital to encounter
          await (_db.update(_db.vitalSigns)..where((v) => v.id.equals(vital.id)))
            .write(VitalSignsCompanion(encounterId: Value(matchingEncounter.id)));
          
          _vitalsLinked++;
          
          if (kDebugMode) {
            print('[DataMigration] Linked vital ${vital.id} to encounter ${matchingEncounter.id}');
          }
        }
        
      } catch (e) {
        _errors++;
        _errorMessages.add('Failed to link vital ${vital.id}: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // STEP 3: EXTRACT DIAGNOSES FROM MEDICAL RECORDS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Extract diagnosis information from medical records into Diagnoses table
  Future<void> _extractDiagnosesFromRecords() async {
    // Get all medical records with diagnosis data
    final recordsWithDiagnosis = await (_db.select(_db.medicalRecords)
      ..where((r) => r.diagnosis.length.isBiggerThanValue(0)))
      .get();
    
    if (kDebugMode) {
      print('[DataMigration] Found ${recordsWithDiagnosis.length} records with diagnoses');
    }
    
    for (final record in recordsWithDiagnosis) {
      try {
        // Check if we already have this diagnosis for this patient
        final existingDiagnosis = await (_db.select(_db.diagnoses)
          ..where((d) => d.patientId.equals(record.patientId))
          ..where((d) => d.description.equals(record.diagnosis)))
          .getSingleOrNull();
        
        if (existingDiagnosis != null) {
          // Already exists
          continue;
        }
        
        // Try to extract ICD code if present
        final icdCode = _extractIcdCode(record.diagnosis);
        
        // Create diagnosis entry
        await _db.insertDiagnosis(DiagnosesCompanion.insert(
          patientId: record.patientId,
          icdCode: Value(icdCode ?? ''),
          description: record.diagnosis,
          diagnosedDate: record.recordDate,
          notes: Value('Migrated from medical record #${record.id}'),
        ));
        
        _diagnosesExtracted++;
        
      } catch (e) {
        _errors++;
        _errorMessages.add('Failed to extract diagnosis from record ${record.id}: $e');
      }
    }
    
    // Also extract from prescriptions
    await _extractDiagnosesFromPrescriptions();
  }

  Future<void> _extractDiagnosesFromPrescriptions() async {
    final prescriptionsWithDiagnosis = await (_db.select(_db.prescriptions)
      ..where((p) => p.diagnosis.length.isBiggerThanValue(0)))
      .get();
    
    for (final prescription in prescriptionsWithDiagnosis) {
      try {
        // Check if diagnosis already exists
        final existingDiagnosis = await (_db.select(_db.diagnoses)
          ..where((d) => d.patientId.equals(prescription.patientId))
          ..where((d) => d.description.equals(prescription.diagnosis)))
          .getSingleOrNull();
        
        if (existingDiagnosis != null) continue;
        
        final icdCode = _extractIcdCode(prescription.diagnosis);
        
        await _db.insertDiagnosis(DiagnosesCompanion.insert(
          patientId: prescription.patientId,
          icdCode: Value(icdCode ?? ''),
          description: prescription.diagnosis,
          diagnosedDate: prescription.createdAt,
          notes: Value('Migrated from prescription #${prescription.id}'),
        ));
        
        _diagnosesExtracted++;
        
      } catch (e) {
        _errors++;
        _errorMessages.add('Failed to extract diagnosis from prescription ${prescription.id}: $e');
      }
    }
  }

  /// Try to extract ICD-10 code from diagnosis text
  String? _extractIcdCode(String diagnosis) {
    // Common patterns for ICD-10 codes
    // F32.1, F41.0, Z71.1, etc.
    final icdPattern = RegExp(r'\b([A-Z]\d{2}(?:\.\d{1,2})?)\b', caseSensitive: false);
    final match = icdPattern.firstMatch(diagnosis);
    return match?.group(1)?.toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // STEP 4: LINK RECORDS TO ENCOUNTERS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Link medical records to encounters based on patient and date
  /// Note: This creates clinical notes from medical records
  Future<void> _linkRecordsToEncounters() async {
    final records = await _db.select(_db.medicalRecords).get();
    
    if (kDebugMode) {
      print('[DataMigration] Processing ${records.length} medical records');
    }
    
    for (final record in records) {
      try {
        // Find encounter for same patient on same day
        final recordDate = record.recordDate;
        final startOfDay = DateTime(recordDate.year, recordDate.month, recordDate.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        final matchingEncounter = await (_db.select(_db.encounters)
          ..where((e) => e.patientId.equals(record.patientId))
          ..where((e) => e.encounterDate.isBiggerOrEqualValue(startOfDay))
          ..where((e) => e.encounterDate.isSmallerThanValue(endOfDay)))
          .getSingleOrNull();
        
        if (matchingEncounter == null) continue;
        
        // Check if we already have a clinical note for this record
        final existingNote = await (_db.select(_db.clinicalNotes)
          ..where((n) => n.encounterId.equals(matchingEncounter.id)))
          .getSingleOrNull();
        
        if (existingNote != null) continue;
        
        // Create clinical note from medical record
        await _db.insertClinicalNote(ClinicalNotesCompanion.insert(
          encounterId: matchingEncounter.id,
          patientId: record.patientId,
          noteType: Value(_mapRecordTypeToNoteType(record.recordType)),
          subjective: Value(record.description),
          objective: const Value(''),
          assessment: Value(record.diagnosis),
          plan: Value(record.treatment),
        ));
        
        _recordsLinked++;
        
      } catch (e) {
        _errors++;
        _errorMessages.add('Failed to link record ${record.id}: $e');
      }
    }
  }

  String _mapRecordTypeToNoteType(String recordType) {
    switch (recordType) {
      case 'psychiatric_assessment':
        return 'psychiatric_eval';
      case 'general':
        return 'progress';
      case 'lab_result':
        return 'progress';
      case 'imaging':
        return 'progress';
      case 'procedure':
        return 'procedure';
      default:
        return 'progress';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Check if migration has been run
  Future<bool> needsMigration() async {
    // Check if there are completed appointments without encounters
    final completedWithoutEncounter = await (_db.selectOnly(_db.appointments)
      ..where(_db.appointments.status.equals('completed'))
      ..addColumns([_db.appointments.id.count()]))
      .map((row) => row.read(_db.appointments.id.count()))
      .getSingle();
    
    final encountersCount = await (_db.selectOnly(_db.encounters)
      ..addColumns([_db.encounters.id.count()]))
      .map((row) => row.read(_db.encounters.id.count()))
      .getSingle();
    
    // If there are completed appointments but few encounters, migration is needed
    return (completedWithoutEncounter ?? 0) > (encountersCount ?? 0);
  }

  /// Get migration preview (what would be migrated)
  Future<MigrationPreview> getPreview() async {
    final completedAppointments = await (_db.select(_db.appointments)
      ..where((a) => a.status.equals('completed')))
      .get();
    
    // Count appointments without encounters
    int appointmentsToMigrate = 0;
    for (final apt in completedAppointments) {
      final hasEncounter = await (_db.select(_db.encounters)
        ..where((e) => e.appointmentId.equals(apt.id)))
        .getSingleOrNull();
      if (hasEncounter == null) appointmentsToMigrate++;
    }
    
    final unlinkedVitals = await (_db.select(_db.vitalSigns)
      ..where((v) => v.encounterId.isNull()))
      .get();
    
    final recordsWithDiagnosis = await (_db.select(_db.medicalRecords)
      ..where((r) => r.diagnosis.length.isBiggerThanValue(0)))
      .get();
    
    return MigrationPreview(
      appointmentsToMigrate: appointmentsToMigrate,
      vitalsToLink: unlinkedVitals.length,
      diagnosesToExtract: recordsWithDiagnosis.length,
      totalRecords: (await _db.select(_db.medicalRecords).get()).length,
    );
  }
}

/// Migration statistics
class MigrationStats {
  final int appointmentsMigrated;
  final int vitalsLinked;
  final int diagnosesExtracted;
  final int recordsLinked;
  final int errors;
  final List<String> errorMessages;

  const MigrationStats({
    required this.appointmentsMigrated,
    required this.vitalsLinked,
    required this.diagnosesExtracted,
    required this.recordsLinked,
    required this.errors,
    required this.errorMessages,
  });

  String get summary => 
    'Appointments: $appointmentsMigrated, Vitals: $vitalsLinked, '
    'Diagnoses: $diagnosesExtracted, Records: $recordsLinked, Errors: $errors';
  
  bool get hasErrors => errors > 0;
  
  int get totalMigrated => 
    appointmentsMigrated + vitalsLinked + diagnosesExtracted + recordsLinked;
}

/// Preview of what will be migrated
class MigrationPreview {
  final int appointmentsToMigrate;
  final int vitalsToLink;
  final int diagnosesToExtract;
  final int totalRecords;

  const MigrationPreview({
    required this.appointmentsToMigrate,
    required this.vitalsToLink,
    required this.diagnosesToExtract,
    required this.totalRecords,
  });

  bool get needsMigration => 
    appointmentsToMigrate > 0 || vitalsToLink > 0 || diagnosesToExtract > 0;
  
  String get summary =>
    '$appointmentsToMigrate appointments, $vitalsToLink vitals, '
    '$diagnosesToExtract diagnoses, $totalRecords records';
}
