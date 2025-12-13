/// Medication Components Library
/// 
/// Reusable components for medication management in prescription screens.
/// 
/// ## Components Overview
/// 
/// ### Models
/// - [MedicationData] - Data model for a medication entry
/// - [MedicationFrequency] - Common medication frequencies (OD, BD, TDS, etc.)
/// - [MedicationTiming] - Medication timing options (Before/After Food, etc.)
/// - [MedicationDuration] - Duration quick picks (3 days, 7 days, etc.)
/// - [PrescriptionTemplate] - Quick template for common conditions
/// - [PrescriptionTemplates] - Database of 12 quick prescription templates
/// 
/// ### Selectors
/// - [FrequencySelector] - Chip-based frequency selector
/// - [TimingSelector] - Chip-based timing selector
/// - [DurationQuickPicks] - Quick duration selection chips
/// - [FrequencyDropdown] - Dropdown variant for frequency
/// - [QuickPrescriptionSelector] - Quick template selector with cards/chips
/// 
/// ### Cards
/// - [MedicationCard] - Full medication card with actions
/// - [MedicationSummaryCard] - Compact read-only medication display
/// - [EmptyMedicationsState] - Empty state placeholder
/// 
/// ### Database
/// - [MedicineDatabase] - Comprehensive medicine database with categories
/// - [MedicineSelectorGrid] - Grid for selecting from database (supports multi-select)
/// 
/// ### Sheets
/// - [EditMedicationSheet] - Bottom sheet for editing medication
/// - [showMedicationEditSheet] - Helper to show the edit sheet
/// 
/// ### Common Widgets
/// - [SafetyAlertsBanner] - Drug interaction/allergy warnings
/// - [PatientAllergiesChip] - Patient allergies display
/// - [SmallActionButton] - Section header action button
/// - [VitalDisplayCard] - Vital signs display
/// - [LabTestChip] - Lab test selection chip
/// - [FollowUpQuickPick] - Follow-up date quick picks
/// - [PrescriptionSectionCard] - Section container card
/// 
/// ### Theme
/// - [MedColors] - Theme colors for medication components
/// - [MedicationInputDecoration] - Input decoration builder
/// - [MedicationContainerStyle] - Container decoration helpers
/// - [MedicationInputLabel] - Styled input label
/// - [MedicationTag] - Colored tag/badge component
library;

// Models
export 'medication_models.dart';

// Theme and styling
export 'medication_theme.dart';

// Selectors
export 'medication_selectors.dart';

// Cards
export 'medication_cards.dart';

// Medicine database
export 'medicine_database.dart';

// Edit sheet
export 'medication_edit_sheet.dart';

// Common widgets
export 'prescription_common_widgets.dart';
