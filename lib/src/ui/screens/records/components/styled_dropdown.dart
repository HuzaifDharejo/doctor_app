import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// A styled dropdown field for medical record forms
/// 
/// Provides consistent styling with label, border, and dark mode support.
/// 
/// Example:
/// ```dart
/// StyledDropdown(
///   label: 'Level of Consciousness',
///   value: _consciousness,
///   options: ['Alert', 'Confused', 'Drowsy', 'Comatose'],
///   onChanged: (v) => setState(() => _consciousness = v!),
/// )
/// ```
class StyledDropdown extends StatelessWidget {
  const StyledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.accentColor,
    this.hint,
    this.isRequired = false,
    this.validator,
  });

  /// Label displayed above the dropdown
  final String label;
  
  /// Currently selected value
  final String? value;
  
  /// List of available options
  final List<String> options;
  
  /// Callback when selection changes
  final ValueChanged<String?> onChanged;
  
  /// Accent color for the dropdown
  final Color? accentColor;
  
  /// Hint text when no value is selected
  final String? hint;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Custom validator function
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              hint: hint != null 
                  ? Text(
                      hint!,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    )
                  : null,
              items: options.map((e) => DropdownMenuItem(
                value: e, 
                child: Text(
                  e, 
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
              validator: validator ?? (isRequired 
                  ? (v) => v == null || v.isEmpty ? '$label is required' : null
                  : null),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of styled dropdowns for compact layouts
class DropdownRow extends StatelessWidget {
  const DropdownRow({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// A simple inline dropdown without label (for tables/grids)
class InlineDropdown extends StatelessWidget {
  const InlineDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.compact = false,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: compact,
          hint: hint != null 
              ? Text(
                  hint!,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: Colors.grey.shade500,
                  ),
                )
              : null,
          items: options.map((e) => DropdownMenuItem(
            value: e, 
            child: Text(
              e, 
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),
          )).toList(),
          onChanged: onChanged,
          dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
        ),
      ),
    );
  }
}
