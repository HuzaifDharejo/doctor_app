import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/encounter_service.dart';
import 'audit_provider.dart';

/// Provider for the EncounterService
final encounterServiceProvider = Provider<EncounterService>((ref) {
  final db = ref.watch(databaseProvider);
  final auditService = ref.watch(auditServiceProvider);
  return EncounterService(db: db, auditService: auditService);
});

/// Provider for today's encounters
final todaysEncountersProvider = FutureProvider<List<Encounter>>((ref) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getTodaysEncounters();
});

/// Provider for active (in-progress) encounters
final activeEncountersProvider = FutureProvider<List<Encounter>>((ref) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getActiveEncounters();
});

/// Provider for a patient's encounters
final patientEncountersProvider = FutureProvider.family<List<Encounter>, int>((ref, patientId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getPatientEncounters(patientId);
});

/// Provider for a specific encounter
final encounterProvider = FutureProvider.family<Encounter?, int>((ref, encounterId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getEncounter(encounterId);
});

/// Provider for encounter summary (full encounter data with vitals, notes, diagnoses)
final encounterSummaryProvider = FutureProvider.family<EncounterSummary, int>((ref, encounterId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getEncounterSummary(encounterId);
});

/// Provider for a patient's diagnoses
final patientDiagnosesProvider = FutureProvider.family<List<Diagnose>, int>((ref, patientId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getPatientDiagnoses(patientId);
});

/// Provider for a patient's active diagnoses
final activeDiagnosesProvider = FutureProvider.family<List<Diagnose>, int>((ref, patientId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getActiveDiagnoses(patientId);
});

/// Provider for an encounter's vitals
final encounterVitalsProvider = FutureProvider.family<List<VitalSign>, int>((ref, encounterId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getEncounterVitals(encounterId);
});

/// Provider for an encounter's clinical notes
final encounterNotesProvider = FutureProvider.family<List<ClinicalNote>, int>((ref, encounterId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getEncounterNotes(encounterId);
});

/// Provider for an encounter's diagnoses
final encounterDiagnosesProvider = FutureProvider.family<List<Diagnose>, int>((ref, encounterId) async {
  final service = ref.watch(encounterServiceProvider);
  return service.getEncounterDiagnoses(encounterId);
});
