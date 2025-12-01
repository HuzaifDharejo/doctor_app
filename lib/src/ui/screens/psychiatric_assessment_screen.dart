import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/suggestion_text_field.dart';

class PsychiatricAssessmentScreen extends ConsumerStatefulWidget {
  
  const PsychiatricAssessmentScreen({super.key, this.preselectedPatient});
  final Patient? preselectedPatient;

  @override
  ConsumerState<PsychiatricAssessmentScreen> createState() =>
      _PsychiatricAssessmentScreenState();
}

class _PsychiatricAssessmentScreenState
    extends ConsumerState<PsychiatricAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Date
  DateTime? _selectedDate;

  // Patient Information Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _educationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  String _maritalStatus = 'Single';

  // Presenting Complaints
  final _pcController = TextEditingController();

  // Symptoms Controllers
  final _sleepController = TextEditingController();
  final _appetiteController = TextEditingController();
  final _anxietyFearController = TextEditingController();
  final _epigastricController = TextEditingController();
  final _libidoController = TextEditingController();
  final _ocdSymptomsController = TextEditingController();
  final _ptsdController = TextEditingController();
  final _pastMedicalController = TextEditingController();
  final _epilepsyOthersController = TextEditingController();
  final _pastSurgicalController = TextEditingController();
  final _pastPsychiatricController = TextEditingController();
  final _pastEctController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _substanceAbuseController = TextEditingController();
  final _headInjuryController = TextEditingController();
  final _forensicHistoryController = TextEditingController();
  final _developmentalMilestonesController = TextEditingController();
  final _premorbidPersonalityController = TextEditingController();
  final _traumaController = TextEditingController();
  final _childAbuseController = TextEditingController();
  final _dshController = TextEditingController();
  final _suicidalSymptomsController = TextEditingController();
  final _homicideController = TextEditingController();
  final _drugAllergyController = TextEditingController();

  // History of Present Illness
  final _hopiController = TextEditingController();

  // Mental State Examination Controllers
  final _appearanceBehaviorController = TextEditingController();
  final _speechController = TextEditingController();
  final _moodController = TextEditingController();
  final _affectController = TextEditingController();
  final _thoughtsController = TextEditingController();
  final _suicideMseController = TextEditingController();
  final _ocdMseController = TextEditingController();
  final _perceptionController = TextEditingController();
  final _attentionController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _memoryRecentController = TextEditingController();
  final _memoryRemoteController = TextEditingController();
  final _memoryImmediateController = TextEditingController();
  final _judgmentController = TextEditingController();
  final _abstractThinkingController = TextEditingController();
  final _insightController = TextEditingController();

  // Delusions Checklist
  Map<String, bool> _delusions = {
    'Persecutory': false,
    'Control': false,
    'Grandiosity': false,
    'Love': false,
    'Nihilism': false,
    'Guilt': false,
  };

  // Physical Examination Controllers
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _rrController = TextEditingController();
  final _anemiaController = TextEditingController();

  // Episode & Medication History
  final _firstEpisodeController = TextEditingController();
  final _firstMedicationController = TextEditingController();
  final _secondEpisodeController = TextEditingController();
  final _secondMedicationController = TextEditingController();

  // Life History
  final _maritalHistoryController = TextEditingController();
  final _childrenController = TextEditingController();
  final _pregnancyBreastfeedingController = TextEditingController();
  final _psychosocialStressorController = TextEditingController();

  // Advise & Treatment
  final _treatmentNotesController = TextEditingController();
  final _followUp1Controller = TextEditingController();
  final _followUp2Controller = TextEditingController();

  // Expansion state
  final Map<String, bool> _expandedSections = {
    'patient_info': true,
    'presenting_complaints': false,
    'symptoms': false,
    'hopi': false,
    'mse': false,
    'physical_exam': false,
    'episode_history': false,
    'life_history': false,
    'treatment': false,
  };
  
  // Patient ID for saving
  int? _patientId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (widget.preselectedPatient != null) {
      _patientId = widget.preselectedPatient!.id;
      _nameController.text = '${widget.preselectedPatient!.firstName} ${widget.preselectedPatient!.lastName}'.trim();
      _phoneController.text = widget.preselectedPatient!.phone;
      _addressController.text = widget.preselectedPatient!.address;
      // Calculate age from DOB if available
      if (widget.preselectedPatient!.dateOfBirth != null) {
        final age = DateTime.now().year - widget.preselectedPatient!.dateOfBirth!.year;
        _ageController.text = age.toString();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Dispose all controllers
    _nameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _pcController.dispose();
    _sleepController.dispose();
    _appetiteController.dispose();
    _anxietyFearController.dispose();
    _epigastricController.dispose();
    _libidoController.dispose();
    _ocdSymptomsController.dispose();
    _ptsdController.dispose();
    _pastMedicalController.dispose();
    _epilepsyOthersController.dispose();
    _pastSurgicalController.dispose();
    _pastPsychiatricController.dispose();
    _pastEctController.dispose();
    _familyHistoryController.dispose();
    _substanceAbuseController.dispose();
    _headInjuryController.dispose();
    _forensicHistoryController.dispose();
    _developmentalMilestonesController.dispose();
    _premorbidPersonalityController.dispose();
    _traumaController.dispose();
    _childAbuseController.dispose();
    _dshController.dispose();
    _suicidalSymptomsController.dispose();
    _homicideController.dispose();
    _drugAllergyController.dispose();
    _hopiController.dispose();
    _appearanceBehaviorController.dispose();
    _speechController.dispose();
    _moodController.dispose();
    _affectController.dispose();
    _thoughtsController.dispose();
    _suicideMseController.dispose();
    _ocdMseController.dispose();
    _perceptionController.dispose();
    _attentionController.dispose();
    _concentrationController.dispose();
    _memoryRecentController.dispose();
    _memoryRemoteController.dispose();
    _memoryImmediateController.dispose();
    _judgmentController.dispose();
    _abstractThinkingController.dispose();
    _insightController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _temperatureController.dispose();
    _rrController.dispose();
    _anemiaController.dispose();
    _firstEpisodeController.dispose();
    _firstMedicationController.dispose();
    _secondEpisodeController.dispose();
    _secondMedicationController.dispose();
    _maritalHistoryController.dispose();
    _childrenController.dispose();
    _pregnancyBreastfeedingController.dispose();
    _psychosocialStressorController.dispose();
    _treatmentNotesController.dispose();
    _followUp1Controller.dispose();
    _followUp2Controller.dispose();
    super.dispose();
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Map<String, dynamic> _buildFormJson() {
    final doctorProfile = ref.read(doctorSettingsProvider).profile;
    return {
      'doctor': 'Dr: ${doctorProfile.name}',
      'assessment_date': DateTime.now().toIso8601String(),
      'patient_information': {
        'date': _selectedDate?.toIso8601String(),
        'name': _nameController.text,
        'age': _ageController.text,
        'education': _educationController.text,
        'marital_status': _maritalStatus,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'occupation': _occupationController.text,
      },
      'presenting_complaints': _pcController.text,
      'symptoms': {
        'sleep': _sleepController.text,
        'appetite': _appetiteController.text,
        'anxiety_fear': _anxietyFearController.text,
        'epigastric': _epigastricController.text,
        'libido': _libidoController.text,
        'ocd': _ocdSymptomsController.text,
        'ptsd': _ptsdController.text,
        'past_medical_dm_htn': _pastMedicalController.text,
        'epilepsy_others': _epilepsyOthersController.text,
        'past_surgical': _pastSurgicalController.text,
        'past_psychiatric': _pastPsychiatricController.text,
        'past_ect': _pastEctController.text,
        'family_history': _familyHistoryController.text,
        'substance_abuse': _substanceAbuseController.text,
        'head_injury': _headInjuryController.text,
        'forensic_history': _forensicHistoryController.text,
        'developmental_milestones': _developmentalMilestonesController.text,
        'premorbid_personality': _premorbidPersonalityController.text,
        'trauma': _traumaController.text,
        'child_abuse': _childAbuseController.text,
        'dsh': _dshController.text,
        'suicidal': _suicidalSymptomsController.text,
        'homicide': _homicideController.text,
        'drug_allergy': _drugAllergyController.text,
      },
      'history_of_present_illness': _hopiController.text,
      'mental_state_examination': {
        'appearance_behavior': _appearanceBehaviorController.text,
        'speech': _speechController.text,
        'mood': _moodController.text,
        'affect': _affectController.text,
        'thoughts': _thoughtsController.text,
        'suicide': _suicideMseController.text,
        'ocd': _ocdMseController.text,
        'delusions': _delusions,
        'perception_hallucination': _perceptionController.text,
        'attention': _attentionController.text,
        'concentration': _concentrationController.text,
        'memory': {
          'recent': _memoryRecentController.text,
          'remote': _memoryRemoteController.text,
          'immediate': _memoryImmediateController.text,
        },
        'judgment': _judgmentController.text,
        'abstract_thinking': _abstractThinkingController.text,
        'insight': _insightController.text,
      },
      'physical_examination': {
        'bp': _bpController.text,
        'pulse': _pulseController.text,
        'temperature': _temperatureController.text,
        'rr': _rrController.text,
        'anemia': _anemiaController.text,
      },
      'episode_medication_history': {
        'first_episode': _firstEpisodeController.text,
        'first_medication': _firstMedicationController.text,
        'second_episode': _secondEpisodeController.text,
        'second_medication': _secondMedicationController.text,
      },
      'life_history': {
        'marital_history': _maritalHistoryController.text,
        'children': _childrenController.text,
        'pregnancy_breastfeeding': _pregnancyBreastfeedingController.text,
        'psychosocial_stressor': _psychosocialStressorController.text,
      },
      'advise_treatment': {
        'treatment_notes': _treatmentNotesController.text,
        'follow_up_1': _followUp1Controller.text,
        'follow_up_2': _followUp2Controller.text,
      },
    };
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_patientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a patient first'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        final db = ref.read(doctorDbProvider).value!;
        final jsonData = _buildFormJson();
        
        // Save as medical record
        final record = MedicalRecordsCompanion(
          patientId: Value(_patientId!),
          recordDate: Value(_selectedDate ?? DateTime.now()),
          recordType: const Value('detailed_psychiatric_assessment'),
          title: Value('Comprehensive Psychiatric Assessment - ${DateFormat('MMM dd, yyyy').format(_selectedDate ?? DateTime.now())}'),
          description: Value(_pcController.text),
          diagnosis: Value(jsonData['mental_state_examination']?['thoughts']?.toString() ?? ''),
          treatment: Value(_treatmentNotesController.text),
          doctorNotes: Value(jsonEncode(jsonData)),
          createdAt: Value(DateTime.now()),
        );
        
        await db.insertMedicalRecord(record);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Psychiatric Assessment saved successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving assessment: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern Gradient Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
              ),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Psychiatric Assessment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate ?? DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => _showClearFormDialog(context),
                tooltip: 'Clear Form',
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Form Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Fill Section
                      _buildQuickFillSection(context, isDark),
                      const SizedBox(height: 20),

                      // Patient Information Section
                      _buildExpansionSection(
                        key: 'patient_info',
                        icon: Icons.person,
                        title: 'Patient Information',
                        colorScheme: colorScheme,
                        children: [
                          _buildDateField(context),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Patient Name',
                            icon: Icons.person_outline,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageController,
                                  label: 'Age',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  required: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _educationController,
                                  label: 'Education',
                                  icon: Icons.school_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMaritalStatusRadio(colorScheme),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _occupationController,
                            label: 'Occupation',
                            icon: Icons.work_outline,
                          ),
                        ],
                      ),

                      // Presenting Complaints Section
                      _buildExpansionSection(
                        key: 'presenting_complaints',
                        icon: Icons.sentiment_dissatisfied,
                        title: 'Presenting Complaints (PC)',
                        colorScheme: colorScheme,
                        children: [
                          _buildTextField(
                            controller: _pcController,
                            label: 'Chief Complaints',
                            hint: "Describe the patient's main complaints...",
                            maxLines: 5,
                          ),
                        ],
                      ),

                      // Symptoms Section
                      _buildExpansionSection(
                        key: 'symptoms',
                        icon: Icons.medical_services_outlined,
                        title: 'Symptoms',
                        colorScheme: colorScheme,
                        children: [
                          _buildSymptomsGrid(),
                        ],
                      ),

                      // History of Present Illness
                      _buildExpansionSection(
                        key: 'hopi',
                        icon: Icons.history,
                        title: 'History of Present Illness (HOPI)',
                        colorScheme: colorScheme,
                        children: [
                          _buildTextField(
                            controller: _hopiController,
                            label: 'History of Present Illness',
                            hint: 'Detailed history of the current illness...',
                            maxLines: 8,
                          ),
                        ],
                      ),

                      // Mental State Examination
                      _buildExpansionSection(
                        key: 'mse',
                        icon: Icons.psychology,
                        title: 'Mental State Examination (MSE)',
                        colorScheme: colorScheme,
                        children: [
                          _buildMseFields(colorScheme),
                        ],
                      ),

                      // Physical Examination
                      _buildExpansionSection(
                        key: 'physical_exam',
                        icon: Icons.favorite_outline,
                        title: 'Physical Examination',
                        colorScheme: colorScheme,
                        children: [
                          _buildPhysicalExamFields(),
                        ],
                      ),

                      // Episode & Medication History
                      _buildExpansionSection(
                        key: 'episode_history',
                        icon: Icons.calendar_month,
                        title: 'Episode & Medication History',
                        colorScheme: colorScheme,
                        children: [
                          _buildEpisodeHistoryFields(),
                        ],
                      ),

                      // Life History
                      _buildExpansionSection(
                        key: 'life_history',
                        icon: Icons.family_restroom,
                        title: 'Life History',
                        colorScheme: colorScheme,
                        children: [
                          _buildLifeHistoryFields(),
                        ],
                      ),

                      // Advise & Treatment
                      _buildExpansionSection(
                        key: 'treatment',
                        icon: Icons.medication,
                        title: 'Advise & Treatment',
                        colorScheme: colorScheme,
                        children: [
                          _buildTreatmentFields(),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveForm,
                        icon: _isSaving 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Assessment'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearFormDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Form'),
        content: const Text('Are you sure you want to clear all form fields? This action cannot be undone.'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllControllers();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearAllControllers() {
    _nameController.clear();
    _ageController.clear();
    _educationController.clear();
    _phoneController.clear();
    _addressController.clear();
    _occupationController.clear();
    _pcController.clear();
    _hopiController.clear();
    _pastPsychiatricController.clear();
    _pastMedicalController.clear();
    _familyHistoryController.clear();
    _appearanceBehaviorController.clear();
    _moodController.clear();
    _thoughtsController.clear();
    _perceptionController.clear();
    _insightController.clear();
    _treatmentNotesController.clear();
    _followUp1Controller.clear();
    _followUp2Controller.clear();
    setState(() {
      _maritalStatus = 'Single';
      _selectedDate = DateTime.now();
    });
  }

  Widget _buildQuickFillSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: Colors.amber.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Fill Templates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFillChip(
                label: 'Depression',
                icon: Icons.sentiment_dissatisfied_rounded,
                color: Colors.blue,
                onTap: () => _fillDepressionTemplate(),
              ),
              _buildQuickFillChip(
                label: 'Anxiety',
                icon: Icons.psychology_alt_rounded,
                color: Colors.purple,
                onTap: () => _fillAnxietyTemplate(),
              ),
              _buildQuickFillChip(
                label: 'Schizophrenia',
                icon: Icons.blur_on_rounded,
                color: Colors.orange,
                onTap: () => _fillSchizophreniaTemplate(),
              ),
              _buildQuickFillChip(
                label: 'Bipolar',
                icon: Icons.swap_vert_rounded,
                color: Colors.teal,
                onTap: () => _fillBipolarTemplate(),
              ),
              _buildQuickFillChip(
                label: 'OCD',
                icon: Icons.loop_rounded,
                color: Colors.pink,
                onTap: () => _fillOCDTemplate(),
              ),
              _buildQuickFillChip(
                label: 'PTSD',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => _fillPTSDTemplate(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFillChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _fillDepressionTemplate() {
    _pcController.text = 'Low mood, loss of interest, sleep disturbances';
    _moodController.text = 'Depressed, low, sad';
    _thoughtsController.text = 'Negative automatic thoughts, hopelessness';
    _sleepController.text = 'Disturbed - early morning awakening, difficulty falling asleep';
    _appetiteController.text = 'Reduced appetite';
    _treatmentNotesController.text = 'Antidepressant therapy (SSRI), Cognitive Behavioral Therapy';
    _showQuickFillSnackbar('Depression template applied');
  }

  void _fillAnxietyTemplate() {
    _pcController.text = 'Excessive worry, restlessness, difficulty concentrating';
    _moodController.text = 'Anxious, worried, apprehensive';
    _thoughtsController.text = 'Catastrophic thinking, worry about future events';
    _anxietyFearController.text = 'Generalized anxiety, anticipatory anxiety';
    _treatmentNotesController.text = 'Anxiolytic therapy, Relaxation techniques, CBT';
    _showQuickFillSnackbar('Anxiety template applied');
  }

  void _fillSchizophreniaTemplate() {
    _pcController.text = 'Auditory hallucinations, paranoid ideation, social withdrawal';
    _moodController.text = 'Flat affect, inappropriate affect';
    _thoughtsController.text = 'Delusions, thought disorder, loosening of associations';
    _perceptionController.text = 'Auditory hallucinations present';
    setState(() {
      _delusions = {
        'Persecutory': true,
        'Control': true,
        'Grandiosity': false,
        'Love': false,
        'Nihilism': false,
        'Guilt': false,
      };
    });
    _treatmentNotesController.text = 'Antipsychotic therapy, Psychosocial rehabilitation';
    _showQuickFillSnackbar('Schizophrenia template applied');
  }

  void _fillBipolarTemplate() {
    _pcController.text = 'Mood swings, periods of elevated mood and depression';
    _moodController.text = 'Fluctuating between manic and depressive episodes';
    _thoughtsController.text = 'Racing thoughts during mania, hopelessness during depression';
    _sleepController.text = 'Reduced need for sleep during mania';
    _treatmentNotesController.text = 'Mood stabilizers, Atypical antipsychotics';
    _showQuickFillSnackbar('Bipolar template applied');
  }

  void _fillOCDTemplate() {
    _pcController.text = 'Intrusive thoughts, repetitive behaviors, compulsions';
    _moodController.text = 'Anxious, distressed when unable to perform rituals';
    _thoughtsController.text = 'Obsessive thoughts, need for symmetry/order';
    _ocdSymptomsController.text = 'Contamination fears, checking behaviors, counting rituals';
    _ocdMseController.text = 'Obsessions and compulsions present with insight';
    _treatmentNotesController.text = 'SSRI therapy, Exposure and Response Prevention (ERP)';
    _showQuickFillSnackbar('OCD template applied');
  }

  void _fillPTSDTemplate() {
    _pcController.text = 'Flashbacks, nightmares, hypervigilance, avoidance';
    _moodController.text = 'Anxious, hyperaroused, emotionally numb';
    _thoughtsController.text = 'Intrusive memories, negative cognitions about self/world';
    _perceptionController.text = 'Flashback episodes, dissociative symptoms';
    _ptsdController.text = 'Traumatic event history present';
    _sleepController.text = 'Nightmares, insomnia';
    _treatmentNotesController.text = 'Trauma-focused CBT, EMDR, SSRI therapy';
    _showQuickFillSnackbar('PTSD template applied');
  }

  void _showQuickFillSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildExpansionSection({
    required String key,
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) => _toggleSection(key),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isExpanded
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isExpanded ? colorScheme.primary : colorScheme.onSurface,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isExpanded ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
              : 'Select Date',
          style: TextStyle(
            color: _selectedDate != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return maxLines > 1
        ? AppInput.multiline(
            controller: controller,
            label: required ? '$label *' : label,
            hint: hint,
            prefixIcon: icon,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
          )
        : AppInput.text(
            controller: controller,
            label: required ? '$label *' : label,
            hint: hint,
            prefixIcon: icon,
            keyboardType: keyboardType,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
          );
  }

  Widget _buildMaritalStatusRadio(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Marital Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: ['Single', 'Married', 'Divorced'].map((status) {
            final isSelected = _maritalStatus == status;
            return ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _maritalStatus = status);
                }
              },
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSymptomsGrid() {
    final symptoms = [
      {'controller': _sleepController, 'label': 'Sleep', 'suggestions': PsychiatricSuggestions.sleep},
      {'controller': _appetiteController, 'label': 'Appetite', 'suggestions': PsychiatricSuggestions.appetite},
      {'controller': _anxietyFearController, 'label': 'Anxiety/Fear', 'suggestions': PsychiatricSuggestions.anxietyFear},
      {'controller': _epigastricController, 'label': 'Epigastric', 'suggestions': PsychiatricSuggestions.epigastric},
      {'controller': _libidoController, 'label': 'Libido', 'suggestions': PsychiatricSuggestions.libido},
      {'controller': _ocdSymptomsController, 'label': 'OCD', 'suggestions': PsychiatricSuggestions.ocdSymptoms},
      {'controller': _ptsdController, 'label': 'PTSD', 'suggestions': PsychiatricSuggestions.ptsd},
      {'controller': _pastMedicalController, 'label': 'Past Medical (DM/HTN)', 'suggestions': PsychiatricSuggestions.pastMedical},
      {'controller': _epilepsyOthersController, 'label': 'Epilepsy/Others', 'suggestions': PsychiatricSuggestions.epilepsyOthers},
      {'controller': _pastSurgicalController, 'label': 'Past Surgical', 'suggestions': PsychiatricSuggestions.pastSurgical},
      {'controller': _pastPsychiatricController, 'label': 'Past Psychiatric', 'suggestions': PsychiatricSuggestions.pastPsychiatric},
      {'controller': _pastEctController, 'label': 'Past ECT', 'suggestions': PsychiatricSuggestions.pastEct},
      {'controller': _familyHistoryController, 'label': 'Family History', 'suggestions': PsychiatricSuggestions.familyHistory},
      {'controller': _substanceAbuseController, 'label': 'Substance Abuse', 'suggestions': PsychiatricSuggestions.substanceAbuse},
      {'controller': _headInjuryController, 'label': 'Head Injury', 'suggestions': PsychiatricSuggestions.headInjury},
      {'controller': _forensicHistoryController, 'label': 'Forensic History', 'suggestions': PsychiatricSuggestions.forensicHistory},
      {
        'controller': _developmentalMilestonesController,
        'label': 'Developmental Milestones',
        'suggestions': PsychiatricSuggestions.developmentalMilestones,
      },
      {
        'controller': _premorbidPersonalityController,
        'label': 'Premorbid Personality',
        'suggestions': PsychiatricSuggestions.premorbidPersonality,
      },
      {'controller': _traumaController, 'label': 'Trauma', 'suggestions': PsychiatricSuggestions.trauma},
      {'controller': _childAbuseController, 'label': 'Child Abuse', 'suggestions': PsychiatricSuggestions.childAbuse},
      {'controller': _dshController, 'label': 'DSH', 'suggestions': PsychiatricSuggestions.dsh},
      {'controller': _suicidalSymptomsController, 'label': 'Suicidal', 'suggestions': PsychiatricSuggestions.suicidal},
      {'controller': _homicideController, 'label': 'Homicide', 'suggestions': PsychiatricSuggestions.homicide},
      {'controller': _drugAllergyController, 'label': 'Drug Allergy', 'suggestions': PsychiatricSuggestions.drugAllergy},
    ];

    return Column(
      children: [
        for (int i = 0; i < symptoms.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller:
                        symptoms[i]['controller']! as TextEditingController,
                    label: symptoms[i]['label']! as String,
                    suggestions: symptoms[i]['suggestions'] as List<String>?,
                  ),
                ),
                if (i + 1 < symptoms.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactTextField(
                      controller: symptoms[i + 1]['controller']!
                          as TextEditingController,
                      label: symptoms[i + 1]['label']! as String,
                      suggestions: symptoms[i + 1]['suggestions'] as List<String>?,
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    List<String>? suggestions,
  }) {
    if (suggestions != null && suggestions.isNotEmpty) {
      return SuggestionTextField(
        controller: controller,
        label: label,
        suggestions: suggestions,
        appendMode: false,
      );
    }
    return AppInput.text(
      controller: controller,
      label: label,
    );
  }

  Widget _buildMseFields(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionTextField(
          controller: _appearanceBehaviorController,
          label: 'Appearance & Behavior',
          suggestions: const [...MedicalRecordSuggestions.appearance, ...MedicalRecordSuggestions.behavior],
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _speechController,
                label: 'Speech',
                suggestions: MedicalRecordSuggestions.speech,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _moodController,
                label: 'Mood',
                suggestions: MedicalRecordSuggestions.mood,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _affectController,
                label: 'Affect',
                suggestions: MedicalRecordSuggestions.affect,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _thoughtsController,
                label: 'Thoughts',
                suggestions: [...MedicalRecordSuggestions.thoughtContent, ...MedicalRecordSuggestions.thoughtProcess],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _suicideMseController,
                label: 'Suicide',
                suggestions: PsychiatricSuggestions.suicidal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _ocdMseController,
                label: 'OCD',
                suggestions: PsychiatricSuggestions.ocdSymptoms,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Delusions Checklist
        Text(
          'Delusions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _delusions.keys.map((delusion) {
            return FilterChip(
              label: Text(delusion),
              selected: _delusions[delusion]!,
              onSelected: (selected) {
                setState(() {
                  _delusions[delusion] = selected;
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        SuggestionTextField(
          controller: _perceptionController,
          label: 'Perception (Hallucination)',
          suggestions: MedicalRecordSuggestions.perception,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _attentionController,
                label: 'Attention',
                suggestions: PsychiatricSuggestions.attention,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _concentrationController,
                label: 'Concentration',
                suggestions: PsychiatricSuggestions.concentration,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Memory Fields
        Text(
          'Memory',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _memoryRecentController,
                label: 'Recent',
                suggestions: PsychiatricSuggestions.memoryRecent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTextField(
                controller: _memoryRemoteController,
                label: 'Remote',
                suggestions: PsychiatricSuggestions.memoryRemote,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactTextField(
                controller: _memoryImmediateController,
                label: 'Immediate',
                suggestions: PsychiatricSuggestions.memoryImmediate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _judgmentController,
                label: 'Judgment',
                suggestions: MedicalRecordSuggestions.judgment,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _abstractThinkingController,
                label: 'Abstract Thinking',
                suggestions: PsychiatricSuggestions.abstractThinking,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _insightController,
          suggestions: MedicalRecordSuggestions.insight,
          label: 'Insight',
        ),
      ],
    );
  }

  Widget _buildPhysicalExamFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _bpController,
                label: 'BP (mmHg)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _pulseController,
                label: 'Pulse (bpm)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _temperatureController,
                label: 'Temperature (°F)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTextField(
                controller: _rrController,
                label: 'R/R (breaths/min)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _anemiaController,
          label: 'Anemia',
        ),
      ],
    );
  }

  Widget _buildEpisodeHistoryFields() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Episode
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'First Episode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _firstEpisodeController,
                label: 'Episode Details',
              ),
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _firstMedicationController,
                label: 'Medication',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Second Episode
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Second Episode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _secondEpisodeController,
                label: 'Episode Details',
              ),
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _secondMedicationController,
                label: 'Medication',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifeHistoryFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _maritalHistoryController,
          label: 'Marital History',
          icon: Icons.favorite_outline,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _childrenController,
          label: 'Children',
          icon: Icons.child_care,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _pregnancyBreastfeedingController,
          label: 'Pregnancy/Breastfeeding Status',
          icon: Icons.pregnant_woman,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _psychosocialStressorController,
          label: 'Psychosocial Stressor',
          icon: Icons.psychology_alt,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTreatmentFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _treatmentNotesController,
          label: 'Treatment Notes',
          hint: 'Medications, therapy recommendations, etc.',
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _followUp1Controller,
          label: 'Follow-up 1',
          hint: 'First follow-up notes...',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _followUp2Controller,
          label: 'Follow-up 2',
          hint: 'Second follow-up notes...',
          maxLines: 3,
        ),
      ],
    );
  }
}

