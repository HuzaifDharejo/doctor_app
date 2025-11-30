import 'package:flutter/material.dart';

import '../db/doctor_db.dart';

/// Service for comprehensive allergy management and analysis
class AllergyManagementService {
  const AllergyManagementService();

  /// Get patients with a specific allergen
  Future<List<Patient>> getPatientsByAllergen(
    DoctorDatabase db,
    String allergen,
  ) async {
    final allPatients = await db.getAllPatients();
    return allPatients
        .where((p) => _normalizeAllergies(p.allergies).contains(allergen.toLowerCase()))
        .toList();
  }

  /// Get all unique allergens in the system
  Future<List<AllergenInfo>> getAllAllergens(DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    final allergenMap = <String, int>{};

    for (final patient in patients) {
      final allergies = _normalizeAllergies(patient.allergies);
      for (final allergen in allergies) {
        allergenMap[allergen] = (allergenMap[allergen] ?? 0) + 1;
      }
    }

    return allergenMap.entries
        .map((e) => AllergenInfo(name: e.key, patientCount: e.value))
        .toList()
      ..sort((a, b) => b.patientCount.compareTo(a.patientCount));
  }

  /// Get patients with multiple allergens (high-risk)
  Future<List<PatientAllergyInfo>> getHighRiskPatients(
    DoctorDatabase db, {
    int minAllergyCount = 3,
  }) async {
    final patients = await db.getAllPatients();
    final results = <PatientAllergyInfo>[];

    for (final patient in patients) {
      final allergies = _normalizeAllergies(patient.allergies);
      if (allergies.length >= minAllergyCount) {
        results.add(
          PatientAllergyInfo(
            patient: patient,
            allergyCount: allergies.length,
            allergens: allergies,
            riskLevel: _calculateRiskLevel(allergies.length),
          ),
        );
      }
    }

    return results..sort((a, b) => b.allergyCount.compareTo(a.allergyCount));
  }

  /// Get patients with specific allergen combinations
  Future<List<Patient>> getPatientsByMultipleAllergens(
    DoctorDatabase db,
    List<String> allergens,
  ) async {
    final allPatients = await db.getAllPatients();
    final normalizedSearch = allergens.map((a) => a.toLowerCase()).toSet();

    return allPatients.where((p) {
      final patientAllergens = _normalizeAllergies(p.allergies).toSet();
      return normalizedSearch.every((a) => patientAllergens.contains(a));
    }).toList();
  }

  /// Search patients by allergen (partial matching)
  Future<List<PatientAllergyInfo>> searchPatientsByAllergen(
    DoctorDatabase db,
    String query,
  ) async {
    final patients = await db.getAllPatients();
    final lowerQuery = query.toLowerCase();
    final results = <PatientAllergyInfo>[];

    for (final patient in patients) {
      final allergies = _normalizeAllergies(patient.allergies);
      final matchingAllergies =
          allergies.where((a) => a.contains(lowerQuery)).toList();

      if (matchingAllergies.isNotEmpty) {
        results.add(
          PatientAllergyInfo(
            patient: patient,
            allergyCount: allergies.length,
            allergens: allergies,
            riskLevel: _calculateRiskLevel(allergies.length),
            matchingAllergens: matchingAllergies,
          ),
        );
      }
    }

    return results
        .where((p) => p.matchingAllergens != null && p.matchingAllergens!.isNotEmpty)
        .toList();
  }

  /// Get allergen statistics for dashboard
  Future<AllergenStatistics> getAllergenStatistics(DoctorDatabase db) async {
    final patients = await db.getAllPatients();
    final allergenFrequency = <String, int>{};
    final allergenRiskMap = <String, List<String>>{};

    for (final patient in patients) {
      final allergies = _normalizeAllergies(patient.allergies);
      for (final allergen in allergies) {
        allergenFrequency[allergen] = (allergenFrequency[allergen] ?? 0) + 1;

        if (!allergenRiskMap.containsKey(allergen)) {
          allergenRiskMap[allergen] = [];
        }
        allergenRiskMap[allergen]!.add(patient.id.toString());
      }
    }

    final patientsWithAllergies =
        patients.where((p) => _normalizeAllergies(p.allergies).isNotEmpty).length;
    final patientsWithMultipleAllergies = patients
        .where((p) => _normalizeAllergies(p.allergies).length >= 2)
        .length;

    final sortedEntries = allergenFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topAllergens = sortedEntries
        .take(10)
        .map((e) => AllergenFrequency(name: e.key, count: e.value))
        .toList();

    return AllergenStatistics(
      totalPatientsWithAllergies: patientsWithAllergies,
      patientsWithMultipleAllergies: patientsWithMultipleAllergies,
      totalUniqueAllergens: allergenFrequency.length,
      mostCommonAllergens: topAllergens,
      allergenRiskMap: allergenRiskMap,
    );
  }

  /// Normalize allergies string into list
  List<String> _normalizeAllergies(String allergiesStr) {
    if (allergiesStr.isEmpty) return [];
    return allergiesStr
        .split(',')
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  /// Calculate risk level based on allergen count
  String _calculateRiskLevel(int allergyCount) {
    if (allergyCount >= 5) return 'Critical';
    if (allergyCount >= 3) return 'High';
    if (allergyCount >= 2) return 'Medium';
    return 'Low';
  }
}

/// Model for allergen information
class AllergenInfo {
  const AllergenInfo({
    required this.name,
    required this.patientCount,
  });

  final String name;
  final int patientCount;

  @override
  String toString() => '$name ($patientCount patients)';
}

/// Model for patient allergy information
class PatientAllergyInfo {
  const PatientAllergyInfo({
    required this.patient,
    required this.allergyCount,
    required this.allergens,
    required this.riskLevel,
    this.matchingAllergens,
  });

  final Patient patient;
  final int allergyCount;
  final List<String> allergens;
  final String riskLevel;
  final List<String>? matchingAllergens; // For search results

  String get initials {
    final parts = patient.firstName.split(' ');
    final firstName = parts.first[0];
    final lastName = patient.lastName.isNotEmpty ? patient.lastName[0] : '';
    return '$firstName$lastName'.toUpperCase();
  }

  String get fullName => '${patient.firstName} ${patient.lastName}'.trim();

  Color get riskColor {
    switch (riskLevel) {
      case 'Critical':
        return const Color(0xFFDC2626);
      case 'High':
        return const Color(0xFFF59E0B);
      case 'Medium':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }
}

/// Model for allergen statistics
class AllergenStatistics {
  const AllergenStatistics({
    required this.totalPatientsWithAllergies,
    required this.patientsWithMultipleAllergies,
    required this.totalUniqueAllergens,
    required this.mostCommonAllergens,
    required this.allergenRiskMap,
  });

  final int totalPatientsWithAllergies;
  final int patientsWithMultipleAllergies;
  final int totalUniqueAllergens;
  final List<AllergenFrequency> mostCommonAllergens;
  final Map<String, List<String>> allergenRiskMap;

  double get allergyPrevalence =>
      totalPatientsWithAllergies > 0 ? totalPatientsWithAllergies / 100 : 0;
}

/// Model for allergen frequency
class AllergenFrequency {
  const AllergenFrequency({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}
