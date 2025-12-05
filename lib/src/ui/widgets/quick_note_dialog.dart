import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';

/// Quick note entry dialog for fast clinical note recording
/// 
/// Usage:
/// ```dart
/// final result = await showQuickNoteDialog(context, db, patient);
/// if (result != null) {
///   // Note saved successfully
/// }
/// ```
Future<MedicalRecord?> showQuickNoteDialog(
  BuildContext context,
  DoctorDatabase db,
  Patient patient, {
  int? encounterId,
}) async {
  return showDialog<MedicalRecord>(
    context: context,
    builder: (context) => _QuickNoteDialog(
      db: db,
      patient: patient,
      encounterId: encounterId,
    ),
  );
}

class _QuickNoteDialog extends StatefulWidget {
  const _QuickNoteDialog({
    required this.db,
    required this.patient,
    this.encounterId,
  });

  final DoctorDatabase db;
  final Patient patient;
  final int? encounterId;

  @override
  State<_QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<_QuickNoteDialog> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _noteType = 'general';
  bool _isSaving = false;
  
  final _noteTypes = [
    ('general', 'General Note', Icons.note, AppColors.primary),
    ('progress', 'Progress Note', Icons.trending_up, AppColors.success),
    ('phone_call', 'Phone Call', Icons.phone, AppColors.info),
    ('message', 'Message/Communication', Icons.message, AppColors.appointments),
    ('lab_review', 'Lab Review', Icons.science, const Color(0xFF0EA5E9)),
    ('medication', 'Medication Note', Icons.medication, AppColors.prescriptions),
    ('referral', 'Referral Note', Icons.send, const Color(0xFF8B5CF6)),
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedType = _noteTypes.firstWhere((t) => t.$1 == _noteType);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    selectedType.$4,
                    selectedType.$4.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selectedType.$3,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Note',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.patient.firstName} ${widget.patient.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note Type Selection
                    Text(
                      'Note Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _noteTypes.map((type) {
                        final isSelected = _noteType == type.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _noteType = type.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? type.$4.withValues(alpha: 0.2) 
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? type.$4 : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type.$3,
                                  size: 16,
                                  color: isSelected ? type.$4 : (isDark ? Colors.white54 : Colors.black45),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type.$2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? type.$4 : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Brief summary...',
                        prefixIcon: Icon(Icons.title, color: selectedType.$4),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: selectedType.$4, width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Note Content
                    TextFormField(
                      controller: _noteController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        hintText: 'Enter your note here...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.notes, color: selectedType.$4),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: selectedType.$4, width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Quick templates
                    Text(
                      'Quick Templates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTemplateChip('Patient stable'),
                          _buildTemplateChip('Follow-up needed'),
                          _buildTemplateChip('Labs ordered'),
                          _buildTemplateChip('Referred to specialist'),
                          _buildTemplateChip('Medication adjusted'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedType.$4,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Save Note'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTemplateChip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        onPressed: () {
          final current = _noteController.text;
          if (current.isNotEmpty && !current.endsWith('\n')) {
            _noteController.text = '$current\n$text';
          } else {
            _noteController.text = '$current$text';
          }
          _noteController.selection = TextSelection.fromPosition(
            TextPosition(offset: _noteController.text.length),
          );
        },
      ),
    );
  }
  
  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a note'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final title = _titleController.text.isNotEmpty 
          ? _titleController.text 
          : '${_noteTypes.firstWhere((t) => t.$1 == _noteType).$2} - ${DateTime.now().toString().split(' ')[0]}';
      
      final companion = MedicalRecordsCompanion(
        patientId: Value(widget.patient.id),
        encounterId: Value(widget.encounterId),
        recordType: Value(_noteType),
        title: Value(title),
        description: Value(_noteController.text),
        recordDate: Value(DateTime.now()),
      );
      
      final id = await widget.db.insertMedicalRecord(companion);
      final saved = await widget.db.getMedicalRecordById(id);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
