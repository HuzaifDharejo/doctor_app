import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// A styled text input field for medical record forms
/// Supports various configurations including multi-line, prefix/suffix icons, etc.
class RecordTextField extends StatelessWidget {
  const RecordTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.isRequired = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.accentColor,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final bool isRequired;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final Color? accentColor;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  label!,
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

        // Text field
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: color, size: 20)
                : null,
            suffixIcon: suffixIcon,
            suffixText: suffixText,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurface
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines == 1 ? 14 : 12,
            ),
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autofocus: autofocus,
          onTap: onTap,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
        ),
      ],
    );
  }
}

/// A numeric input field with unit suffix
class RecordNumberField extends StatelessWidget {
  const RecordNumberField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.unit,
    this.isRequired = false,
    this.min,
    this.max,
    this.decimal = false,
    this.prefixIcon,
    this.onChanged,
    this.enabled = true,
    this.accentColor,
    this.normalRange,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? unit;
  final bool isRequired;
  final double? min;
  final double? max;
  final bool decimal;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Color? accentColor;
  final String? normalRange; // e.g., "60-100"

  @override
  Widget build(BuildContext context) {
    return RecordTextField(
      controller: controller,
      label: label,
      hint: hint ?? (normalRange != null ? 'Normal: $normalRange' : null),
      isRequired: isRequired,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      prefixIcon: prefixIcon,
      suffixText: unit,
      onChanged: onChanged,
      enabled: enabled,
      accentColor: accentColor,
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (isRequired) return 'Required';
          return null;
        }
        final num = double.tryParse(value);
        if (num == null) return 'Enter a valid number';
        if (min != null && num < min!) return 'Min: $min';
        if (max != null && num > max!) return 'Max: $max';
        return null;
      },
      helperText: normalRange != null && hint == null
          ? 'Normal range: $normalRange ${unit ?? ''}'
          : null,
    );
  }
}

/// A multi-line notes/description field
class RecordNotesField extends StatelessWidget {
  const RecordNotesField({
    super.key,
    required this.controller,
    this.label = 'Notes',
    this.hint = 'Add any additional notes or observations...',
    this.isRequired = false,
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
    this.enabled = true,
    this.accentColor,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return RecordTextField(
      controller: controller,
      label: label,
      hint: hint,
      isRequired: isRequired,
      maxLines: maxLines,
      minLines: 2,
      maxLength: maxLength,
      prefixIcon: Icons.notes,
      onChanged: onChanged,
      enabled: enabled,
      accentColor: accentColor,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

/// A grid of compact text fields for related data (like vital signs)
class RecordFieldGrid extends StatelessWidget {
  const RecordFieldGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure itemWidth is never negative
        final calculatedWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final itemWidth = calculatedWidth.clamp(0.0, constraints.maxWidth);

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Compact field for grids
class CompactTextField extends StatelessWidget {
  const CompactTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.unit,
    this.suffix,  // Alias for unit
    this.keyboardType,
    this.isRequired = false,
    this.onChanged,
    this.accentColor,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? unit;
  final String? suffix;  // Alias for unit
  final TextInputType? keyboardType;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    final suffixText = suffix ?? unit;  // Use suffix if provided, otherwise unit

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            isDense: true,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurface
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
            suffixStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
