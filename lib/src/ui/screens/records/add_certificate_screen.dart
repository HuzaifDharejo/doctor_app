import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import 'components/patient_selector_card.dart';

/// Types of medical certificates
enum CertificateType {
  sickLeave,
  fitnessCertificate,
  medicalClearance,
  disabilityCertificate,
  travelFitness,
  schoolAbsence,
  sportsParticipation,
  workFitness,
  custom,
}

extension CertificateTypeExtension on CertificateType {
  String get displayName {
    switch (this) {
      case CertificateType.sickLeave:
        return 'Sick Leave Certificate';
      case CertificateType.fitnessCertificate:
        return 'Fitness Certificate';
      case CertificateType.medicalClearance:
        return 'Medical Clearance';
      case CertificateType.disabilityCertificate:
        return 'Disability Certificate';
      case CertificateType.travelFitness:
        return 'Travel Fitness Certificate';
      case CertificateType.schoolAbsence:
        return 'School Absence Certificate';
      case CertificateType.sportsParticipation:
        return 'Sports Participation Certificate';
      case CertificateType.workFitness:
        return 'Work Fitness Certificate';
      case CertificateType.custom:
        return 'Custom Certificate';
    }
  }

  IconData get icon {
    switch (this) {
      case CertificateType.sickLeave:
        return Icons.sick;
      case CertificateType.fitnessCertificate:
        return Icons.fitness_center;
      case CertificateType.medicalClearance:
        return Icons.verified;
      case CertificateType.disabilityCertificate:
        return Icons.accessible;
      case CertificateType.travelFitness:
        return Icons.flight;
      case CertificateType.schoolAbsence:
        return Icons.school;
      case CertificateType.sportsParticipation:
        return Icons.sports;
      case CertificateType.workFitness:
        return Icons.work;
      case CertificateType.custom:
        return Icons.description;
    }
  }

  String getTemplateContent(String patientName, String doctorName) {
    final date = DateFormat('MMMM d, yyyy').format(DateTime.now());
    switch (this) {
      case CertificateType.sickLeave:
        return '''This is to certify that $patientName was examined on $date and is advised to rest due to medical reasons.

Period of Leave: [FROM_DATE] to [TO_DATE]

The patient is unfit for work/duty during this period.

Diagnosis: [DIAGNOSIS]

This certificate is issued upon the request of the patient for official purposes.''';

      case CertificateType.fitnessCertificate:
        return '''This is to certify that $patientName has been examined on $date and found to be in good health.

The patient is fit for:
[ ] General duties
[ ] Physical work
[ ] Travel
[ ] Other: ____________

No medical condition was found that would prevent normal activities.''';

      case CertificateType.medicalClearance:
        return '''This is to certify that $patientName has been medically examined on $date.

Based on the examination and available medical history, the patient is cleared for:
[ ] Surgery/Procedure: ____________
[ ] Employment
[ ] Educational admission
[ ] Other: ____________

Relevant findings: [FINDINGS]''';

      case CertificateType.disabilityCertificate:
        return '''This is to certify that $patientName has been examined and found to have the following condition:

Diagnosis: [DIAGNOSIS]

Nature of Disability: [DESCRIPTION]

Degree of Disability: [PERCENTAGE]%

Duration: [ ] Temporary [ ] Permanent

This certificate is issued for official/medical purposes.''';

      case CertificateType.travelFitness:
        return '''This is to certify that $patientName has been examined on $date and is fit to travel.

Mode of Travel: [ ] Air [ ] Land [ ] Sea
Destination: ____________
Duration: ____________

The patient has no medical condition that contraindicates travel.

Special precautions if any: [PRECAUTIONS]''';

      case CertificateType.schoolAbsence:
        return '''This is to certify that $patientName was under my medical care from [FROM_DATE] to [TO_DATE].

Reason: [DIAGNOSIS]

The student was unable to attend school during this period due to medical reasons.

The student is now fit to resume school activities.''';

      case CertificateType.sportsParticipation:
        return '''This is to certify that $patientName has been medically examined on $date.

The patient is fit to participate in:
[ ] General sports activities
[ ] Competitive sports
[ ] Specific sport: ____________

No cardiovascular, respiratory, or musculoskeletal conditions were found that would prevent sports participation.

Recommendations: [RECOMMENDATIONS]''';

      case CertificateType.workFitness:
        return '''This is to certify that $patientName has been examined on $date.

The patient is fit to resume work/duty:
[ ] Without restrictions
[ ] With modifications: ____________

Previous condition: [CONDITION]
Current status: [STATUS]

Expected duration of restrictions if any: [DURATION]''';

      case CertificateType.custom:
        return '''This is to certify that $patientName has been examined on $date.

[CERTIFICATE_CONTENT]

This certificate is issued upon request for official purposes.''';
    }
  }
}

/// Screen for creating medical certificates
class AddCertificateScreen extends ConsumerStatefulWidget {
  const AddCertificateScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddCertificateScreen> createState() => _AddCertificateScreenState();
}

class _AddCertificateScreenState extends ConsumerState<AddCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Theme colors
  static const _primaryColor = Color(0xFF8B5CF6);
  static const _secondaryColor = Color(0xFF7C3AED);

  // Form fields
  int? _selectedPatientId;
  DateTime _certificateDate = DateTime.now();
  CertificateType _selectedType = CertificateType.sickLeave;
  
  final _contentController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Date range for sick leave
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      _updateTemplateContent();
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _certificateDate = record.recordDate;
    _notesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        final typeStr = data['certificate_type'] as String?;
        if (typeStr != null) {
          _selectedType = CertificateType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => CertificateType.custom,
          );
        }
        _contentController.text = (data['content'] as String?) ?? '';
        _diagnosisController.text = (data['diagnosis'] as String?) ?? '';
        if (data['from_date'] != null) {
          _fromDate = DateTime.tryParse(data['from_date'] as String);
        }
        if (data['to_date'] != null) {
          _toDate = DateTime.tryParse(data['to_date'] as String);
        }
      } catch (_) {}
    }
  }

  void _updateTemplateContent() {
    final patientName = widget.preselectedPatient != null
        ? '${widget.preselectedPatient!.firstName} ${widget.preselectedPatient!.lastName}'
        : '[Patient Name]';
    final profile = ref.read(doctorSettingsProvider).profile;
    final doctorName = profile.name.isNotEmpty ? profile.name : '[Doctor Name]';
    
    _contentController.text = _selectedType.getTemplateContent(patientName, doctorName);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final dataJson = jsonEncode({
        'certificate_type': _selectedType.name,
        'content': _contentController.text,
        'diagnosis': _diagnosisController.text,
        'from_date': _fromDate?.toIso8601String(),
        'to_date': _toDate?.toIso8601String(),
      });

      final title = '${_selectedType.displayName} - ${DateFormat('MMM d, yyyy').format(_certificateDate)}';

      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'certificate',
          title: title,
          description: '',
          dataJson: dataJson,
          diagnosis: '',
          treatment: '',
          doctorNotes: _notesController.text,
          recordDate: _certificateDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
      } else {
        await db.insertMedicalRecord(
          MedicalRecordsCompanion.insert(
            patientId: _selectedPatientId!,
            recordType: 'certificate',
            title: title,
            dataJson: Value(dataJson),
            doctorNotes: Value(_notesController.text),
            recordDate: _certificateDate,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null 
                ? 'Certificate updated' 
                : 'Certificate saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.existingRecord != null ? 'Edit Certificate' : 'Medical Certificate'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(),
            tooltip: 'Generate PDF',
          ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRecord,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Selection
            if (widget.preselectedPatient != null)
              _buildPatientInfoCard(isDark)
            else
              FutureBuilder<DoctorDatabase>(
                future: ref.read(doctorDbProvider.future),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PatientSelectorCard(
                    db: snapshot.data,
                    selectedPatientId: _selectedPatientId,
                    onPatientSelected: (patient) {
                      setState(() {
                        _selectedPatientId = patient?.id;
                        _updateTemplateContent();
                      });
                    },
                    label: 'Select Patient',
                  );
                },
              ),
            const SizedBox(height: 16),

            // Certificate Type Selection
            _buildCertificateTypeSelector(isDark),
            const SizedBox(height: 16),

            // Date Selection
            _buildDateCard(isDark),
            const SizedBox(height: 16),

            // Date Range (for sick leave)
            if (_selectedType == CertificateType.sickLeave ||
                _selectedType == CertificateType.schoolAbsence)
              ...[
                _buildDateRangeCard(isDark),
                const SizedBox(height: 16),
              ],

            // Diagnosis
            _buildSectionCard(
              isDark: isDark,
              title: 'Diagnosis / Reason',
              icon: Icons.medical_information,
              child: TextFormField(
                controller: _diagnosisController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter diagnosis or reason...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Certificate Content
            _buildSectionCard(
              isDark: isDark,
              title: 'Certificate Content',
              icon: Icons.description,
              child: TextFormField(
                controller: _contentController,
                maxLines: 12,
                validator: (v) => v?.isEmpty ?? true ? 'Content is required' : null,
                decoration: InputDecoration(
                  hintText: 'Certificate content...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Internal Notes
            _buildSectionCard(
              isDark: isDark,
              title: 'Internal Notes',
              icon: Icons.note,
              subtitle: 'Not included in certificate',
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes for your records...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generatePdf(),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Certificate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Certificate Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CertificateType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected ? Colors.white : _primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(type.displayName),
                  ],
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = type;
                      _updateTemplateContent();
                    });
                  }
                },
                selectedColor: _primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 12,
                ),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_certificateDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _certificateDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _certificateDate = date);
              }
            },
            icon: Icon(Icons.edit_calendar, color: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.date_range, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Leave Period',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  isDark: isDark,
                  label: 'From',
                  date: _fromDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _fromDate = date);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: isDark ? Colors.white38 : Colors.grey),
              ),
              Expanded(
                child: _buildDateButton(
                  isDark: isDark,
                  label: 'To',
                  date: _toDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
                      firstDate: _fromDate ?? DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _toDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          if (_fromDate != null && _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Duration: ${_toDate!.difference(_fromDate!).inDays + 1} day(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: _primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required bool isDark,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMM d, yyyy').format(date) : 'Select date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(bool isDark) {
    final patient = widget.preselectedPatient!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                patient.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient.firstName} ${patient.lastName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Creating certificate',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first')),
      );
      return;
    }

    try {
      final db = await ref.read(doctorDbProvider.future);
      final patient = await db.getPatientById(_selectedPatientId!);
      if (patient == null) return;

      final profile = ref.read(doctorSettingsProvider).profile;

      // For now, show a simple message - you can integrate with your existing PDF service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generation will be implemented'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
