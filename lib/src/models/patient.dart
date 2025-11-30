import 'dart:convert';

/// Patient data model representing a patient in the system
class PatientModel {

  const PatientModel({
    required this.firstName, this.id,
    this.lastName = '',
    this.dateOfBirth,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.medicalHistory = '',
    this.tags = const [],
    this.riskLevel = 0,
    this.createdAt,
    this.gender = '',
    this.bloodType = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.allergies = '',
    this.height,
    this.weight,
    this.chronicConditions = const [],
  });

  /// Create from JSON map
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as int?,
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : json['date_of_birth'] != null
              ? DateTime.tryParse(json['date_of_birth'] as String)
              : null,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      medicalHistory: json['medicalHistory'] as String? ?? json['medical_history'] as String? ?? '',
      tags: json['tags'] is String
          ? parseTags(json['tags'] as String)
          : (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      riskLevel: json['riskLevel'] as int? ?? json['risk_level'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
      gender: json['gender'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? json['blood_type'] as String? ?? '',
      emergencyContactName: json['emergencyContactName'] as String? ?? json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? json['emergency_contact_phone'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      chronicConditions: json['chronicConditions'] is String
          ? parseChronicConditions(json['chronicConditions'] as String)
          : (json['chronicConditions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Create from JSON string
  factory PatientModel.fromJsonString(String jsonString) {
    return PatientModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
  final int? id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String phone;
  final String email;
  final String address;
  final String medicalHistory;
  final List<String> tags;
  final int riskLevel; // 0 = Low, 1 = Medium, 2 = High
  final DateTime? createdAt;
  final String gender;
  final String bloodType;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String allergies; // comma-separated
  final double? height; // in cm
  final double? weight; // in kg
  final List<String> chronicConditions;

  /// Full name of the patient
  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';

  /// Initials for avatar display
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
  }

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Calculate BMI from height and weight
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  /// Get allergy list
  List<String> get allergyList {
    if (allergies.isEmpty) return [];
    return allergies.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
  }

  /// Check if patient has allergies
  bool get hasAllergies => allergyList.isNotEmpty;

  /// Get chronic conditions list
  List<String> get conditionsList => chronicConditions;

  /// Risk level as string
  String get riskLevelString {
    switch (riskLevel) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  /// Tags as comma-separated string (for database storage)
  String get tagsString => tags.join(',');

  /// Create from comma-separated tags string
  static List<String> parseTags(String tagsString) {
    if (tagsString.isEmpty) return [];
    return tagsString.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  /// Create from comma-separated chronic conditions string
  static List<String> parseChronicConditions(String conditionsString) {
    if (conditionsString.isEmpty) return [];
    return conditionsString.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'phone': phone,
      'email': email,
      'address': address,
      'medicalHistory': medicalHistory,
      'tags': tags,
      'riskLevel': riskLevel,
      'createdAt': createdAt?.toIso8601String(),
      'gender': gender,
      'bloodType': bloodType,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'allergies': allergies,
      'height': height,
      'weight': weight,
      'chronicConditions': chronicConditions,
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with modified fields
  PatientModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phone,
    String? email,
    String? address,
    String? medicalHistory,
    List<String>? tags,
    int? riskLevel,
    DateTime? createdAt,
    String? gender,
    String? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    double? height,
    double? weight,
    List<String>? chronicConditions,
  }) {
    return PatientModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      tags: tags ?? this.tags,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      chronicConditions: chronicConditions ?? this.chronicConditions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientModel &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.dateOfBirth == dateOfBirth &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.medicalHistory == medicalHistory &&
        _listEquals(other.tags, tags) &&
        other.riskLevel == riskLevel &&
        other.gender == gender &&
        other.bloodType == bloodType &&
        other.emergencyContactName == emergencyContactName &&
        other.emergencyContactPhone == emergencyContactPhone &&
        other.allergies == allergies &&
        other.height == height &&
        other.weight == weight &&
        _listEquals(other.chronicConditions, chronicConditions);
  }

  @override
  int get hashCode => Object.hash(
        id,
        firstName,
        lastName,
        dateOfBirth,
        phone,
        email,
        address,
        medicalHistory,
        Object.hashAll(tags),
        riskLevel,
        gender,
        bloodType,
        emergencyContactName,
        emergencyContactPhone,
        allergies,
        height,
        weight,
        Object.hashAll(chronicConditions),
      );

  @override
  String toString() => 'PatientModel(id: $id, name: $fullName, phone: $phone)';
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
