import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/suggestions_service.dart';
import '../../widgets/suggestion_text_field.dart';
import 'components/record_components.dart';
import 'record_form_widgets.dart';

/// Screen for adding a General Consultation medical record
/// Refactored to use reusable components for cleaner, more maintainable code
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
  final _vitalsKey = GlobalKey<VitalsInputSectionState>();
  bool _isSaving = false;

  // Theme colors for this record type
  static const _primaryColor = Color(0xFF10B981); // Clinical Green
  static const _secondaryColor = Color(0xFF059669);
  static const _gradientColors = [_primaryColor, _secondaryColor];

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
        
        // Load vitals after build using the new component
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final bp = vitals['bp']?.toString() ?? '';
            final bpParts = bp.split('/');
            _vitalsKey.currentState?.setData(VitalsData(
              bpSystolic: bpParts.isNotEmpty && bpParts[0].isNotEmpty ? bpParts[0] : null,
              bpDiastolic: bpParts.length > 1 && bpParts[1].isNotEmpty ? bpParts[1] : null,
              heartRate: vitals['pulse']?.toString(),
              temperature: vitals['temperature']?.toString(),
              weight: vitals['weight']?.toString(),
              height: vitals['height']?.toString(),
              spO2: vitals['spo2']?.toString(),
              respiratoryRate: vitals['respiratory_rate']?.toString(),
            ));
          });
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
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    final vitals = _vitalsKey.currentState?.getData();
    return {
      'chief_complaints': _chiefComplaintsController.text,
      'history': _historyController.text,
      'examination': _examinationController.text,
      'vitals': {
        'bp': vitals?.formattedBP,
        'pulse': vitals?.heartRate,
        'temperature': vitals?.temperature,
        'weight': vitals?.weight,
        'height': vitals?.height,
        'spo2': vitals?.spO2,
        'respiratory_rate': vitals?.respiratoryRate,
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

      MedicalRecord? resultRecord;
      int? recordId;
      
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
        resultRecord = updatedRecord;
        recordId = widget.existingRecord!.id;
      } else {
        recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }

      // Also save vitals to VitalSigns table for patient history tracking
      final vitals = _vitalsKey.currentState?.getData();
      if (vitals != null && _hasAnyVitals(vitals)) {
        await _saveVitalsToPatientRecord(db, vitals, recordId);
      }

      // Create TreatmentOutcome if diagnosis or treatment is provided
      if (_diagnosisController.text.isNotEmpty || _treatmentController.text.isNotEmpty) {
        await _saveTreatmentOutcome(db, recordId);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Record updated successfully!' 
              : 'Record saved successfully!',
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

  bool _hasAnyVitals(VitalsData vitals) {
    return vitals.bpSystolic != null ||
        vitals.bpDiastolic != null ||
        vitals.heartRate != null ||
        vitals.temperature != null ||
        vitals.weight != null ||
        vitals.height != null ||
        vitals.spO2 != null ||
        vitals.respiratoryRate != null;
  }

  Future<void> _saveVitalsToPatientRecord(DoctorDatabase db, VitalsData vitals, int? recordId) async {
    double? weight = vitals.weight != null ? double.tryParse(vitals.weight!) : null;
    double? height = vitals.height != null ? double.tryParse(vitals.height!) : null;
    double? bmi;
    if (weight != null && height != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
    }

    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: _selectedPatientId!,
      recordedAt: _recordDate,
      systolicBp: Value(vitals.bpSystolic != null ? double.tryParse(vitals.bpSystolic!) : null),
      diastolicBp: Value(vitals.bpDiastolic != null ? double.tryParse(vitals.bpDiastolic!) : null),
      heartRate: Value(vitals.heartRate != null ? int.tryParse(vitals.heartRate!) : null),
      temperature: Value(vitals.temperature != null ? double.tryParse(vitals.temperature!) : null),
      respiratoryRate: Value(vitals.respiratoryRate != null ? int.tryParse(vitals.respiratoryRate!) : null),
      oxygenSaturation: Value(vitals.spO2 != null ? double.tryParse(vitals.spO2!) : null),
      weight: Value(weight),
      height: Value(height),
      bmi: Value(bmi),
      notes: Value('Recorded during general consultation'),
    ));
  }

  Future<void> _saveTreatmentOutcome(DoctorDatabase db, int? recordId) async {
    await db.insertTreatmentOutcome(TreatmentOutcomesCompanion.insert(
      patientId: _selectedPatientId!,
      medicalRecordId: Value(recordId),
      treatmentType: 'combination',
      treatmentDescription: _treatmentController.text.isNotEmpty 
          ? _treatmentController.text 
          : 'General consultation treatment',
      providerType: const Value('primary_care'),
      providerName: const Value(''),
      diagnosis: Value(_diagnosisController.text),
      startDate: _recordDate,
      outcome: const Value('ongoing'),
      notes: Value(_doctorNotesController.text),
    ));
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
                      Icons.medical_services_rounded,
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
                              ? 'Edit Record' 
                              : 'General Consultation',
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
                  label: 'Record Date',
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

          // Chief Complaints
          RecordFormSection(
            title: 'Chief Complaints',
            icon: Icons.sick_outlined,
            accentColor: Colors.orange,
            child: SuggestionTextField(
              controller: _chiefComplaintsController,
              label: 'Chief Complaints',
              hint: 'Describe presenting complaints...',
              prefixIcon: Icons.sick_outlined,
              maxLines: 4,
              suggestions: MedicalSuggestions.chiefComplaints,
            ),
          ),
          const SizedBox(height: 16),

          // History
          RecordFormSection(
            title: 'Medical History',
            icon: Icons.history,
            accentColor: Colors.blue,
            collapsible: true,
            child: RecordTextField(
              controller: _historyController,
              hint: 'Relevant medical history...',
              maxLines: 4,
              accentColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Vitals Section - Using new VitalsInputSection component
          RecordFormSection(
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: Colors.red,
            child: VitalsInputSection(
              key: _vitalsKey,
              accentColor: Colors.red,
              compact: true,
            ),
          ),
          const SizedBox(height: 16),

          // Examination
          RecordFormSection(
            title: 'Physical Examination',
            icon: Icons.accessibility_new,
            accentColor: Colors.purple,
            collapsible: true,
            child: RecordTextField(
              controller: _examinationController,
              hint: 'Physical examination findings...',
              maxLines: 4,
              accentColor: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),

          // Diagnosis
          RecordFormSection(
            title: 'Diagnosis',
            icon: Icons.medical_information,
            accentColor: Colors.teal,
            child: SuggestionTextField(
              controller: _diagnosisController,
              label: 'Diagnosis',
              hint: 'Enter diagnosis...',
              prefixIcon: Icons.medical_information_outlined,
              maxLines: 3,
              suggestions: MedicalSuggestions.diagnoses,
            ),
          ),
          const SizedBox(height: 16),

          // Treatment Plan
          RecordFormSection(
            title: 'Treatment Plan',
            icon: Icons.healing,
            accentColor: _primaryColor,
            child: SuggestionTextField(
              controller: _treatmentController,
              label: 'Treatment',
              hint: 'Enter treatment plan...',
              prefixIcon: Icons.healing_outlined,
              maxLines: 4,
              suggestions: PrescriptionSuggestions.instructions,
              separator: '\n',
            ),
          ),
          const SizedBox(height: 16),

          // Doctor's Notes
          RecordFormSection(
            title: "Doctor's Notes",
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: false,
            child: RecordNotesField(
              controller: _doctorNotesController,
              label: '',
              hint: 'Additional notes, observations, follow-up instructions...',
              accentColor: Colors.indigo,
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons - Using new component
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Record' : 'Save Record',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
