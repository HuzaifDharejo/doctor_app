import 'package:flutter/material.dart';

/// Clinical Analytics Service
/// Provides diagnosis trends, treatment success rates, and specialty-based analytics.
class ClinicalAnalyticsService {
  const ClinicalAnalyticsService();

  // ============================================================================
  // Core Methods
  // ============================================================================

  /// Get diagnosis trends over time
  Future<List<DiagnosisTrend>> getTrendsByDiagnosis({
    String? diagnosisFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var trends = _diagnosisTrendDatabase;

    if (diagnosisFilter != null && diagnosisFilter.isNotEmpty) {
      trends = trends
          .where((t) => t.diagnosis.toLowerCase().contains(diagnosisFilter.toLowerCase()))
          .toList();
    }

    if (startDate != null && endDate != null) {
      trends = trends
          .where((t) => t.date.isAfter(startDate) && t.date.isBefore(endDate))
          .toList();
    }

    return trends;
  }

  /// Get success rates by specialty
  Future<List<SpecialtySuccessRate>> getSuccessRatesBySpecialty() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _specialtySuccessRateDatabase;
  }

  /// Get overall treatment outcomes
  Future<TreatmentOutcomes> getTreatmentOutcomes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _treatmentOutcomesData;
  }

  /// Get patient demographics data
  Future<PatientDemographics> getPatientDemographics() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _patientDemographicsData;
  }

  /// Get detailed metrics for a specific diagnosis
  Future<DiagnosisMetrics?> getDiagnosisMetrics(String diagnosis) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _diagnosisMetricsDatabase.firstWhere(
      (m) => m.diagnosis.toLowerCase() == diagnosis.toLowerCase(),
      orElse: () => DiagnosisMetrics(
        diagnosis: diagnosis,
        totalCases: 0,
        successRate: 0.0,
        averageTreatmentDays: 0,
        commonComorbidities: [],
        frequentOutcomes: [],
      ),
    );
  }

  /// Get specialties comparison data
  Future<SpecialtyComparison> getSpecialtiesComparison() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return SpecialtyComparison(
      specialties: _specialtySuccessRateDatabase,
      topPerforming: _specialtySuccessRateDatabase.where((s) => s.successRate >= 85).toList(),
      needsImprovement: _specialtySuccessRateDatabase.where((s) => s.successRate < 70).toList(),
    );
  }

  // ============================================================================
  // Sample Data: Diagnosis Trends (Daily Cases over 30 days)
  // ============================================================================

  static const List<DiagnosisTrend> _diagnosisTrendDatabase = [
    // Hypertension - Increasing trend
    DiagnosisTrend(
      id: 'htn_001',
      diagnosis: 'Hypertension',
      date: DateTime(2025, 11, 1),
      casesReported: 5,
      successRate: 87.5,
      avgTreatmentDays: 12,
    ),
    DiagnosisTrend(
      id: 'htn_002',
      diagnosis: 'Hypertension',
      date: DateTime(2025, 11, 8),
      casesReported: 8,
      successRate: 89.0,
      avgTreatmentDays: 11,
    ),
    DiagnosisTrend(
      id: 'htn_003',
      diagnosis: 'Hypertension',
      date: DateTime(2025, 11, 15),
      casesReported: 12,
      successRate: 91.2,
      avgTreatmentDays: 10,
    ),
    DiagnosisTrend(
      id: 'htn_004',
      diagnosis: 'Hypertension',
      date: DateTime(2025, 11, 22),
      casesReported: 15,
      successRate: 92.5,
      avgTreatmentDays: 9,
    ),
    DiagnosisTrend(
      id: 'htn_005',
      diagnosis: 'Hypertension',
      date: DateTime(2025, 11, 29),
      casesReported: 18,
      successRate: 94.0,
      avgTreatmentDays: 8,
    ),
    // Diabetes - Stable trend
    DiagnosisTrend(
      id: 'dm_001',
      diagnosis: 'Diabetes Type 2',
      date: DateTime(2025, 11, 1),
      casesReported: 8,
      successRate: 82.3,
      avgTreatmentDays: 20,
    ),
    DiagnosisTrend(
      id: 'dm_002',
      diagnosis: 'Diabetes Type 2',
      date: DateTime(2025, 11, 8),
      casesReported: 9,
      successRate: 83.1,
      avgTreatmentDays: 19,
    ),
    DiagnosisTrend(
      id: 'dm_003',
      diagnosis: 'Diabetes Type 2',
      date: DateTime(2025, 11, 15),
      casesReported: 9,
      successRate: 84.0,
      avgTreatmentDays: 19,
    ),
    DiagnosisTrend(
      id: 'dm_004',
      diagnosis: 'Diabetes Type 2',
      date: DateTime(2025, 11, 22),
      casesReported: 10,
      successRate: 85.5,
      avgTreatmentDays: 18,
    ),
    DiagnosisTrend(
      id: 'dm_005',
      diagnosis: 'Diabetes Type 2',
      date: DateTime(2025, 11, 29),
      casesReported: 10,
      successRate: 86.2,
      avgTreatmentDays: 18,
    ),
    // Asthma - Decreasing trend (seasonal)
    DiagnosisTrend(
      id: 'ast_001',
      diagnosis: 'Asthma',
      date: DateTime(2025, 11, 1),
      casesReported: 12,
      successRate: 88.0,
      avgTreatmentDays: 7,
    ),
    DiagnosisTrend(
      id: 'ast_002',
      diagnosis: 'Asthma',
      date: DateTime(2025, 11, 8),
      casesReported: 10,
      successRate: 87.5,
      avgTreatmentDays: 8,
    ),
    DiagnosisTrend(
      id: 'ast_003',
      diagnosis: 'Asthma',
      date: DateTime(2025, 11, 15),
      casesReported: 8,
      successRate: 86.0,
      avgTreatmentDays: 8,
    ),
    DiagnosisTrend(
      id: 'ast_004',
      diagnosis: 'Asthma',
      date: DateTime(2025, 11, 22),
      casesReported: 6,
      successRate: 85.5,
      avgTreatmentDays: 9,
    ),
    DiagnosisTrend(
      id: 'ast_005',
      diagnosis: 'Asthma',
      date: DateTime(2025, 11, 29),
      casesReported: 5,
      successRate: 84.0,
      avgTreatmentDays: 10,
    ),
  ];

  // ============================================================================
  // Sample Data: Specialty Success Rates
  // ============================================================================

  static const List<SpecialtySuccessRate> _specialtySuccessRateDatabase = [
    SpecialtySuccessRate(
      id: 'card_001',
      specialty: 'Cardiology',
      totalPatients: 156,
      successfulCases: 135,
      successRate: 86.5,
      avgTreatmentDays: 14,
      readmissionRate: 8.3,
    ),
    SpecialtySuccessRate(
      id: 'endo_001',
      specialty: 'Endocrinology',
      totalPatients: 203,
      successfulCases: 175,
      successRate: 86.2,
      avgTreatmentDays: 22,
      readmissionRate: 12.5,
    ),
    SpecialtySuccessRate(
      id: 'resp_001',
      specialty: 'Respiratory Medicine',
      totalPatients: 89,
      successfulCases: 78,
      successRate: 87.6,
      avgTreatmentDays: 9,
      readmissionRate: 9.0,
    ),
    SpecialtySuccessRate(
      id: 'neuro_001',
      specialty: 'Neurology',
      totalPatients: 112,
      successfulCases: 92,
      successRate: 82.1,
      avgTreatmentDays: 18,
      readmissionRate: 14.2,
    ),
  ];

  // ============================================================================
  // Sample Data: Treatment Outcomes
  // ============================================================================

  static const TreatmentOutcomes _treatmentOutcomesData = TreatmentOutcomes(
    totalCases: 560,
    successfulCases: 479,
    partiallySuccessful: 58,
    unsuccessful: 23,
    successRate: 85.5,
    improvementRate: 10.4,
    avgTreatmentDays: 15,
    commonOutcomes: [
      'Full Recovery',
      'Improved Condition',
      'Stable Condition',
      'Ongoing Treatment',
      'Referred to Specialist',
    ],
  );

  // ============================================================================
  // Sample Data: Patient Demographics
  // ============================================================================

  static const PatientDemographics _patientDemographicsData = PatientDemographics(
    totalPatients: 1203,
    ageGroups: {
      '18-30': 156,
      '31-45': 289,
      '46-60': 412,
      '61+': 346,
    },
    genderDistribution: {
      'Male': 651,
      'Female': 552,
    },
    locationDistribution: {
      'Urban': 726,
      'Suburban': 337,
      'Rural': 140,
    },
  );

  // ============================================================================
  // Sample Data: Diagnosis-Specific Metrics
  // ============================================================================

  static const List<DiagnosisMetrics> _diagnosisMetricsDatabase = [
    DiagnosisMetrics(
      diagnosis: 'Hypertension',
      totalCases: 178,
      successRate: 92.1,
      averageTreatmentDays: 9,
      commonComorbidities: ['Diabetes', 'Obesity', 'Sleep Apnea'],
      frequentOutcomes: ['BP Controlled', 'Medication Adjusted', 'Lifestyle Modified'],
    ),
    DiagnosisMetrics(
      diagnosis: 'Diabetes Type 2',
      totalCases: 203,
      successRate: 84.7,
      averageTreatmentDays: 19,
      commonComorbidities: ['Hypertension', 'Obesity', 'Dyslipidemia'],
      frequentOutcomes: ['Glucose Controlled', 'HbA1c Improved', 'Medication Changed'],
    ),
    DiagnosisMetrics(
      diagnosis: 'Asthma',
      totalCases: 92,
      successRate: 86.9,
      averageTreatmentDays: 8,
      commonComorbidities: ['Allergic Rhinitis', 'GERD', 'Anxiety'],
      frequentOutcomes: ['Symptom Controlled', 'Inhaler Technique Improved', 'Trigger Avoided'],
    ),
    DiagnosisMetrics(
      diagnosis: 'COPD',
      totalCases: 67,
      successRate: 79.1,
      averageTreatmentDays: 25,
      commonComorbidities: ['Hypertension', 'Coronary Artery Disease', 'Anxiety'],
      frequentOutcomes: ['Exacerbation Prevented', 'Lung Function Stabilized', 'Oxygen Saturation Improved'],
    ),
  ];
}

// ============================================================================
// Data Models
// ============================================================================

/// Represents a diagnosis trend over time
class DiagnosisTrend {
  final String id;
  final String diagnosis;
  final DateTime date;
  final int casesReported;
  final double successRate;
  final int avgTreatmentDays;

  const DiagnosisTrend({
    required this.id,
    required this.diagnosis,
    required this.date,
    required this.casesReported,
    required this.successRate,
    required this.avgTreatmentDays,
  });
}

/// Represents success rate metrics for a specialty
class SpecialtySuccessRate {
  final String id;
  final String specialty;
  final int totalPatients;
  final int successfulCases;
  final double successRate;
  final int avgTreatmentDays;
  final double readmissionRate;

  const SpecialtySuccessRate({
    required this.id,
    required this.specialty,
    required this.totalPatients,
    required this.successfulCases,
    required this.successRate,
    required this.avgTreatmentDays,
    required this.readmissionRate,
  });
}

/// Represents overall treatment outcomes
class TreatmentOutcomes {
  final int totalCases;
  final int successfulCases;
  final int partiallySuccessful;
  final int unsuccessful;
  final double successRate;
  final double improvementRate;
  final int avgTreatmentDays;
  final List<String> commonOutcomes;

  const TreatmentOutcomes({
    required this.totalCases,
    required this.successfulCases,
    required this.partiallySuccessful,
    required this.unsuccessful,
    required this.successRate,
    required this.improvementRate,
    required this.avgTreatmentDays,
    required this.commonOutcomes,
  });
}

/// Represents patient demographic distribution
class PatientDemographics {
  final int totalPatients;
  final Map<String, int> ageGroups;
  final Map<String, int> genderDistribution;
  final Map<String, int> locationDistribution;

  const PatientDemographics({
    required this.totalPatients,
    required this.ageGroups,
    required this.genderDistribution,
    required this.locationDistribution,
  });
}

/// Represents metrics for a specific diagnosis
class DiagnosisMetrics {
  final String diagnosis;
  final int totalCases;
  final double successRate;
  final int averageTreatmentDays;
  final List<String> commonComorbidities;
  final List<String> frequentOutcomes;

  const DiagnosisMetrics({
    required this.diagnosis,
    required this.totalCases,
    required this.successRate,
    required this.averageTreatmentDays,
    required this.commonComorbidities,
    required this.frequentOutcomes,
  });
}

/// Represents specialty comparison data
class SpecialtyComparison {
  final List<SpecialtySuccessRate> specialties;
  final List<SpecialtySuccessRate> topPerforming;
  final List<SpecialtySuccessRate> needsImprovement;

  const SpecialtyComparison({
    required this.specialties,
    required this.topPerforming,
    required this.needsImprovement,
  });
}
