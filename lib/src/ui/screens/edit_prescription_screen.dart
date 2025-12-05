import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';

class EditPrescriptionScreen extends ConsumerStatefulWidget {
  const EditPrescriptionScreen({
    super.key,
    required this.prescription,
    this.patient,
  });

  final Prescription prescription;
  final Patient? patient;

  @override
  ConsumerState<EditPrescriptionScreen> createState() => _EditPrescriptionScreenState();
}

class _EditPrescriptionScreenState extends ConsumerState<EditPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Diagnosis
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();

  // Medications List
  final List<_MedicationEntry> _medications = [];

  // Additional Notes
  final _instructionsController = TextEditingController();

  bool _isSaving = false;
  bool _isRefillable = false;

  @override
  void initState() {
    super.initState();
    _loadPrescriptionData();
  }

  void _loadPrescriptionData() {
    // Load existing prescription data
    _diagnosisController.text = widget.prescription.diagnosis;
    _symptomsController.text = widget.prescription.chiefComplaint;
    _instructionsController.text = widget.prescription.instructions;
    _isRefillable = widget.prescription.isRefillable;

    // Parse medications from JSON
    try {
      final items = jsonDecode(widget.prescription.itemsJson);
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final entry = _MedicationEntry();
            entry.nameController.text = item['name']?.toString() ?? '';
            entry.dosageController.text = item['dosage']?.toString() ?? '';
            entry.frequency = item['frequency']?.toString() ?? 'OD';
            entry.durationController.text = item['duration']?.toString() ?? '';
            entry.timing = item['timing']?.toString() ?? 'After Food';
            entry.instructionsController.text = item['instructions']?.toString() ?? '';
            _medications.add(entry);
          }
        }
      }
    } catch (e) {
      // If parsing fails, add one empty entry
      _medications.add(_MedicationEntry());
    }

    // Ensure at least one medication entry
    if (_medications.isEmpty) {
      _medications.add(_MedicationEntry());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _instructionsController.dispose();
    for (final med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildModernSliverAppBar(context, isDark),
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Patient Info Card
                  if (widget.patient != null) _buildPatientCard(context, isDark),
                  if (widget.patient != null) const SizedBox(height: 16),

                  // Diagnosis Section
                  _buildModernSectionCard(
                    title: 'Diagnosis',
                    icon: Icons.medical_information_rounded,
                    iconColor: const Color(0xFF6366F1),
                    isDark: isDark,
                    child: Column(
                      children: [
                        SuggestionTextField(
                          controller: _symptomsController,
                          label: 'Chief Complaint',
                          hint: 'Enter symptoms...',
                          suggestions: MedicalSuggestions.chiefComplaints,
                        ),
                        const SizedBox(height: 16),
                        SuggestionTextField(
                          controller: _diagnosisController,
                          label: 'Diagnosis',
                          hint: 'Enter diagnosis...',
                          suggestions: MedicalSuggestions.diagnoses,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medications Section
                  _buildModernSectionCard(
                    title: 'Medications',
                    icon: Icons.medication_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    trailing: _buildAddMedicationButton(context),
                    child: _buildMedicationsList(context, isDark),
                  ),
                  const SizedBox(height: 16),

                  // Instructions Section
                  _buildModernSectionCard(
                    title: 'Instructions',
                    icon: Icons.note_alt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _instructionsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Additional instructions for the patient...',
                            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        _buildRefillableToggle(context, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  _buildModernSaveButton(context, isDark),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => _confirmDelete(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [Colors.white, const Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Prescription',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${DateFormat('MMM d, yyyy').format(widget.prescription.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
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

  Widget _buildPatientCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.patient!.firstName} ${widget.patient!.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.patient!.phone.isNotEmpty)
                  Text(
                    widget.patient!.phone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicationButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _medications.add(_MedicationEntry());
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: const Color(0xFF10B981), size: 16),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList(BuildContext context, bool isDark) {
    return Column(
      children: [
        for (int i = 0; i < _medications.length; i++)
          _buildMedicationCard(context, isDark, i),
      ],
    );
  }

  Widget _buildMedicationCard(BuildContext context, bool isDark, int index) {
    final med = _medications[index];
    return Container(
      margin: EdgeInsets.only(bottom: index < _medications.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number and delete button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Med ${index + 1}',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (_medications.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _medications[index].dispose();
                      _medications.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded, color: AppColors.error, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Medicine Name
          SuggestionTextField(
            controller: med.nameController,
            label: 'Medicine Name',
            hint: 'e.g., Paracetamol',
            suggestions: PrescriptionSuggestions.medications,
          ),
          const SizedBox(height: 12),

          // Dosage and Duration row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: med.dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g., 500mg',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: med.durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    hintText: 'e.g., 5 days',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Frequency selector
          Text(
            'Frequency',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['OD', 'BD', 'TDS', 'QID', 'SOS', 'HS'].map((freq) {
              final isSelected = med.frequency == freq;
              return GestureDetector(
                onTap: () => setState(() => med.frequency = freq),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    freq,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.grey : Colors.grey[600]),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Timing selector
          Text(
            'Timing',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Before Food', 'After Food', 'With Food', 'Empty Stomach'].map((timing) {
              final isSelected = med.timing == timing;
              return GestureDetector(
                onTap: () => setState(() => med.timing = timing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    timing,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.grey : Colors.grey[600]),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
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

  Widget _buildRefillableToggle(BuildContext context, bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.refresh_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Refillable Prescription',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: _isRefillable,
          onChanged: (value) => setState(() => _isRefillable = value),
          activeColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildModernSaveButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePrescription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one medication has a name
    final hasValidMed = _medications.any((med) => med.nameController.text.isNotEmpty);
    if (!hasValidMed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add at least one medication'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);

      // Build medications JSON
      final medicationsJson = jsonEncode(
        _medications
            .where((med) => med.nameController.text.isNotEmpty)
            .map((med) => med.toJson())
            .toList(),
      );

      final updatedPrescription = PrescriptionsCompanion(
        id: Value(widget.prescription.id),
        patientId: Value(widget.prescription.patientId),
        createdAt: Value(widget.prescription.createdAt),
        itemsJson: Value(medicationsJson),
        instructions: Value(_instructionsController.text),
        isRefillable: Value(_isRefillable),
        appointmentId: Value(widget.prescription.appointmentId),
        medicalRecordId: Value(widget.prescription.medicalRecordId),
        diagnosis: Value(_diagnosisController.text),
        chiefComplaint: Value(_symptomsController.text),
        vitalsJson: Value(widget.prescription.vitalsJson),
      );

      await db.updatePrescription(updatedPrescription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Prescription updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Prescription'),
          ],
        ),
        content: const Text('Are you sure you want to delete this prescription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        await db.deletePrescription(widget.prescription.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Prescription deleted'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

// Medication Entry Class for edit screen
class _MedicationEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  String frequency = 'OD';
  String timing = 'After Food';

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'dosage': dosageController.text,
      'frequency': frequency,
      'duration': durationController.text,
      'timing': timing,
      'instructions': instructionsController.text,
    };
  }
}
