import 'dart:convert';

/// Individual medication item in a prescription
class MedicationItem {

  const MedicationItem({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    this.route = 'Oral',
    this.instructions = '',
    this.beforeFood = false,
  });

  /// Create from JSON map
  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      name: json['name'] as String? ?? json['medication'] as String? ?? '',
      dosage: json['dosage'] as String? ?? json['dose'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      route: json['route'] as String? ?? 'Oral',
      instructions: json['instructions'] as String? ?? json['notes'] as String? ?? '',
      beforeFood: json['beforeFood'] as bool? ?? json['before_food'] as bool? ?? false,
    );
  }
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String route;
  final String instructions;
  final bool beforeFood;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'route': route,
      'instructions': instructions,
      'beforeFood': beforeFood,
    };
  }

  /// Create a copy with modified fields
  MedicationItem copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? route,
    String? instructions,
    bool? beforeFood,
  }) {
    return MedicationItem(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      instructions: instructions ?? this.instructions,
      beforeFood: beforeFood ?? this.beforeFood,
    );
  }

  /// Get formatted medication line (e.g., "Tab. Paracetamol 500mg - 1 tablet, three times daily for 5 days")
  String get formattedLine {
    final parts = <String>[name];
    if (dosage.isNotEmpty) parts.add(dosage);
    if (frequency.isNotEmpty) parts.add('- $frequency');
    if (duration.isNotEmpty) parts.add('for $duration');
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationItem &&
        other.name == name &&
        other.dosage == dosage &&
        other.frequency == frequency &&
        other.duration == duration &&
        other.route == route &&
        other.instructions == instructions &&
        other.beforeFood == beforeFood;
  }

  @override
  int get hashCode => Object.hash(name, dosage, frequency, duration, route, instructions, beforeFood);

  @override
  String toString() => 'MedicationItem($name $dosage $frequency)';
}

/// Prescription data model
class PrescriptionModel {

  const PrescriptionModel({
    required this.patientId, required this.createdAt, this.id,
    this.patientName,
    this.items = const [],
    this.instructions = '',
    this.isRefillable = false,
    this.diagnosis,
    this.chiefComplaint,
    this.vitals,
    this.appointmentId,
    this.medicalRecordId,
  });

  /// Create from JSON map
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<MedicationItem> items = [];
    
    if (json['items'] is List) {
      items = (json['items'] as List<dynamic>)
          .map((item) => MedicationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['itemsJson'] is String) {
      items = parseItemsJson(json['itemsJson'] as String);
    } else if (json['items_json'] is String) {
      items = parseItemsJson(json['items_json'] as String);
    }

    return PrescriptionModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      patientName: json['patientName'] as String? ?? json['patient_name'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      items: items,
      instructions: json['instructions'] as String? ?? '',
      isRefillable: json['isRefillable'] as bool? ?? json['is_refillable'] as bool? ?? false,
      diagnosis: json['diagnosis'] as String?,
      chiefComplaint: json['chiefComplaint'] as String? ?? json['chief_complaint'] as String?,
      vitals: json['vitals'] as Map<String, dynamic>?,
      appointmentId: json['appointmentId'] as int? ?? json['appointment_id'] as int?,
      medicalRecordId: json['medicalRecordId'] as int? ?? json['medical_record_id'] as int?,
    );
  }

  /// Create from JSON string
  factory PrescriptionModel.fromJsonString(String jsonString) {
    return PrescriptionModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
  final int? id;
  final int patientId;
  final String? patientName; // For display purposes
  final DateTime createdAt;
  final List<MedicationItem> items;
  final String instructions;
  final bool isRefillable;
  final String? diagnosis;
  final String? chiefComplaint;
  final Map<String, dynamic>? vitals;
  final int? appointmentId; // Link to appointment where prescribed
  final int? medicalRecordId; // Link to diagnosis/assessment

  /// Get total number of medications
  int get medicationCount => items.length;

  /// Check if prescription is recent (within last 7 days)
  bool get isRecent {
    final diff = DateTime.now().difference(createdAt);
    return diff.inDays <= 7;
  }

  /// Get formatted date
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  /// Parse items from JSON string
  static List<MedicationItem> parseItemsJson(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((item) => MedicationItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convert items to JSON string
  String get itemsJsonString => jsonEncode(items.map((i) => i.toJson()).toList());

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'isRefillable': isRefillable,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (chiefComplaint != null) 'chiefComplaint': chiefComplaint,
      if (vitals != null) 'vitals': vitals,
      if (appointmentId != null) 'appointmentId': appointmentId,
      if (medicalRecordId != null) 'medicalRecordId': medicalRecordId,
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with modified fields
  PrescriptionModel copyWith({
    int? id,
    int? patientId,
    String? patientName,
    DateTime? createdAt,
    List<MedicationItem>? items,
    String? instructions,
    bool? isRefillable,
    String? diagnosis,
    String? chiefComplaint,
    Map<String, dynamic>? vitals,
    int? appointmentId,
    int? medicalRecordId,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      instructions: instructions ?? this.instructions,
      isRefillable: isRefillable ?? this.isRefillable,
      diagnosis: diagnosis ?? this.diagnosis,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      vitals: vitals ?? this.vitals,
      appointmentId: appointmentId ?? this.appointmentId,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescriptionModel &&
        other.id == id &&
        other.patientId == patientId &&
        other.createdAt == createdAt &&
        other.instructions == instructions &&
        other.isRefillable == isRefillable &&
        other.appointmentId == appointmentId &&
        other.medicalRecordId == medicalRecordId;
  }

  @override
  int get hashCode => Object.hash(id, patientId, createdAt, instructions, isRefillable, appointmentId, medicalRecordId);

  @override
  String toString() => 'PrescriptionModel(id: $id, patientId: $patientId, items: ${items.length}, appointmentId: $appointmentId, medicalRecordId: $medicalRecordId)';
}
