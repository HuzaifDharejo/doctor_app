import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/smart_form_prefill_service.dart';
import '../../providers/db_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../core/components/app_button.dart';

/// Button to copy data from previous visit
/// Shows a dialog with last visit data and allows copying fields
class CopyPreviousVisitButton extends ConsumerWidget {
  const CopyPreviousVisitButton({
    super.key,
    required this.patientId,
    required this.onDataCopied,
    this.diagnosisController,
    this.treatmentController,
    this.notesController,
    this.chiefComplaintController,
    this.symptomsController,
  });

  final int patientId;
  final Function(Map<String, dynamic> data) onDataCopied;
  final TextEditingController? diagnosisController;
  final TextEditingController? treatmentController;
  final TextEditingController? notesController;
  final TextEditingController? chiefComplaintController;
  final TextEditingController? symptomsController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppButton.secondary(
      label: 'Copy Previous Visit',
      icon: Icons.copy_rounded,
      onPressed: () => _showCopyDialog(context, ref),
    );
  }

  Future<void> _showCopyDialog(BuildContext context, WidgetRef ref) async {
    final db = await ref.read(doctorDbProvider.future);
    final service = SmartFormPrefillService(db: db);
    
    // Load last visit data
    final lastVisitData = await service.getLastVisitData(patientId);
    
    if (lastVisitData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous visit data found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFields = <String>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.history_rounded, size: 24),
              SizedBox(width: 12),
              Text('Copy from Previous Visit'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select fields to copy from last visit:',
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCopyOption(
                  context,
                  'Diagnosis',
                  lastVisitData['diagnosis'] as String? ?? '',
                  selectedFields,
                  'diagnosis',
                  setState,
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildCopyOption(
                  context,
                  'Treatment',
                  lastVisitData['treatment'] as String? ?? '',
                  selectedFields,
                  'treatment',
                  setState,
                  isDark,
                ),
                const SizedBox(height: 8),
                if (lastVisitData['chiefComplaint'] != null && (lastVisitData['chiefComplaint'] as String).isNotEmpty)
                  _buildCopyOption(
                    context,
                    'Chief Complaint',
                    lastVisitData['chiefComplaint'] as String,
                    selectedFields,
                    'chiefComplaint',
                    setState,
                    isDark,
                  ),
                if (lastVisitData['chiefComplaint'] != null && (lastVisitData['chiefComplaint'] as String).isNotEmpty)
                  const SizedBox(height: 8),
                _buildCopyOption(
                  context,
                  'Clinical Notes',
                  lastVisitData['doctorNotes'] as String? ?? '',
                  selectedFields,
                  'notes',
                  setState,
                  isDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFields.isEmpty
                  ? null
                  : () {
                      final dataToCopy = <String, dynamic>{};
                      if (selectedFields.contains('diagnosis')) {
                        dataToCopy['diagnosis'] = lastVisitData['diagnosis'];
                      }
                      if (selectedFields.contains('treatment')) {
                        dataToCopy['treatment'] = lastVisitData['treatment'];
                      }
                      if (selectedFields.contains('notes')) {
                        dataToCopy['notes'] = lastVisitData['doctorNotes'];
                      }
                      if (selectedFields.contains('chiefComplaint')) {
                        dataToCopy['chiefComplaint'] = lastVisitData['chiefComplaint'];
                      }
                      
                      Navigator.pop(context);
                      onDataCopied(dataToCopy);
                      
                      // Apply to controllers if provided
                      if (dataToCopy['diagnosis'] != null && diagnosisController != null) {
                        diagnosisController!.text = dataToCopy['diagnosis'] as String;
                      }
                      if (dataToCopy['treatment'] != null && treatmentController != null) {
                        treatmentController!.text = dataToCopy['treatment'] as String;
                      }
                      if (dataToCopy['notes'] != null && notesController != null) {
                        notesController!.text = dataToCopy['notes'] as String;
                      }
                      if (dataToCopy['chiefComplaint'] != null && chiefComplaintController != null) {
                        chiefComplaintController!.text = dataToCopy['chiefComplaint'] as String;
                      }
                    },
              child: const Text('Copy Selected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyOption(
    BuildContext context,
    String label,
    String value,
    Set<String> selectedFields,
    String fieldKey,
    StateSetter setState,
    bool isDark,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    final isSelected = selectedFields.contains(fieldKey);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedFields.remove(fieldKey);
          } else {
            selectedFields.add(fieldKey);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkDivider : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    selectedFields.add(fieldKey);
                  } else {
                    selectedFields.remove(fieldKey);
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.md,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.length > 80 ? '${value.substring(0, 80)}...' : value,
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


