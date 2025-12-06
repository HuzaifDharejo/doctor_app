import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// A progress indicator for medical record forms
/// Shows completion status based on filled sections
class FormProgressIndicator extends StatelessWidget {
  const FormProgressIndicator({
    super.key,
    required this.completedSections,
    required this.totalSections,
    this.accentColor,
    this.showLabel = true,
    this.compact = false,
  });

  final int completedSections;
  final int totalSections;
  final Color? accentColor;
  final bool showLabel;
  final bool compact;

  double get progress => totalSections > 0 ? completedSections / totalSections : 0;
  int get percentage => (progress * 100).round();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    // Dynamic color based on progress
    Color progressColor;
    if (percentage < 30) {
      progressColor = Colors.red.shade400;
    } else if (percentage < 70) {
      progressColor = Colors.orange.shade400;
    } else if (percentage < 100) {
      progressColor = Colors.blue.shade400;
    } else {
      progressColor = Colors.green.shade500;
    }

    if (compact) {
      return _buildCompact(context, isDark, progressColor);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: progressColor.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getProgressIcon(),
                  color: progressColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getProgressLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (showLabel)
                      Text(
                        '$completedSections of $totalSections sections completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark 
                  ? Colors.grey.shade800 
                  : progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, bool isDark, Color progressColor) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark 
                  ? Colors.grey.shade800 
                  : progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: progressColor,
          ),
        ),
      ],
    );
  }

  IconData _getProgressIcon() {
    if (percentage < 30) {
      return Icons.edit_note_rounded;
    } else if (percentage < 70) {
      return Icons.pending_rounded;
    } else if (percentage < 100) {
      return Icons.hourglass_top_rounded;
    } else {
      return Icons.check_circle_rounded;
    }
  }

  String _getProgressLabel() {
    if (percentage < 30) {
      return 'Just Getting Started';
    } else if (percentage < 70) {
      return 'Making Progress';
    } else if (percentage < 100) {
      return 'Almost There!';
    } else {
      return 'Form Complete!';
    }
  }
}

/// A helper class to track form completion status
class FormCompletionTracker {
  FormCompletionTracker({required this.sections});

  final List<FormSection> sections;

  int get completedCount => sections.where((s) => s.isComplete).length;
  int get totalCount => sections.length;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0;
  bool get isComplete => completedCount == totalCount;
}

/// Represents a section in the form
class FormSection {
  FormSection({
    required this.name,
    required this.isComplete,
    this.isRequired = false,
  });

  final String name;
  final bool isComplete;
  final bool isRequired;
}
