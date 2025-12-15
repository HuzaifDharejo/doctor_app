import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/db_provider.dart';
import '../../../../services/dynamic_suggestions_service.dart';

/// A mixin that provides automatic suggestion saving for medical record forms.
/// 
/// When the form is saved, this mixin extracts text from configured controllers
/// and saves any new entries to the suggestions database. This enables the app
/// to "learn" from user input and provide better autocomplete over time.
/// 
/// Usage in a ConsumerStatefulWidget:
/// ```dart
/// class _AddRecordScreenState extends ConsumerState<AddRecordScreen> 
///     with SuggestionSavingMixin {
///   
///   @override
///   Map<SuggestionCategory, TextEditingController> get suggestionControllers => {
///     SuggestionCategory.chiefComplaint: _chiefComplaintController,
///     SuggestionCategory.diagnosis: _diagnosisController,
///     SuggestionCategory.treatment: _treatmentController,
///     SuggestionCategory.clinicalNotes: _notesController,
///   };
///   
///   Future<void> _saveRecord() async {
///     // ... save logic ...
///     
///     // Save suggestions from form fields
///     await saveSuggestionsFromControllers();
///   }
/// }
/// ```
mixin SuggestionSavingMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Override this to provide the mapping of suggestion categories to controllers
  Map<SuggestionCategory, TextEditingController> get suggestionControllers;

  /// Save all non-empty controller values as suggestions
  /// Call this in your save method after the record is saved successfully
  Future<void> saveSuggestionsFromControllers() async {
    try {
      final service = await ref.read(dynamicSuggestionsProvider.future);
      
      for (final entry in suggestionControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          await service.addOrUpdateSuggestion(entry.key, value);
        }
      }
    } catch (e) {
      // Silently ignore - suggestions are enhancement, not critical
      debugPrint('SuggestionSavingMixin: Error saving suggestions: $e');
    }
  }

  /// Record usage of a specific suggestion (when user selects from autocomplete)
  Future<void> recordSuggestionUsage(SuggestionCategory category, String value) async {
    try {
      final service = await ref.read(dynamicSuggestionsProvider.future);
      await service.recordUsage(category, value);
    } catch (e) {
      debugPrint('SuggestionSavingMixin: Error recording usage: $e');
    }
  }
}

/// Extension for saving suggestions without the mixin
/// Use this in screens that can't use the mixin (e.g., StatelessWidget)
extension SuggestionSaving on WidgetRef {
  /// Save a single suggestion
  Future<void> saveSuggestion(SuggestionCategory category, String value) async {
    if (value.trim().isEmpty) return;
    try {
      final service = await read(dynamicSuggestionsProvider.future);
      await service.addOrUpdateSuggestion(category, value);
    } catch (e) {
      debugPrint('SuggestionSaving: Error saving suggestion: $e');
    }
  }

  /// Save multiple suggestions at once
  Future<void> saveSuggestions(Map<SuggestionCategory, String> suggestions) async {
    try {
      final service = await read(dynamicSuggestionsProvider.future);
      for (final entry in suggestions.entries) {
        if (entry.value.trim().isNotEmpty) {
          await service.addOrUpdateSuggestion(entry.key, entry.value);
        }
      }
    } catch (e) {
      debugPrint('SuggestionSaving: Error saving suggestions: $e');
    }
  }

  /// Save suggestions from controllers
  Future<void> saveSuggestionsFromControllers(
    Map<SuggestionCategory, TextEditingController> controllers,
  ) async {
    try {
      final service = await read(dynamicSuggestionsProvider.future);
      for (final entry in controllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          await service.addOrUpdateSuggestion(entry.key, value);
        }
      }
    } catch (e) {
      debugPrint('SuggestionSaving: Error saving suggestions: $e');
    }
  }
}
