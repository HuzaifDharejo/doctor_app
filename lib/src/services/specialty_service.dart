/// Service for managing doctor specialties and specialty-specific configurations
/// This enables the app to work for any type of doctor

import 'package:flutter/material.dart';

/// List of supported medical specialties
enum DoctorSpecialty {
  generalPractice,
  internalMedicine,
  cardiology,
  pulmonology,
  psychiatry,
  orthopedics,
  dermatology,
  pediatrics,
  gynecology,
  ent,
  ophthalmology,
  neurology,
  gastroenterology,
  nephrology,
  endocrinology,
  oncology,
  urology,
  rheumatology,
  other,
}

/// Extension to get display names and icons for specialties
extension DoctorSpecialtyExtension on DoctorSpecialty {
  /// Get the IconData for this specialty
  IconData get icon {
    switch (this) {
      case DoctorSpecialty.generalPractice:
        return Icons.medical_services_rounded;
      case DoctorSpecialty.internalMedicine:
        return Icons.local_hospital_rounded;
      case DoctorSpecialty.cardiology:
        return Icons.favorite_rounded;
      case DoctorSpecialty.pulmonology:
        return Icons.air_rounded;
      case DoctorSpecialty.psychiatry:
        return Icons.psychology_rounded;
      case DoctorSpecialty.orthopedics:
        return Icons.accessibility_new_rounded;
      case DoctorSpecialty.dermatology:
        return Icons.face_rounded;
      case DoctorSpecialty.pediatrics:
        return Icons.child_care_rounded;
      case DoctorSpecialty.gynecology:
        return Icons.pregnant_woman_rounded;
      case DoctorSpecialty.ent:
        return Icons.hearing_rounded;
      case DoctorSpecialty.ophthalmology:
        return Icons.visibility_rounded;
      case DoctorSpecialty.neurology:
        return Icons.psychology_alt_rounded;
      case DoctorSpecialty.gastroenterology:
        return Icons.lunch_dining_rounded;
      case DoctorSpecialty.nephrology:
        return Icons.water_drop_rounded;
      case DoctorSpecialty.endocrinology:
        return Icons.biotech_rounded;
      case DoctorSpecialty.oncology:
        return Icons.healing_rounded;
      case DoctorSpecialty.urology:
        return Icons.medical_information_rounded;
      case DoctorSpecialty.rheumatology:
        return Icons.accessibility_rounded;
      case DoctorSpecialty.other:
        return Icons.local_hospital_rounded;
    }
  }
  String get displayName {
    switch (this) {
      case DoctorSpecialty.generalPractice:
        return 'General Practice / Family Medicine';
      case DoctorSpecialty.internalMedicine:
        return 'Internal Medicine';
      case DoctorSpecialty.cardiology:
        return 'Cardiology';
      case DoctorSpecialty.pulmonology:
        return 'Pulmonology';
      case DoctorSpecialty.psychiatry:
        return 'Psychiatry / Mental Health';
      case DoctorSpecialty.orthopedics:
        return 'Orthopedics';
      case DoctorSpecialty.dermatology:
        return 'Dermatology';
      case DoctorSpecialty.pediatrics:
        return 'Pediatrics';
      case DoctorSpecialty.gynecology:
        return 'Gynecology / Obstetrics';
      case DoctorSpecialty.ent:
        return 'ENT (Ear, Nose, Throat)';
      case DoctorSpecialty.ophthalmology:
        return 'Ophthalmology';
      case DoctorSpecialty.neurology:
        return 'Neurology';
      case DoctorSpecialty.gastroenterology:
        return 'Gastroenterology';
      case DoctorSpecialty.nephrology:
        return 'Nephrology';
      case DoctorSpecialty.endocrinology:
        return 'Endocrinology';
      case DoctorSpecialty.oncology:
        return 'Oncology';
      case DoctorSpecialty.urology:
        return 'Urology';
      case DoctorSpecialty.rheumatology:
        return 'Rheumatology';
      case DoctorSpecialty.other:
        return 'Other Specialty';
    }
  }

  String get shortName {
    switch (this) {
      case DoctorSpecialty.generalPractice:
        return 'General Practice';
      case DoctorSpecialty.internalMedicine:
        return 'Internal Medicine';
      case DoctorSpecialty.cardiology:
        return 'Cardiology';
      case DoctorSpecialty.pulmonology:
        return 'Pulmonology';
      case DoctorSpecialty.psychiatry:
        return 'Psychiatry';
      case DoctorSpecialty.orthopedics:
        return 'Orthopedics';
      case DoctorSpecialty.dermatology:
        return 'Dermatology';
      case DoctorSpecialty.pediatrics:
        return 'Pediatrics';
      case DoctorSpecialty.gynecology:
        return 'Gynecology';
      case DoctorSpecialty.ent:
        return 'ENT';
      case DoctorSpecialty.ophthalmology:
        return 'Ophthalmology';
      case DoctorSpecialty.neurology:
        return 'Neurology';
      case DoctorSpecialty.gastroenterology:
        return 'Gastroenterology';
      case DoctorSpecialty.nephrology:
        return 'Nephrology';
      case DoctorSpecialty.endocrinology:
        return 'Endocrinology';
      case DoctorSpecialty.oncology:
        return 'Oncology';
      case DoctorSpecialty.urology:
        return 'Urology';
      case DoctorSpecialty.rheumatology:
        return 'Rheumatology';
      case DoctorSpecialty.other:
        return 'Other';
    }
  }

  String get iconName {
    switch (this) {
      case DoctorSpecialty.generalPractice:
        return 'medical_services';
      case DoctorSpecialty.internalMedicine:
        return 'local_hospital';
      case DoctorSpecialty.cardiology:
        return 'favorite';
      case DoctorSpecialty.pulmonology:
        return 'air';
      case DoctorSpecialty.psychiatry:
        return 'psychology';
      case DoctorSpecialty.orthopedics:
        return 'accessibility_new';
      case DoctorSpecialty.dermatology:
        return 'face';
      case DoctorSpecialty.pediatrics:
        return 'child_care';
      case DoctorSpecialty.gynecology:
        return 'pregnant_woman';
      case DoctorSpecialty.ent:
        return 'hearing';
      case DoctorSpecialty.ophthalmology:
        return 'visibility';
      case DoctorSpecialty.neurology:
        return 'psychology_alt';
      case DoctorSpecialty.gastroenterology:
        return 'lunch_dining';
      case DoctorSpecialty.nephrology:
        return 'water_drop';
      case DoctorSpecialty.endocrinology:
        return 'biotech';
      case DoctorSpecialty.oncology:
        return 'healing';
      case DoctorSpecialty.urology:
        return 'medical_information';
      case DoctorSpecialty.rheumatology:
        return 'accessibility';
      case DoctorSpecialty.other:
        return 'local_hospital';
    }
  }

  /// Get the storage key for this specialty
  String get storageKey => name;

  /// Parse specialty from storage key
  static DoctorSpecialty? fromStorageKey(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      return DoctorSpecialty.values.firstWhere((s) => s.name == key);
    } catch (_) {
      return null;
    }
  }

  /// Parse specialty from display name (for backward compatibility)
  static DoctorSpecialty? fromDisplayName(String? name) {
    if (name == null || name.isEmpty) return null;
    final lowerName = name.toLowerCase();
    
    // Try exact match first
    for (final specialty in DoctorSpecialty.values) {
      if (specialty.displayName.toLowerCase() == lowerName ||
          specialty.shortName.toLowerCase() == lowerName) {
        return specialty;
      }
    }
    
    // Try partial match
    for (final specialty in DoctorSpecialty.values) {
      if (lowerName.contains(specialty.shortName.toLowerCase()) ||
          specialty.displayName.toLowerCase().contains(lowerName)) {
        return specialty;
      }
    }
    
    return null;
  }
}

/// Record type categories
enum RecordTypeCategory {
  universal,    // Available to all specialties
  specialty,    // Specialty-specific records
  documentation, // Certificates, letters, etc.
}

/// Medical record type definition
class RecordTypeDefinition {
  const RecordTypeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.category,
    this.specialties = const [],
    this.screenRoute,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final List<int> gradientColors; // Two colors for gradient
  final RecordTypeCategory category;
  final List<DoctorSpecialty> specialties; // Empty means universal
  final String? screenRoute;

  /// Check if this record type is relevant for a specialty
  bool isRelevantFor(DoctorSpecialty? specialty) {
    if (category == RecordTypeCategory.universal) return true;
    if (specialties.isEmpty) return true;
    if (specialty == null) return true;
    return specialties.contains(specialty);
  }
}

/// Service that provides specialty-aware record types
class SpecialtyService {
  const SpecialtyService();

  /// Get all available record types
  static List<RecordTypeDefinition> get allRecordTypes => [
    // === UNIVERSAL RECORD TYPES ===
    const RecordTypeDefinition(
      id: 'general_consultation',
      title: 'General\nConsultation',
      description: 'Standard medical visit',
      icon: 'medical_services',
      gradientColors: [0xFF10B981, 0xFF059669],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'follow_up',
      title: 'Follow-up\nVisit',
      description: 'Progress check',
      icon: 'event_repeat',
      gradientColors: [0xFFF59E0B, 0xFFD97706],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'prescription',
      title: 'Prescription\nRecord',
      description: 'Medication records',
      icon: 'medication',
      gradientColors: [0xFF3B82F6, 0xFF2563EB],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'vitals',
      title: 'Vitals\nRecord',
      description: 'BP, weight, temperature',
      icon: 'monitor_heart',
      gradientColors: [0xFFEF4444, 0xFFDC2626],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'lab_result',
      title: 'Lab\nResult',
      description: 'Laboratory tests',
      icon: 'science',
      gradientColors: [0xFF14B8A6, 0xFF0D9488],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'imaging',
      title: 'Imaging /\nRadiology',
      description: 'X-Ray, CT, MRI, etc.',
      icon: 'image',
      gradientColors: [0xFF6366F1, 0xFF4F46E5],
      category: RecordTypeCategory.universal,
    ),
    const RecordTypeDefinition(
      id: 'procedure',
      title: 'Medical\nProcedure',
      description: 'Surgical procedures',
      icon: 'healing',
      gradientColors: [0xFFEC4899, 0xFFDB2777],
      category: RecordTypeCategory.universal,
    ),
    
    // === DOCUMENTATION TYPES ===
    const RecordTypeDefinition(
      id: 'certificate',
      title: 'Medical\nCertificate',
      description: 'Fitness, sick leave',
      icon: 'description',
      gradientColors: [0xFF8B5CF6, 0xFF7C3AED],
      category: RecordTypeCategory.documentation,
    ),
    const RecordTypeDefinition(
      id: 'referral',
      title: 'Referral\nLetter',
      description: 'Specialist referral',
      icon: 'send',
      gradientColors: [0xFF06B6D4, 0xFF0891B2],
      category: RecordTypeCategory.documentation,
    ),
    
    // === SPECIALTY-SPECIFIC RECORD TYPES ===
    
    // ====== CARDIOLOGY ======
    const RecordTypeDefinition(
      id: 'cardiac_examination',
      title: 'Cardiac\nExamination',
      description: 'Heart evaluation',
      icon: 'favorite',
      gradientColors: [0xFFEF4444, 0xFFDC2626],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.cardiology, DoctorSpecialty.internalMedicine],
    ),
    const RecordTypeDefinition(
      id: 'ecg_report',
      title: 'ECG\nReport',
      description: 'Electrocardiogram findings',
      icon: 'monitor_heart',
      gradientColors: [0xFFF43F5E, 0xFFE11D48],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.cardiology, DoctorSpecialty.internalMedicine, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'echo_report',
      title: 'Echo\nReport',
      description: 'Echocardiography findings',
      icon: 'favorite_border',
      gradientColors: [0xFFDC2626, 0xFFB91C1C],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.cardiology],
    ),
    
    // ====== PULMONOLOGY ======
    const RecordTypeDefinition(
      id: 'pulmonary_evaluation',
      title: 'Pulmonary\nEvaluation',
      description: 'Respiratory assessment',
      icon: 'air',
      gradientColors: [0xFF06B6D4, 0xFF0891B2],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pulmonology, DoctorSpecialty.internalMedicine, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'pft_report',
      title: 'PFT\nReport',
      description: 'Pulmonary function test',
      icon: 'speed',
      gradientColors: [0xFF0891B2, 0xFF0E7490],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pulmonology],
    ),
    
    // ====== PSYCHIATRY ======
    const RecordTypeDefinition(
      id: 'psychiatric_assessment',
      title: 'Psychiatric\nAssessment',
      description: 'Mental health evaluation',
      icon: 'psychology',
      gradientColors: [0xFF8B5CF6, 0xFF7C3AED],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.psychiatry, DoctorSpecialty.neurology, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'mood_tracking',
      title: 'Mood\nTracking',
      description: 'PHQ-9, GAD-7 scores',
      icon: 'sentiment_satisfied',
      gradientColors: [0xFF7C3AED, 0xFF6D28D9],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.psychiatry],
    ),
    const RecordTypeDefinition(
      id: 'therapy_session',
      title: 'Therapy\nSession',
      description: 'Counseling notes',
      icon: 'forum',
      gradientColors: [0xFFA78BFA, 0xFF8B5CF6],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.psychiatry],
    ),
    
    // ====== PEDIATRICS ======
    const RecordTypeDefinition(
      id: 'pediatric_checkup',
      title: 'Pediatric\nCheckup',
      description: 'Child health visit',
      icon: 'child_care',
      gradientColors: [0xFFFBBF24, 0xFFF59E0B],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pediatrics, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'vaccination_record',
      title: 'Vaccination\nRecord',
      description: 'Immunization tracking',
      icon: 'vaccines',
      gradientColors: [0xFF22C55E, 0xFF16A34A],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pediatrics, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'growth_chart',
      title: 'Growth\nChart',
      description: 'Height, weight percentiles',
      icon: 'trending_up',
      gradientColors: [0xFFF59E0B, 0xFFD97706],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pediatrics],
    ),
    const RecordTypeDefinition(
      id: 'developmental_milestone',
      title: 'Developmental\nMilestone',
      description: 'Motor, language, social',
      icon: 'emoji_people',
      gradientColors: [0xFFFBBF24, 0xFFEAB308],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.pediatrics],
    ),
    
    // ====== DERMATOLOGY ======
    const RecordTypeDefinition(
      id: 'skin_examination',
      title: 'Skin\nExamination',
      description: 'Dermatology assessment',
      icon: 'face',
      gradientColors: [0xFFF472B6, 0xFFEC4899],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.dermatology],
    ),
    const RecordTypeDefinition(
      id: 'skin_lesion',
      title: 'Skin\nLesion',
      description: 'Lesion documentation',
      icon: 'radio_button_checked',
      gradientColors: [0xFFEC4899, 0xFFDB2777],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.dermatology],
    ),
    const RecordTypeDefinition(
      id: 'dermoscopy',
      title: 'Dermoscopy\nReport',
      description: 'Dermoscopic findings',
      icon: 'camera',
      gradientColors: [0xFFDB2777, 0xFFBE185D],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.dermatology],
    ),
    
    // ====== OPHTHALMOLOGY ======
    const RecordTypeDefinition(
      id: 'eye_examination',
      title: 'Eye\nExamination',
      description: 'Vision assessment',
      icon: 'visibility',
      gradientColors: [0xFF22D3EE, 0xFF06B6D4],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ophthalmology],
    ),
    const RecordTypeDefinition(
      id: 'visual_acuity',
      title: 'Visual\nAcuity',
      description: 'VA, refraction test',
      icon: 'visibility',
      gradientColors: [0xFF06B6D4, 0xFF0891B2],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ophthalmology],
    ),
    const RecordTypeDefinition(
      id: 'fundoscopy',
      title: 'Fundoscopy\nReport',
      description: 'Retinal examination',
      icon: 'remove_red_eye',
      gradientColors: [0xFF0891B2, 0xFF0E7490],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ophthalmology],
    ),
    const RecordTypeDefinition(
      id: 'iop_measurement',
      title: 'IOP\nMeasurement',
      description: 'Intraocular pressure',
      icon: 'speed',
      gradientColors: [0xFF14B8A6, 0xFF0D9488],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ophthalmology],
    ),
    
    // ====== ENT ======
    const RecordTypeDefinition(
      id: 'ent_examination',
      title: 'ENT\nExamination',
      description: 'Ear, nose, throat',
      icon: 'hearing',
      gradientColors: [0xFFA78BFA, 0xFF8B5CF6],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ent],
    ),
    const RecordTypeDefinition(
      id: 'audiometry',
      title: 'Audiometry\nReport',
      description: 'Hearing test results',
      icon: 'hearing',
      gradientColors: [0xFF8B5CF6, 0xFF7C3AED],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ent],
    ),
    const RecordTypeDefinition(
      id: 'nasal_endoscopy',
      title: 'Nasal\nEndoscopy',
      description: 'Rhinoscopy findings',
      icon: 'search',
      gradientColors: [0xFF7C3AED, 0xFF6D28D9],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.ent],
    ),
    
    // ====== ORTHOPEDICS ======
    const RecordTypeDefinition(
      id: 'orthopedic_exam',
      title: 'Orthopedic\nExamination',
      description: 'Musculoskeletal',
      icon: 'accessibility_new',
      gradientColors: [0xFF34D399, 0xFF10B981],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.orthopedics],
    ),
    const RecordTypeDefinition(
      id: 'joint_examination',
      title: 'Joint\nExamination',
      description: 'ROM, stability test',
      icon: 'accessibility',
      gradientColors: [0xFF10B981, 0xFF059669],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.orthopedics, DoctorSpecialty.rheumatology],
    ),
    const RecordTypeDefinition(
      id: 'fracture_documentation',
      title: 'Fracture\nDocumentation',
      description: 'Bone injury records',
      icon: 'broken_image',
      gradientColors: [0xFF059669, 0xFF047857],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.orthopedics],
    ),
    const RecordTypeDefinition(
      id: 'cast_splint',
      title: 'Cast/Splint\nApplication',
      description: 'Immobilization record',
      icon: 'healing',
      gradientColors: [0xFF047857, 0xFF065F46],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.orthopedics],
    ),
    
    // ====== GYNECOLOGY / OBSTETRICS ======
    const RecordTypeDefinition(
      id: 'gyn_examination',
      title: 'GYN\nExamination',
      description: 'Gynecology visit',
      icon: 'pregnant_woman',
      gradientColors: [0xFFF9A8D4, 0xFFF472B6],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gynecology],
    ),
    const RecordTypeDefinition(
      id: 'prenatal_visit',
      title: 'Prenatal\nVisit',
      description: 'Pregnancy checkup',
      icon: 'pregnant_woman',
      gradientColors: [0xFFFDA4AF, 0xFFFB7185],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gynecology],
    ),
    const RecordTypeDefinition(
      id: 'fetal_monitoring',
      title: 'Fetal\nMonitoring',
      description: 'FHR, NST, CTG',
      icon: 'monitor_heart',
      gradientColors: [0xFFFB7185, 0xFFF43F5E],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gynecology],
    ),
    const RecordTypeDefinition(
      id: 'pap_smear',
      title: 'Pap\nSmear',
      description: 'Cervical screening',
      icon: 'biotech',
      gradientColors: [0xFFF472B6, 0xFFEC4899],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gynecology],
    ),
    const RecordTypeDefinition(
      id: 'ultrasound_obs',
      title: 'OB\nUltrasound',
      description: 'Obstetric scan',
      icon: 'child_friendly',
      gradientColors: [0xFFEC4899, 0xFFDB2777],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gynecology],
    ),
    
    // ====== NEUROLOGY ======
    const RecordTypeDefinition(
      id: 'neuro_examination',
      title: 'Neurological\nExam',
      description: 'Nerve assessment',
      icon: 'psychology_alt',
      gradientColors: [0xFF818CF8, 0xFF6366F1],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.neurology],
    ),
    const RecordTypeDefinition(
      id: 'cranial_nerve_exam',
      title: 'Cranial\nNerve Exam',
      description: 'CN I-XII testing',
      icon: 'psychology',
      gradientColors: [0xFF6366F1, 0xFF4F46E5],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.neurology],
    ),
    const RecordTypeDefinition(
      id: 'motor_sensory_exam',
      title: 'Motor/Sensory\nExam',
      description: 'Strength, sensation',
      icon: 'accessibility',
      gradientColors: [0xFF4F46E5, 0xFF4338CA],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.neurology],
    ),
    const RecordTypeDefinition(
      id: 'eeg_report',
      title: 'EEG\nReport',
      description: 'Electroencephalogram',
      icon: 'show_chart',
      gradientColors: [0xFF4338CA, 0xFF3730A3],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.neurology],
    ),
    
    // ====== GASTROENTEROLOGY ======
    const RecordTypeDefinition(
      id: 'gi_examination',
      title: 'GI\nExamination',
      description: 'Digestive assessment',
      icon: 'lunch_dining',
      gradientColors: [0xFFFBBF24, 0xFFF59E0B],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gastroenterology],
    ),
    const RecordTypeDefinition(
      id: 'endoscopy_report',
      title: 'Endoscopy\nReport',
      description: 'Upper/lower GI scope',
      icon: 'search',
      gradientColors: [0xFFF59E0B, 0xFFD97706],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gastroenterology],
    ),
    const RecordTypeDefinition(
      id: 'liver_assessment',
      title: 'Liver\nAssessment',
      description: 'Hepatic evaluation',
      icon: 'science',
      gradientColors: [0xFFD97706, 0xFFB45309],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.gastroenterology],
    ),
    
    // ====== NEPHROLOGY ======
    const RecordTypeDefinition(
      id: 'renal_assessment',
      title: 'Renal\nAssessment',
      description: 'Kidney evaluation',
      icon: 'water_drop',
      gradientColors: [0xFF3B82F6, 0xFF2563EB],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.nephrology, DoctorSpecialty.internalMedicine],
    ),
    const RecordTypeDefinition(
      id: 'dialysis_record',
      title: 'Dialysis\nRecord',
      description: 'HD/PD session notes',
      icon: 'swap_horiz',
      gradientColors: [0xFF2563EB, 0xFF1D4ED8],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.nephrology],
    ),
    
    // ====== ENDOCRINOLOGY ======
    const RecordTypeDefinition(
      id: 'diabetes_review',
      title: 'Diabetes\nReview',
      description: 'HbA1c, glucose log',
      icon: 'bloodtype',
      gradientColors: [0xFF14B8A6, 0xFF0D9488],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.endocrinology, DoctorSpecialty.internalMedicine, DoctorSpecialty.generalPractice],
    ),
    const RecordTypeDefinition(
      id: 'thyroid_assessment',
      title: 'Thyroid\nAssessment',
      description: 'TFT, thyroid exam',
      icon: 'biotech',
      gradientColors: [0xFF0D9488, 0xFF0F766E],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.endocrinology],
    ),
    const RecordTypeDefinition(
      id: 'hormone_panel',
      title: 'Hormone\nPanel',
      description: 'Endocrine workup',
      icon: 'science',
      gradientColors: [0xFF0F766E, 0xFF115E59],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.endocrinology],
    ),
    
    // ====== ONCOLOGY ======
    const RecordTypeDefinition(
      id: 'oncology_review',
      title: 'Oncology\nReview',
      description: 'Cancer follow-up',
      icon: 'healing',
      gradientColors: [0xFFA855F7, 0xFF9333EA],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.oncology],
    ),
    const RecordTypeDefinition(
      id: 'chemotherapy_cycle',
      title: 'Chemotherapy\nCycle',
      description: 'Chemo session record',
      icon: 'science',
      gradientColors: [0xFF9333EA, 0xFF7E22CE],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.oncology],
    ),
    const RecordTypeDefinition(
      id: 'tumor_staging',
      title: 'Tumor\nStaging',
      description: 'TNM staging record',
      icon: 'analytics',
      gradientColors: [0xFF7E22CE, 0xFF6B21A8],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.oncology],
    ),
    
    // ====== UROLOGY ======
    const RecordTypeDefinition(
      id: 'urological_exam',
      title: 'Urological\nExam',
      description: 'GU assessment',
      icon: 'medical_information',
      gradientColors: [0xFF0EA5E9, 0xFF0284C7],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.urology],
    ),
    const RecordTypeDefinition(
      id: 'prostate_exam',
      title: 'Prostate\nExam',
      description: 'DRE, PSA review',
      icon: 'male',
      gradientColors: [0xFF0284C7, 0xFF0369A1],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.urology],
    ),
    const RecordTypeDefinition(
      id: 'urodynamics',
      title: 'Urodynamics\nReport',
      description: 'Bladder function test',
      icon: 'show_chart',
      gradientColors: [0xFF0369A1, 0xFF075985],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.urology],
    ),
    
    // ====== RHEUMATOLOGY ======
    const RecordTypeDefinition(
      id: 'rheumatology_exam',
      title: 'Rheumatology\nExam',
      description: 'Inflammatory assessment',
      icon: 'accessibility',
      gradientColors: [0xFFF97316, 0xFFEA580C],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.rheumatology],
    ),
    const RecordTypeDefinition(
      id: 'das28_score',
      title: 'DAS28\nScore',
      description: 'Disease activity',
      icon: 'calculate',
      gradientColors: [0xFFEA580C, 0xFFDC2626],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.rheumatology],
    ),
    const RecordTypeDefinition(
      id: 'joint_count',
      title: 'Joint\nCount',
      description: 'Swollen/tender joints',
      icon: 'touch_app',
      gradientColors: [0xFFDC2626, 0xFFB91C1C],
      category: RecordTypeCategory.specialty,
      specialties: [DoctorSpecialty.rheumatology],
    ),
  ];

  /// Get record types prioritized for a specific specialty
  static List<RecordTypeDefinition> getRecordTypesForSpecialty(DoctorSpecialty? specialty) {
    final universal = <RecordTypeDefinition>[];
    final recommended = <RecordTypeDefinition>[];
    final documentation = <RecordTypeDefinition>[];
    final other = <RecordTypeDefinition>[];

    for (final recordType in allRecordTypes) {
      if (recordType.category == RecordTypeCategory.universal) {
        universal.add(recordType);
      } else if (recordType.category == RecordTypeCategory.documentation) {
        documentation.add(recordType);
      } else if (recordType.isRelevantFor(specialty)) {
        recommended.add(recordType);
      } else {
        other.add(recordType);
      }
    }

    // Return: Universal first, then recommended specialty, then documentation, then other
    return [...universal, ...recommended, ...documentation, ...other];
  }

  /// Get recommended record types for a specialty (shown in "Recommended for You" section)
  static List<RecordTypeDefinition> getRecommendedRecordTypes(DoctorSpecialty? specialty) {
    if (specialty == null) {
      // Return top universal types for new users
      return allRecordTypes
          .where((r) => r.category == RecordTypeCategory.universal)
          .take(4)
          .toList();
    }

    // Get specialty-specific + most used universal types
    final recommended = <RecordTypeDefinition>[];
    
    // Add specialty-specific first
    recommended.addAll(
      allRecordTypes.where((r) => 
        r.category == RecordTypeCategory.specialty && 
        r.specialties.contains(specialty),
      ),
    );

    // Add key universal types
    final keyUniversal = ['general_consultation', 'follow_up', 'prescription', 'lab_result'];
    for (final id in keyUniversal) {
      final type = allRecordTypes.firstWhere((r) => r.id == id, orElse: () => allRecordTypes.first);
      if (!recommended.contains(type)) {
        recommended.add(type);
      }
    }

    return recommended.take(6).toList();
  }

  /// Get all record types (for "All Record Types" section)
  static List<RecordTypeDefinition> getAllRecordTypes() {
    return allRecordTypes;
  }
}
