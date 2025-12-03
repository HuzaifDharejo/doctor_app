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

/// Screen for adding a General Consultation medical record
class AddGeneralRecordScreen extends ConsumerStatefulWidget {
  const AddGeneralRecordScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddGeneralRecordScreen> createState() => _AddGeneralRecordScreenState();
}

class _AddGeneralRecordScreenState extends ConsumerState<AddGeneralRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();
  final _titleController = TextEditingController();

  // General consultation specific fields
  final _chiefComplaintsController = TextEditingController();
  final _historyController = TextEditingController();
  final _examinationController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _doctorNotesController = TextEditingController();

  // Vitals
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();

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
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatment ?? '';
    _doctorNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _chiefComplaintsController.text = (data['chief_complaints'] as String?) ?? '';
        _historyController.text = (data['history'] as String?) ?? '';
        _examinationController.text = (data['examination'] as String?) ?? '';
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpController.text = (vitals['bp'] as String?) ?? '';
          _pulseController.text = (vitals['pulse'] as String?) ?? '';
          _tempController.text = (vitals['temperature'] as String?) ?? '';
          _weightController.text = (vitals['weight'] as String?) ?? '';
          _heightController.text = (vitals['height'] as String?) ?? '';
          _spo2Controller.text = (vitals['spo2'] as String?) ?? '';
          _respiratoryRateController.text = (vitals['respiratory_rate'] as String?) ?? '';
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _chiefComplaintsController.dispose();
    _historyController.dispose();
    _examinationController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _doctorNotesController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _spo2Controller.dispose();
    _respiratoryRateController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaints': _chiefComplaintsController.text,
      'history': _historyController.text,
      'examination': _examinationController.text,
      'vitals': {
        'bp': _bpController.text.isNotEmpty ? _bpController.text : null,
        'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null,
        'temperature': _tempController.text.isNotEmpty ? _tempController.text : null,
        'weight': _weightController.text.isNotEmpty ? _weightController.text : null,
        'height': _heightController.text.isNotEmpty ? _heightController.text : null,
        'spo2': _spo2Controller.text.isNotEmpty ? _spo2Controller.text : null,
        'respiratory_rate': _respiratoryRateController.text.isNotEmpty 
            ? _respiratoryRateController.text : null,
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
        recordType: 'general',
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : 'General Consultation',
        description: Value(_chiefComplaintsController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_doctorNotesController.text),
        recordDate: _recordDate,
      );

      if (widget.existingRecord != null) {
        // Create a full record with the existing ID for update
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'general',
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'General Consultation',
          description: _chiefComplaintsController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
          doctorNotes: _doctorNotesController.text,
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
              ? 'Record updated successfully!' 
              : 'Record saved successfully!',
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
                    ? 'Edit General Record' 
                    : 'General Consultation',
                subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                icon: Icons.medical_services_rounded,
                gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)], // Clinical Green
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
            context, 'Record Date', Icons.calendar_today,
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

          // Chief Complaints
          RecordFormWidgets.buildSectionHeader(
            context, 'Chief Complaints', Icons.sick_outlined,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _chiefComplaintsController,
            label: 'Chief Complaints',
            hint: 'Describe presenting complaints...',
            prefixIcon: Icons.sick_outlined,
            maxLines: 4,
            suggestions: MedicalSuggestions.chiefComplaints,
          ),
          const SizedBox(height: 20),

          // History
          RecordFormWidgets.buildSectionHeader(
            context, 'History', Icons.history,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _historyController,
            hint: 'Relevant medical history...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Vitals Section
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _bpController,
                      label: 'BP',
                      unit: 'mmHg',
                      hint: '120/80',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _pulseController,
                      label: 'Pulse',
                      unit: 'bpm',
                      hint: '72',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _tempController,
                      label: 'Temp',
                      unit: '°F',
                      hint: '98.6',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _spo2Controller,
                      label: 'SpO₂',
                      unit: '%',
                      hint: '98',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _weightController,
                      label: 'Weight',
                      unit: 'kg',
                      hint: '70',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _heightController,
                      label: 'Height',
                      unit: 'cm',
                      hint: '170',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildVitalField(
                context: context,
                controller: _respiratoryRateController,
                label: 'RR',
                unit: '/min',
                hint: '16',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Examination
          RecordFormWidgets.buildSectionHeader(
            context, 'Physical Examination', Icons.accessibility_new,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _examinationController,
            hint: 'Physical examination findings...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Diagnosis
          RecordFormWidgets.buildSectionHeader(
            context, 'Diagnosis', Icons.medical_information,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _diagnosisController,
            label: 'Diagnosis',
            hint: 'Enter diagnosis...',
            prefixIcon: Icons.medical_information_outlined,
            maxLines: 3,
            suggestions: MedicalSuggestions.diagnoses,
          ),
          const SizedBox(height: 20),

          // Treatment Plan
          RecordFormWidgets.buildSectionHeader(
            context, 'Treatment Plan', Icons.healing,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _treatmentController,
            label: 'Treatment',
            hint: 'Enter treatment plan...',
            prefixIcon: Icons.healing_outlined,
            maxLines: 4,
            suggestions: PrescriptionSuggestions.instructions,
            separator: '\n',
          ),
          const SizedBox(height: 20),

          // Doctor's Notes
          RecordFormWidgets.buildSectionHeader(
            context, "Doctor's Notes", Icons.note_alt,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _doctorNotesController,
            hint: 'Additional notes...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Save Button
          RecordFormWidgets.buildSaveButton(
            context: context,
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Record' : 'Save Record',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)], // Clinical Green
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
