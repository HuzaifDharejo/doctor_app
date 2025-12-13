import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import 'record_form_widgets.dart';
import 'components/record_components.dart';

/// Screen for adding a Pediatric Checkup medical record
class AddPediatricCheckupScreen extends ConsumerStatefulWidget {
  const AddPediatricCheckupScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddPediatricCheckupScreen> createState() => _AddPediatricCheckupScreenState();
}

class _AddPediatricCheckupScreenState extends ConsumerState<AddPediatricCheckupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  static const int _totalSections = 7;
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'growth': GlobalKey(),
    'vitals': GlobalKey(),
    'development': GlobalKey(),
    'nutrition': GlobalKey(),
    'vaccinations': GlobalKey(),
    'examination': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'growth': true,
    'vitals': true,
    'development': true,
    'nutrition': true,
    'vaccinations': true,
    'examination': true,
    'assessment': true,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Growth Parameters
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headCircumferenceController = TextEditingController();
  final _bmiController = TextEditingController();
  final _weightPercentileController = TextEditingController();
  final _heightPercentileController = TextEditingController();

  // Vital Signs
  final _temperatureController = TextEditingController();
  final _pulseController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _bpController = TextEditingController();

  // Development
  List<String> _selectedMilestones = [];
  final _developmentNotesController = TextEditingController();
  String _developmentAssessment = 'Age appropriate';

  // Feeding/Nutrition
  final _feedingController = TextEditingController();
  final _dietController = TextEditingController();
  List<String> _selectedNutritionConcerns = [];

  // Vaccination
  List<String> _selectedVaccinations = [];
  final _vaccinationNotesController = TextEditingController();

  // Examination
  final _generalExamController = TextEditingController();
  final _systemicExamController = TextEditingController();
  List<String> _selectedFindings = [];

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _nextVisitController = TextEditingController();

  final List<String> _milestoneOptions = [
    'Social smile', 'Head control', 'Rolls over', 'Sits without support',
    'Crawls', 'Stands with support', 'Walks independently', 'Speaks first words',
    'Two-word sentences', 'Feeds self', 'Toilet trained', 'Dresses self',
  ];

  final List<String> _nutritionConcerns = [
    'Underweight', 'Overweight', 'Picky eating', 'Food allergies',
    'Anemia', 'Vitamin D deficiency', 'Poor appetite', 'Excessive appetite',
  ];

  final List<String> _vaccinationOptions = [
    'BCG', 'OPV', 'IPV', 'DPT', 'Hepatitis B', 'Hib', 'Rotavirus',
    'PCV', 'MMR', 'Varicella', 'Hepatitis A', 'Typhoid', 'Influenza',
    'HPV', 'Meningococcal', 'Japanese Encephalitis',
  ];

  final List<String> _findingOptions = [
    'Normal growth', 'Failure to thrive', 'Developmental delay',
    'Congenital anomaly', 'Heart murmur', 'Anemia', 'Rickets',
    'Skin rash', 'Enlarged lymph nodes', 'Dental caries',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Well Child Visit',
        icon: Icons.child_care_rounded,
        color: Colors.green,
        description: 'Routine well child checkup',
        data: {
          'development_assessment': 'Age appropriate',
          'general_exam': 'Active child, alert, well-nourished',
          'findings': ['Normal growth'],
          'diagnosis': 'Well child - routine checkup',
          'treatment': 'Continue current diet and care. Age-appropriate vaccinations given.',
        },
      ),
      QuickFillTemplateItem(
        label: 'URTI/Cold',
        icon: Icons.sick_rounded,
        color: Colors.orange,
        description: 'Upper respiratory tract infection',
        data: {
          'general_exam': 'Mild respiratory distress, rhinorrhea present',
          'diagnosis': 'Upper Respiratory Tract Infection',
          'treatment': 'Symptomatic treatment. Paracetamol for fever. Adequate hydration. Nasal saline drops.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Gastroenteritis',
        icon: Icons.coronavirus_rounded,
        color: Colors.amber,
        description: 'Acute gastroenteritis template',
        data: {
          'general_exam': 'Mild dehydration, abdomen soft, active bowel sounds',
          'diagnosis': 'Acute Gastroenteritis',
          'treatment': 'ORS therapy. Zinc supplementation. Continue breastfeeding. BRAT diet if applicable. Probiotics.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Fever Workup',
        icon: Icons.thermostat_rounded,
        color: Colors.red,
        description: 'Fever evaluation template',
        data: {
          'general_exam': 'Febrile child, no apparent focus',
          'diagnosis': 'Fever under evaluation',
          'treatment': 'Paracetamol PRN. Tepid sponging. Adequate hydration. Monitor for red flags. Follow-up if persistent.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Growth',
        icon: Icons.trending_up_rounded,
        color: Colors.blue,
        description: 'Normal growth and development',
        data: {
          'development_assessment': 'Age appropriate',
          'findings': ['Normal growth'],
          'general_exam': 'Active, alert, well-nourished child. No pallor, icterus, or lymphadenopathy.',
          'systemic_exam': 'CVS: S1S2 normal, no murmur. RS: Clear, bilateral equal air entry. Abdomen: Soft, non-tender.',
          'diagnosis': 'Normal growth and development for age',
          'treatment': 'Continue balanced diet. Age-appropriate stimulation. Follow-up as scheduled.',
        },
      ),
    ];
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatment ?? '';
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        final growth = data['growth'] as Map<String, dynamic>?;
        if (growth != null) {
          _weightController.text = (growth['weight'] as String?) ?? '';
          _heightController.text = (growth['height'] as String?) ?? '';
          _headCircumferenceController.text = (growth['head_circumference'] as String?) ?? '';
          _bmiController.text = (growth['bmi'] as String?) ?? '';
        }
        _selectedMilestones = List<String>.from((data['milestones'] as List?) ?? []);
        _developmentAssessment = (data['development_assessment'] as String?) ?? 'Age appropriate';
        _selectedVaccinations = List<String>.from((data['vaccinations'] as List?) ?? []);
        _selectedNutritionConcerns = List<String>.from((data['nutrition_concerns'] as List?) ?? []);
        _selectedFindings = List<String>.from((data['findings'] as List?) ?? []);
      } catch (_) {}
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_weightController.text.isNotEmpty || _heightController.text.isNotEmpty) completed++;
    if (_temperatureController.text.isNotEmpty || _pulseController.text.isNotEmpty) completed++;
    if (_selectedMilestones.isNotEmpty || _developmentNotesController.text.isNotEmpty) completed++;
    if (_feedingController.text.isNotEmpty || _dietController.text.isNotEmpty) completed++;
    if (_selectedVaccinations.isNotEmpty) completed++;
    if (_generalExamController.text.isNotEmpty || _selectedFindings.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      
      if (data['milestones'] != null) {
        _selectedMilestones = List<String>.from(data['milestones'] as List);
      }
      if (data['nutrition_concerns'] != null) {
        _selectedNutritionConcerns = List<String>.from(data['nutrition_concerns'] as List);
      }
      if (data['vaccinations'] != null) {
        _selectedVaccinations = List<String>.from(data['vaccinations'] as List);
      }
      if (data['findings'] != null) {
        _selectedFindings = List<String>.from(data['findings'] as List);
      }
      if (data['development_assessment'] != null) {
        _developmentAssessment = data['development_assessment'] as String;
      }
      if (data['general_exam'] != null) {
        _generalExamController.text = data['general_exam'] as String;
      }
      if (data['systemic_exam'] != null) {
        _systemicExamController.text = data['systemic_exam'] as String;
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
      key: 'growth',
      title: 'Growth',
      icon: Icons.straighten_rounded,
      isComplete: _weightController.text.isNotEmpty || _heightController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'vitals',
      title: 'Vitals',
      icon: Icons.monitor_heart_rounded,
      isComplete: _temperatureController.text.isNotEmpty || _pulseController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'development',
      title: 'Development',
      icon: Icons.psychology_rounded,
      isComplete: _selectedMilestones.isNotEmpty || _developmentNotesController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'nutrition',
      title: 'Nutrition',
      icon: Icons.restaurant_rounded,
      isComplete: _feedingController.text.isNotEmpty || _dietController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'vaccinations',
      title: 'Vaccines',
      icon: Icons.vaccines_rounded,
      isComplete: _selectedVaccinations.isNotEmpty,
    ),
    SectionInfo(
      key: 'examination',
      title: 'Exam',
      icon: Icons.medical_services_rounded,
      isComplete: _generalExamController.text.isNotEmpty || _selectedFindings.isNotEmpty,
    ),
    SectionInfo(
      key: 'assessment',
      title: 'Assessment',
      icon: Icons.assignment_rounded,
      isComplete: _diagnosisController.text.isNotEmpty,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headCircumferenceController.dispose();
    _bmiController.dispose();
    _weightPercentileController.dispose();
    _heightPercentileController.dispose();
    _temperatureController.dispose();
    _pulseController.dispose();
    _respiratoryRateController.dispose();
    _bpController.dispose();
    _developmentNotesController.dispose();
    _feedingController.dispose();
    _dietController.dispose();
    _vaccinationNotesController.dispose();
    _generalExamController.dispose();
    _systemicExamController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    _nextVisitController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'growth': {
        'weight': _weightController.text.isNotEmpty ? _weightController.text : null,
        'height': _heightController.text.isNotEmpty ? _heightController.text : null,
        'head_circumference': _headCircumferenceController.text.isNotEmpty ? _headCircumferenceController.text : null,
        'bmi': _bmiController.text.isNotEmpty ? _bmiController.text : null,
        'weight_percentile': _weightPercentileController.text.isNotEmpty ? _weightPercentileController.text : null,
        'height_percentile': _heightPercentileController.text.isNotEmpty ? _heightPercentileController.text : null,
      },
      'vitals': {
        'temperature': _temperatureController.text.isNotEmpty ? _temperatureController.text : null,
        'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null,
        'respiratory_rate': _respiratoryRateController.text.isNotEmpty ? _respiratoryRateController.text : null,
        'bp': _bpController.text.isNotEmpty ? _bpController.text : null,
      },
      'milestones': _selectedMilestones.isNotEmpty ? _selectedMilestones : null,
      'development_assessment': _developmentAssessment,
      'development_notes': _developmentNotesController.text.isNotEmpty ? _developmentNotesController.text : null,
      'feeding': _feedingController.text.isNotEmpty ? _feedingController.text : null,
      'diet': _dietController.text.isNotEmpty ? _dietController.text : null,
      'nutrition_concerns': _selectedNutritionConcerns.isNotEmpty ? _selectedNutritionConcerns : null,
      'vaccinations': _selectedVaccinations.isNotEmpty ? _selectedVaccinations : null,
      'vaccination_notes': _vaccinationNotesController.text.isNotEmpty ? _vaccinationNotesController.text : null,
      'general_exam': _generalExamController.text.isNotEmpty ? _generalExamController.text : null,
      'systemic_exam': _systemicExamController.text.isNotEmpty ? _systemicExamController.text : null,
      'findings': _selectedFindings.isNotEmpty ? _selectedFindings : null,
      'next_visit': _nextVisitController.text.isNotEmpty ? _nextVisitController.text : null,
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
        recordType: 'pediatric_checkup',
        title: 'Pediatric Checkup - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_diagnosisController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id, patientId: _selectedPatientId!,
          recordType: 'pediatric_checkup',
          title: 'Pediatric Checkup - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _diagnosisController.text, dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _diagnosisController.text, treatment: _treatmentController.text,
          doctorNotes: _clinicalNotesController.text, recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }
      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(context, 'Pediatric checkup saved!');
        Navigator.pop(context, resultRecord);
      }
    } catch (e) {
      if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(
      title: widget.existingRecord != null ? 'Edit Pediatric Checkup' : 'Pediatric Checkup',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.child_care_rounded,
      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      scrollController: _scrollController,
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.preselectedPatient == null) ...[
            PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)),
            const SizedBox(height: AppSpacing.lg),
          ],
          DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)),
          const SizedBox(height: AppSpacing.lg),
          FormProgressIndicator(
            completedSections: _calculateCompletedSections(),
            totalSections: _totalSections,
            accentColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: const Color(0xFFF59E0B),
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

          RecordFormSection(
            key: _sectionKeys['growth'],
            title: 'Growth Parameters',
            icon: Icons.straighten_rounded,
            accentColor: Colors.green,
            collapsible: true,
            initiallyExpanded: _expandedSections['growth'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['growth'] = expanded),
            child: Column(children: [
              Row(children: [
                Expanded(child: RecordTextField(controller: _weightController, label: 'Weight', hint: 'kg', keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RecordTextField(controller: _heightController, label: 'Height', hint: 'cm', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: RecordTextField(controller: _headCircumferenceController, label: 'Head Circ', hint: 'cm', keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RecordTextField(controller: _bmiController, label: 'BMI', hint: 'kg/m²', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: RecordTextField(controller: _weightPercentileController, label: 'Weight %ile', hint: 'Percentile')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RecordTextField(controller: _heightPercentileController, label: 'Height %ile', hint: 'Percentile')),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['vitals'],
            title: 'Vital Signs',
            icon: Icons.monitor_heart_rounded,
            accentColor: Colors.red,
            collapsible: true,
            initiallyExpanded: _expandedSections['vitals'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['vitals'] = expanded),
            child: Column(children: [
              Row(children: [
                Expanded(child: RecordTextField(controller: _temperatureController, label: 'Temp', hint: '°F', keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RecordTextField(controller: _pulseController, label: 'Pulse', hint: 'bpm', keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: RecordTextField(controller: _respiratoryRateController, label: 'RR', hint: '/min', keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: RecordTextField(controller: _bpController, label: 'BP', hint: 'mmHg')),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['development'],
            title: 'Development',
            icon: Icons.psychology_rounded,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['development'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['development'] = expanded),
            child: Column(children: [
              ChipSelectorSection(
                title: 'Milestones Achieved',
                options: _milestoneOptions,
                selected: _selectedMilestones,
                onChanged: (l) => setState(() => _selectedMilestones = l),
                accentColor: Colors.purple,
                showClearButton: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDropdown('Assessment', _developmentAssessment, ['Age appropriate', 'Mild delay', 'Moderate delay', 'Severe delay'], (v) => setState(() => _developmentAssessment = v!), isDark),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _developmentNotesController, label: 'Notes', hint: 'Development concerns', maxLines: 2),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['nutrition'],
            title: 'Nutrition',
            icon: Icons.restaurant_rounded,
            accentColor: Colors.orange,
            collapsible: true,
            initiallyExpanded: _expandedSections['nutrition'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['nutrition'] = expanded),
            child: Column(children: [
              RecordTextField(controller: _feedingController, label: 'Feeding', hint: 'Breastfeeding, formula, etc'),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _dietController, label: 'Diet', hint: 'Current diet'),
              const SizedBox(height: AppSpacing.md),
              ChipSelectorSection(
                title: 'Concerns',
                options: _nutritionConcerns,
                selected: _selectedNutritionConcerns,
                onChanged: (l) => setState(() => _selectedNutritionConcerns = l),
                accentColor: Colors.orange,
                showClearButton: true,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['vaccinations'],
            title: 'Vaccinations',
            icon: Icons.vaccines_rounded,
            accentColor: Colors.blue,
            collapsible: true,
            initiallyExpanded: _expandedSections['vaccinations'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['vaccinations'] = expanded),
            child: Column(children: [
              ChipSelectorSection(
                title: 'Given Today',
                options: _vaccinationOptions,
                selected: _selectedVaccinations,
                onChanged: (l) => setState(() => _selectedVaccinations = l),
                accentColor: Colors.blue,
                showClearButton: true,
              ),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _vaccinationNotesController, label: 'Notes', hint: 'Batch numbers, reactions'),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['examination'],
            title: 'Examination',
            icon: Icons.medical_services_rounded,
            accentColor: Colors.teal,
            collapsible: true,
            initiallyExpanded: _expandedSections['examination'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['examination'] = expanded),
            child: Column(children: [
              RecordTextField(controller: _generalExamController, label: 'General', hint: 'Activity, appearance', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _systemicExamController, label: 'Systemic', hint: 'CVS, RS, Abdomen, CNS', maxLines: 3),
              const SizedBox(height: AppSpacing.md),
              ChipSelectorSection(
                title: 'Findings',
                options: _findingOptions,
                selected: _selectedFindings,
                onChanged: (l) => setState(() => _selectedFindings = l),
                accentColor: Colors.teal,
                showClearButton: true,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          RecordFormSection(
            key: _sectionKeys['assessment'],
            title: 'Assessment & Plan',
            icon: Icons.assignment_rounded,
            accentColor: Colors.green,
            collapsible: true,
            initiallyExpanded: _expandedSections['assessment'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['assessment'] = expanded),
            child: Column(children: [
              RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'Assessment', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Medications, advice', maxLines: 3),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional', maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              RecordTextField(controller: _nextVisitController, label: 'Next Visit', hint: 'Schedule'),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        )),
      ),
    ]);
  }
}
