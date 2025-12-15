/// Medical Record Form Components
/// 
/// A collection of reusable UI components for building medical record forms
/// in the doctor app. These components provide consistent styling and behavior
/// across all record types (general, lab results, imaging, procedures, etc.)
/// 
/// Usage:
/// ```dart
/// import 'package:doctor_app/src/ui/screens/records/components/record_components.dart';
/// ```

// Form sections and layout
export 'record_form_section.dart';

// Patient selection
export 'patient_selector_card.dart';

// Date and time pickers
export 'date_picker_card.dart';

// Text input fields
export 'record_text_fields.dart';

// Buttons and actions
export 'record_buttons.dart';

// Chip selectors (categories, risk levels, etc.)
// Hide ChipSelectorSection and RiskLevel since we have newer versions
export 'chip_selectors.dart' hide ChipSelectorSection, RiskLevel;

// Vital signs input
export 'vitals_input_section.dart';

// Quick fill templates
// Hide showTemplateAppliedSnackbar since we have a newer version in quick_fill_template_bar.dart
export 'quick_fill_templates.dart' hide showTemplateAppliedSnackbar;

// Form progress indicator
export 'form_progress_indicator.dart';

// Auto-save / draft service
export '../../../../services/form_draft_service.dart';

// ============================================================================
// NEW REUSABLE COMPONENTS - Phase 2 Refactoring
// ============================================================================

// Chip selector section - replaces _buildChipSection() pattern
export 'chip_selector_section.dart';

// Styled dropdowns - replaces _buildDropdown() pattern
export 'styled_dropdown.dart';

// Quick fill template bar - unified template UI
export 'quick_fill_template_bar.dart';

// Switch/toggle rows - for boolean fields
export 'switch_row.dart';

// Styled text fields - numeric, notes, multiline
export 'styled_text_fields.dart';

// Finding/observation rows - Normal/Abnormal status
export 'finding_row.dart';

// ============================================================================
// NEW REUSABLE COMPONENTS - Phase 3 Refactoring (More Reusable)
// ============================================================================

// Base mixin for all record screens - common state and utilities
export 'base_record_mixin.dart';

// Common form sections - ChiefComplaint, Assessment, Investigations, Notes
export 'common_sections.dart';

// Record data builder - standardized save/load pattern
export 'record_data_builder.dart';

// Enhanced record scaffold - full-featured layout with gradient header, nav, FAB
export 'enhanced_record_scaffold.dart';

// Quick picker bottom sheet - workflow-style multi-select with icons
export 'quick_picker_bottom_sheet.dart';

// Dynamic suggestion text field - auto-learning suggestions from user input
export 'dynamic_suggestion_text_field.dart';

// Suggestion saving mixin - for forms to save user input as suggestions
export 'suggestion_saving_mixin.dart';

// Re-export the suggestion categories for easy access
export '../../../../services/dynamic_suggestions_service.dart' show SuggestionCategory;
