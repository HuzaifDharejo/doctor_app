/// Pulmonary Evaluation Model
/// Represents a comprehensive pulmonary clinical evaluation record
library;

import 'dart:convert';

/// Data class representing a pulmonary clinical evaluation
class PulmonaryEvaluation {
  // Presenting Complaint
  final String chiefComplaint;
  final String duration;
  final String symptomCharacter; // Dry cough, productive, hemoptysis, etc.
  
  // Associated Symptoms
  final List<String> systemicSymptoms; // Fever, weight loss, night sweats, fatigue
  final List<String> redFlags; // Hemoptysis, severe dyspnea, stridor, cyanosis
  
  // History
  final String pastPulmonaryHistory; // Previous TB, asthma, COPD, pneumonia
  final String exposureHistory; // Occupational, smoking, environmental
  final String allergyAtopyHistory; // Allergies, eczema, rhinitis
  final List<String> currentMedications;
  final List<String> comorbidities; // DM, HTN, immunocompromised, etc.
  
  // Examination
  final ChestAuscultation chestAuscultation;
  
  // Assessment
  final String impressionDiagnosis;
  final List<String> differentialDiagnosis;
  
  // Plan
  final List<String> investigationsRequired;
  final String treatmentPlan;
  final String followUpPlan;
  
  // Vitals (optional)
  final PulmonaryVitals? vitals;

  const PulmonaryEvaluation({
    this.chiefComplaint = '',
    this.duration = '',
    this.symptomCharacter = '',
    this.systemicSymptoms = const [],
    this.redFlags = const [],
    this.pastPulmonaryHistory = '',
    this.exposureHistory = '',
    this.allergyAtopyHistory = '',
    this.currentMedications = const [],
    this.comorbidities = const [],
    this.chestAuscultation = const ChestAuscultation(),
    this.impressionDiagnosis = '',
    this.differentialDiagnosis = const [],
    this.investigationsRequired = const [],
    this.treatmentPlan = '',
    this.followUpPlan = '',
    this.vitals,
  });

  /// Creates a PulmonaryEvaluation from JSON map
  factory PulmonaryEvaluation.fromJson(Map<String, dynamic> json) {
    return PulmonaryEvaluation(
      chiefComplaint: json['chief_complaint'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      symptomCharacter: json['symptom_character'] as String? ?? '',
      systemicSymptoms: _parseStringList(json['systemic_symptoms']),
      redFlags: _parseStringList(json['red_flags']),
      pastPulmonaryHistory: json['past_pulmonary_history'] as String? ?? '',
      exposureHistory: json['exposure_history'] as String? ?? '',
      allergyAtopyHistory: json['allergy_atopy_history'] as String? ?? '',
      currentMedications: _parseStringList(json['current_medications']),
      comorbidities: _parseStringList(json['comorbidities']),
      chestAuscultation: json['chest_auscultation'] != null
          ? ChestAuscultation.fromJson(json['chest_auscultation'] as Map<String, dynamic>)
          : const ChestAuscultation(),
      impressionDiagnosis: json['impression_diagnosis'] as String? ?? '',
      differentialDiagnosis: _parseStringList(json['differential_diagnosis']),
      investigationsRequired: _parseStringList(json['investigations_required']),
      treatmentPlan: json['treatment_plan'] as String? ?? '',
      followUpPlan: json['follow_up_plan'] as String? ?? '',
      vitals: json['vitals'] != null
          ? PulmonaryVitals.fromJson(json['vitals'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts PulmonaryEvaluation to JSON map
  Map<String, dynamic> toJson() {
    return {
      'chief_complaint': chiefComplaint,
      'duration': duration,
      'symptom_character': symptomCharacter,
      'systemic_symptoms': systemicSymptoms,
      'red_flags': redFlags,
      'past_pulmonary_history': pastPulmonaryHistory,
      'exposure_history': exposureHistory,
      'allergy_atopy_history': allergyAtopyHistory,
      'current_medications': currentMedications,
      'comorbidities': comorbidities,
      'chest_auscultation': chestAuscultation.toJson(),
      'impression_diagnosis': impressionDiagnosis,
      'differential_diagnosis': differentialDiagnosis,
      'investigations_required': investigationsRequired,
      'treatment_plan': treatmentPlan,
      'follow_up_plan': followUpPlan,
      if (vitals != null) 'vitals': vitals!.toJson(),
    };
  }

  /// Serializes to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Creates from JSON string
  factory PulmonaryEvaluation.fromJsonString(String jsonString) {
    return PulmonaryEvaluation.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  /// Returns a copy with updated fields
  PulmonaryEvaluation copyWith({
    String? chiefComplaint,
    String? duration,
    String? symptomCharacter,
    List<String>? systemicSymptoms,
    List<String>? redFlags,
    String? pastPulmonaryHistory,
    String? exposureHistory,
    String? allergyAtopyHistory,
    List<String>? currentMedications,
    List<String>? comorbidities,
    ChestAuscultation? chestAuscultation,
    String? impressionDiagnosis,
    List<String>? differentialDiagnosis,
    List<String>? investigationsRequired,
    String? treatmentPlan,
    String? followUpPlan,
    PulmonaryVitals? vitals,
  }) {
    return PulmonaryEvaluation(
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      duration: duration ?? this.duration,
      symptomCharacter: symptomCharacter ?? this.symptomCharacter,
      systemicSymptoms: systemicSymptoms ?? this.systemicSymptoms,
      redFlags: redFlags ?? this.redFlags,
      pastPulmonaryHistory: pastPulmonaryHistory ?? this.pastPulmonaryHistory,
      exposureHistory: exposureHistory ?? this.exposureHistory,
      allergyAtopyHistory: allergyAtopyHistory ?? this.allergyAtopyHistory,
      currentMedications: currentMedications ?? this.currentMedications,
      comorbidities: comorbidities ?? this.comorbidities,
      chestAuscultation: chestAuscultation ?? this.chestAuscultation,
      impressionDiagnosis: impressionDiagnosis ?? this.impressionDiagnosis,
      differentialDiagnosis: differentialDiagnosis ?? this.differentialDiagnosis,
      investigationsRequired: investigationsRequired ?? this.investigationsRequired,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      followUpPlan: followUpPlan ?? this.followUpPlan,
      vitals: vitals ?? this.vitals,
    );
  }
}

/// Chest auscultation findings
class ChestAuscultation {
  final String breathSounds; // Normal vesicular, bronchial, diminished, absent
  final List<String> addedSounds; // Crackles, wheeze, rhonchi, pleural rub
  final String rightUpperZone;
  final String rightMiddleZone;
  final String rightLowerZone;
  final String leftUpperZone;
  final String leftMiddleZone;
  final String leftLowerZone;
  final String additionalFindings;

  const ChestAuscultation({
    this.breathSounds = '',
    this.addedSounds = const [],
    this.rightUpperZone = '',
    this.rightMiddleZone = '',
    this.rightLowerZone = '',
    this.leftUpperZone = '',
    this.leftMiddleZone = '',
    this.leftLowerZone = '',
    this.additionalFindings = '',
  });

  factory ChestAuscultation.fromJson(Map<String, dynamic> json) {
    return ChestAuscultation(
      breathSounds: json['breath_sounds'] as String? ?? '',
      addedSounds: PulmonaryEvaluation._parseStringList(json['added_sounds']),
      rightUpperZone: json['right_upper_zone'] as String? ?? '',
      rightMiddleZone: json['right_middle_zone'] as String? ?? '',
      rightLowerZone: json['right_lower_zone'] as String? ?? '',
      leftUpperZone: json['left_upper_zone'] as String? ?? '',
      leftMiddleZone: json['left_middle_zone'] as String? ?? '',
      leftLowerZone: json['left_lower_zone'] as String? ?? '',
      additionalFindings: json['additional_findings'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breath_sounds': breathSounds,
      'added_sounds': addedSounds,
      'right_upper_zone': rightUpperZone,
      'right_middle_zone': rightMiddleZone,
      'right_lower_zone': rightLowerZone,
      'left_upper_zone': leftUpperZone,
      'left_middle_zone': leftMiddleZone,
      'left_lower_zone': leftLowerZone,
      'additional_findings': additionalFindings,
    };
  }
}

/// Pulmonary-specific vitals
class PulmonaryVitals {
  final String bloodPressure;
  final String pulse;
  final String temperature;
  final String respiratoryRate;
  final String spo2; // Oxygen saturation
  final String peakFlowRate;
  final String weight;

  const PulmonaryVitals({
    this.bloodPressure = '',
    this.pulse = '',
    this.temperature = '',
    this.respiratoryRate = '',
    this.spo2 = '',
    this.peakFlowRate = '',
    this.weight = '',
  });

  factory PulmonaryVitals.fromJson(Map<String, dynamic> json) {
    return PulmonaryVitals(
      bloodPressure: json['bp'] as String? ?? json['blood_pressure'] as String? ?? '',
      pulse: json['pulse'] as String? ?? '',
      temperature: json['temperature'] as String? ?? '',
      respiratoryRate: json['respiratory_rate'] as String? ?? '',
      spo2: json['spo2'] as String? ?? json['oxygen_saturation'] as String? ?? '',
      peakFlowRate: json['peak_flow_rate'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bp': bloodPressure,
      'pulse': pulse,
      'temperature': temperature,
      'respiratory_rate': respiratoryRate,
      'spo2': spo2,
      'peak_flow_rate': peakFlowRate,
      'weight': weight,
    };
  }
}
