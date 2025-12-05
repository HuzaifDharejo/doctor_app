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

  // Theme colors for this record type
  static const _primaryColor = Color(0xFF14B8A6); // Lab Teal
  static const _secondaryColor = Color(0xFF0D9488);
  static const _gradientColors = [_primaryColor, _secondaryColor];

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();
  final _titleController = TextEditingController();

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
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _titleController.text = record.title;
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
    _scrollController.dispose();
    _titleController.dispose();
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
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : _testNameController.text.isNotEmpty 
                ? 'Lab: ${_testNameController.text}'
                : 'Lab Result',
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
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : _testNameController.text.isNotEmpty 
                  ? 'Lab: ${_testNameController.text}'
                  : 'Lab Result',
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

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: dbAsync.when(
        data: (db) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern Sliver App Bar
            _buildSliverAppBar(context, isDark, isCompact),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFormContent(context, db, isDark),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, bool isCompact) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradientColors,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                50,
                isCompact ? 16 : 24,
                20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingRecord != null 
                              ? 'Edit Lab Result' 
                              : 'Lab Result',
                          style: TextStyle(
                            fontSize: isCompact ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEEE, dd MMM yyyy').format(_recordDate),
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const SizedBox(height: 16),
                RecordTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Enter record title (optional)...',
                  prefixIcon: Icons.title,
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
