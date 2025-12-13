import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// A reusable multi-select chip section for medical record forms
/// 
/// Used for selecting symptoms, investigations, signs, etc.
/// Displays chips in a wrap layout with selection highlighting.
/// 
/// Example:
/// ```dart
/// ChipSelectorSection(
///   title: 'Symptoms',
///   options: ['Chest Pain', 'Dyspnea', 'Fatigue'],
///   selected: _selectedSymptoms,
///   onChanged: (list) => setState(() => _selectedSymptoms = list),
///   accentColor: Colors.orange,
/// )
/// ```
class ChipSelectorSection extends StatelessWidget {
  const ChipSelectorSection({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accentColor,
    this.showClearButton = true,
    this.maxSelection,
    this.compact = false,
  });

  /// Title displayed above the chips
  final String title;
  
  /// List of available options to choose from
  final List<String> options;
  
  /// Currently selected options
  final List<String> selected;
  
  /// Callback when selection changes
  final ValueChanged<List<String>> onChanged;
  
  /// Accent color for selected chips
  final Color? accentColor;
  
  /// Whether to show a "Clear All" button when items are selected
  final bool showClearButton;
  
  /// Maximum number of selections allowed (null for unlimited)
  final int? maxSelection;
  
  /// Whether to use compact chip styling
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with optional clear button
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
            if (showClearButton && selected.isNotEmpty)
              GestureDetector(
                onTap: () => onChanged([]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Clear (${selected.length})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Chips
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            final canSelect = maxSelection == null || 
                              selected.length < maxSelection! || 
                              isSelected;
            
            return FilterChip(
              label: Text(
                option, 
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: isSelected ? color : null,
                ),
              ),
              selected: isSelected,
              onSelected: canSelect ? (sel) {
                final newList = List<String>.from(selected);
                if (sel) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onChanged(newList);
              } : null,
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              visualDensity: compact ? VisualDensity.compact : null,
              materialTapTargetSize: compact 
                  ? MaterialTapTargetSize.shrinkWrap 
                  : null,
            );
          }).toList(),
        ),
        // Selection count indicator
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${selected.length} selected${maxSelection != null ? ' / $maxSelection max' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A single-select chip section (radio-button style)
class SingleSelectChipSection extends StatelessWidget {
  const SingleSelectChipSection({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.accentColor,
    this.compact = false,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final Color? accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: options.map((option) {
            final isSelected = selected == option;
            
            return ChoiceChip(
              label: Text(
                option, 
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              onSelected: (sel) => onChanged(sel ? option : null),
              selectedColor: color,
              visualDensity: compact ? VisualDensity.compact : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
