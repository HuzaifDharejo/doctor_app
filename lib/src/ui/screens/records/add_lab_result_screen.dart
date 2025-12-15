import 'dart:async';
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
import 'components/record_components.dart';
import 'record_form_widgets.dart';

/// Screen for adding a Lab Result medical record
class AddLabResultScreen extends ConsumerStatefulWidget {
  const AddLabResultScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
    this.encounterId,
    this.appointmentId,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;
  /// Associated encounter ID from workflow - links the record to a visit
  final int? encounterId;
  /// Associated appointment ID from workflow
  final int? appointmentId;

  @override
  ConsumerState<AddLabResultScreen> createState() => _AddLabResultScreenState();
}

class _AddLabResultScreenState extends ConsumerState<AddLabResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Auto-save state
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  bool _isAutoSaving = false;
  static const _autoSaveInterval = Duration(seconds: 30);

  // Theme colors for this record type
  static const _primaryColor = Color(0xFF14B8A6); // Lab Teal
  static const _secondaryColor = Color(0xFF0D9488);
  static const _gradientColors = [_primaryColor, _secondaryColor];
  static const int _totalSections = 5;

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'test_info': GlobalKey(),
    'results': GlobalKey(),
    'interpretation': GlobalKey(),
    'notes': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'test_info': true,
    'results': true,
    'interpretation': true,
    'notes': false,
  };
  
  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Lab Result specific fields
  final _testNameController = TextEditingController();
  final _testCategoryController = TextEditingController();
  final _resultController = TextEditingController();
  final _referenceRangeController = TextEditingController();
  final _unitsController = TextEditingController();
  final _specimenController = TextEditingController();
  final _labNameController = TextEditingController();
  final _orderingPhysicianController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _interpretationController = TextEditingController();

  String _resultStatus = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    // Initialize lab-specific templates
    _templates = [
      QuickFillTemplateItem(
        label: 'Normal CBC',
        icon: Icons.bloodtype_rounded,
        color: Colors.red,
        description: 'Complete Blood Count - Normal values',
        data: {
          'test_name': 'Complete Blood Count (CBC)',
          'category': 'Hematology',
          'specimen': 'Blood',
          'reference_range': 'WBC: 4.5-11.0 K/uL, RBC: 4.5-5.5 M/uL, Hgb: 12-16 g/dL, Plt: 150-400 K/uL',
          'units': 'Various',
          'result_status': 'Normal',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal LFT',
        icon: Icons.monitor_heart_rounded,
        color: Colors.amber,
        description: 'Liver Function Tests - Normal values',
        data: {
          'test_name': 'Liver Function Tests (LFT)',
          'category': 'Biochemistry',
          'specimen': 'Blood',
          'reference_range': 'ALT: 7-56 U/L, AST: 10-40 U/L, ALP: 44-147 U/L, Bilirubin: 0.1-1.2 mg/dL',
          'units': 'U/L, mg/dL',
          'result_status': 'Normal',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal RFT',
        icon: Icons.water_drop_rounded,
        color: Colors.blue,
        description: 'Renal Function Tests - Normal values',
        data: {
          'test_name': 'Renal Function Tests (RFT)',
          'category': 'Biochemistry',
          'specimen': 'Blood',
          'reference_range': 'Creatinine: 0.7-1.3 mg/dL, BUN: 7-20 mg/dL, eGFR: >90 mL/min/1.73m²',
          'units': 'mg/dL, mL/min',
          'result_status': 'Normal',
        },
      ),
      QuickFillTemplateItem(
        label: 'Diabetic Panel',
        icon: Icons.opacity_rounded,
        color: Colors.purple,
        description: 'Diabetes monitoring panel',
        data: {
          'test_name': 'Diabetic Panel',
          'category': 'Endocrinology',
          'specimen': 'Blood',
          'reference_range': 'FBS: 70-100 mg/dL, HbA1c: <5.7%, PPBS: <140 mg/dL',
          'units': 'mg/dL, %',
        },
      ),
      QuickFillTemplateItem(
        label: 'Lipid Profile',
        icon: Icons.favorite_rounded,
        color: Colors.green,
        description: 'Lipid panel for cardiovascular assessment',
        data: {
          'test_name': 'Lipid Profile',
          'category': 'Lipid Panel',
          'specimen': 'Blood',
          'reference_range': 'Total Cholesterol: <200 mg/dL, LDL: <100 mg/dL, HDL: >40 mg/dL, TG: <150 mg/dL',
          'units': 'mg/dL',
        },
      ),
    ];
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
    }
    
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _autoSave());
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty && mounted) {
      setState(() {
        _testNameController.text = (data['test_name'] as String?) ?? '';
        _testCategoryController.text = (data['test_category'] as String?) ?? '';
        _resultController.text = (data['result'] as String?) ?? '';
        _referenceRangeController.text = (data['reference_range'] as String?) ?? '';
        _unitsController.text = (data['units'] as String?) ?? '';
        _specimenController.text = (data['specimen'] as String?) ?? '';
        _labNameController.text = (data['lab_name'] as String?) ?? '';
        _orderingPhysicianController.text = (data['ordering_physician'] as String?) ?? '';
        _interpretationController.text = (data['interpretation'] as String?) ?? '';
        _resultStatus = (data['result_status'] as String?) ?? 'Normal';
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _scrollController.dispose();
    _testNameController.dispose();
    _testCategoryController.dispose();
    _resultController.dispose();
    _referenceRangeController.dispose();
    _unitsController.dispose();
    _specimenController.dispose();
    _labNameController.dispose();
    _orderingPhysicianController.dispose();
    _clinicalNotesController.dispose();
    _interpretationController.dispose();
    super.dispose();
  }

  // Auto-save methods
  Future<void> _checkForDraft() async {
    final draft = await FormDraftService.loadDraft(
      formType: 'lab_result',
      patientId: _selectedPatientId,
    );
    if (draft != null && mounted) {
      _showRestoreDraftDialog(draft);
    }
  }

  void _showRestoreDraftDialog(FormDraft draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restore, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Restore Draft?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A previous draft was found for this form.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('Saved ${draft.timeAgo}', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FormDraftService.clearDraft(formType: 'lab_result', patientId: _selectedPatientId);
            },
            child: Text('Discard', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromDraft(draft.data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _restoreFromDraft(Map<String, dynamic> data) {
    setState(() {
      _testNameController.text = (data['test_name'] as String?) ?? '';
      _testCategoryController.text = (data['test_category'] as String?) ?? '';
      _resultController.text = (data['result'] as String?) ?? '';
      _referenceRangeController.text = (data['reference_range'] as String?) ?? '';
      _unitsController.text = (data['units'] as String?) ?? '';
      _specimenController.text = (data['specimen'] as String?) ?? '';
      _labNameController.text = (data['lab_name'] as String?) ?? '';
      _orderingPhysicianController.text = (data['ordering_physician'] as String?) ?? '';
      _clinicalNotesController.text = (data['clinical_notes'] as String?) ?? '';
      _interpretationController.text = (data['interpretation'] as String?) ?? '';
      _resultStatus = (data['result_status'] as String?) ?? 'Normal';
      if (data['record_date'] != null) {
        _recordDate = DateTime.parse(data['record_date'] as String);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Draft restored')]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _buildDraftData() => {
    'test_name': _testNameController.text,
    'test_category': _testCategoryController.text,
    'result': _resultController.text,
    'reference_range': _referenceRangeController.text,
    'units': _unitsController.text,
    'specimen': _specimenController.text,
    'lab_name': _labNameController.text,
    'ordering_physician': _orderingPhysicianController.text,
    'clinical_notes': _clinicalNotesController.text,
    'interpretation': _interpretationController.text,
    'result_status': _resultStatus,
    'record_date': _recordDate.toIso8601String(),
  };

  bool _hasAnyContent() =>
    _testNameController.text.isNotEmpty ||
    _resultController.text.isNotEmpty ||
    _interpretationController.text.isNotEmpty ||
    _clinicalNotesController.text.isNotEmpty;

  Future<void> _autoSave() async {
    if (!mounted || !_hasAnyContent()) return;
    setState(() => _isAutoSaving = true);
    try {
      await FormDraftService.saveDraft(formType: 'lab_result', patientId: _selectedPatientId, data: _buildDraftData());
      if (mounted) setState(() { _lastSaved = DateTime.now(); _isAutoSaving = false; });
    } catch (_) {
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }

  Future<void> _clearDraftOnSuccess() async {
    await FormDraftService.clearDraft(formType: 'lab_result', patientId: _selectedPatientId);
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'test_name': _testNameController.text.isNotEmpty ? _testNameController.text : null,
      'test_category': _testCategoryController.text.isNotEmpty ? _testCategoryController.text : null,
      'result': _resultController.text.isNotEmpty ? _resultController.text : null,
      'reference_range': _referenceRangeController.text.isNotEmpty ? _referenceRangeController.text : null,
      'units': _unitsController.text.isNotEmpty ? _unitsController.text : null,
      'specimen': _specimenController.text.isNotEmpty ? _specimenController.text : null,
      'lab_name': _labNameController.text.isNotEmpty ? _labNameController.text : null,
      'ordering_physician': _orderingPhysicianController.text.isNotEmpty ? _orderingPhysicianController.text : null,
      'interpretation': _interpretationController.text.isNotEmpty ? _interpretationController.text : null,
      'result_status': _resultStatus,
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
      // V6: Build data for normalized storage
      final recordData = _buildDataJson();
      
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        encounterId: Value(widget.encounterId),
        recordType: 'lab_result',
        title: _testNameController.text.isNotEmpty 
            ? 'Lab: ${_testNameController.text} - ${DateFormat('MMM d').format(_recordDate)}'
            : 'Lab Result - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_resultController.text),
        dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        diagnosis: Value(_interpretationController.text),
        treatment: const Value(''),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          encounterId: widget.encounterId ?? widget.existingRecord!.encounterId,
          recordType: 'lab_result',
          title: _testNameController.text.isNotEmpty 
              ? 'Lab: ${_testNameController.text} - ${DateFormat('MMM d').format(_recordDate)}'
              : 'Lab Result - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _resultController.text,
          dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: _interpretationController.text,
          treatment: '',
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
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

      if (mounted) {
        await _clearDraftOnSuccess();
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Lab result updated successfully!' 
              : 'Lab result saved successfully!',
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

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null) completed++;
    if (_testNameController.text.isNotEmpty) completed++;
    if (_resultController.text.isNotEmpty) completed++;
    if (_referenceRangeController.text.isNotEmpty) completed++;
    if (_interpretationController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    final data = template.data;
    setState(() {
      if (data['test_name'] != null) {
        _testNameController.text = data['test_name'] as String;
      }
      if (data['category'] != null) {
        _testCategoryController.text = data['category'] as String;
      }
      if (data['specimen'] != null) {
        _specimenController.text = data['specimen'] as String;
      }
      if (data['reference_range'] != null) {
        _referenceRangeController.text = data['reference_range'] as String;
      }
      if (data['units'] != null) {
        _unitsController.text = data['units'] as String;
      }
      if (data['result_status'] != null) {
        _resultStatus = data['result_status'] as String;
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
      key: 'test_info',
      title: 'Test Info',
      icon: Icons.biotech,
      isComplete: _testNameController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'results',
      title: 'Results',
      icon: Icons.analytics_outlined,
      isComplete: _resultController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'interpretation',
      title: 'Interpretation',
      icon: Icons.analytics,
      isComplete: _interpretationController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'notes',
      title: 'Notes',
      icon: Icons.note_alt,
      isComplete: _clinicalNotesController.text.isNotEmpty,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Lab Result' 
          : 'Lab Result',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.science_rounded,
      gradientColors: _gradientColors,
      scrollController: _scrollController,
      trailing: AutoSaveIndicator(
        isSaving: _isAutoSaving,
        lastSaved: _lastSaved,
      ),
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
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
          // Patient Selection
          if (widget.preselectedPatient == null) ...[
            PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onChanged: (id) => setState(() => _selectedPatientId = id),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          
          // Date Picker
          DatePickerCard(
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
            label: 'Test Date',
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress Indicator
          FormProgressIndicator(
            completedSections: _calculateCompletedSections(),
            totalSections: _totalSections,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Fill Templates (using new component)
          QuickFillTemplateBar(
            templates: _templates,
            onTemplateSelected: _applyTemplate,
            title: 'Common Lab Tests',
            collapsible: true,
            initiallyExpanded: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Test Information Section
          RecordFormSection(
            key: _sectionKeys['test_info'],
            title: 'Test Information',
            icon: Icons.biotech,
            accentColor: AppColors.info,
            collapsible: true,
            initiallyExpanded: _expandedSections['test_info'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['test_info'] = expanded),
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _testNameController,
                  label: 'Test Name',
                  hint: 'e.g., Complete Blood Count, HbA1c...',
                  prefixIcon: Icons.science_outlined,
                  suggestions: MedicalRecordSuggestions.labTestNames,
                ),
                const SizedBox(height: AppSpacing.md),
                SuggestionTextField(
                  controller: _testCategoryController,
                  label: 'Category',
                  hint: 'e.g., Hematology, Biochemistry...',
                  prefixIcon: Icons.category_outlined,
                  suggestions: const [
                    'Hematology',
                    'Biochemistry',
                    'Immunology',
                    'Microbiology',
                    'Serology',
                    'Endocrinology',
                    'Urinalysis',
                    'Coagulation',
                    'Lipid Panel',
                    'Liver Function',
                    'Kidney Function',
                    'Cardiac Markers',
                    'Tumor Markers',
                    'Thyroid Panel',
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _specimenController,
                      label: 'Specimen Type',
                      hint: 'e.g., Blood, Urine...',
                      accentColor: AppColors.info,
                    ),
                    CompactTextField(
                      controller: _labNameController,
                      label: 'Lab Name',
                      hint: 'Laboratory...',
                      accentColor: AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Results Section
          RecordFormSection(
            key: _sectionKeys['results'],
            title: 'Test Results',
            icon: Icons.analytics_outlined,
            accentColor: _getStatusColor(_resultStatus),
            collapsible: true,
            initiallyExpanded: _expandedSections['results'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['results'] = expanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecordTextField(
                  controller: _resultController,
                  hint: 'Test result value(s)...',
                  maxLines: 4,
                  accentColor: _getStatusColor(_resultStatus),
                  enableVoice: true,
                  suggestions: investigationResultsSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _referenceRangeController,
                      label: 'Reference Range',
                      hint: 'Normal range...',
                      accentColor: _getStatusColor(_resultStatus),
                    ),
                    CompactTextField(
                      controller: _unitsController,
                      label: 'Units',
                      hint: 'e.g., mg/dL...',
                      accentColor: _getStatusColor(_resultStatus),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                StatusSelector(
                  selectedStatus: _resultStatus,
                  onChanged: (status) {
                    if (status != null) setState(() => _resultStatus = status);
                  },
                  label: 'Result Status',
                  statuses: const ['Normal', 'Abnormal Low', 'Abnormal High', 'Critical'],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Interpretation Section
          RecordFormSection(
            key: _sectionKeys['interpretation'],
            title: 'Clinical Interpretation',
            icon: Icons.analytics,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['interpretation'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['interpretation'] = expanded),
            child: RecordTextField(
              controller: _interpretationController,
              hint: 'Clinical significance and interpretation...',
              maxLines: 4,
              accentColor: Colors.purple,
              enableVoice: true,
              suggestions: diagnosisSuggestions,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clinical Notes Section
          RecordFormSection(
            key: _sectionKeys['notes'],
            title: 'Clinical Notes',
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: _expandedSections['notes'] ?? false,
            onToggle: (expanded) => setState(() => _expandedSections['notes'] = expanded),
            child: RecordNotesField(
              controller: _clinicalNotesController,
              label: '',
              hint: 'Additional notes, follow-up instructions...',
              accentColor: Colors.indigo,
              enableVoice: true,
              suggestions: clinicalNotesSuggestions,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Lab Result' : 'Save Lab Result',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical':
        return AppColors.error;
      case 'Abnormal High':
        return AppColors.warning;
      case 'Abnormal Low':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }
}
