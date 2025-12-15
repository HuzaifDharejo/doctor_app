import 'package:drift/drift.dart';
import '../db/doctor_db.dart';
import 'suggestions_service.dart';

/// Categories for suggestions (must match database category field)
enum SuggestionCategory {
  chiefComplaint('chief_complaint'),
  examinationFindings('examination_findings'),
  investigationResults('investigation_results'),
  diagnosis('diagnosis'),
  treatment('treatment'),
  clinicalNotes('clinical_notes'),
  medication('medication'),
  instruction('instruction'),
  symptom('symptom'),
  investigation('investigation'),
  procedure('procedure'),
  referralReason('referral_reason'),
  vitalNotes('vital_notes');

  final String value;
  const SuggestionCategory(this.value);
}

/// Service that provides dynamic suggestions by combining:
/// 1. Built-in static suggestions from SuggestionsService
/// 2. User-added suggestions from the database (sorted by usage)
class DynamicSuggestionsService {
  DynamicSuggestionsService(this._db);
  
  final DoctorDatabase _db;
  
  /// Cache for suggestions (category -> list of suggestions)
  final Map<SuggestionCategory, List<String>> _cache = {};
  
  /// Whether cache has been loaded
  bool _initialized = false;

  /// Initialize the service and load suggestions from database
  Future<void> initialize() async {
    if (_initialized) return;
    await _refreshCache();
    _initialized = true;
  }

  /// Refresh the cache from database
  Future<void> _refreshCache() async {
    _cache.clear();
    
    // Load all user suggestions from database
    final userSuggestions = await (_db.select(_db.userSuggestions)
      ..orderBy([
        (s) => OrderingTerm.desc(s.usageCount),
        (s) => OrderingTerm.desc(s.lastUsedAt),
      ]))
      .get();
    
    // Group by category
    for (final suggestion in userSuggestions) {
      final category = SuggestionCategory.values.firstWhere(
        (c) => c.value == suggestion.category,
        orElse: () => SuggestionCategory.clinicalNotes,
      );
      _cache.putIfAbsent(category, () => []);
      _cache[category]!.add(suggestion.value);
    }
  }

  /// Get suggestions for a category, combining built-in and user-added
  /// User-added suggestions appear first (sorted by usage), then built-in
  Future<List<String>> getSuggestions(SuggestionCategory category) async {
    if (!_initialized) await initialize();
    
    final userSuggestions = _cache[category] ?? [];
    final builtInSuggestions = _getBuiltInSuggestions(category);
    
    // Combine: user suggestions first, then built-in (excluding duplicates)
    final combined = <String>[...userSuggestions];
    for (final suggestion in builtInSuggestions) {
      if (!combined.any((s) => s.toLowerCase() == suggestion.toLowerCase())) {
        combined.add(suggestion);
      }
    }
    
    return combined;
  }

  /// Get built-in suggestions for a category
  List<String> _getBuiltInSuggestions(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.chiefComplaint:
        return MedicalSuggestions.chiefComplaints;
      case SuggestionCategory.examinationFindings:
        return _examinationFindingsBuiltIn;
      case SuggestionCategory.investigationResults:
        return _investigationResultsBuiltIn;
      case SuggestionCategory.diagnosis:
        return MedicalSuggestions.diagnoses;
      case SuggestionCategory.treatment:
        return _treatmentBuiltIn;
      case SuggestionCategory.clinicalNotes:
        return _clinicalNotesBuiltIn;
      case SuggestionCategory.medication:
        return PrescriptionSuggestions.medications;
      case SuggestionCategory.instruction:
        return PrescriptionSuggestions.instructions;
      case SuggestionCategory.symptom:
        return MedicalSuggestions.symptoms;
      case SuggestionCategory.investigation:
        return _investigationNamesBuiltIn;
      case SuggestionCategory.procedure:
        return _procedureBuiltIn;
      case SuggestionCategory.referralReason:
        return _referralReasonBuiltIn;
      case SuggestionCategory.vitalNotes:
        return MedicalSuggestions.vitalNotes;
    }
  }

  /// Add a new suggestion when user enters a value not in the list
  /// If suggestion already exists, increment usage count
  Future<void> addOrUpdateSuggestion(SuggestionCategory category, String value) async {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return;
    
    // Check if suggestion already exists
    final existing = await (_db.select(_db.userSuggestions)
      ..where((s) => 
        s.category.equals(category.value) & 
        s.value.lower().equals(trimmedValue.toLowerCase())
      ))
      .getSingleOrNull();
    
    if (existing != null) {
      // Update usage count and last used time
      await (_db.update(_db.userSuggestions)..where((s) => s.id.equals(existing.id)))
        .write(UserSuggestionsCompanion(
          usageCount: Value(existing.usageCount + 1),
          lastUsedAt: Value(DateTime.now()),
        ));
    } else {
      // Check if it's a built-in suggestion (don't add duplicates)
      final builtIn = _getBuiltInSuggestions(category);
      final isBuiltIn = builtIn.any((s) => s.toLowerCase() == trimmedValue.toLowerCase());
      
      if (!isBuiltIn) {
        // Add new suggestion
        await _db.into(_db.userSuggestions).insert(UserSuggestionsCompanion.insert(
          category: category.value,
          value: trimmedValue,
        ));
      }
    }
    
    // Refresh cache
    await _refreshCache();
  }

  /// Record that a suggestion was used (increment count if user-added, or add if built-in used often)
  Future<void> recordUsage(SuggestionCategory category, String value) async {
    await addOrUpdateSuggestion(category, value);
  }

  /// Delete a user-added suggestion
  Future<void> deleteSuggestion(int id) async {
    await (_db.delete(_db.userSuggestions)..where((s) => s.id.equals(id))).go();
    await _refreshCache();
  }

  /// Get all user-added suggestions for a category (for management UI)
  Future<List<UserSuggestion>> getUserSuggestions(SuggestionCategory category) async {
    return await (_db.select(_db.userSuggestions)
      ..where((s) => s.category.equals(category.value))
      ..orderBy([
        (s) => OrderingTerm.desc(s.usageCount),
        (s) => OrderingTerm.desc(s.lastUsedAt),
      ]))
      .get();
  }

  /// Clear all user suggestions for a category
  Future<void> clearCategory(SuggestionCategory category) async {
    await (_db.delete(_db.userSuggestions)
      ..where((s) => s.category.equals(category.value)))
      .go();
    await _refreshCache();
  }

  /// Clear all user suggestions
  Future<void> clearAll() async {
    await _db.delete(_db.userSuggestions).go();
    _cache.clear();
  }

  // ============================================================================
  // BUILT-IN SUGGESTIONS (not in SuggestionsService)
  // ============================================================================

  static const List<String> _examinationFindingsBuiltIn = [
    'General condition good',
    'Patient appears comfortable',
    'No acute distress',
    'Alert and oriented',
    'Well hydrated',
    'Pallor present',
    'Icterus present',
    'Cyanosis absent',
    'Clubbing absent',
    'Lymphadenopathy absent',
    'Edema absent',
    'Chest clear',
    'Bilateral air entry equal',
    'No added sounds',
    'Heart sounds S1 S2 normal',
    'No murmurs',
    'Abdomen soft',
    'Non-tender',
    'Bowel sounds present',
    'No organomegaly',
    'CNS intact',
    'Power normal all limbs',
    'Reflexes normal',
    'Pupils equal and reactive',
    'Throat congested',
    'Tonsils normal',
    'ENT examination normal',
    'Skin normal',
    'Joints normal',
    'Gait normal',
  ];

  static const List<String> _investigationResultsBuiltIn = [
    'CBC within normal limits',
    'Hemoglobin normal',
    'WBC count normal',
    'Platelet count normal',
    'Blood sugar fasting normal',
    'Blood sugar PP normal',
    'HbA1c within target',
    'LFT normal',
    'RFT normal',
    'Creatinine normal',
    'Urea normal',
    'Lipid profile normal',
    'Cholesterol elevated',
    'Triglycerides elevated',
    'Thyroid profile normal',
    'TSH normal',
    'Urine routine normal',
    'No proteinuria',
    'No glycosuria',
    'ECG normal sinus rhythm',
    'Chest X-ray normal',
    'No cardiomegaly',
    'USG abdomen normal',
    'No focal lesion',
    'Echo normal EF',
    'CT scan normal',
    'MRI normal',
    'CRP elevated',
    'ESR elevated',
    'Vitamin D deficient',
  ];

  static const List<String> _treatmentBuiltIn = [
    'Medications prescribed as above',
    'Continue current medications',
    'Dose adjusted',
    'New medication added',
    'Rest advised',
    'Plenty of oral fluids',
    'Soft diet',
    'Low salt diet',
    'Diabetic diet',
    'Weight loss advised',
    'Exercise regularly',
    'Avoid smoking',
    'Avoid alcohol',
    'Hot fomentation',
    'Steam inhalation',
    'Gargle with warm salt water',
    'Follow up in 1 week',
    'Follow up in 2 weeks',
    'Follow up as needed',
    'Review with reports',
    'Refer to specialist',
    'Admit for observation',
    'Emergency referral',
    'Physiotherapy advised',
    'Blood pressure monitoring at home',
    'Blood sugar monitoring at home',
    'Compliance counseling given',
    'Patient educated about condition',
    'Warning signs explained',
    'Return if symptoms worsen',
  ];

  static const List<String> _clinicalNotesBuiltIn = [
    'Patient is stable',
    'Condition improving',
    'Symptoms resolving',
    'Good response to treatment',
    'Partial response to treatment',
    'No improvement noted',
    'Condition unchanged',
    'New symptoms reported',
    'Side effects reported',
    'Compliance good',
    'Compliance poor',
    'Lifestyle modification counseled',
    'Diet counseling given',
    'Vaccination counseling given',
    'Follow-up scheduled',
    'Labs ordered',
    'Imaging ordered',
    'Referral made',
    'Family counseled',
    'Prognosis good',
    'Prognosis guarded',
    'Risk factors discussed',
    'Prevention measures discussed',
    'Patient questions answered',
    'Written instructions provided',
    'Emergency contact given',
    'Next visit planned',
    'Annual checkup due',
    'Screening tests advised',
    'Immunizations up to date',
  ];

  static const List<String> _investigationNamesBuiltIn = [
    'CBC', 'Complete Blood Count', 'Hemoglobin', 'WBC', 'Platelet Count',
    'LFT', 'Liver Function Test', 'RFT', 'Renal Function Test',
    'Blood Sugar Fasting', 'Blood Sugar PP', 'Random Blood Sugar', 'HbA1c',
    'Lipid Profile', 'Total Cholesterol', 'Triglycerides', 'HDL', 'LDL',
    'Thyroid Profile', 'TSH', 'T3', 'T4', 'Free T3', 'Free T4',
    'Urine Routine', 'Urine Culture', 'Stool Routine', 'Stool Culture',
    'ECG', 'Echo', '2D Echo', 'Stress Test', 'Treadmill Test',
    'Chest X-Ray', 'X-Ray Spine', 'X-Ray Knee', 'X-Ray Shoulder',
    'USG Abdomen', 'USG Pelvis', 'USG KUB', 'USG Thyroid',
    'CT Scan', 'CT Head', 'CT Abdomen', 'CT Chest', 'HRCT',
    'MRI', 'MRI Brain', 'MRI Spine', 'MRI Knee',
    'CRP', 'ESR', 'RA Factor', 'ANA', 'Anti-CCP',
    'Vitamin D', 'Vitamin B12', 'Iron Studies', 'Ferritin',
    'PT INR', 'APTT', 'D-Dimer', 'Fibrinogen',
    'Blood Group', 'Cross Match', 'Coombs Test',
  ];

  static const List<String> _procedureBuiltIn = [
    'Wound dressing',
    'Suture removal',
    'Injection given',
    'IV cannulation',
    'IV fluids started',
    'Nebulization',
    'ECG done',
    'Blood sample collected',
    'Urine sample collected',
    'Wound cleaning',
    'Abscess drainage',
    'Foreign body removal',
    'Ear wax removal',
    'Nasal packing',
    'Catheterization',
    'NG tube insertion',
    'Splinting',
    'Bandaging',
    'Vaccination given',
    'Allergy testing',
    'Skin biopsy',
    'FNAC',
    'Joint aspiration',
    'Trigger point injection',
    'Minor surgery',
  ];

  static const List<String> _referralReasonBuiltIn = [
    'For specialist opinion',
    'For further evaluation',
    'For surgical opinion',
    'Uncontrolled symptoms despite treatment',
    'Diagnostic uncertainty',
    'Advanced investigation required',
    'Procedure required',
    'Second opinion',
    'Emergency care required',
    'Multidisciplinary care needed',
    'Subspecialty expertise needed',
    'Complex case management',
    'Chronic disease management',
    'Rehabilitation services',
    'Psychological evaluation',
    'Nutritional counseling',
    'Physical therapy',
    'Pre-operative assessment',
    'Post-operative follow-up',
    'Pain management',
  ];
}
