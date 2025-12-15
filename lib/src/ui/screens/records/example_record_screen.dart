import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import 'components/record_components.dart';

/// Example screen demonstrating the new reusable medical record components
/// 
/// This serves as a reference implementation showing how to build
/// medical record screens with minimal code using the component library.
/// 
/// Key Components Used:
/// - [BaseRecordMixin] - Common state management
/// - [EnhancedRecordScaffold] - Full-featured layout with header, nav, FAB
/// - [ChiefComplaintSection] - Reusable complaint/symptoms section
/// - [AssessmentSection] - Reusable diagnosis/treatment section
/// - [InvestigationsSection] - Reusable tests/results section
/// - [RecordDataBuilder] - Standardized save/load pattern
class ExampleRecordScreen extends ConsumerStatefulWidget {
  const ExampleRecordScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<ExampleRecordScreen> createState() => _ExampleRecordScreenState();
}

class _ExampleRecordScreenState extends ConsumerState<ExampleRecordScreen>
    with BaseRecordMixin {
  
  // ============================================================
  // SECTION CONFIGURATION
  // ============================================================
  
  @override
  List<RecordSection> get sections => const [
    RecordSection(key: 'complaint', name: 'Complaint', icon: Icons.report_problem_rounded),
    RecordSection(key: 'examination', name: 'Exam', icon: Icons.medical_services_outlined),
    RecordSection(key: 'tests', name: 'Tests', icon: Icons.biotech_rounded),
    RecordSection(key: 'assessment', name: 'Assessment', icon: Icons.assignment_rounded),
    RecordSection(key: 'notes', name: 'Notes', icon: Icons.note_alt),
  ];

  // ============================================================
  // FORM CONTROLLERS
  // ============================================================
  
  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  List<String> _selectedSymptoms = [];
  
  // Examination
  final _examinationController = TextEditingController();
  
  // Investigations
  List<String> _selectedInvestigations = [];
  final _investigationResultsController = TextEditingController();
  
  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  // ============================================================
  // QUICK FILL TEMPLATES
  // ============================================================
  
  late List<QuickFillTemplateItem> _templates;
  
  // Theme colors
  static const _primaryColor = Color(0xFF6366F1); // Indigo
  static const _gradientColors = [Color(0xFF6366F1), Color(0xFF4F46E5)];

  @override
  void initState() {
    super.initState();
    
    // Initialize base record mixin
    initializeSections();
    
    // Set patient from preselection
    selectedPatientId = widget.preselectedPatient?.id;
    
    // Initialize templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Common Cold',
        icon: Icons.sick,
        color: Colors.blue,
        description: 'Upper respiratory infection template',
        data: {
          'chief_complaint': 'Runny nose, sore throat, mild fever',
          'symptoms': ['Fever', 'Cough', 'Headache'],
          'examination': 'Throat congested, no lymphadenopathy',
          'diagnosis': 'Acute Upper Respiratory Tract Infection',
          'treatment': 'Symptomatic treatment. Rest. Fluids. Paracetamol PRN.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Gastritis',
        icon: Icons.restaurant,
        color: Colors.orange,
        description: 'Acute gastritis template',
        data: {
          'chief_complaint': 'Epigastric pain, burning sensation',
          'symptoms': ['Nausea', 'Abdominal Pain'],
          'examination': 'Mild epigastric tenderness, no guarding',
          'diagnosis': 'Acute Gastritis',
          'treatment': 'PPI. Antacids. Dietary modification. Avoid spicy foods.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Exam',
        icon: Icons.check_circle,
        color: Colors.green,
        description: 'Normal examination template',
        data: {
          'examination': 'General examination unremarkable. No abnormality detected.',
          'diagnosis': 'Normal Examination',
        },
      ),
    ];
    
    // Load existing record if editing
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
  }

  Future<void> _loadExistingRecord() async {
    final record = widget.existingRecord!;
    recordDate = record.recordDate;
    
    // Use RecordDataBuilder to load fields
    final data = await RecordDataBuilder.load(
      db: await getDatabase(),
      recordId: record.id,
    );
    
    if (data.isNotEmpty && mounted) {
      setState(() {
        _chiefComplaintController.text = data.getString('chief_complaint');
        _durationController.text = data.getString('duration');
        _selectedSymptoms = data.getStringList('symptoms');
        _examinationController.text = data.getString('examination');
        _selectedInvestigations = data.getStringList('investigations');
        _investigationResultsController.text = data.getString('investigation_results');
        _diagnosisController.text = data.getString('diagnosis');
        _treatmentController.text = data.getString('treatment');
        _clinicalNotesController.text = data.getString('clinical_notes');
      });
    }
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      if (data['chief_complaint'] != null) {
        _chiefComplaintController.text = data['chief_complaint'] as String;
      }
      if (data['symptoms'] != null) {
        _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      }
      if (data['examination'] != null) {
        _examinationController.text = data['examination'] as String;
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
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

  double _calculateProgress() {
    int filled = 0;
    int total = 5;
    
    if (_chiefComplaintController.text.isNotEmpty) filled++;
    if (_examinationController.text.isNotEmpty) filled++;
    if (_selectedInvestigations.isNotEmpty || _investigationResultsController.text.isNotEmpty) filled++;
    if (_diagnosisController.text.isNotEmpty) filled++;
    if (_treatmentController.text.isNotEmpty || _clinicalNotesController.text.isNotEmpty) filled++;
    
    return filled / total;
  }

  Future<void> _saveRecord() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedPatientId == null) {
      showErrorSnackBar('Please select a patient');
      return;
    }

    setSaving(true);

    try {
      final db = await getDatabase();
      
      // Build data using RecordDataBuilder
      final builder = RecordDataBuilder()
        ..addChiefComplaintFields(
          complaint: _chiefComplaintController.text,
          duration: _durationController.text,
          symptoms: _selectedSymptoms,
        )
        ..addField('examination', _examinationController.text)
        ..addListField('investigations', _selectedInvestigations)
        ..addField('investigation_results', _investigationResultsController.text)
        ..addAssessmentFields(
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          notes: _clinicalNotesController.text,
        );

      // Generate title
      final title = _diagnosisController.text.isNotEmpty
          ? 'Example: ${_diagnosisController.text}'
          : 'Example Record - ${DateFormat('MMM d, yyyy').format(recordDate)}';

      if (widget.existingRecord != null) {
        // Update existing
        await builder.update(
          db: db,
          recordId: widget.existingRecord!.id,
          patientId: selectedPatientId!,
          recordType: 'example_record',
          title: title,
          recordDate: recordDate,
          description: _chiefComplaintController.text,
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          doctorNotes: _clinicalNotesController.text,
        );
        
        showSuccessSnackBar('Record updated successfully!');
      } else {
        // Create new
        await builder.save(
          db: db,
          patientId: selectedPatientId!,
          recordType: 'example_record',
          title: title,
          recordDate: recordDate,
          description: _chiefComplaintController.text,
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          doctorNotes: _clinicalNotesController.text,
        );
        
        showSuccessSnackBar('Record saved successfully!');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
    } finally {
      setSaving(false);
    }
  }

  void _resetForm() {
    setState(() {
      _chiefComplaintController.clear();
      _durationController.clear();
      _selectedSymptoms.clear();
      _examinationController.clear();
      _selectedInvestigations.clear();
      _investigationResultsController.clear();
      _diagnosisController.clear();
      _treatmentController.clear();
      _clinicalNotesController.clear();
    });
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _examinationController.dispose();
    _investigationResultsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(doctorDbProvider).when(
      data: (db) => _buildScaffold(context, db),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, DoctorDatabase db) {
    return EnhancedRecordScaffold(
      title: widget.existingRecord != null ? 'Edit Example Record' : 'Example Record',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(recordDate),
      icon: Icons.description_rounded,
      gradientColors: _gradientColors,
      sections: sections,
      sectionKeys: sectionKeys,
      onSectionTap: scrollToSection,
      templates: _templates,
      onTemplateSelected: _applyTemplate,
      db: db,
      selectedPatientId: selectedPatientId,
      onPatientChanged: setPatientId,
      preselectedPatient: widget.preselectedPatient,
      recordDate: recordDate,
      onDateChanged: setRecordDate,
      isSaving: isSaving,
      onSave: _saveRecord,
      onReset: _resetForm,
      formKey: formKey,
      scrollController: scrollController,
      isEditing: widget.existingRecord != null,
      progress: _calculateProgress(),
      body: Column(
        children: [
          // Chief Complaint Section (using reusable component with new QuickPicker UI)
          ChiefComplaintSection(
            sectionKey: getSectionKey('complaint'),
            isExpanded: isSectionExpanded('complaint'),
            onToggle: (expanded) => setState(() => expandedSections['complaint'] = expanded),
            chiefComplaintController: _chiefComplaintController,
            durationController: _durationController,
            selectedSymptoms: _selectedSymptoms,
            onSymptomsChanged: (list) => setState(() => _selectedSymptoms = list),
            accentColor: Colors.orange,
          ),
          const SizedBox(height: 16),

          // Examination Section (custom using RecordFormSection)
          RecordFormSection(
            sectionKey: getSectionKey('examination'),
            title: 'Physical Examination',
            icon: Icons.medical_services_outlined,
            accentColor: _primaryColor,
            collapsible: true,
            initiallyExpanded: isSectionExpanded('examination'),
            onToggle: (expanded) => setState(() => expandedSections['examination'] = expanded),
            completionSummary: _examinationController.text.isNotEmpty
                ? 'Examination recorded'
                : null,
            child: StyledTextField(
              label: 'Examination Findings',
              controller: _examinationController,
              hint: 'Document physical examination findings...',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
              accentColor: _primaryColor,
              enableVoice: true,
              suggestions: examinationFindingsSuggestions,
            ),
          ),
          const SizedBox(height: 16),

          // Investigations Section (using reusable component with new QuickPicker UI)
          InvestigationsSection(
            sectionKey: getSectionKey('tests'),
            isExpanded: isSectionExpanded('tests'),
            onToggle: (expanded) => setState(() => expandedSections['tests'] = expanded),
            selectedInvestigations: _selectedInvestigations,
            onInvestigationsChanged: (list) => setState(() => _selectedInvestigations = list),
            resultsController: _investigationResultsController,
            accentColor: Colors.purple,
          ),
          const SizedBox(height: 16),

          // Assessment Section (using reusable component)
          AssessmentSection(
            sectionKey: getSectionKey('assessment'),
            isExpanded: isSectionExpanded('assessment'),
            onToggle: (expanded) => setState(() => expandedSections['assessment'] = expanded),
            diagnosisController: _diagnosisController,
            treatmentController: _treatmentController,
            accentColor: Colors.green,
          ),
          const SizedBox(height: 16),

          // Notes Section (using reusable component)
          ClinicalNotesSection(
            sectionKey: getSectionKey('notes'),
            isExpanded: isSectionExpanded('notes'),
            onToggle: (expanded) => setState(() => expandedSections['notes'] = expanded),
            notesController: _clinicalNotesController,
            accentColor: Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}
