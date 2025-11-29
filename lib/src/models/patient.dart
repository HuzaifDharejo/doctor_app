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
        other.riskLevel == riskLevel;
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
