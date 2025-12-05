import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/design_tokens.dart';

/// Quick date preset options
enum DatePreset {
  today('Today'),
  tomorrow('Tomorrow'),
  nextWeek('Next Week'),
  nextMonth('Next Month'),
  custom('Custom');

  const DatePreset(this.label);
  final String label;

  DateTime? toDate() {
    final now = DateTime.now();
    switch (this) {
      case DatePreset.today:
        return DateTime(now.year, now.month, now.day);
      case DatePreset.tomorrow:
        return DateTime(now.year, now.month, now.day + 1);
      case DatePreset.nextWeek:
        return DateTime(now.year, now.month, now.day + 7);
      case DatePreset.nextMonth:
        return DateTime(now.year, now.month + 1, now.day);
      case DatePreset.custom:
        return null;
    }
  }
}

/// Quick time preset options
enum TimePreset {
  morning('Morning (9 AM)', 9, 0),
  noon('Noon (12 PM)', 12, 0),
  afternoon('Afternoon (2 PM)', 14, 0),
  evening('Evening (5 PM)', 17, 0),
  custom('Custom', 0, 0);

  const TimePreset(this.label, this.hour, this.minute);
  final String label;
  final int hour;
  final int minute;

  TimeOfDay? toTime() {
    if (this == TimePreset.custom) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

/// A date/time picker with quick preset options for common selections.
/// 
/// Features:
/// - Quick date presets (Today, Tomorrow, Next Week, Next Month)
/// - Quick time presets (Morning, Noon, Afternoon, Evening)
/// - Custom date/time selection via system pickers
/// - Displays selected value in a styled button
/// - Dark mode support
/// - Accessibility support with semantic labels
class AppDateTimePicker extends StatefulWidget {
  const AppDateTimePicker({
    super.key,
    this.label,
    this.initialDate,
    this.initialTime,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.onTimeSelected,
    this.onDateTimeSelected,
    this.showDatePresets = true,
    this.showTimePresets = true,
    this.showTime = true,
    this.dateFormat,
    this.timeFormat,
    this.selectableDayPredicate,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
  });

  /// Label displayed above the picker
  final String? label;
  
  /// Initial date value
  final DateTime? initialDate;
  
  /// Initial time value
  final TimeOfDay? initialTime;
  
  /// Earliest selectable date
  final DateTime? firstDate;
  
  /// Latest selectable date
  final DateTime? lastDate;
  
  /// Callback when date is selected
  final ValueChanged<DateTime>? onDateSelected;
  
  /// Callback when time is selected
  final ValueChanged<TimeOfDay>? onTimeSelected;
  
  /// Callback when both date and time are selected (combines them into DateTime)
  final ValueChanged<DateTime>? onDateTimeSelected;
  
  /// Whether to show quick date preset chips
  final bool showDatePresets;
  
  /// Whether to show quick time preset chips
  final bool showTimePresets;
  
  /// Whether to show time picker
  final bool showTime;
  
  /// Custom date format (defaults to 'MMM d, yyyy')
  final DateFormat? dateFormat;
  
  /// Custom time format (defaults to 'h:mm a')
  final DateFormat? timeFormat;
  
  /// Predicate to determine if a day is selectable
  final bool Function(DateTime)? selectableDayPredicate;
  
  /// Helper text displayed below the picker
  final String? helperText;
  
  /// Error message to display
  final String? errorText;
  
  /// Whether this field is required
  final bool isRequired;
  
  /// Whether the picker is enabled
  final bool enabled;

  @override
  State<AppDateTimePicker> createState() => _AppDateTimePickerState();
}

class _AppDateTimePickerState extends State<AppDateTimePicker> {
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  DatePreset? _activeDatePreset;
  TimePreset? _activeTimePreset;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _detectActivePresets();
  }

  @override
  void didUpdateWidget(covariant AppDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
      _detectActivePresets();
    }
    if (widget.initialTime != oldWidget.initialTime) {
      _selectedTime = widget.initialTime;
      _detectActivePresets();
    }
  }

  void _detectActivePresets() {
    // Detect if selected date matches a preset
    _activeDatePreset = null;
    if (_selectedDate != null) {
      for (final preset in DatePreset.values) {
        final presetDate = preset.toDate();
        if (presetDate != null && _isSameDay(_selectedDate!, presetDate)) {
          _activeDatePreset = preset;
          break;
        }
      }
      _activeDatePreset ??= DatePreset.custom;
    }

    // Detect if selected time matches a preset
    _activeTimePreset = null;
    if (_selectedTime != null) {
      for (final preset in TimePreset.values) {
        final presetTime = preset.toTime();
        if (presetTime != null &&
            _selectedTime!.hour == presetTime.hour &&
            _selectedTime!.minute == presetTime.minute) {
          _activeTimePreset = preset;
          break;
        }
      }
      _activeTimePreset ??= TimePreset.custom;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDatePresetSelected(DatePreset preset) {
    if (!widget.enabled) return;
    
    if (preset == DatePreset.custom) {
      _showDatePicker();
    } else {
      final date = preset.toDate();
      if (date != null) {
        setState(() {
          _selectedDate = date;
          _activeDatePreset = preset;
        });
        widget.onDateSelected?.call(date);
        _notifyDateTimeChange();
      }
    }
  }

  void _onTimePresetSelected(TimePreset preset) {
    if (!widget.enabled) return;
    
    if (preset == TimePreset.custom) {
      _showTimePicker();
    } else {
      final time = preset.toTime();
      if (time != null) {
        setState(() {
          _selectedTime = time;
          _activeTimePreset = preset;
        });
        widget.onTimeSelected?.call(time);
        _notifyDateTimeChange();
      }
    }
  }

  Future<void> _showDatePicker() async {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(now.year - 100);
    final lastDate = widget.lastDate ?? DateTime(now.year + 100);
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: widget.selectableDayPredicate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _activeDatePreset = DatePreset.custom;
      });
      widget.onDateSelected?.call(date);
      _notifyDateTimeChange();
    }
  }

  Future<void> _showTimePicker() async {
    if (!widget.enabled) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _activeTimePreset = TimePreset.custom;
      });
      widget.onTimeSelected?.call(time);
      _notifyDateTimeChange();
    }
  }

  void _notifyDateTimeChange() {
    if (widget.onDateTimeSelected != null && _selectedDate != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime?.hour ?? 0,
        _selectedTime?.minute ?? 0,
      );
      widget.onDateTimeSelected!(dateTime);
    }
  }

  String _formatDate(DateTime date) {
    final format = widget.dateFormat ?? DateFormat('MMM d, yyyy');
    return format.format(date);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = widget.timeFormat ?? DateFormat('h:mm a');
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Semantics(
      label: widget.label ?? 'Date and time picker',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) _buildLabel(context, isDark),
          
          // Date section
          _buildSectionTitle(context, isDark, 'Date'),
          if (widget.showDatePresets) _buildDatePresets(context, isDark),
          const SizedBox(height: AppSpacing.xs),
          _buildDateButton(context, isDark, hasError),
          
          // Time section
          if (widget.showTime) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSectionTitle(context, isDark, 'Time'),
            if (widget.showTimePresets) _buildTimePresets(context, isDark),
            const SizedBox(height: AppSpacing.xs),
            _buildTimeButton(context, isDark, hasError),
          ],
          
          // Error/Helper text
          if (hasError)
            _buildErrorText(context)
          else if (widget.helperText != null)
            _buildHelperText(context, isDark),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (widget.isRequired) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white54 : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDatePresets(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: DatePreset.values.where((p) => p != DatePreset.custom).map((preset) {
          final isSelected = _activeDatePreset == preset;
          return _buildPresetChip(
            context: context,
            label: preset.label,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => _onDatePresetSelected(preset),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimePresets(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: TimePreset.values.where((p) => p != TimePreset.custom).map((preset) {
          final isSelected = _activeTimePreset == preset;
          return _buildPresetChip(
            context: context,
            label: preset.label.split(' ').first, // Just show "Morning", not full label
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => _onTimePresetSelected(preset),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPresetChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Semantics(
      button: true,
      label: '$label preset',
      selected: isSelected,
      child: InkWell(
        onTap: widget.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withValues(alpha: 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? primaryColor
                  : (isDark ? Colors.white24 : Colors.grey[300]!),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected 
                  ? primaryColor
                  : (isDark ? Colors.white70 : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, bool isDark, bool hasError) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Semantics(
      button: true,
      label: _selectedDate != null 
          ? 'Selected date: ${_formatDate(_selectedDate!)}'
          : 'Select date',
      child: InkWell(
        onTap: widget.enabled ? _showDatePicker : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Theme.of(context).colorScheme.error
                  : (isDark ? Colors.white24 : Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: _selectedDate != null ? primaryColor : Colors.grey,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _selectedDate != null 
                      ? _formatDate(_selectedDate!)
                      : 'Select date...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.w400,
                    color: _selectedDate != null
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.grey),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, bool isDark, bool hasError) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Semantics(
      button: true,
      label: _selectedTime != null 
          ? 'Selected time: ${_formatTime(_selectedTime!)}'
          : 'Select time',
      child: InkWell(
        onTap: widget.enabled ? _showTimePicker : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Theme.of(context).colorScheme.error
                  : (isDark ? Colors.white24 : Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 20,
                color: _selectedTime != null ? primaryColor : Colors.grey,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _selectedTime != null 
                      ? _formatTime(_selectedTime!)
                      : 'Select time...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedTime != null ? FontWeight.w500 : FontWeight.w400,
                    color: _selectedTime != null
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.grey),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.errorText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperText(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        widget.helperText!,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.grey[600],
        ),
      ),
    );
  }
}

/// Compact date picker - just the date selection button with presets
class CompactDatePicker extends StatelessWidget {
  const CompactDatePicker({
    super.key,
    this.label,
    this.selectedDate,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.showPresets = true,
    this.enabled = true,
  });

  final String? label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool showPresets;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppDateTimePicker(
      label: label,
      initialDate: selectedDate,
      onDateSelected: onDateSelected,
      firstDate: firstDate,
      lastDate: lastDate,
      showDatePresets: showPresets,
      showTime: false,
      enabled: enabled,
    );
  }
}

/// Compact time picker - just the time selection button with presets
class CompactTimePicker extends StatelessWidget {
  const CompactTimePicker({
    super.key,
    this.selectedTime,
    this.onTimeSelected,
    this.showPresets = true,
    this.enabled = true,
  });

  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay>? onTimeSelected;
  final bool showPresets;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppDateTimePicker(
      initialTime: selectedTime,
      onTimeSelected: onTimeSelected,
      showTimePresets: showPresets,
      showDatePresets: false,
      showTime: true,
      enabled: enabled,
    );
  }
}
