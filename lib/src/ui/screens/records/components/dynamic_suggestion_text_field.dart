import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/db_provider.dart';
import '../../../../services/dynamic_suggestions_service.dart';
import 'styled_text_fields.dart';

/// A text field that loads suggestions dynamically from the database
/// and saves new entries when the user types something not in the list.
/// 
/// This is a wrapper around StyledTextField that integrates with
/// DynamicSuggestionsService to:
/// 1. Load suggestions from built-in + user-added database entries
/// 2. Auto-save new entries when user submits (on focus loss or save)
/// 
/// Example:
/// ```dart
/// DynamicSuggestionTextField(
///   label: 'Chief Complaint',
///   controller: _chiefComplaintController,
///   category: SuggestionCategory.chiefComplaint,
///   isRequired: true,
///   enableVoice: true,
/// )
/// ```
class DynamicSuggestionTextField extends ConsumerStatefulWidget {
  const DynamicSuggestionTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.category,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.accentColor,
    this.helperText,
    this.autofocus = false,
    this.enableVoice = false,
    this.onChanged,
    this.focusNode,
    this.onSubmitted,
    this.onEditingComplete,
    this.autoSaveOnFocusLost = true,
  });

  /// Field label
  final String label;
  
  /// Text controller
  final TextEditingController controller;
  
  /// Category for suggestions (determines which list to load/save)
  final SuggestionCategory category;
  
  /// Placeholder hint text
  final String? hint;
  
  /// Leading icon
  final IconData? icon;
  
  /// Maximum number of lines
  final int maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum character count
  final int? maxLength;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Validation function
  final String? Function(String?)? validator;
  
  /// Whether input is enabled
  final bool enabled;
  
  /// Whether input is read-only
  final bool readOnly;
  
  /// Accent color for focus state
  final Color? accentColor;
  
  /// Helper text shown below input
  final String? helperText;
  
  /// Autofocus on mount
  final bool autofocus;
  
  /// Enable voice dictation button
  final bool enableVoice;
  
  /// Callback when value changes
  final ValueChanged<String>? onChanged;
  
  /// Focus node
  final FocusNode? focusNode;
  
  /// Callback when submitted
  final ValueChanged<String>? onSubmitted;
  
  /// Callback when editing complete
  final VoidCallback? onEditingComplete;
  
  /// Auto-save new suggestions when focus is lost
  final bool autoSaveOnFocusLost;

  @override
  ConsumerState<DynamicSuggestionTextField> createState() => _DynamicSuggestionTextFieldState();
}

class _DynamicSuggestionTextFieldState extends ConsumerState<DynamicSuggestionTextField> {
  List<String> _suggestions = [];
  late FocusNode _focusNode;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _lastSavedValue = widget.controller.text;
    _loadSuggestions();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final suggestionsService = await ref.read(dynamicSuggestionsProvider.future);
    final loaded = await suggestionsService.getSuggestions(widget.category);
    if (mounted) {
      setState(() => _suggestions = loaded);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.autoSaveOnFocusLost) {
      _saveIfNew();
    }
  }

  Future<void> _saveIfNew() async {
    final value = widget.controller.text.trim();
    if (value.isEmpty || value == _lastSavedValue) return;
    
    _lastSavedValue = value;
    
    try {
      final suggestionsService = await ref.read(dynamicSuggestionsProvider.future);
      await suggestionsService.addOrUpdateSuggestion(widget.category, value);
      // Refresh suggestions
      await _loadSuggestions();
    } catch (e) {
      // Silently ignore errors - suggestions are not critical
      debugPrint('Error saving suggestion: $e');
    }
  }

  void _onSuggestionSelected(String suggestion) {
    // Record that this suggestion was used
    ref.read(dynamicSuggestionsProvider.future).then((service) {
      service.recordUsage(widget.category, suggestion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      icon: widget.icon,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      isRequired: widget.isRequired,
      validator: widget.validator,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      accentColor: widget.accentColor,
      helperText: widget.helperText,
      autofocus: widget.autofocus,
      enableVoice: widget.enableVoice,
      suggestions: _suggestions,
      onSuggestionSelected: _onSuggestionSelected,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      onSubmitted: (value) {
        _saveIfNew();
        widget.onSubmitted?.call(value);
      },
      onEditingComplete: () {
        _saveIfNew();
        widget.onEditingComplete?.call();
      },
    );
  }
}

/// Extension to easily convert common section fields to use dynamic suggestions
/// Usage: In save methods, call this to record what the user entered
extension SuggestionRecorder on DynamicSuggestionsService {
  /// Record multiple field values at once when saving a form
  Future<void> recordFormFields(Map<SuggestionCategory, String> fields) async {
    for (final entry in fields.entries) {
      if (entry.value.trim().isNotEmpty) {
        await addOrUpdateSuggestion(entry.key, entry.value);
      }
    }
  }
}
