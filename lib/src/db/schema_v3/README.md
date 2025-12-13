# Schema V3: Fully Normalized Database Design

## Overview

Schema V3 represents a comprehensive redesign of the database to properly normalize all data that was previously stored as JSON blobs or comma-separated text fields.

## Problem

The original schema stored complex data in JSON columns:
- `Prescriptions.itemsJson` - medications and lab tests as JSON array
- `Invoices.itemsJson` - invoice line items as JSON array
- `FamilyMedicalHistory.conditions` - conditions as JSON array
- `MedicationResponses.sideEffects` - side effects as JSON array
- `ClinicalNotes.mentalStatusExam` - MSE findings as JSON object
- `LabOrders.testCodes/testNames` - tests as JSON arrays
- `Patients.allergies` - comma-separated text
- And many more...

### Issues with JSON Storage

1. **No SQL Querying**: Can't query "all patients on medication X" or "all patients with side effect Y"
2. **No Referential Integrity**: Can't enforce foreign keys or cascading deletes
3. **No Indexing**: Slow searches through JSON data
4. **Difficult Reporting**: Analytics require parsing JSON in application code
5. **Data Duplication**: Same medication name stored differently across records

## Solution: New Normalized Tables

### 1. PrescriptionMedications
Individual medications linked to prescriptions with full details:
- Medication name, generic name, brand name
- Drug code (RxNorm, NDC)
- Strength, dosage form, route
- Frequency, timing, duration
- Quantity, refills
- Before/after/with food flags
- Status (active, completed, discontinued)

### 2. InvoiceLineItems
Individual line items for invoices:
- Item type (service, medication, procedure, lab)
- Description, CPT/HCPCS codes
- Links to appointments, prescriptions, lab orders
- Unit price, quantity, discounts, taxes
- Total amount

### 3. FamilyConditions
Individual conditions for family medical history:
- Condition name, ICD code
- Category (cardiovascular, cancer, etc.)
- Age at onset, severity, outcome

### 4. TreatmentSymptoms
Track symptoms being treated:
- Symptom name and category
- Baseline, current, and target severity
- Improvement level and percentage

### 5. SideEffects
Track medication/treatment side effects:
- Effect name and category
- Severity score
- Onset and resolution dates
- Management action taken

### 6. Attachments
Centralized file attachments:
- Links to any entity (clinical notes, referrals, etc.)
- File metadata (name, path, type, size)
- Categories and confidentiality flags

### 7. MentalStatusExams
Structured mental status exam findings:
- Appearance, grooming, behavior
- Speech characteristics
- Mood, affect, thought process
- Hallucinations, delusions
- Suicidal/homicidal ideation
- Cognition, insight, judgment

### 8. LabTestResults
Individual test results within lab orders:
- Test name and LOINC code
- Result value, unit, type
- Reference range
- Abnormal/critical flags
- Trends vs previous values

### 9. ProgressNoteEntries
Individual progress note entries:
- Entry date and note text
- Progress rating and status
- Barriers and interventions used

### 10. TreatmentInterventions
Track interventions used in treatment:
- Intervention name and type
- Modality (CBT, DBT, etc.)
- Effectiveness rating
- Patient response

### 11. ClaimBillingCodes
Billing codes for insurance claims:
- Code type (diagnosis, procedure, modifier)
- Code value and description
- Charged amount and units

### 12. PatientAllergies
Individual patient allergies:
- Allergen and type (medication, food, etc.)
- Reaction type and severity
- Status and verification

### 13. PatientChronicConditions
Individual chronic conditions:
- Condition name and ICD code
- Status and severity
- Current treatment
- Review dates

## Migration Strategy

### Phase 1: Create Tables (Non-Destructive)
```dart
// Run migration SQL statements to create new tables
await SchemaV3Migration.createTableStatements.forEach((sql) async {
  await db.customStatement(sql);
});
```

### Phase 2: Migrate Data
```dart
// Migrate existing JSON data to new tables
final migrator = SchemaV3DataMigrator(db);
final result = await migrator.migrateAll();
print(result);
```

### Phase 3: Verify Data
```dart
// Verify data integrity
final medications = await db.customSelect(
  'SELECT COUNT(*) as count FROM prescription_medications'
).getSingle();
print('Migrated ${medications.read<int>('count')} medications');
```

### Phase 4: Update Services (Future)
Update service classes to use new normalized tables instead of JSON:

**Before:**
```dart
// Old way - parsing JSON
final prescription = await prescriptionDao.getById(id);
final items = jsonDecode(prescription.itemsJson) as List;
final medications = items.where((i) => i['type'] != 'labTest').toList();
```

**After:**
```dart
// New way - direct query
final medications = await db.select(db.prescriptionMedications)
  .where((m) => m.prescriptionId.equals(prescriptionId))
  .get();
```

### Phase 5: Remove Deprecated Columns (Future)
In a future release, remove the deprecated JSON columns:
```sql
ALTER TABLE prescriptions DROP COLUMN items_json;
ALTER TABLE invoices DROP COLUMN items_json;
-- etc.
```

## Benefits

### 1. Full SQL Querying
```sql
-- Find all patients on a specific medication
SELECT DISTINCT p.* 
FROM patients p
JOIN prescription_medications pm ON p.id = pm.patient_id
WHERE pm.medication_name LIKE '%Sertraline%';

-- Find patients with specific side effects
SELECT DISTINCT p.* 
FROM patients p
JOIN side_effects se ON p.id = se.patient_id
WHERE se.effect_name LIKE '%weight gain%';
```

### 2. Better Analytics
```sql
-- Most prescribed medications
SELECT medication_name, COUNT(*) as count
FROM prescription_medications
GROUP BY medication_name
ORDER BY count DESC
LIMIT 10;

-- Side effect frequency by medication
SELECT pm.medication_name, se.effect_name, COUNT(*) as count
FROM prescription_medications pm
JOIN side_effects se ON se.prescription_medication_id = pm.id
GROUP BY pm.medication_name, se.effect_name
ORDER BY count DESC;
```

### 3. Drug Interaction Checking
```dart
// Check for interactions across ALL patient medications
final allMedications = await db.select(db.prescriptionMedications)
  .where((m) => m.patientId.equals(patientId))
  .where((m) => m.status.equals('active'))
  .get();

// Now check interactions with standardized drug codes
```

### 4. Referential Integrity
- Cascading deletes when parent records are removed
- Foreign key constraints prevent orphaned records
- Data consistency guaranteed at database level

### 5. Performance
- Indexed columns for fast lookups
- No JSON parsing overhead
- Efficient joins for complex queries

## Files

| File | Description |
|------|-------------|
| `schema_v3_design.dart` | Drift table definitions for new tables |
| `schema_v3_migration.dart` | SQL CREATE TABLE statements |
| `schema_v3_data_migrator.dart` | Service to migrate JSON data |
| `schema_v3.dart` | Export file |

## Usage

```dart
import 'package:doctor_app/src/db/schema_v3/schema_v3.dart';

// In your database migration
Future<void> upgradeToV3(DoctorDatabase db) async {
  // 1. Create tables
  for (final sql in SchemaV3Migration.createTableStatements) {
    await db.customStatement(sql);
  }
  
  // 2. Migrate data
  final migrator = SchemaV3DataMigrator(db);
  final result = await migrator.migrateAll();
  
  if (result.success) {
    print('Migration complete! ${result.totalMigrated} records migrated.');
  } else {
    print('Migration failed: ${result.error}');
  }
}
```
