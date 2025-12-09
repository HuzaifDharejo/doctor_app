import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef GrowthMeasurementData = GrowthMeasurement;

/// Service for managing growth measurements
class GrowthChartService {
  GrowthChartService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create growth measurement
  Future<int> createMeasurement({
    required int patientId,
    required DateTime measurementDate,
    required int ageMonths,
    int? encounterId,
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
    String? chartStandard,
    String? notes,
  }) async {
    final id = await _db.into(_db.growthMeasurements).insert(
      GrowthMeasurementsCompanion.insert(
        patientId: patientId,
        measurementDate: measurementDate,
        ageMonths: ageMonths,
        encounterId: Value(encounterId),
        weightKg: Value(weightKg),
        heightCm: Value(heightCm),
        headCircumferenceCm: Value(headCircumferenceCm),
        bmi: Value(bmi),
        weightPercentile: Value(weightPercentile),
        heightPercentile: Value(heightPercentile),
        headCircumferencePercentile: Value(headCircumferencePercentile),
        bmiPercentile: Value(bmiPercentile),
        weightZScore: Value(weightZScore),
        heightZScore: Value(heightZScore),
        headCircumferenceZScore: Value(headCircumferenceZScore),
        bmiZScore: Value(bmiZScore),
        chartStandard: Value(chartStandard ?? 'WHO'),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.growthMeasurement,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_measurement', 'age_months': ageMonths},
    );

    if (kDebugMode) {
      print('[GrowthChartService] Created measurement $id for patient $patientId');
    }

    return id;
  }

  /// Get all measurements for a patient
  Future<List<GrowthMeasurement>> getMeasurementsForPatient(int patientId) async {
    return (_db.select(_db.growthMeasurements)
          ..where((m) => m.patientId.equals(patientId))
          ..orderBy([(m) => OrderingTerm.asc(m.measurementDate)]))
        .get();
  }

  /// Get measurement by ID
  Future<GrowthMeasurement?> getMeasurementById(int id) async {
    return (_db.select(_db.growthMeasurements)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get latest measurement
  Future<GrowthMeasurement?> getLatestMeasurement(int patientId) async {
    return (_db.select(_db.growthMeasurements)
          ..where((m) => m.patientId.equals(patientId))
          ..orderBy([(m) => OrderingTerm.desc(m.measurementDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get measurements within age range
  Future<List<GrowthMeasurement>> getMeasurementsInAgeRange(
    int patientId,
    int minAgeMonths,
    int maxAgeMonths,
  ) async {
    return (_db.select(_db.growthMeasurements)
          ..where((m) =>
              m.patientId.equals(patientId) &
              m.ageMonths.isBiggerOrEqualValue(minAgeMonths) &
              m.ageMonths.isSmallerOrEqualValue(maxAgeMonths))
          ..orderBy([(m) => OrderingTerm.asc(m.ageMonths)]))
        .get();
  }

  /// Update measurement
  Future<bool> updateMeasurement({
    required int id,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    double? bmi,
    double? weightPercentile,
    double? heightPercentile,
    String? notes,
  }) async {
    final existing = await getMeasurementById(id);
    if (existing == null) return false;

    await (_db.update(_db.growthMeasurements)..where((m) => m.id.equals(id)))
        .write(GrowthMeasurementsCompanion(
          weightKg: weightKg != null ? Value(weightKg) : const Value.absent(),
          heightCm: heightCm != null ? Value(heightCm) : const Value.absent(),
          headCircumferenceCm: headCircumferenceCm != null ? Value(headCircumferenceCm) : const Value.absent(),
          bmi: bmi != null ? Value(bmi) : const Value.absent(),
          weightPercentile: weightPercentile != null ? Value(weightPercentile) : const Value.absent(),
          heightPercentile: heightPercentile != null ? Value(heightPercentile) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.growthMeasurement,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_measurement'},
    );

    return true;
  }

  /// Delete measurement
  Future<bool> deleteMeasurement(int id) async {
    final existing = await getMeasurementById(id);
    if (existing == null) return false;

    await (_db.delete(_db.growthMeasurements)..where((m) => m.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.growthMeasurement,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_measurement'},
    );

    return true;
  }

  /// Calculate BMI
  double? calculateBmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get growth statistics
  Future<Map<String, dynamic>> getGrowthStatistics(int patientId) async {
    final measurements = await getMeasurementsForPatient(patientId);
    if (measurements.isEmpty) {
      return {'has_data': false};
    }

    final latest = measurements.last;
    final first = measurements.first;

    return {
      'has_data': true,
      'measurement_count': measurements.length,
      'latest_weight_kg': latest.weightKg,
      'latest_height_cm': latest.heightCm,
      'latest_bmi': latest.bmi,
      'weight_gain_kg': (latest.weightKg != null && first.weightKg != null)
          ? latest.weightKg! - first.weightKg!
          : null,
      'height_gain_cm': (latest.heightCm != null && first.heightCm != null)
          ? latest.heightCm! - first.heightCm!
          : null,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get all measurements (screen compatibility)
  /// Can be called as getAllMeasurements(patientId) or getAllMeasurements(patientId: id)
  Future<List<GrowthMeasurementData>> getAllMeasurements([int? patientId]) async {
    if (patientId == null) {
      // Return all measurements if no patient specified
      return (_db.select(_db.growthMeasurements)
            ..orderBy([(m) => OrderingTerm.desc(m.measurementDate)]))
          .get();
    }
    return getMeasurementsForPatient(patientId);
  }

  /// Record measurement (screen compatibility)
  Future<int> recordMeasurement({
    required int patientId,
    required DateTime measurementDate,
    int? ageMonths,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    String? notes,
  }) async {
    return createMeasurement(
      patientId: patientId,
      measurementDate: measurementDate,
      ageMonths: ageMonths ?? 0,
      weightKg: weightKg,
      heightCm: heightCm,
      headCircumferenceCm: headCircumferenceCm,
      notes: notes,
    );
  }
}
