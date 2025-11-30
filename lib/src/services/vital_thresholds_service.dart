import 'package:flutter/material.dart';

class VitalSign {
  final String name;
  final double? value;
  final String unit;
  final double? minNormal;
  final double? maxNormal;
  final double? criticalLow;
  final double? criticalHigh;

  VitalSign({
    required this.name,
    this.value,
    required this.unit,
    required this.minNormal,
    required this.maxNormal,
    this.criticalLow,
    this.criticalHigh,
  });

  bool get isAbnormal {
    if (value == null) return false;
    return (minNormal != null && value! < minNormal!) ||
        (maxNormal != null && value! > maxNormal!);
  }

  bool get isCritical {
    if (value == null) return false;
    return (criticalLow != null && value! < criticalLow!) ||
        (criticalHigh != null && value! > criticalHigh!);
  }

  VitalThresholdLevel get level {
    if (value == null) return VitalThresholdLevel.normal;
    if (isCritical) return VitalThresholdLevel.critical;
    if (isAbnormal) return VitalThresholdLevel.abnormal;
    return VitalThresholdLevel.normal;
  }

  String get recommendation {
    if (value == null) return '';

    switch (name) {
      case 'Systolic BP':
        if (value! > 180) return 'Hypertensive Crisis - Immediate intervention required';
        if (value! > 160) return 'Stage 2 Hypertension - Consider IV medications';
        if (value! > 140) return 'Elevated Blood Pressure';
        if (value! < 90) return 'Hypotension - Monitor closely';
        return '';

      case 'Diastolic BP':
        if (value! > 120) return 'Hypertensive Crisis - Immediate intervention required';
        if (value! > 100) return 'Stage 2 Hypertension - Consider IV medications';
        if (value! > 90) return 'Elevated Blood Pressure';
        if (value! < 60) return 'Hypotension - Monitor closely';
        return '';

      case 'Heart Rate':
        if (value! > 120) return 'Tachycardia - Check for fever, anxiety, or cardiac issues';
        if (value! < 40) return 'Bradycardia - Consider medication review or cardiac assessment';
        return '';

      case 'Temperature':
        if (value! > 38.5) return 'High fever - Consider antipyretics and investigate source';
        if (value! > 37.5) return 'Mild fever - Monitor for infection';
        if (value! < 35) return 'Hypothermia - Requires active rewarming';
        return '';

      case 'O2 Saturation':
        if (value! < 90) return 'Hypoxia - Consider supplemental oxygen and respiratory support';
        if (value! < 94) return 'Low oxygen - Monitor respiratory status';
        return '';

      case 'Respiratory Rate':
        if (value! > 24) return 'Tachypnea - Assess for respiratory distress';
        if (value! < 12) return 'Bradypnea - Monitor airway and consider ventilation';
        return '';

      default:
        return '';
    }
  }
}

enum VitalThresholdLevel { normal, abnormal, critical }

class VitalThresholdsService {
  /// Standard vital signs thresholds for adults
  static const Map<String, Map<String, dynamic>> standardThresholds = {
    'Systolic BP': {
      'normal_min': 90.0,
      'normal_max': 130.0,
      'abnormal_min': 90.0,
      'abnormal_max': 180.0,
      'critical_min': null,
      'critical_max': 180.0,
      'unit': 'mmHg',
    },
    'Diastolic BP': {
      'normal_min': 60.0,
      'normal_max': 85.0,
      'abnormal_min': 60.0,
      'abnormal_max': 120.0,
      'critical_min': null,
      'critical_max': 120.0,
      'unit': 'mmHg',
    },
    'Heart Rate': {
      'normal_min': 60.0,
      'normal_max': 100.0,
      'abnormal_min': 40.0,
      'abnormal_max': 120.0,
      'critical_min': 40.0,
      'critical_max': 120.0,
      'unit': 'bpm',
    },
    'Temperature': {
      'normal_min': 36.5,
      'normal_max': 37.5,
      'abnormal_min': 35.0,
      'abnormal_max': 38.5,
      'critical_min': 35.0,
      'critical_max': 38.5,
      'unit': '°C',
    },
    'O2 Saturation': {
      'normal_min': 95.0,
      'normal_max': 100.0,
      'abnormal_min': 90.0,
      'abnormal_max': 100.0,
      'critical_min': 90.0,
      'critical_max': null,
      'unit': '%',
    },
    'Respiratory Rate': {
      'normal_min': 12.0,
      'normal_max': 20.0,
      'abnormal_min': 10.0,
      'abnormal_max': 24.0,
      'critical_min': 10.0,
      'critical_max': 24.0,
      'unit': 'breaths/min',
    },
  };

  /// Check a single vital sign
  VitalSign checkVitalSign(
    String name,
    double? value,
  ) {
    final threshold = standardThresholds[name];
    if (threshold == null) {
      return VitalSign(
        name: name,
        value: value,
        unit: 'N/A',
        minNormal: null,
        maxNormal: null,
      );
    }

    return VitalSign(
      name: name,
      value: value,
      unit: threshold['unit'] as String,
      minNormal: threshold['normal_min'] as double?,
      maxNormal: threshold['normal_max'] as double?,
      criticalLow: threshold['critical_min'] as double?,
      criticalHigh: threshold['critical_max'] as double?,
    );
  }

  /// Check all vital signs at once
  List<VitalSign> checkAllVitals({
    double? systolicBp,
    double? diastolicBp,
    double? heartRate,
    double? temperature,
    double? o2Saturation,
    double? respiratoryRate,
  }) {
    return [
      if (systolicBp != null) checkVitalSign('Systolic BP', systolicBp),
      if (diastolicBp != null) checkVitalSign('Diastolic BP', diastolicBp),
      if (heartRate != null) checkVitalSign('Heart Rate', heartRate),
      if (temperature != null) checkVitalSign('Temperature', temperature),
      if (o2Saturation != null) checkVitalSign('O2 Saturation', o2Saturation),
      if (respiratoryRate != null) checkVitalSign('Respiratory Rate', respiratoryRate),
    ];
  }

  /// Get all abnormal vitals
  List<VitalSign> getAbnormalVitals(List<VitalSign> vitals) {
    return vitals.where((v) => v.isAbnormal).toList();
  }

  /// Get all critical vitals
  List<VitalSign> getCriticalVitals(List<VitalSign> vitals) {
    return vitals.where((v) => v.isCritical).toList();
  }

  /// Get color for vital sign level
  Color getColorForLevel(VitalThresholdLevel level) {
    switch (level) {
      case VitalThresholdLevel.critical:
        return Colors.red;
      case VitalThresholdLevel.abnormal:
        return Colors.orange;
      case VitalThresholdLevel.normal:
        return Colors.green;
    }
  }

  /// Get icon for vital sign level
  IconData getIconForLevel(VitalThresholdLevel level) {
    switch (level) {
      case VitalThresholdLevel.critical:
        return Icons.error;
      case VitalThresholdLevel.abnormal:
        return Icons.warning;
      case VitalThresholdLevel.normal:
        return Icons.check_circle;
    }
  }

  /// Check if vitals indicate emergency
  bool isEmergency(List<VitalSign> vitals) {
    return vitals.any((v) => v.isCritical);
  }

  /// Get emergency summary
  String getEmergencySummary(List<VitalSign> vitals) {
    final critical = getCriticalVitals(vitals);
    if (critical.isEmpty) return '';

    return 'CRITICAL: ${critical.map((v) => '${v.name} ${v.value}${v.unit}').join(', ')}';
  }
}
