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

/// Screen for adding a Gynecological Examination medical record
class AddGynExamScreen extends ConsumerStatefulWidget {
  const AddGynExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddGynExamScreen> createState() => _AddGynExamScreenState();
}

class _AddGynExamScreenState extends ConsumerState<AddGynExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 8;
  DateTime _recordDate = DateTime.now();
  
  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'menstrual': GlobalKey(),
    'obstetric': GlobalKey(),
    'screening': GlobalKey(),
    'pregnancy': GlobalKey(),
    'breast': GlobalKey(),
    'pelvic': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'menstrual': true,
    'obstetric': true,
    'screening': true,
    'pregnancy': true,
    'breast': true,
    'pelvic': true,
    'investigations': true,
    'assessment': true,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  final _chiefComplaintController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Menstrual History
  final _lmpController = TextEditingController();
  final _cycleController = TextEditingController();
  final _durationController = TextEditingController();
  final _flowController = TextEditingController();
  bool _dysmenorrhea = false;
  bool _irregularCycles = false;

  // Obstetric History (GPAL)
  final _gravidaController = TextEditingController();
  final _paraController = TextEditingController();
  final _abortionController = TextEditingController();
  final _livingController = TextEditingController();

  // Sexual & Contraceptive
  bool _sexuallyActive = false;
  final _contraceptionController = TextEditingController();
  final _lastPapController = TextEditingController();
  final _papResultController = TextEditingController();

  // Pregnancy (if applicable)
  bool _currentlyPregnant = false;
  final _gestationalAgeController = TextEditingController();
  final _eddController = TextEditingController();
  final _fundalHeightController = TextEditingController();
  final _fetalHeartController = TextEditingController();
  final _presentationController = TextEditingController();

  // Breast Exam
  String _breastExamResult = 'Normal';
  final _breastFindingsController = TextEditingController();

  // Abdominal/Pelvic Exam
  final _abdominalExamController = TextEditingController();
  final _externalGenitalsController = TextEditingController();
  final _speculumController = TextEditingController();
  final _cervixController = TextEditingController();
  final _vaginalDischargeController = TextEditingController();
  final _bimanualController = TextEditingController();
  final _uterusSizeController = TextEditingController();
  final _adnexaController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Abnormal bleeding', 'Amenorrhea', 'Dysmenorrhea', 'Pelvic pain', 'Vaginal discharge', 'Itching', 'Dyspareunia', 'Infertility', 'Urinary symptoms', 'Menopausal symptoms', 'Breast lump', 'Nipple discharge'];
  final List<String> _investigationOptions = ['Pap smear', 'HPV test', 'Pelvic ultrasound', 'TVS', 'Mammogram', 'Pregnancy test', 'Hormone panel', 'STI screening', 'Endometrial biopsy', 'Colposcopy', 'HSG', 'CA-125'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'PCOS',
        icon: Icons.bubble_chart_rounded,
        color: Colors.purple,
        description: 'Polycystic Ovary Syndrome template',
        data: {
          'symptoms': ['Amenorrhea', 'Infertility'],
          'irregular_cycles': true,
          'investigations': ['Pelvic ultrasound', 'Hormone panel'],
          'diagnosis': 'Polycystic Ovary Syndrome (PCOS)',
          'treatment': 'Lifestyle modifications. Metformin. OCP for cycle regulation. Weight management. Follow-up with hormone panel.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Menorrhagia',
        icon: Icons.water_drop_rounded,
        color: Colors.red,
        description: 'Heavy menstrual bleeding template',
        data: {
          'symptoms': ['Abnormal bleeding'],
          'investigations': ['Pelvic ultrasound', 'Hormone panel'],
          'diagnosis': 'Menorrhagia',
          'treatment': 'Tranexamic acid. NSAIDs for pain. Iron supplementation. Hormonal therapy if indicated. Follow-up for evaluation.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Vaginitis',
        icon: Icons.healing_rounded,
        color: Colors.orange,
        description: 'Vaginal infection template',
        data: {
          'symptoms': ['Vaginal discharge', 'Itching'],
          'vaginal_discharge': 'Present - character noted',
          'speculum': 'Vaginal walls - inflamed',
          'diagnosis': 'Vaginitis (Candidal/Bacterial/Trichomonas)',
          'treatment': 'Antifungal/Antibiotic therapy. Partner treatment if indicated. Hygiene advice. Follow-up in 1 week.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Fibroid',
        icon: Icons.circle_rounded,
        color: Colors.indigo,
        description: 'Uterine fibroid template',
        data: {
          'symptoms': ['Abnormal bleeding', 'Pelvic pain'],
          'investigations': ['Pelvic ultrasound', 'TVS'],
          'uterus_size': 'Enlarged, irregular',
          'diagnosis': 'Uterine Fibroid (Leiomyoma)',
          'treatment': 'Medical management: GnRH analogs, tranexamic acid. Consider surgical intervention if symptomatic. Regular follow-up.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Gyn Exam',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        description: 'Routine gynecological examination',
        data: {
          'breast_result': 'Normal',
          'abdominal': 'Soft, non-tender',
          'speculum': 'Cervix - healthy, no discharge',
          'bimanual': 'Uterus - normal size, anteverted',
          'investigations': ['Pap smear'],
          'diagnosis': 'Routine gynecological examination - Normal',
          'treatment': 'Annual screening advised. Pap smear taken. Continue regular checkups.',
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
      if (data['irregular_cycles'] != null) _irregularCycles = data['irregular_cycles'] as bool;
      if (data['vaginal_discharge'] != null) _vaginalDischargeController.text = data['vaginal_discharge'] as String;
      if (data['speculum'] != null) _speculumController.text = data['speculum'] as String;
      if (data['breast_result'] != null) _breastExamResult = data['breast_result'] as String;
      if (data['abdominal'] != null) _abdominalExamController.text = data['abdominal'] as String;
      if (data['bimanual'] != null) _bimanualController.text = data['bimanual'] as String;
      if (data['uterus_size'] != null) _uterusSizeController.text = data['uterus_size'] as String;
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
      key: 'menstrual',
      title: 'Menstrual',
      icon: Icons.calendar_today_rounded,
      isComplete: _lmpController.text.isNotEmpty || _cycleController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'obstetric',
      title: 'Obstetric',
      icon: Icons.child_care_rounded,
      isComplete: _gravidaController.text.isNotEmpty || _paraController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'screening',
      title: 'Screening',
      icon: Icons.health_and_safety_rounded,
      isComplete: _lastPapController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'pregnancy',
      title: 'Pregnancy',
      icon: Icons.pregnant_woman_rounded,
      isComplete: _currentlyPregnant,
    ),
    SectionInfo(
      key: 'breast',
      title: 'Breast',
      icon: Icons.healing_rounded,
      isComplete: _breastExamResult != 'Normal' || _breastFindingsController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'pelvic',
      title: 'Pelvic',
      icon: Icons.medical_services_rounded,
      isComplete: _abdominalExamController.text.isNotEmpty || _speculumController.text.isNotEmpty,
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
        _lmpController.text = (data['lmp'] as String?) ?? '';
        _currentlyPregnant = (data['pregnant'] as bool?) ?? false;
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      } catch (_) {}
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_lmpController.text.isNotEmpty || _cycleController.text.isNotEmpty) completed++;
    if (_gravidaController.text.isNotEmpty || _paraController.text.isNotEmpty) completed++;
    if (_breastExamResult.isNotEmpty) completed++;
    if (_abdominalExamController.text.isNotEmpty || _speculumController.text.isNotEmpty) completed++;
    if (_bimanualController.text.isNotEmpty || _cervixController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _lmpController.dispose();
    _cycleController.dispose();
    _durationController.dispose();
    _flowController.dispose();
    _gravidaController.dispose();
    _paraController.dispose();
    _abortionController.dispose();
    _livingController.dispose();
    _contraceptionController.dispose();
    _lastPapController.dispose();
    _papResultController.dispose();
    _gestationalAgeController.dispose();
    _eddController.dispose();
    _fundalHeightController.dispose();
    _fetalHeartController.dispose();
    _presentationController.dispose();
    _breastFindingsController.dispose();
    _abdominalExamController.dispose();
    _externalGenitalsController.dispose();
    _speculumController.dispose();
    _cervixController.dispose();
    _vaginalDischargeController.dispose();
    _bimanualController.dispose();
    _uterusSizeController.dispose();
    _adnexaController.dispose();
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
      'menstrual': {'lmp': _lmpController.text.isNotEmpty ? _lmpController.text : null, 'cycle': _cycleController.text.isNotEmpty ? _cycleController.text : null, 'duration': _durationController.text.isNotEmpty ? _durationController.text : null, 'flow': _flowController.text.isNotEmpty ? _flowController.text : null, 'dysmenorrhea': _dysmenorrhea, 'irregular': _irregularCycles},
      'obstetric': {'gravida': _gravidaController.text.isNotEmpty ? _gravidaController.text : null, 'para': _paraController.text.isNotEmpty ? _paraController.text : null, 'abortion': _abortionController.text.isNotEmpty ? _abortionController.text : null, 'living': _livingController.text.isNotEmpty ? _livingController.text : null},
      'sexually_active': _sexuallyActive, 'contraception': _contraceptionController.text.isNotEmpty ? _contraceptionController.text : null,
      'pap': {'last': _lastPapController.text.isNotEmpty ? _lastPapController.text : null, 'result': _papResultController.text.isNotEmpty ? _papResultController.text : null},
      'pregnant': _currentlyPregnant,
      'pregnancy': _currentlyPregnant ? {'gestational_age': _gestationalAgeController.text.isNotEmpty ? _gestationalAgeController.text : null, 'edd': _eddController.text.isNotEmpty ? _eddController.text : null, 'fundal_height': _fundalHeightController.text.isNotEmpty ? _fundalHeightController.text : null, 'fetal_heart': _fetalHeartController.text.isNotEmpty ? _fetalHeartController.text : null, 'presentation': _presentationController.text.isNotEmpty ? _presentationController.text : null} : null,
      'breast_exam': {'result': _breastExamResult, 'findings': _breastFindingsController.text.isNotEmpty ? _breastFindingsController.text : null},
      'pelvic_exam': {'abdominal': _abdominalExamController.text.isNotEmpty ? _abdominalExamController.text : null, 'external': _externalGenitalsController.text.isNotEmpty ? _externalGenitalsController.text : null, 'speculum': _speculumController.text.isNotEmpty ? _speculumController.text : null, 'cervix': _cervixController.text.isNotEmpty ? _cervixController.text : null, 'discharge': _vaginalDischargeController.text.isNotEmpty ? _vaginalDischargeController.text : null, 'bimanual': _bimanualController.text.isNotEmpty ? _bimanualController.text : null, 'uterus_size': _uterusSizeController.text.isNotEmpty ? _uterusSizeController.text : null, 'adnexa': _adnexaController.text.isNotEmpty ? _adnexaController.text : null},
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
        patientId: _selectedPatientId!, recordType: 'gyn_examination',
        title: _diagnosisController.text.isNotEmpty ? 'Gyn: ${_diagnosisController.text}' : 'Gyn Exam${_currentlyPregnant ? " (Pregnant)" : ""} - ${DateFormat('MMM d').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'gyn_examination',
          title: _diagnosisController.text.isNotEmpty ? 'Gyn: ${_diagnosisController.text}' : 'Gyn Exam${_currentlyPregnant ? " (Pregnant)" : ""} - ${DateFormat('MMM d').format(_recordDate)}',
          description: _chiefComplaintController.text, dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _diagnosisController.text, treatment: _treatmentController.text, doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate, createdAt: widget.existingRecord!.createdAt);
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'Gynecological examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(title: widget.existingRecord != null ? 'Edit Gyn Exam' : 'Gynecological Examination', subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.pregnant_woman_rounded, gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)], scrollController: _scrollController,
      body: dbAsync.when(data: (db) => _buildFormContent(context, db, isDark), loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), error: (err, stack) => Center(child: Text('Error: $err'))));
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.preselectedPatient == null) ...[PatientSelectorCard(db: db, selectedPatientId: _selectedPatientId, onChanged: (id) => setState(() => _selectedPatientId = id)), const SizedBox(height: AppSpacing.lg)],
      DatePickerCard(selectedDate: _recordDate, onDateSelected: (date) => setState(() => _recordDate = date)), const SizedBox(height: AppSpacing.lg),

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFFEC4899)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFFEC4899),
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
        accentColor: Colors.pink,
        collapsible: true,
        initiallyExpanded: _expandedSections['complaint'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _chiefComplaintController, label: 'Chief Complaint', hint: 'Reason for visit', maxLines: 2),
          const SizedBox(height: AppSpacing.md), 
          ChipSelectorSection(
            title: 'Symptoms',
            options: _symptomOptions,
            selected: _selectedSymptoms,
            onChanged: (l) => setState(() => _selectedSymptoms = l),
            accentColor: Colors.pink,
            showClearButton: true,
          ),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['menstrual'],
        title: 'Menstrual History', 
        icon: Icons.calendar_today_rounded, 
        accentColor: Colors.red,
        collapsible: true,
        initiallyExpanded: _expandedSections['menstrual'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['menstrual'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _lmpController, label: 'LMP', hint: 'Last menstrual period')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _cycleController, label: 'Cycle', hint: '28 days'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _durationController, label: 'Duration', hint: '4-5 days')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _flowController, label: 'Flow', hint: 'Normal/heavy'))]),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: SwitchListTile(title: const Text('Dysmenorrhea'), value: _dysmenorrhea, onChanged: (v) => setState(() => _dysmenorrhea = v), dense: true, contentPadding: EdgeInsets.zero)),
            Expanded(child: SwitchListTile(title: const Text('Irregular'), value: _irregularCycles, onChanged: (v) => setState(() => _irregularCycles = v), dense: true, contentPadding: EdgeInsets.zero))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['obstetric'],
        title: 'Obstetric History (GPAL)', 
        icon: Icons.child_care_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['obstetric'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['obstetric'] = expanded),
        child: Column(children: [
          Row(children: [Expanded(child: RecordTextField(controller: _gravidaController, label: 'Gravida (G)', hint: '0', keyboardType: TextInputType.number)), const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _paraController, label: 'Para (P)', hint: '0', keyboardType: TextInputType.number)),
            const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _abortionController, label: 'Abortion (A)', hint: '0', keyboardType: TextInputType.number)), const SizedBox(width: AppSpacing.sm), Expanded(child: RecordTextField(controller: _livingController, label: 'Living (L)', hint: '0', keyboardType: TextInputType.number))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['screening'],
        title: 'Sexual & Screening', 
        icon: Icons.health_and_safety_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['screening'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['screening'] = expanded),
        child: Column(children: [
          SwitchListTile(title: const Text('Sexually Active'), value: _sexuallyActive, onChanged: (v) => setState(() => _sexuallyActive = v), contentPadding: EdgeInsets.zero),
          RecordTextField(controller: _contraceptionController, label: 'Contraception', hint: 'Method used'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _lastPapController, label: 'Last Pap', hint: 'Date')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _papResultController, label: 'Result', hint: 'Normal/abnormal'))]),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['pregnancy'],
        title: 'Pregnancy Status', 
        icon: Icons.pregnant_woman_rounded, 
        accentColor: Colors.amber,
        collapsible: true,
        initiallyExpanded: _expandedSections['pregnancy'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['pregnancy'] = expanded),
        child: Column(children: [
          SwitchListTile(title: const Text('Currently Pregnant'), value: _currentlyPregnant, onChanged: (v) => setState(() => _currentlyPregnant = v), contentPadding: EdgeInsets.zero),
          if (_currentlyPregnant) ...[const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _gestationalAgeController, label: 'GA', hint: 'weeks')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _eddController, label: 'EDD', hint: 'Expected date'))]),
            const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _fundalHeightController, label: 'Fundal Height', hint: 'cm')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _fetalHeartController, label: 'FHR', hint: 'bpm'))]),
            const SizedBox(height: AppSpacing.md), RecordTextField(controller: _presentationController, label: 'Presentation', hint: 'Cephalic, breech')],
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['breast'],
        title: 'Breast Examination', 
        icon: Icons.healing_rounded, 
        accentColor: Colors.orange,
        collapsible: true,
        initiallyExpanded: _expandedSections['breast'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['breast'] = expanded),
        child: Column(children: [
          _buildDropdown('Result', _breastExamResult, ['Normal', 'Abnormal', 'Not done'], (v) => setState(() => _breastExamResult = v!), isDark),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _breastFindingsController, label: 'Findings', hint: 'Masses, discharge', maxLines: 2),
        ]),
      ), 
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['pelvic'],
        title: 'Pelvic Examination', 
        icon: Icons.medical_services_rounded, 
        accentColor: Colors.indigo,
        collapsible: true,
        initiallyExpanded: _expandedSections['pelvic'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['pelvic'] = expanded),
        child: Column(children: [
          RecordTextField(controller: _abdominalExamController, label: 'Abdominal', hint: 'Soft, non-tender'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _externalGenitalsController, label: 'External', hint: 'Normal, lesions'),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _speculumController, label: 'Speculum', hint: 'Findings'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _cervixController, label: 'Cervix', hint: 'Appearance')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _vaginalDischargeController, label: 'Discharge', hint: 'Type'))]),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _bimanualController, label: 'Bimanual', hint: 'Findings'),
          const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: RecordTextField(controller: _uterusSizeController, label: 'Uterus', hint: 'Size, position')), const SizedBox(width: AppSpacing.md), Expanded(child: RecordTextField(controller: _adnexaController, label: 'Adnexa', hint: 'Masses, tenderness'))]),
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
          RecordTextField(controller: _diagnosisController, label: 'Diagnosis', hint: 'e.g., PCOS, Fibroids', maxLines: 2),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _treatmentController, label: 'Treatment', hint: 'Plan, medications', maxLines: 3),
          const SizedBox(height: AppSpacing.md), RecordTextField(controller: _clinicalNotesController, label: 'Notes', hint: 'Additional notes', maxLines: 2),
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
