/// Allergy Checking Service
/// 
/// Provides allergy checking, contraindication warnings,
/// and allergy-related clinical decision support

class AllergyCheckResult {
  AllergyCheckResult({
    required this.hasConcern,
    required this.allergyType,
    required this.severity,
    required this.message,
    this.recommendation = '',
  });

  final bool hasConcern;
  final String allergyType;
  final AllergySeverity severity;
  final String message;
  final String recommendation;
}

enum AllergySeverity {
  mild('Mild', 0xFFFFB74D),
  moderate('Moderate', 0xFFF57C00),
  severe('Severe', 0xFFC62828),
  none('None', 0xFF4CAF50);

  const AllergySeverity(this.label, this.colorValue);
  final String label;
  final int colorValue;
}

class AllergyCheckingService {
  // Common drug allergies and their contraindications
  static const commonDrugAllergies = {
    'penicillin': {
      'contraindicated': [
        'amoxicillin',
        'ampicillin',
        'cephalexin', // Cross-reactivity 1-2%
        'cephalosporin',
        'piperacillin',
        'ticarcillin',
      ],
      'severity': 'severe',
      'description': 'Beta-lactam allergy - risk of anaphylaxis',
    },
    'sulfa': {
      'contraindicated': [
        'sulfamethoxazole',
        'sulfadiazine',
        'sulfasalazine',
        'trimethoprim',
        'thiazide',
        'furosemide',
        'bumetanide',
      ],
      'severity': 'severe',
      'description': 'Sulfonamide allergy - risk of Stevens-Johnson Syndrome',
    },
    'aspirin': {
      'contraindicated': [
        'nsaid',
        'ibuprofen',
        'naproxen',
        'meloxicam',
        'indomethacin',
      ],
      'severity': 'moderate',
      'description': 'NSAID allergy - risk of bronchospasm or anaphylaxis',
    },
    'codeine': {
      'contraindicated': [
        'morphine',
        'opioid',
        'fentanyl',
      ],
      'severity': 'moderate',
      'description': 'Opioid allergy - may have cross-sensitivity',
    },
    'latex': {
      'contraindicated': [
        'banana',
        'avocado',
        'kiwi',
        'chestnut',
      ],
      'severity': 'moderate',
      'description': 'Latex-fruit syndrome - cross-reactive allergens',
    },
  };

  /// Check if a proposed drug is safe given patient allergies
  static AllergyCheckResult checkDrugSafety({
    required String allergyHistory,
    required String proposedDrug,
  }) {
    if (allergyHistory.isEmpty || proposedDrug.isEmpty) {
      return AllergyCheckResult(
        hasConcern: false,
        allergyType: 'None',
        severity: AllergySeverity.none,
        message: 'No allergies documented',
      );
    }

    final allergies = _parseAllergies(allergyHistory);
    final drug = proposedDrug.toLowerCase().trim();

    for (final allergy in allergies) {
      final allergyInfo = _findAllergyInfo(allergy);
      if (allergyInfo != null) {
        final isContraindicated = _isContraindicated(drug, allergyInfo);
        if (isContraindicated) {
          final severity = _parseSeverity(allergyInfo['severity'] as String?);
          return AllergyCheckResult(
            hasConcern: true,
            allergyType: allergy,
            severity: severity,
            message: '⚠️ ${allergyInfo['description']} - Patient allergic to $allergy',
            recommendation: 'Choose alternative medication. Ensure epinephrine available.',
          );
        }
      }
    }

    return AllergyCheckResult(
      hasConcern: false,
      allergyType: 'None',
      severity: AllergySeverity.none,
      message: 'Drug appears safe based on documented allergies',
    );
  }

  /// Get severity indicator for allergy
  static AllergySeverity getAllergySeverity(String allergy) {
    final allergyInfo = _findAllergyInfo(allergy);
    if (allergyInfo == null) {
      return AllergySeverity.mild;
    }
    return _parseSeverity(allergyInfo['severity'] as String?);
  }

  /// Check if allergy warrants caution with specific drug class
  static bool shouldAvoidDrugClass({
    required String allergy,
    required String drugClass,
  }) {
    final allergyInfo = _findAllergyInfo(allergy);
    if (allergyInfo == null) return false;

    final contraindicated = (allergyInfo['contraindicated'] as List<dynamic>? ?? [])
        .cast<String>();
    
    for (final item in contraindicated) {
      if (drugClass.toLowerCase().contains(item.toLowerCase()) ||
          item.toLowerCase().contains(drugClass.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  /// Get allergy-related education
  static String getAllergyEducation(String allergy) {
    switch (allergy.toLowerCase().trim()) {
      case 'penicillin':
        return 'Patient has penicillin allergy. Use alternative antibiotics (fluoroquinolone, macrolide, or aminoglycoside). '
            'Cephalosporin use requires careful consideration due to 1-2% cross-reactivity.';
      case 'sulfa':
        return 'Patient has sulfa allergy. Avoid sulfonamides, thiazide diuretics, and loop diuretics (furosemide). '
            'Risk of Stevens-Johnson Syndrome is significant.';
      case 'aspirin':
        return 'Patient has aspirin/NSAID allergy. Use acetaminophen for pain/fever. '
            'For antiplatelet therapy, consider alternative agents.';
      case 'latex':
        return 'Patient has latex allergy. Use non-latex gloves and equipment. Avoid latex-containing equipment.';
      default:
        return 'Document specific reaction type and severity for this allergy.';
    }
  }

  static Map<String, dynamic>? _findAllergyInfo(String allergy) {
    final allergyLower = allergy.toLowerCase().trim();
    
    for (final entry in commonDrugAllergies.entries) {
      if (allergyLower.contains(entry.key) || entry.key.contains(allergyLower)) {
        return entry.value as Map<String, dynamic>;
      }
    }
    
    return null;
  }

  static bool _isContraindicated(String drug, Map<String, dynamic> allergyInfo) {
    final contraindicated = (allergyInfo['contraindicated'] as List<dynamic>? ?? [])
        .cast<String>();
    
    for (final item in contraindicated) {
      if (drug.contains(item.toLowerCase()) || item.toLowerCase().contains(drug)) {
        return true;
      }
    }
    
    return false;
  }

  static AllergySeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'severe':
        return AllergySeverity.severe;
      case 'moderate':
        return AllergySeverity.moderate;
      case 'mild':
        return AllergySeverity.mild;
      default:
        return AllergySeverity.moderate;
    }
  }

  static List<String> _parseAllergies(String allergyString) {
    if (allergyString.isEmpty) return [];
    return allergyString
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }
}
