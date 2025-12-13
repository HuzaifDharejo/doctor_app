import 'dart:math';

/// Clinical Calculator Service
/// Provides common medical calculations for doctors
class ClinicalCalculatorService {
  // ═══════════════════════════════════════════════════════════════════════════════
  // BASIC CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Calculate BMI (Body Mass Index)
  /// Formula: weight (kg) / height (m)²
  static BmiResult calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    
    String category;
    String risk;
    
    if (bmi < 18.5) {
      category = 'Underweight';
      risk = 'Increased risk of nutritional deficiency';
    } else if (bmi < 25) {
      category = 'Normal';
      risk = 'Low risk';
    } else if (bmi < 30) {
      category = 'Overweight';
      risk = 'Increased risk of cardiovascular disease';
    } else if (bmi < 35) {
      category = 'Obese Class I';
      risk = 'High risk of cardiovascular disease';
    } else if (bmi < 40) {
      category = 'Obese Class II';
      risk = 'Very high risk';
    } else {
      category = 'Obese Class III';
      risk = 'Extremely high risk';
    }
    
    return BmiResult(
      bmi: double.parse(bmi.toStringAsFixed(1)),
      category: category,
      risk: risk,
      idealWeightRange: _calculateIdealWeightRange(heightCm),
    );
  }

  static (double, double) _calculateIdealWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    final minWeight = 18.5 * heightM * heightM;
    final maxWeight = 24.9 * heightM * heightM;
    return (double.parse(minWeight.toStringAsFixed(1)), double.parse(maxWeight.toStringAsFixed(1)));
  }

  /// Calculate Body Surface Area (BSA)
  /// Mosteller formula: sqrt((height cm × weight kg) / 3600)
  static double calculateBsa({
    required double weightKg,
    required double heightCm,
  }) {
    final bsa = sqrt((heightCm * weightKg) / 3600);
    return double.parse(bsa.toStringAsFixed(2));
  }

  /// Calculate Ideal Body Weight (IBW)
  /// Devine formula
  static double calculateIbw({
    required double heightCm,
    required bool isMale,
  }) {
    final heightInches = heightCm / 2.54;
    double ibw;
    
    if (isMale) {
      ibw = 50 + 2.3 * (heightInches - 60);
    } else {
      ibw = 45.5 + 2.3 * (heightInches - 60);
    }
    
    return double.parse(ibw.toStringAsFixed(1));
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // RENAL FUNCTION
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Calculate eGFR using CKD-EPI formula (2021)
  static GfrResult calculateGfr({
    required double creatinine, // mg/dL
    required int age,
    required bool isMale,
  }) {
    // CKD-EPI 2021 (race-free)
    double kappa = isMale ? 0.9 : 0.7;
    double alpha = isMale ? -0.302 : -0.241;
    double multiplier = isMale ? 1.0 : 1.012;
    
    double scrOverKappa = creatinine / kappa;
    double minTerm = min(scrOverKappa, 1.0);
    double maxTerm = max(scrOverKappa, 1.0);
    
    double gfr = 142 * pow(minTerm, alpha) * pow(maxTerm, -1.200) * pow(0.9938, age) * multiplier;
    
    String stage;
    String description;
    
    if (gfr >= 90) {
      stage = 'G1';
      description = 'Normal or high';
    } else if (gfr >= 60) {
      stage = 'G2';
      description = 'Mildly decreased';
    } else if (gfr >= 45) {
      stage = 'G3a';
      description = 'Mildly to moderately decreased';
    } else if (gfr >= 30) {
      stage = 'G3b';
      description = 'Moderately to severely decreased';
    } else if (gfr >= 15) {
      stage = 'G4';
      description = 'Severely decreased';
    } else {
      stage = 'G5';
      description = 'Kidney failure';
    }
    
    return GfrResult(
      gfr: double.parse(gfr.toStringAsFixed(1)),
      stage: stage,
      description: description,
      formula: 'CKD-EPI 2021',
    );
  }

  /// Calculate Creatinine Clearance (Cockcroft-Gault)
  static double calculateCrCl({
    required double creatinine, // mg/dL
    required int age,
    required double weightKg,
    required bool isMale,
  }) {
    double crcl = ((140 - age) * weightKg) / (72 * creatinine);
    if (!isMale) crcl *= 0.85;
    return double.parse(crcl.toStringAsFixed(1));
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // CARDIOVASCULAR RISK
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Calculate CHADS₂-VASc Score for Atrial Fibrillation Stroke Risk
  static ChadsVascResult calculateChadsVasc({
    required bool hasChf,
    required bool hasHypertension,
    required int age,
    required bool hasDiabetes,
    required bool hasStrokeTiaVte,
    required bool hasVascularDisease,
    required bool isFemale,
  }) {
    int score = 0;
    final breakdown = <String>[];
    
    if (hasChf) {
      score += 1;
      breakdown.add('CHF: +1');
    }
    if (hasHypertension) {
      score += 1;
      breakdown.add('Hypertension: +1');
    }
    if (age >= 75) {
      score += 2;
      breakdown.add('Age ≥75: +2');
    } else if (age >= 65) {
      score += 1;
      breakdown.add('Age 65-74: +1');
    }
    if (hasDiabetes) {
      score += 1;
      breakdown.add('Diabetes: +1');
    }
    if (hasStrokeTiaVte) {
      score += 2;
      breakdown.add('Stroke/TIA/VTE: +2');
    }
    if (hasVascularDisease) {
      score += 1;
      breakdown.add('Vascular disease: +1');
    }
    if (isFemale) {
      score += 1;
      breakdown.add('Female: +1');
    }
    
    String risk;
    String recommendation;
    double annualStrokeRisk;
    
    // Risk stratification
    switch (score) {
      case 0:
        risk = 'Low';
        annualStrokeRisk = 0.2;
        recommendation = 'No anticoagulation recommended';
      case 1:
        risk = 'Low-Moderate';
        annualStrokeRisk = 0.6;
        recommendation = 'Consider anticoagulation (especially if male)';
      case 2:
        risk = 'Moderate';
        annualStrokeRisk = 2.2;
        recommendation = 'Anticoagulation recommended';
      case 3:
        risk = 'Moderate-High';
        annualStrokeRisk = 3.2;
        recommendation = 'Anticoagulation strongly recommended';
      case 4:
        risk = 'High';
        annualStrokeRisk = 4.8;
        recommendation = 'Anticoagulation strongly recommended';
      default:
        risk = 'Very High';
        annualStrokeRisk = score >= 6 ? 9.7 : 6.7;
        recommendation = 'Anticoagulation essential';
    }
    
    return ChadsVascResult(
      score: score,
      risk: risk,
      annualStrokeRisk: annualStrokeRisk,
      recommendation: recommendation,
      breakdown: breakdown,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // PEDIATRIC CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Calculate Pediatric Drug Dose based on weight
  static PediatricDoseResult calculatePediatricDose({
    required double weightKg,
    required double dosePerKg, // mg/kg
    required double maxDose, // mg
    required String frequency,
  }) {
    double calculatedDose = weightKg * dosePerKg;
    bool exceededMax = calculatedDose > maxDose;
    double finalDose = exceededMax ? maxDose : calculatedDose;
    
    return PediatricDoseResult(
      calculatedDose: double.parse(calculatedDose.toStringAsFixed(1)),
      finalDose: double.parse(finalDose.toStringAsFixed(1)),
      exceededMaxDose: exceededMax,
      frequency: frequency,
      warning: exceededMax ? 'Calculated dose exceeds maximum. Using max dose.' : null,
    );
  }

  /// Calculate Pediatric Maintenance Fluids (Holliday-Segar)
  static MaintenanceFluidsResult calculateMaintenanceFluids({
    required double weightKg,
  }) {
    double mlPerDay;
    String formula;
    
    if (weightKg <= 10) {
      mlPerDay = weightKg * 100;
      formula = '100 mL/kg/day for first 10 kg';
    } else if (weightKg <= 20) {
      mlPerDay = 1000 + (weightKg - 10) * 50;
      formula = '1000 mL + 50 mL/kg for each kg over 10';
    } else {
      mlPerDay = 1500 + (weightKg - 20) * 20;
      formula = '1500 mL + 20 mL/kg for each kg over 20';
    }
    
    return MaintenanceFluidsResult(
      mlPerDay: mlPerDay.round(),
      mlPerHour: (mlPerDay / 24).round(),
      formula: formula,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // COMMON CLINICAL SCORES
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Wells Score for DVT
  static WellsDvtResult calculateWellsDvt({
    required bool activeCancer,
    required bool paralysisParesis,
    required bool recentBedridden,
    required bool localizedTenderness,
    required bool entireLegSwollen,
    required bool calfSwelling3cm,
    required bool pittingEdema,
    required bool collateralVeins,
    required bool previousDvt,
    required bool alternativeDiagnosisLikely,
  }) {
    int score = 0;
    final breakdown = <String>[];
    
    if (activeCancer) {
      score += 1;
      breakdown.add('Active cancer: +1');
    }
    if (paralysisParesis) {
      score += 1;
      breakdown.add('Paralysis/paresis: +1');
    }
    if (recentBedridden) {
      score += 1;
      breakdown.add('Recently bedridden >3 days: +1');
    }
    if (localizedTenderness) {
      score += 1;
      breakdown.add('Localized tenderness: +1');
    }
    if (entireLegSwollen) {
      score += 1;
      breakdown.add('Entire leg swollen: +1');
    }
    if (calfSwelling3cm) {
      score += 1;
      breakdown.add('Calf swelling >3cm: +1');
    }
    if (pittingEdema) {
      score += 1;
      breakdown.add('Pitting edema: +1');
    }
    if (collateralVeins) {
      score += 1;
      breakdown.add('Collateral superficial veins: +1');
    }
    if (previousDvt) {
      score += 1;
      breakdown.add('Previous DVT: +1');
    }
    if (alternativeDiagnosisLikely) {
      score -= 2;
      breakdown.add('Alternative diagnosis likely: -2');
    }
    
    String risk;
    double probability;
    String recommendation;
    
    if (score <= 0) {
      risk = 'Low';
      probability = 5;
      recommendation = 'D-dimer testing recommended';
    } else if (score <= 2) {
      risk = 'Moderate';
      probability = 17;
      recommendation = 'D-dimer testing recommended, consider ultrasound';
    } else {
      risk = 'High';
      probability = 53;
      recommendation = 'Ultrasound recommended';
    }
    
    return WellsDvtResult(
      score: score,
      risk: risk,
      probability: probability,
      recommendation: recommendation,
      breakdown: breakdown,
    );
  }

  /// CURB-65 Score for Pneumonia Severity
  static Curb65Result calculateCurb65({
    required bool confusion,
    required double urea, // mg/dL (>19 = abnormal)
    required int respiratoryRate, // >30 = abnormal
    required int systolicBp,
    required int diastolicBp,
    required int age,
  }) {
    int score = 0;
    final breakdown = <String>[];
    
    if (confusion) {
      score += 1;
      breakdown.add('Confusion: +1');
    }
    if (urea > 19) {
      score += 1;
      breakdown.add('Urea >19 mg/dL: +1');
    }
    if (respiratoryRate >= 30) {
      score += 1;
      breakdown.add('RR ≥30: +1');
    }
    if (systolicBp < 90 || diastolicBp <= 60) {
      score += 1;
      breakdown.add('BP <90 systolic or ≤60 diastolic: +1');
    }
    if (age >= 65) {
      score += 1;
      breakdown.add('Age ≥65: +1');
    }
    
    String severity;
    double mortality30Day;
    String recommendation;
    
    switch (score) {
      case 0:
      case 1:
        severity = 'Low';
        mortality30Day = score == 0 ? 0.6 : 2.7;
        recommendation = 'Consider outpatient treatment';
      case 2:
        severity = 'Moderate';
        mortality30Day = 6.8;
        recommendation = 'Consider short inpatient or supervised outpatient';
      case 3:
        severity = 'Severe';
        mortality30Day = 14.0;
        recommendation = 'Hospitalization recommended';
      default:
        severity = 'Very Severe';
        mortality30Day = score == 4 ? 27.8 : 57.0;
        recommendation = 'ICU admission recommended';
    }
    
    return Curb65Result(
      score: score,
      severity: severity,
      mortality30Day: mortality30Day,
      recommendation: recommendation,
      breakdown: breakdown,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

class BmiResult {
  final double bmi;
  final String category;
  final String risk;
  final (double, double) idealWeightRange;
  
  BmiResult({
    required this.bmi,
    required this.category,
    required this.risk,
    required this.idealWeightRange,
  });
  
  Map<String, dynamic> toJson() => {
    'bmi': bmi,
    'category': category,
    'risk': risk,
    'idealWeightMin': idealWeightRange.$1,
    'idealWeightMax': idealWeightRange.$2,
  };
}

class GfrResult {
  final double gfr;
  final String stage;
  final String description;
  final String formula;
  
  GfrResult({
    required this.gfr,
    required this.stage,
    required this.description,
    required this.formula,
  });
  
  Map<String, dynamic> toJson() => {
    'gfr': gfr,
    'stage': stage,
    'description': description,
    'formula': formula,
  };
}

class ChadsVascResult {
  final int score;
  final String risk;
  final double annualStrokeRisk;
  final String recommendation;
  final List<String> breakdown;
  
  ChadsVascResult({
    required this.score,
    required this.risk,
    required this.annualStrokeRisk,
    required this.recommendation,
    required this.breakdown,
  });
  
  Map<String, dynamic> toJson() => {
    'score': score,
    'risk': risk,
    'annualStrokeRisk': annualStrokeRisk,
    'recommendation': recommendation,
    'breakdown': breakdown,
  };
}

class PediatricDoseResult {
  final double calculatedDose;
  final double finalDose;
  final bool exceededMaxDose;
  final String frequency;
  final String? warning;
  
  PediatricDoseResult({
    required this.calculatedDose,
    required this.finalDose,
    required this.exceededMaxDose,
    required this.frequency,
    this.warning,
  });
  
  Map<String, dynamic> toJson() => {
    'calculatedDose': calculatedDose,
    'finalDose': finalDose,
    'exceededMaxDose': exceededMaxDose,
    'frequency': frequency,
    'warning': warning,
  };
}

class MaintenanceFluidsResult {
  final int mlPerDay;
  final int mlPerHour;
  final String formula;
  
  MaintenanceFluidsResult({
    required this.mlPerDay,
    required this.mlPerHour,
    required this.formula,
  });
  
  Map<String, dynamic> toJson() => {
    'mlPerDay': mlPerDay,
    'mlPerHour': mlPerHour,
    'formula': formula,
  };
}

class WellsDvtResult {
  final int score;
  final String risk;
  final double probability;
  final String recommendation;
  final List<String> breakdown;
  
  WellsDvtResult({
    required this.score,
    required this.risk,
    required this.probability,
    required this.recommendation,
    required this.breakdown,
  });
  
  Map<String, dynamic> toJson() => {
    'score': score,
    'risk': risk,
    'probability': probability,
    'recommendation': recommendation,
    'breakdown': breakdown,
  };
}

class Curb65Result {
  final int score;
  final String severity;
  final double mortality30Day;
  final String recommendation;
  final List<String> breakdown;
  
  Curb65Result({
    required this.score,
    required this.severity,
    required this.mortality30Day,
    required this.recommendation,
    required this.breakdown,
  });
  
  Map<String, dynamic> toJson() => {
    'score': score,
    'severity': severity,
    'mortality30Day': mortality30Day,
    'recommendation': recommendation,
    'breakdown': breakdown,
  };
}
