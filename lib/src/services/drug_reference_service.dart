/// Drug Reference Service
/// Comprehensive drug database with interaction checking and FDA warnings.
/// 
/// Provides:
/// - Drug information lookup (name, class, dosage, contraindications)
/// - Drug-drug interaction checking
/// - Drug-allergy checking
/// - FDA warnings and black box alerts
/// - Alternative drug suggestions
import 'package:flutter/material.dart';

/// Main drug reference service
class DrugReferenceService {
  const DrugReferenceService();

  /// Search for drug information
  Future<List<DrugInfo>> searchDrugs(
    String query, {
    String? drugClass,
    int limit = 20,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final lowerQuery = query.toLowerCase();
    final results = _drugDatabase
        .where((drug) =>
            drug.name.toLowerCase().contains(lowerQuery) ||
            drug.genericName.toLowerCase().contains(lowerQuery))
        .where((drug) => drugClass == null || drug.drugClass == drugClass)
        .take(limit)
        .toList();

    return results;
  }

  /// Get detailed drug information
  Future<DrugInfo?> getDrugInfo(String drugId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _drugDatabase.firstWhere((drug) => drug.id == drugId);
    } catch (e) {
      return null;
    }
  }

  /// Check drug-drug interactions
  Future<List<DrugInteraction>> checkInteractions(
    List<String> drugIds, {
    bool includeLowRisk = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final interactions = <DrugInteraction>[];

    for (int i = 0; i < drugIds.length; i++) {
      for (int j = i + 1; j < drugIds.length; j++) {
        final drug1Id = drugIds[i];
        final drug2Id = drugIds[j];

        final drug1 = _drugDatabase.firstWhere((d) => d.id == drug1Id);
        final drug2 = _drugDatabase.firstWhere((d) => d.id == drug2Id);

        final interaction = _findInteraction(drug1, drug2);

        if (interaction != null) {
          if (includeLowRisk || interaction.severity.index >= 1) {
            interactions.add(interaction);
          }
        }
      }
    }

    return interactions..sort((a, b) => b.severity.index.compareTo(a.severity.index));
  }

  /// Check drug-allergy interactions
  Future<List<DrugAllergyWarning>> checkAllergyContraindications(
    String drugId,
    List<String> allergyList,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final drug = _drugDatabase.firstWhere((d) => d.id == drugId);
    final warnings = <DrugAllergyWarning>[];

    for (final allergy in allergyList) {
      final contraindicated = _isContraindicatedByAllergy(drug, allergy);
      if (contraindicated) {
        warnings.add(
          DrugAllergyWarning(
            id: '${drug.id}_$allergy',
            drugId: drug.id,
            drugName: drug.name,
            allergen: allergy,
            riskLevel: 'high',
            recommendation: 'Avoid this drug due to cross-reactivity with $allergy allergy',
            alternatives: _getAlternativeDrugs(drug, allergyList),
          ),
        );
      }
    }

    return warnings;
  }

  /// Get FDA warnings for a drug
  Future<List<FDAWarning>> getFDAWarnings(String drugId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return _fdaWarnings
        .where((warning) => warning.drugId == drugId)
        .toList();
  }

  /// Get black box warnings (most serious)
  Future<List<BlackBoxWarning>> getBlackBoxWarnings(String drugId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return _blackBoxWarnings
        .where((warning) => warning.drugId == drugId)
        .toList();
  }

  /// Get contraindications for a drug
  Future<List<Contraindication>> getContraindications(String drugId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final drug = _drugDatabase.firstWhere((d) => d.id == drugId);
    return drug.contraindications;
  }

  /// Get dosing information
  Future<DosingInfo?> getDosingInfo(
    String drugId, {
    String? patientAge,
    String? renalFunction,
    String? hepaticFunction,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final drug = _drugDatabase.firstWhere((d) => d.id == drugId);
      return drug.dosingInfo;
    } catch (e) {
      return null;
    }
  }

  /// Get alternative drugs for a given drug
  Future<List<DrugInfo>> getAlternativeDrugs(
    DrugInfo drug,
    List<String> allergyList,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _drugDatabase
        .where((alternative) =>
            alternative.drugClass == drug.drugClass &&
            alternative.id != drug.id &&
            !_hasAllergyContraindication(alternative, allergyList))
        .take(3)
        .toList();
  }

  /// Get drug-disease interactions
  Future<List<DiseaseContraindication>> checkDiseaseContraindications(
    String drugId,
    List<String> diagnosesList,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final drug = _drugDatabase.firstWhere((d) => d.id == drugId);
    final contraindications = <DiseaseContraindication>[];

    for (final diagnosis in diagnosesList) {
      if (_isContraindicatedByDisease(drug, diagnosis)) {
        contraindications.add(
          DiseaseContraindication(
            id: '${drug.id}_$diagnosis',
            drugId: drug.id,
            drugName: drug.name,
            diagnosis: diagnosis,
            severity: 'moderate',
            explanation: '$drug.name may worsen $diagnosis',
            recommendation: 'Consider alternative therapy',
          ),
        );
      }
    }

    return contraindications;
  }

  /// Helper: Find interaction between two drugs
  DrugInteraction? _findInteraction(DrugInfo drug1, DrugInfo drug2) {
    final key1 = '${drug1.id}_${drug2.id}';

    final interaction = _interactionDatabase.firstWhere(
      (i) => i.drug1Id == drug1.id && i.drug2Id == drug2.id ||
          i.drug1Id == drug2.id && i.drug2Id == drug1.id,
      orElse: () => DrugInteraction(
        id: key1,
        drug1Id: drug1.id,
        drug1Name: drug1.name,
        drug2Id: drug2.id,
        drug2Name: drug2.name,
        severity: InteractionSeverity.none,
        mechanism: '',
        management: '',
        references: [],
      ),
    );

    return interaction.severity == InteractionSeverity.none ? null : interaction;
  }

  /// Helper: Check if drug is contraindicated by allergy
  bool _isContraindicatedByAllergy(DrugInfo drug, String allergen) {
    // Simplified: check if drug class matches common allergen cross-reactions
    final allergyCrossReactions = {
      'penicillin': ['beta-lactams', 'cephalosporins'],
      'sulfa': ['thiazides', 'loop diuretics'],
      'aspirin': ['NSAIDs'],
    };

    final contraIndicators = allergyCrossReactions[allergen.toLowerCase()] ?? [];
    return contraIndicators.any((indicator) =>
        drug.drugClass.toLowerCase().contains(indicator));
  }

  /// Helper: Check if drug has allergy contraindication
  bool _hasAllergyContraindication(DrugInfo drug, List<String> allergyList) {
    return allergyList.any((allergy) =>
        _isContraindicatedByAllergy(drug, allergy));
  }

  /// Helper: Check if drug is contraindicated by disease
  bool _isContraindicatedByDisease(DrugInfo drug, String diagnosis) {
    final diseaseContraindications = {
      'asthma': ['beta-blockers', 'aspirin'],
      'gout': ['thiazides', 'loop diuretics'],
      'pregnancy': ['ACE inhibitors', 'tetracyclines'],
      'renal failure': ['NSAIDs', 'ACE inhibitors'],
    };

    final contraIndicators =
        diseaseContraindications[diagnosis.toLowerCase()] ?? [];
    return contraIndicators.any((indicator) =>
        drug.drugClass.toLowerCase().contains(indicator));
  }

  /// Helper: Get alternative drugs for allergy avoidance
  List<DrugInfo> _getAlternativeDrugs(DrugInfo drug, List<String> allergyList) {
    return _drugDatabase
        .where((alternative) =>
            alternative.drugClass == drug.drugClass &&
            alternative.id != drug.id &&
            !_hasAllergyContraindication(alternative, allergyList),
        )
        .take(3)
        .toList();
  }

  // ============================================================================
  // Sample Drug Database
  // ============================================================================

  static const List<DrugInfo> _drugDatabase = [
    DrugInfo(
      id: 'amp_500',
      name: 'Ampicillin',
      genericName: 'ampicillin',
      drugClass: 'beta-lactam antibiotics',
      mechanism: 'Inhibits bacterial cell wall synthesis',
      indications: [
        'Bacterial infections',
        'Pneumonia',
        'Urinary tract infections',
      ],
      dosage: '250-500 mg',
      frequency: 'Every 6 hours',
      sideEffects: ['Rash', 'Diarrhea', 'Nausea'],
      contraindications: [
        Contraindication(
          id: 'amp_penicillin',
          condition: 'Penicillin allergy',
          severity: 'critical',
          description: 'Risk of severe allergic reaction',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '500 mg QID',
        renalImpairment: 'Reduce dose if GFR <10',
        hepaticImpairment: 'No adjustment needed',
        pediatric: '50 mg/kg/day divided',
        geriatric: '250 mg TID',
      ),
      interactions: [],
    ),
    DrugInfo(
      id: 'amox_500',
      name: 'Amoxicillin',
      genericName: 'amoxicillin',
      drugClass: 'beta-lactam antibiotics',
      mechanism: 'Inhibits bacterial cell wall synthesis',
      indications: [
        'Bacterial infections',
        'Otitis media',
        'Strep throat',
      ],
      dosage: '250-500 mg',
      frequency: 'Every 8 hours',
      sideEffects: ['Rash', 'Allergic reactions', 'Diarrhea'],
      contraindications: [
        Contraindication(
          id: 'amox_penicillin',
          condition: 'Penicillin allergy',
          severity: 'critical',
          description: 'High risk of cross-reactivity',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '500 mg TID',
        renalImpairment: 'GFR <10: 250 mg daily',
        hepaticImpairment: 'No adjustment',
        pediatric: '25-45 mg/kg/day divided',
        geriatric: '250 mg BID-TID',
      ),
      interactions: [],
    ),
    DrugInfo(
      id: 'cipro_500',
      name: 'Ciprofloxacin',
      genericName: 'ciprofloxacin',
      drugClass: 'fluoroquinolone antibiotics',
      mechanism: 'Inhibits bacterial DNA gyrase',
      indications: [
        'UTIs',
        'Respiratory infections',
        'Gram-negative infections',
      ],
      dosage: '250-750 mg',
      frequency: 'Every 12 hours',
      sideEffects: ['Tendon rupture', 'QT prolongation', 'Photosensitivity'],
      contraindications: [
        Contraindication(
          id: 'cipro_pregnancy',
          condition: 'Pregnancy',
          severity: 'major',
          description: 'Risk to fetal development',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '500 mg BID',
        renalImpairment: 'GFR <30: 250 mg daily',
        hepaticImpairment: 'No adjustment',
        pediatric: 'Not recommended',
        geriatric: '250-500 mg BID',
      ),
      interactions: [],
    ),
    DrugInfo(
      id: 'lisin_10',
      name: 'Lisinopril',
      genericName: 'lisinopril',
      drugClass: 'ACE inhibitors',
      mechanism: 'Inhibits ACE enzyme',
      indications: ['Hypertension', 'Heart failure', 'Post-MI'],
      dosage: '10 mg',
      frequency: 'Once daily',
      sideEffects: ['Cough', 'Hyperkalemia', 'Dizziness'],
      contraindications: [
        Contraindication(
          id: 'lisin_pregnancy',
          condition: 'Pregnancy (2nd and 3rd trimester)',
          severity: 'critical',
          description: 'Teratogenic effects',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '10 mg daily',
        renalImpairment: 'GFR <30: 5 mg daily',
        hepaticImpairment: 'No adjustment',
        pediatric: '0.07 mg/kg daily',
        geriatric: '5-10 mg daily',
      ),
      interactions: [],
    ),
    DrugInfo(
      id: 'met_500',
      name: 'Metformin',
      genericName: 'metformin',
      drugClass: 'Antidiabetics',
      mechanism: 'Reduces hepatic glucose production',
      indications: ['Type 2 diabetes', 'Prediabetes'],
      dosage: '500-1000 mg',
      frequency: 'BID-TID',
      sideEffects: ['GI upset', 'Lactic acidosis', 'B12 deficiency'],
      contraindications: [
        Contraindication(
          id: 'met_renal',
          condition: 'GFR <30',
          severity: 'critical',
          description: 'Risk of lactic acidosis',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '500 mg BID-TID',
        renalImpairment: 'GFR 30-45: reduce dose; GFR <30: contraindicated',
        hepaticImpairment: 'Avoid in hepatic disease',
        pediatric: '500 mg daily-BID',
        geriatric: '250 mg daily-BID',
      ),
      interactions: [],
    ),
    DrugInfo(
      id: 'ibu_400',
      name: 'Ibuprofen',
      genericName: 'ibuprofen',
      drugClass: 'NSAIDs',
      mechanism: 'Inhibits COX-1 and COX-2',
      indications: ['Pain', 'Fever', 'Inflammation'],
      dosage: '200-400 mg',
      frequency: 'Every 6-8 hours',
      sideEffects: ['GI bleeding', 'Renal dysfunction', 'Cardiovascular risk'],
      contraindications: [
        Contraindication(
          id: 'ibu_asthma',
          condition: 'Asthma (aspirin-sensitive)',
          severity: 'major',
          description: 'Cross-reactivity risk',
        ),
      ],
      dosingInfo: DosingInfo(
        standard: '400 mg Q6-8H PRN',
        renalImpairment: 'Avoid if GFR <30',
        hepaticImpairment: 'Use caution',
        pediatric: '10 mg/kg Q6-8H',
        geriatric: '200-400 mg Q6-8H',
      ),
      interactions: [],
    ),
  ];

  // ============================================================================
  // Drug Interactions Database
  // ============================================================================

  static final List<DrugInteraction> _interactionDatabase = [
    DrugInteraction(
      id: 'int_cipro_theo',
      drug1Id: 'cipro_500',
      drug1Name: 'Ciprofloxacin',
      drug2Id: 'theo_200',
      drug2Name: 'Theophylline',
      severity: InteractionSeverity.significant,
      mechanism:
          'Ciprofloxacin inhibits CYP1A2, decreasing theophylline metabolism',
      management:
          'Monitor theophylline levels; reduce dose by 25-30% if concurrent use necessary',
      references: ['Drug Interaction Database', 'FDA Guidance'],
    ),
    DrugInteraction(
      id: 'int_lisin_pot',
      drug1Id: 'lisin_10',
      drug1Name: 'Lisinopril',
      drug2Id: 'met_500',
      drug2Name: 'Metformin',
      severity: InteractionSeverity.moderate,
      mechanism: 'Both may affect electrolyte balance',
      management: 'Monitor potassium and renal function regularly',
      references: ['Clinical guidelines'],
    ),
  ];

  // ============================================================================
  // FDA Warnings Database
  // ============================================================================

  static const List<FDAWarning> _fdaWarnings = [
    FDAWarning(
      id: 'fda_cipro_tendon',
      drugId: 'cipro_500',
      drugName: 'Ciprofloxacin',
      title: 'Fluoroquinolone Risk of Tendinopathy and Tendon Rupture',
      description:
          'Fluoroquinolones are associated with disabling and potentially permanent adverse reactions',
      dateIssued: '2013-07-23',
      severity: 'major',
    ),
    FDAWarning(
      id: 'fda_ibu_cv',
      drugId: 'ibu_400',
      drugName: 'Ibuprofen',
      title: 'NSAIDs and Cardiovascular Risk',
      description:
          'NSAIDs increase the risk of heart attack and stroke, especially with long-term use',
      dateIssued: '2015-06-10',
      severity: 'major',
    ),
  ];

  // ============================================================================
  // Black Box Warnings Database
  // ============================================================================

  static const List<BlackBoxWarning> _blackBoxWarnings = [
    BlackBoxWarning(
      id: 'bb_lisin_preg',
      drugId: 'lisin_10',
      drugName: 'Lisinopril',
      title: 'ACE Inhibitors in Pregnancy',
      description:
          'Can cause injury and death to the developing fetus. Use is contraindicated in pregnancy, especially second and third trimesters.',
      recommendation: 'Use alternative antihypertensive in women of childbearing age',
      severity: 'critical',
    ),
  ];
}

// ============================================================================
// Models
// ============================================================================

/// Drug information model
class DrugInfo {
  final String id;
  final String name;
  final String genericName;
  final String drugClass;
  final String mechanism;
  final List<String> indications;
  final String dosage;
  final String frequency;
  final List<String> sideEffects;
  final List<Contraindication> contraindications;
  final DosingInfo dosingInfo;
  final List<String> interactions;

  const DrugInfo({
    required this.id,
    required this.name,
    required this.genericName,
    required this.drugClass,
    required this.mechanism,
    required this.indications,
    required this.dosage,
    required this.frequency,
    required this.sideEffects,
    required this.contraindications,
    required this.dosingInfo,
    required this.interactions,
  });
}

/// Contraindication model
class Contraindication {
  final String id;
  final String condition;
  final String severity;
  final String description;

  const Contraindication({
    required this.id,
    required this.condition,
    required this.severity,
    required this.description,
  });
}

/// Dosing information model
class DosingInfo {
  final String standard;
  final String renalImpairment;
  final String hepaticImpairment;
  final String pediatric;
  final String geriatric;

  const DosingInfo({
    required this.standard,
    required this.renalImpairment,
    required this.hepaticImpairment,
    required this.pediatric,
    required this.geriatric,
  });
}

/// Drug interaction model
class DrugInteraction {
  final String id;
  final String drug1Id;
  final String drug1Name;
  final String drug2Id;
  final String drug2Name;
  final InteractionSeverity severity;
  final String mechanism;
  final String management;
  final List<String> references;

  const DrugInteraction({
    required this.id,
    required this.drug1Id,
    required this.drug1Name,
    required this.drug2Id,
    required this.drug2Name,
    required this.severity,
    required this.mechanism,
    required this.management,
    required this.references,
  });

  String get severityLabel {
    switch (severity) {
      case InteractionSeverity.none:
        return 'None';
      case InteractionSeverity.minor:
        return 'Minor';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.significant:
        return 'Significant';
      case InteractionSeverity.contraindicated:
        return 'Contraindicated';
    }
  }

  Color get severityColor {
    switch (severity) {
      case InteractionSeverity.none:
        return const Color(0xFF4CAF50); // green
      case InteractionSeverity.minor:
        return const Color(0xFF2196F3); // blue
      case InteractionSeverity.moderate:
        return const Color(0xFFFFC107); // amber
      case InteractionSeverity.significant:
        return const Color(0xFFFF9800); // orange
      case InteractionSeverity.contraindicated:
        return const Color(0xFFF44336); // red
    }
  }
}

/// Interaction severity enum
enum InteractionSeverity {
  none(0),
  minor(1),
  moderate(2),
  significant(3),
  contraindicated(4);

  final int value;
  const InteractionSeverity(this.value);
}

/// Drug-allergy warning model
class DrugAllergyWarning {
  final String id;
  final String drugId;
  final String drugName;
  final String allergen;
  final String riskLevel;
  final String recommendation;
  final List<DrugInfo> alternatives;

  const DrugAllergyWarning({
    required this.id,
    required this.drugId,
    required this.drugName,
    required this.allergen,
    required this.riskLevel,
    required this.recommendation,
    required this.alternatives,
  });
}

/// FDA warning model
class FDAWarning {
  final String id;
  final String drugId;
  final String drugName;
  final String title;
  final String description;
  final String dateIssued;
  final String severity;

  const FDAWarning({
    required this.id,
    required this.drugId,
    required this.drugName,
    required this.title,
    required this.description,
    required this.dateIssued,
    required this.severity,
  });
}

/// Black box warning model (most serious)
class BlackBoxWarning {
  final String id;
  final String drugId;
  final String drugName;
  final String title;
  final String description;
  final String recommendation;
  final String severity;

  const BlackBoxWarning({
    required this.id,
    required this.drugId,
    required this.drugName,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.severity,
  });
}

/// Disease contraindication model
class DiseaseContraindication {
  final String id;
  final String drugId;
  final String drugName;
  final String diagnosis;
  final String severity;
  final String explanation;
  final String recommendation;

  const DiseaseContraindication({
    required this.id,
    required this.drugId,
    required this.drugName,
    required this.diagnosis,
    required this.severity,
    required this.explanation,
    required this.recommendation,
  });
}
