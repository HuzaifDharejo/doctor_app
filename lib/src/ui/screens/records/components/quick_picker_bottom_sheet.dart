import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/voice_dictation_service.dart';

/// A data class for picker options with icons
class PickerOption {
  const PickerOption({
    required this.label,
    this.icon = Icons.circle,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
}

/// Common symptom options with icons (reusable across screens)
const List<PickerOption> commonSymptomOptions = [
  PickerOption(label: 'Fever', icon: Icons.thermostat_rounded),
  PickerOption(label: 'Cough', icon: Icons.air_rounded),
  PickerOption(label: 'Cold', icon: Icons.ac_unit_rounded),
  PickerOption(label: 'Headache', icon: Icons.psychology_rounded),
  PickerOption(label: 'Body Pain', icon: Icons.accessibility_new_rounded),
  PickerOption(label: 'Stomach Pain', icon: Icons.restaurant_rounded),
  PickerOption(label: 'Vomiting', icon: Icons.sick_rounded),
  PickerOption(label: 'Diarrhea', icon: Icons.water_drop_rounded),
  PickerOption(label: 'Chest Pain', icon: Icons.favorite_rounded),
  PickerOption(label: 'Shortness of Breath', icon: Icons.airline_seat_flat_rounded),
  PickerOption(label: 'Dizziness', icon: Icons.rotate_right_rounded),
  PickerOption(label: 'Fatigue', icon: Icons.battery_1_bar_rounded),
  PickerOption(label: 'Back Pain', icon: Icons.accessibility_rounded),
  PickerOption(label: 'Joint Pain', icon: Icons.sports_martial_arts_rounded),
  PickerOption(label: 'Skin Rash', icon: Icons.blur_on_rounded),
  PickerOption(label: 'Sore Throat', icon: Icons.record_voice_over_rounded),
  PickerOption(label: 'Nausea', icon: Icons.sentiment_very_dissatisfied_rounded),
  PickerOption(label: 'Loss of Appetite', icon: Icons.no_food_rounded),
  PickerOption(label: 'Weakness', icon: Icons.battery_0_bar_rounded),
  PickerOption(label: 'Swelling', icon: Icons.bubble_chart_rounded),
];

/// Common investigation options with icons (reusable across screens)
const List<PickerOption> commonInvestigationOptions = [
  PickerOption(label: 'CBC', icon: Icons.bloodtype_rounded, subtitle: 'Complete Blood Count'),
  PickerOption(label: 'LFT', icon: Icons.science_rounded, subtitle: 'Liver Function Test'),
  PickerOption(label: 'RFT', icon: Icons.science_rounded, subtitle: 'Renal Function Test'),
  PickerOption(label: 'Blood Sugar', icon: Icons.water_drop_rounded, subtitle: 'Fasting/PP/Random'),
  PickerOption(label: 'HbA1c', icon: Icons.donut_small_rounded, subtitle: 'Glycated Hemoglobin'),
  PickerOption(label: 'Lipid Profile', icon: Icons.analytics_rounded, subtitle: 'Cholesterol Panel'),
  PickerOption(label: 'Thyroid', icon: Icons.monitor_heart_rounded, subtitle: 'TSH, T3, T4'),
  PickerOption(label: 'Urine R/E', icon: Icons.water_rounded, subtitle: 'Urine Routine'),
  PickerOption(label: 'ECG', icon: Icons.show_chart_rounded, subtitle: 'Electrocardiogram'),
  PickerOption(label: 'X-ray Chest', icon: Icons.grid_on_rounded, subtitle: 'Chest Radiograph'),
  PickerOption(label: 'USG Abdomen', icon: Icons.waves_rounded, subtitle: 'Ultrasound'),
  PickerOption(label: 'CT Scan', icon: Icons.circle_outlined, subtitle: 'CT Imaging'),
  PickerOption(label: 'MRI', icon: Icons.blur_circular_rounded, subtitle: 'MRI Imaging'),
  PickerOption(label: 'ECHO', icon: Icons.favorite_border_rounded, subtitle: 'Echocardiogram'),
  PickerOption(label: '2D Echo', icon: Icons.favorite_rounded, subtitle: 'Cardiac Ultrasound'),
  PickerOption(label: 'Serum Electrolytes', icon: Icons.electric_bolt_rounded, subtitle: 'Na, K, Cl'),
  PickerOption(label: 'CRP', icon: Icons.local_fire_department_rounded, subtitle: 'C-Reactive Protein'),
  PickerOption(label: 'ESR', icon: Icons.speed_rounded, subtitle: 'Erythrocyte Sed. Rate'),
  PickerOption(label: 'Uric Acid', icon: Icons.bubble_chart_rounded),
  PickerOption(label: 'Vitamin D', icon: Icons.wb_sunny_rounded),
  PickerOption(label: 'Vitamin B12', icon: Icons.medication_rounded),
  PickerOption(label: 'Iron Studies', icon: Icons.hardware_rounded),
  PickerOption(label: 'Stool R/E', icon: Icons.biotech_rounded, subtitle: 'Stool Routine'),
  PickerOption(label: 'Sputum', icon: Icons.air_rounded, subtitle: 'Sputum Analysis'),
];

// ============================================================================
// COMMON SUGGESTIONS FOR TEXT FIELDS
// These are used by StyledTextField's autocomplete feature
// ============================================================================

/// Common chief complaint suggestions
const List<String> chiefComplaintSuggestions = [
  'Fever since 3 days',
  'Cough and cold for 5 days',
  'Headache and body ache',
  'Stomach pain after eating',
  'Chest pain on exertion',
  'Shortness of breath',
  'Difficulty breathing',
  'Burning urination',
  'Loose stools',
  'Vomiting and nausea',
  'Weakness and fatigue',
  'Back pain',
  'Joint pain and swelling',
  'Skin rash and itching',
  'Sore throat and difficulty swallowing',
  'Dizziness and vertigo',
  'Palpitations',
  'Loss of appetite',
  'Weight loss',
  'Swelling in legs',
  'Abdominal distension',
  'Blood in stool',
  'Blood in urine',
  'Eye pain and redness',
  'Ear pain',
];

/// Common examination findings suggestions
const List<String> examinationFindingsSuggestions = [
  'Vitals stable',
  'Patient conscious, oriented',
  'Pallor present',
  'No pallor, icterus, cyanosis, clubbing, edema',
  'Lymphadenopathy present',
  'Throat congested',
  'Tonsils enlarged',
  'Chest clear, bilateral air entry equal',
  'Rhonchi present',
  'Crepitations heard',
  'Wheezing present',
  'Heart sounds S1 S2 normal, no murmur',
  'Systolic murmur grade II/VI',
  'Abdomen soft, non-tender',
  'Tenderness in right iliac fossa',
  'Hepatomegaly present',
  'Splenomegaly present',
  'Guarding and rigidity',
  'Bowel sounds present',
  'Pedal edema present',
  'Joint swelling and warmth',
  'Restricted movements',
  'Skin rash - maculopapular',
  'Pupils equal, reactive to light',
  'Neck stiffness',
  'Kernig sign positive',
  'Reflexes normal',
  'Power 5/5 all limbs',
  'Sensations intact',
  'Blood pressure elevated',
];

/// Common investigation results suggestions
const List<String> investigationResultsSuggestions = [
  'CBC - WNL',
  'Hemoglobin low (anemia)',
  'TLC elevated (infection)',
  'Platelets low',
  'Blood sugar - fasting normal, PP elevated',
  'HbA1c elevated',
  'Lipid profile - dyslipidemia',
  'Cholesterol elevated',
  'LFT - elevated liver enzymes',
  'Bilirubin elevated',
  'RFT - creatinine elevated',
  'Urea elevated',
  'Urine routine - pus cells present',
  'Urine culture positive',
  'Thyroid - TSH elevated (hypothyroid)',
  'ECG - normal sinus rhythm',
  'ECG - ST changes',
  'X-ray chest - normal',
  'X-ray - consolidation seen',
  'USG abdomen - normal',
  'USG - fatty liver',
  'USG - hepatomegaly',
  'CT scan - normal',
  'MRI - normal',
  'ECHO - normal LV function',
  'ECHO - mild MR/TR',
  'ESR elevated',
  'CRP elevated',
  'Vitamin D deficient',
  'Vitamin B12 low',
];

/// Common diagnosis suggestions
const List<String> diagnosisSuggestions = [
  'Acute viral fever',
  'Upper respiratory tract infection',
  'Acute pharyngitis',
  'Acute tonsillitis',
  'Acute bronchitis',
  'Pneumonia',
  'Acute gastroenteritis',
  'Acid peptic disease',
  'Gastritis',
  'Urinary tract infection',
  'Acute gastritis',
  'Viral fever with myalgia',
  'Dengue fever (suspected)',
  'Malaria (suspected)',
  'Typhoid fever',
  'Type 2 Diabetes Mellitus',
  'Hypertension',
  'Dyslipidemia',
  'Hypothyroidism',
  'Anemia - iron deficiency',
  'Vitamin D deficiency',
  'Osteoarthritis',
  'Lumbar spondylosis',
  'Cervical spondylosis',
  'Migraine',
  'Tension headache',
  'Allergic rhinitis',
  'Asthma - acute exacerbation',
  'COPD - acute exacerbation',
  'Ischemic heart disease',
  'Heart failure',
  'Anxiety disorder',
  'Depression',
  'Dermatitis',
  'Fungal infection - skin',
];

/// Common treatment suggestions
const List<String> treatmentSuggestions = [
  'Tab Paracetamol 500mg TDS x 3 days',
  'Tab Azithromycin 500mg OD x 3 days',
  'Tab Amoxicillin 500mg TDS x 5 days',
  'Tab Metformin 500mg BD',
  'Tab Amlodipine 5mg OD',
  'Tab Pantoprazole 40mg OD BBF',
  'Tab Cetirizine 10mg HS',
  'Tab Montelukast 10mg HS',
  'Syrup Cough expectorant TDS',
  'Tab Domperidone 10mg TDS',
  'Tab Ondansetron 4mg SOS',
  'ORS sachets - adequate hydration',
  'Steam inhalation TDS',
  'Saline nasal drops',
  'Tab Ibuprofen 400mg BD after food',
  'Tab Diclofenac 50mg BD after food',
  'Tab Omeprazole 20mg OD BBF',
  'Tab Vitamin D3 60000 IU weekly x 8 weeks',
  'Tab Vitamin B12 1500mcg OD x 1 month',
  'Tab Iron 100mg OD',
  'Nebulization with Salbutamol + Budesonide',
  'Rest and adequate hydration',
  'Low salt, low fat diet',
  'Diabetic diet - avoid sweets',
  'Follow up after 1 week',
  'Review with reports',
  'Refer to specialist if no improvement',
  'Blood tests ordered - CBC, LFT, RFT',
  'Continue current medications',
  'Lifestyle modifications advised',
];

/// Common clinical notes suggestions
const List<String> clinicalNotesSuggestions = [
  'Patient counseled regarding condition',
  'Explained prognosis and treatment plan',
  'Advised rest and adequate hydration',
  'Diet modifications discussed',
  'Medication compliance emphasized',
  'Side effects of medications explained',
  'Warning signs explained - when to seek care',
  'Follow up after completion of course',
  'Review with investigation reports',
  'Refer to specialist if symptoms persist',
  'Patient stable, can be managed on OPD basis',
  'Admission advised but patient refused',
  'Patient not affordable for all tests',
  'Limited tests done due to financial constraints',
  'Previously on similar treatment with good response',
  'Known case - on regular follow up',
  'First visit for this complaint',
  'Recurrence of previous condition',
  'Symptoms improved since last visit',
  'Symptoms worsened despite treatment',
  'Treatment modified due to poor response',
  'Added medications for better control',
  'Investigations ordered for evaluation',
  'Awaiting reports for final diagnosis',
  'Provisional diagnosis - to be confirmed',
  'Plan: Complete course and review',
  'Plan: Investigate and treat accordingly',
  'Plan: Conservative management',
  'Plan: Watch and wait approach',
  'Plan: Specialist opinion if no improvement',
];

/// Shows a modern bottom sheet picker with icons for multi-select
/// Similar to workflow wizard's quick complaint picker
Future<List<String>?> showQuickPickerBottomSheet({
  required BuildContext context,
  required String title,
  required List<PickerOption> options,
  required List<String> selected,
  Color accentColor = const Color(0xFF6366F1),
  String? subtitle,
  bool allowCustom = true,
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _QuickPickerSheet(
      title: title,
      subtitle: subtitle,
      options: options,
      initialSelected: selected,
      accentColor: accentColor,
      allowCustom: allowCustom,
    ),
  );
}

class _QuickPickerSheet extends StatefulWidget {
  const _QuickPickerSheet({
    required this.title,
    this.subtitle,
    required this.options,
    required this.initialSelected,
    required this.accentColor,
    required this.allowCustom,
  });

  final String title;
  final String? subtitle;
  final List<PickerOption> options;
  final List<String> initialSelected;
  final Color accentColor;
  final bool allowCustom;

  @override
  State<_QuickPickerSheet> createState() => _QuickPickerSheetState();
}

class _QuickPickerSheetState extends State<_QuickPickerSheet> {
  late Set<String> _selected;
  final _customController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Voice dictation
  final _dictationService = VoiceDictationService();
  bool _isListening = false;
  bool _voiceAvailable = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    _initVoice();
  }
  
  Future<void> _initVoice() async {
    final available = await _dictationService.initialize();
    if (mounted) {
      setState(() => _voiceAvailable = available);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _searchController.dispose();
    _dictationService.dispose();
    super.dispose();
  }
  
  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _dictationService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _dictationService.startListening(
        onResult: (text) {
          if (mounted && text.isNotEmpty) {
            // Parse voice input and add matching options or as custom
            _processVoiceInput(text);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: $error')),
            );
          }
        },
        onStatusChange: (listening) {
          if (mounted) {
            setState(() => _isListening = listening);
          }
        },
      );
    }
  }
  
  void _processVoiceInput(String text) {
    // Try to match spoken words to options
    final words = text.toLowerCase().split(RegExp(r'[,\s]+'));
    bool foundMatch = false;
    
    for (final word in words) {
      if (word.length < 3) continue;
      for (final option in widget.options) {
        if (option.label.toLowerCase().contains(word) ||
            word.contains(option.label.toLowerCase())) {
          if (!_selected.contains(option.label)) {
            setState(() => _selected.add(option.label));
            foundMatch = true;
          }
        }
      }
    }
    
    // If no match, add as custom if it looks like a valid entry
    if (!foundMatch && text.trim().isNotEmpty && text.trim().length > 2) {
      final cleaned = text.trim();
      // Capitalize first letter
      final capitalized = cleaned[0].toUpperCase() + cleaned.substring(1);
      if (!_selected.contains(capitalized)) {
        setState(() => _selected.add(capitalized));
      }
    }
  }

  List<PickerOption> get _filteredOptions {
    if (_searchQuery.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }
  
  /// Suggestions based on search query - shows matching but not yet selected options
  List<PickerOption> get _suggestions {
    if (_searchQuery.length < 2) return [];
    return widget.options
        .where((o) => 
            o.label.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !_selected.contains(o.label))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    size: 22,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        )
                      else
                        Text(
                          'Tap to select multiple',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_selected.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Search bar with voice
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search or type to add...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addCustom(value);
                      }
                    },
                  ),
                ),
                // Voice button
                if (_voiceAvailable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleVoice,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening 
                            ? Colors.red 
                            : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isListening 
                              ? Colors.red 
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        boxShadow: _isListening ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening 
                            ? Colors.white 
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Voice listening indicator
          if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Listening... Say symptoms like "fever, cough, headache"',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Suggestions row (when typing)
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _suggestions.map((option) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selected.add(option.label);
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(option.icon, size: 16, color: widget.accentColor),
                            const SizedBox(width: 6),
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.accentColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.add_rounded, size: 14, color: widget.accentColor),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 4),
          
          // Options grid
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredOptions.map((option) {
                    final isSelected = _selected.contains(option.label);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(option.label);
                          } else {
                            _selected.add(option.label);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? widget.accentColor 
                              : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? widget.accentColor
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_rounded : option.icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (option.subtitle != null && !isSelected)
                                  Text(
                                    option.subtitle!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // Custom input
          if (widget.allowCustom)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      decoration: InputDecoration(
                        hintText: 'Add custom...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.add_rounded,
                          color: widget.accentColor,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _addCustom,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addCustom(_customController.text),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.accentColor.withValues(alpha: 0.15),
                    ),
                    icon: Icon(Icons.add_rounded, color: widget.accentColor),
                  ),
                ],
              ),
            ),
          
          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
            child: Row(
              children: [
                // Clear all button
                if (_selected.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _selected.clear()),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                const Spacer(),
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Done button
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('Done${_selected.isNotEmpty ? ' (${_selected.length})' : ''}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCustom(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_selected.contains(trimmed)) {
      setState(() {
        _selected.add(trimmed);
        _customController.clear();
      });
    }
  }
}

/// A tap target widget that opens the quick picker
/// Shows selected items as chips and opens picker on tap
class QuickPickerField extends StatelessWidget {
  const QuickPickerField({
    super.key,
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
    this.accentColor,
    this.icon = Icons.flash_on_rounded,
    this.hint = 'Tap to select',
    this.pickerTitle,
    this.pickerSubtitle,
    this.allowCustom = true,
  });

  final String label;
  final List<String> selected;
  final List<PickerOption> options;
  final ValueChanged<List<String>> onChanged;
  final Color? accentColor;
  final IconData icon;
  final String hint;
  final String? pickerTitle;
  final String? pickerSubtitle;
  final bool allowCustom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selected.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Tap target
        GestureDetector(
          onTap: () async {
            final result = await showQuickPickerBottomSheet(
              context: context,
              title: pickerTitle ?? label,
              subtitle: pickerSubtitle,
              options: options,
              selected: selected,
              accentColor: color,
              allowCustom: allowCustom,
            );
            if (result != null) {
              onChanged(result);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected.isNotEmpty 
                    ? color.withValues(alpha: 0.5)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
            ),
            child: selected.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...selected.map((item) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                final newList = List<String>.from(selected)..remove(item);
                                onChanged(newList);
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      )),
                      // Add more button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
