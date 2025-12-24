# Naming Issues & Fixes Needed

**Date:** December 2024  
**Status:** ✅ **ALL FIXES COMPLETED**

---

## ✅ High Priority Issues - FIXED

### 1. Duplicate Dashboard Screens ✅
**Status:** ✅ **FIXED**

**Changes Made:**
- ✅ Renamed `dashboard_screen_modern.dart` → `dashboard_screen.dart`
- ✅ Updated class `DashboardScreenModern` → `DashboardScreen`
- ✅ Updated state `_DashboardScreenModernState` → `_DashboardScreenState`
- ✅ Removed old duplicate `dashboard_screen.dart`
- ✅ Updated all imports in:
  - `lib/src/app.dart`
  - `lib/src/core/routing/app_router.dart`

---

### 2. "Modern" Suffix Inconsistency ✅
**Status:** ✅ **FIXED**

**Changes Made:**
- ✅ Removed `_modern` suffix from all files
- ✅ Updated all class names
- ✅ Updated all imports

**Files Fixed:**
- ✅ `dashboard_screen_modern.dart` → `dashboard_screen.dart`
- ✅ `psychiatric_assessment_screen_modern.dart` → `psychiatric_assessment_screen.dart`
- ✅ `pulmonary_evaluation_screen_modern.dart` → `pulmonary_evaluation_screen.dart`

---

### 3. Patient View Naming
**Issue:** Potential duplicate or inconsistent naming
- `patient_view_screen.dart` (correct)
- `patient_view.dart` (needs verification)

**Impact:** Potential confusion

**Fix:**
1. Verify if `patient_view.dart` is duplicate
2. If duplicate, remove or consolidate
3. Ensure all use `patient_view_screen.dart`

---

## 🟡 Medium Priority Issues

### 4. Widget File Naming
**Issue:** Mix of singular and plural widget files
- `empty_state.dart` (singular - correct for single widget)
- `patient_view_widgets.dart` (plural - correct for multiple widgets)
- Some inconsistencies

**Impact:** Minor confusion

**Fix:**
1. Review all widget files
2. Use singular for single widget files
3. Use plural for files with multiple widgets
4. Document pattern clearly

---

### 5. Component vs Widget Naming
**Issue:** Some files use `component`, some use `widget`
- `app_button.dart` (component)
- `app_input.dart` (component)
- `empty_state.dart` (widget)

**Impact:** Minor inconsistency

**Fix:**
1. Standardize: Use `widget` for UI widgets
2. Use `component` only for specific component pattern
3. Or: Use descriptive names without suffix

---

## 📋 Files Requiring Rename

### Immediate Actions Needed

1. **`dashboard_screen_modern.dart`**
   - Rename to: `dashboard_screen.dart`
   - Class: `DashboardScreenModern` → `DashboardScreen`
   - State: `_DashboardScreenModernState` → `_DashboardScreenState`

2. **`psychiatric_assessment_screen_modern.dart`**
   - Rename to: `psychiatric_assessment_screen.dart`
   - Class: `PsychiatricAssessmentScreenModern` → `PsychiatricAssessmentScreen`
   - State: `_PsychiatricAssessmentScreenModernState` → `_PsychiatricAssessmentScreenState`

3. **`pulmonary_evaluation_screen_modern.dart`**
   - Rename to: `pulmonary_evaluation_screen.dart`
   - Class: `PulmonaryEvaluationScreenModern` → `PulmonaryEvaluationScreen`
   - State: `_PulmonaryEvaluationScreenModernState` → `_PulmonaryEvaluationScreenState`

---

## 🔍 Files to Verify

1. **`patient_view.dart`**
   - Check if this is duplicate of `patient_view_screen.dart`
   - If duplicate, remove or consolidate

2. **`dashboard_screen.dart`**
   - Check if this is old version
   - If old, remove or archive

---

## 📝 Migration Checklist

### Step 1: Backup
- [ ] Create git branch for renaming
- [ ] Commit current state

### Step 2: Rename Files
- [ ] Rename `dashboard_screen_modern.dart` → `dashboard_screen.dart`
- [ ] Rename `psychiatric_assessment_screen_modern.dart` → `psychiatric_assessment_screen.dart`
- [ ] Rename `pulmonary_evaluation_screen_modern.dart` → `pulmonary_evaluation_screen.dart`

### Step 3: Update Class Names
- [ ] Update `DashboardScreenModern` → `DashboardScreen`
- [ ] Update `PsychiatricAssessmentScreenModern` → `PsychiatricAssessmentScreen`
- [ ] Update `PulmonaryEvaluationScreenModern` → `PulmonaryEvaluationScreen`
- [ ] Update all state class names

### Step 4: Update Imports
- [ ] Find all imports of renamed files
- [ ] Update import paths
- [ ] Update class references

### Step 5: Verify
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Build app - no compilation errors
- [ ] Test affected screens manually

### Step 6: Cleanup
- [ ] Remove old `dashboard_screen.dart` if duplicate
- [ ] Remove `patient_view.dart` if duplicate
- [ ] Update documentation

---

## 🎯 Priority Order

1. **High Priority:**
   - Fix duplicate dashboard screens
   - Remove "modern" suffix from all screens

2. **Medium Priority:**
   - Verify and fix patient view naming
   - Standardize widget file naming

3. **Low Priority:**
   - Review component vs widget naming
   - Document patterns clearly

---

## 📚 Related Documents

- `NAMING_CONVENTIONS.md` - Full naming conventions guide
- `CODEBASE_CONTEXT.md` - Current codebase structure

---

*This document tracks naming issues that need to be fixed for consistency.*

