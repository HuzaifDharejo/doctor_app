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

/// Screen for adding a Neurological Examination medical record
class AddNeuroExamScreen extends ConsumerStatefulWidget {
  const AddNeuroExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddNeuroExamScreen> createState() => _AddNeuroExamScreenState();
}

class _AddNeuroExamScreenState extends ConsumerState<AddNeuroExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 9;
  DateTime _recordDate = DateTime.now();

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'mental_status': GlobalKey(),
    'cranial_nerves': GlobalKey(),
    'motor': GlobalKey(),
    'sensory': GlobalKey(),
    'reflexes': GlobalKey(),
    'coordination': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'mental_status': true,
    'cranial_nerves': true,
    'motor': true,
    'sensory': true,
    'reflexes': true,
    'coordination': true,
    'investigations': true,
    'assessment': true,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  final _chiefComplaintController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Mental Status
  String _consciousness = 'Alert';
  final _gcsController = TextEditingController();
  final _orientationController = TextEditingController();
  final _speechController = TextEditingController();
  final _memoryController = TextEditingController();
  final _attentionController = TextEditingController();

  // Cranial Nerves
  final _cnIController = TextEditingController();
  final _cnIIController = TextEditingController();
  final _cnIIIIVVIController = TextEditingController();
  final _cnVController = TextEditingController();
  final _cnVIIController = TextEditingController();
  final _cnVIIIController = TextEditingController();
  final _cnIXXController = TextEditingController();
  final _cnXIController = TextEditingController();
  final _cnXIIController = TextEditingController();

  // Motor Exam
  final _toneController = TextEditingController();
  final _powerURController = TextEditingController();
  final _powerULController = TextEditingController();
  final _powerLRController = TextEditingController();
  final _powerLLController = TextEditingController();
  final _bulkController = TextEditingController();
  final _involuntaryController = TextEditingController();

  // Sensory Exam
  final _lightTouchController = TextEditingController();
  final _pinPrickController = TextEditingController();
  final _vibrationController = TextEditingController();
  final _proprioceptionController = TextEditingController();

  // Reflexes
  final _bicepsRController = TextEditingController();
  final _bicepsLController = TextEditingController();
  final _tricepsRController = TextEditingController();
  final _tricepsLController = TextEditingController();
  final _kneeRController = TextEditingController();
  final _kneeLController = TextEditingController();
  final _ankleRController = TextEditingController();
  final _ankleLController = TextEditingController();
  final _plantarRController = TextEditingController();
  final _plantarLController = TextEditingController();

  // Coordination & Gait
  final _fingerNoseController = TextEditingController();
  final _heelShinController = TextEditingController();
  final _dysdiadochokinesiaController = TextEditingController();
  final _rombergController = TextEditingController();
  final _gaitController = TextEditingController();
  final _tandemGaitController = TextEditingController();

  // Signs
  List<String> _selectedSigns = [];

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Headache', 'Weakness', 'Numbness', 'Tingling', 'Dizziness', 'Vision changes', 'Speech difficulty', 'Memory problems', 'Tremor', 'Seizures', 'Balance problems', 'Difficulty walking'];
  final List<String> _signOptions = ['Babinski', 'Hoffman', 'Clonus', 'Neck stiffness', 'Kernig', 'Brudzinski', 'Lhermitte', 'Pronator drift', 'Nystagmus', 'Papilledema'];
  final List<String> _investigationOptions = ['CT Head', 'MRI Brain', 'MRI Spine', 'EEG', 'EMG/NCV', 'LP/CSF', 'Carotid Doppler', 'MRA', 'PET scan', 'Blood tests'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Stroke',
        icon: Icons.emergency,
        color: Colors.red,
        description: 'Acute stroke assessment',
        data: {
          'symptoms': ['Weakness', 'Speech difficulty'],
          'consciousness': 'Alert',
          'signs': ['Babinski', 'Pronator drift'],
          'investigations': ['CT Head', 'MRI Brain'],
          'diagnosis': 'Acute Ischemic Stroke',
          'treatment': 'Thrombolysis evaluation. Antiplatelet therapy. BP management.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Migraine',
        icon: Icons.psychology,
        color: Colors.purple,
        description: 'Migraine headache',
        data: {
          'symptoms': ['Headache', 'Vision changes'],
          'gcs': '15',
          'cn_ii': 'Visual aura reported, fields intact',
          'diagnosis': 'Migraine with aura',
          'treatment': 'Triptans. NSAIDs. Prophylaxis if frequent.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Seizure',
        icon: Icons.flash_on,
        color: Colors.orange,
        description: 'Seizure disorder',
        data: {
          'symptoms': ['Seizures'],
          'investigations': ['EEG', 'MRI Brain'],
          'diagnosis': 'Seizure Disorder',
          'treatment': 'Antiepileptic medication. Seizure precautions.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Parkinson\'s',
        icon: Icons.elderly,
        color: Colors.brown,
        description: 'Parkinson\'s disease',
        data: {
          'symptoms': ['Tremor', 'Difficulty walking'],
          'tone': 'Rigidity - cogwheel type',
          'gait': 'Shuffling gait, reduced arm swing',
          'investigations': ['MRI Brain'],
          'diagnosis': 'Parkinson\'s Disease',
          'treatment': 'Levodopa/Carbidopa. Dopamine agonists. Physiotherapy.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Neuropathy',
        icon: Icons.sensors,
        color: Colors.cyan,
        description: 'Peripheral neuropathy',
        data: {
          'symptoms': ['Numbness', 'Tingling', 'Weakness'],
          'light_touch': 'Reduced distally in glove-stocking pattern',
          'vibration': 'Reduced at ankles',
          'investigations': ['EMG/NCV', 'Blood tests'],
          'diagnosis': 'Peripheral Neuropathy',
          'treatment': 'Treat underlying cause. Gabapentin/Pregabalin. B12 supplementation.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Exam',
        icon: Icons.check_circle,
        color: Colors.green,
        description: 'Normal neurological exam',
        data: {
          'consciousness': 'Alert',
          'gcs': '15/15',
          'orientation': 'Oriented to time, place, person',
          'tone': 'Normal',
          'power_ur': '5/5',
          'power_ul': '5/5', 
          'power_lr': '5/5',
          'power_ll': '5/5',
          'gait': 'Normal',
        },
      ),
    ];
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatment ?? '';
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty && mounted) {
      setState(() {
        _chiefComplaintController.text = (data['chief_complaint'] as String?) ?? '';
        _selectedSymptoms = List<String>.from((data['symptoms'] as List?) ?? []);
        _consciousness = (data['consciousness'] as String?) ?? 'Alert';
        _selectedSigns = List<String>.from((data['signs'] as List?) ?? []);
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      });
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_gcsController.text.isNotEmpty || _orientationController.text.isNotEmpty) completed++;
    if (_cnIIController.text.isNotEmpty || _cnVIIController.text.isNotEmpty) completed++;
    if (_toneController.text.isNotEmpty || _powerURController.text.isNotEmpty) completed++;
    if (_lightTouchController.text.isNotEmpty || _vibrationController.text.isNotEmpty) completed++;
    if (_bicepsRController.text.isNotEmpty || _kneeRController.text.isNotEmpty) completed++;
    if (_gaitController.text.isNotEmpty || _fingerNoseController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      if (data['symptoms'] != null) _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      if (data['signs'] != null) _selectedSigns = List<String>.from(data['signs'] as List);
      if (data['investigations'] != null) _selectedInvestigations = List<String>.from(data['investigations'] as List);
      if (data['consciousness'] != null) _consciousness = data['consciousness'] as String;
      if (data['gcs'] != null) _gcsController.text = data['gcs'] as String;
      if (data['orientation'] != null) _orientationController.text = data['orientation'] as String;
      if (data['cn_ii'] != null) _cnIIController.text = data['cn_ii'] as String;
      if (data['tone'] != null) _toneController.text = data['tone'] as String;
      if (data['power_ur'] != null) _powerURController.text = data['power_ur'] as String;
      if (data['power_ul'] != null) _powerULController.text = data['power_ul'] as String;
      if (data['power_lr'] != null) _powerLRController.text = data['power_lr'] as String;
      if (data['power_ll'] != null) _powerLLController.text = data['power_ll'] as String;
      if (data['light_touch'] != null) _lightTouchController.text = data['light_touch'] as String;
      if (data['vibration'] != null) _vibrationController.text = data['vibration'] as String;
      if (data['gait'] != null) _gaitController.text = data['gait'] as String;
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
      key: 'mental_status',
      title: 'Mental Status',
      icon: Icons.psychology_alt_rounded,
      isComplete: _gcsController.text.isNotEmpty || _orientationController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'cranial_nerves',
      title: 'Cranial Nerves',
      icon: Icons.account_tree_rounded,
      isComplete: _cnIIController.text.isNotEmpty || _cnVIIController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'motor',
      title: 'Motor',
      icon: Icons.fitness_center_rounded,
      isComplete: _toneController.text.isNotEmpty || _powerURController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'sensory',
      title: 'Sensory',
      icon: Icons.touch_app_rounded,
      isComplete: _lightTouchController.text.isNotEmpty || _vibrationController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'reflexes',
      title: 'Reflexes',
      icon: Icons.sports_gymnastics_rounded,
      isComplete: _bicepsRController.text.isNotEmpty || _kneeRController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'coordination',
      title: 'Coordination',
      icon: Icons.directions_walk_rounded,
      isComplete: _gaitController.text.isNotEmpty || _fingerNoseController.text.isNotEmpty,
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
    _gcsController.dispose();
    _orientationController.dispose();
    _speechController.dispose();
    _memoryController.dispose();
    _attentionController.dispose();
    _cnIController.dispose();
    _cnIIController.dispose();
    _cnIIIIVVIController.dispose();
    _cnVController.dispose();
    _cnVIIController.dispose();
    _cnVIIIController.dispose();
    _cnIXXController.dispose();
    _cnXIController.dispose();
    _cnXIIController.dispose();
    _toneController.dispose();
    _powerURController.dispose();
    _powerULController.dispose();
    _powerLRController.dispose();
    _powerLLController.dispose();
    _bulkController.dispose();
    _involuntaryController.dispose();
    _lightTouchController.dispose();
    _pinPrickController.dispose();
    _vibrationController.dispose();
    _proprioceptionController.dispose();
    _bicepsRController.dispose();
    _bicepsLController.dispose();
    _tricepsRController.dispose();
    _tricepsLController.dispose();
    _kneeRController.dispose();
    _kneeLController.dispose();
    _ankleRController.dispose();
    _ankleLController.dispose();
    _plantarRController.dispose();
    _plantarLController.dispose();
    _fingerNoseController.dispose();
    _heelShinController.dispose();
    _dysdiadochokinesiaController.dispose();
    _rombergController.dispose();
    _gaitController.dispose();
    _tandemGaitController.dispose();
    _investigationResultsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null, 'consciousness': _consciousness,
      'mental_status': {'gcs': _gcsController.text.isNotEmpty ? _gcsController.text : null, 'orientation': _orientationController.text.isNotEmpty ? _orientationController.text : null, 'speech': _speechController.text.isNotEmpty ? _speechController.text : null, 'memory': _memoryController.text.isNotEmpty ? _memoryController.text : null, 'attention': _attentionController.text.isNotEmpty ? _attentionController.text : null},
      'cranial_nerves': {'CN_I': _cnIController.text.isNotEmpty ? _cnIController.text : null, 'CN_II': _cnIIController.text.isNotEmpty ? _cnIIController.text : null, 'CN_III_IV_VI': _cnIIIIVVIController.text.isNotEmpty ? _cnIIIIVVIController.text : null, 'CN_V': _cnVController.text.isNotEmpty ? _cnVController.text : null, 'CN_VII': _cnVIIController.text.isNotEmpty ? _cnVIIController.text : null, 'CN_VIII': _cnVIIIController.text.isNotEmpty ? _cnVIIIController.text : null, 'CN_IX_X': _cnIXXController.text.isNotEmpty ? _cnIXXController.text : null, 'CN_XI': _cnXIController.text.isNotEmpty ? _cnXIController.text : null, 'CN_XII': _cnXIIController.text.isNotEmpty ? _cnXIIController.text : null},
      'motor': {'tone': _toneController.text.isNotEmpty ? _toneController.text : null, 'power_UR': _powerURController.text.isNotEmpty ? _powerURController.text : null, 'power_UL': _powerULController.text.isNotEmpty ? _powerULController.text : null, 'power_LR': _powerLRController.text.isNotEmpty ? _powerLRController.text : null, 'power_LL': _powerLLController.text.isNotEmpty ? _powerLLController.text : null, 'bulk': _bulkController.text.isNotEmpty ? _bulkController.text : null, 'involuntary': _involuntaryController.text.isNotEmpty ? _involuntaryController.text : null},
      'sensory': {'light_touch': _lightTouchController.text.isNotEmpty ? _lightTouchController.text : null, 'pin_prick': _pinPrickController.text.isNotEmpty ? _pinPrickController.text : null, 'vibration': _vibrationController.text.isNotEmpty ? _vibrationController.text : null, 'proprioception': _proprioceptionController.text.isNotEmpty ? _proprioceptionController.text : null},
      'reflexes': {'biceps_R': _bicepsRController.text.isNotEmpty ? _bicepsRController.text : null, 'biceps_L': _bicepsLController.text.isNotEmpty ? _bicepsLController.text : null, 'triceps_R': _tricepsRController.text.isNotEmpty ? _tricepsRController.text : null, 'triceps_L': _tricepsLController.text.isNotEmpty ? _tricepsLController.text : null, 'knee_R': _kneeRController.text.isNotEmpty ? _kneeRController.text : null, 'knee_L': _kneeLController.text.isNotEmpty ? _kneeLController.text : null, 'ankle_R': _ankleRController.text.isNotEmpty ? _ankleRController.text : null, 'ankle_L': _ankleLController.text.isNotEmpty ? _ankleLController.text : null, 'plantar_R': _plantarRController.text.isNotEmpty ? _plantarRController.text : null, 'plantar_L': _plantarLController.text.isNotEmpty ? _plantarLController.text : null},
      'coordination': {'finger_nose': _fingerNoseController.text.isNotEmpty ? _fingerNoseController.text : null, 'heel_shin': _heelShinController.text.isNotEmpty ? _heelShinController.text : null, 'dysdiadochokinesia': _dysdiadochokinesiaController.text.isNotEmpty ? _dysdiadochokinesiaController.text : null, 'romberg': _rombergController.text.isNotEmpty ? _rombergController.text : null, 'gait': _gaitController.text.isNotEmpty ? _gaitController.text : null, 'tandem': _tandemGaitController.text.isNotEmpty ? _tandemGaitController.text : null},
      'signs': _selectedSigns.isNotEmpty ? _selectedSigns : null, 'investigations': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
      'investigation_results': _investigationResultsController.text.isNotEmpty ? _investigationResultsController.text : null,
    };
  }

  Future<void> _saveRecord(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) { RecordFormWidgets.showErrorSnackbar(context, 'Please select a patient'); return; }
    setState(() => _isSaving = true);
    try {
      // V6: Build data for normalized storage
      final recordData = _buildDataJson();
      
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!, recordType: 'neuro_examination',
        title: _diagnosisController.text.isNotEmpty ? 'Neuro: ${_diagnosisController.text}' : 'Neurological Exam - ${DateFormat('MMM d').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'neuro_examination',
          title: _diagnosisController.text.isNotEmpty ? 'Neuro: ${_diagnosisController.text}' : 'Neurological Exam - ${DateFormat('MMM d').format(_recordDate)}',
          description: _chiefComplaintController.text, dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: _diagnosisController.text, treatment: _treatmentController.text, doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate, createdAt: widget.existingRecord!.createdAt);
        await db.updateMedicalRecord(updatedRecord);
        // V6: Delete old fields and re-insert
        await db.deleteFieldsForMedicalRecord(widget.existingRecord!.id);
        await db.insertMedicalRecordFieldsBatch(widget.existingRecord!.id, _selectedPatientId!, recordData);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        // V6: Save fields to normalized table
        await db.insertMedicalRecordFieldsBatch(recordId, _selectedPatientId!, recordData);
        resultRecord = await db.getMedicalRecordById(recordId);
      }
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'Neurological examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(title: widget.existingRecord != null ? 'Edit Neuro Exam' : 'Neurological Examination', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.psychology_rounded, gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)], scrollController: _scrollController,
      body: dbAsync.when(data: (db) => _buildFormContent(context, db, isDark), loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), error: (err, stack) => Center(child: Text('Error: $err'))));
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)), const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFF6366F1)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFF6366F1),
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
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['complaint'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'Reason for evaluation', maxLines: 2, enableVoice: true, suggestions: chiefComplaintSuggestions),
          const SizedBox(height: AppSpacing.md), 
          ChipSelectorSection(
            title: 'Symptoms',
            options: _symptomOptions,
            selected: _selectedSymptoms,
            onChanged: (l) => setState(() => _selectedSymptoms = l),
            accentColor: Colors.indigo,
            showClearButton: true,
          ),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['mental_status'],
        title: 'Mental Status', 
        icon: Icons.psychology_alt_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['mental_status'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['mental_status'] = expanded),
        child: Column(children: [
          _buildDropdown('Level of Consciousness', _consciousness, ['Alert', 'Confused', 'Drowsy', 'Stuporous', 'Comatose'], (v) => setState(() => _consciousness = v!), isDark),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _gcsController, label: 'GCS', hint: 'E4V5M6 = 15'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _orientationController, label: 'Orientation', hint: 'Time, place, person'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _speechController, label: 'Speech', hint: 'Fluent, clear')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _memoryController, label: 'Memory', hint: 'Intact'))]),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _attentionController, label: 'Attention', hint: 'Serial 7s'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['cranial_nerves'],
        title: 'Cranial Nerves', 
        icon: Icons.account_tree_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['cranial_nerves'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['cranial_nerves'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _cnIController, label: 'I (Smell)', hint: 'Intact')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _cnIIController, label: 'II (Vision)', hint: 'VA, fields'))]),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _cnIIIIVVIController, label: 'III,IV,VI (Eye movements)', hint: 'PERLA, EOM'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _cnVController, label: 'V (Trigeminal)', hint: 'Sensation, jaw')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _cnVIIController, label: 'VII (Facial)', hint: 'Symmetry'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _cnVIIIController, label: 'VIII (Hearing)', hint: 'Intact')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _cnIXXController, label: 'IX,X (Palate)', hint: 'Gag, uvula'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _cnXIController, label: 'XI (Trapezius)', hint: 'Shrug')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _cnXIIController, label: 'XII (Tongue)', hint: 'Midline'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['motor'],
        title: 'Motor Examination', 
        icon: Icons.fitness_center_rounded, 
        accentColor: Colors.orange,
        collapsible: true,
        initiallyExpanded: _expandedSections['motor'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['motor'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _toneController, label: 'Tone', hint: 'Normal/spastic')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _bulkController, label: 'Bulk', hint: 'Normal/wasted'))]),
          const SizedBox(height: AppSpacing.md), Text('Power (0-5)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)), const SizedBox(height: AppSpacing.sm),
          Row(children: [Expanded(child: RecordTextField(controller: _powerURController, label: 'Upper R', hint: '5/5')), const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _powerULController, label: 'Upper L', hint: '5/5')), const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _powerLRController, label: 'Lower R', hint: '5/5')), const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _powerLLController, label: 'Lower L', hint: '5/5'))]),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _involuntaryController, label: 'Involuntary Movements', hint: 'Tremor, chorea'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['sensory'],
        title: 'Sensory Examination', 
        icon: Icons.touch_app_rounded, 
        accentColor: Colors.pink,
        collapsible: true,
        initiallyExpanded: _expandedSections['sensory'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['sensory'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _lightTouchController, label: 'Light Touch', hint: 'Intact')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _pinPrickController, label: 'Pin Prick', hint: 'Intact'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _vibrationController, label: 'Vibration', hint: 'Intact')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _proprioceptionController, label: 'Proprioception', hint: 'Intact'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['reflexes'],
        title: 'Reflexes', 
        icon: Icons.sports_gymnastics_rounded, 
        accentColor: Colors.amber,
        collapsible: true,
        initiallyExpanded: _expandedSections['reflexes'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['reflexes'] = expanded),
        child: Column(children: [
          Row(children: [const SizedBox(width: 80), Expanded(child: Center(child: Text('Right', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)))), Expanded(child: Center(child: Text('Left', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700))))]),
          const SizedBox(height: AppSpacing.sm), _buildReflexRow('Biceps', _bicepsRController, _bicepsLController),
          const SizedBox(height: AppSpacing.sm), _buildReflexRow('Triceps', _tricepsRController, _tricepsLController),
          const SizedBox(height: AppSpacing.sm), _buildReflexRow('Knee', _kneeRController, _kneeLController),
          const SizedBox(height: AppSpacing.sm), _buildReflexRow('Ankle', _ankleRController, _ankleLController),
          const SizedBox(height: AppSpacing.sm), _buildReflexRow('Plantar', _plantarRController, _plantarLController),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['coordination'],
        title: 'Coordination & Gait', 
        icon: Icons.directions_walk_rounded, 
        accentColor: Colors.blue,
        collapsible: true,
        initiallyExpanded: _expandedSections['coordination'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['coordination'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _fingerNoseController, label: 'Finger-Nose', hint: 'Intact')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _heelShinController, label: 'Heel-Shin', hint: 'Intact'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _dysdiadochokinesiaController, label: 'RAM', hint: 'Normal')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _rombergController, label: 'Romberg', hint: 'Negative'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _gaitController, label: 'Gait', hint: 'Normal')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _tandemGaitController, label: 'Tandem', hint: 'Normal'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['investigations'],
        title: 'Signs & Investigations', 
        icon: Icons.biotech_rounded, 
        accentColor: Colors.cyan,
        collapsible: true,
        initiallyExpanded: _expandedSections['investigations'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['investigations'] = expanded),
        child: Column(children: [
          ChipSelectorSection(
            title: 'Special Signs',
            options: _signOptions,
            selected: _selectedSigns,
            onChanged: (l) => setState(() => _selectedSigns = l),
            accentColor: Colors.red,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          ChipSelectorSection(
            title: 'Investigations',
            options: _investigationOptions,
            selected: _selectedInvestigations,
            onChanged: (l) => setState(() => _selectedInvestigations = l),
            accentColor: Colors.cyan,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _investigationResultsController, label: 'Results', hint: 'Imaging, lab findings', maxLines: 3, enableVoice: true, suggestions: investigationResultsSuggestions),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., CVA, MS, Parkinson', maxLines: 2, enableVoice: true, suggestions: diagnosisSuggestions),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Medications, therapy', maxLines: 3, enableVoice: true, suggestions: treatmentSuggestions),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional notes', maxLines: 2, enableVoice: true, suggestions: clinicalNotesSuggestions),
        ]),
      ), 
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'), const SizedBox(height: AppSpacing.xl),
    ]));
  }

  Widget _buildReflexRow(String name, TextEditingController rightCtrl, TextEditingController leftCtrl) {
    return Row(children: [SizedBox(width: 80, child: Text(name)), const SizedBox(width: 8), Expanded(child: RecordTextField(controller: rightCtrl, hint: '++')), const SizedBox(width: 8), Expanded(child: RecordTextField(controller: leftCtrl, hint: '++'))]);
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)), const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: isDark ? Colors.grey.shade800 : Colors.white, items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: onChanged)))]);
  }
}
