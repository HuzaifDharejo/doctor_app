# Data Storage Improvements - Unified Approach

## Current Problems

1. **Inconsistent Data Storage:**
   - Medications: ✅ Normalized in `PrescriptionMedications` table
   - Lab Tests: ❌ Still in JSON (`itemsJson`)
   - Follow-up: ❌ Still in JSON (`itemsJson`)
   - Notes: ❌ Still in JSON (`itemsJson`)
   - Invoice Items: ✅ Normalized in `InvoiceLineItems` table

2. **Issues with Current Approach:**
   - Can't query lab tests directly from database
   - Can't link lab orders to prescriptions properly
   - Follow-up data is buried in JSON
   - Inconsistent access patterns across the app
   - Difficult to maintain and extend

## Proposed Solution

### 1. Database Schema Changes

#### Add fields to Prescriptions table:
```dart
DateTimeColumn get followUpDate => dateTime().nullable()();
TextColumn get followUpNotes => text().withDefault(const Constant(''))();
TextColumn get clinicalNotes => text().withDefault(const Constant(''))(); // Rename from itemsJson notes
```

#### Link LabOrders to Prescriptions:
- Add `prescriptionId` to `LabOrders` table (already has encounterId)
- This creates proper relationship: Prescription → LabOrders → LabTestResults

### 2. Migration Strategy

1. **Phase 1: Add new fields** (non-breaking)
   - Add `followUpDate`, `followUpNotes`, `clinicalNotes` to Prescriptions
   - Add `prescriptionId` to LabOrders

2. **Phase 2: Migrate existing data**
   - Parse `itemsJson` and populate new fields
   - Link existing lab orders to prescriptions

3. **Phase 3: Update code**
   - Update all screens to use new fields
   - Create helper methods for consistent access
   - Deprecate JSON parsing

### 3. Helper Methods

Create consistent database access methods:
```dart
// Get lab tests for a prescription
Future<List<LabTestResult>> getLabTestsForPrescription(int prescriptionId);

// Get follow-up info for a prescription  
Future<Map<String, dynamic>?> getFollowUpForPrescription(int prescriptionId);

// Get complete prescription data (medications + lab tests + follow-up)
Future<PrescriptionData> getCompletePrescriptionData(int prescriptionId);
```

### 4. Benefits

- ✅ Consistent data access patterns
- ✅ Queryable lab tests and follow-ups
- ✅ Proper foreign key relationships
- ✅ Better performance (indexed fields)
- ✅ Easier to maintain and extend
- ✅ Type-safe data access

## Implementation Plan

1. ✅ Create database helper methods (getLabTestsForPrescriptionCompat, getFollowUpForPrescriptionCompat, getClinicalNotesForPrescriptionCompat)
2. ✅ Update prescriptions_screen to use helper methods
3. ✅ Update PDF service to use helper methods
4. ✅ Update add_prescription_screen to save lab tests in itemsJson (for now)
5. ⏳ Future: Add prescriptionId to LabOrders table
6. ⏳ Future: Add followUpDate and followUpNotes fields to Prescriptions table
7. ⏳ Future: Migrate existing data from JSON to normalized tables

## What Was Implemented

### 1. Database Helper Methods
Created three new helper methods in `doctor_db.dart`:
- `getLabTestsForPrescriptionCompat()` - Gets lab tests from LabOrders (via encounterId) or falls back to itemsJson
- `getFollowUpForPrescriptionCompat()` - Gets follow-up from ScheduledFollowUps or falls back to itemsJson
- `getClinicalNotesForPrescriptionCompat()` - Gets notes from itemsJson

### 2. Updated Screens
- **prescriptions_screen.dart**: Now uses helper methods instead of parsing JSON directly
- **pdf_service.dart**: Now uses helper methods with fallback to JSON parsing

### 3. Benefits
- ✅ Consistent data access patterns across the app
- ✅ Backwards compatible (works with old JSON data)
- ✅ Easier to maintain (single source of truth for data access)
- ✅ Ready for future normalization (can migrate to tables later)

## ✅ COMPLETED - Full Normalization (Schema V14)

### Database Schema Changes

1. ✅ **Added to Prescriptions table:**
   - `followUpDate` (DateTime, nullable) - Normalized follow-up date
   - `followUpNotes` (Text) - Normalized follow-up notes
   - `clinicalNotes` (Text) - Normalized clinical notes

2. ✅ **Added to LabOrders table:**
   - `prescriptionId` (Int, nullable, foreign key) - Direct link to prescription

3. ✅ **Schema Version:** Updated to 14 with migration code

### Code Updates

1. ✅ **Helper Methods Updated:**
   - `getLabTestsForPrescriptionCompat()` - Now checks prescriptionId first, then encounterId, then itemsJson
   - `getFollowUpForPrescriptionCompat()` - Now checks Prescriptions.followUpDate/followUpNotes first
   - `getClinicalNotesForPrescriptionCompat()` - Now checks Prescriptions.clinicalNotes first

2. ✅ **add_prescription_screen.dart:**
   - Saves follow-up to normalized fields (followUpDate, followUpNotes)
   - Saves notes to normalized field (clinicalNotes)
   - Links lab orders via prescriptionId
   - Still maintains itemsJson for backwards compatibility

3. ✅ **LabOrderService:**
   - Added prescriptionId parameter to createLabOrder()
   - Lab orders now directly linked to prescriptions

4. ✅ **All Screens:**
   - Use helper methods for consistent data access
   - Backwards compatible with old JSON data

### Data Flow

**New Prescriptions:**
1. Follow-up → `Prescriptions.followUpDate` and `Prescriptions.followUpNotes`
2. Notes → `Prescriptions.clinicalNotes`
3. Lab Tests → `LabOrders` table (linked via `prescriptionId`)
4. Medications → `PrescriptionMedications` table

**Reading Data:**
1. Helper methods check normalized fields first
2. Fall back to itemsJson for old records
3. All screens use same helper methods

### Benefits Achieved

- ✅ **Fully Normalized:** All prescription data in proper database tables
- ✅ **Queryable:** Can query lab tests, follow-ups directly
- ✅ **Type-Safe:** Proper foreign key relationships
- ✅ **Backwards Compatible:** Works with existing JSON data
- ✅ **Consistent:** Single source of truth via helper methods
- ✅ **Performance:** Indexed fields for faster queries

### Migration Notes

- Existing data in itemsJson will continue to work
- New prescriptions use normalized fields
- Helper methods automatically migrate data on read
- Can run data migration script later to move old data to new fields

