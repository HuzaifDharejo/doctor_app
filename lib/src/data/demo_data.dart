import '../db/doctor_db.dart';
import '../services/doctor_settings_service.dart';

/// Demo data for showcasing the app when database is unavailable
/// This app is designed for a single doctor managing their own clinic
class DemoData {
  static final DateTime _today = DateTime.now();
  static final DateTime _baseDate = DateTime(_today.year, _today.month, _today.day);

  /// Sample doctor profile for demo mode (single doctor app)
  static DoctorProfile get defaultDoctor => DoctorProfile(
    name: 'Dr. Raees Ahmed Dharejo',
    specialization: 'General Physician & Internist',
    qualifications: 'MBBS, FCPS (Medicine)',
    licenseNumber: 'PMC-54321-2012',
    experienceYears: 15,
    bio: 'Experienced general physician with over 15 years of practice in internal medicine. '
         'Specialized in managing chronic diseases including diabetes, hypertension, cardiovascular conditions, '
         'respiratory disorders, and mental health. Committed to providing compassionate, patient-centered care.',
    phone: '+92 321 1234567',
    email: 'dr.raees@dharejoclinic.com',
    clinicName: 'Dharejo Medical Center',
    clinicAddress: '45 Main Boulevard, F-10 Markaz, Islamabad',
    clinicPhone: '+92 51 2345678',
    consultationFee: 2000,
    followUpFee: 1500,
    emergencyFee: 3500,
    languages: ['English', 'Urdu', 'Sindhi'],
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

  /// Sample patients for demo mode (onboarding display only)
  static List<Patient> get patients => [
    // Chronic Disease Management
    Patient(
      id: 1,
      firstName: 'Muhammad',
      lastName: 'Ahmed',
      age: 58,
      gender: 'Male',
      bloodType: 'O+',
      phone: '0300-1234567',
      email: 'ahmed@email.com',
      address: 'House 45, F-10, Islamabad',
      medicalHistory: 'Type 2 Diabetes, Hypertension',
      allergies: 'Penicillin',
      chronicConditions: 'Diabetes,Hypertension',
      tags: 'priority',
      riskLevel: 4,
      emergencyContactName: 'Fatima Ahmed (Wife)',
      emergencyContactPhone: '0300-1111111',
      createdAt: _baseDate.subtract(const Duration(days: 180)),
    ),
    Patient(
      id: 2,
      firstName: 'Fatima',
      lastName: 'Bibi',
      age: 52,
      gender: 'Female',
      bloodType: 'A+',
      phone: '0321-2345678',
      email: 'fatima@email.com',
      address: '123 Gulberg III, Lahore',
      medicalHistory: 'Hypothyroidism, Osteoporosis',
      allergies: '',
      chronicConditions: 'Thyroid,Osteoporosis',
      tags: 'regular',
      riskLevel: 2,
      emergencyContactName: 'Usman Bibi (Son)',
      emergencyContactPhone: '0321-2222222',
      createdAt: _baseDate.subtract(const Duration(days: 120)),
    ),
    Patient(
      id: 3,
      firstName: 'Ali',
      lastName: 'Raza',
      age: 65,
      gender: 'Male',
      bloodType: 'B+',
      phone: '0333-3456789',
      email: 'ali.raza@email.com',
      address: 'DHA Phase 5, Karachi',
      medicalHistory: 'Coronary Artery Disease, Hyperlipidemia',
      allergies: 'Aspirin',
      chronicConditions: 'CAD,Hyperlipidemia',
      tags: 'priority',
      riskLevel: 5,
      emergencyContactName: 'Sara Raza (Daughter)',
      emergencyContactPhone: '0333-3333333',
      createdAt: _baseDate.subtract(const Duration(days: 365)),
    ),
    // Mental Health
    Patient(
      id: 4,
      firstName: 'Ayesha',
      lastName: 'Khan',
      age: 34,
      gender: 'Female',
      bloodType: 'AB+',
      phone: '0345-4567890',
      email: 'ayesha@email.com',
      address: '78 Model Town, Lahore',
      medicalHistory: 'Generalized Anxiety Disorder',
      allergies: '',
      chronicConditions: 'Anxiety',
      tags: 'regular',
      riskLevel: 3,
      emergencyContactName: 'Ahmed Khan (Husband)',
      emergencyContactPhone: '0345-4444444',
      createdAt: _baseDate.subtract(const Duration(days: 90)),
    ),
    Patient(
      id: 5,
      firstName: 'Hassan',
      lastName: 'Malik',
      age: 42,
      gender: 'Male',
      bloodType: 'A-',
      phone: '0302-5678901',
      email: 'hassan@email.com',
      address: 'G-9, Islamabad',
      medicalHistory: 'Major Depressive Disorder',
      allergies: 'Sulfa drugs',
      chronicConditions: 'Depression',
      tags: 'regular',
      riskLevel: 3,
      emergencyContactName: 'Zahida Malik (Wife)',
      emergencyContactPhone: '0302-5555555',
      createdAt: _baseDate.subtract(const Duration(days: 75)),
    ),
    // Respiratory
    Patient(
      id: 6,
      firstName: 'Zainab',
      lastName: 'Hussain',
      age: 28,
      gender: 'Female',
      bloodType: 'O-',
      phone: '0311-6789012',
      email: 'zainab@email.com',
      address: 'Satellite Town, Rawalpindi',
      medicalHistory: 'Asthma',
      allergies: 'Dust, Pollen',
      chronicConditions: 'Asthma',
      tags: 'regular',
      riskLevel: 2,
      emergencyContactName: 'Imran Hussain (Brother)',
      emergencyContactPhone: '0311-6666666',
      createdAt: _baseDate.subtract(const Duration(days: 60)),
    ),
    Patient(
      id: 7,
      firstName: 'Usman',
      lastName: 'Tariq',
      age: 55,
      gender: 'Male',
      bloodType: 'B-',
      phone: '0322-7890123',
      email: 'usman@email.com',
      address: 'Bahria Town, Islamabad',
      medicalHistory: 'COPD',
      allergies: 'NSAIDs',
      chronicConditions: 'COPD',
      tags: 'priority',
      riskLevel: 4,
      emergencyContactName: 'Asma Tariq (Wife)',
      emergencyContactPhone: '0322-7777777',
      createdAt: _baseDate.subtract(const Duration(days: 200)),
    ),
    // General Practice
    Patient(
      id: 8,
      firstName: 'Maryam',
      lastName: 'Nawaz',
      age: 30,
      gender: 'Female',
      bloodType: 'A+',
      phone: '0334-8901234',
      email: 'maryam@email.com',
      address: 'Johar Town, Lahore',
      medicalHistory: 'PCOS, Iron Deficiency Anemia',
      allergies: '',
      chronicConditions: 'PCOS,Anemia',
      tags: 'regular',
      riskLevel: 2,
      emergencyContactName: 'Bilal Nawaz (Husband)',
      emergencyContactPhone: '0334-8888888',
      createdAt: _baseDate.subtract(const Duration(days: 45)),
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
        notes: 'Check HbA1c results and adjust medication',
        createdAt: _baseDate.subtract(const Duration(days: 7)),
      ),
      Appointment(
        id: 2,
        patientId: 3,
        appointmentDateTime: _baseDate.add(const Duration(hours: 10)),
        durationMinutes: 45,
        reason: 'Cardiac follow-up',
        status: 'in-progress',
        reminderAt: _baseDate.add(const Duration(hours: 9)),
        notes: 'Review ECG results and discuss medication changes',
        createdAt: _baseDate.subtract(const Duration(days: 5)),
      ),
      Appointment(
        id: 3,
        patientId: 4,
        appointmentDateTime: _baseDate.add(const Duration(hours: 11)),
        durationMinutes: 30,
        reason: 'Anxiety follow-up',
        status: 'checked-in',
        reminderAt: _baseDate.add(const Duration(hours: 10)),
        notes: 'Mental health session - GAD-7 assessment',
        createdAt: _baseDate.subtract(const Duration(days: 3)),
      ),
      Appointment(
        id: 4,
        patientId: 6,
        appointmentDateTime: _baseDate.add(const Duration(hours: 14)),
        durationMinutes: 30,
        reason: 'Asthma review',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(hours: 13)),
        notes: 'Check inhaler technique and peak flow',
        createdAt: _baseDate.subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 5,
        patientId: 7,
        appointmentDateTime: _baseDate.add(const Duration(hours: 15)),
        durationMinutes: 45,
        reason: 'COPD management',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(hours: 14)),
        notes: 'Pulmonary function test review',
        createdAt: _baseDate.subtract(const Duration(days: 4)),
      ),
      // Tomorrow's appointments
      Appointment(
        id: 6,
        patientId: 2,
        appointmentDateTime: _baseDate.add(const Duration(days: 1, hours: 9, minutes: 30)),
        durationMinutes: 30,
        reason: 'Thyroid follow-up',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 1, hours: 8, minutes: 30)),
        notes: 'TSH results review',
        createdAt: _baseDate.subtract(const Duration(days: 4)),
      ),
      Appointment(
        id: 7,
        patientId: 5,
        appointmentDateTime: _baseDate.add(const Duration(days: 1, hours: 11)),
        durationMinutes: 45,
        reason: 'Depression follow-up',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 1, hours: 10)),
        notes: 'PHQ-9 assessment, medication review',
        createdAt: _baseDate.subtract(const Duration(days: 6)),
      ),
      Appointment(
        id: 8,
        patientId: 8,
        appointmentDateTime: _baseDate.add(const Duration(days: 2, hours: 10)),
        durationMinutes: 30,
        reason: 'PCOS follow-up',
        status: 'scheduled',
        reminderAt: _baseDate.add(const Duration(days: 2, hours: 9)),
        notes: 'Hormone levels review',
        createdAt: _baseDate,
      ),
    ];
  }

  /// Sample prescriptions for demo mode
  static List<DemoPrescription> get prescriptions => [
    DemoPrescription(
      id: 1,
      patientId: 1,
      patientName: 'Muhammad Ahmed',
      createdAt: _baseDate.subtract(const Duration(days: 7)),
      medications: [
        DemoMedication(name: 'Metformin', dosage: '500mg', frequency: 'Twice daily with meals'),
        DemoMedication(name: 'Lisinopril', dosage: '10mg', frequency: 'Once daily morning'),
        DemoMedication(name: 'Atorvastatin', dosage: '20mg', frequency: 'Once daily at bedtime'),
      ],
      instructions: 'Monitor blood sugar before meals. Follow diabetic diet.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 2,
      patientId: 2,
      patientName: 'Fatima Bibi',
      createdAt: _baseDate.subtract(const Duration(days: 14)),
      medications: [
        DemoMedication(name: 'Levothyroxine', dosage: '50mcg', frequency: 'Once daily on empty stomach'),
        DemoMedication(name: 'Calcium + Vitamin D', dosage: '500mg/400IU', frequency: 'Twice daily'),
      ],
      instructions: 'Take thyroid medication 1 hour before breakfast.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 3,
      patientId: 3,
      patientName: 'Ali Raza',
      createdAt: _baseDate.subtract(const Duration(days: 3)),
      medications: [
        DemoMedication(name: 'Aspirin', dosage: '75mg', frequency: 'Once daily after lunch'),
        DemoMedication(name: 'Clopidogrel', dosage: '75mg', frequency: 'Once daily'),
        DemoMedication(name: 'Rosuvastatin', dosage: '10mg', frequency: 'Once daily at bedtime'),
        DemoMedication(name: 'Metoprolol', dosage: '25mg', frequency: 'Twice daily'),
      ],
      instructions: 'Do not stop medications without consulting. Report any bleeding.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 4,
      patientId: 4,
      patientName: 'Ayesha Khan',
      createdAt: _baseDate.subtract(const Duration(days: 21)),
      medications: [
        DemoMedication(name: 'Escitalopram', dosage: '10mg', frequency: 'Once daily morning'),
        DemoMedication(name: 'Alprazolam', dosage: '0.5mg', frequency: 'As needed (max 2/day)'),
      ],
      instructions: 'Avoid alcohol. May cause drowsiness initially.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 5,
      patientId: 6,
      patientName: 'Zainab Hussain',
      createdAt: _baseDate.subtract(const Duration(days: 5)),
      medications: [
        DemoMedication(name: 'Salbutamol Inhaler', dosage: '100mcg', frequency: '2 puffs as needed'),
        DemoMedication(name: 'Fluticasone Inhaler', dosage: '250mcg', frequency: '2 puffs twice daily'),
        DemoMedication(name: 'Montelukast', dosage: '10mg', frequency: 'Once daily at bedtime'),
      ],
      instructions: 'Rinse mouth after using Fluticasone. Carry rescue inhaler always.',
      isRefillable: true,
      status: 'active',
    ),
    DemoPrescription(
      id: 6,
      patientId: 7,
      patientName: 'Usman Tariq',
      createdAt: _baseDate.subtract(const Duration(days: 10)),
      medications: [
        DemoMedication(name: 'Tiotropium Inhaler', dosage: '18mcg', frequency: 'Once daily morning'),
        DemoMedication(name: 'Formoterol + Budesonide', dosage: '12/400mcg', frequency: 'Twice daily'),
      ],
      instructions: 'Use Tiotropium first, then combination inhaler.',
      isRefillable: true,
      status: 'active',
    ),
  ];

  /// Sample medical records for demo mode
  static List<DemoMedicalRecord> get medicalRecords => [
    DemoMedicalRecord(
      id: 1,
      patientId: 1,
      patientName: 'Muhammad Ahmed',
      recordType: 'general',
      title: 'Diabetes Follow-up',
      description: 'Routine diabetes checkup and medication adjustment',
      diagnosis: 'Type 2 Diabetes Mellitus - Well Controlled (E11.9)',
      treatment: 'Continue current regimen. Increase Metformin to 500mg TID.',
      doctorNotes: 'HbA1c: 6.8% (improved from 7.2%). Fasting glucose: 126 mg/dL. Patient compliant with diet and exercise.',
      recordDate: _baseDate.subtract(const Duration(days: 30)),
    ),
    DemoMedicalRecord(
      id: 2,
      patientId: 3,
      patientName: 'Ali Raza',
      recordType: 'general',
      title: 'Cardiac Evaluation',
      description: 'Annual cardiac assessment post-stent placement',
      diagnosis: 'Coronary Artery Disease - Stable (I25.10)',
      treatment: 'Continue dual antiplatelet therapy. Cardiac rehab recommended.',
      doctorNotes: 'ECG: Normal sinus rhythm. No chest pain or dyspnea. Stress test negative. EF 55%.',
      recordDate: _baseDate.subtract(const Duration(days: 14)),
    ),
    DemoMedicalRecord(
      id: 3,
      patientId: 4,
      patientName: 'Ayesha Khan',
      recordType: 'psychiatric_assessment',
      title: 'Anxiety Assessment',
      description: 'Follow-up for Generalized Anxiety Disorder',
      diagnosis: 'Generalized Anxiety Disorder - Moderate (F41.1)',
      treatment: 'Continue Escitalopram. CBT sessions recommended.',
      doctorNotes: 'GAD-7 Score: 12 (moderate). Sleep improved. Fewer panic episodes.',
      recordDate: _baseDate.subtract(const Duration(days: 21)),
    ),
    DemoMedicalRecord(
      id: 4,
      patientId: 6,
      patientName: 'Zainab Hussain',
      recordType: 'pulmonary_evaluation',
      title: 'Asthma Control Assessment',
      description: 'Pulmonary function test and medication review',
      diagnosis: 'Moderate Persistent Asthma - Partially Controlled (J45.40)',
      treatment: 'Step up controller therapy. Add LABA.',
      doctorNotes: 'FEV1: 78% predicted. Peak flow variability 18%. Using rescue inhaler 3x/week.',
      recordDate: _baseDate.subtract(const Duration(days: 7)),
    ),
    DemoMedicalRecord(
      id: 5,
      patientId: 7,
      patientName: 'Usman Tariq',
      recordType: 'pulmonary_evaluation',
      title: 'COPD Management',
      description: 'Comprehensive COPD evaluation with spirometry',
      diagnosis: 'COPD - GOLD Stage II (J44.1)',
      treatment: 'Continue triple inhaler therapy. Pulmonary rehabilitation.',
      doctorNotes: 'FEV1: 58% predicted. FEV1/FVC: 0.62. O2 sat: 94% on room air.',
      recordDate: _baseDate.subtract(const Duration(days: 5)),
    ),
  ];

  /// Sample invoices for demo mode
  static List<DemoInvoice> get invoices => [
    DemoInvoice(
      id: 1,
      patientId: 1,
      patientName: 'Muhammad Ahmed',
      invoiceNumber: 'INV-2025-1001',
      invoiceDate: _baseDate.subtract(const Duration(days: 7)),
      items: [
        DemoInvoiceItem(description: 'Consultation Fee', quantity: 1, unitPrice: 2000),
        DemoInvoiceItem(description: 'HbA1c Test', quantity: 1, unitPrice: 1500),
        DemoInvoiceItem(description: 'Lipid Profile', quantity: 1, unitPrice: 1200),
      ],
      subtotal: 4700,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 4700,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash',
    ),
    DemoInvoice(
      id: 2,
      patientId: 3,
      patientName: 'Ali Raza',
      invoiceNumber: 'INV-2025-1002',
      invoiceDate: _baseDate.subtract(const Duration(days: 5)),
      items: [
        DemoInvoiceItem(description: 'Cardiac Consultation', quantity: 1, unitPrice: 3500),
        DemoInvoiceItem(description: 'ECG', quantity: 1, unitPrice: 800),
        DemoInvoiceItem(description: 'Echo Review', quantity: 1, unitPrice: 500),
      ],
      subtotal: 4800,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 4800,
      paymentStatus: 'Paid',
      paymentMethod: 'Card',
    ),
    DemoInvoice(
      id: 3,
      patientId: 4,
      patientName: 'Ayesha Khan',
      invoiceNumber: 'INV-2025-1003',
      invoiceDate: _baseDate.subtract(const Duration(days: 3)),
      items: [
        DemoInvoiceItem(description: 'Psychiatric Consultation', quantity: 1, unitPrice: 3000),
      ],
      subtotal: 3000,
      discountPercent: 10,
      discountAmount: 300,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 2700,
      paymentStatus: 'Paid',
      paymentMethod: 'Online',
    ),
    DemoInvoice(
      id: 4,
      patientId: 6,
      patientName: 'Zainab Hussain',
      invoiceNumber: 'INV-2025-1004',
      invoiceDate: _baseDate.subtract(const Duration(days: 10)),
      items: [
        DemoInvoiceItem(description: 'Consultation Fee', quantity: 1, unitPrice: 2000),
        DemoInvoiceItem(description: 'Spirometry', quantity: 1, unitPrice: 2500),
      ],
      subtotal: 4500,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 4500,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash',
    ),
    DemoInvoice(
      id: 5,
      patientId: 7,
      patientName: 'Usman Tariq',
      invoiceNumber: 'INV-2025-1005',
      invoiceDate: _baseDate,
      items: [
        DemoInvoiceItem(description: 'Pulmonary Consultation', quantity: 1, unitPrice: 3000),
        DemoInvoiceItem(description: 'Spirometry', quantity: 1, unitPrice: 2500),
        DemoInvoiceItem(description: 'Pulse Oximetry', quantity: 1, unitPrice: 300),
      ],
      subtotal: 5800,
      discountPercent: 0,
      discountAmount: 0,
      taxPercent: 0,
      taxAmount: 0,
      grandTotal: 5800,
      paymentStatus: 'Partial',
      paymentMethod: 'Cash',
      notes: 'Paid Rs. 3000, balance Rs. 2800 due',
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
