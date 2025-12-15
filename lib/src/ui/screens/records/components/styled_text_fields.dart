import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../services/voice_dictation_service.dart';

/// A styled text input field for medical record forms
/// 
/// Provides consistent styling, validation indicators, and medical-specific
/// features like character limits, multi-line support, voice dictation,
/// and autocomplete suggestions.
/// 
/// Example:
/// ```dart
/// StyledTextField(
///   label: 'Chief Complaint',
///   controller: _chiefComplaintController,
///   maxLines: 3,
///   isRequired: true,
///   enableVoice: true,
///   suggestions: ['Fever', 'Cough', 'Headache'],
/// )
/// ```
class StyledTextField extends StatefulWidget {
  const StyledTextField({
    super.key,
    required this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.accentColor,
    this.helperText,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.focusNode,
    this.onSubmitted,
    this.onEditingComplete,
    this.enableVoice = false,
    this.suggestions,
    this.onSuggestionSelected,
  });

  /// Field label
  final String label;
  
  /// Text controller (alternative to value/onChanged)
  final TextEditingController? controller;
  
  /// Current value (used when controller is null)
  final String? value;
  
  /// Callback when value changes
  final ValueChanged<String>? onChanged;
  
  /// Placeholder hint text
  final String? hint;
  
  /// Leading icon
  final IconData? icon;
  
  /// Maximum number of lines (set > 1 for multiline)
  final int maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum character count
  final int? maxLength;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Validation function
  final String? Function(String?)? validator;
  
  /// Keyboard type
  final TextInputType? keyboardType;
  
  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Whether input is enabled
  final bool enabled;
  
  /// Whether input is read-only
  final bool readOnly;
  
  /// Obscure text (for passwords)
  final bool obscureText;
  
  /// Widget to show after the input
  final Widget? suffixIcon;
  
  /// Text to show before input
  final String? prefixText;
  
  /// Text to show after input
  final String? suffixText;
  
  /// Accent color for focus state
  final Color? accentColor;
  
  /// Helper text shown below input
  final String? helperText;
  
  /// Autofocus on mount
  final bool autofocus;
  
  /// Text capitalization mode
  final TextCapitalization textCapitalization;
  
  /// Focus node
  final FocusNode? focusNode;
  
  /// Callback when submitted
  final ValueChanged<String>? onSubmitted;
  
  /// Callback when editing complete
  final VoidCallback? onEditingComplete;
  
  /// Enable voice dictation button
  final bool enableVoice;
  
  /// List of suggestions to show as user types
  final List<String>? suggestions;
  
  /// Callback when a suggestion is selected
  final ValueChanged<String>? onSuggestionSelected;

  @override
  State<StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  late TextEditingController _internalController;
  final VoiceDictationService _dictationService = VoiceDictationService();
  bool _isListening = false;
  bool _voiceAvailable = false;
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];
  final FocusNode _internalFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController(text: widget.value);
    
    if (widget.enableVoice) {
      _initVoice();
    }
    
    if (widget.suggestions != null && widget.suggestions!.isNotEmpty) {
      _internalController.addListener(_onTextChanged);
      (widget.focusNode ?? _internalFocusNode).addListener(_onFocusChanged);
    }
  }

  Future<void> _initVoice() async {
    final available = await _dictationService.initialize();
    if (mounted) {
      setState(() => _voiceAvailable = available);
    }
  }

  void _onTextChanged() {
    if (widget.suggestions == null) return;
    
    final text = _internalController.text.toLowerCase();
    if (text.length < 2) {
      _hideSuggestions();
      return;
    }
    
    // Get last word being typed
    final words = text.split(RegExp(r'[,.\s]+'));
    final lastWord = words.isNotEmpty ? words.last : '';
    
    if (lastWord.length < 2) {
      _hideSuggestions();
      return;
    }
    
    _filteredSuggestions = widget.suggestions!
        .where((s) => s.toLowerCase().contains(lastWord) && 
                      !text.contains(s.toLowerCase()))
        .take(5)
        .toList();
    
    if (_filteredSuggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestions();
    }
  }

  void _onFocusChanged() {
    if (!(widget.focusNode ?? _internalFocusNode).hasFocus) {
      _hideSuggestions();
    }
  }

  void _showSuggestionsOverlay() {
    _hideSuggestions();
    
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: context.findRenderObject() != null 
            ? (context.findRenderObject() as RenderBox).size.width 
            : 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: _buildSuggestionsDropdown(),
          ),
        ),
      ),
    );
    
    overlay.insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _showSuggestions = false);
    }
  }

  Widget _buildSuggestionsDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.accentColor ?? Theme.of(context).primaryColor;
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _filteredSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _filteredSuggestions[index];
          return InkWell(
            onTap: () => _selectSuggestion(suggestion),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    final currentText = _internalController.text;
    final words = currentText.split(RegExp(r'[,.\s]+'));
    
    // Replace last partial word with suggestion
    if (words.isNotEmpty) {
      words.removeLast();
      final newText = words.isEmpty 
          ? suggestion 
          : '${words.join(', ')}, $suggestion';
      _internalController.text = newText;
      _internalController.selection = TextSelection.collapsed(offset: newText.length);
    }
    
    _hideSuggestions();
    widget.onChanged?.call(_internalController.text);
    widget.onSuggestionSelected?.call(suggestion);
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _dictationService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _dictationService.startListening(
        onResult: (text) {
          if (mounted && text.isNotEmpty) {
            final currentText = _internalController.text;
            final newText = currentText.isEmpty 
                ? text 
                : '$currentText $text';
            _internalController.text = newText;
            _internalController.selection = TextSelection.collapsed(offset: newText.length);
            widget.onChanged?.call(newText);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Voice error: $error')),
            );
          }
        },
        onStatusChange: (listening) {
          if (mounted) {
            setState(() => _isListening = listening);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _hideSuggestions();
    if (widget.controller == null) {
      _internalController.dispose();
    }
    _dictationService.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.accentColor ?? Theme.of(context).primaryColor;

    // Build suffix icon with voice button if enabled
    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.enableVoice && _voiceAvailable) {
      effectiveSuffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.suffixIcon != null) widget.suffixIcon!,
          GestureDetector(
            onTap: _toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isListening 
                    ? Colors.red 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 20,
                color: _isListening 
                    ? Colors.white 
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              ),
            ),
          ),
        ],
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                if (widget.isRequired) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                // Voice indicator
                if (_isListening)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
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
                        Text(
                          'Listening...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Text field
          TextFormField(
            controller: _internalController,
            onChanged: (value) {
              widget.onChanged?.call(value);
            },
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            textCapitalization: widget.textCapitalization,
            focusNode: widget.focusNode ?? _internalFocusNode,
            onFieldSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixText: widget.prefixText,
              suffixText: widget.suffixText,
              suffixIcon: effectiveSuffixIcon,
              helperText: widget.helperText,
              helperStyle: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: _isListening 
                  ? Colors.red.withValues(alpha: 0.05)
                  : (isDark 
                      ? Colors.grey.shade800.withValues(alpha: 0.5) 
                      : Colors.grey.shade50),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isListening 
                      ? Colors.red.withValues(alpha: 0.5)
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isListening ? Colors.red : effectiveColor, 
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.maxLines > 1 ? 14 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A numeric input field with stepper buttons
/// 
/// Example:
/// ```dart
/// NumericField(
///   label: 'Blood Pressure (Systolic)',
///   value: _systolic,
///   onChanged: (v) => setState(() => _systolic = v),
///   unit: 'mmHg',
///   min: 60,
///   max: 300,
/// )
/// ```
class NumericField extends StatefulWidget {
  const NumericField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.unit,
    this.icon,
    this.isRequired = false,
    this.accentColor,
    this.showStepper = true,
    this.decimalPlaces = 0,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  final double? min;
  final double? max;
  final double step;
  final String? unit;
  final IconData? icon;
  final bool isRequired;
  final Color? accentColor;
  final bool showStepper;
  final int decimalPlaces;

  @override
  State<NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<NumericField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null 
          ? widget.value!.toStringAsFixed(widget.decimalPlaces)
          : '',
    );
  }

  @override
  void didUpdateWidget(NumericField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = widget.value != null 
          ? widget.value!.toStringAsFixed(widget.decimalPlaces)
          : '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    final current = widget.value ?? 0;
    final newValue = current + widget.step;
    if (widget.max == null || newValue <= widget.max!) {
      widget.onChanged(newValue);
    }
  }

  void _decrement() {
    final current = widget.value ?? 0;
    final newValue = current - widget.step;
    if (widget.min == null || newValue >= widget.min!) {
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.accentColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Input row
        Row(
          children: [
            if (widget.showStepper) ...[
              _StepperButton(
                icon: Icons.remove,
                onPressed: _decrement,
                color: effectiveColor,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.decimalPlaces > 0,
                ),
                textAlign: TextAlign.center,
                onChanged: (text) {
                  final value = double.tryParse(text);
                  widget.onChanged(value);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(widget.decimalPlaces > 0 
                        ? r'^\d*\.?\d*$' 
                        : r'^\d*$'),
                  ),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
                decoration: InputDecoration(
                  suffixText: widget.unit,
                  suffixStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: isDark 
                      ? Colors.grey.shade800.withValues(alpha: 0.5) 
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: effectiveColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            if (widget.showStepper) ...[
              const SizedBox(width: 8),
              _StepperButton(
                icon: Icons.add,
                onPressed: _increment,
                color: effectiveColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

/// Multi-line notes field with expandable support
/// 
/// Example:
/// ```dart
/// NotesField(
///   label: 'Clinical Notes',
///   value: _notes,
///   onChanged: (v) => setState(() => _notes = v),
///   expandable: true,
/// )
/// ```
class NotesField extends StatefulWidget {
  const NotesField({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.controller,
    this.hint,
    this.icon,
    this.minLines = 3,
    this.maxLines = 10,
    this.maxLength,
    this.expandable = false,
    this.accentColor,
  });

  final String label;
  final String? value;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool expandable;
  final Color? accentColor;

  @override
  State<NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<NotesField> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = widget.accentColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            if (widget.expandable) ...[
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isExpanded 
                      ? Icons.unfold_less_rounded 
                      : Icons.unfold_more_rounded,
                  size: 18,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                tooltip: _isExpanded ? 'Collapse' : 'Expand',
                color: effectiveColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Text field
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.value : null,
          onChanged: widget.onChanged,
          minLines: _isExpanded ? widget.maxLines : widget.minLines,
          maxLines: _isExpanded ? null : widget.maxLines,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Enter notes here...',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: isDark 
                ? Colors.grey.shade800.withValues(alpha: 0.5) 
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: effectiveColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}
