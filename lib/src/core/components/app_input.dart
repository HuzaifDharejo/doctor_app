import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Unified form field component for all text inputs
/// Provides consistent styling and behavior across the app
class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final bool showLabel;
  final bool showBorder;
  final Color? backgroundColor;
  final int? maxLength;
  final bool showCharacterCount;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const AppInput({
    Key? key,
    this.label,
    this.hint,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.controller,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.showLabel = true,
    this.showBorder = true,
    this.backgroundColor,
    this.maxLength,
    this.showCharacterCount = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  /// Text input variant
  factory AppInput.text({
    String? label,
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint,
        initialValue: initialValue,
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        enabled: enabled,
        keyboardType: TextInputType.text,
      );

  /// Email input variant
  factory AppInput.email({
    String? label = 'Email Address',
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint ?? 'name@example.com',
        initialValue: initialValue,
        controller: controller,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Invalid email address';
              return null;
            },
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        prefixIcon: Icons.email_outlined,
      );

  /// Phone input variant
  factory AppInput.phone({
    String? label = 'Phone Number',
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint ?? '+1 (555) 000-0000',
        initialValue: initialValue,
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone_outlined,
      );

  /// Number input variant
  factory AppInput.number({
    String? label,
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint,
        initialValue: initialValue,
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.number,
      );

  /// Password input variant
  factory AppInput.password({
    String? label = 'Password',
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint,
        initialValue: initialValue,
        controller: controller,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        prefixIcon: Icons.lock_outlined,
        suffixIcon: Icons.visibility_outlined,
      );

  /// Multiline text input variant
  factory AppInput.multiline({
    String? label,
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLines = 4,
    int? minLines = 2,
    int? maxLength,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        label: label,
        hint: hint,
        initialValue: initialValue,
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.multiline,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        showCharacterCount: maxLength != null,
      );

  /// Search input variant
  factory AppInput.search({
    String? hint = 'Search...',
    TextEditingController? controller,
    void Function(String)? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
    Key? key,
  }) =>
      AppInput(
        key: key,
        hint: hint,
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        prefixIcon: Icons.search,
        suffixIcon: Icons.close,
        showLabel: false,
      );

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscureText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.enabled ? colorScheme.onSurface : colorScheme.outline,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          obscureText: _obscureText,
          enabled: widget.enabled,
          obscuringCharacter: '●',
          validator: widget.validator,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          onFieldSubmitted: widget.onSubmitted,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colorScheme.outline.withOpacity(0.7),
              fontSize: AppFontSize.bodyMedium,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: colorScheme.outline)
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: widget.suffixIcon != null
                ? SizedBox(
                    width: 40,
                    child: InkWell(
                      onTap: _obscureText && widget.obscureText
                          ? _toggleObscureText
                          : widget.onSuffixIconPressed,
                      child: Icon(
                        _obscureText && widget.obscureText
                            ? Icons.visibility_off_outlined
                            : widget.suffixIcon,
                        color: colorScheme.outline,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: widget.backgroundColor ??
                (isDarkMode
                    ? colorScheme.surface.withOpacity(0.5)
                    : colorScheme.surfaceVariant.withOpacity(0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: widget.showBorder ? colorScheme.outline : Colors.transparent,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: widget.showBorder ? colorScheme.outline : Colors.transparent,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.38),
                width: 1.5,
              ),
            ),
            errorStyle: TextStyle(
              color: colorScheme.error,
              fontSize: AppFontSize.labelMedium,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            counterText: widget.showCharacterCount ? null : '',
            counterStyle: TextStyle(
              color: colorScheme.outline,
              fontSize: AppFontSize.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}
