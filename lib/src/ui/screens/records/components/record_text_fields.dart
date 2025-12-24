import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/voice_dictation_service.dart';
import 'quick_picker_bottom_sheet.dart';

/// A styled text input field for medical record forms
/// Supports various configurations including multi-line, prefix/suffix icons,
/// voice dictation, and autocomplete suggestions.
class RecordTextField extends StatefulWidget {
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
    this.enableVoice = false,
    this.suggestions,
    this.onSuggestionSelected,
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
  
  /// Whether to show voice dictation button
  final bool enableVoice;
  
  /// List of suggestions to show as autocomplete
  final List<String>? suggestions;
  
  /// Callback when a suggestion is selected
  final ValueChanged<String>? onSuggestionSelected;

  @override
  State<RecordTextField> createState() => _RecordTextFieldState();
}

class _RecordTextFieldState extends State<RecordTextField> {
  final VoiceDictationService _voiceService = VoiceDictationService();
  bool _isListening = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late FocusNode _internalFocusNode;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    _internalFocusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    if (!_internalFocusNode.hasFocus) {
      _removeOverlay();
    } else {
      _updateSuggestions();
    }
  }

  void _onTextChanged() {
    _updateSuggestions();
  }

  void _updateSuggestions() {
    if (widget.suggestions == null || widget.suggestions!.isEmpty) return;
    
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    // Get last word being typed (for multi-line content)
    final words = text.split(RegExp(r'[\s,;.]+'));
    final lastWord = words.isNotEmpty ? words.last : '';
    
    if (lastWord.length < 2) {
      _removeOverlay();
      return;
    }

    _filteredSuggestions = widget.suggestions!
        .where((s) => s.toLowerCase().contains(lastWord))
        .take(6)
        .toList();

    if (_filteredSuggestions.isNotEmpty && _internalFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.accentColor ?? AppColors.primary,
                  width: 1,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    widget.onSuggestionSelected?.call(suggestion);
    _removeOverlay();
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      final available = await _voiceService.initialize();
      if (!available) return;
      
      setState(() => _isListening = true);
      
      await _voiceService.startListening(
        onResult: (text) {
          if (!mounted) return;
          if (text.isNotEmpty) {
            try {
              final current = widget.controller.text;
              if (current.isEmpty) {
                widget.controller.text = text;
              } else {
                widget.controller.text = '$current $text';
              }
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.controller.text.length),
              );
            } catch (e) {
              // Controller may be disposed
              debugPrint('Voice dictation: Controller disposed or invalid: $e');
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatusChange: (isListening) {
          if (mounted) {
            setState(() => _isListening = isListening);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.accentColor ?? AppColors.primary;

    // Build suffix widget with voice button
    Widget? suffix = widget.suffixIcon;
    if (widget.enableVoice) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.suffixIcon != null) widget.suffixIcon!,
          GestureDetector(
            onTap: _toggleVoice,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isListening 
                      ? Colors.red.withValues(alpha: 0.1) 
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isListening ? Colors.red : color,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_isListening) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Listening...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Text field with suggestions - wrapped to prevent overflow
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.helperText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: color, size: 20)
                  : null,
              suffixIcon: suffix,
              suffixText: widget.suffixText,
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
                vertical: (widget.maxLines ?? 1) == 1 ? 14 : 12,
              ),
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: widget.maxLines ?? 1,
            minLines: widget.minLines ?? ((widget.maxLines ?? 1) > 1 ? widget.maxLines : 1),
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            validator: widget.validator,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            textInputAction: widget.textInputAction ?? ((widget.maxLines ?? 1) > 1 ? TextInputAction.newline : TextInputAction.done),
            onFieldSubmitted: widget.onSubmitted,
            // Ensure text can scroll when it exceeds bounds
            textAlignVertical: (widget.maxLines ?? 1) > 1 ? TextAlignVertical.top : null,
          ),
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
    this.enableVoice = false,
    this.suggestions,
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
  final bool enableVoice;
  final List<String>? suggestions;

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
      enableVoice: enableVoice,
      suggestions: suggestions,
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
