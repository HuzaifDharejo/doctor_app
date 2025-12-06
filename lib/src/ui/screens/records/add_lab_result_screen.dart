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
import '../../widgets/suggestion_text_field.dart';
import 'components/record_components.dart';
import 'record_form_widgets.dart';

/// Screen for adding a Lab Result medical record
class AddLabResultScreen extends ConsumerStatefulWidget {
  const AddLabResultScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

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
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
    }
    
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _autoSave());
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
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
      } catch (_) {}
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
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: 'lab_result',
        title: _testNameController.text.isNotEmpty 
            ? 'Lab: ${_testNameController.text} - ${DateFormat('MMM d').format(_recordDate)}'
            : 'Lab Result - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_resultController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
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
          recordType: 'lab_result',
          title: _testNameController.text.isNotEmpty 
              ? 'Lab: ${_testNameController.text} - ${DateFormat('MMM d').format(_recordDate)}'
              : 'Lab Result - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _resultController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _interpretationController.text,
          treatment: '',
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
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

  void _applyTemplate(QuickFillTemplate template) {
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
    });
    showTemplateAppliedSnackbar(context, template.label);
  }

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
    // Calculate form completion
    final completedSections = _calculateCompletedSections();
    const totalSections = 5; // Patient, Test Name, Result, Reference, Interpretation

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Indicator
          FormProgressIndicator(
            completedSections: completedSections,
            totalSections: totalSections,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: 16),

          // Quick Fill Templates
          QuickFillSection(
            title: 'Common Lab Tests',
            templates: LabResultTemplates.templates,
            onTemplateSelected: _applyTemplate,
          ),
          const SizedBox(height: 16),

          // Patient Selection
          RecordFormSection(
            title: 'Patient Information',
            icon: Icons.person_outline,
            accentColor: _primaryColor,
            child: PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onPatientSelected: (patient) {
                setState(() => _selectedPatientId = patient?.id);
              },
              label: 'Select Patient',
            ),
          ),
          const SizedBox(height: 16),

          // Date and Title Section
          RecordFormSection(
            title: 'Record Details',
            icon: Icons.event_note,
            accentColor: _primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DatePickerCard(
                  selectedDate: _recordDate,
                  onDateSelected: (date) => setState(() => _recordDate = date),
                  label: 'Test Date',
                  accentColor: _primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Test Information Section
          RecordFormSection(
            title: 'Test Information',
            icon: Icons.biotech,
            accentColor: AppColors.info,
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _testNameController,
                  label: 'Test Name',
                  hint: 'e.g., Complete Blood Count, HbA1c...',
                  prefixIcon: Icons.science_outlined,
                  suggestions: MedicalRecordSuggestions.labTestNames,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
          const SizedBox(height: 16),

          // Results Section
          RecordFormSection(
            title: 'Test Results',
            icon: Icons.analytics_outlined,
            accentColor: _getStatusColor(_resultStatus),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecordTextField(
                  controller: _resultController,
                  hint: 'Test result value(s)...',
                  maxLines: 4,
                  accentColor: _getStatusColor(_resultStatus),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
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
          const SizedBox(height: 16),

          // Interpretation
          RecordFormSection(
            title: 'Clinical Interpretation',
            icon: Icons.analytics,
            accentColor: Colors.purple,
            collapsible: true,
            child: RecordTextField(
              controller: _interpretationController,
              hint: 'Clinical significance and interpretation...',
              maxLines: 4,
              accentColor: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),

          // Clinical Notes
          RecordFormSection(
            title: 'Clinical Notes',
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: false,
            child: RecordNotesField(
              controller: _clinicalNotesController,
              label: '',
              hint: 'Additional notes, follow-up instructions...',
              accentColor: Colors.indigo,
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Lab Result' : 'Save Lab Result',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: 40),
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
