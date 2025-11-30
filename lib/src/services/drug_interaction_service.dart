/// Drug Interaction Checking Service
/// 
/// Provides a basic database of known drug interactions
/// and methods to check for potential interactions

class DrugInteraction {
  DrugInteraction({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    this.recommendation = '',
  });

  final String drug1;
  final String drug2;
  final InteractionSeverity severity;
  final String description;
  final String recommendation;
}

enum InteractionSeverity {
  mild('Mild', 0xFFFFB74D),
  moderate('Moderate', 0xFFF57C00),
  severe('Severe', 0xFFC62828);

  const InteractionSeverity(this.label, this.colorValue);
  final String label;
  final int colorValue;
}

class DrugInteractionService {
  static final _interactions = <DrugInteraction>[
    // Antidepressants with MAO inhibitors
    DrugInteraction(
      drug1: 'SSRI',
      drug2: 'MAOI',
      severity: InteractionSeverity.severe,
      description: 'Risk of serotonin syndrome when combined',
      recommendation: 'Avoid combination. Wait 14 days after MAOI before starting SSRI.',
    ),
    // Warfarin interactions
    DrugInteraction(
      drug1: 'Warfarin',
      drug2: 'NSAIDs',
      severity: InteractionSeverity.severe,
      description: 'Increased bleeding risk',
      recommendation: 'Avoid NSAIDs. Use acetaminophen for pain relief instead.',
    ),
    // ACE inhibitors with potassium
    DrugInteraction(
      drug1: 'ACE Inhibitor',
      drug2: 'Potassium Supplement',
      severity: InteractionSeverity.moderate,
      description: 'Risk of hyperkalemia',
      recommendation: 'Monitor potassium levels. May need dose adjustment.',
    ),
    // Metformin with contrast media
    DrugInteraction(
      drug1: 'Metformin',
      drug2: 'Iodinated Contrast Media',
      severity: InteractionSeverity.moderate,
      description: 'Risk of lactic acidosis',
      recommendation: 'Hold metformin for 48 hours after contrast administration.',
    ),
    // Lithium with diuretics
    DrugInteraction(
      drug1: 'Lithium',
      drug2: 'Diuretics',
      severity: InteractionSeverity.severe,
      description: 'Increased lithium levels and toxicity risk',
      recommendation: 'Monitor lithium levels closely. May need dose adjustment.',
    ),
    // Antiarrhythmics
    DrugInteraction(
      drug1: 'Statins',
      drug2: 'Gemfibrozil',
      severity: InteractionSeverity.moderate,
      description: 'Increased risk of myopathy and rhabdomyolysis',
      recommendation: 'Choose alternative fibrate or reduce statin dose.',
    ),
    // Phenytoin interactions
    DrugInteraction(
      drug1: 'Warfarin',
      drug2: 'Phenytoin',
      severity: InteractionSeverity.moderate,
      description: 'Variable effects on warfarin metabolism',
      recommendation: 'Monitor INR closely. Dosing adjustments may be needed.',
    ),
    // St. Johns Wort
    DrugInteraction(
      drug1: 'St. Johns Wort',
      drug2: 'Warfarin',
      severity: InteractionSeverity.moderate,
      description: 'Decreased warfarin effectiveness',
      recommendation: 'Avoid combination. Increases risk of clots.',
    ),
    // QT prolongation
    DrugInteraction(
      drug1: 'Fluoroquinolones',
      drug2: 'Antiarrhythmics',
      severity: InteractionSeverity.severe,
      description: 'Risk of QT prolongation and arrhythmias',
      recommendation: 'Use alternative antibiotic if possible.',
    ),
    // Clopidogrel with SSRIs
    DrugInteraction(
      drug1: 'Clopidogrel',
      drug2: 'SSRI',
      severity: InteractionSeverity.moderate,
      description: 'Reduced clopidogrel effectiveness',
      recommendation: 'Monitor for stent thrombosis. Consider alternative antidepressant.',
    ),
  ];

  /// Check for interactions between multiple drugs
  static List<DrugInteraction> checkInteractions(List<String> drugs) {
    final interactions = <DrugInteraction>[];
    
    for (int i = 0; i < drugs.length; i++) {
      for (int j = i + 1; j < drugs.length; j++) {
        final interaction = _findInteraction(drugs[i], drugs[j]);
        if (interaction != null) {
          interactions.add(interaction);
        }
      }
    }
    
    return interactions;
  }

  /// Check interaction between two specific drugs
  static DrugInteraction? _findInteraction(String drug1, String drug2) {
    drug1 = drug1.toLowerCase().trim();
    drug2 = drug2.toLowerCase().trim();
    
    for (final interaction in _interactions) {
      final i1 = interaction.drug1.toLowerCase();
      final i2 = interaction.drug2.toLowerCase();
      
      // Check if either drug matches (case-insensitive substring)
      if ((drug1.contains(i1) || i1.contains(drug1)) &&
          (drug2.contains(i2) || i2.contains(drug2))) {
        return interaction;
      }
      
      // Check reverse order
      if ((drug1.contains(i2) || i2.contains(drug1)) &&
          (drug2.contains(i1) || i1.contains(drug2))) {
        return interaction;
      }
    }
    
    return null;
  }

  /// Get common allergy and contraindication database
  static const allergyContraindications = {
    'Penicillin': ['Cephalosporins (cross-reactivity 1-2%)', 'Beta-lactams'],
    'Sulfonamides': ['Trimethoprim', 'Thiazide diuretics'],
    'Aspirin': ['NSAIDs'],
    'Codeine': ['Morphine (may have cross-sensitivity)'],
    'Latex': ['Avocado', 'Banana', 'Kiwi'],
  };

  /// Check if patient has contraindication for drug
  static bool hasContraindication(String allergy, String drug) {
    allergy = allergy.toLowerCase().trim();
    drug = drug.toLowerCase().trim();
    
    final contraindications = allergyContraindications[allergy] ?? [];
    for (final contra in contraindications) {
      if (drug.contains(contra.toLowerCase()) || 
          contra.toLowerCase().contains(drug)) {
        return true;
      }
    }
    
    return false;
  }
}
