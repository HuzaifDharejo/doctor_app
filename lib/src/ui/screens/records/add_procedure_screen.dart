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
import 'record_form_widgets.dart';

/// Screen for adding a Procedure medical record
class AddProcedureScreen extends ConsumerStatefulWidget {
  const AddProcedureScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddProcedureScreen> createState() => _AddProcedureScreenState();
}

class _AddProcedureScreenState extends ConsumerState<AddProcedureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();
  final _titleController = TextEditingController();

  // Procedure specific fields
  final _procedureNameController = TextEditingController();
  final _procedureCodeController = TextEditingController();
  final _indicationController = TextEditingController();
  final _anesthesiaController = TextEditingController();
  final _procedureNotesController = TextEditingController();
  final _findingsController = TextEditingController();
  final _complicationsController = TextEditingController();
  final _specimenController = TextEditingController();
  final _postOpInstructionsController = TextEditingController();
  final _performedByController = TextEditingController();
  final _assistedByController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  // Vitals
  final _bpPreController = TextEditingController();
  final _pulsePreController = TextEditingController();
  final _spo2PreController = TextEditingController();
  final _bpPostController = TextEditingController();
  final _pulsePostController = TextEditingController();
  final _spo2PostController = TextEditingController();

  String _procedureStatus = 'Completed';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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
        _procedureNameController.text = (data['procedure_name'] as String?) ?? '';
        _procedureCodeController.text = (data['procedure_code'] as String?) ?? '';
        _indicationController.text = (data['indication'] as String?) ?? '';
        _anesthesiaController.text = (data['anesthesia'] as String?) ?? '';
        _procedureNotesController.text = (data['procedure_notes'] as String?) ?? '';
        _findingsController.text = (data['findings'] as String?) ?? '';
        _complicationsController.text = (data['complications'] as String?) ?? '';
        _specimenController.text = (data['specimen'] as String?) ?? '';
        _postOpInstructionsController.text = (data['post_op_instructions'] as String?) ?? '';
        _performedByController.text = (data['performed_by'] as String?) ?? '';
        _assistedByController.text = (data['assisted_by'] as String?) ?? '';
        _procedureStatus = (data['procedure_status'] as String?) ?? 'Completed';
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpPreController.text = (vitals['bp_pre'] as String?) ?? '';
          _pulsePreController.text = (vitals['pulse_pre'] as String?) ?? '';
          _spo2PreController.text = (vitals['spo2_pre'] as String?) ?? '';
          _bpPostController.text = (vitals['bp_post'] as String?) ?? '';
          _pulsePostController.text = (vitals['pulse_post'] as String?) ?? '';
          _spo2PostController.text = (vitals['spo2_post'] as String?) ?? '';
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _procedureNameController.dispose();
    _procedureCodeController.dispose();
    _indicationController.dispose();
    _anesthesiaController.dispose();
    _procedureNotesController.dispose();
    _findingsController.dispose();
    _complicationsController.dispose();
    _specimenController.dispose();
    _postOpInstructionsController.dispose();
    _performedByController.dispose();
    _assistedByController.dispose();
    _clinicalNotesController.dispose();
    _bpPreController.dispose();
    _pulsePreController.dispose();
    _spo2PreController.dispose();
    _bpPostController.dispose();
    _pulsePostController.dispose();
    _spo2PostController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'procedure_name': _procedureNameController.text.isNotEmpty ? _procedureNameController.text : null,
      'procedure_code': _procedureCodeController.text.isNotEmpty ? _procedureCodeController.text : null,
      'indication': _indicationController.text.isNotEmpty ? _indicationController.text : null,
      'anesthesia': _anesthesiaController.text.isNotEmpty ? _anesthesiaController.text : null,
      'procedure_notes': _procedureNotesController.text.isNotEmpty ? _procedureNotesController.text : null,
      'findings': _findingsController.text.isNotEmpty ? _findingsController.text : null,
      'complications': _complicationsController.text.isNotEmpty ? _complicationsController.text : null,
      'specimen': _specimenController.text.isNotEmpty ? _specimenController.text : null,
      'post_op_instructions': _postOpInstructionsController.text.isNotEmpty ? _postOpInstructionsController.text : null,
      'performed_by': _performedByController.text.isNotEmpty ? _performedByController.text : null,
      'assisted_by': _assistedByController.text.isNotEmpty ? _assistedByController.text : null,
      'procedure_status': _procedureStatus,
      'start_time': _startTime != null ? '${_startTime!.hour}:${_startTime!.minute}' : null,
      'end_time': _endTime != null ? '${_endTime!.hour}:${_endTime!.minute}' : null,
      'vitals': {
        'bp_pre': _bpPreController.text.isNotEmpty ? _bpPreController.text : null,
        'pulse_pre': _pulsePreController.text.isNotEmpty ? _pulsePreController.text : null,
        'spo2_pre': _spo2PreController.text.isNotEmpty ? _spo2PreController.text : null,
        'bp_post': _bpPostController.text.isNotEmpty ? _bpPostController.text : null,
        'pulse_post': _pulsePostController.text.isNotEmpty ? _pulsePostController.text : null,
        'spo2_post': _spo2PostController.text.isNotEmpty ? _spo2PostController.text : null,
      },
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
        recordType: 'procedure',
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : _procedureNameController.text.isNotEmpty 
                ? 'Procedure: ${_procedureNameController.text}'
                : 'Medical Procedure',
        description: Value(_procedureNotesController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_findingsController.text),
        treatment: Value(_postOpInstructionsController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'procedure',
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : _procedureNameController.text.isNotEmpty 
                  ? 'Procedure: ${_procedureNameController.text}'
                  : 'Medical Procedure',
          description: _procedureNotesController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _findingsController.text,
          treatment: _postOpInstructionsController.text,
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
              ? 'Procedure record updated successfully!' 
              : 'Procedure record saved successfully!',
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
                    ? 'Edit Procedure' 
                    : 'Medical Procedure',
                subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                icon: Icons.healing_rounded,
                gradientColors: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
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
            context, 'Procedure Date', Icons.calendar_today,
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

          // Procedure Information
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Procedure Information',
            icon: Icons.healing_outlined,
            accentColor: const Color(0xFFEC4899),
            children: [
              SuggestionTextField(
                controller: _procedureNameController,
                label: 'Procedure Name',
                hint: 'e.g., Wound Debridement, Biopsy...',
                prefixIcon: Icons.healing_outlined,
                suggestions: MedicalRecordSuggestions.procedureNames,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _procedureCodeController,
                      hint: 'Procedure code...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusSelector(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _indicationController,
                hint: 'Clinical indication for procedure...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTimeSelector('Start', _startTime, (t) => setState(() => _startTime = t), isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeSelector('End', _endTime, (t) => setState(() => _endTime = t), isDark)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Anesthesia
          RecordFormWidgets.buildSectionHeader(
            context, 'Anesthesia', Icons.airline_seat_flat,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _anesthesiaController,
            label: 'Anesthesia Type',
            hint: 'e.g., Local, General, Regional...',
            prefixIcon: Icons.airline_seat_flat_outlined,
            suggestions: const [
              'None',
              'Local anesthesia',
              'Topical anesthesia',
              'Regional block',
              'Spinal anesthesia',
              'Epidural anesthesia',
              'General anesthesia',
              'Conscious sedation',
              'Monitored anesthesia care (MAC)',
            ],
          ),
          const SizedBox(height: 20),

          // Pre-Procedure Vitals
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Pre-Procedure Vitals',
            icon: Icons.favorite_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _bpPreController,
                      label: 'BP',
                      unit: 'mmHg',
                      hint: '120/80',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _pulsePreController,
                      label: 'Pulse',
                      unit: 'bpm',
                      hint: '72',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _spo2PreController,
                      label: 'SpO₂',
                      unit: '%',
                      hint: '98',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Procedure Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Procedure Notes', Icons.note_alt,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _procedureNotesController,
            label: 'Procedure Details',
            hint: 'Describe the procedure performed...',
            prefixIcon: Icons.note_alt_outlined,
            maxLines: 6,
            suggestions: MedicalRecordSuggestions.procedureNotes,
            separator: '. ',
          ),
          const SizedBox(height: 20),

          // Findings
          RecordFormWidgets.buildSectionHeader(
            context, 'Intra-operative Findings', Icons.search,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _findingsController,
            hint: 'Findings during procedure...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Specimen
          RecordFormWidgets.buildSectionHeader(
            context, 'Specimen', Icons.science_outlined,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _specimenController,
            hint: 'Specimen collected (if any)...',
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Complications
          RecordFormWidgets.buildSectionHeader(
            context, 'Complications', Icons.warning_amber_outlined,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _complicationsController,
            hint: 'Any complications during/after procedure...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Post-Procedure Vitals
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Post-Procedure Vitals',
            icon: Icons.monitor_heart_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _bpPostController,
                      label: 'BP',
                      unit: 'mmHg',
                      hint: '120/80',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _pulsePostController,
                      label: 'Pulse',
                      unit: 'bpm',
                      hint: '72',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _spo2PostController,
                      label: 'SpO₂',
                      unit: '%',
                      hint: '98',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Post-Op Instructions
          RecordFormWidgets.buildSectionHeader(
            context, 'Post-Op Instructions', Icons.assignment_outlined,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _postOpInstructionsController,
            hint: 'Post-procedure care instructions...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Personnel
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Personnel',
            icon: Icons.people_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _performedByController,
                      hint: 'Performed by...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _assistedByController,
                      hint: 'Assisted by...',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clinical Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Additional Notes', Icons.note_alt,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _clinicalNotesController,
            hint: 'Additional clinical notes...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Save Button
          RecordFormWidgets.buildSaveButton(
            context: context,
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Procedure' : 'Save Procedure',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: DropdownButton<String>(
            value: _procedureStatus,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            items: ['Completed', 'Cancelled', 'Partial', 'Aborted'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (v) => setState(() => _procedureStatus = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, ValueChanged<TimeOfDay> onChanged, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  time != null ? time.format(context) : '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

