import '../db/doctor_db.dart';
import '../services/doctor_settings_service.dart';

/// Demo data for showcasing the app when database is unavailable
/// This app is designed for a single doctor managing their own clinic
class DemoData {
  static final DateTime _today = DateTime.now();
  static final DateTime _baseDate = DateTime(_today.year, _today.month, _today.day);

  /// Sample doctor profile for demo mode (single doctor app)
  static DoctorProfile get defaultDoctor => DoctorProfile(
    name: 'Dr. Ahmed Hassan',
    specialization: 'General Physician',
    qualifications: 'MBBS, FCPS (Medicine)',
    licenseNumber: 'PMC-12345-2015',
    experienceYears: 12,
    bio: 'Experienced general physician with over a decade of practice in internal medicine. '
         'Specialized in managing chronic diseases including diabetes, hypertension, and cardiovascular conditions.',
    phone: '+92 321 1234567',
    email: 'dr.ahmed.hassan@clinic.com',
    clinicName: 'Hassan Medical Center',
    clinicAddress: '45 Main Boulevard, Gulberg III, Lahore',
    clinicPhone: '+92 42 35761234',
    consultationFee: 2000,
    followUpFee: 1500,
    emergencyFee: 3500,
    languages: ['English', 'Urdu', 'Punjabi'],
    workingHours: {
      'Monday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
      'Tuesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
      'Wednesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
      'Thursday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
      'Friday': {'enabled': true, 'start': '09:00', 'end': '13:00'},
      'Saturday': {'enabled': true, 'start': '10:00', 'end': '14:00'},
      'Sunday': {'enabled': false, 'start': '09:00', 'end': '17:00'},
    },
  );

  /// Sample patients for demo mode
  static List<Patient> get patients => [
    Patient(
      id: 1,
      firstName: 'Sarah',
      lastName: 'Johnson',
      age: 40,  // born 1985
      phone: '+1 (555) 123-4567',
      email: 'sarah.johnson@email.com',
      address: '123 Oak Street, Springfield',
      medicalHistory: 'Diabetes Type 2, Hypertension',
      allergies: 'Penicillin, Sulfa drugs',
      tags: 'regular,priority',
      riskLevel: 3,
      gender: 'Female',
      bloodType: 'O+',
      emergencyContactName: 'Michael Johnson',
      emergencyContactPhone: '+1 (555) 123-4568',
      chronicConditions: 'Diabetes Type 2,Hypertension',
      createdAt: _baseDate.subtract(const Duration(days: 120)),
    ),
    Patient(
      id: 2,
      firstName: 'Michael',
      lastName: 'Chen',
      age: 35,  // born 1990
      phone: '+1 (555) 234-5678',
      email: 'michael.chen@email.com',
      address: '456 Maple Avenue, Riverside',
      medicalHistory: 'Asthma, Allergies',
      allergies: 'Pollen, Dust mites, Shellfish',
      tags: 'new',
      riskLevel: 2,
      gender: 'Male',
      bloodType: 'A+',
      emergencyContactName: 'Linda Chen',
      emergencyContactPhone: '+1 (555) 234-5679',
      chronicConditions: 'Asthma',
      createdAt: _baseDate.subtract(const Duration(days: 45)),
    ),
    Patient(
      id: 3,
      firstName: 'Emily',
      lastName: 'Williams',
      age: 47,  // born 1978
      phone: '+1 (555) 345-6789',
      email: 'emily.williams@email.com',
      address: '789 Pine Road, Lakewood',
      medicalHistory: 'Heart Disease, High Cholesterol',
      allergies: '',
      tags: 'priority,followup',
      riskLevel: 5,
      gender: 'Female',
      bloodType: 'B+',
      emergencyContactName: 'Richard Williams',
      emergencyContactPhone: '+1 (555) 345-6780',
      chronicConditions: 'Heart Disease,High Cholesterol',
      createdAt: _baseDate.subtract(const Duration(days: 200)),
    ),
    Patient(
      id: 4,
      firstName: 'James',
      lastName: 'Rodriguez',
      age: 30,  // born 1995
      phone: '+1 (555) 456-7890',
      email: 'james.r@email.com',
      address: '321 Elm Court, Meadowbrook',
      medicalHistory: 'Sports Injury',
      allergies: 'Ibuprofen',
      tags: 'new',
      riskLevel: 1,
      gender: 'Male',
      bloodType: 'AB+',
      emergencyContactName: 'Maria Rodriguez',
      emergencyContactPhone: '+1 (555) 456-7891',
      chronicConditions: '',
      createdAt: _baseDate.subtract(const Duration(days: 14)),
    ),
    Patient(
      id: 5,
      firstName: 'Lisa',
      lastName: 'Thompson',
      age: 43,  // born 1982
      phone: '+1 (555) 567-8901',
      email: 'lisa.thompson@email.com',
      address: '654 Cedar Lane, Hillside',
      medicalHistory: 'Migraine, Anxiety',
      allergies: 'Aspirin',
      tags: 'regular',
      riskLevel: 2,
      gender: 'Female',
      bloodType: 'O-',
      emergencyContactName: 'Thomas Thompson',
      emergencyContactPhone: '+1 (555) 567-8902',
      chronicConditions: 'Migraine,Anxiety',
      createdAt: _baseDate.subtract(const Duration(days: 90)),
    ),
    Patient(
      id: 6,
      firstName: 'Robert',
      lastName: 'Davis',
      age: 57,  // born 1968
      phone: '+1 (555) 678-9012',
      email: 'robert.davis@email.com',
      address: '987 Birch Street, Oakville',
      medicalHistory: 'COPD, Arthritis, Diabetes',
      allergies: 'Codeine, Morphine',
      tags: 'priority,regular',
      riskLevel: 4,
      gender: 'Male',
      bloodType: 'A-',
      emergencyContactName: 'Susan Davis',
      emergencyContactPhone: '+1 (555) 678-9013',
      chronicConditions: 'COPD,Arthritis,Diabetes',
      createdAt: _baseDate.subtract(const Duration(days: 365)),
    ),
    Patient(
      id: 7,
      firstName: 'Amanda',
      lastName: 'Martinez',
      age: 33,  // born 1992
      phone: '+1 (555) 789-0123',
      email: 'amanda.m@email.com',
      address: '147 Walnut Drive, Sunnyvale',
      medicalHistory: 'Pregnancy, Gestational Diabetes',
      allergies: 'Latex',
      tags: 'priority,new',
      riskLevel: 3,
      gender: 'Female',
      bloodType: 'B-',
      emergencyContactName: 'Carlos Martinez',
      emergencyContactPhone: '+1 (555) 789-0124',
      chronicConditions: 'Gestational Diabetes',
      createdAt: _baseDate.subtract(const Duration(days: 30)),
    ),
    Patient(
      id: 8,
      firstName: 'David',
      lastName: 'Brown',
      age: 50,  // born 1975
      phone: '+1 (555) 890-1234',
      email: 'david.brown@email.com',
      address: '258 Spruce Avenue, Greenfield',
      medicalHistory: 'Back Pain, Insomnia',
      allergies: '',
      tags: 'followup',
      riskLevel: 2,
      gender: 'Male',
      bloodType: 'AB-',
      emergencyContactName: 'Patricia Brown',
      emergencyContactPhone: '+1 (555) 890-1235',
      chronicConditions: 'Chronic Back Pain',
      createdAt: _baseDate.subtract(const Duration(days: 60)),
    ),
  ];

  /// Sample appointments for demo mode
  static List<Appointment> get appointments {
    return [
      // Today's appointments
      Appointment(
        id: 1,
        patientId: 1,
        appointmentDateTime: _baseDate.add(const Duration(hours: 9)),
        durationMinutes: 30,
        reason: 'Diabetes checkup',
        status: 'completed',
        reminderAt: _baseDate.add(const Duration(hours: 8)),
        notes: 'Check blood sugar levels and adjust medication if needed',
        createdAt: _baseDate.subtract(const Duration(days: 7)),
      ),
      Appointment(
        id: 2,
        patientId: 3,
        appointmentDateTime: _baseDate.add(const Duration(hours: 10, minutes: 30)),
        durationMinutes: 45,
        reason: 'Cardiac follow-up',
        status: 'in-progress',
        reminderAt: _baseDate.add(const Duration(hours: 9, minutes: 30)),
        notes: 'Review ECG results and discuss medication changes',
        createdAt: _baseDate.subtract(const Duration(days: 5)),
      ),
      Appointment(
        id: 3,
        patientId: 5,
        appointmentDateTime: _baseDate.add(const Duration(hours: 14)),
        durationMinutes: 30,
        reason: 'Migraine consultation',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(hours: 13)),
        notes: 'Discuss new preventive medication options',
        createdAt: _baseDate.subtract(const Duration(days: 3)),
      ),
      Appointment(
        id: 4,
        patientId: 7,
        appointmentDateTime: _baseDate.add(const Duration(hours: 15, minutes: 30)),
        durationMinutes: 45,
        reason: 'Prenatal checkup',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(hours: 14, minutes: 30)),
        notes: 'Third trimester checkup, ultrasound review',
        createdAt: _baseDate.subtract(const Duration(days: 2)),
      ),
      // Tomorrow's appointments
      Appointment(
        id: 5,
        patientId: 2,
        appointmentDateTime: _baseDate.add(const Duration(days: 1, hours: 9, minutes: 30)),
        durationMinutes: 30,
        reason: 'Asthma follow-up',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 1, hours: 8, minutes: 30)),
        notes: 'Check inhaler technique and lung function',
        createdAt: _baseDate.subtract(const Duration(days: 4)),
      ),
      Appointment(
        id: 6,
        patientId: 6,
        appointmentDateTime: _baseDate.add(const Duration(days: 1, hours: 11)),
        durationMinutes: 45,
        reason: 'COPD management',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 1, hours: 10)),
        notes: 'Review oxygen therapy and breathing exercises',
        createdAt: _baseDate.subtract(const Duration(days: 6)),
      ),
      Appointment(
        id: 7,
        patientId: 4,
        appointmentDateTime: _baseDate.add(const Duration(days: 1, hours: 14, minutes: 30)),
        durationMinutes: 30,
        reason: 'Sports injury follow-up',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 1, hours: 13, minutes: 30)),
        notes: 'Check knee recovery progress',
        createdAt: _baseDate.subtract(const Duration(days: 1)),
      ),
      // Day after tomorrow
      Appointment(
        id: 8,
        patientId: 8,
        appointmentDateTime: _baseDate.add(const Duration(days: 2, hours: 10)),
        durationMinutes: 30,
        reason: 'Back pain review',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 2, hours: 9)),
        notes: 'Discuss physical therapy progress',
        createdAt: _baseDate,
      ),
    ];
  }

  /// Sample prescriptions for demo mode
  static List<DemoPrescription> get prescriptions => [
    DemoPrescription(
      id: 1,
      patientId: 1,
      patientName: 'Sarah Johnson',
      createdAt: _baseDate.subtract(const Duration(days: 7)),
      medications: [
        DemoMedication(name: 'Metformin', dosage: '500mg', frequency: 'Twice daily'),
        DemoMedication(name: 'Lisinopril', dosage: '10mg', frequency: 'Once daily'),
      ],
      instructions: 'Take with meals. Monitor blood sugar regularly.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 2,
      patientId: 2,
      patientName: 'Michael Chen',
      createdAt: _baseDate.subtract(const Duration(days: 14)),
      medications: [
        DemoMedication(name: 'Albuterol Inhaler', dosage: '90mcg', frequency: 'As needed'),
        DemoMedication(name: 'Fluticasone', dosage: '250mcg', frequency: 'Twice daily'),
      ],
      instructions: 'Use albuterol for rescue. Rinse mouth after fluticasone.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 3,
      patientId: 3,
      patientName: 'Emily Williams',
      createdAt: _baseDate.subtract(const Duration(days: 3)),
      medications: [
        DemoMedication(name: 'Atorvastatin', dosage: '40mg', frequency: 'Once daily at bedtime'),
        DemoMedication(name: 'Aspirin', dosage: '81mg', frequency: 'Once daily'),
        DemoMedication(name: 'Metoprolol', dosage: '50mg', frequency: 'Twice daily'),
      ],
      instructions: 'Do not skip doses. Report any muscle pain immediately.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 4,
      patientId: 5,
      patientName: 'Lisa Thompson',
      createdAt: _baseDate.subtract(const Duration(days: 21)),
      medications: [
        DemoMedication(name: 'Sumatriptan', dosage: '50mg', frequency: 'As needed for migraine'),
        DemoMedication(name: 'Propranolol', dosage: '40mg', frequency: 'Twice daily'),
      ],
      instructions: 'Take sumatriptan at first sign of migraine. Max 2 doses per day.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 5,
      patientId: 6,
      patientName: 'Robert Davis',
      createdAt: _baseDate.subtract(const Duration(days: 5)),
      medications: [
        DemoMedication(name: 'Tiotropium', dosage: '18mcg', frequency: 'Once daily'),
        DemoMedication(name: 'Prednisone', dosage: '20mg', frequency: 'Once daily for 5 days'),
        DemoMedication(name: 'Ibuprofen', dosage: '400mg', frequency: 'Three times daily'),
      ],
      instructions: 'Complete prednisone course. Use inhaler before activities.',
      isRefillable: false,
      status: 'active',
    ),
    DemoPrescription(
      id: 6,
      patientId: 7,
      patientName: 'Amanda Martinez',
      createdAt: _baseDate.subtract(const Duration(days: 10)),
      medications: [
        DemoMedication(name: 'Prenatal Vitamins', dosage: '1 tablet', frequency: 'Once daily'),
        DemoMedication(name: 'Folic Acid', dosage: '400mcg', frequency: 'Once daily'),
        DemoMedication(name: 'Iron Supplement', dosage: '27mg', frequency: 'Once daily'),
      ],
      instructions: 'Take with food to reduce stomach upset.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 7,
      patientId: 8,
      patientName: 'David Brown',
      createdAt: _baseDate.subtract(const Duration(days: 30)),
      medications: [
        DemoMedication(name: 'Cyclobenzaprine', dosage: '10mg', frequency: 'At bedtime'),
        DemoMedication(name: 'Naproxen', dosage: '500mg', frequency: 'Twice daily'),
      ],
      instructions: 'Do not operate machinery after taking cyclobenzaprine.',
      isRefillable: false,
      status: 'completed',
    ),
    DemoPrescription(
      id: 8,
      patientId: 4,
      patientName: 'James Rodriguez',
      createdAt: _baseDate.subtract(const Duration(days: 7)),
      medications: [
        DemoMedication(name: 'Ibuprofen', dosage: '600mg', frequency: 'Three times daily'),
        DemoMedication(name: 'Acetaminophen', dosage: '500mg', frequency: 'Every 6 hours as needed'),
      ],
      instructions: 'Apply ice to knee 20 min on/off. Continue physical therapy.',
      isRefillable: false,
      status: 'active',
    ),
  ];

  /// Sample medical records for demo mode
  static List<DemoMedicalRecord> get medicalRecords => [
    DemoMedicalRecord(
      id: 1,
      patientId: 1,
      patientName: 'Sarah Johnson',
      recordType: 'general',
      title: 'Diabetes Management Consultation',
      description: 'Routine diabetes checkup and medication adjustment',
      diagnosis: 'Type 2 Diabetes Mellitus, well-controlled',
      treatment: 'Continue current medication regimen with minor adjustments',
      doctorNotes: 'HbA1c improved from 7.2% to 6.8%. Patient showing good adherence to diet and exercise.',
      recordDate: _baseDate.subtract(const Duration(days: 30)),
    ),
    DemoMedicalRecord(
      id: 2,
      patientId: 3,
      patientName: 'Emily Williams',
      recordType: 'general',
      title: 'Cardiac Follow-up',
      description: 'Post-stent placement follow-up',
      diagnosis: 'Coronary Artery Disease, stable',
      treatment: 'Continue dual antiplatelet therapy',
      doctorNotes: 'ECG shows normal sinus rhythm. No chest pain or dyspnea reported.',
      recordDate: _baseDate.subtract(const Duration(days: 14)),
    ),
    DemoMedicalRecord(
      id: 3,
      patientId: 2,
      patientName: 'Michael Chen',
      recordType: 'pulmonary_evaluation',
      title: 'Asthma Evaluation',
      description: 'Pulmonary function testing and medication review',
      diagnosis: 'Moderate Persistent Asthma',
      treatment: 'Step up controller therapy, add LABA',
      doctorNotes: 'FEV1 72% predicted. Increased nighttime symptoms.',
      recordDate: _baseDate.subtract(const Duration(days: 21)),
    ),
    DemoMedicalRecord(
      id: 4,
      patientId: 6,
      patientName: 'Robert Davis',
      recordType: 'pulmonary_evaluation',
      title: 'COPD Assessment',
      description: 'Comprehensive COPD evaluation with spirometry',
      diagnosis: 'COPD Gold Stage III',
      treatment: 'Triple inhaler therapy, pulmonary rehabilitation referral',
      doctorNotes: 'FEV1 45% predicted. Oxygen saturation 94% on room air.',
      recordDate: _baseDate.subtract(const Duration(days: 7)),
    ),
    DemoMedicalRecord(
      id: 5,
      patientId: 5,
      patientName: 'Lisa Thompson',
      recordType: 'psychiatric_assessment',
      title: 'Anxiety Assessment',
      description: 'Initial psychiatric evaluation for anxiety symptoms',
      diagnosis: 'Generalized Anxiety Disorder',
      treatment: 'CBT referral, consider SSRI if no improvement',
      doctorNotes: 'GAD-7 score: 14 (moderate). Sleep disturbance present.',
      recordDate: _baseDate.subtract(const Duration(days: 45)),
    ),
    DemoMedicalRecord(
      id: 6,
      patientId: 7,
      patientName: 'Amanda Martinez',
      recordType: 'follow_up',
      title: 'Prenatal Checkup - 28 Weeks',
      description: 'Third trimester routine checkup',
      diagnosis: 'Normal pregnancy, 28 weeks gestation',
      treatment: 'Continue prenatal vitamins, glucose tolerance test ordered',
      doctorNotes: 'Fetal heart rate 145 bpm. Fundal height appropriate for dates.',
      recordDate: _baseDate.subtract(const Duration(days: 10)),
    ),
    DemoMedicalRecord(
      id: 7,
      patientId: 4,
      patientName: 'James Rodriguez',
      recordType: 'imaging',
      title: 'Knee MRI Report',
      description: 'MRI of right knee following sports injury',
      diagnosis: 'Partial ACL tear, mild meniscal damage',
      treatment: 'Physical therapy, possible arthroscopic surgery',
      doctorNotes: 'Grade II ACL sprain. Recommend conservative management first.',
      recordDate: _baseDate.subtract(const Duration(days: 12)),
    ),
    DemoMedicalRecord(
      id: 8,
      patientId: 1,
      patientName: 'Sarah Johnson',
      recordType: 'lab_result',
      title: 'HbA1c and Lipid Panel',
      description: 'Routine diabetic monitoring labs',
      diagnosis: 'Diabetes Type 2 with mild dyslipidemia',
      treatment: 'Consider statin therapy for elevated LDL',
      doctorNotes: 'HbA1c: 6.8%, LDL: 142 mg/dL, HDL: 48 mg/dL',
      recordDate: _baseDate.subtract(const Duration(days: 5)),
    ),
  ];

  /// Sample invoices for demo mode
  static List<DemoInvoice> get invoices => [
    DemoInvoice(
      id: 1,
      patientId: 1,
      patientName: 'Sarah Johnson',
      invoiceNumber: 'INV-2024-001',
      invoiceDate: _baseDate.subtract(const Duration(days: 7)),
      items: [
        DemoInvoiceItem(description: 'Consultation Fee', quantity: 1, unitPrice: 2000),
        DemoInvoiceItem(description: 'Blood Sugar Test', quantity: 1, unitPrice: 500),
        DemoInvoiceItem(description: 'HbA1c Test', quantity: 1, unitPrice: 1500),
      ],
      subtotal: 4000,
      discountPercent: 10,
      discountAmount: 400,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 3600,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash',
    ),
    DemoInvoice(
      id: 2,
      patientId: 3,
      patientName: 'Emily Williams',
      invoiceNumber: 'INV-2024-002',
      invoiceDate: _baseDate.subtract(const Duration(days: 5)),
      items: [
        DemoInvoiceItem(description: 'Cardiac Consultation', quantity: 1, unitPrice: 5000),
        DemoInvoiceItem(description: 'ECG', quantity: 1, unitPrice: 1000),
        DemoInvoiceItem(description: 'Echo Report Review', quantity: 1, unitPrice: 500),
      ],
      subtotal: 6500,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 6500,
      paymentStatus: 'Paid',
      paymentMethod: 'Card',
    ),
    DemoInvoice(
      id: 3,
      patientId: 2,
      patientName: 'Michael Chen',
      invoiceNumber: 'INV-2024-003',
      invoiceDate: _baseDate.subtract(const Duration(days: 3)),
      items: [
        DemoInvoiceItem(description: 'Follow-up Consultation', quantity: 1, unitPrice: 1500),
        DemoInvoiceItem(description: 'Spirometry Test', quantity: 1, unitPrice: 2000),
      ],
      subtotal: 3500,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 3500,
      paymentStatus: 'Pending',
      paymentMethod: 'Cash',
    ),
    DemoInvoice(
      id: 4,
      patientId: 7,
      patientName: 'Amanda Martinez',
      invoiceNumber: 'INV-2024-004',
      invoiceDate: _baseDate.subtract(const Duration(days: 10)),
      items: [
        DemoInvoiceItem(description: 'Prenatal Checkup', quantity: 1, unitPrice: 3000),
        DemoInvoiceItem(description: 'Ultrasound', quantity: 1, unitPrice: 2500),
        DemoInvoiceItem(description: 'Blood Work Panel', quantity: 1, unitPrice: 1800),
      ],
      subtotal: 7300,
      discountPercent: 5,
      discountAmount: 365,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 6935,
      paymentStatus: 'Paid',
      paymentMethod: 'Online',
    ),
    DemoInvoice(
      id: 5,
      patientId: 4,
      patientName: 'James Rodriguez',
      invoiceNumber: 'INV-2024-005',
      invoiceDate: _baseDate.subtract(const Duration(days: 12)),
      items: [
        DemoInvoiceItem(description: 'Sports Injury Consultation', quantity: 1, unitPrice: 2500),
        DemoInvoiceItem(description: 'MRI Interpretation', quantity: 1, unitPrice: 1000),
      ],
      subtotal: 3500,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 3500,
      paymentStatus: 'Pending',
      paymentMethod: 'Cash',
    ),
    DemoInvoice(
      id: 6,
      patientId: 6,
      patientName: 'Robert Davis',
      invoiceNumber: 'INV-2024-006',
      invoiceDate: _baseDate,
      items: [
        DemoInvoiceItem(description: 'COPD Consultation', quantity: 1, unitPrice: 3500),
        DemoInvoiceItem(description: 'Spirometry', quantity: 1, unitPrice: 2000),
        DemoInvoiceItem(description: 'Oxygen Saturation Test', quantity: 1, unitPrice: 300),
        DemoInvoiceItem(description: 'Chest X-Ray Review', quantity: 1, unitPrice: 500),
      ],
      subtotal: 6300,
      discountPercent: 15,
      discountAmount: 945,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 5355,
      paymentStatus: 'Partial',
      paymentMethod: 'Cash',
      notes: 'Paid Rs. 3000 upfront, remaining Rs. 2355 due next visit',
    ),
  ];

  /// Get appointments for a specific day
  static List<Appointment> getAppointmentsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    return appointments.where((apt) {
      return apt.appointmentDateTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
             apt.appointmentDateTime.isBefore(dayEnd);
    }).toList();
  }

  /// Get patient by ID
  static Patient? getPatientById(int id) {
    try {
      return patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get medical records for a patient
  static List<DemoMedicalRecord> getMedicalRecordsForPatient(int patientId) {
    return medicalRecords.where((r) => r.patientId == patientId).toList();
  }

  /// Get invoices for a patient
  static List<DemoInvoice> getInvoicesForPatient(int patientId) {
    return invoices.where((i) => i.patientId == patientId).toList();
  }

  /// Get total revenue from invoices
  static double get totalRevenue {
    return invoices
        .where((i) => i.paymentStatus == 'Paid')
        .fold(0.0, (sum, i) => sum + i.grandTotal);
  }

  /// Get pending revenue
  static double get pendingRevenue {
    return invoices
        .where((i) => i.paymentStatus != 'Paid')
        .fold(0.0, (sum, i) => sum + i.grandTotal);
  }

  /// Get today's appointment count
  static int get todayAppointmentCount => getAppointmentsForDay(_baseDate).length;

  /// Get pending appointments count
  static int get pendingAppointmentCount => 
    getAppointmentsForDay(_baseDate).where((a) => a.status == 'scheduled').length;
}

/// Demo medication class for prescription display
class DemoMedication {

  DemoMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });
  final String name;
  final String dosage;
  final String frequency;
}

/// Demo prescription class with additional display info
class DemoPrescription {

  DemoPrescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.createdAt,
    required this.medications,
    required this.instructions,
    required this.isRefillable,
    required this.status,
  });
  final int id;
  final int patientId;
  final String patientName;
  final DateTime createdAt;
  final List<DemoMedication> medications;
  final String instructions;
  final bool isRefillable;
  final String status;
}

/// Demo medical record class for display
class DemoMedicalRecord {

  DemoMedicalRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.recordType,
    required this.title,
    required this.description,
    required this.diagnosis,
    required this.treatment,
    required this.doctorNotes,
    required this.recordDate,
  });
  final int id;
  final int patientId;
  final String patientName;
  final String recordType;
  final String title;
  final String description;
  final String diagnosis;
  final String treatment;
  final String doctorNotes;
  final DateTime recordDate;
}

/// Demo invoice item class
class DemoInvoiceItem {

  DemoInvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });
  final String description;
  final int quantity;
  final double unitPrice;
  
  double get total => quantity * unitPrice;
}

/// Demo invoice class for display
class DemoInvoice {

  DemoInvoice({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.items,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentStatus,
    required this.paymentMethod,
    this.notes,
  });
  final int id;
  final int patientId;
  final String patientName;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<DemoInvoiceItem> items;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final String paymentStatus;
  final String paymentMethod;
  final String? notes;
}
