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

/// Screen for adding a Skin Examination medical record
class AddSkinExamScreen extends ConsumerStatefulWidget {
  const AddSkinExamScreen({super.key, this.preselectedPatient, this.existingRecord});
  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddSkinExamScreen> createState() => _AddSkinExamScreenState();
}

class _AddSkinExamScreenState extends ConsumerState<AddSkinExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  int? _selectedPatientId;
  static const int _totalSections = 6;
  DateTime _recordDate = DateTime.now();

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'lesion': GlobalKey(),
    'location': GlobalKey(),
    'features': GlobalKey(),
    'investigations': GlobalKey(),
    'assessment': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'lesion': true,
    'location': true,
    'features': true,
    'investigations': true,
    'assessment': true,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  final _progressionController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Lesion Description
  String _lesionType = 'Macule';
  final _lesionSizeController = TextEditingController();
  final _lesionColorController = TextEditingController();
  final _lesionShapeController = TextEditingController();
  final _lesionBorderController = TextEditingController();
  final _lesionSurfaceController = TextEditingController();
  final _lesionDistributionController = TextEditingController();

  // Body Location
  List<String> _selectedLocations = [];
  final _locationDetailsController = TextEditingController();

  // Associated Features
  List<String> _selectedFeatures = [];
  final _nailChangesController = TextEditingController();
  final _hairChangesController = TextEditingController();
  final _mucosalInvolvementController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _differentialController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  final List<String> _symptomOptions = ['Itching', 'Pain', 'Burning', 'Bleeding', 'Discharge', 'Scaling', 'Crusting', 'Swelling', 'Fever', 'Joint pain'];
  final List<String> _lesionTypes = ['Macule', 'Patch', 'Papule', 'Plaque', 'Nodule', 'Tumor', 'Vesicle', 'Bulla', 'Pustule', 'Wheal', 'Erosion', 'Ulcer', 'Crust', 'Scale', 'Lichenification', 'Atrophy'];
  final List<String> _locationOptions = ['Face', 'Scalp', 'Neck', 'Chest', 'Back', 'Abdomen', 'Upper limbs', 'Lower limbs', 'Hands', 'Feet', 'Palms', 'Soles', 'Nails', 'Genitals', 'Flexures', 'Extensor surfaces'];
  final List<String> _featureOptions = ['Koebner phenomenon', 'Auspitz sign', 'Dermographism', 'Nikolsky sign', 'Photo-sensitivity', 'Satellite lesions', 'Regional lymphadenopathy'];
  final List<String> _investigationOptions = ['Skin biopsy', 'KOH mount', 'Wood\'s lamp', 'Tzanck smear', 'Patch test', 'Dermoscopy', 'Culture', 'Blood tests'];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    if (widget.existingRecord != null) _loadExistingRecord();
    
    // Initialize dermatology-specific templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Eczema/Dermatitis',
        icon: Icons.healing_rounded,
        color: Colors.orange,
        description: 'Atopic dermatitis / Eczema template',
        data: {
          'symptoms': ['Itching', 'Scaling'],
          'lesion_type': 'Plaque',
          'locations': ['Flexures', 'Hands'],
          'diagnosis': 'Atopic Dermatitis / Eczema',
          'treatment': 'Emollients liberally. Topical corticosteroids (mild-moderate potency). Avoid irritants and triggers.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Psoriasis',
        icon: Icons.layers_rounded,
        color: Colors.purple,
        description: 'Psoriasis vulgaris template',
        data: {
          'symptoms': ['Scaling', 'Itching'],
          'lesion_type': 'Plaque',
          'locations': ['Scalp', 'Extensor surfaces'],
          'features': ['Auspitz sign', 'Koebner phenomenon'],
          'diagnosis': 'Psoriasis Vulgaris',
          'treatment': 'Topical steroids and Vitamin D analogues. Salicylic acid for scaling. Consider phototherapy.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Acne',
        icon: Icons.face_rounded,
        color: Colors.red,
        description: 'Acne vulgaris template',
        data: {
          'lesion_type': 'Papule',
          'locations': ['Face', 'Back', 'Chest'],
          'diagnosis': 'Acne Vulgaris',
          'treatment': 'Topical retinoids and benzoyl peroxide. Oral antibiotics if moderate-severe. Skincare advice given.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Fungal Infection',
        icon: Icons.bug_report_rounded,
        color: Colors.teal,
        description: 'Tinea / Dermatophytosis template',
        data: {
          'symptoms': ['Itching', 'Scaling'],
          'lesion_type': 'Patch',
          'investigations': ['KOH mount'],
          'diagnosis': 'Tinea Corporis / Dermatophytosis',
          'treatment': 'Topical antifungal (Clotrimazole/Terbinafine) for 2-4 weeks. Keep area dry. Avoid sharing towels.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Skin Exam',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        description: 'Normal skin examination',
        data: {
          'lesion_type': 'Macule',
          'diagnosis': 'Normal Skin Examination',
          'treatment': 'No treatment required. General skin care advice given.',
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
      if (data['lesion_type'] != null) _lesionType = data['lesion_type'] as String;
      if (data['locations'] != null) {
        _selectedLocations = List<String>.from(data['locations'] as List);
      }
      if (data['features'] != null) {
        _selectedFeatures = List<String>.from(data['features'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
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
      key: 'lesion',
      title: 'Lesion',
      icon: Icons.lens_rounded,
      isComplete: _lesionSizeController.text.isNotEmpty || _lesionColorController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'location',
      title: 'Location',
      icon: Icons.accessibility_new_rounded,
      isComplete: _selectedLocations.isNotEmpty,
    ),
    SectionInfo(
      key: 'features',
      title: 'Features',
      icon: Icons.fact_check_rounded,
      isComplete: _selectedFeatures.isNotEmpty || _nailChangesController.text.isNotEmpty,
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
        _lesionType = (data['lesion_type'] as String?) ?? 'Macule';
        _selectedLocations = List<String>.from((data['locations'] as List?) ?? []);
        _selectedFeatures = List<String>.from((data['features'] as List?) ?? []);
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
      });
    }
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_chiefComplaintController.text.isNotEmpty || _selectedSymptoms.isNotEmpty) completed++;
    if (_lesionSizeController.text.isNotEmpty || _lesionColorController.text.isNotEmpty) completed++;
    if (_selectedLocations.isNotEmpty) completed++;
    if (_selectedFeatures.isNotEmpty || _nailChangesController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    return completed;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _progressionController.dispose();
    _lesionSizeController.dispose();
    _lesionColorController.dispose();
    _lesionShapeController.dispose();
    _lesionBorderController.dispose();
    _lesionSurfaceController.dispose();
    _lesionDistributionController.dispose();
    _locationDetailsController.dispose();
    _nailChangesController.dispose();
    _hairChangesController.dispose();
    _mucosalInvolvementController.dispose();
    _investigationResultsController.dispose();
    _diagnosisController.dispose();
    _differentialController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'duration': _durationController.text.isNotEmpty ? _durationController.text : null,
      'progression': _progressionController.text.isNotEmpty ? _progressionController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      'lesion': {
        'type': _lesionType,
        'size': _lesionSizeController.text.isNotEmpty ? _lesionSizeController.text : null,
        'color': _lesionColorController.text.isNotEmpty ? _lesionColorController.text : null,
        'shape': _lesionShapeController.text.isNotEmpty ? _lesionShapeController.text : null,
        'border': _lesionBorderController.text.isNotEmpty ? _lesionBorderController.text : null,
        'surface': _lesionSurfaceController.text.isNotEmpty ? _lesionSurfaceController.text : null,
        'distribution': _lesionDistributionController.text.isNotEmpty ? _lesionDistributionController.text : null,
      },
      'locations': _selectedLocations.isNotEmpty ? _selectedLocations : null,
      'location_details': _locationDetailsController.text.isNotEmpty ? _locationDetailsController.text : null,
      'features': _selectedFeatures.isNotEmpty ? _selectedFeatures : null,
      'nail_changes': _nailChangesController.text.isNotEmpty ? _nailChangesController.text : null,
      'hair_changes': _hairChangesController.text.isNotEmpty ? _hairChangesController.text : null,
      'mucosal': _mucosalInvolvementController.text.isNotEmpty ? _mucosalInvolvementController.text : null,
      'investigations': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
      'investigation_results': _investigationResultsController.text.isNotEmpty ? _investigationResultsController.text : null,
      'differential': _differentialController.text.isNotEmpty ? _differentialController.text : null,
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
        patientId: _selectedPatientId!, recordType: 'skin_examination',
        title: _diagnosisController.text.isNotEmpty ? 'Skin: ${_diagnosisController.text}' : 'Skin Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintController.text), dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_diagnosisController.text), treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text), recordDate: _recordDate,
      );
      MedicalRecord? resultRecord;
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id, patientId: _selectedPatientId!, recordType: 'skin_examination',
          title: _diagnosisController.text.isNotEmpty ? 'Skin: ${_diagnosisController.text}' : 'Skin Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
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
      if (mounted) { RecordFormWidgets.showSuccessSnackbar(context, 'Skin examination saved!'); Navigator.pop(context, resultRecord); }
    } catch (e) { if (mounted) RecordFormWidgets.showErrorSnackbar(context, 'Error: $e'); }
    finally { if (mounted) setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RecordFormScaffold(
      title: widget.existingRecord != null ? 'Edit Skin Examination' : 'Skin Examination',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.face_retouching_natural_rounded, gradientColors: [const Color(0xFFF97316), const Color(0xFFEA580C)],
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

      FormProgressIndicator(completedSections: _calculateCompletedSections(), totalSections: _totalSections, accentColor: const Color(0xFFF97316)),
      const SizedBox(height: AppSpacing.md),
      
      // Section Navigation Bar
      SectionNavigationBar(
        sections: _sections,
        onSectionTap: _scrollToSection,
        accentColor: const Color(0xFFF97316),
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
          RecordTextField(
            controller: _chiefComplaintController,
            label: 'Chief Complaint',
            hint: 'e.g., Skin rash, itching',
            maxLines: 2,
            enableVoice: true,
            suggestions: chiefComplaintSuggestions,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _durationController, label: 'Duration', hint: '2 weeks')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _progressionController, label: 'Progression', hint: 'Spreading/stable')),
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
        key: _sectionKeys['lesion'],
        title: 'Lesion Description', 
        icon: Icons.lens_rounded, 
        accentColor: Colors.purple,
        collapsible: true,
        initiallyExpanded: _expandedSections['lesion'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['lesion'] = expanded),
        child: Column(children: [
          _buildDropdown('Type', _lesionType, _lesionTypes, (v) => setState(() => _lesionType = v!), isDark),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _lesionSizeController, label: 'Size', hint: 'cm/mm')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _lesionColorController, label: 'Color', hint: 'Red, brown')),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _lesionShapeController, label: 'Shape', hint: 'Round, oval')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _lesionBorderController, label: 'Border', hint: 'Well-defined')),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: RecordTextField(controller: _lesionSurfaceController, label: 'Surface', hint: 'Smooth, scaly')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: RecordTextField(controller: _lesionDistributionController, label: 'Distribution', hint: 'Localized')),
          ]),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['location'],
        title: 'Body Location', 
        icon: Icons.accessibility_new_rounded, 
        accentColor: Colors.teal,
        collapsible: true,
        initiallyExpanded: _expandedSections['location'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['location'] = expanded),
        child: Column(children: [
          ChipSelectorSection(
            title: 'Areas Involved',
            options: _locationOptions,
            selected: _selectedLocations,
            onChanged: (l) => setState(() => _selectedLocations = l),
            accentColor: Colors.teal,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _locationDetailsController, label: 'Details', hint: 'Specific location notes', maxLines: 2),
        ]),
      ),
      const SizedBox(height: AppSpacing.lg),

      RecordFormSection(
        key: _sectionKeys['features'],
        title: 'Associated Features', 
        icon: Icons.fact_check_rounded, 
        accentColor: Colors.red,
        collapsible: true,
        initiallyExpanded: _expandedSections['features'] ?? true,
        onToggle: (expanded) => setState(() => _expandedSections['features'] = expanded),
        child: Column(children: [
          ChipSelectorSection(
            title: 'Signs',
            options: _featureOptions,
            selected: _selectedFeatures,
            onChanged: (l) => setState(() => _selectedFeatures = l),
            accentColor: Colors.red,
            showClearButton: true,
          ),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _nailChangesController, label: 'Nail Changes', hint: 'Pitting, onycholysis'),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _hairChangesController, label: 'Hair Changes', hint: 'Alopecia pattern'),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _mucosalInvolvementController, label: 'Mucosal Involvement', hint: 'Oral, genital'),
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
          RecordTextField(
            controller: _investigationResultsController,
            label: 'Results',
            hint: 'Investigation findings',
            maxLines: 3,
            enableVoice: true,
            suggestions: investigationResultsSuggestions,
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
          RecordTextField(
            controller: _diagnosisController,
            label: 'Diagnosis',
            hint: 'e.g., Psoriasis, Eczema',
            maxLines: 2,
            enableVoice: true,
            suggestions: diagnosisSuggestions,
          ),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(controller: _differentialController, label: 'Differential', hint: 'Other possibilities', enableVoice: true),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(
            controller: _treatmentController,
            label: 'Treatment',
            hint: 'Medications, procedures',
            maxLines: 3,
            enableVoice: true,
            suggestions: treatmentSuggestions,
          ),
          const SizedBox(height: AppSpacing.md),
          RecordTextField(
            controller: _clinicalNotesController,
            label: 'Notes',
            hint: 'Additional observations',
            maxLines: 2,
            enableVoice: true,
            suggestions: clinicalNotesSuggestions,
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.xl),
      RecordSaveButton(onPressed: () => _saveRecord(db), isLoading: _isSaving, label: widget.existingRecord != null ? 'Update' : 'Save'),
      const SizedBox(height: AppSpacing.xl),
    ]));
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
