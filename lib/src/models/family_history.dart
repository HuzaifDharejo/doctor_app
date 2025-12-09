import 'dart:convert';

/// Family relationship types
enum FamilyRelationship {
  father('father', 'Father', 1),
  mother('mother', 'Mother', 1),
  brother('brother', 'Brother', 1),
  sister('sister', 'Sister', 1),
  son('son', 'Son', 1),
  daughter('daughter', 'Daughter', 1),
  paternalGrandfather('paternal_grandfather', 'Paternal Grandfather', 2),
  paternalGrandmother('paternal_grandmother', 'Paternal Grandmother', 2),
  maternalGrandfather('maternal_grandfather', 'Maternal Grandfather', 2),
  maternalGrandmother('maternal_grandmother', 'Maternal Grandmother', 2),
  paternalUncle('paternal_uncle', 'Paternal Uncle', 2),
  paternalAunt('paternal_aunt', 'Paternal Aunt', 2),
  maternalUncle('maternal_uncle', 'Maternal Uncle', 2),
  maternalAunt('maternal_aunt', 'Maternal Aunt', 2),
  cousin('cousin', 'Cousin', 2),
  halfSibling('half_sibling', 'Half-Sibling', 1),
  spouse('spouse', 'Spouse', 0),
  other('other', 'Other', 3);

  const FamilyRelationship(this.value, this.label, this.degree);
  final String value;
  final String label;
  final int degree; // Degree of relationship (1 = first-degree, 2 = second-degree, etc.)

  static FamilyRelationship fromValue(String value) {
    return FamilyRelationship.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => FamilyRelationship.other,
    );
  }

  /// Check if this is a first-degree relative
  bool get isFirstDegree => degree == 1;
}

/// Common hereditary conditions
class HereditaryConditions {
  static const List<String> cardiovascular = [
    'Heart Disease',
    'Coronary Artery Disease',
    'Heart Attack (MI)',
    'Heart Failure',
    'Arrhythmia',
    'Cardiomyopathy',
    'Congenital Heart Defect',
    'High Cholesterol',
    'Hypertension',
    'Stroke',
    'Deep Vein Thrombosis',
    'Pulmonary Embolism',
    'Aortic Aneurysm',
  ];

  static const List<String> metabolic = [
    'Type 1 Diabetes',
    'Type 2 Diabetes',
    'Gestational Diabetes',
    'Obesity',
    'Thyroid Disease',
    'Hyperthyroidism',
    'Hypothyroidism',
    'Metabolic Syndrome',
  ];

  static const List<String> cancer = [
    'Breast Cancer',
    'Ovarian Cancer',
    'Colon Cancer',
    'Prostate Cancer',
    'Lung Cancer',
    'Melanoma',
    'Pancreatic Cancer',
    'Leukemia',
    'Lymphoma',
    'Thyroid Cancer',
    'Kidney Cancer',
    'Bladder Cancer',
    'Stomach Cancer',
    'Liver Cancer',
    'Brain Cancer',
    'Multiple Myeloma',
  ];

  static const List<String> psychiatric = [
    'Major Depression',
    'Bipolar Disorder',
    'Schizophrenia',
    'Anxiety Disorder',
    'OCD',
    'PTSD',
    'ADHD',
    'Autism Spectrum Disorder',
    'Substance Use Disorder',
    'Alcoholism',
    'Eating Disorder',
    'Suicide',
  ];

  static const List<String> neurological = [
    'Alzheimer\'s Disease',
    'Dementia',
    'Parkinson\'s Disease',
    'Multiple Sclerosis',
    'Epilepsy',
    'Migraine',
    'Huntington\'s Disease',
    'ALS',
  ];

  static const List<String> genetic = [
    'Cystic Fibrosis',
    'Sickle Cell Disease',
    'Hemophilia',
    'Thalassemia',
    'Down Syndrome',
    'Marfan Syndrome',
    'Polycystic Kidney Disease',
    'BRCA1/BRCA2 Mutation',
    'Lynch Syndrome',
    'Familial Hypercholesterolemia',
    'Hemochromatosis',
    'Factor V Leiden',
  ];

  static const List<String> autoimmune = [
    'Rheumatoid Arthritis',
    'Lupus (SLE)',
    'Psoriasis',
    'Psoriatic Arthritis',
    'Crohn\'s Disease',
    'Ulcerative Colitis',
    'Celiac Disease',
    'Multiple Sclerosis',
    'Type 1 Diabetes',
    'Hashimoto\'s Thyroiditis',
    'Graves\' Disease',
  ];

  static const List<String> respiratory = [
    'Asthma',
    'COPD',
    'Cystic Fibrosis',
    'Alpha-1 Antitrypsin Deficiency',
    'Pulmonary Fibrosis',
  ];

  static List<String> get all => [
    ...cardiovascular,
    ...metabolic,
    ...cancer,
    ...psychiatric,
    ...neurological,
    ...genetic,
    ...autoimmune,
    ...respiratory,
  ]..sort();
}

/// Family medical history data model
class FamilyHistoryModel {
  const FamilyHistoryModel({
    required this.patientId,
    required this.relationship,
    this.id,
    this.relativeName = '',
    this.relativeAge,
    this.isDeceased = false,
    this.ageAtDeath,
    this.causeOfDeath = '',
    this.conditions = const [],
    this.conditionDetails = const {},
    this.hasHeartDisease = false,
    this.hasDiabetes = false,
    this.hasCancer = false,
    this.cancerTypes = const [],
    this.hasHypertension = false,
    this.hasStroke = false,
    this.hasMentalIllness = false,
    this.mentalIllnessTypes = const [],
    this.hasSubstanceAbuse = false,
    this.hasGeneticDisorder = false,
    this.geneticDisorderTypes = const [],
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyHistoryModel.fromJson(Map<String, dynamic> json) {
    return FamilyHistoryModel(
      id: json['id'] as int?,
      patientId: json['patientId'] as int? ?? json['patient_id'] as int? ?? 0,
      relationship: FamilyRelationship.fromValue(json['relationship'] as String? ?? 'other'),
      relativeName: json['relativeName'] as String? ?? json['relative_name'] as String? ?? '',
      relativeAge: json['relativeAge'] as int? ?? json['relative_age'] as int?,
      isDeceased: json['isDeceased'] as bool? ?? json['is_deceased'] as bool? ?? false,
      ageAtDeath: json['ageAtDeath'] as int? ?? json['age_at_death'] as int?,
      causeOfDeath: json['causeOfDeath'] as String? ?? json['cause_of_death'] as String? ?? '',
      conditions: _parseStringList(json['conditions']),
      conditionDetails: _parseStringMap(json['conditionDetails'] ?? json['condition_details']),
      hasHeartDisease: json['hasHeartDisease'] as bool? ?? json['has_heart_disease'] as bool? ?? false,
      hasDiabetes: json['hasDiabetes'] as bool? ?? json['has_diabetes'] as bool? ?? false,
      hasCancer: json['hasCancer'] as bool? ?? json['has_cancer'] as bool? ?? false,
      cancerTypes: _parseStringList(json['cancerTypes'] ?? json['cancer_types']),
      hasHypertension: json['hasHypertension'] as bool? ?? json['has_hypertension'] as bool? ?? false,
      hasStroke: json['hasStroke'] as bool? ?? json['has_stroke'] as bool? ?? false,
      hasMentalIllness: json['hasMentalIllness'] as bool? ?? json['has_mental_illness'] as bool? ?? false,
      mentalIllnessTypes: _parseStringList(json['mentalIllnessTypes'] ?? json['mental_illness_types']),
      hasSubstanceAbuse: json['hasSubstanceAbuse'] as bool? ?? json['has_substance_abuse'] as bool? ?? false,
      hasGeneticDisorder: json['hasGeneticDisorder'] as bool? ?? json['has_genetic_disorder'] as bool? ?? false,
      geneticDisorderTypes: _parseStringList(json['geneticDisorderTypes'] ?? json['genetic_disorder_types']),
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  final int? id;
  final int patientId;
  final FamilyRelationship relationship;
  final String relativeName;
  final int? relativeAge;
  final bool isDeceased;
  final int? ageAtDeath;
  final String causeOfDeath;
  final List<String> conditions;
  final Map<String, String> conditionDetails;
  final bool hasHeartDisease;
  final bool hasDiabetes;
  final bool hasCancer;
  final List<String> cancerTypes;
  final bool hasHypertension;
  final bool hasStroke;
  final bool hasMentalIllness;
  final List<String> mentalIllnessTypes;
  final bool hasSubstanceAbuse;
  final bool hasGeneticDisorder;
  final List<String> geneticDisorderTypes;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'relationship': relationship.value,
      'relativeName': relativeName,
      'relativeAge': relativeAge,
      'isDeceased': isDeceased,
      'ageAtDeath': ageAtDeath,
      'causeOfDeath': causeOfDeath,
      'conditions': jsonEncode(conditions),
      'conditionDetails': jsonEncode(conditionDetails),
      'hasHeartDisease': hasHeartDisease,
      'hasDiabetes': hasDiabetes,
      'hasCancer': hasCancer,
      'cancerTypes': jsonEncode(cancerTypes),
      'hasHypertension': hasHypertension,
      'hasStroke': hasStroke,
      'hasMentalIllness': hasMentalIllness,
      'mentalIllnessTypes': jsonEncode(mentalIllnessTypes),
      'hasSubstanceAbuse': hasSubstanceAbuse,
      'hasGeneticDisorder': hasGeneticDisorder,
      'geneticDisorderTypes': jsonEncode(geneticDisorderTypes),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  FamilyHistoryModel copyWith({
    int? id,
    int? patientId,
    FamilyRelationship? relationship,
    String? relativeName,
    int? relativeAge,
    bool? isDeceased,
    int? ageAtDeath,
    String? causeOfDeath,
    List<String>? conditions,
    Map<String, String>? conditionDetails,
    bool? hasHeartDisease,
    bool? hasDiabetes,
    bool? hasCancer,
    List<String>? cancerTypes,
    bool? hasHypertension,
    bool? hasStroke,
    bool? hasMentalIllness,
    List<String>? mentalIllnessTypes,
    bool? hasSubstanceAbuse,
    bool? hasGeneticDisorder,
    List<String>? geneticDisorderTypes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyHistoryModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      relationship: relationship ?? this.relationship,
      relativeName: relativeName ?? this.relativeName,
      relativeAge: relativeAge ?? this.relativeAge,
      isDeceased: isDeceased ?? this.isDeceased,
      ageAtDeath: ageAtDeath ?? this.ageAtDeath,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      conditions: conditions ?? this.conditions,
      conditionDetails: conditionDetails ?? this.conditionDetails,
      hasHeartDisease: hasHeartDisease ?? this.hasHeartDisease,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasCancer: hasCancer ?? this.hasCancer,
      cancerTypes: cancerTypes ?? this.cancerTypes,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasStroke: hasStroke ?? this.hasStroke,
      hasMentalIllness: hasMentalIllness ?? this.hasMentalIllness,
      mentalIllnessTypes: mentalIllnessTypes ?? this.mentalIllnessTypes,
      hasSubstanceAbuse: hasSubstanceAbuse ?? this.hasSubstanceAbuse,
      hasGeneticDisorder: hasGeneticDisorder ?? this.hasGeneticDisorder,
      geneticDisorderTypes: geneticDisorderTypes ?? this.geneticDisorderTypes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for the relative
  String get displayName {
    if (relativeName.isNotEmpty) {
      return '$relativeName (${relationship.label})';
    }
    return relationship.label;
  }

  /// Get all conditions as a single list
  List<String> get allConditions {
    final all = <String>[...conditions];
    if (hasHeartDisease && !all.contains('Heart Disease')) all.add('Heart Disease');
    if (hasDiabetes && !all.contains('Diabetes')) all.add('Diabetes');
    if (hasCancer) all.addAll(cancerTypes.where((c) => !all.contains(c)));
    if (hasHypertension && !all.contains('Hypertension')) all.add('Hypertension');
    if (hasStroke && !all.contains('Stroke')) all.add('Stroke');
    if (hasMentalIllness) all.addAll(mentalIllnessTypes.where((c) => !all.contains(c)));
    if (hasSubstanceAbuse && !all.contains('Substance Abuse')) all.add('Substance Abuse');
    if (hasGeneticDisorder) all.addAll(geneticDisorderTypes.where((c) => !all.contains(c)));
    return all;
  }

  /// Check if this relative has any significant medical history
  bool get hasSignificantHistory {
    return conditions.isNotEmpty ||
           hasHeartDisease ||
           hasDiabetes ||
           hasCancer ||
           hasHypertension ||
           hasStroke ||
           hasMentalIllness ||
           hasSubstanceAbuse ||
           hasGeneticDisorder;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
    }
    return [];
  }

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return value.cast<String, String>();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return decoded.cast<String, String>();
      } catch (_) {}
    }
    return {};
  }
}

/// Summary of family history risks
class FamilyHistorySummary {
  const FamilyHistorySummary({
    required this.patientId,
    required this.entries,
  });

  final int patientId;
  final List<FamilyHistoryModel> entries;

  /// Get first-degree relatives with a specific condition
  List<FamilyHistoryModel> getFirstDegreeWith(String condition) {
    return entries.where((e) => 
      e.relationship.isFirstDegree && 
      e.allConditions.any((c) => c.toLowerCase().contains(condition.toLowerCase()))
    ).toList();
  }

  /// Check if there's a strong family history of heart disease
  bool get hasStrongHeartDiseaseHistory {
    return getFirstDegreeWith('heart').length >= 2 ||
           entries.any((e) => e.hasHeartDisease && e.relationship.isFirstDegree && 
                            (e.ageAtDeath != null && e.ageAtDeath! < 55));
  }

  /// Check if there's a strong family history of cancer
  bool get hasStrongCancerHistory {
    return entries.where((e) => e.hasCancer && e.relationship.isFirstDegree).length >= 2;
  }

  /// Check if there's a strong family history of diabetes
  bool get hasStrongDiabetesHistory {
    return getFirstDegreeWith('diabetes').length >= 2;
  }

  /// Get all unique conditions across family
  Set<String> get allFamilyConditions {
    final conditions = <String>{};
    for (final entry in entries) {
      conditions.addAll(entry.allConditions);
    }
    return conditions;
  }

  /// Get risk factors summary
  List<String> get riskFactors {
    final risks = <String>[];
    if (hasStrongHeartDiseaseHistory) risks.add('Family history of heart disease');
    if (hasStrongCancerHistory) risks.add('Family history of cancer');
    if (hasStrongDiabetesHistory) risks.add('Family history of diabetes');
    if (entries.any((e) => e.hasMentalIllness && e.relationship.isFirstDegree)) {
      risks.add('Family history of mental illness');
    }
    if (entries.any((e) => e.hasGeneticDisorder)) {
      risks.add('Family history of genetic disorders');
    }
    return risks;
  }
}
