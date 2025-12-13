import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import 'components/patient_selector_card.dart';

/// Common referral specialties
final _referralSpecialties = [
  'Cardiology',
  'Pulmonology',
  'Gastroenterology',
  'Neurology',
  'Orthopedics',
  'Psychiatry',
  'Dermatology',
  'Ophthalmology',
  'ENT',
  'Urology',
  'Nephrology',
  'Endocrinology',
  'Oncology',
  'Rheumatology',
  'General Surgery',
  'Pediatrics',
  'Gynecology',
  'Physical Therapy',
  'Radiology',
  'Pathology',
  'Other',
];

/// Urgency levels for referrals
enum ReferralUrgency {
  routine,
  urgent,
  emergency,
}

extension ReferralUrgencyExtension on ReferralUrgency {
  String get displayName {
    switch (this) {
      case ReferralUrgency.routine:
        return 'Routine';
      case ReferralUrgency.urgent:
        return 'Urgent';
      case ReferralUrgency.emergency:
        return 'Emergency';
    }
  }

  Color get color {
    switch (this) {
      case ReferralUrgency.routine:
        return Colors.green;
      case ReferralUrgency.urgent:
        return Colors.orange;
      case ReferralUrgency.emergency:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ReferralUrgency.routine:
        return Icons.schedule;
      case ReferralUrgency.urgent:
        return Icons.priority_high;
      case ReferralUrgency.emergency:
        return Icons.emergency;
    }
  }
}

/// Screen for creating referral letters
class AddReferralScreen extends ConsumerStatefulWidget {
  const AddReferralScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddReferralScreen> createState() => _AddReferralScreenState();
}

class _AddReferralScreenState extends ConsumerState<AddReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Theme colors
  static const _primaryColor = Color(0xFF06B6D4);
  static const _secondaryColor = Color(0xFF0891B2);

  // Form fields
  int? _selectedPatientId;
  DateTime _referralDate = DateTime.now();
  String? _selectedSpecialty;
  ReferralUrgency _urgency = ReferralUrgency.routine;

  final _referToController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _reasonController = TextEditingController();
  final _clinicalSummaryController = TextEditingController();
  final _investigationsController = TextEditingController();
  final _currentTreatmentController = TextEditingController();
  final _specificQuestionsController = TextEditingController();
  final _notesController = TextEditingController();

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
    _referralDate = record.recordDate;
    _notesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _selectedSpecialty = data['specialty'] as String?;
        _referToController.text = (data['refer_to'] as String?) ?? '';
        _hospitalController.text = (data['hospital'] as String?) ?? '';
        _reasonController.text = (data['reason'] as String?) ?? '';
        _clinicalSummaryController.text = (data['clinical_summary'] as String?) ?? '';
        _investigationsController.text = (data['investigations'] as String?) ?? '';
        _currentTreatmentController.text = (data['current_treatment'] as String?) ?? '';
        _specificQuestionsController.text = (data['specific_questions'] as String?) ?? '';
        
        final urgencyStr = data['urgency'] as String?;
        if (urgencyStr != null) {
          _urgency = ReferralUrgency.values.firstWhere(
            (u) => u.name == urgencyStr,
            orElse: () => ReferralUrgency.routine,
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _referToController.dispose();
    _hospitalController.dispose();
    _reasonController.dispose();
    _clinicalSummaryController.dispose();
    _investigationsController.dispose();
    _currentTreatmentController.dispose();
    _specificQuestionsController.dispose();
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
    if (_selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specialty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final dataJson = jsonEncode({
        'specialty': _selectedSpecialty,
        'refer_to': _referToController.text,
        'hospital': _hospitalController.text,
        'reason': _reasonController.text,
        'clinical_summary': _clinicalSummaryController.text,
        'investigations': _investigationsController.text,
        'current_treatment': _currentTreatmentController.text,
        'specific_questions': _specificQuestionsController.text,
        'urgency': _urgency.name,
      });

      final referTo = _referToController.text.isNotEmpty 
          ? _referToController.text 
          : _selectedSpecialty;
      final title = 'Referral to $referTo - ${DateFormat('MMM d, yyyy').format(_referralDate)}';

      if (widget.existingRecord != null) {
        await db.updateMedicalRecord(
          MedicalRecord(
            id: widget.existingRecord!.id,
            patientId: widget.existingRecord!.patientId,
            recordType: 'referral',
            title: title,
            description: '',
            dataJson: dataJson,
            diagnosis: '',
            treatment: '',
            doctorNotes: _notesController.text,
            recordDate: _referralDate,
            createdAt: widget.existingRecord!.createdAt,
          ),
        );
      } else {
        await db.insertMedicalRecord(
          MedicalRecordsCompanion.insert(
            patientId: _selectedPatientId!,
            recordType: 'referral',
            title: title,
            dataJson: Value(dataJson),
            doctorNotes: Value(_notesController.text),
            recordDate: _referralDate,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null 
                ? 'Referral updated' 
                : 'Referral saved'),
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
        title: Text(widget.existingRecord != null ? 'Edit Referral' : 'Referral Letter'),
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
              _buildPatientInfoCard(widget.preselectedPatient!, isDark)
            else
              PatientSelectorCard(
                selectedPatientId: _selectedPatientId,
                onPatientSelected: (patient) {
                  setState(() => _selectedPatientId = patient?.id);
                },
              ),
            const SizedBox(height: 16),

            // Specialty Selection
            _buildSpecialtySelector(isDark),
            const SizedBox(height: 16),

            // Urgency Selection
            _buildUrgencySelector(isDark),
            const SizedBox(height: 16),

            // Date Selection
            _buildDateCard(isDark),
            const SizedBox(height: 16),

            // Refer To (Doctor/Hospital)
            _buildSectionCard(
              isDark: isDark,
              title: 'Refer To',
              icon: Icons.person,
              child: Column(
                children: [
                  TextFormField(
                    controller: _referToController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Name (optional)',
                      hintText: 'Dr. Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hospitalController,
                    decoration: InputDecoration(
                      labelText: 'Hospital/Clinic (optional)',
                      hintText: 'Hospital name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      prefixIcon: const Icon(Icons.local_hospital_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason for Referral
            _buildSectionCard(
              isDark: isDark,
              title: 'Reason for Referral',
              icon: Icons.help_outline,
              child: TextFormField(
                controller: _reasonController,
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Please enter reason' : null,
                decoration: InputDecoration(
                  hintText: 'Why is this patient being referred?',
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

            // Clinical Summary
            _buildSectionCard(
              isDark: isDark,
              title: 'Clinical Summary',
              icon: Icons.summarize,
              child: TextFormField(
                controller: _clinicalSummaryController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Brief history, examination findings, current diagnosis...',
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

            // Investigations Done
            _buildSectionCard(
              isDark: isDark,
              title: 'Investigations Done',
              icon: Icons.science,
              child: TextFormField(
                controller: _investigationsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'List any tests/imaging already performed...',
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

            // Current Treatment
            _buildSectionCard(
              isDark: isDark,
              title: 'Current Treatment',
              icon: Icons.medication,
              child: TextFormField(
                controller: _currentTreatmentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Current medications and treatment...',
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

            // Specific Questions
            _buildSectionCard(
              isDark: isDark,
              title: 'Specific Questions',
              icon: Icons.quiz,
              subtitle: 'Questions you\'d like answered',
              child: TextFormField(
                controller: _specificQuestionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any specific questions for the specialist?',
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
              subtitle: 'Not included in referral letter',
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
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
                        : const Text('Save Referral'),
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

  Widget _buildPatientInfoCard(Patient patient, bool isDark) {
    final fullName = '${patient.firstName} ${patient.lastName}'.trim();
    final initials = '${patient.firstName.isNotEmpty ? patient.firstName[0] : ''}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}'.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _primaryColor.withValues(alpha: 0.1),
            child: Text(
              initials.isNotEmpty ? initials : 'P',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'Unknown Patient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (patient.age != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Age: ${patient.age} years',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtySelector(bool isDark) {
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
                child: Icon(Icons.medical_services, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Referral Specialty *',
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
            children: _referralSpecialties.map((specialty) {
              final isSelected = _selectedSpecialty == specialty;
              return FilterChip(
                selected: isSelected,
                label: Text(specialty),
                onSelected: (selected) {
                  setState(() {
                    _selectedSpecialty = selected ? specialty : null;
                  });
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

  Widget _buildUrgencySelector(bool isDark) {
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
                  color: _urgency.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_urgency.icon, color: _urgency.color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Urgency Level',
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
            children: ReferralUrgency.values.map((urgency) {
              final isSelected = _urgency == urgency;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: urgency != ReferralUrgency.emergency ? 8 : 0,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _urgency = urgency),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? urgency.color.withValues(alpha: 0.15)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? urgency.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            urgency.icon,
                            color: isSelected ? urgency.color : (isDark ? Colors.white54 : Colors.grey),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            urgency.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected 
                                  ? urgency.color 
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                  'Referral Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_referralDate),
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
                initialDate: _referralDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() => _referralDate = date);
              }
            },
            icon: Icon(Icons.edit_calendar, color: _primaryColor),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF generation will be implemented'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
