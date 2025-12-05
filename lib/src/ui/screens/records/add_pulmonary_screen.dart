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
  final _titleController = TextEditingController();

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
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _titleController.text = record.title;
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
    _titleController.dispose();
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
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : 'Pulmonary Evaluation',
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
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'Pulmonary Evaluation',
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
                label: 'Asthma',
                icon: Icons.air_rounded,
                color: Colors.blue,
                onTap: () => _fillAsthmaTemplate(),
              ),
              _buildQuickFillChip(
                label: 'COPD',
                icon: Icons.smoke_free,
                color: Colors.orange,
                onTap: () => _fillCOPDTemplate(),
              ),
              _buildQuickFillChip(
                label: 'Pneumonia',
                icon: Icons.coronavirus_outlined,
                color: Colors.red,
                onTap: () => _fillPneumoniaTemplate(),
              ),
              _buildQuickFillChip(
                label: 'Bronchitis',
                icon: Icons.sick_outlined,
                color: Colors.teal,
                onTap: () => _fillBronchitisTemplate(),
              ),
              _buildQuickFillChip(
                label: 'TB',
                icon: Icons.medical_services_outlined,
                color: Colors.purple,
                onTap: () => _fillTBTemplate(),
              ),
              _buildQuickFillChip(
                label: 'URTI',
                icon: Icons.thermostat_outlined,
                color: Colors.green,
                onTap: () => _fillURTITemplate(),
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

  void _fillAsthmaTemplate() {
    _titleController.text = 'Bronchial Asthma Evaluation';
    _chiefComplaintController.text = 'Difficulty breathing, wheezing, chest tightness';
    _symptomCharacterController.text = 'Episodic, worse at night/early morning';
    setState(() {
      _selectedSystemicSymptoms = ['Cough', 'Shortness of breath'];
      _selectedAddedSounds = ['Wheeze', 'Rhonchi'];
    });
    _breathSoundsController.text = 'Bilateral wheeze';
    _diagnosisController.text = 'Bronchial Asthma';
    _treatmentController.text = 'Inhaled bronchodilators (SABA), Inhaled corticosteroids (ICS)';
    _showQuickFillSnackbar('Asthma template applied');
  }

  void _fillCOPDTemplate() {
    _titleController.text = 'COPD Evaluation';
    _chiefComplaintController.text = 'Progressive dyspnea, chronic cough with sputum';
    _symptomCharacterController.text = 'Chronic, progressive';
    _durationController.text = 'Several years';
    setState(() {
      _selectedSystemicSymptoms = ['Cough', 'Shortness of breath', 'Fatigue'];
      _selectedComorbidities = ['Smoking', 'Chronic Bronchitis'];
      _selectedAddedSounds = ['Rhonchi', 'Diminished breath sounds'];
    });
    _breathSoundsController.text = 'Diminished with prolonged expiration';
    _diagnosisController.text = 'COPD';
    _treatmentController.text = 'LABA/LAMA, ICS if frequent exacerbations, Pulmonary rehabilitation';
    _showQuickFillSnackbar('COPD template applied');
  }

  void _fillPneumoniaTemplate() {
    _titleController.text = 'Pneumonia Evaluation';
    _chiefComplaintController.text = 'Fever, productive cough, pleuritic chest pain';
    _symptomCharacterController.text = 'Acute onset';
    _durationController.text = '3-7 days';
    setState(() {
      _selectedSystemicSymptoms = ['Fever', 'Cough', 'Shortness of breath', 'Fatigue'];
      _selectedRedFlags = ['High fever', 'Hypoxia', 'Altered sensorium'];
      _selectedAddedSounds = ['Crepitations', 'Bronchial breath sounds'];
      _selectedInvestigations = ['Chest X-ray', 'CBC', 'Sputum culture'];
    });
    _breathSoundsController.text = 'Bronchial breath sounds over affected area';
    _diagnosisController.text = 'Community-acquired Pneumonia';
    _treatmentController.text = 'Antibiotics (Amoxicillin-Clavulanate or Respiratory fluoroquinolone), Supportive care';
    _showQuickFillSnackbar('Pneumonia template applied');
  }

  void _fillBronchitisTemplate() {
    _titleController.text = 'Acute Bronchitis Evaluation';
    _chiefComplaintController.text = 'Cough with or without sputum, chest discomfort';
    _symptomCharacterController.text = 'Acute onset, usually following viral URTI';
    _durationController.text = '1-2 weeks';
    setState(() {
      _selectedSystemicSymptoms = ['Cough', 'Mild fever'];
      _selectedAddedSounds = ['Rhonchi'];
    });
    _breathSoundsController.text = 'Scattered rhonchi, clear with coughing';
    _diagnosisController.text = 'Acute Bronchitis';
    _treatmentController.text = 'Symptomatic treatment, cough suppressants, hydration, rest';
    _showQuickFillSnackbar('Bronchitis template applied');
  }

  void _fillTBTemplate() {
    _titleController.text = 'Pulmonary TB Evaluation';
    _chiefComplaintController.text = 'Chronic cough >2 weeks, hemoptysis, weight loss, night sweats';
    _symptomCharacterController.text = 'Chronic, progressive';
    _durationController.text = '>3 weeks';
    setState(() {
      _selectedSystemicSymptoms = ['Fever', 'Weight loss', 'Night sweats', 'Fatigue'];
      _selectedRedFlags = ['Hemoptysis', 'Significant weight loss'];
      _selectedAddedSounds = ['Crepitations'];
      _selectedInvestigations = ['Chest X-ray', 'Sputum AFB', 'Gene Xpert', 'Mantoux test'];
    });
    _breathSoundsController.text = 'Crepitations over upper zones';
    _diagnosisController.text = 'Pulmonary Tuberculosis';
    _treatmentController.text = 'Anti-TB regimen (HRZE) as per DOTS protocol';
    _showQuickFillSnackbar('TB template applied');
  }

  void _fillURTITemplate() {
    _titleController.text = 'URTI Evaluation';
    _chiefComplaintController.text = 'Sore throat, nasal congestion, mild cough';
    _symptomCharacterController.text = 'Acute onset';
    _durationController.text = '2-5 days';
    setState(() {
      _selectedSystemicSymptoms = ['Mild fever', 'Cough'];
    });
    _breathSoundsController.text = 'Normal/Clear';
    _diagnosisController.text = 'Upper Respiratory Tract Infection';
    _treatmentController.text = 'Symptomatic treatment, rest, hydration, analgesics';
    _showQuickFillSnackbar('URTI template applied');
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

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Fill Templates
          _buildQuickFillSection(context, isDark),
          const SizedBox(height: AppSpacing.lg),

          // Patient Selection
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

          // Title
          RecordFormSection(
            title: 'Title',
            icon: Icons.title,
            child: RecordTextField(
              controller: _titleController,
              hint: 'Enter record title (optional)...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chief Complaint
          RecordFormSection(
            title: 'Presenting Complaint',
            icon: Icons.air,
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

          // Systemic Symptoms
          ChipSelectorSection(
            title: 'Systemic Symptoms',
            icon: Icons.thermostat_outlined,
            options: PulmonarySuggestions.systemicSymptoms,
            selectedOptions: _selectedSystemicSymptoms,
            onChanged: (list) => setState(() => _selectedSystemicSymptoms = list),
            chipColor: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Red Flags
          ChipSelectorSection(
            title: 'Red Flags',
            icon: Icons.warning_amber_rounded,
            options: PulmonarySuggestions.redFlags,
            selectedOptions: _selectedRedFlags,
            onChanged: (list) => setState(() => _selectedRedFlags = list),
            chipColor: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clinical History
          RecordFormSection(
            title: 'Clinical History',
            icon: Icons.history,
            accentColor: const Color(0xFF3B82F6),
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
                  hint: 'Current medications (comma-separated)...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Comorbidities
          ChipSelectorSection(
            title: 'Comorbidities',
            icon: Icons.medical_services_outlined,
            options: PulmonarySuggestions.comorbidities,
            selectedOptions: _selectedComorbidities,
            onChanged: (list) => setState(() => _selectedComorbidities = list),
            chipColor: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vital Signs
          RecordFormSection(
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: const Color(0xFF3B82F6),
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
            title: 'Chest Auscultation',
            icon: Icons.hearing,
            accentColor: const Color(0xFF3B82F6),
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
                Text(
                  'Added Sounds',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RecordFormWidgets.buildChipSelector(
                  context: context,
                  options: PulmonarySuggestions.addedSounds,
                  selectedOptions: _selectedAddedSounds,
                  onChanged: (list) => setState(() => _selectedAddedSounds = list),
                  color: AppColors.accent,
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
                  hint: 'Additional auscultation findings...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Investigations
          ChipSelectorSection(
            title: 'Investigations Required',
            icon: Icons.biotech,
            options: PulmonarySuggestions.investigations,
            selectedOptions: _selectedInvestigations,
            onChanged: (list) => setState(() => _selectedInvestigations = list),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Diagnosis
          RecordFormSection(
            title: 'Diagnosis',
            icon: Icons.medical_information,
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
            title: 'Treatment Plan',
            icon: Icons.healing,
            child: RecordNotesField(
              controller: _treatmentController,
              hint: 'Enter treatment plan...',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Follow-up Plan
          RecordFormSection(
            title: 'Follow-up Plan',
            icon: Icons.event_note,
            child: RecordNotesField(
              controller: _followUpPlanController,
              hint: 'Follow-up instructions and plan...',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clinical Notes
          RecordFormSection(
            title: 'Additional Notes',
            icon: Icons.note_alt,
            child: RecordNotesField(
              controller: _clinicalNotesController,
              hint: 'Additional clinical notes...',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          RecordSaveButton(
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Evaluation' : 'Save Evaluation',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // Info Cyan
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

