import 'dart:convert';

/// Medical record type enum
enum MedicalRecordType {
  general('general', 'General Consultation', 'General clinical notes and consultation'),
  psychiatricAssessment('psychiatric_assessment', 'Psychiatric Assessment', 'Mental health evaluation'),
  pulmonaryEvaluation('pulmonary_evaluation', 'Pulmonary Evaluation', 'Respiratory system evaluation'),
  labResult('lab_result', 'Lab Result', 'Laboratory test results'),
  imaging('imaging', 'Imaging', 'X-ray, CT, MRI, Ultrasound reports'),
  procedure('procedure', 'Procedure', 'Medical procedures performed'),
  followUp('follow_up', 'Follow-up', 'Follow-up visit notes');

  final String value;
  final String label;
  final String description;
  
  const MedicalRecordType(this.value, this.label, this.description);

  static MedicalRecordType fromValue(String value) {
    return MedicalRecordType.values.firstWhere(
      (t) => t.value == value.toLowerCase(),
      orElse: () => MedicalRecordType.general,
    );
  }
}

/// Medical record data model
class MedicalRecordModel {
  final int? id;
  final int patientId;
  final String? patientName; // For display purposes
  final MedicalRecordType recordType;
  final String title;
  final String description;
  final Map<String, dynamic> data; // Type-specific form data
  final String diagnosis;
  final String treatment;
  final String doctorNotes;
  final DateTime recordDate;
  final DateTime? createdAt;
  final List<String>? attachments; // File paths or URLs

  const MedicalRecordModel({
    this.id,
    required this.patientId,
    this.patientName,
    this.recordType = MedicalRecordType.general,
    required this.title,
    this.description = '',
    this.data = const {},
    this.diagnosis = '',
    this.treatment = '',
    this.doctorNotes = '',
    required this.recordDate,
    this.createdAt,
    this.attachments,
  });

  /// Get formatted record date
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[recordDate.month - 1]} ${recordDate.day}, ${recordDate.year}';
  }

  /// Check if record is recent (within last 30 days)
  bool get isRecent {
    final diff = DateTime.now().difference(recordDate);
    return diff.inDays <= 30;
  }

  /// Get data as JSON string (for database storage)
  String get dataJsonString => jsonEncode(data);

  /// Parse data from JSON string
  static Map<String, dynamic> parseDataJson(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') return {};
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Create from JSON map
  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = {};
    
    if (json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['dataJson'] is String) {
      data = parseDataJson(json['dataJson'] as String);
    } else if (json['data_json'] is String) {
      data = parseDataJson(json['data_json'] as String);
    }

    return MedicalRecordModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? json['patient_name'] as String?,
      recordType: MedicalRecordType.fromValue(
        json['recordType'] as String? ?? json['record_type'] as String? ?? 'general',
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      data: data,
      diagnosis: json['diagnosis'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      doctorNotes: json['doctorNotes'] as String? ?? json['doctor_notes'] as String? ?? '',
      recordDate: json['recordDate'] != null
          ? DateTime.parse(json['recordDate'] as String)
          : json['record_date'] != null
              ? DateTime.parse(json['record_date'] as String)
              : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      attachments: (json['attachments'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'recordType': recordType.value,
      'title': title,
      'description': description,
      'data': data,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'doctorNotes': doctorNotes,
      'recordDate': recordDate.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (attachments != null) 'attachments': attachments,
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON string
  factory MedicalRecordModel.fromJsonString(String jsonString) {
    return MedicalRecordModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Create a copy with modified fields
  MedicalRecordModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    MedicalRecordType? recordType,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    String? diagnosis,
    String? treatment,
    String? doctorNotes,
    DateTime? recordDate,
    DateTime? createdAt,
    List<String>? attachments,
  }) {
    return MedicalRecordModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicalRecordModel &&
        other.id == id &&
        other.patientId == patientId &&
        other.recordType == recordType &&
        other.title == title &&
        other.recordDate == recordDate;
  }

  @override
  int get hashCode => Object.hash(id, patientId, recordType, title, recordDate);

  @override
  String toString() => 'MedicalRecordModel(id: $id, type: ${recordType.label}, title: $title)';
}

/// Vital signs model for medical records
class VitalSigns {
  final String? bloodPressure;
  final int? pulseRate;
  final double? temperature;
  final int? respiratoryRate;
  final int? spo2;
  final double? weight;
  final double? height;
  final double? bmi;

  const VitalSigns({
    this.bloodPressure,
    this.pulseRate,
    this.temperature,
    this.respiratoryRate,
    this.spo2,
    this.weight,
    this.height,
    this.bmi,
  });

  /// Calculate BMI from weight and height
  static double? calculateBmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  String? get bmiCategory {
    if (bmi == null) return null;
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Overweight';
    return 'Obese';
  }

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      bloodPressure: json['bloodPressure'] as String? ?? json['bp'] as String?,
      pulseRate: json['pulseRate'] as int? ?? json['pulse'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? (json['temp'] as num?)?.toDouble(),
      respiratoryRate: json['respiratoryRate'] as int? ?? json['rr'] as int?,
      spo2: json['spo2'] as int? ?? json['oxygen'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bloodPressure != null) 'bloodPressure': bloodPressure,
      if (pulseRate != null) 'pulseRate': pulseRate,
      if (temperature != null) 'temperature': temperature,
      if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
      if (spo2 != null) 'spo2': spo2,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bmi != null) 'bmi': bmi,
    };
  }

  VitalSigns copyWith({
    String? bloodPressure,
    int? pulseRate,
    double? temperature,
    int? respiratoryRate,
    int? spo2,
    double? weight,
    double? height,
    double? bmi,
  }) {
    return VitalSigns(
      bloodPressure: bloodPressure ?? this.bloodPressure,
      pulseRate: pulseRate ?? this.pulseRate,
      temperature: temperature ?? this.temperature,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      spo2: spo2 ?? this.spo2,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
    );
  }
}
