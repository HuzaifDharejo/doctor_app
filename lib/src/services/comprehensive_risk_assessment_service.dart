import 'dart:convert';
import 'package:doctor_app/src/db/doctor_db.dart';

/// Comprehensive risk assessment service combining multiple risk factors
class RiskFactor {
  RiskFactor({
    required this.category,
    required this.riskLevel,
    required this.description,
    required this.recommendations,
    this.dataPoint,
  });

  final String category; // 'allergy', 'drug_interaction', 'vital_sign', 'clinical', 'appointment'
  final RiskLevel riskLevel;
  final String description;
  final List<String> recommendations;
  final String? dataPoint; // specific data point that triggered the risk
}

enum RiskLevel {
  critical('Critical', 0xFFC62828, 'Immediate action required'),
  high('High', 0xFFF57C00, 'Action needed soon'),
  medium('Medium', 0xFFFFB74D, 'Monitor and review'),
  low('Low', 0xFF4CAF50, 'Standard care'),
  none('None', 0xFF2E7D32, 'No risk identified');

  const RiskLevel(this.label, this.colorValue, this.description);
  final String label;
  final int colorValue;
  final String description;
}

class ComprehensiveRiskAssessment {
  ComprehensiveRiskAssessment({
    required this.patient,
    required this.overallRiskLevel,
    required this.riskFactors,
    required this.criticalAlerts,
    required this.followUpRequired,
  });

  final Patient patient;
  final RiskLevel overallRiskLevel;
  final List<RiskFactor> riskFactors;
  final List<String> criticalAlerts;
  final bool followUpRequired;

  int get criticalRiskCount => riskFactors.where((r) => r.riskLevel == RiskLevel.critical).length;
  int get highRiskCount => riskFactors.where((r) => r.riskLevel == RiskLevel.high).length;
  int get mediumRiskCount => riskFactors.where((r) => r.riskLevel == RiskLevel.medium).length;
}

class ComprehensiveRiskAssessmentService {
  /// Perform complete risk assessment for a patient
  static ComprehensiveRiskAssessment assessPatient({
    required Patient patient,
    required List<VitalSign> recentVitals,
    required List<Prescription> activePrescriptions,
    required List<Appointment> recentAppointments,
    required List<MedicalRecord> recentAssessments,
  }) {
    final riskFactors = <RiskFactor>[];
    final criticalAlerts = <String>[];

    // 1. Allergy Risk Assessment
    riskFactors.addAll(_assessAllergyRisks(patient));

    // 2. Drug Interaction Risks
    riskFactors.addAll(_assessDrugInteractionRisks(activePrescriptions));

    // 3. Vital Signs Abnormalities
    riskFactors.addAll(_assessVitalSignsRisks(recentVitals));

    // 4. Clinical Risk Factors
    riskFactors.addAll(_assessClinicalRisks(patient, recentAssessments));

    // 5. Appointment Compliance
    riskFactors.addAll(_assessAppointmentCompliance(recentAppointments));

    // 6. Medication Adherence
    riskFactors.addAll(_assessMedicationAdherence(patient, activePrescriptions));

    // Determine overall risk level
    final overallRiskLevel = _calculateOverallRiskLevel(riskFactors);

    // Generate critical alerts
    if (riskFactors.any((r) => r.riskLevel == RiskLevel.critical)) {
      criticalAlerts.addAll(
        riskFactors
            .where((r) => r.riskLevel == RiskLevel.critical)
            .map((r) => '🔴 CRITICAL: ${r.description}'),
      );
    }

    final followUpRequired =
        overallRiskLevel == RiskLevel.critical || overallRiskLevel == RiskLevel.high;

    return ComprehensiveRiskAssessment(
      patient: patient,
      overallRiskLevel: overallRiskLevel,
      riskFactors: riskFactors,
      criticalAlerts: criticalAlerts,
      followUpRequired: followUpRequired,
    );
  }

  /// Assess allergy-related risks
  static List<RiskFactor> _assessAllergyRisks(Patient patient) {
    final risks = <RiskFactor>[];

    if (patient.allergies.isEmpty) {
      return risks;
    }

    final allergies = patient.allergies.split(',').map((a) => a.trim()).toList();

    if (allergies.isNotEmpty) {
      risks.add(
        RiskFactor(
          category: 'allergy',
          riskLevel: RiskLevel.high,
          description: 'Patient has documented allergies: ${allergies.join(", ")}',
          recommendations: [
            'Review all prescriptions against allergy list before issuing',
            'Ensure patient wears medical alert identification',
            'Keep epinephrine auto-injector accessible',
          ],
          dataPoint: allergies.join(', '),
        ),
      );
    }

    return risks;
  }

  /// Assess drug interaction risks
  static List<RiskFactor> _assessDrugInteractionRisks(List<Prescription> prescriptions) {
    final risks = <RiskFactor>[];

    if (prescriptions.length < 2) {
      return risks;
    }

    // Parse medication items from prescriptions
    final medications = <String>[];
    for (final rx in prescriptions) {
      try {
        final items = jsonDecode(rx.itemsJson) as List<dynamic>;
        for (final item in items) {
          if (item is Map) {
            medications.add((item['name'] ?? '').toString().toLowerCase());
          }
        }
      } catch (_) {
        // ignore parsing errors
      }
    }

    // Check for known drug interactions
    final severeInteractions = _checkSevereInteractions(medications);

    if (severeInteractions.isNotEmpty) {
      risks.add(
        RiskFactor(
          category: 'drug_interaction',
          riskLevel: RiskLevel.critical,
          description: 'Severe drug interactions detected: ${severeInteractions.join(", ")}',
          recommendations: [
            'Review medication regimen immediately',
            'Consider dose adjustments or alternative medications',
            'Monitor for interaction symptoms',
            'Document clinical decision in patient record',
          ],
          dataPoint: severeInteractions.join(', '),
        ),
      );
    }

    return risks;
  }

  /// Check for severe drug interactions
  static List<String> _checkSevereInteractions(List<String> medications) {
    final interactions = <String>[];

    final severeInteractionPairs = [
      ['ssri', 'maoi'],
      ['lithium', 'diuretic'],
      ['warfarin', 'nsaid'],
      ['metformin', 'contrast'],
      ['ace inhibitor', 'potassium'],
    ];

    for (final pair in severeInteractionPairs) {
      if (medications.any((m) => m.contains(pair[0])) && medications.any((m) => m.contains(pair[1]))) {
        interactions.add('${pair[0].toUpperCase()} + ${pair[1].toUpperCase()}');
      }
    }

    return interactions;
  }

  /// Assess vital signs for abnormalities
  static List<RiskFactor> _assessVitalSignsRisks(List<VitalSign> vitals) {
    final risks = <RiskFactor>[];

    if (vitals.isEmpty) {
      return risks;
    }

    final latestVital = vitals.isNotEmpty ? vitals.first : null;
    if (latestVital == null) return risks;

    // Blood Pressure Assessment
    if (latestVital.systolicBp != null && latestVital.diastolicBp != null) {
      if (latestVital.systolicBp! >= 180 || latestVital.diastolicBp! >= 120) {
        risks.add(
          RiskFactor(
            category: 'vital_sign',
            riskLevel: RiskLevel.critical,
            description: 'Hypertensive Crisis: BP ${latestVital.systolicBp}/${latestVital.diastolicBp} mmHg',
            recommendations: [
              'Contact patient immediately',
              'Consider emergency referral if symptomatic',
              'Recheck vital signs',
            ],
            dataPoint: '${latestVital.systolicBp}/${latestVital.diastolicBp}',
          ),
        );
      } else if (latestVital.systolicBp! >= 140 || latestVital.diastolicBp! >= 90) {
        risks.add(
          RiskFactor(
            category: 'vital_sign',
            riskLevel: RiskLevel.high,
            description: 'Stage 2 Hypertension: BP ${latestVital.systolicBp}/${latestVital.diastolicBp} mmHg',
            recommendations: ['Monitor BP regularly', 'Consider medication adjustment'],
            dataPoint: '${latestVital.systolicBp}/${latestVital.diastolicBp}',
          ),
        );
      }
    }

    // Heart Rate Assessment
    if (latestVital.heartRate != null) {
      if (latestVital.heartRate! > 120) {
        risks.add(
          RiskFactor(
            category: 'vital_sign',
            riskLevel: RiskLevel.high,
            description: 'Elevated Heart Rate: ${latestVital.heartRate} bpm (tachycardia)',
            recommendations: ['Assess for anxiety, infection, or cardiac issues', 'Monitor symptoms'],
            dataPoint: '${latestVital.heartRate} bpm',
          ),
        );
      } else if (latestVital.heartRate! < 50) {
        risks.add(
          RiskFactor(
            category: 'vital_sign',
            riskLevel: RiskLevel.high,
            description: 'Low Heart Rate: ${latestVital.heartRate} bpm (bradycardia)',
            recommendations: ['Evaluate for medication effects', 'Consider ECG if symptomatic'],
            dataPoint: '${latestVital.heartRate} bpm',
          ),
        );
      }
    }

    // Oxygen Saturation
    if (latestVital.oxygenSaturation != null && latestVital.oxygenSaturation! < 90) {
      risks.add(
        RiskFactor(
          category: 'vital_sign',
          riskLevel: RiskLevel.critical,
          description: 'Low Oxygen Saturation: ${latestVital.oxygenSaturation}%',
          recommendations: ['Assess respiratory status', 'Consider oxygen therapy', 'Rule out hypoxemia'],
          dataPoint: '${latestVital.oxygenSaturation}%',
        ),
      );
    }

    // Temperature
    if (latestVital.temperature != null) {
      if (latestVital.temperature! > 39) {
        risks.add(
          RiskFactor(
            category: 'vital_sign',
            riskLevel: RiskLevel.high,
            description: 'High Fever: ${latestVital.temperature}°C',
            recommendations: ['Assess for infection source', 'Consider antibiotic if indicated'],
            dataPoint: '${latestVital.temperature}°C',
          ),
        );
      }
    }

    return risks;
  }

  /// Assess clinical risk factors from medical history and assessments
  static List<RiskFactor> _assessClinicalRisks(
    Patient patient,
    List<MedicalRecord> recentAssessments,
  ) {
    final risks = <RiskFactor>[];

    // Check for high-risk diagnoses
    final medicalHistory = patient.medicalHistory.toLowerCase();
    final highRiskDiagnoses = [
      'suicidal',
      'homicidal',
      'psychosis',
      'mania',
      'severe depression',
      'bipolar',
    ];

    for (final diagnosis in highRiskDiagnoses) {
      if (medicalHistory.contains(diagnosis)) {
        risks.add(
          RiskFactor(
            category: 'clinical',
            riskLevel: RiskLevel.high,
            description: 'Patient has history of $diagnosis - requires careful monitoring',
            recommendations: [
              'Ensure frequent follow-up appointments',
              'Screen for current symptoms at each visit',
              'Have crisis protocol in place',
              'Coordinate with emergency services if needed',
            ],
            dataPoint: diagnosis,
          ),
        );
      }
    }

    // Check recent psychiatric assessments for risk indicators
    if (recentAssessments.isNotEmpty) {
      final latestAssessment = recentAssessments.first;
      try {
        final data = jsonDecode(latestAssessment.dataJson) as Map<String, dynamic>;

        // Check for suicidal/homicidal ideation
        if (data['suicidal_ideation'] == true || (data['suicidal_ideation'] as String?)?.toLowerCase() == 'yes') {
          risks.add(
            RiskFactor(
              category: 'clinical',
              riskLevel: RiskLevel.critical,
              description: 'Active suicidal ideation reported',
              recommendations: [
                'Immediate safety assessment required',
                'Consider hospitalization if high intent/plan',
                'Contact emergency services if imminent risk',
                'Document risk assessment and safety plan',
              ],
            ),
          );
        }

        if (data['homicidal_ideation'] == true || (data['homicidal_ideation'] as String?)?.toLowerCase() == 'yes') {
          risks.add(
            RiskFactor(
              category: 'clinical',
              riskLevel: RiskLevel.critical,
              description: 'Active homicidal ideation reported',
              recommendations: [
                'Immediate safety assessment required',
                'Consider duty to warn third parties',
                'Contact emergency services',
                'Document carefully with legal considerations',
              ],
            ),
          );
        }
      } catch (_) {
        // ignore parsing errors
      }
    }

    return risks;
  }

  /// Assess appointment compliance
  static List<RiskFactor> _assessAppointmentCompliance(List<Appointment> appointments) {
    final risks = <RiskFactor>[];

    final noShowCount = appointments.where((a) => a.status == 'no-show').length;
    final cancelledCount = appointments.where((a) => a.status == 'cancelled').length;
    const late Count = appointments.where((a) => a.status == 'late').length;

    if (noShowCount >= 2) {
      risks.add(
        RiskFactor(
          category: 'appointment',
          riskLevel: RiskLevel.high,
          description: 'Patient has $noShowCount no-show appointments',
          recommendations: [
            'Call patient to reschedule',
            'Discuss barriers to attendance',
            'Consider home visits or telehealth',
            'Send reminder 24 hours before appointment',
          ],
          dataPoint: '$noShowCount no-shows',
        ),
      );
    }

    if (cancelledCount >= 3) {
      risks.add(
        RiskFactor(
          category: 'appointment',
          riskLevel: RiskLevel.medium,
          description: 'Patient has cancelled $cancelledCount appointments',
          recommendations: [
            'Explore reasons for cancellations',
            'Adjust appointment times if needed',
            'Discuss treatment engagement',
          ],
          dataPoint: '$cancelledCount cancellations',
        ),
      );
    }

    return risks;
  }

  /// Assess medication adherence
  static List<RiskFactor> _assessMedicationAdherence(
    Patient patient,
    List<Prescription> prescriptions,
  ) {
    // This would be enhanced with actual adherence data from medication responses
    return [];
  }

  /// Calculate overall risk level from multiple risk factors
  static RiskLevel _calculateOverallRiskLevel(List<RiskFactor> factors) {
    if (factors.any((f) => f.riskLevel == RiskLevel.critical)) {
      return RiskLevel.critical;
    }
    if (factors.any((f) => f.riskLevel == RiskLevel.high)) {
      return RiskLevel.high;
    }
    if (factors.any((f) => f.riskLevel == RiskLevel.medium)) {
      return RiskLevel.medium;
    }
    if (factors.any((f) => f.riskLevel == RiskLevel.low)) {
      return RiskLevel.low;
    }
    return RiskLevel.none;
  }
}
