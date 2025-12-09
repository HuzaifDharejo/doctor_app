import 'dart:math' as math;

/// Growth chart standard
enum GrowthChartStandard {
  who('WHO', 'World Health Organization'),
  cdc('CDC', 'Centers for Disease Control');

  const GrowthChartStandard(this.value, this.label);
  final String value;
  final String label;

  static GrowthChartStandard fromValue(String value) {
    return GrowthChartStandard.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => GrowthChartStandard.who,
    );
  }
}

/// Growth measurement data model
class GrowthMeasurementModel {
  const GrowthMeasurementModel({
    required this.patientId,
    required this.measurementDate,
    required this.ageMonths,
    this.id,
    this.encounterId,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
    this.bmi,
    this.weightPercentile,
    this.heightPercentile,
    this.headCircumferencePercentile,
    this.bmiPercentile,
    this.weightZScore,
    this.heightZScore,
    this.headCircumferenceZScore,
    this.bmiZScore,
    this.chartStandard = GrowthChartStandard.who,
    this.notes = '',
    this.createdAt,
  });

  factory GrowthMeasurementModel.fromJson(Map<String, dynamic> json) {
    return GrowthMeasurementModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      encounterId: json['encounterId'] as int? ?? json['encounter_id'] as int?,
      measurementDate: _parseDateTime(json['measurementDate'] ?? json['measurement_date']) ?? DateTime.now(),
      ageMonths: json['ageMonths'] as int? ?? json['age_months'] as int? ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? (json['height_cm'] as num?)?.toDouble(),
      headCircumferenceCm: (json['headCircumferenceCm'] as num?)?.toDouble() ?? (json['head_circumference_cm'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      weightPercentile: (json['weightPercentile'] as num?)?.toDouble() ?? (json['weight_percentile'] as num?)?.toDouble(),
      heightPercentile: (json['heightPercentile'] as num?)?.toDouble() ?? (json['height_percentile'] as num?)?.toDouble(),
      headCircumferencePercentile: (json['headCircumferencePercentile'] as num?)?.toDouble() ?? (json['head_circumference_percentile'] as num?)?.toDouble(),
      bmiPercentile: (json['bmiPercentile'] as num?)?.toDouble() ?? (json['bmi_percentile'] as num?)?.toDouble(),
      weightZScore: (json['weightZScore'] as num?)?.toDouble() ?? (json['weight_z_score'] as num?)?.toDouble(),
      heightZScore: (json['heightZScore'] as num?)?.toDouble() ?? (json['height_z_score'] as num?)?.toDouble(),
      headCircumferenceZScore: (json['headCircumferenceZScore'] as num?)?.toDouble() ?? (json['head_circumference_z_score'] as num?)?.toDouble(),
      bmiZScore: (json['bmiZScore'] as num?)?.toDouble() ?? (json['bmi_z_score'] as num?)?.toDouble(),
      chartStandard: GrowthChartStandard.fromValue(json['chartStandard'] as String? ?? json['chart_standard'] as String? ?? 'WHO'),
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final int? id;
  final int patientId;
  final int? encounterId;
  final DateTime measurementDate;
  final int ageMonths;
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;
  final double? bmi;
  final double? weightPercentile;
  final double? heightPercentile;
  final double? headCircumferencePercentile;
  final double? bmiPercentile;
  final double? weightZScore;
  final double? heightZScore;
  final double? headCircumferenceZScore;
  final double? bmiZScore;
  final GrowthChartStandard chartStandard;
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'measurementDate': measurementDate.toIso8601String(),
      'ageMonths': ageMonths,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'headCircumferenceCm': headCircumferenceCm,
      'bmi': bmi,
      'weightPercentile': weightPercentile,
      'heightPercentile': heightPercentile,
      'headCircumferencePercentile': headCircumferencePercentile,
      'bmiPercentile': bmiPercentile,
      'weightZScore': weightZScore,
      'heightZScore': heightZScore,
      'headCircumferenceZScore': headCircumferenceZScore,
      'bmiZScore': bmiZScore,
      'chartStandard': chartStandard.value,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  GrowthMeasurementModel copyWith({
    int? id,
    int? patientId,
    int? encounterId,
    DateTime? measurementDate,
    int? ageMonths,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    double? bmi,
    double? weightPercentile,
    double? heightPercentile,
    double? headCircumferencePercentile,
    double? bmiPercentile,
    double? weightZScore,
    double? heightZScore,
    double? headCircumferenceZScore,
    double? bmiZScore,
    GrowthChartStandard? chartStandard,
    String? notes,
    DateTime? createdAt,
  }) {
    return GrowthMeasurementModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      measurementDate: measurementDate ?? this.measurementDate,
      ageMonths: ageMonths ?? this.ageMonths,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      bmi: bmi ?? this.bmi,
      weightPercentile: weightPercentile ?? this.weightPercentile,
      heightPercentile: heightPercentile ?? this.heightPercentile,
      headCircumferencePercentile: headCircumferencePercentile ?? this.headCircumferencePercentile,
      bmiPercentile: bmiPercentile ?? this.bmiPercentile,
      weightZScore: weightZScore ?? this.weightZScore,
      heightZScore: heightZScore ?? this.heightZScore,
      headCircumferenceZScore: headCircumferenceZScore ?? this.headCircumferenceZScore,
      bmiZScore: bmiZScore ?? this.bmiZScore,
      chartStandard: chartStandard ?? this.chartStandard,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate BMI from weight and height
  static double? calculateBmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get age in years and months display
  String get ageDisplay {
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    if (years == 0) {
      return '$months mo';
    } else if (months == 0) {
      return '$years yr';
    } else {
      return '$years yr $months mo';
    }
  }

  /// Get weight status based on BMI percentile (for children 2+)
  String? get weightStatus {
    if (bmiPercentile == null) return null;
    if (bmiPercentile! < 5) return 'Underweight';
    if (bmiPercentile! < 85) return 'Healthy Weight';
    if (bmiPercentile! < 95) return 'Overweight';
    return 'Obese';
  }

  /// Check if any value is concerning (below 3rd or above 97th percentile)
  bool get hasConcerningValue {
    return (weightPercentile != null && (weightPercentile! < 3 || weightPercentile! > 97)) ||
           (heightPercentile != null && (heightPercentile! < 3 || heightPercentile! > 97)) ||
           (bmiPercentile != null && (bmiPercentile! < 5 || bmiPercentile! > 95)) ||
           (headCircumferencePercentile != null && (headCircumferencePercentile! < 3 || headCircumferencePercentile! > 97));
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Growth percentile calculator using LMS method
class GrowthPercentileCalculator {
  /// Calculate percentile from z-score
  static double zScoreToPercentile(double zScore) {
    // Using standard normal distribution approximation
    return _normalCdf(zScore) * 100;
  }

  /// Calculate z-score from percentile
  static double percentileToZScore(double percentile) {
    return _normalCdfInverse(percentile / 100);
  }

  /// Calculate z-score using LMS method
  static double calculateZScore({
    required double value,
    required double l,
    required double m,
    required double s,
  }) {
    if (l == 0) {
      return math.log(value / m) / s;
    }
    return (math.pow(value / m, l) - 1) / (l * s);
  }

  /// Calculate value from z-score using LMS method
  static double calculateValueFromZScore({
    required double zScore,
    required double l,
    required double m,
    required double s,
  }) {
    if (l == 0) {
      return m * math.exp(s * zScore);
    }
    return m * math.pow(1 + l * s * zScore, 1 / l);
  }

  /// Standard normal CDF approximation
  static double _normalCdf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs() / math.sqrt(2);

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);

    return 0.5 * (1.0 + sign * y);
  }

  /// Inverse standard normal CDF (approximation)
  static double _normalCdfInverse(double p) {
    if (p <= 0) return double.negativeInfinity;
    if (p >= 1) return double.infinity;
    if (p == 0.5) return 0;

    // Rational approximation for central region
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];

    const pLow = 0.02425;
    const pHigh = 1 - pLow;

    double q, r;

    if (p < pLow) {
      q = math.sqrt(-2 * math.log(p));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    } else if (p <= pHigh) {
      q = p - 0.5;
      r = q * q;
      return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q /
          (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
    } else {
      q = math.sqrt(-2 * math.log(1 - p));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
  }
}

/// Growth trend analysis
class GrowthTrendAnalysis {
  const GrowthTrendAnalysis({
    required this.measurements,
    required this.patientId,
    required this.gender,
  });

  final List<GrowthMeasurementModel> measurements;
  final int patientId;
  final String gender;

  /// Check for crossing percentile lines (weight)
  bool get hasWeightPercentileCrossing {
    if (measurements.length < 2) return false;
    final sorted = [...measurements]..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].weightPercentile;
      final curr = sorted[i].weightPercentile;
      if (prev != null && curr != null) {
        // Check if crossed 2 major percentile lines (e.g., 50th to 10th)
        if ((prev - curr).abs() > 25) return true;
      }
    }
    return false;
  }

  /// Check for growth faltering (failure to thrive)
  bool get hasGrowthFaltering {
    if (measurements.length < 2) return false;
    final sorted = [...measurements]..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    
    // Check for consistent downward trend in weight percentile
    int decreasingCount = 0;
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1].weightPercentile;
      final curr = sorted[i].weightPercentile;
      if (prev != null && curr != null && curr < prev) {
        decreasingCount++;
      }
    }
    return decreasingCount >= 2 && sorted.last.weightPercentile != null && sorted.last.weightPercentile! < 5;
  }

  /// Get latest measurement
  GrowthMeasurementModel? get latestMeasurement {
    if (measurements.isEmpty) return null;
    final sorted = [...measurements]..sort((a, b) => b.measurementDate.compareTo(a.measurementDate));
    return sorted.first;
  }

  /// Get weight velocity (change per month)
  double? get weightVelocity {
    if (measurements.length < 2) return null;
    final sorted = [...measurements]..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    final first = sorted.first;
    final last = sorted.last;
    
    if (first.weightKg == null || last.weightKg == null) return null;
    final monthsDiff = last.ageMonths - first.ageMonths;
    if (monthsDiff <= 0) return null;
    
    return (last.weightKg! - first.weightKg!) / monthsDiff;
  }

  /// Get height velocity (change per month)
  double? get heightVelocity {
    if (measurements.length < 2) return null;
    final sorted = [...measurements]..sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    final first = sorted.first;
    final last = sorted.last;
    
    if (first.heightCm == null || last.heightCm == null) return null;
    final monthsDiff = last.ageMonths - first.ageMonths;
    if (monthsDiff <= 0) return null;
    
    return (last.heightCm! - first.heightCm!) / monthsDiff;
  }

  /// Get growth alerts
  List<String> get alerts {
    final alerts = <String>[];
    final latest = latestMeasurement;
    
    if (latest == null) return alerts;

    if (latest.weightPercentile != null && latest.weightPercentile! < 3) {
      alerts.add('Weight below 3rd percentile');
    }
    if (latest.weightPercentile != null && latest.weightPercentile! > 97) {
      alerts.add('Weight above 97th percentile');
    }
    if (latest.heightPercentile != null && latest.heightPercentile! < 3) {
      alerts.add('Height below 3rd percentile');
    }
    if (latest.bmiPercentile != null && latest.bmiPercentile! >= 95) {
      alerts.add('BMI indicates obesity');
    }
    if (latest.bmiPercentile != null && latest.bmiPercentile! < 5) {
      alerts.add('BMI indicates underweight');
    }
    if (hasWeightPercentileCrossing) {
      alerts.add('Significant percentile crossing detected');
    }
    if (hasGrowthFaltering) {
      alerts.add('Possible growth faltering');
    }
    
    return alerts;
  }
}
