import 'package:drift/drift.dart';
import '../../../../db/doctor_db.dart';

/// Helper class for building and saving medical record data
/// 
/// Provides a standardized way to:
/// - Build the data map from form fields
/// - Save to both MedicalRecords table and MedicalRecordFields table
/// - Load existing record data with backward compatibility
/// 
/// Example:
/// ```dart
/// final builder = RecordDataBuilder()
///   ..addField('chief_complaint', _chiefComplaintController.text)
///   ..addField('duration', _durationController.text)
///   ..addListField('symptoms', _selectedSymptoms)
///   ..addVitalsFields(
///     systolic: _bpSystolicController.text,
///     diastolic: _bpDiastolicController.text,
///     pulse: _pulseController.text,
///   );
/// 
/// final recordId = await builder.save(
///   db: database,
///   patientId: patientId,
///   recordType: 'cardiac_exam',
///   recordDate: recordDate,
/// );
/// ```
class RecordDataBuilder {
  /// Internal data map
  final Map<String, dynamic> _data = {};
  
  /// Get the built data map
  Map<String, dynamic> get data => Map.unmodifiable(_data);
  
  /// Add a simple field (string value)
  RecordDataBuilder addField(String key, String? value) {
    if (value != null && value.isNotEmpty) {
      _data[key] = value;
    }
    return this;
  }
  
  /// Add a numeric field
  RecordDataBuilder addNumericField(String key, String? value) {
    if (value != null && value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        _data[key] = parsed;
      } else {
        _data[key] = value;
      }
    }
    return this;
  }
  
  /// Add a list field (e.g., symptoms, investigations)
  RecordDataBuilder addListField(String key, List<String>? values) {
    if (values != null && values.isNotEmpty) {
      _data[key] = values;
    }
    return this;
  }
  
  /// Add a boolean field
  RecordDataBuilder addBoolField(String key, bool? value) {
    if (value != null) {
      _data[key] = value;
    }
    return this;
  }
  
  /// Add a map field (nested data)
  RecordDataBuilder addMapField(String key, Map<String, dynamic>? value) {
    if (value != null && value.isNotEmpty) {
      _data[key] = value;
    }
    return this;
  }
  
  /// Add common vitals fields
  RecordDataBuilder addVitalsFields({
    String? systolic,
    String? diastolic,
    String? pulse,
    String? respiratoryRate,
    String? temperature,
    String? spo2,
    String? weight,
    String? height,
  }) {
    if (systolic != null && systolic.isNotEmpty) {
      addNumericField('bp_systolic', systolic);
    }
    if (diastolic != null && diastolic.isNotEmpty) {
      addNumericField('bp_diastolic', diastolic);
    }
    if (pulse != null && pulse.isNotEmpty) {
      addNumericField('pulse', pulse);
    }
    if (respiratoryRate != null && respiratoryRate.isNotEmpty) {
      addNumericField('respiratory_rate', respiratoryRate);
    }
    if (temperature != null && temperature.isNotEmpty) {
      addNumericField('temperature', temperature);
    }
    if (spo2 != null && spo2.isNotEmpty) {
      addNumericField('spo2', spo2);
    }
    if (weight != null && weight.isNotEmpty) {
      addNumericField('weight', weight);
    }
    if (height != null && height.isNotEmpty) {
      addNumericField('height', height);
    }
    return this;
  }
  
  /// Add common assessment fields
  RecordDataBuilder addAssessmentFields({
    String? diagnosis,
    String? treatment,
    String? notes,
  }) {
    addField('diagnosis', diagnosis);
    addField('treatment', treatment);
    addField('clinical_notes', notes);
    return this;
  }
  
  /// Add common chief complaint fields
  RecordDataBuilder addChiefComplaintFields({
    String? complaint,
    String? duration,
    List<String>? symptoms,
  }) {
    addField('chief_complaint', complaint);
    addField('duration', duration);
    addListField('symptoms', symptoms);
    return this;
  }
  
  /// Clear all data
  void clear() {
    _data.clear();
  }
  
  /// Check if a field has a value
  bool hasField(String key) => _data.containsKey(key) && _data[key] != null;
  
  /// Get a field value
  T? getField<T>(String key) => _data[key] as T?;
  
  /// Count of non-empty fields
  int get fieldCount => _data.length;
  
  /// Save a new medical record
  /// 
  /// Creates the record in MedicalRecords table and saves fields
  /// to MedicalRecordFields table for normalized storage.
  Future<int> save({
    required DoctorDatabase db,
    required int patientId,
    required String recordType,
    required String title,
    required DateTime recordDate,
    String? description,
    String? diagnosis,
    String? treatment,
    String? doctorNotes,
    int? encounterId,
  }) async {
    // Create the medical record
    final recordId = await db.into(db.medicalRecords).insert(
      MedicalRecordsCompanion.insert(
        patientId: patientId,
        recordType: recordType,
        title: title,
        description: Value(description ?? ''),
        dataJson: const Value('{}'), // Empty - using normalized fields
        diagnosis: Value(diagnosis ?? ''),
        treatment: Value(treatment ?? ''),
        doctorNotes: Value(doctorNotes ?? ''),
        recordDate: recordDate,
        encounterId: Value(encounterId),
      ),
    );
    
    // Save to normalized MedicalRecordFields table
    await db.insertMedicalRecordFieldsBatch(recordId, patientId, _data);
    
    return recordId;
  }
  
  /// Update an existing medical record
  /// 
  /// Updates the record and re-saves all fields to the normalized table.
  Future<void> update({
    required DoctorDatabase db,
    required int recordId,
    required int patientId,
    required String recordType,
    required String title,
    required DateTime recordDate,
    String? description,
    String? diagnosis,
    String? treatment,
    String? doctorNotes,
    int? encounterId,
  }) async {
    // Update the medical record metadata
    await (db.update(db.medicalRecords)..where((r) => r.id.equals(recordId)))
        .write(MedicalRecordsCompanion(
          recordType: Value(recordType),
          title: Value(title),
          description: Value(description ?? ''),
          recordDate: Value(recordDate),
          dataJson: const Value('{}'), // Empty - using normalized fields
          diagnosis: Value(diagnosis ?? ''),
          treatment: Value(treatment ?? ''),
          doctorNotes: Value(doctorNotes ?? ''),
          encounterId: Value(encounterId),
        ));
    
    // Delete old fields and insert new ones
    await db.deleteFieldsForMedicalRecord(recordId);
    await db.insertMedicalRecordFieldsBatch(recordId, patientId, _data);
  }
  
  /// Load record data from normalized table with fallback to dataJson
  static Future<Map<String, dynamic>> load({
    required DoctorDatabase db,
    required int recordId,
  }) async {
    return db.getMedicalRecordFieldsCompat(recordId);
  }
}

/// Extension methods for populating controllers from loaded data
extension RecordDataPopulator on Map<String, dynamic> {
  /// Get a string value, returns empty string if not found
  String getString(String key) => this[key]?.toString() ?? '';
  
  /// Get a list of strings, returns empty list if not found
  List<String> getStringList(String key) {
    final value = this[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
  
  /// Get a boolean value, returns false if not found
  bool getBool(String key) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
  
  /// Get a numeric value as string for text controllers
  String getNumericString(String key) {
    final value = this[key];
    if (value == null) return '';
    if (value is num) {
      // Remove trailing .0 for whole numbers
      if (value == value.toInt()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }
  
  /// Check if a key exists and has a non-empty value
  bool hasValue(String key) {
    final value = this[key];
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }
}
