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

/// Screen for adding an ENT Examination medical record
class AddEntExamScreen extends ConsumerStatefulWidget {
  const AddEntExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddEntExamScreen> createState() => _AddEntExamScreenState();
}

class _AddEntExamScreenState extends ConsumerState<AddEntExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 7;
  DateTime _recordDate = DateTime.now();
  
  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'ear': GlobalKey(),
    'nose': GlobalKey(),
    'throat': GlobalKey(),
    'neck': GlobalKey(),
    'audiometry': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'ear': true,
    'nose': true,
    'throat': true,
    'neck': true,
    'audiometry': true,
    'investigations': true,
    'assessment': true,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Ear Examination
  final _earRightExternalController = TextEditingController();
  final _earLeftExternalController = TextEditingController();
  final _earRightTMController = TextEditingController();
  final _earLeftTMController = TextEditingController();
  final _earRightCanalController = TextEditingController();
  final _earLeftCanalController = TextEditingController();
  final _hearingRightController = TextEditingController();
  final _hearingLeftController = TextEditingController();

  // Nose Examination
  final _externalNoseController = TextEditingController();
  final _septumController = TextEditingController();
  final _turbinatesController = TextEditingController();
  final _nasalMucosaController = TextEditingController();
  final _sinusesController = TextEditingController();

  // Throat Examination
  final _oropharynxController = TextEditingController();
  final _tonsilsController = TextEditingController();
  final _palateController = TextEditingController();
  final _tongueController = TextEditingController();
  final _larynxController = TextEditingController();
  final _vocalCordsController = TextEditingController();

  // Neck
  final _lymphNodesController = TextEditingController();
  final _thyroidController = TextEditingController();
  final _neckMassController = TextEditingController();

  // Audiometry
  final _puretoneController = TextEditingController();
  final _speechController = TextEditingController();
  final _tympanometryController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Ear pain', 'Hearing loss', 'Tinnitus', 'Vertigo', 'Ear discharge', 'Nasal congestion', 'Rhinorrhea', 'Epistaxis', 'Anosmia', 'Snoring', 'Sore throat', 'Dysphagia', 'Hoarseness', 'Neck swelling'];
  final List<String> _investigationOptions = ['Audiometry', 'Tympanometry', 'OAE', 'BERA', 'CT Temporal Bone', 'CT PNS', 'MRI', 'Nasal Endoscopy', 'Laryngoscopy', 'FNAC', 'X-ray PNS', 'X-ray Soft Tissue Neck'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Sinusitis',
        icon: Icons.air_rounded,
        color: Colors.teal,
        description: 'Acute/Chronic sinusitis template',
        data: {
          'symptoms': ['Nasal congestion', 'Rhinorrhea'],
          'septum': 'Midline',
          'turbinates': 'Congested, edematous',
          'investigations': ['X-ray PNS'],
          'diagnosis': 'Acute Sinusitis',
          'treatment': 'Nasal decongestants. Steam inhalation. Antibiotics (Amoxicillin). Analgesics. Saline nasal spray.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Otitis Media',
        icon: Icons.hearing_rounded,
        color: Colors.blue,
        description: 'Acute otitis media template',
        data: {
          'symptoms': ['Ear pain', 'Hearing loss'],
          'ear_right_tm': 'Congested/Bulging',
          'diagnosis': 'Acute Otitis Media',
          'treatment': 'Oral antibiotics (Amoxicillin). Analgesics. Ear drops. Follow-up in 1 week.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Tonsillitis',
        icon: Icons.mic_rounded,
        color: Colors.red,
        description: 'Acute tonsillitis template',
        data: {
          'symptoms': ['Sore throat', 'Dysphagia'],
          'tonsils': 'Enlarged, congested, exudate present',
          'lymph_nodes': 'Jugulodigastric nodes enlarged, tender',
          'diagnosis': 'Acute Tonsillitis',
          'treatment': 'Oral antibiotics. Analgesics. Warm saline gargles. Soft diet. Adequate hydration.',
        },
      ),
      QuickFillTemplateItem(
        label: 'URTI',
        icon: Icons.sick_rounded,
        color: Colors.orange,
        description: 'Upper respiratory infection',
        data: {
          'symptoms': ['Nasal congestion', 'Rhinorrhea', 'Sore throat'],
          'mucosa': 'Congested, edematous',
          'oropharynx': 'Mild congestion',
          'diagnosis': 'Upper Respiratory Tract Infection',
          'treatment': 'Symptomatic treatment. Antihistamines. Analgesics. Steam inhalation. Rest and fluids.',
        },
      ),
    ];
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      
      if (data['symptoms'] != null) {
        _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
      if (data['septum'] != null) _septumController.text = data['septum'] as String;
      if (data['turbinates'] != null) _turbinatesController.text = data['turbinates'] as String;
      if (data['mucosa'] != null) _nasalMucosaController.text = data['mucosa'] as String;
      if (data['oropharynx'] != null) _oropharynxController.text = data['oropharynx'] as String;
      if (data['tonsils'] != null) _tonsilsController.text = data['tonsils'] as String;
      if (data['lymph_nodes'] != null) _lymphNodesController.text = data['lymph_nodes'] as String;
      if (data['ear_right_tm'] != null) _earRightTMController.text = data['ear_right_tm'] as String;
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
      title: 'Chief Complaint',
      icon: Icons.report_problem_rounded,
      isComplete: _chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty,
    ),
    SectionInfo(
      key: 'ear',
      title: 'Ear Exam',
      icon: Icons.hearing_rounded,
      isComplete: _earRightTMController.text.isNotEmpty || _earLeftTMController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'nose',
      title: 'Nose Exam',
      icon: Icons.air_rounded,
      isComplete: _septumController.text.isNotEmpty || _turbinatesController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'throat',
      title: 'Throat Exam',
      icon: Icons.mic_rounded,
      isComplete: _tonsilsController.text.isNotEmpty || _oropharynxController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'neck',
      title: 'Neck',
      icon: Icons.accessibility_new_rounded,
      isComplete: _lymphNodesController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'audiometry',
      title: 'Audiometry',
      icon: Icons.graphic_eq_rounded,
      isComplete: _puretoneController.text.isNotEmpty,
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
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      });
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_earRightTMController.text.isNotEmpty || _earLeftTMController.text.isNotEmpty) completed++;
    if (_septumController.text.isNotEmpty || _turbinatesController.text.isNotEmpty) completed++;
    if (_tonsilsController.text.isNotEmpty || _oropharynxController.text.isNotEmpty) completed++;
    if (_lymphNodesController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _earRightExternalController.dispose();
    _earLeftExternalController.dispose();
    _earRightTMController.dispose();
    _earLeftTMController.dispose();
    _earRightCanalController.dispose();
    _earLeftCanalController.dispose();
    _hearingRightController.dispose();
    _hearingLeftController.dispose();
    _externalNoseController.dispose();
    _septumController.dispose();
    _turbinatesController.dispose();
    _nasalMucosaController.dispose();
    _sinusesController.dispose();
    _oropharynxController.dispose();
    _tonsilsController.dispose();
    _palateController.dispose();
    _tongueController.dispose();
    _larynxController.dispose();
    _vocalCordsController.dispose();
    _lymphNodesController.dispose();
    _thyroidController.dispose();
    _neckMassController.dispose();
    _puretoneController.dispose();
    _speechController.dispose();
    _tympanometryController.dispose();
    _investigationResultsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'duration': _durationController.text.isNotEmpty ? _durationController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      'ear_right': {'external': _earRightExternalController.text.isNotEmpty ? _earRightExternalController.text : null, 'tm': _earRightTMController.text.isNotEmpty ? _earRightTMController.text : null, 'canal': _earRightCanalController.text.isNotEmpty ? _earRightCanalController.text : null, 'hearing': _hearingRightController.text.isNotEmpty ? _hearingRightController.text : null},
      'ear_left': {'external': _earLeftExternalController.text.isNotEmpty ? _earLeftExternalController.text : null, 'tm': _earLeftTMController.text.isNotEmpty ? _earLeftTMController.text : null, 'canal': _earLeftCanalController.text.isNotEmpty ? _earLeftCanalController.text : null, 'hearing': _hearingLeftController.text.isNotEmpty ? _hearingLeftController.text : null},
      'nose': {'external': _externalNoseController.text.isNotEmpty ? _externalNoseController.text : null, 'septum': _septumController.text.isNotEmpty ? _septumController.text : null, 'turbinates': _turbinatesController.text.isNotEmpty ? _turbinatesController.text : null, 'mucosa': _nasalMucosaController.text.isNotEmpty ? _nasalMucosaController.text : null, 'sinuses': _sinusesController.text.isNotEmpty ? _sinusesController.text : null},
      'throat': {'oropharynx': _oropharynxController.text.isNotEmpty ? _oropharynxController.text : null, 'tonsils': _tonsilsController.text.isNotEmpty ? _tonsilsController.text : null, 'palate': _palateController.text.isNotEmpty ? _palateController.text : null, 'tongue': _tongueController.text.isNotEmpty ? _tongueController.text : null, 'larynx': _larynxController.text.isNotEmpty ? _larynxController.text : null, 'vocal_cords': _vocalCordsController.text.isNotEmpty ? _vocalCordsController.text : null},
      'neck': {'lymph_nodes': _lymphNodesController.text.isNotEmpty ? _lymphNodesController.text : null, 'thyroid': _thyroidController.text.isNotEmpty ? _thyroidController.text : null, 'mass': _neckMassController.text.isNotEmpty ? _neckMassController.text : null},
      'audiometry': {'puretone': _puretoneController.text.isNotEmpty ? _puretoneController.text : null, 'speech': _speechController.text.isNotEmpty ? _speechController.text : null, 'tympanometry': _tympanometryController.text.isNotEmpty ? _tympanometryController.text : null},
      'investigations': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
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
        patientId: _selectedPatientId!, recordType: 'ent_examination',
        title: _diagnosisController.text.isNotEmpty ? 'ENT: ${_diagnosisController.text}' : 'ENT Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'ent_examination',
          title: _diagnosisController.text.isNotEmpty ? 'ENT: ${_diagnosisController.text}' : 'ENT Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
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
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'ENT examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(title: widget.existingRecord != null ? 'Edit ENT Examination' : 'ENT Examination', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.hearing_rounded, gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], scrollController: _scrollController,
      body: dbAsync.when(data: (db) => _buildFormContent(context, db, isDark), loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), error: (err, stack) => Center(child: Text('Error: $err'))));
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)), const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFF8B5CF6)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFF8B5CF6),
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
        accentColor: Colors.orange,
        collapsible: true,
        initiallyExpanded: _expandedSections['complaint'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'e.g., Ear pain, hearing loss', maxLines: 2, enableVoice: true, suggestions: chiefComplaintSuggestions),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _durationController, label: 'Duration', hint: 'e.g., 1 week'),
          const SizedBox(height: AppSpacing.md), 
          // Using new ChipSelectorSection component
          ChipSelectorSection(
            title: 'Symptoms',
            options: _symptomOptions,
            selected: _selectedSymptoms,
            onChanged: (l) => setState(() => _selectedSymptoms = l),
            accentColor: Colors.orange,
            showClearButton: true,
          ),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['ear'],
        title: 'Ear Examination', 
        icon: Icons.hearing_rounded, 
        accentColor: Colors.blue,
        collapsible: true,
        initiallyExpanded: _expandedSections['ear'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['ear'] = expanded),
        child: Column(children: [
          Text('Right Ear', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800)), const SizedBox(height: AppSpacing.sm),
          RecordTextField(controller: _earRightExternalController, label: 'External', hint: 'Pinna, pre/post auricular'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _earRightCanalController, label: 'Canal', hint: 'Clear, wax, discharge'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _earRightTMController, label: 'Tympanic Membrane', hint: 'Intact, perforation, retracted'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _hearingRightController, label: 'Hearing', hint: 'Tuning fork tests'),
          const SizedBox(height: AppSpacing.lg), Text('Left Ear', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade800)), const SizedBox(height: AppSpacing.sm),
          RecordTextField(controller: _earLeftExternalController, label: 'External', hint: 'Pinna, pre/post auricular'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _earLeftCanalController, label: 'Canal', hint: 'Clear, wax, discharge'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _earLeftTMController, label: 'Tympanic Membrane', hint: 'Intact, perforation, retracted'),
          const SizedBox(height: AppSpacing.sm), RecordTextField(controller: _hearingLeftController, label: 'Hearing', hint: 'Tuning fork tests'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['nose'],
        title: 'Nose Examination', 
        icon: Icons.air_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['nose'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['nose'] = expanded),
        child: Column(children: [
        RecordTextField(controller: _externalNoseController, label: 'External Nose', hint: 'Shape, swelling'),
        const SizedBox(height: AppSpacing.md), RecordTextField(controller: _septumController, label: 'Septum', hint: 'Midline, deviation'),
        const SizedBox(height: AppSpacing.md), RecordTextField(controller: _turbinatesController, label: 'Turbinates', hint: 'Size, color'),
        const SizedBox(height: AppSpacing.md), RecordTextField(controller: _nasalMucosaController, label: 'Mucosa', hint: 'Color, discharge'),
        const SizedBox(height: AppSpacing.md), RecordTextField(controller: _sinusesController, label: 'Sinuses', hint: 'Tenderness'),
      ])), const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['throat'],
        title: 'Throat Examination', 
        icon: Icons.mic_rounded, 
        accentColor: Colors.red,
        collapsible: true,
        initiallyExpanded: _expandedSections['throat'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['throat'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _oropharynxController, label: 'Oropharynx', hint: 'Posterior wall'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _tonsilsController, label: 'Tonsils', hint: 'Size, exudate'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _palateController, label: 'Palate', hint: 'Soft palate movement'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _tongueController, label: 'Tongue', hint: 'Size, coating'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _larynxController, label: 'Larynx', hint: 'IDL findings'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _vocalCordsController, label: 'Vocal Cords', hint: 'Mobility, lesions'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['neck'],
        title: 'Neck', 
        icon: Icons.accessibility_new_rounded, 
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['neck'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['neck'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _lymphNodesController, label: 'Lymph Nodes', hint: 'Cervical chains'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _thyroidController, label: 'Thyroid', hint: 'Size, nodules'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _neckMassController, label: 'Mass', hint: 'Location, size'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['audiometry'],
        title: 'Audiometry', 
        icon: Icons.graphic_eq_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['audiometry'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['audiometry'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _puretoneController, label: 'Pure Tone', hint: 'Thresholds'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _speechController, label: 'Speech', hint: 'SRT, SDS'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _tympanometryController, label: 'Tympanometry', hint: 'Type A, B, C'),
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
          // Using new ChipSelectorSection component
          ChipSelectorSection(
            title: 'Tests',
            options: _investigationOptions,
            selected: _selectedInvestigations,
            onChanged: (l) => setState(() => _selectedInvestigations = l),
            accentColor: Colors.cyan,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _investigationResultsController, label: 'Results', hint: 'Investigation findings', maxLines: 3, enableVoice: true, suggestions: investigationResultsSuggestions),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., CSOM, Allergic rhinitis', maxLines: 2, enableVoice: true, suggestions: diagnosisSuggestions),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Medications, surgery', maxLines: 3, enableVoice: true, suggestions: treatmentSuggestions),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional', maxLines: 2, enableVoice: true, suggestions: clinicalNotesSuggestions),
        ]),
      ), 
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'), 
      const SizedBox(height: AppSpacing.xl),
    ]));
  }
}
