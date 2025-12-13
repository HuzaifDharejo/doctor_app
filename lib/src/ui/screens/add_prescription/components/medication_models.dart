/// Medication data models for prescription management
library;

/// Data model for a medication entry
class MedicationData {
  MedicationData({
    this.name = '',
    this.dosage = '',
    this.frequency = 'OD',
    this.duration = '',
    this.timing = 'After Food',
    this.instructions = '',
  });

  factory MedicationData.fromJson(Map<String, dynamic> json) => MedicationData(
    name: (json['name'] as String?) ?? '',
    dosage: (json['dosage'] as String?) ?? '',
    frequency: (json['frequency'] as String?) ?? 'OD',
    duration: (json['duration'] as String?) ?? '',
    timing: (json['timing'] as String?) ?? 'After Food',
    instructions: (json['instructions'] as String?) ?? '',
  );

  String name;
  String dosage;
  String frequency;
  String duration;
  String timing;
  String instructions;

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'timing': timing,
    'instructions': instructions,
  };

  MedicationData copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? timing,
    String? instructions,
  }) => MedicationData(
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    frequency: frequency ?? this.frequency,
    duration: duration ?? this.duration,
    timing: timing ?? this.timing,
    instructions: instructions ?? this.instructions,
  );

  bool get isValid => name.isNotEmpty;
  
  @override
  String toString() => 'MedicationData($name, $dosage, $frequency)';
}

/// Common medication frequencies with their descriptions
class MedicationFrequency {
  const MedicationFrequency({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;
  
  static const List<MedicationFrequency> all = [
    MedicationFrequency(code: 'OD', label: 'OD', description: 'Once daily'),
    MedicationFrequency(code: 'BD', label: 'BD', description: 'Twice daily'),
    MedicationFrequency(code: 'TDS', label: 'TDS', description: 'Three times daily'),
    MedicationFrequency(code: 'QID', label: 'QID', description: 'Four times daily'),
    MedicationFrequency(code: 'SOS', label: 'SOS', description: 'As needed'),
    MedicationFrequency(code: 'HS', label: 'HS', description: 'At bedtime'),
    MedicationFrequency(code: 'AC', label: 'AC', description: 'Before meals'),
    MedicationFrequency(code: 'PC', label: 'PC', description: 'After meals'),
    MedicationFrequency(code: 'Q4H', label: 'Q4H', description: 'Every 4 hours'),
    MedicationFrequency(code: 'Q6H', label: 'Q6H', description: 'Every 6 hours'),
    MedicationFrequency(code: 'Q8H', label: 'Q8H', description: 'Every 8 hours'),
    MedicationFrequency(code: 'STAT', label: 'STAT', description: 'Immediately'),
  ];
  
  static List<String> get codes => all.map((f) => f.code).toList();
}

/// Common medication timings
class MedicationTiming {
  const MedicationTiming({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final String? icon;
  
  static const List<MedicationTiming> all = [
    MedicationTiming(value: 'Before Food', label: 'Before Food', icon: '🍽️'),
    MedicationTiming(value: 'After Food', label: 'After Food', icon: '🥗'),
    MedicationTiming(value: 'With Food', label: 'With Food', icon: '🍛'),
    MedicationTiming(value: 'Empty Stomach', label: 'Empty Stomach', icon: '⏰'),
    MedicationTiming(value: 'At Bedtime', label: 'At Bedtime', icon: '🌙'),
  ];
  
  static List<String> get values => all.map((t) => t.value).toList();
}

/// Common duration options for medications
class MedicationDuration {
  const MedicationDuration({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
  
  static const List<MedicationDuration> quickPicks = [
    MedicationDuration(value: '3 days', label: '3 days'),
    MedicationDuration(value: '5 days', label: '5 days'),
    MedicationDuration(value: '7 days', label: '7 days'),
    MedicationDuration(value: '10 days', label: '10 days'),
    MedicationDuration(value: '14 days', label: '14 days'),
    MedicationDuration(value: '1 month', label: '1 month'),
    MedicationDuration(value: '2 months', label: '2 months'),
    MedicationDuration(value: '3 months', label: '3 months'),
    MedicationDuration(value: 'Continuous', label: 'Continuous'),
  ];
  
  static List<String> get values => quickPicks.map((d) => d.value).toList();
}

/// Quick prescription template for common conditions
class PrescriptionTemplate {
  const PrescriptionTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.medications,
    this.color,
  });

  final String name;
  final String description;
  final String icon;
  final List<MedicationData> medications;
  final int? color;
  
  int get medicationCount => medications.length;
}

/// Database of quick prescription templates
class PrescriptionTemplates {
  PrescriptionTemplates._();

  static const _commonCold = [
    {'name': 'Paracetamol 500mg', 'dosage': '1 tablet', 'frequency': 'TDS', 'duration': '3 days', 'timing': 'After Food'},
    {'name': 'Cetirizine 10mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '5 days', 'timing': 'At Bedtime'},
    {'name': 'Ambroxol 30mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': '5 days', 'timing': 'After Food'},
  ];

  static const _fever = [
    {'name': 'Paracetamol 650mg', 'dosage': '1 tablet', 'frequency': 'TDS', 'duration': '3 days', 'timing': 'After Food', 'instructions': 'Take if temp > 100°F'},
    {'name': 'Vitamin C 500mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '7 days', 'timing': 'After Food'},
  ];

  static const _acidity = [
    {'name': 'Pantoprazole 40mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '14 days', 'timing': 'Before Food', 'instructions': 'Take 30 min before breakfast'},
    {'name': 'Domperidone 10mg', 'dosage': '1 tablet', 'frequency': 'TDS', 'duration': '7 days', 'timing': 'Before Food'},
  ];

  static const _uti = [
    {'name': 'Ciprofloxacin 500mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': '5 days', 'timing': 'After Food'},
    {'name': 'Cranberry Extract', 'dosage': '1 capsule', 'frequency': 'BD', 'duration': '14 days', 'timing': 'After Food'},
  ];

  static const _painRelief = [
    {'name': 'Aceclofenac 100mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': '5 days', 'timing': 'After Food'},
    {'name': 'Pantoprazole 40mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '5 days', 'timing': 'Before Food'},
    {'name': 'Thiocolchicoside 4mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': '5 days', 'timing': 'After Food'},
  ];

  static const _diabetesStarter = [
    {'name': 'Metformin 500mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': 'Continuous', 'timing': 'After Food', 'instructions': 'Take with meals'},
    {'name': 'Vitamin B12 1500mcg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '1 month', 'timing': 'After Food'},
  ];

  static const _hypertensionStarter = [
    {'name': 'Amlodipine 5mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': 'Continuous', 'timing': 'After Food'},
    {'name': 'Aspirin 75mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': 'Continuous', 'timing': 'After Food'},
  ];

  static const _allergies = [
    {'name': 'Levocetirizine 5mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '7 days', 'timing': 'At Bedtime'},
    {'name': 'Montelukast 10mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '14 days', 'timing': 'At Bedtime'},
  ];

  static const _antibioticCourse = [
    {'name': 'Azithromycin 500mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '3 days', 'timing': 'After Food'},
    {'name': 'Probiotic', 'dosage': '1 capsule', 'frequency': 'OD', 'duration': '7 days', 'timing': 'After Food'},
  ];

  static const _skinInfection = [
    {'name': 'Cefixime 200mg', 'dosage': '1 tablet', 'frequency': 'BD', 'duration': '7 days', 'timing': 'After Food'},
    {'name': 'Cetirizine 10mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '7 days', 'timing': 'At Bedtime'},
    {'name': 'Vitamin C 500mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '14 days', 'timing': 'After Food'},
  ];

  static const _vitaminsBoost = [
    {'name': 'Vitamin D3 60000IU', 'dosage': '1 sachet', 'frequency': 'Weekly', 'duration': '8 weeks', 'timing': 'After Food'},
    {'name': 'Vitamin B12 1500mcg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '1 month', 'timing': 'After Food'},
    {'name': 'Calcium + D3 500mg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': '1 month', 'timing': 'After Food'},
  ];

  static const _thyroidStarter = [
    {'name': 'Levothyroxine 50mcg', 'dosage': '1 tablet', 'frequency': 'OD', 'duration': 'Continuous', 'timing': 'Empty Stomach', 'instructions': 'Take 30 min before breakfast'},
  ];

  static List<MedicationData> _toMedications(List<Map<String, String>> list) {
    return list.map((m) => MedicationData(
      name: m['name'] ?? '',
      dosage: m['dosage'] ?? '',
      frequency: m['frequency'] ?? 'OD',
      duration: m['duration'] ?? '',
      timing: m['timing'] ?? 'After Food',
      instructions: m['instructions'] ?? '',
    )).toList();
  }

  /// All available prescription templates
  static List<PrescriptionTemplate> get all => [
    PrescriptionTemplate(
      name: 'Common Cold',
      description: 'Fever, runny nose, congestion',
      icon: '🤧',
      medications: _toMedications(_commonCold),
      color: 0xFF0EA5E9,
    ),
    PrescriptionTemplate(
      name: 'Fever',
      description: 'High temperature management',
      icon: '🌡️',
      medications: _toMedications(_fever),
      color: 0xFFEF4444,
    ),
    PrescriptionTemplate(
      name: 'Acidity & GERD',
      description: 'Heartburn, acid reflux',
      icon: '🔥',
      medications: _toMedications(_acidity),
      color: 0xFFF59E0B,
    ),
    PrescriptionTemplate(
      name: 'UTI Treatment',
      description: 'Urinary tract infection',
      icon: '💧',
      medications: _toMedications(_uti),
      color: 0xFF8B5CF6,
    ),
    PrescriptionTemplate(
      name: 'Pain & Inflammation',
      description: 'Muscle pain, joint pain',
      icon: '💪',
      medications: _toMedications(_painRelief),
      color: 0xFFEC4899,
    ),
    PrescriptionTemplate(
      name: 'Diabetes Starter',
      description: 'Initial diabetes management',
      icon: '🩸',
      medications: _toMedications(_diabetesStarter),
      color: 0xFF10B981,
    ),
    PrescriptionTemplate(
      name: 'Hypertension Starter',
      description: 'Initial BP management',
      icon: '❤️',
      medications: _toMedications(_hypertensionStarter),
      color: 0xFFEF4444,
    ),
    PrescriptionTemplate(
      name: 'Allergies',
      description: 'Allergic rhinitis, skin allergy',
      icon: '🌸',
      medications: _toMedications(_allergies),
      color: 0xFFA855F7,
    ),
    PrescriptionTemplate(
      name: 'Antibiotic Course',
      description: 'Standard antibiotic therapy',
      icon: '💊',
      medications: _toMedications(_antibioticCourse),
      color: 0xFF6366F1,
    ),
    PrescriptionTemplate(
      name: 'Skin Infection',
      description: 'Bacterial skin infection',
      icon: '🩹',
      medications: _toMedications(_skinInfection),
      color: 0xFFD946EF,
    ),
    PrescriptionTemplate(
      name: 'Vitamins Boost',
      description: 'Vitamin deficiency correction',
      icon: '✨',
      medications: _toMedications(_vitaminsBoost),
      color: 0xFFF59E0B,
    ),
    PrescriptionTemplate(
      name: 'Thyroid Starter',
      description: 'Hypothyroidism management',
      icon: '🦋',
      medications: _toMedications(_thyroidStarter),
      color: 0xFF14B8A6,
    ),
  ];

  /// Search templates by name
  static List<PrescriptionTemplate> search(String query) {
    if (query.isEmpty) return all;
    final lower = query.toLowerCase();
    return all.where((t) => 
      t.name.toLowerCase().contains(lower) ||
      t.description.toLowerCase().contains(lower)
    ).toList();
  }

  /// Get template by name
  static PrescriptionTemplate? getByName(String name) {
    try {
      return all.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }
}
