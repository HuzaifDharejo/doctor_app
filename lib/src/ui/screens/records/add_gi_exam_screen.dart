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

/// Screen for adding a Gastrointestinal Examination medical record
class AddGIExamScreen extends ConsumerStatefulWidget {
  const AddGIExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddGIExamScreen> createState() => _AddGIExamScreenState();
}

class _AddGIExamScreenState extends ConsumerState<AddGIExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 9;
  DateTime _recordDate = DateTime.now();

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'history': GlobalKey(),
    'general': GlobalKey(),
    'inspection': GlobalKey(),
    'auscultation': GlobalKey(),
    'percussion': GlobalKey(),
    'palpation': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'history': true,
    'general': true,
    'inspection': true,
    'auscultation': true,
    'percussion': true,
    'palpation': true,
    'investigations': true,
    'assessment': true,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  final _chiefComplaintController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // History
  final _durationController = TextEditingController();
  final _appetiteController = TextEditingController();
  final _bowelHabitController = TextEditingController();
  final _nauseaVomitingController = TextEditingController();
  final _weightChangeController = TextEditingController();
  bool _dysphagia = false;
  bool _heartburn = false;
  bool _hematemesis = false;
  bool _melena = false;
  bool _jaundice = false;

  // General Inspection
  final _generalAppearanceController = TextEditingController();
  final _nutritionController = TextEditingController();
  bool _pallor = false;
  bool _icterus = false;
  bool _clubbing = false;
  bool _lymphadenopathy = false;

  // Abdominal Inspection
  final _shapeController = TextEditingController();
  final _movementController = TextEditingController();
  final _visiblePulsationsController = TextEditingController();
  final _visibleMassesController = TextEditingController();
  final _scarsController = TextEditingController();
  final _dilatedVeinsController = TextEditingController();

  // Auscultation
  final _bowelSoundsController = TextEditingController();
  final _bruitsController = TextEditingController();
  final _venousHumController = TextEditingController();

  // Percussion
  final _liverSpanController = TextEditingController();
  final _spleenPercussionController = TextEditingController();
  final _shiftingDullnessController = TextEditingController();
  final _fluidThrillController = TextEditingController();

  // Palpation
  final _tendernessController = TextEditingController();
  final _guardingController = TextEditingController();
  final _rigidityController = TextEditingController();
  final _reboundController = TextEditingController();
  final _liverPalpationController = TextEditingController();
  final _spleenPalpationController = TextEditingController();
  final _kidneyPalpationController = TextEditingController();
  final _massesController = TextEditingController();

  // Special Signs
  List<String> _selectedSigns = [];

  // Rectal Exam
  bool _rectalExamDone = false;
  final _rectalFindingsController = TextEditingController();

  // Hernial Orifices
  final _hernialOrificesController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Abdominal pain', 'Nausea', 'Vomiting', 'Diarrhea', 'Constipation', 'Bloating', 'Heartburn', 'Dysphagia', 'Hematemesis', 'Melena', 'Rectal bleeding', 'Weight loss', 'Jaundice', 'Anorexia'];
  final List<String> _signOptions = ['Murphy\'s sign', 'McBurney\'s point', 'Rovsing\'s sign', 'Psoas sign', 'Obturator sign', 'Cullen\'s sign', 'Grey-Turner sign', 'Courvoisier sign', 'Sister Mary Joseph nodule', 'Ascites'];
  final List<String> _investigationOptions = ['CBC', 'LFT', 'RFT', 'Amylase/Lipase', 'Stool exam', 'FOBT', 'USG Abdomen', 'CT Abdomen', 'Upper GI Endoscopy', 'Colonoscopy', 'MRCP', 'H. pylori test', 'Hepatitis panel'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'GERD',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        description: 'Gastroesophageal reflux disease',
        data: {
          'symptoms': ['Heartburn', 'Dysphagia'],
          'heartburn': true,
          'diagnosis': 'Gastroesophageal Reflux Disease',
          'treatment': 'PPI therapy. Lifestyle modifications. Avoid trigger foods.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Appendicitis',
        icon: Icons.warning,
        color: Colors.red,
        description: 'Acute appendicitis',
        data: {
          'symptoms': ['Abdominal pain', 'Nausea', 'Vomiting'],
          'signs': ['McBurney\'s point', 'Rovsing\'s sign'],
          'investigations': ['CBC', 'USG Abdomen'],
          'diagnosis': 'Acute Appendicitis',
          'treatment': 'Surgical consult. NPO. IV fluids. Antibiotics.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Gastritis',
        icon: Icons.sick,
        color: Colors.amber,
        description: 'Acute gastritis/PUD',
        data: {
          'symptoms': ['Abdominal pain', 'Nausea', 'Bloating'],
          'tenderness': 'Epigastric tenderness',
          'investigations': ['Upper GI Endoscopy', 'H. pylori test'],
          'diagnosis': 'Acute Gastritis',
          'treatment': 'PPI. Antacids. H. pylori eradication if positive.',
        },
      ),
      QuickFillTemplateItem(
        label: 'IBS',
        icon: Icons.sync_alt,
        color: Colors.purple,
        description: 'Irritable bowel syndrome',
        data: {
          'symptoms': ['Abdominal pain', 'Bloating', 'Diarrhea', 'Constipation'],
          'bowel_habit': 'Alternating diarrhea/constipation',
          'shape': 'Mildly distended',
          'diagnosis': 'Irritable Bowel Syndrome (IBS)',
          'treatment': 'Dietary modifications (low FODMAP). Fiber supplementation. Antispasmodics. Probiotics.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Liver Disease',
        icon: Icons.healing,
        color: Colors.brown,
        description: 'Chronic liver disease',
        data: {
          'symptoms': ['Jaundice', 'Abdominal pain', 'Weight loss'],
          'jaundice': true,
          'icterus': true,
          'liver_palpation': 'Enlarged, firm',
          'investigations': ['LFT', 'USG Abdomen', 'Hepatitis panel'],
          'diagnosis': 'Chronic Liver Disease / Hepatitis',
          'treatment': 'Treat underlying cause. Hepatoprotective agents. Avoid hepatotoxic drugs/alcohol.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Exam',
        icon: Icons.check_circle,
        color: Colors.green,
        description: 'Normal GI examination',
        data: {
          'general_appearance': 'Well-nourished, comfortable',
          'shape': 'Flat, symmetric',
          'bowel_sounds': 'Normal, present in all quadrants',
          'tenderness': 'No tenderness',
          'liver_palpation': 'Not palpable',
          'spleen_palpation': 'Not palpable',
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
        _chiefComplaintController.text = (data['chief_complaint'] as String?) ?? '';
        _selectedSymptoms = List<String>.from((data['symptoms'] as List?) ?? []);
        _selectedSigns = List<String>.from((data['signs'] as List?) ?? []);
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      } catch (_) {}
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_appetiteController.text.isNotEmpty || _bowelHabitController.text.isNotEmpty) completed++;
    if (_generalAppearanceController.text.isNotEmpty) completed++;
    if (_shapeController.text.isNotEmpty || _movementController.text.isNotEmpty) completed++;
    if (_bowelSoundsController.text.isNotEmpty) completed++;
    if (_liverSpanController.text.isNotEmpty || _shiftingDullnessController.text.isNotEmpty) completed++;
    if (_tendernessController.text.isNotEmpty || _liverPalpationController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      
      if (data['symptoms'] != null) {
        _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      }
      if (data['signs'] != null) {
        _selectedSigns = List<String>.from(data['signs'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
      if (data['heartburn'] == true) _heartburn = true;
      if (data['jaundice'] == true) _jaundice = true;
      if (data['icterus'] == true) _icterus = true;
      if (data['general_appearance'] != null) _generalAppearanceController.text = data['general_appearance'] as String;
      if (data['shape'] != null) _shapeController.text = data['shape'] as String;
      if (data['bowel_habit'] != null) _bowelHabitController.text = data['bowel_habit'] as String;
      if (data['bowel_sounds'] != null) _bowelSoundsController.text = data['bowel_sounds'] as String;
      if (data['tenderness'] != null) _tendernessController.text = data['tenderness'] as String;
      if (data['liver_palpation'] != null) _liverPalpationController.text = data['liver_palpation'] as String;
      if (data['spleen_palpation'] != null) _spleenPalpationController.text = data['spleen_palpation'] as String;
      if (data['diagnosis'] != null) _diagnosisController.text = data['diagnosis'] as String;
      if (data['treatment'] != null) _treatmentController.text = data['treatment'] as String;
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
      icon: Icons.report_problem_rounded,
      isComplete: _chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty,
    ),
    SectionInfo(
      key: 'history',
      title: 'History',
      icon: Icons.history_rounded,
      isComplete: _appetiteController.text.isNotEmpty || _bowelHabitController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'general',
      title: 'General',
      icon: Icons.person_search_rounded,
      isComplete: _generalAppearanceController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'inspection',
      title: 'Inspection',
      icon: Icons.visibility_rounded,
      isComplete: _shapeController.text.isNotEmpty || _movementController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'auscultation',
      title: 'Auscultation',
      icon: Icons.hearing_rounded,
      isComplete: _bowelSoundsController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'percussion',
      title: 'Percussion',
      icon: Icons.touch_app_rounded,
      isComplete: _liverSpanController.text.isNotEmpty || _shiftingDullnessController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'palpation',
      title: 'Palpation',
      icon: Icons.pan_tool_rounded,
      isComplete: _tendernessController.text.isNotEmpty || _liverPalpationController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'investigations',
      title: 'Investigations',
      icon: Icons.biotech_rounded,
      isComplete: _selectedInvestigations.isNotEmpty,
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
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _appetiteController.dispose();
    _bowelHabitController.dispose();
    _nauseaVomitingController.dispose();
    _weightChangeController.dispose();
    _generalAppearanceController.dispose();
    _nutritionController.dispose();
    _shapeController.dispose();
    _movementController.dispose();
    _visiblePulsationsController.dispose();
    _visibleMassesController.dispose();
    _scarsController.dispose();
    _dilatedVeinsController.dispose();
    _bowelSoundsController.dispose();
    _bruitsController.dispose();
    _venousHumController.dispose();
    _liverSpanController.dispose();
    _spleenPercussionController.dispose();
    _shiftingDullnessController.dispose();
    _fluidThrillController.dispose();
    _tendernessController.dispose();
    _guardingController.dispose();
    _rigidityController.dispose();
    _reboundController.dispose();
    _liverPalpationController.dispose();
    _spleenPalpationController.dispose();
    _kidneyPalpationController.dispose();
    _massesController.dispose();
    _rectalFindingsController.dispose();
    _hernialOrificesController.dispose();
    _investigationResultsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      'history': {'duration': _durationController.text.isNotEmpty ? _durationController.text : null, 'appetite': _appetiteController.text.isNotEmpty ? _appetiteController.text : null, 'bowel_habit': _bowelHabitController.text.isNotEmpty ? _bowelHabitController.text : null, 'nausea_vomiting': _nauseaVomitingController.text.isNotEmpty ? _nauseaVomitingController.text : null, 'weight_change': _weightChangeController.text.isNotEmpty ? _weightChangeController.text : null, 'dysphagia': _dysphagia, 'heartburn': _heartburn, 'hematemesis': _hematemesis, 'melena': _melena, 'jaundice': _jaundice},
      'general': {'appearance': _generalAppearanceController.text.isNotEmpty ? _generalAppearanceController.text : null, 'nutrition': _nutritionController.text.isNotEmpty ? _nutritionController.text : null, 'pallor': _pallor, 'icterus': _icterus, 'clubbing': _clubbing, 'lymphadenopathy': _lymphadenopathy},
      'inspection': {'shape': _shapeController.text.isNotEmpty ? _shapeController.text : null, 'movement': _movementController.text.isNotEmpty ? _movementController.text : null, 'pulsations': _visiblePulsationsController.text.isNotEmpty ? _visiblePulsationsController.text : null, 'masses': _visibleMassesController.text.isNotEmpty ? _visibleMassesController.text : null, 'scars': _scarsController.text.isNotEmpty ? _scarsController.text : null, 'dilated_veins': _dilatedVeinsController.text.isNotEmpty ? _dilatedVeinsController.text : null},
      'auscultation': {'bowel_sounds': _bowelSoundsController.text.isNotEmpty ? _bowelSoundsController.text : null, 'bruits': _bruitsController.text.isNotEmpty ? _bruitsController.text : null, 'venous_hum': _venousHumController.text.isNotEmpty ? _venousHumController.text : null},
      'percussion': {'liver_span': _liverSpanController.text.isNotEmpty ? _liverSpanController.text : null, 'spleen': _spleenPercussionController.text.isNotEmpty ? _spleenPercussionController.text : null, 'shifting_dullness': _shiftingDullnessController.text.isNotEmpty ? _shiftingDullnessController.text : null, 'fluid_thrill': _fluidThrillController.text.isNotEmpty ? _fluidThrillController.text : null},
      'palpation': {'tenderness': _tendernessController.text.isNotEmpty ? _tendernessController.text : null, 'guarding': _guardingController.text.isNotEmpty ? _guardingController.text : null, 'rigidity': _rigidityController.text.isNotEmpty ? _rigidityController.text : null, 'rebound': _reboundController.text.isNotEmpty ? _reboundController.text : null, 'liver': _liverPalpationController.text.isNotEmpty ? _liverPalpationController.text : null, 'spleen': _spleenPalpationController.text.isNotEmpty ? _spleenPalpationController.text : null, 'kidney': _kidneyPalpationController.text.isNotEmpty ? _kidneyPalpationController.text : null, 'masses': _massesController.text.isNotEmpty ? _massesController.text : null},
      'signs': _selectedSigns.isNotEmpty ? _selectedSigns : null,
      'rectal_exam': {'done': _rectalExamDone, 'findings': _rectalFindingsController.text.isNotEmpty ? _rectalFindingsController.text : null},
      'hernial_orifices': _hernialOrificesController.text.isNotEmpty ? _hernialOrificesController.text : null,
      'investigations': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
      'investigation_results': _investigationResultsController.text.isNotEmpty ? _investigationResultsController.text : null,
    };
  }

  Future<void> _saveRecord(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) { RecordFormWidgets.showErrorSnackbar(context, 'Please select a patient'); return; }
    setState(() => _isSaving = true);
    try {
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!, recordType: 'gi_examination',
        title: _diagnosisController.text.isNotEmpty ? 'GI: ${_diagnosisController.text}' : 'GI Examination - ${DateFormat('MMM d').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'gi_examination',
          title: _diagnosisController.text.isNotEmpty ? 'GI: ${_diagnosisController.text}' : 'GI Examination - ${DateFormat('MMM d').format(_recordDate)}',
          description: _chiefComplaintController.text, dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _diagnosisController.text, treatment: _treatmentController.text, doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate, createdAt: widget.existingRecord!.createdAt);
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'GI examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(title: widget.existingRecord != null ? 'Edit GI Exam' : 'GI Examination', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.restaurant_rounded, gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)], scrollController: _scrollController,
      body: dbAsync.when(data: (db) => _buildFormContent(context, db, isDark), loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), error: (err, stack) => Center(child: Text('Error: $err'))));
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)), const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFF14B8A6)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFF14B8A6),
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
        key: _sectionKeys['complaint'],
        title: 'Chief Complaint', 
        icon: Icons.report_problem_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['complaint'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'Reason for evaluation', maxLines: 2),
          const SizedBox(height: AppSpacing.md), 
          ChipSelectorSection(
            title: 'Symptoms',
            options: _symptomOptions,
            selected: _selectedSymptoms,
            onChanged: (l) => setState(() => _selectedSymptoms = l),
            accentColor: Colors.teal,
            showClearButton: true,
          ),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['history'],
        title: 'History', 
        icon: Icons.history_rounded, 
        accentColor: Colors.blue,
        collapsible: true,
        initiallyExpanded: _expandedSections['history'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['history'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _durationController, label: 'Duration', hint: 'Days/weeks')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _appetiteController, label: 'Appetite', hint: 'Normal/reduced'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _bowelHabitController, label: 'Bowel Habit', hint: 'Regular')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _nauseaVomitingController, label: 'Nausea/Vomiting', hint: 'Present/absent'))]),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _weightChangeController, label: 'Weight Change', hint: 'Gained/lost kg'),
          const SizedBox(height: AppSpacing.md), Wrap(spacing: 16, runSpacing: 8, children: [_buildSwitch('Dysphagia', _dysphagia, (v) => setState(() => _dysphagia = v)), _buildSwitch('Heartburn', _heartburn, (v) => setState(() => _heartburn = v)), _buildSwitch('Hematemesis', _hematemesis, (v) => setState(() => _hematemesis = v)), _buildSwitch('Melena', _melena, (v) => setState(() => _melena = v)), _buildSwitch('Jaundice', _jaundice, (v) => setState(() => _jaundice = v))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['general'],
        title: 'General Examination', 
        icon: Icons.person_search_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['general'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['general'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _generalAppearanceController, label: 'Appearance', hint: 'Well/ill-looking')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _nutritionController, label: 'Nutrition', hint: 'Well-nourished'))]),
          const SizedBox(height: AppSpacing.md), Wrap(spacing: 16, runSpacing: 8, children: [_buildSwitch('Pallor', _pallor, (v) => setState(() => _pallor = v)), _buildSwitch('Icterus', _icterus, (v) => setState(() => _icterus = v)), _buildSwitch('Clubbing', _clubbing, (v) => setState(() => _clubbing = v)), _buildSwitch('Lymphadenopathy', _lymphadenopathy, (v) => setState(() => _lymphadenopathy = v))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['inspection'],
        title: 'Abdominal Inspection', 
        icon: Icons.visibility_rounded, 
        accentColor: Colors.orange,
        collapsible: true,
        initiallyExpanded: _expandedSections['inspection'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['inspection'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _shapeController, label: 'Shape', hint: 'Flat/distended')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _movementController, label: 'Movement', hint: 'With respiration'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _visiblePulsationsController, label: 'Pulsations', hint: 'Present/absent')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _visibleMassesController, label: 'Visible Masses', hint: 'None'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _scarsController, label: 'Scars', hint: 'Previous surgery')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _dilatedVeinsController, label: 'Dilated Veins', hint: 'Caput medusae'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['auscultation'],
        title: 'Auscultation', 
        icon: Icons.hearing_rounded, 
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['auscultation'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['auscultation'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _bowelSoundsController, label: 'Bowel Sounds', hint: 'Normal/hyperactive/absent'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _bruitsController, label: 'Bruits', hint: 'Absent')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _venousHumController, label: 'Venous Hum', hint: 'Absent'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['percussion'],
        title: 'Percussion', 
        icon: Icons.touch_app_rounded, 
        accentColor: Colors.amber,
        collapsible: true,
        initiallyExpanded: _expandedSections['percussion'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['percussion'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _liverSpanController, label: 'Liver Span', hint: '10-12 cm')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _spleenPercussionController, label: 'Spleen', hint: 'Not enlarged'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _shiftingDullnessController, label: 'Shifting Dullness', hint: 'Absent')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _fluidThrillController, label: 'Fluid Thrill', hint: 'Absent'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['palpation'],
        title: 'Palpation', 
        icon: Icons.pan_tool_rounded, 
        accentColor: Colors.red,
        collapsible: true,
        initiallyExpanded: _expandedSections['palpation'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['palpation'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _tendernessController, label: 'Tenderness', hint: 'Location')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _guardingController, label: 'Guarding', hint: 'Present/absent'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _rigidityController, label: 'Rigidity', hint: 'Present/absent')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _reboundController, label: 'Rebound', hint: 'Present/absent'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _liverPalpationController, label: 'Liver', hint: 'Not palpable')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _spleenPalpationController, label: 'Spleen', hint: 'Not palpable'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _kidneyPalpationController, label: 'Kidneys', hint: 'Not ballotable')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _massesController, label: 'Masses', hint: 'None'))]),
          const SizedBox(height: AppSpacing.lg),
          ChipSelectorSection(
            title: 'Special Signs',
            options: _signOptions,
            selected: _selectedSigns,
            onChanged: (l) => setState(() => _selectedSigns = l),
            accentColor: Colors.pink,
            showClearButton: true,
          ),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        title: 'Rectal & Hernial Exam', 
        icon: Icons.medical_services_rounded, 
        accentColor: Colors.brown,
        collapsible: true,
        child: Column(children: [
          SwitchListTile(title: const Text('Rectal Exam Done'), value: _rectalExamDone, onChanged: (v) => setState(() => _rectalExamDone = v), contentPadding: EdgeInsets.zero),
          if (_rectalExamDone) RecordTextField(controller: _rectalFindingsController, label: 'Rectal Findings', hint: 'Findings', maxLines: 2),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _hernialOrificesController, label: 'Hernial Orifices', hint: 'Intact/hernia present'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['investigations'],
        title: 'Investigations', 
        icon: Icons.biotech_rounded, 
        accentColor: Colors.cyan,
        collapsible: true,
        initiallyExpanded: _expandedSections['investigations'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['investigations'] = expanded),
        child: Column(children: [
          ChipSelectorSection(
            title: 'Tests',
            options: _investigationOptions,
            selected: _selectedInvestigations,
            onChanged: (l) => setState(() => _selectedInvestigations = l),
            accentColor: Colors.cyan,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _investigationResultsController, label: 'Results', hint: 'Test findings', maxLines: 3),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., GERD, PUD, IBD', maxLines: 2),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Medications, diet', maxLines: 3),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional notes', maxLines: 2),
        ]),
      ), 
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'), 
      const SizedBox(height: AppSpacing.xl),
    ]));
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 13)), Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)]);
  }
}
