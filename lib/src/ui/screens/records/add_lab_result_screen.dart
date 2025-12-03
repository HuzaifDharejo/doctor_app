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
      } else {
        await db.insertMedicalRecord(companion);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Lab result updated successfully!' 
              : 'Lab result saved successfully!',
        );
        Navigator.pop(context, true);
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: dbAsync.when(
        data: (db) => CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: RecordFormWidgets.buildGradientHeader(
                context: context,
                title: widget.existingRecord != null 
                    ? 'Edit Lab Result' 
                    : 'Lab Result',
                subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                icon: Icons.science_rounded,
                gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)], // Lab Teal
              ),
            ),
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
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
          RecordFormWidgets.buildSectionHeader(
            context, 'Patient', Icons.person_outline,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildPatientSelector(
            context: context,
            db: db,
            selectedPatientId: _selectedPatientId,
            onChanged: (id) => setState(() => _selectedPatientId = id),
          ),
          const SizedBox(height: 20),

          // Date Selection
          RecordFormWidgets.buildSectionHeader(
            context, 'Test Date', Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildDateSelector(
            context: context,
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
          ),
          const SizedBox(height: 20),

          // Title
          RecordFormWidgets.buildSectionHeader(context, 'Title', Icons.title),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _titleController,
            hint: 'Enter record title (optional)...',
          ),
          const SizedBox(height: 20),

          // Test Information Section
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Test Information',
            icon: Icons.biotech,
            accentColor: AppColors.info,
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
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _specimenController,
                      hint: 'Specimen type...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _labNameController,
                      hint: 'Lab name...',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Results Section
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Results',
            icon: Icons.analytics_outlined,
            accentColor: _getStatusColor(_resultStatus),
            children: [
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _resultController,
                hint: 'Test result value(s)...',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SuggestionTextField(
                      controller: _referenceRangeController,
                      label: 'Reference Range',
                      hint: 'Normal range...',
                      prefixIcon: Icons.straighten_outlined,
                      suggestions: MedicalRecordSuggestions.referenceRanges,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _unitsController,
                      hint: 'Units (e.g., mg/dL)...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildResultStatusSelector(isDark),
            ],
          ),
          const SizedBox(height: 20),

          // Interpretation
          RecordFormWidgets.buildSectionHeader(
            context, 'Clinical Interpretation', Icons.analytics,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _interpretationController,
            hint: 'Clinical significance and interpretation...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Clinical Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Clinical Notes', Icons.note_alt,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _clinicalNotesController,
            hint: 'Additional notes...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Save Button
          RecordFormWidgets.buildSaveButton(
            context: context,
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Lab Result' : 'Save Lab Result',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)], // Lab Teal
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResultStatusSelector(bool isDark) {
    final statuses = ['Normal', 'Abnormal Low', 'Abnormal High', 'Critical'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Result Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final isSelected = _resultStatus == status;
            final chipColor = _getStatusColor(status);
            
            return ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _resultStatus = status);
              },
              selectedColor: chipColor.withValues(alpha: 0.2),
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              labelStyle: TextStyle(
                color: isSelected 
                    ? chipColor 
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected 
                      ? chipColor 
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
