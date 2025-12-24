# Naming Conventions Guide

**Last Updated:** December 2024  
**Status:** Active Standards

---

## 📋 Overview

This document defines the naming conventions for the Doctor App codebase. Consistent naming improves code readability, maintainability, and developer experience.

---

## 📁 File Naming

### Screens
**Pattern:** `{feature}_screen.dart`

**Examples:**
- ✅ `patients_screen.dart`
- ✅ `appointments_screen.dart`
- ✅ `add_patient_screen.dart`
- ✅ `edit_appointment_screen.dart`
- ✅ `patient_view_screen.dart`

**Rules:**
- Always use `_screen.dart` suffix
- Use lowercase with underscores (snake_case)
- Use descriptive feature names
- For add/edit screens: `add_{feature}_screen.dart` or `edit_{feature}_screen.dart`
- For detail views: `{feature}_detail_screen.dart` or `{feature}_view_screen.dart`

**❌ Avoid:**
- `dashboard_screen_modern.dart` → Should be `dashboard_screen.dart` (remove "modern")
- `patient_view.dart` → Should be `patient_view_screen.dart`
- `dashboard.dart` → Should be `dashboard_screen.dart`

---

### Widgets
**Pattern:** `{feature}_widget.dart` (singular) or `{feature}_widgets.dart` (plural for multiple widgets)

**Examples:**
- ✅ `empty_state.dart` (single widget)
- ✅ `toast.dart` (single widget)
- ✅ `patient_view_widgets.dart` (multiple related widgets)
- ✅ `record_form_widgets.dart` (multiple related widgets)

**Rules:**
- Use singular for single widget files
- Use plural for files containing multiple related widgets
- Use descriptive names without redundant "widget" if context is clear
- For shared widgets: `{feature}_widget.dart`
- For screen-specific widgets: `{screen}_widgets.dart`

**❌ Avoid:**
- Mixing singular/plural inconsistently
- Generic names like `widget.dart` or `components.dart`

---

### Services
**Pattern:** `{feature}_service.dart`

**Examples:**
- ✅ `logger_service.dart`
- ✅ `app_lock_service.dart`
- ✅ `doctor_settings_service.dart`

**Rules:**
- Always use `_service.dart` suffix
- Use lowercase with underscores
- Use descriptive feature names

**✅ Current Status:** All service files follow this convention correctly.

---

### Models
**Pattern:** `{entity}.dart` or `{entity}_model.dart`

**Examples:**
- ✅ `patient.dart`
- ✅ `appointment.dart`
- ✅ `prescription.dart`

**Rules:**
- Prefer simple entity name without suffix
- Use `_model.dart` only if there's ambiguity
- Use lowercase with underscores

**✅ Current Status:** Model files follow this convention correctly.

---

### Providers
**Pattern:** `{feature}_provider.dart`

**Examples:**
- ✅ `db_provider.dart`
- ✅ `app_lock_provider.dart`
- ✅ `audit_provider.dart`

**Rules:**
- Always use `_provider.dart` suffix
- Use lowercase with underscores

**✅ Current Status:** Provider files follow this convention correctly.

---

### Components
**Pattern:** `{feature}_component.dart` or descriptive name

**Examples:**
- ✅ `app_button.dart`
- ✅ `app_input.dart`
- ✅ `app_card.dart`

**Rules:**
- Use descriptive names
- Prefix with `app_` for core app components
- Use lowercase with underscores

---

### Utilities/Helpers
**Pattern:** `{purpose}_utils.dart` or `{purpose}.dart`

**Examples:**
- ✅ `string_utils.dart`
- ✅ `date_utils.dart`
- ✅ `input_validators.dart`

**Rules:**
- Use descriptive purpose name
- Use `_utils.dart` suffix for utility files
- Use lowercase with underscores

---

## 🏷️ Class Naming

### Screens
**Pattern:** `{Feature}Screen` (PascalCase)

**Examples:**
- ✅ `PatientsScreen`
- ✅ `AppointmentsScreen`
- ✅ `AddPatientScreen`
- ✅ `EditAppointmentScreen`
- ✅ `PatientViewScreen`

**Rules:**
- Use PascalCase
- Always end with `Screen`
- Match file name (without extension, converted to PascalCase)
- State class: `_{Feature}ScreenState`

**❌ Avoid:**
- `DashboardScreenModern` → Should be `DashboardScreen`
- `PatientView` → Should be `PatientViewScreen`

---

### Widgets
**Pattern:** `{Feature}Widget` or descriptive name

**Examples:**
- ✅ `EmptyState`
- ✅ `Toast`
- ✅ `SkeletonBox`
- ✅ `PatientCard`

**Rules:**
- Use PascalCase
- Use descriptive names
- No suffix needed if context is clear
- For reusable widgets: `{Feature}Widget`

---

### Services
**Pattern:** `{Feature}Service`

**Examples:**
- ✅ `LoggerService`
- ✅ `AppLockService`
- ✅ `DoctorSettingsService`

**Rules:**
- Use PascalCase
- Always end with `Service`
- Match file name (without extension, converted to PascalCase)

**✅ Current Status:** All services follow this convention correctly.

---

### Models
**Pattern:** `{Entity}` (PascalCase)

**Examples:**
- ✅ `Patient`
- ✅ `Appointment`
- ✅ `Prescription`

**Rules:**
- Use PascalCase
- Use singular entity name
- Match file name (without extension, converted to PascalCase)

**✅ Current Status:** Model classes follow this convention correctly.

---

### Providers
**Pattern:** `{feature}Provider` (camelCase for variable, PascalCase for class)

**Examples:**
- ✅ `final doctorDbProvider = Provider<DoctorDatabase>(...)`
- ✅ `final appLockServiceProvider = StateNotifierProvider<AppLockService, ...>(...)`

**Rules:**
- Provider variable: camelCase with `Provider` suffix
- Provider class: PascalCase with `Provider` suffix

---

## 🔤 Variable Naming

### Private Variables
**Pattern:** `_{name}` (camelCase with underscore prefix)

**Examples:**
- ✅ `_searchQuery`
- ✅ `_isLoading`
- ✅ `_patients`

**Rules:**
- Start with underscore for private members
- Use camelCase
- Use descriptive names

---

### Public Variables
**Pattern:** `{name}` (camelCase)

**Examples:**
- ✅ `patientCount`
- ✅ `isLoading`
- ✅ `selectedPatient`

**Rules:**
- Use camelCase
- Use descriptive names
- Boolean variables: prefix with `is`, `has`, `should`, `can`

---

### Constants
**Pattern:** `{NAME}` (UPPER_SNAKE_CASE)

**Examples:**
- ✅ `MAX_PATIENTS`
- ✅ `DEFAULT_TIMEOUT`
- ✅ `API_BASE_URL`

**Rules:**
- Use UPPER_SNAKE_CASE
- Use descriptive names
- Group related constants in classes

---

### Static Constants
**Pattern:** `{Name}` (PascalCase in class)

**Examples:**
- ✅ `AppSpacing.lg`
- ✅ `AppColors.primary`
- ✅ `AppRadius.md`

**Rules:**
- Use PascalCase for class name
- Use lowercase abbreviations for values
- Group related constants in classes

---

## 📂 Directory Naming

### Feature Directories
**Pattern:** `{feature}/` (lowercase, singular)

**Examples:**
- ✅ `patient_view/`
- ✅ `add_prescription/`
- ✅ `lab_orders/`

**Rules:**
- Use lowercase
- Use singular form
- Use underscores for multi-word names

---

### Component Directories
**Pattern:** `components/` or `widgets/`

**Examples:**
- ✅ `components/` (for reusable components)
- ✅ `widgets/` (for screen-specific widgets)

**Rules:**
- Use `components/` for shared/reusable components
- Use `widgets/` for screen-specific widgets

---

## 🎯 Naming Best Practices

### 1. Be Descriptive
```dart
// ✅ Good
final patientAppointments = await db.getAppointmentsForPatient(patientId);

// ❌ Bad
final apps = await db.getApps(pId);
```

### 2. Use Consistent Abbreviations
```dart
// ✅ Good
final db = doctorDatabase;
final ref = widgetRef;

// ❌ Bad
final database = doctorDatabase;
final widgetRef = widgetRef;
```

### 3. Avoid Redundant Names
```dart
// ✅ Good
class PatientService { }

// ❌ Bad
class PatientServiceService { }
```

### 4. Use Boolean Prefixes
```dart
// ✅ Good
bool isLoading;
bool hasError;
bool canEdit;
bool shouldRefresh;

// ❌ Bad
bool loading;
bool error;
bool edit;
bool refresh;
```

### 5. Use Action Verbs for Methods
```dart
// ✅ Good
Future<void> savePatient(Patient patient);
Future<void> deleteAppointment(int id);
List<Patient> getPatients();

// ❌ Bad
Future<void> patient(Patient patient);
Future<void> appointment(int id);
List<Patient> patients();
```

---

## 🔍 Current Issues & Recommendations

### Files Needing Rename

1. **`dashboard_screen_modern.dart`** → `dashboard_screen.dart`
   - Class: `DashboardScreenModern` → `DashboardScreen`
   - Reason: Remove "modern" suffix, keep only one dashboard

2. **`dashboard_screen.dart`** → Consider removing if `dashboard_screen_modern.dart` is the active one
   - Reason: Avoid duplicate screens

3. **`psychiatric_assessment_screen_modern.dart`** → `psychiatric_assessment_screen.dart`
   - Class: `PsychiatricAssessmentScreenModern` → `PsychiatricAssessmentScreen`
   - Reason: Remove "modern" suffix

4. **`pulmonary_evaluation_screen_modern.dart`** → `pulmonary_evaluation_screen.dart`
   - Class: `PulmonaryEvaluationScreenModern` → `PulmonaryEvaluationScreen`
   - Reason: Remove "modern" suffix

5. **`patient_view.dart`** → Check if this is duplicate of `patient_view_screen.dart`
   - Reason: Ensure consistency

### Widget Files Needing Review

1. **`patient_view_widgets.dart`** (in patient_view folder)
   - Check if this is duplicate of `widgets/patient_view_widgets.dart`
   - Reason: Avoid duplication

---

## 📝 Migration Plan

### Phase 1: Remove "Modern" Suffix
1. Rename `dashboard_screen_modern.dart` → `dashboard_screen.dart`
2. Update class name `DashboardScreenModern` → `DashboardScreen`
3. Update all imports and references
4. Remove old `dashboard_screen.dart` if it exists

### Phase 2: Standardize Screen Names
1. Review all screen files for consistency
2. Ensure all screens use `_screen.dart` suffix
3. Update class names to match

### Phase 3: Review Widget Files
1. Consolidate duplicate widget files
2. Standardize singular/plural usage
3. Ensure consistent naming

---

## ✅ Checklist for New Code

When creating new files, ensure:

- [ ] File name uses snake_case
- [ ] File name has appropriate suffix (`_screen.dart`, `_service.dart`, etc.)
- [ ] Class name uses PascalCase
- [ ] Class name matches file name (converted to PascalCase)
- [ ] Private variables start with `_`
- [ ] Boolean variables use appropriate prefix (`is`, `has`, `can`, `should`)
- [ ] Methods use action verbs
- [ ] Constants use UPPER_SNAKE_CASE or grouped in classes
- [ ] No redundant names
- [ ] Descriptive and clear names

---

## 📚 References

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Style Guide](https://docs.flutter.dev/development/ui/widgets-intro)
- Internal: `CODEBASE_CONTEXT.md` for existing patterns

---

*This document should be updated as naming conventions evolve.*

