import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'medication_models.dart';
import 'medication_theme.dart';

/// Reusable card widget for displaying a medication entry
class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.medication,
    required this.index,
    this.onEdit,
    this.onRemove,
    this.showDragHandle = false,
    this.showActions = true,
  });

  final MedicationData medication;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool showDragHandle;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: MedicationContainerStyle.card(isDark: isDark),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 12),
              _buildTags(),
              if (medication.instructions.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildInstructions(isDark),
              ],
              if (showActions) ...[
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Index badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MedColors.primary.withValues(alpha: 0.15),
                MedColors.secondary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: MedColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Medication name and dosage
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (medication.dosage.isNotEmpty)
                Text(
                  medication.dosage,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        // Drag handle (for reorderable list)
        if (showDragHandle)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.drag_handle,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MedicationTag(text: medication.frequency, color: MedColors.accent),
        MedicationTag(text: medication.timing, color: MedColors.success),
        if (medication.duration.isNotEmpty)
          MedicationTag(text: medication.duration, color: MedColors.secondary),
      ],
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MedColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: MedColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              medication.instructions,
              style: const TextStyle(
                fontSize: 12,
                color: MedColors.info,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: MedColors.accent,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Remove'),
            style: TextButton.styleFrom(
              foregroundColor: MedColors.error,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact medication summary card (read-only display)
/// 
/// Supports two APIs:
/// 1. Pass a [MedicationData] object via [medication]
/// 2. Pass individual fields: [name], [dosage], [frequency], [timing], [duration], [instructions]
class MedicationSummaryCard extends StatelessWidget {
  const MedicationSummaryCard({
    super.key,
    this.medication,
    this.name,
    this.dosage,
    this.frequency,
    this.timing,
    this.duration,
    this.instructions,
    this.index,
  }) : assert(
         medication != null || name != null,
         'Either medication or name must be provided',
       );

  /// Full medication data object (preferred)
  final MedicationData? medication;
  
  /// Individual fields (backward compatible)
  final String? name;
  final String? dosage;
  final String? frequency;
  final String? timing;
  final String? duration;
  final String? instructions;
  final int? index;
  
  // Getters to resolve from either medication or individual fields
  String get _name => medication?.name ?? name ?? '';
  String get _dosage => medication?.dosage ?? dosage ?? '';
  String get _frequency => medication?.frequency ?? frequency ?? 'OD';
  String get _timing => medication?.timing ?? timing ?? 'After Food';
  String get _duration => medication?.duration ?? duration ?? '';
  String get _instructions => medication?.instructions ?? instructions ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (index != null)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: MedColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index! + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MedColors.warning,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (_dosage.isNotEmpty)
                      MedicationTag(text: _dosage, color: MedColors.accent, size: TagSize.small),
                    MedicationTag(text: _frequency, color: MedColors.success, size: TagSize.small),
                    MedicationTag(text: _timing, color: MedColors.secondary, size: TagSize.small),
                    if (_duration.isNotEmpty)
                      MedicationTag(text: _duration, color: MedColors.primary, size: TagSize.small),
                  ],
                ),
                if (_instructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _instructions,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for medication list
class EmptyMedicationsState extends StatelessWidget {
  const EmptyMedicationsState({
    super.key,
    this.onTap,
    this.message = 'No medications added',
    this.actionLabel = 'Tap to add medications',
  });

  final VoidCallback? onTap;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MedColors.primary.withValues(alpha: 0.1),
                    MedColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 40,
                color: MedColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 4),
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
