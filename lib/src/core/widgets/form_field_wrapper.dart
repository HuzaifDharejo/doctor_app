import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// A reusable wrapper for form fields that provides consistent styling,
/// labels, error display, and helper text.
/// 
/// Features:
/// - Label with optional required indicator
/// - Helper text below the field
/// - Error message display
/// - Info tooltip icon
/// - Consistent padding and spacing
/// - Dark mode support
class FormFieldWrapper extends StatelessWidget {
  const FormFieldWrapper({
    super.key,
    required this.child,
    this.label,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.showInfoTooltip = false,
    this.infoTooltipMessage,
    this.padding,
    this.labelStyle,
    this.semanticLabel,
  });

  /// The form field widget to wrap
  final Widget child;
  
  /// Label text displayed above the field
  final String? label;
  
  /// Helper text displayed below the field
  final String? helperText;
  
  /// Error message to display (takes precedence over helper text)
  final String? errorText;
  
  /// Whether to show a required indicator (*) next to the label
  final bool isRequired;
  
  /// Whether to show an info icon next to the label
  final bool showInfoTooltip;
  
  /// Message to display when info icon is tapped
  final String? infoTooltipMessage;
  
  /// Custom padding around the entire wrapper
  final EdgeInsets? padding;
  
  /// Custom style for the label
  final TextStyle? labelStyle;
  
  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Factory constructor for text fields
  factory FormFieldWrapper.textField({
    Key? key,
    required TextEditingController controller,
    String? label,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    Widget? prefix,
    Widget? suffix,
    bool enabled = true,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
  }) {
    return FormFieldWrapper(
      key: key,
      label: label,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      child: _StyledTextField(
        controller: controller,
        hint: hint,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validator,
        prefix: prefix,
        suffix: suffix,
        enabled: enabled,
        focusNode: focusNode,
        textInputAction: textInputAction,
        hasError: errorText != null && errorText.isNotEmpty,
      ),
    );
  }

  /// Static method for creating dropdown fields
  /// 
  /// Usage:
  /// ```dart
  /// FormFieldWrapper.dropdown<String>(
  ///   value: selectedValue,
  ///   items: [...],
  ///   onChanged: (v) => setState(() => selectedValue = v),
  /// )
  /// ```
  static FormFieldWrapper dropdown<T>({
    Key? key,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? label,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    String? hint,
    Widget? icon,
    bool enabled = true,
  }) {
    return FormFieldWrapper(
      key: key,
      label: label,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      child: _StyledDropdown<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        hint: hint,
        icon: icon,
        hasError: errorText != null && errorText.isNotEmpty,
      ),
    );
  }

  /// Factory constructor for checkbox fields
  factory FormFieldWrapper.checkbox({
    Key? key,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    String? label,
    String? title,
    String? subtitle,
    String? helperText,
    bool enabled = true,
  }) {
    return FormFieldWrapper(
      key: key,
      label: label,
      helperText: helperText,
      child: _StyledCheckbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  /// Factory constructor for switch fields
  factory FormFieldWrapper.switchField({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    String? label,
    String? title,
    String? subtitle,
    String? helperText,
    bool enabled = true,
  }) {
    return FormFieldWrapper(
      key: key,
      label: label,
      helperText: helperText,
      child: _StyledSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePadding = padding ?? const EdgeInsets.only(bottom: AppSpacing.md);
    
    return Semantics(
      label: semanticLabel ?? label,
      child: Padding(
        padding: effectivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) _buildLabel(context, isDark),
            child,
            if (errorText != null && errorText!.isNotEmpty)
              _buildErrorText(context)
            else if (helperText != null && helperText!.isNotEmpty)
              _buildHelperText(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label!,
            style: labelStyle ?? TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (showInfoTooltip && infoTooltipMessage != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: infoTooltipMessage!,
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ],
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
              errorText!,
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
        helperText!,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.grey[600],
        ),
      ),
    );
  }
}

/// Internal styled text field widget
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark 
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
      ),
    );
  }
}

/// Internal styled dropdown widget
class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.icon,
    this.hasError = false,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final Widget? icon;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint != null ? Text(hint!) : null,
      icon: icon ?? const Icon(Icons.arrow_drop_down),
      dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark 
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Internal styled checkbox widget
class _StyledCheckbox extends StatelessWidget {
  const _StyledCheckbox({
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (title != null || subtitle != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Internal styled switch widget
class _StyledSwitch extends StatelessWidget {
  const _StyledSwitch({
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (title != null || subtitle != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
