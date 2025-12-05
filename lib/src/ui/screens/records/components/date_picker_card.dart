import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';

/// A reusable date picker card widget for medical record forms
/// Shows the selected date with a calendar icon and opens a date picker on tap
class DatePickerCard extends StatelessWidget {
  const DatePickerCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date',
    this.isRequired = true,
    this.firstDate,
    this.lastDate,
    this.helpText,
    this.compact = false,
    this.enabled = true,
    this.showTime = false,
    this.accentColor,
    this.dateFormat,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? helpText;
  final bool compact;
  final bool enabled;
  final bool showTime;
  final Color? accentColor;
  final String? dateFormat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    final formattedDate = selectedDate != null
        ? _formatDate(selectedDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

        // Date picker button
        InkWell(
          onTap: enabled ? () => _showDatePicker(context, isDark, color) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(compact ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: color,
                    size: compact ? 16 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (compact && label.isNotEmpty)
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        formattedDate ?? 'Select date...',
                        style: TextStyle(
                          fontWeight: formattedDate != null ? FontWeight.w500 : FontWeight.normal,
                          fontSize: compact ? 13 : 14,
                          color: formattedDate != null
                              ? (isDark ? Colors.white : AppColors.textPrimary)
                              : (isDark ? Colors.white38 : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedDate != null && enabled)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    onPressed: () => onDateSelected(DateTime.now()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  Icon(
                    Icons.arrow_drop_down,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
              ],
            ),
          ),
        ),

        // Help text
        if (helpText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              helpText!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    if (dateFormat != null) {
      return DateFormat(dateFormat).format(date);
    }
    if (showTime) {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  Future<void> _showDatePicker(BuildContext context, bool isDark, Color color) async {
    final now = DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(now.year + 10),
      helpText: helpText ?? 'Select $label',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: color,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      if (showTime) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(selectedDate ?? now),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: color,
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (time != null) {
          onDateSelected(DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ));
        }
      } else {
        onDateSelected(date);
      }
    }
  }
}

/// A date range picker for selecting start and end dates
class DateRangePickerCard extends StatelessWidget {
  const DateRangePickerCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeSelected,
    this.label = 'Date Range',
    this.isRequired = true,
    this.firstDate,
    this.lastDate,
    this.accentColor,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime start, DateTime end) onDateRangeSelected;
  final String label;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: DatePickerCard(
                selectedDate: startDate,
                onDateSelected: (date) {
                  onDateRangeSelected(date, endDate ?? date);
                },
                label: 'Start',
                compact: true,
                isRequired: false,
                lastDate: endDate,
                accentColor: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: DatePickerCard(
                selectedDate: endDate,
                onDateSelected: (date) {
                  onDateRangeSelected(startDate ?? date, date);
                },
                label: 'End',
                compact: true,
                isRequired: false,
                firstDate: startDate,
                accentColor: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick date selection chips
class QuickDateSelector extends StatelessWidget {
  const QuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.accentColor,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    final now = DateTime.now();

    final options = [
      ('Today', now),
      ('Yesterday', now.subtract(const Duration(days: 1))),
      ('Last week', now.subtract(const Duration(days: 7))),
      ('Last month', DateTime(now.year, now.month - 1, now.day)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedDate != null &&
            _isSameDay(selectedDate!, option.$2);

        return ChoiceChip(
          label: Text(option.$1),
          selected: isSelected,
          onSelected: (_) => onDateSelected(option.$2),
          selectedColor: color.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? color
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? color
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
