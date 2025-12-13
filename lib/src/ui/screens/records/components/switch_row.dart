import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// A styled switch row with label for forms
/// 
/// Provides a consistent look for boolean fields across all medical forms.
/// 
/// Example:
/// ```dart
/// SwitchRow(
///   label: 'Abnormal Finding',
///   value: _isAbnormal,
///   onChanged: (v) => setState(() => _isAbnormal = v),
///   subtitle: 'Mark if any concerning findings',
/// )
/// ```
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.activeColor,
    this.enabled = true,
    this.dense = false,
  });

  /// Main label text
  final String label;
  
  /// Current switch value
  final bool value;
  
  /// Callback when value changes
  final ValueChanged<bool> onChanged;
  
  /// Optional subtitle/description text
  final String? subtitle;
  
  /// Optional leading icon
  final IconData? icon;
  
  /// Active color for the switch
  final Color? activeColor;
  
  /// Whether the switch is enabled
  final bool enabled;
  
  /// Use dense padding
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveActiveColor = activeColor ?? Theme.of(context).primaryColor;

    return Padding(
      padding: dense 
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: value 
                  ? effectiveActiveColor 
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
                    fontSize: dense ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? (isDark ? Colors.white : Colors.grey.shade800)
                        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: effectiveActiveColor,
          ),
        ],
      ),
    );
  }
}

/// A group of switches in a card container
/// 
/// Example:
/// ```dart
/// SwitchGroup(
///   title: 'Symptoms Present',
///   switches: [
///     SwitchItem(label: 'Dyspnea', value: _dyspnea, onChanged: ...),
///     SwitchItem(label: 'Chest Pain', value: _chestPain, onChanged: ...),
///   ],
/// )
/// ```
class SwitchGroup extends StatelessWidget {
  const SwitchGroup({
    super.key,
    required this.switches,
    this.title,
    this.icon,
    this.accentColor,
    this.dividers = true,
  });

  /// List of switch items
  final List<SwitchItem> switches;
  
  /// Optional group title
  final String? title;
  
  /// Optional title icon
  final IconData? icon;
  
  /// Accent color for the group
  final Color? accentColor;
  
  /// Show dividers between items
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = accentColor ?? Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: effectiveColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
          ],
          ...switches.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                SwitchRow(
                  label: item.label,
                  value: item.value,
                  onChanged: item.onChanged,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  activeColor: item.activeColor ?? effectiveColor,
                  enabled: item.enabled,
                  dense: true,
                ),
                if (dividers && index < switches.length - 1)
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Data class for switch items in a group
class SwitchItem {
  const SwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.activeColor,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final IconData? icon;
  final Color? activeColor;
  final bool enabled;
}

/// Present/Absent toggle row - common pattern in medical forms
/// 
/// Provides a visually distinct toggle for marking findings as present or absent.
/// 
/// Example:
/// ```dart
/// PresentAbsentToggle(
///   label: 'Murmur',
///   isPresent: _murmurPresent,
///   onChanged: (present) => setState(() => _murmurPresent = present),
/// )
/// ```
class PresentAbsentToggle extends StatelessWidget {
  const PresentAbsentToggle({
    super.key,
    required this.label,
    required this.isPresent,
    required this.onChanged,
    this.presentLabel = 'Present',
    this.absentLabel = 'Absent',
    this.presentColor,
    this.absentColor,
    this.icon,
  });

  final String label;
  final bool? isPresent;
  final ValueChanged<bool?> onChanged;
  final String presentLabel;
  final String absentLabel;
  final Color? presentColor;
  final Color? absentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePresentColor = presentColor ?? Colors.red.shade600;
    final effectiveAbsentColor = absentColor ?? Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: Text(
                  absentLabel,
                  style: const TextStyle(fontSize: 11),
                ),
                icon: Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: isPresent == false ? effectiveAbsentColor : null,
                ),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text(
                  presentLabel,
                  style: const TextStyle(fontSize: 11),
                ),
                icon: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: isPresent == true ? effectivePresentColor : null,
                ),
              ),
            ],
            selected: isPresent != null ? {isPresent!} : {},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                onChanged(selected.first);
              }
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Severity selector with predefined options
/// 
/// Example:
/// ```dart
/// SeveritySelector(
///   label: 'Pain Intensity',
///   value: _painSeverity,
///   onChanged: (s) => setState(() => _painSeverity = s),
/// )
/// ```
class SeveritySelector extends StatelessWidget {
  const SeveritySelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.levels = const ['None', 'Mild', 'Moderate', 'Severe'],
    this.colors,
    this.icon,
    this.showNone = true,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> levels;
  final List<Color>? colors;
  final IconData? icon;
  final bool showNone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColors = colors ?? [
      Colors.green.shade600,    // None
      Colors.yellow.shade700,   // Mild
      Colors.orange.shade600,   // Moderate
      Colors.red.shade600,      // Severe
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levels.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final isSelected = value == level;
              final color = effectiveColors[index % effectiveColors.length];

              return ChoiceChip(
                label: Text(level),
                selected: isSelected,
                onSelected: (selected) => onChanged(selected ? level : null),
                selectedColor: color.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? color : Colors.grey.shade400,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? color : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                avatar: isSelected
                    ? Icon(Icons.check, size: 16, color: color)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
