import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// Multi-select chip selector for categories, symptoms, etc.
/// Now supports both inline and card-style layouts
class ChipSelectorSection extends StatelessWidget {
  const ChipSelectorSection({
    super.key,
    required this.options,
    this.selectedValues,
    this.selectedOptions,  // Alias for selectedValues
    required this.onChanged,
    this.label,
    this.title,  // Alias for label with icon/card style
    this.icon,   // Icon for card style
    this.allowMultiple = true,
    this.accentColor,
    this.chipColor,  // Alias for accentColor
    this.wrap = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<String> options;
  final List<String>? selectedValues;
  final List<String>? selectedOptions;  // Alias for selectedValues
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final String? title;  // Alias for label with icon/card style
  final IconData? icon;  // Icon for card style
  final bool allowMultiple;
  final Color? accentColor;
  final Color? chipColor;  // Alias for accentColor
  final bool wrap;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = chipColor ?? accentColor ?? AppColors.primary;
    final selected = selectedOptions ?? selectedValues ?? [];
    final displayLabel = title ?? label;

    // If title and icon are provided, use card-style layout
    if (title != null && icon != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips
          wrap
              ? Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: _buildChips(isDark, color, selected),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildChips(isDark, color, selected)
                        .expand((chip) => [chip, SizedBox(width: spacing)])
                        .toList()
                      ..removeLast(),
                  ),
                ),
        ],
      );
    }

    // Simple inline layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              displayLabel!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        wrap
            ? Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: _buildChips(isDark, color, selected),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildChips(isDark, color, selected)
                      .expand((chip) => [chip, SizedBox(width: spacing)])
                      .toList()
                    ..removeLast(),
                ),
              ),
      ],
    );
  }

  List<Widget> _buildChips(bool isDark, Color color, List<String> selected) {
    return options.map((option) {
      final isSelected = selected.contains(option);

      return FilterChip(
        label: Text(option),
        selected: isSelected,
        onSelected: (sel) {
          if (allowMultiple) {
            if (sel) {
              onChanged([...selected, option]);
            } else {
              onChanged(selected.where((v) => v != option).toList());
            }
          } else {
            onChanged(sel ? [option] : []);
          }
        },
        selectedColor: color.withValues(alpha: isDark ? 0.3 : 0.15),
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected
              ? color
              : (isDark ? Colors.white70 : AppColors.textSecondary),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();
  }
}

/// Icon-based chip selector with custom styling per option
class IconChipSelector extends StatelessWidget {
  const IconChipSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.label,
  });

  final List<IconChipOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option.value;
            final color = option.color ?? AppColors.primary;

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(
                      option.icon,
                      size: 16,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white54 : Colors.grey),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(option.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option.value : null);
              },
              selectedColor: color.withValues(alpha: isDark ? 0.3 : 0.15),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected
                    ? color
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? color
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Data class for icon chip options
class IconChipOption {
  const IconChipOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
}

/// Risk/severity level selector with color coding
class RiskLevelSelector extends StatelessWidget {
  const RiskLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
    this.label = 'Risk Level',
    this.levels,
  });

  final String? selectedLevel;
  final ValueChanged<String?> onChanged;
  final String label;
  final List<RiskLevel>? levels;

  static const defaultLevels = [
    RiskLevel('low', 'Low', Colors.green, Icons.shield_outlined),
    RiskLevel('medium', 'Medium', Colors.orange, Icons.warning_amber_outlined),
    RiskLevel('high', 'High', Colors.red, Icons.error_outline),
    RiskLevel('critical', 'Critical', Color(0xFF880000), Icons.dangerous_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskLevels = levels ?? defaultLevels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: riskLevels.map((level) {
            final isSelected = selectedLevel == level.value;

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    level.icon,
                    size: 16,
                    color: isSelected
                        ? level.color
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(level.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? level.value : null);
              },
              selectedColor: level.color.withValues(alpha: isDark ? 0.3 : 0.15),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              checkmarkColor: level.color,
              labelStyle: TextStyle(
                color: isSelected
                    ? level.color
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? level.color
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Data class for risk levels
class RiskLevel {
  const RiskLevel(this.value, this.label, this.color, this.icon);

  final String value;
  final String label;
  final Color color;
  final IconData icon;
}

/// Status selector (e.g., Normal, Abnormal, Critical)
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
    this.label = 'Status',
    this.statuses = const ['Normal', 'Abnormal', 'Critical'],
  });

  final String? selectedStatus;
  final ValueChanged<String?> onChanged;
  final String label;
  final List<String> statuses;

  @override
  Widget build(BuildContext context) {
    return IconChipSelector(
      label: label,
      selectedValue: selectedStatus,
      onChanged: onChanged,
      options: statuses.map((status) {
        return IconChipOption(
          value: status,
          label: status,
          icon: _getStatusIcon(status),
          color: _getStatusColor(status),
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Icons.check_circle_outline;
      case 'abnormal':
        return Icons.warning_amber_outlined;
      case 'critical':
        return Icons.error_outline;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'abnormal':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Toggleable option row
class ToggleOptionRow extends StatelessWidget {
  const ToggleOptionRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
