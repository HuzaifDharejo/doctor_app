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

/// Screen for adding an Orthopedic Examination medical record
class AddOrthopedicExamScreen extends ConsumerStatefulWidget {
  const AddOrthopedicExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddOrthopedicExamScreen> createState() => _AddOrthopedicExamScreenState();
}

class _AddOrthopedicExamScreenState extends ConsumerState<AddOrthopedicExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 8;
  DateTime _recordDate = DateTime.now();
  
  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'site': GlobalKey(),
    'inspection': GlobalKey(),
    'palpation': GlobalKey(),
    'rom': GlobalKey(),
    'neurovascular': GlobalKey(),
    'special_tests': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'site': true,
    'inspection': true,
    'palpation': true,
    'rom': true,
    'neurovascular': true,
    'special_tests': true,
    'investigations': true,
    'assessment': true,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  final _mechanismController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Site
  String _selectedSite = 'Knee';
  String _selectedSide = 'Right';

  // Inspection
  final _swellingController = TextEditingController();
  final _deformityController = TextEditingController();
  final _skinChangesController = TextEditingController();
  final _muscleWastingController = TextEditingController();
  final _gaitController = TextEditingController();

  // Palpation
  final _tendernessController = TextEditingController();
  final _warmthController = TextEditingController();
  final _crepitusController = TextEditingController();
  final _effusionController = TextEditingController();

  // ROM
  final _activeRomController = TextEditingController();
  final _passiveRomController = TextEditingController();
  final _endFeelController = TextEditingController();

  // Motor/Sensory
  final _powerController = TextEditingController();
  final _sensationController = TextEditingController();
  final _reflexesController = TextEditingController();
  final _pulseController = TextEditingController();

  // Special Tests
  List<String> _selectedSpecialTests = [];
  final _specialTestResultsController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Pain', 'Swelling', 'Stiffness', 'Locking', 'Giving way', 'Weakness', 'Numbness', 'Deformity', 'Limited ROM', 'Night pain'];
  final List<String> _siteOptions = ['Shoulder', 'Elbow', 'Wrist', 'Hand', 'Hip', 'Knee', 'Ankle', 'Foot', 'Spine - Cervical', 'Spine - Lumbar', 'Spine - Thoracic'];
  final List<String> _specialTestOptions = ['Drawer test', 'Lachman test', 'McMurray test', 'Valgus/Varus stress', 'Pivot shift', 'Apprehension test', 'Empty can test', 'Hawkins test', 'Neer test', 'FABER test', 'SLR', 'Phalen test', 'Tinel sign', 'Thomas test', 'Ober test'];
  final List<String> _investigationOptions = ['X-ray', 'MRI', 'CT scan', 'Ultrasound', 'Bone scan', 'DEXA', 'Arthroscopy', 'EMG/NCV', 'Blood tests'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Fracture',
        icon: Icons.broken_image_rounded,
        color: Colors.red,
        description: 'Bone fracture template',
        data: {
          'symptoms': ['Pain', 'Swelling', 'Deformity', 'Limited ROM'],
          'swelling': 'Present at fracture site',
          'deformity': 'Visible - describe',
          'tenderness': 'Point tenderness at fracture site',
          'investigations': ['X-ray'],
          'diagnosis': 'Fracture - [describe location and type]',
          'treatment': 'Immobilization. Pain management. Orthopedic consultation. Consider reduction and fixation if indicated.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Osteoarthritis',
        icon: Icons.elderly_rounded,
        color: Colors.amber,
        description: 'Osteoarthritis template',
        data: {
          'symptoms': ['Pain', 'Stiffness', 'Limited ROM'],
          'swelling': 'Mild bony swelling',
          'crepitus': 'Present on movement',
          'active_rom': 'Reduced',
          'investigations': ['X-ray'],
          'diagnosis': 'Osteoarthritis',
          'treatment': 'NSAIDs. Physiotherapy. Weight reduction. Consider bracing. Intra-articular injections if needed.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Low Back Pain',
        icon: Icons.airline_seat_flat_rounded,
        color: Colors.indigo,
        description: 'Low back pain / lumbar spondylosis template',
        data: {
          'site': 'Spine - Lumbar',
          'symptoms': ['Pain', 'Stiffness', 'Numbness'],
          'tenderness': 'Paravertebral tenderness',
          'special_tests': ['SLR'],
          'investigations': ['X-ray', 'MRI'],
          'diagnosis': 'Lumbar Spondylosis / Low Back Pain',
          'treatment': 'NSAIDs. Muscle relaxants. Physiotherapy. Posture correction. Core strengthening exercises.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Knee Injury',
        icon: Icons.sports_soccer_rounded,
        color: Colors.blue,
        description: 'Knee ligament injury template',
        data: {
          'site': 'Knee',
          'symptoms': ['Giving way', 'Swelling', 'Pain'],
          'effusion': 'Present',
          'special_tests': ['Lachman test', 'Drawer test', 'Pivot shift'],
          'investigations': ['MRI'],
          'diagnosis': 'Knee Ligament Injury / ACL Tear',
          'treatment': 'RICE protocol. Knee brace. Physiotherapy. Consider surgical reconstruction if indicated.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Ortho Exam',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        description: 'Normal orthopedic examination',
        data: {
          'swelling': 'None',
          'deformity': 'None',
          'tenderness': 'None',
          'active_rom': 'Full range',
          'passive_rom': 'Full range',
          'power': '5/5',
          'sensation': 'Intact',
          'reflexes': 'Normal',
          'pulse': 'Present',
          'diagnosis': 'Normal orthopedic examination',
          'treatment': 'Reassurance. Follow-up as needed.',
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
      if (data['special_tests'] != null) {
        _selectedSpecialTests = List<String>.from(data['special_tests'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
      if (data['site'] != null) _selectedSite = data['site'] as String;
      if (data['swelling'] != null) _swellingController.text = data['swelling'] as String;
      if (data['deformity'] != null) _deformityController.text = data['deformity'] as String;
      if (data['tenderness'] != null) _tendernessController.text = data['tenderness'] as String;
      if (data['crepitus'] != null) _crepitusController.text = data['crepitus'] as String;
      if (data['effusion'] != null) _effusionController.text = data['effusion'] as String;
      if (data['active_rom'] != null) _activeRomController.text = data['active_rom'] as String;
      if (data['passive_rom'] != null) _passiveRomController.text = data['passive_rom'] as String;
      if (data['power'] != null) _powerController.text = data['power'] as String;
      if (data['sensation'] != null) _sensationController.text = data['sensation'] as String;
      if (data['reflexes'] != null) _reflexesController.text = data['reflexes'] as String;
      if (data['pulse'] != null) _pulseController.text = data['pulse'] as String;
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
      key: 'site',
      title: 'Site',
      icon: Icons.location_on_rounded,
      isComplete: _selectedSite.isNotEmpty,
    ),
    SectionInfo(
      key: 'inspection',
      title: 'Inspection',
      icon: Icons.visibility_rounded,
      isComplete: _swellingController.text.isNotEmpty || _deformityController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'palpation',
      title: 'Palpation',
      icon: Icons.touch_app_rounded,
      isComplete: _tendernessController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'rom',
      title: 'ROM',
      icon: Icons.rotate_90_degrees_ccw_rounded,
      isComplete: _activeRomController.text.isNotEmpty || _passiveRomController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'neurovascular',
      title: 'Neuro',
      icon: Icons.bolt_rounded,
      isComplete: _powerController.text.isNotEmpty || _sensationController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'special_tests',
      title: 'Tests',
      icon: Icons.fact_check_rounded,
      isComplete: _selectedSpecialTests.isNotEmpty,
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
        _selectedSite = (data['site'] as String?) ?? 'Knee';
        _selectedSide = (data['side'] as String?) ?? 'Right';
        _selectedSpecialTests = List<String>.from((data['special_tests'] as List?) ?? []);
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      });
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_selectedSite.isNotEmpty) completed++;
    if (_swellingController.text.isNotEmpty || _deformityController.text.isNotEmpty) completed++;
    if (_tendernessController.text.isNotEmpty) completed++;
    if (_activeRomController.text.isNotEmpty || _passiveRomController.text.isNotEmpty) completed++;
    if (_selectedSpecialTests.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _mechanismController.dispose();
    _swellingController.dispose();
    _deformityController.dispose();
    _skinChangesController.dispose();
    _muscleWastingController.dispose();
    _gaitController.dispose();
    _tendernessController.dispose();
    _warmthController.dispose();
    _crepitusController.dispose();
    _effusionController.dispose();
    _activeRomController.dispose();
    _passiveRomController.dispose();
    _endFeelController.dispose();
    _powerController.dispose();
    _sensationController.dispose();
    _reflexesController.dispose();
    _pulseController.dispose();
    _specialTestResultsController.dispose();
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
      'mechanism': _mechanismController.text.isNotEmpty ? _mechanismController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      'site': _selectedSite, 'side': _selectedSide,
      'inspection': {'swelling': _swellingController.text.isNotEmpty ? _swellingController.text : null, 'deformity': _deformityController.text.isNotEmpty ? _deformityController.text : null, 'skin': _skinChangesController.text.isNotEmpty ? _skinChangesController.text : null, 'muscle_wasting': _muscleWastingController.text.isNotEmpty ? _muscleWastingController.text : null, 'gait': _gaitController.text.isNotEmpty ? _gaitController.text : null},
      'palpation': {'tenderness': _tendernessController.text.isNotEmpty ? _tendernessController.text : null, 'warmth': _warmthController.text.isNotEmpty ? _warmthController.text : null, 'crepitus': _crepitusController.text.isNotEmpty ? _crepitusController.text : null, 'effusion': _effusionController.text.isNotEmpty ? _effusionController.text : null},
      'rom': {'active': _activeRomController.text.isNotEmpty ? _activeRomController.text : null, 'passive': _passiveRomController.text.isNotEmpty ? _passiveRomController.text : null, 'end_feel': _endFeelController.text.isNotEmpty ? _endFeelController.text : null},
      'neurovascular': {'power': _powerController.text.isNotEmpty ? _powerController.text : null, 'sensation': _sensationController.text.isNotEmpty ? _sensationController.text : null, 'reflexes': _reflexesController.text.isNotEmpty ? _reflexesController.text : null, 'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null},
      'special_tests': _selectedSpecialTests.isNotEmpty ? _selectedSpecialTests : null,
      'special_test_results': _specialTestResultsController.text.isNotEmpty ? _specialTestResultsController.text : null,
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
        patientId: _selectedPatientId!, recordType: 'orthopedic_examination',
        title: _diagnosisController.text.isNotEmpty ? 'Ortho: ${_diagnosisController.text}' : 'Orthopedic Exam - $_selectedSide $_selectedSite - ${DateFormat('MMM d').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'orthopedic_examination',
          title: _diagnosisController.text.isNotEmpty ? 'Ortho: ${_diagnosisController.text}' : 'Orthopedic Exam - $_selectedSide $_selectedSite - ${DateFormat('MMM d').format(_recordDate)}',
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
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'Orthopedic examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(title: widget.existingRecord != null ? 'Edit Orthopedic Exam' : 'Orthopedic Examination', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.accessibility_new_rounded, gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)], scrollController: _scrollController,
      body: dbAsync.when(data: (db) => _buildFormContent(context, db, isDark), loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), error: (err, stack) => Center(child: Text('Error: $err'))));
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)), const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFF10B981)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFF10B981),
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
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'e.g., Knee pain, back pain', maxLines: 2, enableVoice: true, suggestions: chiefComplaintSuggestions),
          const SizedBox(height: AppSpacing.md), 
          Row(children: [
            Expanded(child: RecordTextField(controller: _durationController, label: 'Duration', hint: '2 weeks')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _mechanismController, label: 'Mechanism', hint: 'Fall, sports'))
          ]),
          const SizedBox(height: AppSpacing.md), 
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
        key: _sectionKeys['site'],
        title: 'Site', 
        icon: Icons.location_on_rounded, 
        accentColor: Colors.blue,
        collapsible: true,
        initiallyExpanded: _expandedSections['site'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['site'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: _buildDropdown('Joint/Region', _selectedSite, _siteOptions, (v) => setState(() => _selectedSite = v!), isDark)), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: _buildDropdown('Side', _selectedSide, ['Right', 'Left', 'Bilateral'], (v) => setState(() => _selectedSide = v!), isDark))
          ]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['inspection'],
        title: 'Inspection', 
        icon: Icons.visibility_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['inspection'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['inspection'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: RecordTextField(controller: _swellingController, label: 'Swelling', hint: 'Present/absent')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _deformityController, label: 'Deformity', hint: 'Type'))
          ]),
          const SizedBox(height: AppSpacing.md), 
          Row(children: [
            Expanded(child: RecordTextField(controller: _skinChangesController, label: 'Skin', hint: 'Scars, bruising')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _muscleWastingController, label: 'Muscle Wasting', hint: 'Quadriceps'))
          ]),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _gaitController, label: 'Gait', hint: 'Antalgic, Trendelenburg'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['palpation'],
        title: 'Palpation', 
        icon: Icons.touch_app_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['palpation'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['palpation'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: RecordTextField(controller: _tendernessController, label: 'Tenderness', hint: 'Location')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _warmthController, label: 'Warmth', hint: 'Present/absent'))
          ]),
          const SizedBox(height: AppSpacing.md), 
          Row(children: [
            Expanded(child: RecordTextField(controller: _crepitusController, label: 'Crepitus', hint: 'Present/absent')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _effusionController, label: 'Effusion', hint: 'Present/absent'))
          ]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['rom'],
        title: 'Range of Motion', 
        icon: Icons.rotate_90_degrees_ccw_rounded, 
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['rom'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['rom'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: RecordTextField(controller: _activeRomController, label: 'Active ROM', hint: '0-120°')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _passiveRomController, label: 'Passive ROM', hint: '0-130°'))
          ]),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _endFeelController, label: 'End Feel', hint: 'Bony, capsular, empty'),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['neurovascular'],
        title: 'Neurovascular', 
        icon: Icons.bolt_rounded, 
        accentColor: Colors.amber,
        collapsible: true,
        initiallyExpanded: _expandedSections['neurovascular'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['neurovascular'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: RecordTextField(controller: _powerController, label: 'Power', hint: '5/5')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _sensationController, label: 'Sensation', hint: 'Intact'))
          ]),
          const SizedBox(height: AppSpacing.md), 
          Row(children: [
            Expanded(child: RecordTextField(controller: _reflexesController, label: 'Reflexes', hint: '++')), 
            const SizedBox(width: AppSpacing.md), 
            Expanded(child: RecordTextField(controller: _pulseController, label: 'Pulse', hint: 'Present'))
          ]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['special_tests'],
        title: 'Special Tests', 
        icon: Icons.fact_check_rounded, 
        accentColor: Colors.red,
        collapsible: true,
        initiallyExpanded: _expandedSections['special_tests'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['special_tests'] = expanded),
        child: Column(children: [
          ChipSelectorSection(
            title: 'Tests',
            options: _specialTestOptions,
            selected: _selectedSpecialTests,
            onChanged: (l) => setState(() => _selectedSpecialTests = l),
            accentColor: Colors.red,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _specialTestResultsController, label: 'Results', hint: 'Positive/negative findings', maxLines: 2, enableVoice: true, suggestions: examinationFindingsSuggestions),
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
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _investigationResultsController, label: 'Results', hint: 'X-ray, MRI findings', maxLines: 3, enableVoice: true, suggestions: investigationResultsSuggestions),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., ACL tear, OA knee', maxLines: 2, enableVoice: true, suggestions: diagnosisSuggestions),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Physiotherapy, surgery', maxLines: 3, enableVoice: true, suggestions: treatmentSuggestions),
          const SizedBox(height: AppSpacing.md), 
          RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional', maxLines: 2, enableVoice: true, suggestions: clinicalNotesSuggestions),
        ]),
      ), 
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'), 
      const SizedBox(height: AppSpacing.xl),
    ]));
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)), const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: isDark ? Colors.grey.shade800 : Colors.white, items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: onChanged)))]);
  }
}
