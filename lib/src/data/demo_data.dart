import '../db/doctor_db.dart';

/// Demo data for showcasing the app when database is unavailable
class DemoData {
  static final DateTime _today = DateTime.now();
  static final DateTime _baseDate = DateTime(_today.year, _today.month, _today.day);

  /// Sample patients for demo mode
  static List<Patient> get patients => [
    Patient(
      id: 1,
      firstName: 'Sarah',
      lastName: 'Johnson',
      dateOfBirth: DateTime(1985, 3, 15),
      phone: '+1 (555) 123-4567',
      email: 'sarah.johnson@email.com',
      address: '123 Oak Street, Springfield',
      medicalHistory: 'Diabetes Type 2, Hypertension',
      tags: 'regular,priority',
      riskLevel: 3,
      createdAt: _baseDate.subtract(const Duration(days: 120)),
    ),
    Patient(
      id: 2,
      firstName: 'Michael',
      lastName: 'Chen',
      dateOfBirth: DateTime(1990, 7, 22),
      phone: '+1 (555) 234-5678',
      email: 'michael.chen@email.com',
      address: '456 Maple Avenue, Riverside',
      medicalHistory: 'Asthma, Allergies',
      tags: 'new',
      riskLevel: 2,
      createdAt: _baseDate.subtract(const Duration(days: 45)),
    ),
    Patient(
      id: 3,
      firstName: 'Emily',
      lastName: 'Williams',
      dateOfBirth: DateTime(1978, 11, 8),
      phone: '+1 (555) 345-6789',
      email: 'emily.williams@email.com',
      address: '789 Pine Road, Lakewood',
      medicalHistory: 'Heart Disease, High Cholesterol',
      tags: 'priority,followup',
      riskLevel: 5,
      createdAt: _baseDate.subtract(const Duration(days: 200)),
    ),
    Patient(
      id: 4,
      firstName: 'James',
      lastName: 'Rodriguez',
      dateOfBirth: DateTime(1995, 5, 30),
      phone: '+1 (555) 456-7890',
      email: 'james.r@email.com',
      address: '321 Elm Court, Meadowbrook',
      medicalHistory: 'Sports Injury',
      tags: 'new',
      riskLevel: 1,
      createdAt: _baseDate.subtract(const Duration(days: 14)),
    ),
    Patient(
      id: 5,
      firstName: 'Lisa',
      lastName: 'Thompson',
      dateOfBirth: DateTime(1982, 9, 12),
      phone: '+1 (555) 567-8901',
      email: 'lisa.thompson@email.com',
      address: '654 Cedar Lane, Hillside',
      medicalHistory: 'Migraine, Anxiety',
      tags: 'regular',
      riskLevel: 2,
      createdAt: _baseDate.subtract(const Duration(days: 90)),
    ),
    Patient(
      id: 6,
      firstName: 'Robert',
      lastName: 'Davis',
      dateOfBirth: DateTime(1968, 2, 28),
      phone: '+1 (555) 678-9012',
      email: 'robert.davis@email.com',
      address: '987 Birch Street, Oakville',
      medicalHistory: 'COPD, Arthritis, Diabetes',
      tags: 'priority,regular',
      riskLevel: 4,
      createdAt: _baseDate.subtract(const Duration(days: 365)),
    ),
    Patient(
      id: 7,
      firstName: 'Amanda',
      lastName: 'Martinez',
      dateOfBirth: DateTime(1992, 12, 5),
      phone: '+1 (555) 789-0123',
      email: 'amanda.m@email.com',
      address: '147 Walnut Drive, Sunnyvale',
      medicalHistory: 'Pregnancy, Gestational Diabetes',
      tags: 'priority,new',
      riskLevel: 3,
      createdAt: _baseDate.subtract(const Duration(days: 30)),
    ),
    Patient(
      id: 8,
      firstName: 'David',
      lastName: 'Brown',
      dateOfBirth: DateTime(1975, 6, 18),
      phone: '+1 (555) 890-1234',
      email: 'david.brown@email.com',
      address: '258 Spruce Avenue, Greenfield',
      medicalHistory: 'Back Pain, Insomnia',
      tags: 'followup',
      riskLevel: 2,
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

  /// Get today's appointment count
  static int get todayAppointmentCount => getAppointmentsForDay(_baseDate).length;

  /// Get pending appointments count
  static int get pendingAppointmentCount => 
    getAppointmentsForDay(_baseDate).where((a) => a.status == 'scheduled').length;
}

/// Demo medication class for prescription display
class DemoMedication {
  final String name;
  final String dosage;
  final String frequency;

  DemoMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });
}

/// Demo prescription class with additional display info
class DemoPrescription {
  final int id;
  final int patientId;
  final String patientName;
  final DateTime createdAt;
  final List<DemoMedication> medications;
  final String instructions;
  final bool isRefillable;
  final String status;

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
}
