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

/// Screen for adding an Eye Examination medical record
class AddEyeExamScreen extends ConsumerStatefulWidget {
  const AddEyeExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddEyeExamScreen> createState() => _AddEyeExamScreenState();
}

class _AddEyeExamScreenState extends ConsumerState<AddEyeExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 8;
  DateTime _recordDate = DateTime.now();

  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Visual Acuity
  final _vaRightController = TextEditingController();
  final _vaLeftController = TextEditingController();
  final _vaRightCorrectedController = TextEditingController();
  final _vaLeftCorrectedController = TextEditingController();
  final _nearVisionController = TextEditingController();
  final _colorVisionController = TextEditingController();

  // Refraction
  final _sphereRightController = TextEditingController();
  final _sphereLeftController = TextEditingController();
  final _cylinderRightController = TextEditingController();
  final _cylinderLeftController = TextEditingController();
  final _axisRightController = TextEditingController();
  final _axisLeftController = TextEditingController();

  // IOP
  final _iopRightController = TextEditingController();
  final _iopLeftController = TextEditingController();
  final _iopMethodController = TextEditingController();

  // Anterior Segment
  final _conjunctivaController = TextEditingController();
  final _corneaController = TextEditingController();
  final _anteriorChamberController = TextEditingController();
  final _irisController = TextEditingController();
  final _pupilController = TextEditingController();
  final _lensController = TextEditingController();

  // Posterior Segment
  final _fundusController = TextEditingController();
  final _discController = TextEditingController();
  final _cupDiscRatioController = TextEditingController();
  final _maculaController = TextEditingController();
  final _vesselsController = TextEditingController();
  final _retinaController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Blurred vision', 'Eye pain', 'Redness', 'Watering', 'Itching', 'Discharge', 'Floaters', 'Flashes', 'Double vision', 'Night blindness', 'Photophobia', 'Headache'];
  final List<String> _investigationOptions = ['OCT', 'FFA', 'Visual Fields', 'Gonioscopy', 'Pachymetry', 'A-scan', 'B-scan', 'Keratometry', 'Topography'];

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'visual_acuity': GlobalKey(),
    'refraction': GlobalKey(),
    'iop': GlobalKey(),
    'anterior': GlobalKey(),
    'posterior': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'visual_acuity': true,
    'refraction': true,
    'iop': true,
    'anterior': true,
    'posterior': true,
    'investigations': true,
    'assessment': true,
  };
  
  late List<QuickFillTemplateItem> _templates;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Cataract',
        icon: Icons.visibility_off_rounded,
        color: Colors.blue,
        description: 'Age-related cataract template',
        data: {
          'symptoms': ['Blurred vision'],
          'lens': 'Nuclear sclerosis/cortical opacity',
          'diagnosis': 'Age-related Cataract',
          'treatment': 'Cataract surgery (Phacoemulsification + IOL)',
        },
      ),
      QuickFillTemplateItem(
        label: 'Glaucoma',
        icon: Icons.remove_red_eye,
        color: Colors.red,
        description: 'Primary open angle glaucoma',
        data: {
          'symptoms': ['Blurred vision'],
          'cup_disc_ratio': '0.7-0.8',
          'diagnosis': 'Primary Open Angle Glaucoma',
          'treatment': 'Topical antiglaucoma medications. IOP monitoring. Visual field testing.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Conjunctivitis',
        icon: Icons.water_drop,
        color: Colors.pink,
        description: 'Acute conjunctivitis',
        data: {
          'symptoms': ['Redness', 'Watering', 'Discharge'],
          'conjunctiva': 'Congested, chemosis',
          'diagnosis': 'Acute Conjunctivitis',
          'treatment': 'Topical antibiotics. Lubricating drops. Cold compresses.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Refractive Error',
        icon: Icons.visibility_rounded,
        color: Colors.purple,
        description: 'Myopia/Hyperopia template',
        data: {
          'symptoms': ['Blurred vision', 'Headache'],
          'diagnosis': 'Refractive Error',
          'treatment': 'Corrective glasses/Contact lenses prescribed',
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
        final va = data['visual_acuity'] as Map<String, dynamic>?;
        if (va != null) {
          _vaRightController.text = (va['right'] as String?) ?? '';
          _vaLeftController.text = (va['left'] as String?) ?? '';
          _vaRightCorrectedController.text = (va['right_corrected'] as String?) ?? '';
          _vaLeftCorrectedController.text = (va['left_corrected'] as String?) ?? '';
        }
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      });
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_vaRightController.text.isNotEmpty || _vaLeftController.text.isNotEmpty) completed++;
    if (_sphereRightController.text.isNotEmpty || _sphereLeftController.text.isNotEmpty) completed++;
    if (_iopRightController.text.isNotEmpty || _iopLeftController.text.isNotEmpty) completed++;
    if (_conjunctivaController.text.isNotEmpty || _corneaController.text.isNotEmpty) completed++;
    if (_fundusController.text.isNotEmpty || _maculaController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      if (data['symptoms'] != null) _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      if (data['investigations'] != null) _selectedInvestigations = List<String>.from(data['investigations'] as List);
      if (data['lens'] != null) _lensController.text = data['lens'] as String;
      if (data['cup_disc_ratio'] != null) _cupDiscRatioController.text = data['cup_disc_ratio'] as String;
      if (data['conjunctiva'] != null) _conjunctivaController.text = data['conjunctiva'] as String;
      if (data['diagnosis'] != null) _diagnosisController.text = data['diagnosis'] as String;
      if (data['treatment'] != null) _treatmentController.text = data['treatment'] as String;
    });
    _showAppliedSnackbar(template.label, template.color);
  }

  void _showAppliedSnackbar(String templateName, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$templateName template applied'),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
      key: 'visual_acuity',
      title: 'Visual Acuity',
      icon: Icons.visibility,
      isComplete: _vaRightController.text.isNotEmpty || _vaLeftController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'refraction',
      title: 'Refraction',
      icon: Icons.lens_rounded,
      isComplete: _sphereRightController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'iop',
      title: 'IOP',
      icon: Icons.speed,
      isComplete: _iopRightController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'anterior',
      title: 'Anterior',
      icon: Icons.lens_outlined,
      isComplete: _conjunctivaController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'posterior',
      title: 'Posterior',
      icon: Icons.circle,
      isComplete: _fundusController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'investigations',
      title: 'Tests',
      icon: Icons.biotech,
      isComplete: _selectedInvestigations.isNotEmpty,
    ),
    SectionInfo(
      key: 'assessment',
      title: 'Assessment',
      icon: Icons.assignment,
      isComplete: _diagnosisController.text.isNotEmpty,
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _vaRightController.dispose();
    _vaLeftController.dispose();
    _vaRightCorrectedController.dispose();
    _vaLeftCorrectedController.dispose();
    _nearVisionController.dispose();
    _colorVisionController.dispose();
    _sphereRightController.dispose();
    _sphereLeftController.dispose();
    _cylinderRightController.dispose();
    _cylinderLeftController.dispose();
    _axisRightController.dispose();
    _axisLeftController.dispose();
    _iopRightController.dispose();
    _iopLeftController.dispose();
    _iopMethodController.dispose();
    _conjunctivaController.dispose();
    _corneaController.dispose();
    _anteriorChamberController.dispose();
    _irisController.dispose();
    _pupilController.dispose();
    _lensController.dispose();
    _fundusController.dispose();
    _discController.dispose();
    _cupDiscRatioController.dispose();
    _maculaController.dispose();
    _vesselsController.dispose();
    _retinaController.dispose();
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
      'visual_acuity': {
        'right': _vaRightController.text.isNotEmpty ? _vaRightController.text : null,
        'left': _vaLeftController.text.isNotEmpty ? _vaLeftController.text : null,
        'right_corrected': _vaRightCorrectedController.text.isNotEmpty ? _vaRightCorrectedController.text : null,
        'left_corrected': _vaLeftCorrectedController.text.isNotEmpty ? _vaLeftCorrectedController.text : null,
        'near': _nearVisionController.text.isNotEmpty ? _nearVisionController.text : null,
        'color': _colorVisionController.text.isNotEmpty ? _colorVisionController.text : null,
      },
      'refraction': {
        'sphere_right': _sphereRightController.text.isNotEmpty ? _sphereRightController.text : null,
        'sphere_left': _sphereLeftController.text.isNotEmpty ? _sphereLeftController.text : null,
        'cylinder_right': _cylinderRightController.text.isNotEmpty ? _cylinderRightController.text : null,
        'cylinder_left': _cylinderLeftController.text.isNotEmpty ? _cylinderLeftController.text : null,
        'axis_right': _axisRightController.text.isNotEmpty ? _axisRightController.text : null,
        'axis_left': _axisLeftController.text.isNotEmpty ? _axisLeftController.text : null,
      },
      'iop': {
        'right': _iopRightController.text.isNotEmpty ? _iopRightController.text : null,
        'left': _iopLeftController.text.isNotEmpty ? _iopLeftController.text : null,
        'method': _iopMethodController.text.isNotEmpty ? _iopMethodController.text : null,
      },
      'anterior_segment': {
        'conjunctiva': _conjunctivaController.text.isNotEmpty ? _conjunctivaController.text : null,
        'cornea': _corneaController.text.isNotEmpty ? _corneaController.text : null,
        'anterior_chamber': _anteriorChamberController.text.isNotEmpty ? _anteriorChamberController.text : null,
        'iris': _irisController.text.isNotEmpty ? _irisController.text : null,
        'pupil': _pupilController.text.isNotEmpty ? _pupilController.text : null,
        'lens': _lensController.text.isNotEmpty ? _lensController.text : null,
      },
      'posterior_segment': {
        'fundus': _fundusController.text.isNotEmpty ? _fundusController.text : null,
        'disc': _discController.text.isNotEmpty ? _discController.text : null,
        'cup_disc_ratio': _cupDiscRatioController.text.isNotEmpty ? _cupDiscRatioController.text : null,
        'macula': _maculaController.text.isNotEmpty ? _maculaController.text : null,
        'vessels': _vesselsController.text.isNotEmpty ? _vesselsController.text : null,
        'retina': _retinaController.text.isNotEmpty ? _retinaController.text : null,
      },
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
        patientId: _selectedPatientId!, recordType: 'eye_examination',
        title: _diagnosisController.text.isNotEmpty ? 'Eye: ${_diagnosisController.text}' : 'Eye Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'eye_examination',
          title: _diagnosisController.text.isNotEmpty ? 'Eye: ${_diagnosisController.text}' : 'Eye Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _chiefComplaintController.text, dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: _diagnosisController.text, treatment: _treatmentController.text,
          doctorNotes: _clinicalNotesController.text, recordDate: _recordDate, createdAt: widget.existingRecord!.createdAt,
        );
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
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'Eye examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(
      title: widget.existingRecord != null ? 'Edit Eye Examination' : 'Eye Examination',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.visibility_rounded, gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      scrollController: _scrollController,
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)),
      const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFF06B6D4)),
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
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'e.g., Blurred vision, eye pain', maxLines: 2, enableVoice: true, suggestions: chiefComplaintSuggestions),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _durationController, label: 'Duration', hint: 'e.g., 2 weeks'),
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
        key: _sectionKeys['visual_acuity'],
        title: 'Visual Acuity',
        icon: Icons.visibility_rounded,
        accentColor: Colors.blue,
        collapsible: true,
        initiallyExpanded: _expandedSections['visual_acuity'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['visual_acuity'] = expanded),
        child: Column(children: [
          Text('Uncorrected', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: RecordTextField(controller: _vaRightController, label: 'OD (Right)', hint: '6/6')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _vaLeftController, label: 'OS (Left)', hint: '6/6')),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('Corrected', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: RecordTextField(controller: _vaRightCorrectedController, label: 'OD', hint: '6/6')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _vaLeftCorrectedController, label: 'OS', hint: '6/6')),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _nearVisionController, label: 'Near Vision', hint: 'N6')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _colorVisionController, label: 'Color Vision', hint: 'Normal/Deficient')),
          ]),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['refraction'],
        title: 'Refraction',
        icon: Icons.lens_rounded,
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['refraction'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['refraction'] = expanded),
        child: Column(children: [
          Text('Right Eye (OD)', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: RecordTextField(controller: _sphereRightController, label: 'Sphere', hint: '+/-')),
            const SizedBox(width: 8),
            Expanded(child: RecordTextField(controller: _cylinderRightController, label: 'Cylinder', hint: '+/-')),
            const SizedBox(width: 8),
            Expanded(child: RecordTextField(controller: _axisRightController, label: 'Axis', hint: '°')),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('Left Eye (OS)', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.grey.shade700)),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: RecordTextField(controller: _sphereLeftController, label: 'Sphere', hint: '+/-')),
            const SizedBox(width: 8),
            Expanded(child: RecordTextField(controller: _cylinderLeftController, label: 'Cylinder', hint: '+/-')),
            const SizedBox(width: 8),
            Expanded(child: RecordTextField(controller: _axisLeftController, label: 'Axis', hint: '°')),
          ]),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['iop'],
        title: 'Intraocular Pressure',
        icon: Icons.speed_rounded,
        accentColor: Colors.green,
        collapsible: true,
        initiallyExpanded: _expandedSections['iop'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['iop'] = expanded),
        child: Column(children: [
          Row(children: [
            Expanded(child: RecordTextField(controller: _iopRightController, label: 'OD (Right)', hint: 'mmHg', keyboardType: TextInputType.number)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _iopLeftController, label: 'OS (Left)', hint: 'mmHg', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _iopMethodController, label: 'Method', hint: 'Applanation, NCT'),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['anterior'],
        title: 'Anterior Segment',
        icon: Icons.remove_red_eye_rounded,
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['anterior'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['anterior'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _conjunctivaController, label: 'Conjunctiva', hint: 'Clear, injected'),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _corneaController, label: 'Cornea', hint: 'Clear, edema, opacity'),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _anteriorChamberController, label: 'Anterior Chamber', hint: 'Depth, cells, flare'),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _irisController, label: 'Iris', hint: 'Color, pattern')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _pupilController, label: 'Pupil', hint: 'Size, shape, reaction')),
          ]),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _lensController, label: 'Lens', hint: 'Clear, cataract grade'),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['posterior'],
        title: 'Posterior Segment',
        icon: Icons.blur_circular_rounded,
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['posterior'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['posterior'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _fundusController, label: 'Fundus', hint: 'Overall appearance'),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _discController, label: 'Optic Disc', hint: 'Color, margins')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _cupDiscRatioController, label: 'C/D Ratio', hint: '0.3')),
          ]),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _maculaController, label: 'Macula', hint: 'Foveal reflex, pathology'),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _vesselsController, label: 'Vessels', hint: 'AV ratio, caliber')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _retinaController, label: 'Retina', hint: 'Attached, lesions')),
          ]),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., Cataract, Glaucoma', maxLines: 2, enableVoice: true, suggestions: diagnosisSuggestions),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Medications, surgery plan', maxLines: 3, enableVoice: true, suggestions: treatmentSuggestions),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional observations', maxLines: 2, enableVoice: true, suggestions: clinicalNotesSuggestions),
        ]),
      ),
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'),
      const SizedBox(height: AppSpacing.xl),
    ]));
  }
}
