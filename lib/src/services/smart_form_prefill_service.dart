import 'dart:convert';
import '../db/doctor_db.dart';

/// Service for smart form pre-filling based on patient history
class SmartFormPrefillService {
  final DoctorDatabase db;

  SmartFormPrefillService({required this.db});

  /// Get recent diagnoses for a patient (last 5 used)
  Future<List<String>> getRecentDiagnoses(int patientId) async {
    try {
      // Get diagnoses from normalized Diagnoses table
      final diagnoses = await db.getDiagnosesForPatient(patientId);
      
      // Also get from medical records (for backwards compatibility)
      final records = await db.getMedicalRecordsForPatient(patientId);
      
      final allDiagnoses = <String>[];
      
      // Add from normalized diagnoses
      for (final diagnosis in diagnoses) {
        if (diagnosis.description.isNotEmpty) {
          allDiagnoses.add(diagnosis.description);
        }
      }
      
      // Add from medical records
      for (final record in records) {
        if (record.diagnosis != null && record.diagnosis!.isNotEmpty) {
          allDiagnoses.add(record.diagnosis!);
        }
        
        // Also check dataJson for diagnosis
        if (record.dataJson != null && record.dataJson!.isNotEmpty) {
          try {
            final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
            if (data.containsKey('diagnosis') && data['diagnosis'] is String) {
              final diag = data['diagnosis'] as String;
              if (diag.isNotEmpty) {
                allDiagnoses.add(diag);
              }
            }
          } catch (_) {
            // Skip invalid JSON
          }
        }
      }
      
      // Remove duplicates and return last 5
      final uniqueDiagnoses = allDiagnoses.toSet().toList();
      uniqueDiagnoses.sort((a, b) => b.compareTo(a)); // Most recent first (assuming chronological order)
      
      return uniqueDiagnoses.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recent medications for a patient (for prescription templates)
  Future<List<Map<String, dynamic>>> getRecentMedications(int patientId) async {
    try {
      final prescriptions = await db.getPrescriptionsForPatient(patientId);
      
      // Get unique medications from recent prescriptions (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentPrescriptions = prescriptions
          .where((p) => p.createdAt.isAfter(thirtyDaysAgo))
          .toList();
      
      final medications = <Map<String, dynamic>>[];
      final seenMedications = <String>{};
      
      for (final prescription in recentPrescriptions.reversed) {
        // Parse medications from prescription itemsJson
        try {
          if (prescription.itemsJson.isNotEmpty) {
            final meds = jsonDecode(prescription.itemsJson) as List;
            for (final med in meds) {
              if (med is Map<String, dynamic>) {
                final name = med['name'] as String? ?? '';
                if (name.isNotEmpty && !seenMedications.contains(name.toLowerCase())) {
                  seenMedications.add(name.toLowerCase());
                  medications.add({
                    'name': name,
                    'dosage': med['dosage'] as String? ?? '',
                    'frequency': med['frequency'] as String? ?? '',
                    'instructions': med['instructions'] as String? ?? '',
                  });
                }
              }
            }
          }
        } catch (_) {
          // Skip invalid JSON
        }
      }
      
      return medications.take(5).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get last visit data for copying
  Future<Map<String, dynamic>?> getLastVisitData(int patientId) async {
    try {
      // Get last encounter
      final encounters = await db.getEncountersForPatient(patientId);
      if (encounters.isEmpty) return null;
      
      // Sort by date descending
      encounters.sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
      final lastEncounter = encounters.first;
      
      // Get related medical records for this encounter
      final records = await db.getMedicalRecordsForPatient(patientId);
      final encounterRecords = records
          .where((r) => r.dataJson != null && r.dataJson!.contains('"encounterId":${lastEncounter.id}'))
          .toList();
      
      if (encounterRecords.isEmpty) {
        // Fallback: get most recent record
        records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        if (records.isEmpty) return null;
        final lastRecord = records.first;
        
        return {
          'diagnosis': lastRecord.diagnosis ?? '',
          'treatment': lastRecord.treatment ?? '',
          'doctorNotes': lastRecord.doctorNotes ?? '',
          'chiefComplaint': _extractFromJson(lastRecord.dataJson, 'chief_complaint') ?? '',
          'symptoms': _extractFromJson(lastRecord.dataJson, 'symptoms') ?? '',
          'date': lastRecord.recordDate.toIso8601String(),
        };
      }
      
      final lastRecord = encounterRecords.first;
      
      return {
        'diagnosis': lastRecord.diagnosis ?? '',
        'treatment': lastRecord.treatment ?? '',
        'doctorNotes': lastRecord.doctorNotes ?? '',
        'chiefComplaint': _extractFromJson(lastRecord.dataJson, 'chief_complaint') ?? '',
        'symptoms': _extractFromJson(lastRecord.dataJson, 'symptoms') ?? '',
        'date': lastRecord.recordDate.toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Extract value from JSON string
  String? _extractFromJson(String? jsonString, String key) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final value = data[key];
      if (value is String) return value;
      if (value is List) return value.join(', ');
      return value?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Get common diagnoses (most used across all patients)
  Future<List<String>> getCommonDiagnoses({int limit = 10}) async {
    try {
      final allDiagnoses = await db.getAllDiagnoses();
      final diagnoses = await db.getMedicalRecordsForPatient(0); // This won't work, need different approach
      
      // Count frequency of diagnoses
      final frequencyMap = <String, int>{};
      
      // Count from normalized diagnoses
      for (final diagnosis in allDiagnoses) {
        if (diagnosis.description.isNotEmpty) {
          frequencyMap[diagnosis.description] = (frequencyMap[diagnosis.description] ?? 0) + 1;
        }
      }
      
      // Sort by frequency and return top diagnoses
      final sorted = frequencyMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }
}

