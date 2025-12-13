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

class EditMedicalRecordScreen extends ConsumerStatefulWidget {
  const EditMedicalRecordScreen({
    super.key,
    required this.record,
    this.patient,
  });

  final MedicalRecord record;
  final Patient? patient;

  @override
  ConsumerState<EditMedicalRecordScreen> createState() => _EditMedicalRecordScreenState();
}

class _EditMedicalRecordScreenState extends ConsumerState<EditMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  late DateTime _recordDate;
  late String _recordType;
  final _descriptionController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _doctorNotesController = TextEditingController();

  // Additional data stored in JSON
  Map<String, dynamic> _additionalData = {};

  final Map<String, String> _recordTypeLabels = {
    'general': 'General Consultation',
    'pulmonary_evaluation': 'Pulmonary Evaluation',
    'psychiatric_assessment': 'Psychiatric Assessment',
    'lab_result': 'Lab Result',
    'imaging': 'Imaging/Radiology',
    'procedure': 'Procedure',
    'follow_up': 'Follow-up Visit',
  };

  final Map<String, IconData> _recordTypeIcons = {
    'general': Icons.medical_services_outlined,
    'pulmonary_evaluation': Icons.air_rounded,
    'psychiatric_assessment': Icons.psychology_outlined,
    'lab_result': Icons.science_outlined,
    'imaging': Icons.image_outlined,
    'procedure': Icons.local_hospital_outlined,
    'follow_up': Icons.event_repeat_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadRecordData();
  }

  Future<void> _loadRecordData() async {
    _recordDate = widget.record.recordDate;
    _recordType = widget.record.recordType;
    _descriptionController.text = widget.record.description;
    _diagnosisController.text = widget.record.diagnosis;
    _treatmentController.text = widget.record.treatment;
    _doctorNotesController.text = widget.record.doctorNotes;

    // V6: Load additional data from normalized table with fallback
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(widget.record.id);
    if (mounted) {
      setState(() {
        _additionalData = data;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _doctorNotesController.dispose();
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

                  // Record Type Info
                  _buildRecordTypeCard(context, isDark),
                  const SizedBox(height: 16),

                  // Date Section
                  _buildModernSectionCard(
                    title: 'Record Date',
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    isDark: isDark,
                    child: _buildDateSelector(context, isDark),
                  ),
                  const SizedBox(height: 16),

                  // Title and Description
                  _buildModernSectionCard(
                    title: 'Record Details',
                    icon: Icons.description_rounded,
                    iconColor: const Color(0xFF6366F1),
                    isDark: isDark,
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration('Description', 'Enter description...', isDark),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Diagnosis Section
                  _buildModernSectionCard(
                    title: 'Diagnosis & Treatment',
                    icon: Icons.medical_information_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    child: Column(
                      children: [
                        SuggestionTextField(
                          controller: _diagnosisController,
                          label: 'Diagnosis',
                          hint: 'Enter diagnosis...',
                          suggestions: MedicalSuggestions.diagnoses,
                        ),
                        const SizedBox(height: 16),
                        SuggestionTextField(
                          controller: _treatmentController,
                          label: 'Treatment',
                          hint: 'Enter treatment plan...',
                          suggestions: PrescriptionSuggestions.medications,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Additional Data Section (if any)
                  if (_additionalData.isNotEmpty)
                    _buildAdditionalDataSection(context, isDark),
                  if (_additionalData.isNotEmpty) const SizedBox(height: 16),

                  // Doctor Notes Section
                  _buildModernSectionCard(
                    title: 'Doctor Notes',
                    icon: Icons.note_alt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    isDark: isDark,
                    child: TextFormField(
                      controller: _doctorNotesController,
                      maxLines: 4,
                      decoration: _inputDecoration('Notes', 'Add clinical notes...', isDark),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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

  InputDecoration _inputDecoration(String label, String hint, bool isDark) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
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
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_document, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Medical Record',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(widget.record.recordDate),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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

  Widget _buildRecordTypeCard(BuildContext context, bool isDark) {
    final typeLabel = _recordTypeLabels[_recordType] ?? _recordType;
    final typeIcon = _recordTypeIcons[_recordType] ?? Icons.description;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: const Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Type',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _recordDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _recordDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: const Color(0xFF3B82F6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_recordDate),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDataSection(BuildContext context, bool isDark) {
    return _buildModernSectionCard(
      title: 'Additional Data',
      icon: Icons.data_object_rounded,
      iconColor: const Color(0xFF8B5CF6),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _additionalData.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFieldName(entry.key),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                if (entry.value is Map)
                  ...(_buildNestedData(entry.value as Map<String, dynamic>, isDark))
                else if (entry.value is List)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (entry.value as List).map((item) {
                      return Chip(
                        label: Text(
                          item.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    entry.value?.toString() ?? 'N/A',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildNestedData(Map<String, dynamic> data, bool isDark) {
    return data.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatFieldName(entry.key)}: ',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Expanded(
              child: Text(
                entry.value?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Widget _buildModernSaveButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRecord,
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

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);

      final updatedRecord = MedicalRecordsCompanion(
        id: Value(widget.record.id),
        patientId: Value(widget.record.patientId),
        recordType: Value(_recordType),
        title: Value(_diagnosisController.text.isNotEmpty 
            ? '${_recordTypeLabels[_recordType] ?? 'Record'}: ${_diagnosisController.text}'
            : '${_recordTypeLabels[_recordType] ?? 'Medical Record'} - ${DateFormat('MMM d, yyyy').format(_recordDate)}'),
        description: Value(_descriptionController.text),
        dataJson: Value(jsonEncode(_additionalData)),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_doctorNotesController.text),
        recordDate: Value(_recordDate),
        createdAt: Value(widget.record.createdAt),
      );

      await db.updateMedicalRecord(updatedRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Medical record updated successfully'),
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
            Text('Delete Record'),
          ],
        ),
        content: const Text('Are you sure you want to delete this medical record? This action cannot be undone.'),
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
        await db.deleteMedicalRecord(widget.record.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Medical record deleted'),
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
