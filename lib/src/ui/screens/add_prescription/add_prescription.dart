// Barrel file for add_prescription module

// Export popup but hide MedicationData which is now in components
export 'medication_popup.dart' hide MedicationData;

// Export prescription widgets but hide classes that are now in components
export 'prescription_widgets.dart' hide 
    PrescriptionSectionCard,
    SmallActionButton,
    SafetyAlertsBanner,
    PatientAllergiesChip,
    MedicationSummaryCard,
    EmptyMedicationsState,
    VitalDisplayCard,
    LabTestChip,
    FollowUpQuickPick;

// Reusable components (MedicationData and other shared models/components)
export 'components/medication_components.dart';
