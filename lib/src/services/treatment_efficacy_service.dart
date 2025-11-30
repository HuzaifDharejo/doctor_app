import 'package:flutter/material.dart';

import '../db/doctor_db.dart';

/// Service for tracking and analyzing treatment efficacy
/// Monitors vital sign changes, medication effectiveness, and treatment outcomes
class TreatmentEfficacyService {
  const TreatmentEfficacyService();

  /// Get patient's vital sign trend over time
  Future<VitalSignTrend?> getVitalSignTrend(
    DoctorDatabase db,
    int patientId,
    String vitalType, // 'systolic_bp', 'diastolic_bp', 'heart_rate', 'temperature', 'oxygen_sat'
    {int days = 30},
  ) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final vitals = await db.getVitalSignsForPatient(patientId);
    final filteredVitals = vitals
        .where((v) => v.recordedAt.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (filteredVitals.isEmpty) return null;

    // Extract specific vital values
    List<double> values = [];
    switch (vitalType) {
      case 'systolic_bp':
        values = filteredVitals.where((v) => v.systolicBp != null).map((v) => v.systolicBp!).toList();
        break;
      case 'diastolic_bp':
        values = filteredVitals.where((v) => v.diastolicBp != null).map((v) => v.diastolicBp!).toList();
        break;
      case 'heart_rate':
        values = filteredVitals.where((v) => v.heartRate != null).map((v) => v.heartRate!.toDouble()).toList();
        break;
      case 'temperature':
        values = filteredVitals.where((v) => v.temperature != null).map((v) => v.temperature!).toList();
        break;
      case 'oxygen_sat':
        values = filteredVitals.where((v) => v.oxygenSaturation != null).map((v) => v.oxygenSaturation!).toList();
        break;
    }

    if (values.isEmpty) return null;

    final first = values.first;
    final last = values.last;
    final change = last - first;
    final percentChange = first > 0 ? (change / first * 100) : 0;

    return VitalSignTrend(
      vitalType: vitalType,
      initialValue: first,
      currentValue: last,
      change: change,
      percentChange: percentChange,
      dataPoints: values,
      recordCount: filteredVitals.length,
      startDate: filteredVitals.first.recordedAt,
      endDate: filteredVitals.last.recordedAt,
      avgValue: values.reduce((a, b) => a + b) / values.length,
      minValue: values.reduce((a, b) => a < b ? a : b),
      maxValue: values.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Get medication effectiveness ratings for a patient
  Future<MedicationEfficacy?> getMedicationEfficacy(
    DoctorDatabase db,
    int patientId,
  ) async {
    final responses = await db.getMedicationResponsesForPatient(patientId);

    if (responses.isEmpty) return null;

    // Calculate average effectiveness and side effects
    final effectivenessRatings = responses
        .where((r) => r.effectivenessRating != null)
        .map((r) => r.effectivenessRating!)
        .toList();

    final sideEffectSevere = responses
        .where((r) => r.sideEffectSeverity == 'severe')
        .length;

    final avgEffectiveness = effectivenessRatings.isNotEmpty
        ? effectivenessRatings.reduce((a, b) => a + b) / effectivenessRatings.length
        : 0.0;

    return MedicationEfficacy(
      prescriptionId: patientId,
      avgEffectiveness: avgEffectiveness,
      responseCount: responses.length,
      sideEffectsReported: responses.where((r) => r.sideEffectRating != null).length,
      severeSideEffects: sideEffectSevere,
      toleranceScore: avgEffectiveness > 7 && sideEffectSevere < 2 ? 'excellent' :
                      avgEffectiveness > 5 && sideEffectSevere < 3 ? 'good' :
                      avgEffectiveness > 3 ? 'moderate' : 'poor',
    );
  }

  /// Get treatment session progression and mood trends
  Future<TreatmentProgression?> getTreatmentProgression(
    DoctorDatabase db,
    int patientId,
    {int sessions = 10},
  ) async {
    final treatmentSessions = await db.getTreatmentSessionsForPatient(patientId);
    
    if (treatmentSessions.isEmpty) return null;

    // Sort by date and take the most recent
    final sorted = treatmentSessions.toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    
    final recentSessions = sorted.take(sessions).toList();
    
    // Reverse to chronological order
    final chronological = recentSessions.reversed.toList();
    
    final moodRatings = chronological
        .where((s) => s.moodRating != null)
        .map((s) => s.moodRating!)
        .toList();

    if (moodRatings.isEmpty) return null;

    final initialMood = moodRatings.first;
    final finalMood = moodRatings.last;
    final moodImprovement = finalMood - initialMood;

    return TreatmentProgression(
      totalSessions: treatmentSessions.length,
      moodTrend: moodRatings,
      initialMoodRating: initialMood,
      currentMoodRating: finalMood,
      moodImprovement: moodImprovement,
      positiveProgression: moodImprovement > 0,
      avgMoodRating: moodRatings.reduce((a, b) => a + b) / moodRatings.length,
      completedSessions: chronological.length,
      lastSessionDate: chronological.last.sessionDate,
      riskAssessmentCurrent: chronological.last.riskAssessment,
    );
  }

  /// Get comprehensive treatment outcome analysis
  Future<TreatmentOutcome?> getTreatmentOutcome(
    DoctorDatabase db,
    int treatmentOutcomeId,
  ) async {
    try {
      final outcome = await db.getTreatmentOutcomeById(treatmentOutcomeId);

      if (outcome == null) return null;

      // Get related vital sign trends
      final vitalTrend = await getVitalSignTrend(
        db,
        outcome.patientId,
        'systolic_bp',
        days: 60,
      );

      // Get related treatment sessions
      final sessions = await db.getTreatmentSessionsForTreatment(treatmentOutcomeId);

      return TreatmentOutcome(
        id: outcome.id,
        patientId: outcome.patientId,
        diagnoses: [outcome.diagnosis],
        treatmentPlan: outcome.treatmentDescription,
        startDate: outcome.startDate,
        expectedEndDate: outcome.nextReviewDate ?? outcome.endDate,
        actualEndDate: outcome.endDate,
        outcome: outcome.outcome,
        successStatus: _calculateSuccessStatus(outcome.outcome),
        sessionsCompleted: sessions.length,
        vitalSignImprovement: vitalTrend,
        notes: outcome.notes,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate success metrics for multiple treatments
  Future<List<TreatmentMetrics>> getPatientTreatmentMetrics(
    DoctorDatabase db,
    int patientId,
  ) async {
    final outcomes = await db.getTreatmentOutcomesForPatient(patientId);

    final metrics = <TreatmentMetrics>[];

    for (final outcome in outcomes) {
      final sessions = await db.getTreatmentSessionsForTreatment(outcome.id);

      metrics.add(TreatmentMetrics(
        treatmentId: outcome.id,
        diagnosis: outcome.diagnosis,
        startDate: outcome.startDate,
        endDate: outcome.endDate ?? DateTime.now(),
        sessionsCompleted: sessions.length,
        successRate: _calculateSuccessRate(outcome.outcome),
        successStatus: _calculateSuccessStatus(outcome.outcome),
        avgMoodImprovement: _calculateAvgMoodChange(sessions),
      ));
    }

    return metrics;
  }

  /// Get comparative treatment efficacy across patients
  Future<EfficacyComparison> getEfficacyComparison(
    DoctorDatabase db,
    String diagnosis, {
    int months = 3,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: months * 30));

    final outcomes = await db.getAllTreatmentOutcomes();
    final relatedOutcomes = outcomes
        .where((o) => o.diagnosis.contains(diagnosis) && o.startDate.isAfter(startDate))
        .toList();

    if (relatedOutcomes.isEmpty) {
      return EfficacyComparison(
        diagnosis: diagnosis,
        totalTreatments: 0,
        successRate: 0,
        avgSessionCount: 0,
        avgDuration: 0,
      );
    }

    final successfulOutcomes = relatedOutcomes
        .where((o) => o.outcome == 'improved' || o.outcome == 'resolved')
        .length;

    final sessionCounts = <int>[];
    for (final outcome in relatedOutcomes) {
      final sessions = await db.getTreatmentSessionsForTreatment(outcome.id);
      sessionCounts.add(sessions.length);
    }

    final durations = relatedOutcomes
        .map((o) => o.endDate != null 
            ? o.endDate!.difference(o.startDate).inDays 
            : DateTime.now().difference(o.startDate).inDays)
        .toList();

    return EfficacyComparison(
      diagnosis: diagnosis,
      totalTreatments: relatedOutcomes.length,
      successRate: successfulOutcomes / relatedOutcomes.length,
      avgSessionCount: sessionCounts.isEmpty ? 0 : sessionCounts.reduce((a, b) => a + b) / sessionCounts.length,
      avgDuration: durations.isEmpty ? 0 : durations.reduce((a, b) => a + b) / durations.length,
    );
  }

  // Helper methods
  String _calculateSuccessStatus(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'resolved':
        return 'Complete';
      case 'improved':
        return 'Improved';
      case 'stable':
        return 'Stable';
      case 'declined':
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  double _calculateSuccessRate(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'resolved':
        return 1.0;
      case 'improved':
        return 0.75;
      case 'stable':
        return 0.5;
      case 'declined':
        return 0.25;
      default:
        return 0.0;
    }
  }

  double _calculateAvgMoodChange(List<TreatmentSession> sessions) {
    final moodRatings = sessions
        .where((s) => s.moodRating != null)
        .map((s) => s.moodRating!)
        .toList();

    if (moodRatings.isEmpty || moodRatings.length < 2) return 0;

    return (moodRatings.last - moodRatings.first).toDouble();
  }
}


/// Model for vital sign trending
class VitalSignTrend {
  const VitalSignTrend({
    required this.vitalType,
    required this.initialValue,
    required this.currentValue,
    required this.change,
    required this.percentChange,
    required this.dataPoints,
    required this.recordCount,
    required this.startDate,
    required this.endDate,
    required this.avgValue,
    required this.minValue,
    required this.maxValue,
  });

  final String vitalType;
  final double initialValue;
  final double currentValue;
  final double change;
  final double percentChange;
  final List<double> dataPoints;
  final int recordCount;
  final DateTime startDate;
  final DateTime endDate;
  final double avgValue;
  final double minValue;
  final double maxValue;

  bool get isImproving => percentChange < 0; // Lower is better for most vitals
  String get trend => percentChange < -5 ? 'Improving' : percentChange > 5 ? 'Worsening' : 'Stable';
  Color get trendColor => percentChange < -5 ? const Color(0xFF10B981) : percentChange > 5 ? const Color(0xFFDC2626) : const Color(0xFF3B82F6);
}

/// Model for medication efficacy
class MedicationEfficacy {
  const MedicationEfficacy({
    required this.prescriptionId,
    required this.avgEffectiveness,
    required this.responseCount,
    required this.sideEffectsReported,
    required this.severeSideEffects,
    required this.toleranceScore,
  });

  final int prescriptionId;
  final double avgEffectiveness; // 0-10 scale
  final int responseCount;
  final int sideEffectsReported;
  final int severeSideEffects;
  final String toleranceScore; // 'excellent', 'good', 'moderate', 'poor'

  Color get effectivenessColor => avgEffectiveness >= 7 
      ? const Color(0xFF10B981)
      : avgEffectiveness >= 5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFDC2626);
}

/// Model for treatment session progression
class TreatmentProgression {
  const TreatmentProgression({
    required this.totalSessions,
    required this.moodTrend,
    required this.initialMoodRating,
    required this.currentMoodRating,
    required this.moodImprovement,
    required this.positiveProgression,
    required this.avgMoodRating,
    required this.completedSessions,
    required this.lastSessionDate,
    required this.riskAssessmentCurrent,
  });

  final int totalSessions;
  final List<int> moodTrend;
  final int initialMoodRating;
  final int currentMoodRating;
  final int moodImprovement;
  final bool positiveProgression;
  final double avgMoodRating;
  final int completedSessions;
  final DateTime lastSessionDate;
  final String riskAssessmentCurrent;

  String get progressStatus => moodImprovement > 2 ? 'Excellent Progress' : 
                               moodImprovement > 0 ? 'Good Progress' : 
                               moodImprovement < 0 ? 'Needs Attention' : 'Stable';
  
  Color get progressColor => moodImprovement > 2 ? const Color(0xFF10B981) : 
                             moodImprovement > 0 ? const Color(0xFFF59E0B) : 
                             const Color(0xFFDC2626);
}

/// Model for comprehensive treatment outcome
class TreatmentOutcome {
  const TreatmentOutcome({
    required this.id,
    required this.patientId,
    required this.diagnoses,
    required this.treatmentPlan,
    required this.startDate,
    required this.expectedEndDate,
    required this.actualEndDate,
    required this.outcome,
    required this.successStatus,
    required this.sessionsCompleted,
    this.vitalSignImprovement,
    required this.notes,
  });

  final int id;
  final int patientId;
  final List<String> diagnoses;
  final String treatmentPlan;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final DateTime? actualEndDate;
  final String outcome;
  final String successStatus;
  final int sessionsCompleted;
  final VitalSignTrend? vitalSignImprovement;
  final String notes;

  int get durationDays => (actualEndDate ?? DateTime.now()).difference(startDate).inDays;
  bool get isComplete => actualEndDate != null;
  bool get isOnSchedule => !isComplete || (actualEndDate ?? DateTime.now()).isBefore(expectedEndDate);
}

/// Model for treatment metrics
class TreatmentMetrics {
  const TreatmentMetrics({
    required this.treatmentId,
    required this.diagnosis,
    required this.startDate,
    required this.endDate,
    required this.sessionsCompleted,
    required this.successRate,
    required this.successStatus,
    required this.avgMoodImprovement,
  });

  final int treatmentId;
  final String diagnosis;
  final DateTime startDate;
  final DateTime endDate;
  final int sessionsCompleted;
  final double successRate; // 0-1.0
  final String successStatus;
  final double avgMoodImprovement;

  int get durationDays => endDate.difference(startDate).inDays;
  Color get statusColor => successRate >= 0.75 ? const Color(0xFF10B981) :
                           successRate >= 0.5 ? const Color(0xFFF59E0B) :
                           const Color(0xFFDC2626);
}

/// Model for efficacy comparison across patients/diagnoses
class EfficacyComparison {
  const EfficacyComparison({
    required this.diagnosis,
    required this.totalTreatments,
    required this.successRate,
    required this.avgSessionCount,
    required this.avgDuration,
  });

  final String diagnosis;
  final int totalTreatments;
  final double successRate; // 0-1.0
  final double avgSessionCount;
  final double avgDuration; // in days

  String get efficacyLevel => successRate >= 0.75 ? 'High' :
                              successRate >= 0.5 ? 'Moderate' :
                              'Low';
  
  Color get efficacyColor => successRate >= 0.75 ? const Color(0xFF10B981) :
                             successRate >= 0.5 ? const Color(0xFFF59E0B) :
                             const Color(0xFFDC2626);
}
