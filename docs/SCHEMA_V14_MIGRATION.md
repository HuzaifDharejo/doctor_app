# Schema V14 Migration Guide

## Overview

Schema V14 completes the normalization of prescription data by adding dedicated fields for follow-up information and clinical notes, and linking lab orders directly to prescriptions.

## Changes

### 1. Prescriptions Table
- **Added:** `followUpDate` (DateTime, nullable)
- **Added:** `followUpNotes` (Text)
- **Added:** `clinicalNotes` (Text)

### 2. LabOrders Table
- **Added:** `prescriptionId` (Int, nullable, foreign key to Prescriptions)

## Migration

The migration runs automatically when the app starts. It:
1. Adds the new columns to existing tables
2. Preserves all existing data
3. New prescriptions will use the normalized fields
4. Old data in itemsJson continues to work via helper methods

## Code Changes Required

### When Creating Prescriptions

**Before:**
```dart
itemsJson: jsonEncode({
  'follow_up': {'date': date, 'notes': notes},
  'notes': clinicalNotes,
})
```

**After:**
```dart
followUpDate: Value(followUpDate),
followUpNotes: Value(followUpNotes),
clinicalNotes: Value(clinicalNotes),
// itemsJson still maintained for backwards compatibility
```

### When Creating Lab Orders

**Before:**
```dart
createLabOrder(
  encounterId: encounterId,
  // ...
)
```

**After:**
```dart
createLabOrder(
  encounterId: encounterId,
  prescriptionId: prescriptionId, // V6: Direct link
  // ...
)
```

### When Reading Data

Always use helper methods:
```dart
// Lab tests
final labTests = await db.getLabTestsForPrescriptionCompat(prescriptionId);

// Follow-up
final followUp = await db.getFollowUpForPrescriptionCompat(prescriptionId);

// Notes
final notes = await db.getClinicalNotesForPrescriptionCompat(prescriptionId);
```

## Backwards Compatibility

- ✅ Old prescriptions with data in itemsJson continue to work
- ✅ Helper methods automatically read from normalized fields first, then fall back to JSON
- ✅ No data loss during migration
- ✅ Can migrate old data to new fields later

## Testing

After migration, verify:
1. New prescriptions save to normalized fields
2. Old prescriptions still display correctly
3. Lab orders are linked to prescriptions
4. PDF generation works with both old and new data

