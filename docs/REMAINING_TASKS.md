# Remaining Tasks - Schema V14 Implementation

## ✅ Completed

1. ✅ Database schema changes (Prescriptions.followUpDate, followUpNotes, clinicalNotes)
2. ✅ Database schema changes (LabOrders.prescriptionId)
3. ✅ Schema version updated to 14 with migration code
4. ✅ Helper methods created and updated
5. ✅ add_prescription_screen.dart - saves to normalized fields
6. ✅ prescriptions_screen.dart - reads from normalized fields via helpers
7. ✅ pdf_service.dart - reads from normalized fields via helpers
8. ✅ LabOrderService - accepts prescriptionId parameter

## ⏳ Remaining Tasks

### 1. Run Build Runner (REQUIRED)
**Status:** ⚠️ **CRITICAL - Must be done before running app**

After schema changes, you MUST run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This regenerates the database code (`doctor_db.g.dart`) with the new fields.

**Why:** The generated code needs to include the new `followUpDate`, `followUpNotes`, `clinicalNotes`, and `prescriptionId` fields.

### 2. Optional: Update edit_prescription_screen
**Status:** ⚠️ **Optional** - Currently read-only for follow-up/notes

The `edit_prescription_screen.dart` is currently a simplified edit screen that only allows editing medications and instructions. It doesn't have UI for editing follow-up or clinical notes.

**Options:**
- **Option A:** Leave as-is (read-only view) - Users can view but not edit follow-up/notes
- **Option B:** Add UI fields for follow-up and notes editing

**If choosing Option B:**
- Add controllers: `_followUpDate`, `_followUpNotesController`, `_clinicalNotesController`
- Load from helper methods in `_loadPrescriptionData()`
- Save to normalized fields in `_savePrescription()`

### 3. Optional: Data Migration Script
**Status:** ⏳ **Optional** - Can be done later

Create a script to migrate existing data from `itemsJson` to normalized fields:
- Parse `itemsJson` for old prescriptions
- Extract `follow_up` → populate `followUpDate` and `followUpNotes`
- Extract `notes` → populate `clinicalNotes`
- Link existing lab orders to prescriptions via `encounterId` → `prescriptionId`

**Note:** This is optional because helper methods already handle reading from both sources.

### 4. Testing Checklist
**Status:** ⏳ **Should be done after build_runner**

- [ ] Run build_runner successfully
- [ ] App starts without errors
- [ ] Create new prescription with follow-up and notes
- [ ] Verify data saved to normalized fields
- [ ] View prescription - verify follow-up and notes display
- [ ] Create prescription with lab tests - verify lab orders linked
- [ ] View old prescriptions - verify still work (backwards compatibility)
- [ ] Generate PDF - verify lab tests and follow-up appear
- [ ] Edit prescription - verify medications update correctly

## Summary

**Critical (Must Do):**
1. ⚠️ Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Optional (Nice to Have):**
2. Add follow-up/notes editing to edit_prescription_screen
3. Create data migration script for old prescriptions

**Testing:**
4. Test all prescription workflows after build_runner

## Next Steps

1. **Immediate:** Run build_runner
2. **After build_runner:** Test the app
3. **If issues:** Check generated code matches schema
4. **Optional:** Enhance edit screen or create migration script

