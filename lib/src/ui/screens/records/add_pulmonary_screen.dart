import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/suggestions_service.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../widgets/suggestion_text_field.dart';
import 'record_form_widgets.dart';
import 'components/record_components.dart';

/// Screen for adding a Pulmonary Evaluation medical record
class AddPulmonaryScreen extends ConsumerStatefulWidget {
  const AddPulmonaryScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddPulmonaryScreen> createState() => _AddPulmonaryScreenState();
}

class _AddPulmonaryScreenState extends ConsumerState<AddPulmonaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'symptoms': GlobalKey(),
    'history': GlobalKey(),
    'vitals': GlobalKey(),
    'auscultation': GlobalKey(),
    'investigations': GlobalKey(),
    'diagnosis': GlobalKey(),
    'treatment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'symptoms': true,
    'history': true,
    'vitals': true,
    'auscultation': true,
    'investigations': true,
    'diagnosis': true,
    'treatment': true,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Pulmonary Evaluation Fields
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  final _symptomCharacterController = TextEditingController();
  List<String> _selectedSystemicSymptoms = [];
  List<String> _selectedRedFlags = [];
  final _pastPulmonaryHistoryController = TextEditingController();
  final _exposureHistoryController = TextEditingController();
  final _allergyHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  List<String> _selectedComorbidities = [];
  
  // Chest Auscultation
  final _breathSoundsController = TextEditingController();
  List<String> _selectedAddedSounds = [];
  final _rightUpperZoneController = TextEditingController();
  final _rightMiddleZoneController = TextEditingController();
  final _rightLowerZoneController = TextEditingController();
  final _leftUpperZoneController = TextEditingController();
  final _leftMiddleZoneController = TextEditingController();
  final _leftLowerZoneController = TextEditingController();
  final _additionalFindingsController = TextEditingController();
  
  // Vitals
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _peakFlowController = TextEditingController();
  
  // Investigations & Plan
  List<String> _selectedInvestigations = [];
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _followUpPlanController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
    
    // Initialize pulmonary-specific templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Asthma',
        icon: Icons.air_rounded,
        color: Colors.blue,
        description: 'Bronchial Asthma template',
        data: {
          'chief_complaint': 'Difficulty breathing, wheezing, chest tightness',
          'symptom_character': 'Episodic, worse at night/early morning',
          'systemic_symptoms': ['Cough', 'Shortness of breath'],
          'added_sounds': ['Wheeze', 'Rhonchi'],
          'breath_sounds': 'Bilateral wheeze',
          'diagnosis': 'Bronchial Asthma',
          'treatment': 'Inhaled bronchodilators (SABA), Inhaled corticosteroids (ICS)',
        },
      ),
      QuickFillTemplateItem(
        label: 'COPD',
        icon: Icons.smoke_free,
        color: Colors.orange,
        description: 'Chronic Obstructive Pulmonary Disease template',
        data: {
          'chief_complaint': 'Progressive dyspnea, chronic cough with sputum',
          'symptom_character': 'Chronic, progressive',
          'duration': 'Several years',
          'systemic_symptoms': ['Cough', 'Shortness of breath', 'Fatigue'],
          'comorbidities': ['Smoking', 'Chronic Bronchitis'],
          'added_sounds': ['Rhonchi', 'Diminished breath sounds'],
          'breath_sounds': 'Diminished with prolonged expiration',
          'diagnosis': 'COPD',
          'treatment': 'LABA/LAMA, ICS if frequent exacerbations, Pulmonary rehabilitation',
        },
      ),
      QuickFillTemplateItem(
        label: 'Pneumonia',
        icon: Icons.coronavirus_outlined,
        color: Colors.red,
        description: 'Community-acquired Pneumonia template',
        data: {
          'chief_complaint': 'Fever, productive cough, pleuritic chest pain',
          'symptom_character': 'Acute onset',
          'duration': '3-7 days',
          'systemic_symptoms': ['Fever', 'Cough', 'Shortness of breath', 'Fatigue'],
          'red_flags': ['High fever', 'Hypoxia', 'Altered sensorium'],
          'added_sounds': ['Crepitations', 'Bronchial breath sounds'],
          'investigations': ['Chest X-ray', 'CBC', 'Sputum culture'],
          'breath_sounds': 'Bronchial breath sounds over affected area',
          'diagnosis': 'Community-acquired Pneumonia',
          'treatment': 'Antibiotics (Amoxicillin-Clavulanate or Respiratory fluoroquinolone), Supportive care',
        },
      ),
      QuickFillTemplateItem(
        label: 'Bronchitis',
        icon: Icons.sick_outlined,
        color: Colors.teal,
        description: 'Acute Bronchitis template',
        data: {
          'chief_complaint': 'Cough with or without sputum, chest discomfort',
          'symptom_character': 'Acute onset, usually following viral URTI',
          'duration': '1-2 weeks',
          'systemic_symptoms': ['Cough', 'Mild fever'],
          'added_sounds': ['Rhonchi'],
          'breath_sounds': 'Scattered rhonchi, clear with coughing',
          'diagnosis': 'Acute Bronchitis',
          'treatment': 'Symptomatic treatment, cough suppressants, hydration, rest',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Chest Exam',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        description: 'Normal chest examination',
        data: {
          'breath_sounds': 'Vesicular, bilateral equal air entry',
          'diagnosis': 'Normal Chest Examination',
          'treatment': 'No specific treatment required. General advice given.',
        },
      ),
    ];
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      
      if (data['chief_complaint'] != null) {
        _chiefComplaintController.text = data['chief_complaint'] as String;
      }
      if (data['symptom_character'] != null) {
        _symptomCharacterController.text = data['symptom_character'] as String;
      }
      if (data['duration'] != null) {
        _durationController.text = data['duration'] as String;
      }
      if (data['systemic_symptoms'] != null) {
        _selectedSystemicSymptoms = List<String>.from(data['systemic_symptoms'] as List);
      }
      if (data['red_flags'] != null) {
        _selectedRedFlags = List<String>.from(data['red_flags'] as List);
      }
      if (data['comorbidities'] != null) {
        _selectedComorbidities = List<String>.from(data['comorbidities'] as List);
      }
      if (data['added_sounds'] != null) {
        _selectedAddedSounds = List<String>.from(data['added_sounds'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
      if (data['breath_sounds'] != null) {
        _breathSoundsController.text = data['breath_sounds'] as String;
      }
      if (data['diagnosis'] != null) {
        _diagnosisController.text = data['diagnosis'] as String;
      }
      if (data['treatment'] != null) {
        _treatmentController.text = data['treatment'] as String;
      }
    });
    
    showTemplateAppliedSnackbar(context, template.label, color: template.color);
  }

  void _scrollToSection(String sectionKey) {
    final key = _sectionKeys[sectionKey];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  List<SectionInfo> get _sections => [
    SectionInfo(
      key: 'complaint',
      title: 'Complaint',
      icon: Icons.air,
      isComplete: _chiefComplaintController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'symptoms',
      title: 'Symptoms',
      icon: Icons.thermostat_outlined,
      isComplete: _selectedSystemicSymptoms.isNotEmpty || _selectedRedFlags.isNotEmpty,
    ),
    SectionInfo(
      key: 'history',
      title: 'History',
      icon: Icons.history,
      isComplete: _pastPulmonaryHistoryController.text.isNotEmpty || _selectedComorbidities.isNotEmpty,
    ),
    SectionInfo(
      key: 'vitals',
      title: 'Vitals',
      icon: Icons.favorite_outline,
      isComplete: _bpController.text.isNotEmpty || _spo2Controller.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'auscultation',
      title: 'Auscultation',
      icon: Icons.hearing,
      isComplete: _breathSoundsController.text.isNotEmpty || _selectedAddedSounds.isNotEmpty,
    ),
    SectionInfo(
      key: 'investigations',
      title: 'Investigations',
      icon: Icons.biotech,
      isComplete: _selectedInvestigations.isNotEmpty,
    ),
    SectionInfo(
      key: 'diagnosis',
      title: 'Diagnosis',
      icon: Icons.medical_information,
      isComplete: _diagnosisController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'treatment',
      title: 'Treatment',
      icon: Icons.healing,
      isComplete: _treatmentController.text.isNotEmpty,
    ),
  ];

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatment ?? '';
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _chiefComplaintController.text = (data['chief_complaint'] as String?) ?? '';
        _durationController.text = (data['duration'] as String?) ?? '';
        _symptomCharacterController.text = (data['symptom_character'] as String?) ?? '';
        _selectedSystemicSymptoms = List<String>.from((data['systemic_symptoms'] as List?) ?? []);
        _selectedRedFlags = List<String>.from((data['red_flags'] as List?) ?? []);
        _pastPulmonaryHistoryController.text = (data['past_pulmonary_history'] as String?) ?? '';
        _exposureHistoryController.text = (data['exposure_history'] as String?) ?? '';
        _allergyHistoryController.text = (data['allergy_atopy_history'] as String?) ?? '';
        _currentMedicationsController.text = (data['current_medications'] as List?)?.join(', ') ?? '';
        _selectedComorbidities = List<String>.from((data['comorbidities'] as List?) ?? []);
        _selectedInvestigations = List<String>.from((data['investigations_required'] as List?) ?? []);
        _followUpPlanController.text = (data['follow_up_plan'] as String?) ?? '';
        
        final auscultation = data['chest_auscultation'] as Map<String, dynamic>?;
        if (auscultation != null) {
          _breathSoundsController.text = (auscultation['breath_sounds'] as String?) ?? '';
          _selectedAddedSounds = List<String>.from((auscultation['added_sounds'] as List?) ?? []);
          _rightUpperZoneController.text = (auscultation['right_upper_zone'] as String?) ?? '';
          _rightMiddleZoneController.text = (auscultation['right_middle_zone'] as String?) ?? '';
          _rightLowerZoneController.text = (auscultation['right_lower_zone'] as String?) ?? '';
          _leftUpperZoneController.text = (auscultation['left_upper_zone'] as String?) ?? '';
          _leftMiddleZoneController.text = (auscultation['left_middle_zone'] as String?) ?? '';
          _leftLowerZoneController.text = (auscultation['left_lower_zone'] as String?) ?? '';
          _additionalFindingsController.text = (auscultation['additional_findings'] as String?) ?? '';
        }
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpController.text = (vitals['bp'] as String?) ?? '';
          _pulseController.text = (vitals['pulse'] as String?) ?? '';
          _tempController.text = (vitals['temperature'] as String?) ?? '';
          _weightController.text = (vitals['weight'] as String?) ?? '';
          _respiratoryRateController.text = (vitals['respiratory_rate'] as String?) ?? '';
          _spo2Controller.text = (vitals['spo2'] as String?) ?? '';
          _peakFlowController.text = (vitals['peak_flow_rate'] as String?) ?? '';
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _symptomCharacterController.dispose();
    _pastPulmonaryHistoryController.dispose();
    _exposureHistoryController.dispose();
    _allergyHistoryController.dispose();
    _currentMedicationsController.dispose();
    _breathSoundsController.dispose();
    _rightUpperZoneController.dispose();
    _rightMiddleZoneController.dispose();
    _rightLowerZoneController.dispose();
    _leftUpperZoneController.dispose();
    _leftMiddleZoneController.dispose();
    _leftLowerZoneController.dispose();
    _additionalFindingsController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _respiratoryRateController.dispose();
    _spo2Controller.dispose();
    _peakFlowController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _followUpPlanController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'duration': _durationController.text.isNotEmpty ? _durationController.text : null,
      'symptom_character': _symptomCharacterController.text.isNotEmpty ? _symptomCharacterController.text : null,
      'systemic_symptoms': _selectedSystemicSymptoms.isNotEmpty ? _selectedSystemicSymptoms : null,
      'red_flags': _selectedRedFlags.isNotEmpty ? _selectedRedFlags : null,
      'past_pulmonary_history': _pastPulmonaryHistoryController.text.isNotEmpty ? _pastPulmonaryHistoryController.text : null,
      'exposure_history': _exposureHistoryController.text.isNotEmpty ? _exposureHistoryController.text : null,
      'allergy_atopy_history': _allergyHistoryController.text.isNotEmpty ? _allergyHistoryController.text : null,
      'current_medications': _currentMedicationsController.text.isNotEmpty 
          ? _currentMedicationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() 
          : null,
      'comorbidities': _selectedComorbidities.isNotEmpty ? _selectedComorbidities : null,
      'chest_auscultation': {
        'breath_sounds': _breathSoundsController.text.isNotEmpty ? _breathSoundsController.text : null,
        'added_sounds': _selectedAddedSounds.isNotEmpty ? _selectedAddedSounds : null,
        'right_upper_zone': _rightUpperZoneController.text.isNotEmpty ? _rightUpperZoneController.text : null,
        'right_middle_zone': _rightMiddleZoneController.text.isNotEmpty ? _rightMiddleZoneController.text : null,
        'right_lower_zone': _rightLowerZoneController.text.isNotEmpty ? _rightLowerZoneController.text : null,
        'left_upper_zone': _leftUpperZoneController.text.isNotEmpty ? _leftUpperZoneController.text : null,
        'left_middle_zone': _leftMiddleZoneController.text.isNotEmpty ? _leftMiddleZoneController.text : null,
        'left_lower_zone': _leftLowerZoneController.text.isNotEmpty ? _leftLowerZoneController.text : null,
        'additional_findings': _additionalFindingsController.text.isNotEmpty ? _additionalFindingsController.text : null,
      },
      'investigations_required': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
      'follow_up_plan': _followUpPlanController.text.isNotEmpty ? _followUpPlanController.text : null,
      'vitals': {
        'bp': _bpController.text.isNotEmpty ? _bpController.text : null,
        'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null,
        'temperature': _tempController.text.isNotEmpty ? _tempController.text : null,
        'respiratory_rate': _respiratoryRateController.text.isNotEmpty ? _respiratoryRateController.text : null,
        'spo2': _spo2Controller.text.isNotEmpty ? _spo2Controller.text : null,
        'peak_flow_rate': _peakFlowController.text.isNotEmpty ? _peakFlowController.text : null,
        'weight': _weightController.text.isNotEmpty ? _weightController.text : null,
      },
    };
  }

  Future<void> _saveRecord(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      RecordFormWidgets.showErrorSnackbar(context, 'Please select a patient');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: 'pulmonary_evaluation',
        title: _diagnosisController.text.isNotEmpty 
            ? 'Pulmonary: ${_diagnosisController.text}'
            : 'Pulmonary Evaluation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'pulmonary_evaluation',
          title: _diagnosisController.text.isNotEmpty 
              ? 'Pulmonary: ${_diagnosisController.text}'
              : 'Pulmonary Evaluation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _chiefComplaintController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Pulmonary evaluation updated successfully!' 
              : 'Pulmonary evaluation saved successfully!',
        );
        Navigator.pop(context, resultRecord);
      }
    } catch (e) {
      if (mounted) {
        RecordFormWidgets.showErrorSnackbar(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Total sections for progress calculation
  static const int _totalSections = 8; // Patient, Date, Complaint, Symptoms, Auscultation, Vitals, Diagnosis, Treatment

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null || widget.preselectedPatient != null) completed++;
    if (_chiefComplaintController.text.isNotEmpty) completed++;
    if (_durationController.text.isNotEmpty) completed++;
    if (_selectedSystemicSymptoms.isNotEmpty) completed++;
    if (_breathSoundsController.text.isNotEmpty || _selectedAddedSounds.isNotEmpty) completed++;
    // Vitals - check if any vital is filled
    if (_bpController.text.isNotEmpty || _pulseController.text.isNotEmpty || _spo2Controller.text.isNotEmpty) {
      completed++;
    }
    if (_diagnosisController.text.isNotEmpty) completed++;
    if (_treatmentController.text.isNotEmpty) completed++;
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Pulmonary Evaluation' 
          : 'Pulmonary Evaluation',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.air_rounded,
      gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Info Cyan
      scrollController: _scrollController,
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    final completedSections = _calculateCompletedSections();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Indicator
          FormProgressIndicator(
            completedSections: completedSections,
            totalSections: _totalSections,
            accentColor: const Color(0xFF06B6D4),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: const Color(0xFF06B6D4),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Fill Templates (using new component)
          QuickFillTemplateBar(
            templates: _templates,
            onTemplateSelected: _applyTemplate,
            collapsible: true,
            initiallyExpanded: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Patient Selection / Info Card
          if (widget.preselectedPatient != null)
            PatientInfoCard(
              patient: widget.preselectedPatient!,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              icon: Icons.air_rounded,
            )
          else
            PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onChanged: (id) => setState(() => _selectedPatientId = id),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Date Selection
          DatePickerCard(
            label: 'Evaluation Date',
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chief Complaint
          RecordFormSection(
            key: _sectionKeys['complaint'],
            title: 'Presenting Complaint',
            icon: Icons.air,
            accentColor: const Color(0xFF06B6D4),
            collapsible: true,
            initiallyExpanded: _expandedSections['complaint'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _chiefComplaintController,
                  label: 'Chief Complaint',
                  hint: 'Describe the main respiratory complaint...',
                  prefixIcon: Icons.air,
                  maxLines: 3,
                  suggestions: PulmonarySuggestions.chiefComplaints,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SuggestionTextField(
                        controller: _durationController,
                        label: 'Duration',
                        hint: 'How long?',
                        prefixIcon: Icons.schedule,
                        suggestions: PulmonarySuggestions.durations,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SuggestionTextField(
                        controller: _symptomCharacterController,
                        label: 'Character',
                        hint: 'Type of symptom',
                        prefixIcon: Icons.description_outlined,
                        suggestions: PulmonarySuggestions.symptomCharacters,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Symptoms Section (Systemic Symptoms + Red Flags)
          RecordFormSection(
            key: _sectionKeys['symptoms'],
            title: 'Symptoms & Red Flags',
            icon: Icons.thermostat_outlined,
            accentColor: AppColors.warning,
            collapsible: true,
            initiallyExpanded: _expandedSections['symptoms'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['symptoms'] = expanded),
            child: Column(
              children: [
                ChipSelectorSection(
                  title: 'Systemic Symptoms',
                  options: PulmonarySuggestions.systemicSymptoms,
                  selected: _selectedSystemicSymptoms,
                  onChanged: (list) => setState(() => _selectedSystemicSymptoms = list),
                  accentColor: AppColors.warning,
                  showClearButton: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                ChipSelectorSection(
                  title: 'Red Flags',
                  options: PulmonarySuggestions.redFlags,
                  selected: _selectedRedFlags,
                  onChanged: (list) => setState(() => _selectedRedFlags = list),
                  accentColor: AppColors.error,
                  showClearButton: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clinical History
          RecordFormSection(
            key: _sectionKeys['history'],
            title: 'Clinical History',
            icon: Icons.history,
            accentColor: const Color(0xFF3B82F6),
            collapsible: true,
            initiallyExpanded: _expandedSections['history'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['history'] = expanded),
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _pastPulmonaryHistoryController,
                  label: 'Past Pulmonary History',
                  hint: 'Previous respiratory conditions...',
                  prefixIcon: Icons.history,
                  maxLines: 2,
                  suggestions: PulmonarySuggestions.pastPulmonaryHistory,
                ),
                const SizedBox(height: AppSpacing.md),
                SuggestionTextField(
                  controller: _exposureHistoryController,
                  label: 'Exposure History',
                  hint: 'Smoking, occupational, environmental...',
                  prefixIcon: Icons.smoke_free,
                  maxLines: 2,
                  suggestions: PulmonarySuggestions.exposureHistory,
                ),
                const SizedBox(height: AppSpacing.md),
                SuggestionTextField(
                  controller: _allergyHistoryController,
                  label: 'Allergy/Atopy History',
                  hint: 'Allergies, eczema, rhinitis...',
                  prefixIcon: Icons.spa_outlined,
                  maxLines: 2,
                  suggestions: PulmonarySuggestions.allergyHistory,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _currentMedicationsController,
                  label: 'Current Medications',
                  hint: 'Current medications (comma-separated)...',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                ChipSelectorSection(
                  title: 'Comorbidities',
                  options: PulmonarySuggestions.comorbidities,
                  selected: _selectedComorbidities,
                  onChanged: (list) => setState(() => _selectedComorbidities = list),
                  accentColor: AppColors.info,
                  showClearButton: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vital Signs
          RecordFormSection(
            key: _sectionKeys['vitals'],
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: const Color(0xFF3B82F6),
            collapsible: true,
            initiallyExpanded: _expandedSections['vitals'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['vitals'] = expanded),
            child: Column(
              children: [
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _bpController,
                      label: 'BP',
                      hint: '120/80',
                      suffix: 'mmHg',
                    ),
                    CompactTextField(
                      controller: _pulseController,
                      label: 'Pulse',
                      hint: '72',
                      suffix: 'bpm',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _tempController,
                      label: 'Temp',
                      hint: '98.6',
                      suffix: '°F',
                    ),
                    CompactTextField(
                      controller: _respiratoryRateController,
                      label: 'RR',
                      hint: '16',
                      suffix: '/min',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _spo2Controller,
                      label: 'SpO₂',
                      hint: '98',
                      suffix: '%',
                    ),
                    CompactTextField(
                      controller: _peakFlowController,
                      label: 'PEFR',
                      hint: '350',
                      suffix: 'L/min',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CompactTextField(
                  controller: _weightController,
                  label: 'Weight',
                  hint: '70',
                  suffix: 'kg',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chest Auscultation
          RecordFormSection(
            key: _sectionKeys['auscultation'],
            title: 'Chest Auscultation',
            icon: Icons.hearing,
            accentColor: const Color(0xFF3B82F6),
            collapsible: true,
            initiallyExpanded: _expandedSections['auscultation'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['auscultation'] = expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SuggestionTextField(
                  controller: _breathSoundsController,
                  label: 'Breath Sounds',
                  hint: 'Type of breath sounds...',
                  prefixIcon: Icons.hearing,
                  suggestions: PulmonarySuggestions.breathSounds,
                ),
                const SizedBox(height: AppSpacing.md),
                ChipSelectorSection(
                  title: 'Added Sounds',
                  options: PulmonarySuggestions.addedSounds,
                  selected: _selectedAddedSounds,
                  onChanged: (list) => setState(() => _selectedAddedSounds = list),
                  accentColor: AppColors.accent,
                  showClearButton: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Zone-wise Findings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RecordFieldGrid(
                  children: [
                    SuggestionTextField(
                      controller: _rightUpperZoneController,
                      label: 'R. Upper',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                    SuggestionTextField(
                      controller: _leftUpperZoneController,
                      label: 'L. Upper',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                RecordFieldGrid(
                  children: [
                    SuggestionTextField(
                      controller: _rightMiddleZoneController,
                      label: 'R. Middle',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                    SuggestionTextField(
                      controller: _leftMiddleZoneController,
                      label: 'L. Middle',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                RecordFieldGrid(
                  children: [
                    SuggestionTextField(
                      controller: _rightLowerZoneController,
                      label: 'R. Lower',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                    SuggestionTextField(
                      controller: _leftLowerZoneController,
                      label: 'L. Lower',
                      hint: 'Findings...',
                      suggestions: PulmonarySuggestions.zoneFindings,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _additionalFindingsController,
                  label: 'Additional Findings',
                  hint: 'Additional auscultation findings...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Investigations
          RecordFormSection(
            key: _sectionKeys['investigations'],
            title: 'Investigations Required',
            icon: Icons.biotech,
            accentColor: Colors.cyan,
            collapsible: true,
            initiallyExpanded: _expandedSections['investigations'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['investigations'] = expanded),
            child: ChipSelectorSection(
              title: 'Select Investigations',
              options: PulmonarySuggestions.investigations,
              selected: _selectedInvestigations,
              onChanged: (list) => setState(() => _selectedInvestigations = list),
              accentColor: Colors.cyan,
              showClearButton: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Diagnosis
          RecordFormSection(
            key: _sectionKeys['diagnosis'],
            title: 'Diagnosis',
            icon: Icons.medical_information,
            accentColor: Colors.green,
            collapsible: true,
            initiallyExpanded: _expandedSections['diagnosis'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['diagnosis'] = expanded),
            child: SuggestionTextField(
              controller: _diagnosisController,
              label: 'Diagnosis',
              hint: 'Enter diagnosis...',
              prefixIcon: Icons.medical_information_outlined,
              maxLines: 3,
              suggestions: const [
                'Bronchial Asthma',
                'COPD',
                'Acute Bronchitis',
                'Pneumonia',
                'Pulmonary Tuberculosis',
                'Interstitial Lung Disease',
                'Bronchiectasis',
                'Pleural Effusion',
                'Allergic Rhinitis',
                'Upper Respiratory Tract Infection',
                'Lower Respiratory Tract Infection',
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Treatment Plan
          RecordFormSection(
            key: _sectionKeys['treatment'],
            title: 'Treatment & Follow-up',
            icon: Icons.healing,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['treatment'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['treatment'] = expanded),
            child: Column(
              children: [
                RecordNotesField(
                  controller: _treatmentController,
                  label: 'Treatment Plan',
                  hint: 'Enter treatment plan...',
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordNotesField(
                  controller: _followUpPlanController,
                  label: 'Follow-up Plan',
                  hint: 'Follow-up instructions and plan...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordNotesField(
                  controller: _clinicalNotesController,
                  label: 'Additional Notes',
                  hint: 'Additional clinical notes...',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          RecordSaveButton(
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Evaluation' : 'Save Evaluation',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

