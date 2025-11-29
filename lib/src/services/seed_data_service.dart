import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import '../db/doctor_db.dart';

/// Seed sample data into the database for testing and demo purposes.
/// This version checks if data exists first and skips if not empty.
Future<void> seedSampleData(DoctorDatabase db) async {
  // Check if patients already exist to avoid duplicates
  final existingPatients = await db.getAllPatients();
  if (existingPatients.isNotEmpty) {
    return; // Data already seeded
  }

  await _insertSampleData(db);
}

/// Force seed sample data - always adds data regardless of existing records.
/// Use this for demo/testing purposes when user explicitly requests it.
Future<void> seedSampleDataForce(DoctorDatabase db) async {
  await _insertSampleData(db);
}

/// Internal function to insert sample data - Pakistani patients with comprehensive data
Future<void> _insertSampleData(DoctorDatabase db) async {
  print('Seeding database with comprehensive sample data...');
  final random = Random();

  // Pakistani patient data - 30 patients with diverse conditions
  final patientData = [
    {'firstName': 'Muhammad', 'lastName': 'Ahmed Khan', 'dob': DateTime(1985, 3, 15), 'phone': '0300-1234567', 'email': 'ahmed.khan@gmail.com', 'address': 'House 45, Street 7, F-10/2, Islamabad', 'history': 'Hypertension, Type 2 Diabetes', 'tags': 'chronic,follow-up', 'risk': 3},
    {'firstName': 'Fatima', 'lastName': 'Bibi', 'dob': DateTime(1990, 7, 22), 'phone': '0321-2345678', 'email': 'fatima.bibi@yahoo.com', 'address': '123 Gulberg III, Lahore', 'history': 'Anxiety, Insomnia', 'tags': 'psychiatric', 'risk': 2},
    {'firstName': 'Ali', 'lastName': 'Raza', 'dob': DateTime(1978, 11, 5), 'phone': '0333-3456789', 'email': 'ali.raza@hotmail.com', 'address': 'Flat 12, Block B, Clifton, Karachi', 'history': 'Cardiovascular disease, High cholesterol', 'tags': 'cardiac,urgent', 'risk': 5},
    {'firstName': 'Ayesha', 'lastName': 'Siddiqui', 'dob': DateTime(1995, 1, 18), 'phone': '0345-4567890', 'email': 'ayesha.siddiqui@gmail.com', 'address': '78 Model Town, Lahore', 'history': 'Migraine, Depression', 'tags': 'neurology,psychiatric', 'risk': 3},
    {'firstName': 'Hassan', 'lastName': 'Malik', 'dob': DateTime(1970, 6, 30), 'phone': '0302-5678901', 'email': 'hassan.malik@outlook.com', 'address': 'House 23, DHA Phase 5, Karachi', 'history': 'Arthritis, Osteoporosis', 'tags': 'orthopedic,elderly', 'risk': 2},
    {'firstName': 'Zainab', 'lastName': 'Hussain', 'dob': DateTime(1988, 9, 12), 'phone': '0311-6789012', 'email': 'zainab.hussain@gmail.com', 'address': '56 Satellite Town, Rawalpindi', 'history': 'Asthma, Allergies', 'tags': 'respiratory', 'risk': 1},
    {'firstName': 'Usman', 'lastName': 'Tariq', 'dob': DateTime(1982, 4, 25), 'phone': '0322-7890123', 'email': 'usman.tariq@yahoo.com', 'address': 'Plot 89, Bahria Town, Islamabad', 'history': 'Bipolar disorder', 'tags': 'psychiatric,follow-up', 'risk': 4},
    {'firstName': 'Maryam', 'lastName': 'Nawaz', 'dob': DateTime(1992, 12, 8), 'phone': '0334-8901234', 'email': 'maryam.nawaz@gmail.com', 'address': '34 Johar Town, Lahore', 'history': 'PCOS, Thyroid disorder', 'tags': 'endocrine', 'risk': 2},
    {'firstName': 'Bilal', 'lastName': 'Ashraf', 'dob': DateTime(1975, 8, 3), 'phone': '0301-9012345', 'email': 'bilal.ashraf@hotmail.com', 'address': 'House 67, G-9/4, Islamabad', 'history': 'Chronic kidney disease', 'tags': 'nephrology,chronic', 'risk': 5},
    {'firstName': 'Sana', 'lastName': 'Javed', 'dob': DateTime(1998, 2, 14), 'phone': '0312-0123456', 'email': 'sana.javed@gmail.com', 'address': '45 Gulshan-e-Iqbal, Karachi', 'history': 'Anxiety, Panic attacks', 'tags': 'psychiatric', 'risk': 3},
    {'firstName': 'Imran', 'lastName': 'Shah', 'dob': DateTime(1968, 5, 20), 'phone': '0323-1234567', 'email': 'imran.shah@outlook.com', 'address': '12 Cantt Area, Peshawar', 'history': 'COPD, Hypertension', 'tags': 'respiratory,cardiac', 'risk': 4},
    {'firstName': 'Hira', 'lastName': 'Qureshi', 'dob': DateTime(1993, 10, 7), 'phone': '0335-2345678', 'email': 'hira.qureshi@yahoo.com', 'address': '89 Garden Town, Lahore', 'history': 'Iron deficiency anemia', 'tags': 'hematology', 'risk': 1},
    {'firstName': 'Kamran', 'lastName': 'Akmal', 'dob': DateTime(1980, 7, 16), 'phone': '0303-3456789', 'email': 'kamran.akmal@gmail.com', 'address': 'Flat 5, Block C, North Nazimabad, Karachi', 'history': 'Schizophrenia', 'tags': 'psychiatric,chronic', 'risk': 5},
    {'firstName': 'Amna', 'lastName': 'Ilyas', 'dob': DateTime(1987, 3, 28), 'phone': '0313-4567890', 'email': 'amna.ilyas@hotmail.com', 'address': '23 Wapda Town, Lahore', 'history': 'Gestational diabetes (history)', 'tags': 'endocrine,follow-up', 'risk': 2},
    {'firstName': 'Faisal', 'lastName': 'Qureshi', 'dob': DateTime(1972, 11, 11), 'phone': '0324-5678901', 'email': 'faisal.qureshi@gmail.com', 'address': 'House 78, E-11/3, Islamabad', 'history': 'Liver cirrhosis, Hepatitis C', 'tags': 'gastro,chronic', 'risk': 5},
    {'firstName': 'Nadia', 'lastName': 'Khan', 'dob': DateTime(1996, 6, 5), 'phone': '0336-6789012', 'email': 'nadia.khan@yahoo.com', 'address': '56 Gulberg II, Lahore', 'history': 'OCD, Social anxiety', 'tags': 'psychiatric', 'risk': 3},
    {'firstName': 'Saad', 'lastName': 'Haroon', 'dob': DateTime(1983, 1, 22), 'phone': '0304-7890123', 'email': 'saad.haroon@outlook.com', 'address': '34 Defence, Karachi', 'history': 'Peptic ulcer, GERD', 'tags': 'gastro', 'risk': 2},
    {'firstName': 'Rabia', 'lastName': 'Butt', 'dob': DateTime(1991, 8, 17), 'phone': '0314-8901234', 'email': 'rabia.butt@gmail.com', 'address': '67 Bahria Town, Rawalpindi', 'history': 'Epilepsy', 'tags': 'neurology,chronic', 'risk': 4},
    {'firstName': 'Waqar', 'lastName': 'Younis', 'dob': DateTime(1965, 4, 9), 'phone': '0325-9012345', 'email': 'waqar.younis@hotmail.com', 'address': 'House 90, F-7/2, Islamabad', 'history': 'Prostate issues, BPH', 'tags': 'urology,elderly', 'risk': 3},
    {'firstName': 'Mehwish', 'lastName': 'Hayat', 'dob': DateTime(1989, 12, 25), 'phone': '0337-0123456', 'email': 'mehwish.hayat@yahoo.com', 'address': '12 Model Town Extension, Lahore', 'history': 'Fibromyalgia', 'tags': 'rheumatology,chronic', 'risk': 2},
    {'firstName': 'Junaid', 'lastName': 'Jamshed', 'dob': DateTime(1977, 9, 3), 'phone': '0305-1234567', 'email': 'junaid.j@gmail.com', 'address': '45 Shahra-e-Faisal, Karachi', 'history': 'Major depressive disorder', 'tags': 'psychiatric,follow-up', 'risk': 4},
    {'firstName': 'Sidra', 'lastName': 'Iqbal', 'dob': DateTime(1994, 5, 30), 'phone': '0315-2345678', 'email': 'sidra.iqbal@outlook.com', 'address': '78 PWD Housing, Islamabad', 'history': 'Vitamin D deficiency, Fatigue', 'tags': 'general', 'risk': 1},
    {'firstName': 'Adnan', 'lastName': 'Sami', 'dob': DateTime(1971, 2, 15), 'phone': '0326-3456789', 'email': 'adnan.sami@hotmail.com', 'address': '23 Cavalry Ground, Lahore', 'history': 'Obesity, Sleep apnea', 'tags': 'metabolic,respiratory', 'risk': 3},
    {'firstName': 'Komal', 'lastName': 'Rizvi', 'dob': DateTime(1986, 7, 8), 'phone': '0338-4567890', 'email': 'komal.rizvi@gmail.com', 'address': 'Flat 8, Block A, Askari 11, Lahore', 'history': 'Rheumatoid arthritis', 'tags': 'rheumatology,chronic', 'risk': 3},
    {'firstName': 'Shahid', 'lastName': 'Afridi', 'dob': DateTime(1980, 3, 1), 'phone': '0306-5678901', 'email': 'shahid.afridi@yahoo.com', 'address': '56 Hayatabad, Peshawar', 'history': 'Sports injury, Knee problems', 'tags': 'orthopedic', 'risk': 2},
    {'firstName': 'Iqra', 'lastName': 'Aziz', 'dob': DateTime(1997, 11, 24), 'phone': '0316-6789012', 'email': 'iqra.aziz@gmail.com', 'address': '89 Gulistan Colony, Faisalabad', 'history': 'Acne, Hormonal imbalance', 'tags': 'dermatology,endocrine', 'risk': 1},
    {'firstName': 'Asad', 'lastName': 'Shafiq', 'dob': DateTime(1984, 6, 18), 'phone': '0327-7890123', 'email': 'asad.shafiq@outlook.com', 'address': '34 Askari 10, Lahore', 'history': 'Generalized anxiety disorder', 'tags': 'psychiatric', 'risk': 3},
    {'firstName': 'Nimra', 'lastName': 'Ali', 'dob': DateTime(1990, 10, 2), 'phone': '0339-8901234', 'email': 'nimra.ali@hotmail.com', 'address': '67 DHA Phase 6, Karachi', 'history': 'Hypothyroidism', 'tags': 'endocrine,follow-up', 'risk': 2},
    {'firstName': 'Babar', 'lastName': 'Azam', 'dob': DateTime(1994, 10, 15), 'phone': '0307-9012345', 'email': 'babar.azam@gmail.com', 'address': '12 Gulberg IV, Lahore', 'history': 'Mild hypertension', 'tags': 'cardiac', 'risk': 2},
    {'firstName': 'Sajal', 'lastName': 'Aly', 'dob': DateTime(1993, 1, 17), 'phone': '0317-0123456', 'email': 'sajal.aly@yahoo.com', 'address': '45 PECHS, Karachi', 'history': 'PTSD, Adjustment disorder', 'tags': 'psychiatric,follow-up', 'risk': 4},
  ];

  // Insert all patients
  final patientIds = <int>[];
  for (final p in patientData) {
    final id = await db.insertPatient(
      PatientsCompanion(
        firstName: Value(p['firstName'] as String),
        lastName: Value(p['lastName'] as String),
        dateOfBirth: Value(p['dob'] as DateTime),
        phone: Value(p['phone'] as String),
        email: Value(p['email'] as String),
        address: Value(p['address'] as String),
        medicalHistory: Value(p['history'] as String),
        tags: Value(p['tags'] as String),
        riskLevel: Value(p['risk'] as int),
      ),
    );
    patientIds.add(id);
  }
  print('✓ Inserted ${patientIds.length} patients');

  // ========== APPOINTMENTS ==========
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  final appointmentReasons = [
    'Regular checkup',
    'Follow-up consultation',
    'Medication review',
    'Blood pressure monitoring',
    'Lab results discussion',
    'Psychiatric evaluation',
    'Pain management',
    'Prescription refill',
    'New symptoms evaluation',
    'Post-treatment follow-up',
    'Annual physical exam',
    'Diabetes management',
    'Mental health session',
    'Cardiac assessment',
    'Respiratory therapy',
  ];

  final appointmentStatuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no-show'];
  int appointmentCount = 0;

  // Past appointments (last 30 days)
  for (int dayOffset = 30; dayOffset > 0; dayOffset--) {
    final appointmentDay = today.subtract(Duration(days: dayOffset));
    final appointmentsPerDay = 3 + random.nextInt(4); // 3-6 per day
    
    for (int i = 0; i < appointmentsPerDay; i++) {
      final patientIndex = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(8); // 9am to 5pm
      final minute = [0, 15, 30, 45][random.nextInt(4)];
      
      await db.insertAppointment(
        AppointmentsCompanion(
          patientId: Value(patientIds[patientIndex]),
          appointmentDateTime: Value(appointmentDay.add(Duration(hours: hour, minutes: minute))),
          durationMinutes: Value([15, 20, 30, 45, 60][random.nextInt(5)]),
          reason: Value(appointmentReasons[random.nextInt(appointmentReasons.length)]),
          status: Value(random.nextInt(10) < 8 ? 'completed' : (random.nextInt(2) == 0 ? 'cancelled' : 'no-show')),
          notes: Value('Patient visit notes for ${patientData[patientIndex]['firstName']} ${patientData[patientIndex]['lastName']}'),
        ),
      );
      appointmentCount++;
    }
  }

  // Today's appointments
  for (int i = 0; i < 6; i++) {
    final patientIndex = i % patientIds.length;
    final hour = 9 + (i * 1.5).floor();
    
    await db.insertAppointment(
      AppointmentsCompanion(
        patientId: Value(patientIds[patientIndex]),
        appointmentDateTime: Value(today.add(Duration(hours: hour))),
        durationMinutes: Value([15, 30, 30, 45, 30, 20][i]),
        reason: Value(appointmentReasons[i]),
        status: Value(i < 3 ? 'completed' : 'confirmed'),
        notes: Value('Today\'s appointment for ${patientData[patientIndex]['firstName']}'),
      ),
    );
    appointmentCount++;
  }

  // Future appointments (next 14 days)
  for (int dayOffset = 1; dayOffset <= 14; dayOffset++) {
    final appointmentDay = today.add(Duration(days: dayOffset));
    final appointmentsPerDay = 2 + random.nextInt(5); // 2-6 per day
    
    for (int i = 0; i < appointmentsPerDay; i++) {
      final patientIndex = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(8);
      final minute = [0, 15, 30, 45][random.nextInt(4)];
      
      await db.insertAppointment(
        AppointmentsCompanion(
          patientId: Value(patientIds[patientIndex]),
          appointmentDateTime: Value(appointmentDay.add(Duration(hours: hour, minutes: minute))),
          durationMinutes: Value([15, 20, 30, 45][random.nextInt(4)]),
          reason: Value(appointmentReasons[random.nextInt(appointmentReasons.length)]),
          status: Value(random.nextInt(3) == 0 ? 'confirmed' : 'scheduled'),
          reminderAt: Value(appointmentDay.subtract(const Duration(hours: 24))),
          notes: Value('Upcoming appointment'),
        ),
      );
      appointmentCount++;
    }
  }
  print('✓ Inserted $appointmentCount appointments');

  // ========== PRESCRIPTIONS ==========
  final medications = [
    [
      {'name': 'Metformin', 'dosage': '500mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Lisinopril', 'dosage': '10mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Alprazolam', 'dosage': '0.5mg', 'frequency': 'As needed', 'duration': '1 month'},
      {'name': 'Zolpidem', 'dosage': '10mg', 'frequency': 'At bedtime', 'duration': '2 weeks'},
    ],
    [
      {'name': 'Atorvastatin', 'dosage': '20mg', 'frequency': 'Once daily', 'duration': '6 months'},
      {'name': 'Aspirin', 'dosage': '75mg', 'frequency': 'Once daily', 'duration': '6 months'},
      {'name': 'Metoprolol', 'dosage': '25mg', 'frequency': 'Twice daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Sumatriptan', 'dosage': '50mg', 'frequency': 'At onset', 'duration': '30 tablets'},
      {'name': 'Sertraline', 'dosage': '50mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Celecoxib', 'dosage': '200mg', 'frequency': 'Once daily', 'duration': '1 month'},
      {'name': 'Calcium + Vitamin D', 'dosage': '600mg', 'frequency': 'Twice daily', 'duration': '6 months'},
    ],
    [
      {'name': 'Salbutamol Inhaler', 'dosage': '100mcg', 'frequency': 'As needed', 'duration': '200 puffs'},
      {'name': 'Fluticasone', 'dosage': '250mcg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Montelukast', 'dosage': '10mg', 'frequency': 'At bedtime', 'duration': '3 months'},
    ],
    [
      {'name': 'Lithium', 'dosage': '300mg', 'frequency': 'Twice daily', 'duration': '6 months'},
      {'name': 'Quetiapine', 'dosage': '100mg', 'frequency': 'At bedtime', 'duration': '3 months'},
    ],
    [
      {'name': 'Metformin', 'dosage': '850mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Levothyroxine', 'dosage': '50mcg', 'frequency': 'Once daily (empty stomach)', 'duration': '6 months'},
    ],
    [
      {'name': 'Telmisartan', 'dosage': '40mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Furosemide', 'dosage': '40mg', 'frequency': 'Once daily', 'duration': '1 month'},
      {'name': 'Potassium Chloride', 'dosage': '600mg', 'frequency': 'Once daily', 'duration': '1 month'},
    ],
    [
      {'name': 'Escitalopram', 'dosage': '10mg', 'frequency': 'Once daily (morning)', 'duration': '3 months'},
      {'name': 'Clonazepam', 'dosage': '0.5mg', 'frequency': 'As needed (max 2/day)', 'duration': '20 tablets'},
    ],
    [
      {'name': 'Tiotropium', 'dosage': '18mcg', 'frequency': 'Once daily', 'duration': '30 capsules'},
      {'name': 'Amlodipine', 'dosage': '5mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Hydrochlorothiazide', 'dosage': '12.5mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Ferrous Sulfate', 'dosage': '200mg', 'frequency': 'Twice daily (with vitamin C)', 'duration': '3 months'},
      {'name': 'Folic Acid', 'dosage': '5mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Risperidone', 'dosage': '2mg', 'frequency': 'Twice daily', 'duration': '6 months'},
      {'name': 'Benztropine', 'dosage': '1mg', 'frequency': 'Twice daily', 'duration': '6 months'},
      {'name': 'Clozapine', 'dosage': '50mg', 'frequency': 'At bedtime', 'duration': '3 months'},
    ],
    [
      {'name': 'Glimepiride', 'dosage': '2mg', 'frequency': 'Once daily (breakfast)', 'duration': '3 months'},
      {'name': 'Pioglitazone', 'dosage': '15mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Tenofovir', 'dosage': '300mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Ribavirin', 'dosage': '400mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Silymarin', 'dosage': '140mg', 'frequency': 'Three times daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Fluoxetine', 'dosage': '20mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Propranolol', 'dosage': '20mg', 'frequency': 'As needed', 'duration': '30 tablets'},
    ],
    [
      {'name': 'Omeprazole', 'dosage': '20mg', 'frequency': 'Once daily (before breakfast)', 'duration': '1 month'},
      {'name': 'Sucralfate', 'dosage': '1g', 'frequency': 'Four times daily', 'duration': '2 weeks'},
    ],
    [
      {'name': 'Levetiracetam', 'dosage': '500mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Carbamazepine', 'dosage': '200mg', 'frequency': 'Twice daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Tamsulosin', 'dosage': '0.4mg', 'frequency': 'Once daily (after meal)', 'duration': '3 months'},
      {'name': 'Finasteride', 'dosage': '5mg', 'frequency': 'Once daily', 'duration': '6 months'},
    ],
    [
      {'name': 'Pregabalin', 'dosage': '75mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Duloxetine', 'dosage': '30mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Tramadol', 'dosage': '50mg', 'frequency': 'As needed', 'duration': '20 tablets'},
    ],
    [
      {'name': 'Venlafaxine XR', 'dosage': '75mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Trazodone', 'dosage': '50mg', 'frequency': 'At bedtime', 'duration': '1 month'},
    ],
    [
      {'name': 'Vitamin D3', 'dosage': '50,000 IU', 'frequency': 'Once weekly', 'duration': '8 weeks'},
      {'name': 'Vitamin B12', 'dosage': '1000mcg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Orlistat', 'dosage': '120mg', 'frequency': 'With each main meal', 'duration': '3 months'},
      {'name': 'CPAP Machine', 'dosage': 'Auto-titrating', 'frequency': 'Every night', 'duration': 'Ongoing'},
    ],
    [
      {'name': 'Methotrexate', 'dosage': '15mg', 'frequency': 'Once weekly', 'duration': '3 months'},
      {'name': 'Folic Acid', 'dosage': '5mg', 'frequency': 'Daily (except MTX day)', 'duration': '3 months'},
      {'name': 'Hydroxychloroquine', 'dosage': '200mg', 'frequency': 'Twice daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Diclofenac Gel', 'dosage': '1%', 'frequency': 'Apply 3-4 times daily', 'duration': '2 weeks'},
      {'name': 'Glucosamine', 'dosage': '1500mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Isotretinoin', 'dosage': '20mg', 'frequency': 'Once daily', 'duration': '6 months'},
      {'name': 'Spironolactone', 'dosage': '50mg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Buspirone', 'dosage': '10mg', 'frequency': 'Twice daily', 'duration': '3 months'},
      {'name': 'Propranolol', 'dosage': '10mg', 'frequency': 'Three times daily', 'duration': '1 month'},
    ],
    [
      {'name': 'Levothyroxine', 'dosage': '75mcg', 'frequency': 'Once daily (empty stomach)', 'duration': '6 months'},
      {'name': 'Selenium', 'dosage': '200mcg', 'frequency': 'Once daily', 'duration': '3 months'},
    ],
    [
      {'name': 'Amlodipine', 'dosage': '5mg', 'frequency': 'Once daily', 'duration': '3 months'},
      {'name': 'Aspirin', 'dosage': '75mg', 'frequency': 'Once daily', 'duration': '6 months'},
    ],
    [
      {'name': 'Prazosin', 'dosage': '1mg', 'frequency': 'At bedtime', 'duration': '3 months'},
      {'name': 'Sertraline', 'dosage': '100mg', 'frequency': 'Once daily', 'duration': '6 months'},
      {'name': 'Cognitive Behavioral Therapy', 'dosage': 'N/A', 'frequency': 'Weekly sessions', 'duration': '12 weeks'},
    ],
  ];

  final instructions = [
    'Take with meals. Monitor blood sugar levels weekly. Report hypoglycemic symptoms.',
    'Take as directed. Avoid alcohol. Report any unusual symptoms. Do not drive if drowsy.',
    'Take with food. Monitor blood pressure regularly. Report any muscle pain.',
    'Take at first sign of symptoms. Do not exceed 2 doses in 24 hours. Avoid during aura.',
    'Take with food. Avoid prolonged sun exposure. Report GI issues.',
    'Use inhaler as directed. Rinse mouth after steroid inhaler. Keep rescue inhaler available.',
    'Regular blood tests required every 3 months. Report any side effects. Stay hydrated.',
    'Take thyroid medication on empty stomach. Wait 4 hours before calcium supplements.',
    'Monitor kidney function. Report any swelling or breathing difficulty. Weigh daily.',
    'Take in the morning. Avoid abrupt discontinuation. Report suicidal thoughts immediately.',
    'Use regularly for best effect. Annual lung function tests. Report any infections.',
    'Take with vitamin C for better absorption. Avoid tea/coffee within 2 hours.',
    'Regular follow-up required. Report any movement problems or excessive sedation.',
    'Monitor blood sugar before meals. Maintain consistent meal times.',
    'Regular liver function tests required. Avoid alcohol completely.',
    'Take with food. Report any worsening of symptoms. Attend therapy sessions.',
    'Take before meals. Avoid lying down after eating. Follow diet restrictions.',
    'Do not stop suddenly. Report any seizure changes. Blood tests every 6 months.',
    'Take after dinner. Report urinary symptoms. Regular prostate exams.',
    'May cause drowsiness. Report any worsening pain. Avoid driving until adjusted.',
    'Take consistently. Report severe anxiety or panic. Attend follow-up appointments.',
    'Take vitamin D with fatty meal. Recheck levels in 3 months.',
    'Follow reduced-calorie diet. Use CPAP every night. Weight check monthly.',
    'Blood tests before each dose. Report any infections. Avoid pregnancy.',
    'Physical therapy recommended. Apply gel to clean skin. Avoid heat application.',
    'Monthly pregnancy tests required (females). Use sunscreen. Lip moisturizer recommended.',
    'Take consistently. Effects may take 2-4 weeks. Report panic attacks.',
    'Annual thyroid function tests. Report heart palpitations or weight changes.',
    'Lifestyle modifications important. Low sodium diet. Regular exercise.',
    'Take prazosin at bedtime initially. Therapy attendance is essential.',
  ];

  int prescriptionCount = 0;
  for (int i = 0; i < 30; i++) {
    // Multiple prescriptions per patient over time
    final numPrescriptions = 1 + random.nextInt(3); // 1-3 prescriptions per patient
    for (int j = 0; j < numPrescriptions; j++) {
      await db.insertPrescription(
        PrescriptionsCompanion(
          patientId: Value(patientIds[i]),
          itemsJson: Value(jsonEncode(medications[i])),
          instructions: Value(instructions[i]),
          isRefillable: Value(random.nextInt(3) != 0), // 66% refillable
          createdAt: Value(today.subtract(Duration(days: j * 30 + random.nextInt(15)))),
        ),
      );
      prescriptionCount++;
    }
  }
  print('✓ Inserted $prescriptionCount prescriptions');

  // ========== MEDICAL RECORDS ==========
  final recordTypes = ['general', 'psychiatric_assessment', 'lab_result', 'imaging', 'procedure'];
  
  // General consultation records
  final generalRecords = [
    {'title': 'Initial Consultation', 'diagnosis': 'Type 2 Diabetes Mellitus', 'treatment': 'Started Metformin 500mg BD', 'notes': 'Patient education on diet and exercise. Glucometer provided.'},
    {'title': 'Routine Follow-up', 'diagnosis': 'Controlled Hypertension', 'treatment': 'Continue current medications', 'notes': 'Blood pressure well controlled. Continue lifestyle modifications.'},
    {'title': 'Emergency Visit', 'diagnosis': 'Acute Anxiety Attack', 'treatment': 'Lorazepam 1mg stat, counseling', 'notes': 'Trigger identified as work stress. Referral to psychiatrist.'},
    {'title': 'Annual Physical Exam', 'diagnosis': 'Overall good health', 'treatment': 'Preventive care recommendations', 'notes': 'Vaccinations up to date. Cancer screening discussed.'},
    {'title': 'Sick Visit', 'diagnosis': 'Upper Respiratory Infection', 'treatment': 'Symptomatic treatment, rest', 'notes': 'Viral etiology likely. Return if not improving in 5 days.'},
    {'title': 'Chronic Disease Management', 'diagnosis': 'COPD Stage II', 'treatment': 'Inhaler therapy optimized', 'notes': 'Smoking cessation counseling provided. Pulmonary rehab referral.'},
    {'title': 'Post-Hospitalization Follow-up', 'diagnosis': 'Post-MI care', 'treatment': 'Cardiac rehabilitation', 'notes': 'Good recovery. Stress test scheduled. Diet counseling provided.'},
    {'title': 'Medication Review', 'diagnosis': 'Polypharmacy assessment', 'treatment': 'Medications optimized', 'notes': 'Discontinued 2 redundant medications. Patient education on drug interactions.'},
  ];

  // Psychiatric assessment records
  final psychiatricRecords = [
    {
      'title': 'Initial Psychiatric Evaluation',
      'data': {'chiefComplaint': 'Persistent sadness and loss of interest', 'moodAssessment': 'Depressed', 'anxietyLevel': 'Moderate', 'sleepQuality': 'Poor - early morning awakening', 'appetiteChanges': 'Decreased', 'suicidalIdeation': 'Denied', 'substanceUse': 'None', 'phq9Score': 15, 'gad7Score': 12},
      'diagnosis': 'Major Depressive Disorder, moderate severity',
      'treatment': 'Started Sertraline 50mg daily. Weekly CBT sessions.',
      'notes': 'Patient shows insight into condition. Good social support. Follow-up in 2 weeks.'
    },
    {
      'title': 'Anxiety Disorder Assessment',
      'data': {'chiefComplaint': 'Excessive worry and panic attacks', 'moodAssessment': 'Anxious', 'anxietyLevel': 'Severe', 'panicAttacks': 'Yes - 3 per week', 'avoidanceBehaviors': 'Yes', 'sleepQuality': 'Poor', 'phq9Score': 8, 'gad7Score': 18},
      'diagnosis': 'Generalized Anxiety Disorder with Panic',
      'treatment': 'Escitalopram 10mg daily, Clonazepam 0.5mg PRN',
      'notes': 'Panic attack management plan discussed. Breathing exercises taught.'
    },
    {
      'title': 'Bipolar Disorder Follow-up',
      'data': {'currentEpisode': 'Euthymic', 'moodStability': 'Good for 3 months', 'medicationCompliance': 'Good', 'sideEffects': 'Mild tremor', 'sleepPattern': 'Regular', 'lithiumLevel': '0.8 mEq/L'},
      'diagnosis': 'Bipolar I Disorder - stable on treatment',
      'treatment': 'Continue Lithium 300mg BD, Quetiapine 100mg HS',
      'notes': 'Stable on current regimen. Lithium levels therapeutic. Renal function normal.'
    },
    {
      'title': 'PTSD Assessment',
      'data': {'traumaHistory': 'Motor vehicle accident 6 months ago', 'flashbacks': 'Daily', 'nightmares': '4-5 per week', 'avoidance': 'Avoiding driving and highways', 'hypervigilance': 'Marked', 'pcl5Score': 52},
      'diagnosis': 'Post-Traumatic Stress Disorder',
      'treatment': 'Started Prazosin 1mg HS for nightmares. EMDR therapy referral.',
      'notes': 'Patient motivated for treatment. Support group recommended.'
    },
    {
      'title': 'Schizophrenia Management',
      'data': {'positiveSymptoms': 'Auditory hallucinations - well controlled', 'negativeSymptoms': 'Mild flat affect', 'cognitiveFunction': 'Mildly impaired', 'medicationCompliance': 'Fair - occasional missed doses', 'sideEffects': 'Weight gain'},
      'diagnosis': 'Schizophrenia - partially controlled',
      'treatment': 'Continue Risperidone 2mg BD. Added Metformin for metabolic syndrome.',
      'notes': 'Family meeting held. Medication reminder system implemented.'
    },
  ];

  // Lab results
  final labRecords = [
    {
      'title': 'Complete Blood Count',
      'data': {'hemoglobin': '14.2 g/dL', 'wbc': '7.5 x10^9/L', 'platelets': '250 x10^9/L', 'mcv': '88 fL', 'hematocrit': '42%'},
      'notes': 'All values within normal range. No anemia or infection.'
    },
    {
      'title': 'Comprehensive Metabolic Panel',
      'data': {'glucose': '126 mg/dL (H)', 'bun': '18 mg/dL', 'creatinine': '0.9 mg/dL', 'sodium': '140 mEq/L', 'potassium': '4.2 mEq/L', 'chloride': '102 mEq/L', 'co2': '24 mEq/L', 'calcium': '9.5 mg/dL', 'alt': '25 U/L', 'ast': '22 U/L'},
      'notes': 'Glucose slightly elevated. Continue monitoring. Kidney and liver function normal.'
    },
    {
      'title': 'Lipid Panel',
      'data': {'totalCholesterol': '220 mg/dL (H)', 'ldl': '145 mg/dL (H)', 'hdl': '42 mg/dL', 'triglycerides': '165 mg/dL', 'nonHdl': '178 mg/dL'},
      'notes': 'Elevated LDL cholesterol. Statin therapy recommended. Diet modifications advised.'
    },
    {
      'title': 'Thyroid Function Tests',
      'data': {'tsh': '5.8 mIU/L (H)', 'freeT4': '0.9 ng/dL', 'freeT3': '2.8 pg/mL', 'tpoAntibodies': 'Positive'},
      'notes': 'Subclinical hypothyroidism with positive antibodies. Start low-dose levothyroxine.'
    },
    {
      'title': 'HbA1c Test',
      'data': {'hba1c': '7.8%', 'estimatedAverageGlucose': '177 mg/dL'},
      'notes': 'Above target of 7%. Medication adjustment needed. Diet review scheduled.'
    },
    {
      'title': 'Liver Function Panel',
      'data': {'alt': '85 U/L (H)', 'ast': '72 U/L (H)', 'alp': '95 U/L', 'totalBilirubin': '0.8 mg/dL', 'albumin': '4.0 g/dL', 'ggt': '65 U/L (H)'},
      'notes': 'Elevated liver enzymes. Hepatitis panel ordered. Alcohol use discussed.'
    },
    {
      'title': 'Urinalysis',
      'data': {'appearance': 'Clear', 'ph': '6.0', 'specificGravity': '1.020', 'protein': 'Trace', 'glucose': 'Negative', 'ketones': 'Negative', 'blood': 'Negative', 'wbc': '0-2/hpf', 'bacteria': 'None'},
      'notes': 'Trace protein. Follow-up with 24-hour urine protein if persists.'
    },
    {
      'title': 'Vitamin D Level',
      'data': {'vitaminD25OH': '15 ng/mL (L)', 'normalRange': '30-100 ng/mL'},
      'notes': 'Severe vitamin D deficiency. High-dose supplementation started.'
    },
  ];

  // Imaging records
  final imagingRecords = [
    {
      'title': 'Chest X-Ray',
      'data': {'findings': 'Clear lung fields bilaterally', 'heartSize': 'Normal', 'mediastinum': 'Normal', 'bones': 'No acute abnormality'},
      'notes': 'No active pulmonary disease. Normal cardiac silhouette.'
    },
    {
      'title': 'Abdominal Ultrasound',
      'data': {'liver': 'Mild fatty infiltration', 'gallbladder': 'Normal, no stones', 'kidneys': 'Normal size and echogenicity', 'spleen': 'Normal', 'pancreas': 'Partially visualized, normal'},
      'notes': 'Fatty liver disease grade 1. Recommend lifestyle modifications.'
    },
    {
      'title': 'Echocardiogram',
      'data': {'ef': '55%', 'lvFunction': 'Normal', 'valves': 'No significant abnormality', 'rwma': 'None', 'pericardium': 'Normal'},
      'notes': 'Normal cardiac function. No valvular disease.'
    },
    {
      'title': 'Brain MRI',
      'data': {'findings': 'No acute infarct', 'ventricles': 'Normal', 'whiteMatters': 'Few nonspecific foci of T2 hyperintensity', 'massLesion': 'None'},
      'notes': 'Age-appropriate changes. No evidence of stroke or tumor.'
    },
    {
      'title': 'Knee X-Ray',
      'data': {'findings': 'Moderate osteoarthritis', 'jointSpace': 'Narrowed', 'osteophytes': 'Present', 'alignment': 'Mild varus'},
      'notes': 'Osteoarthritis of knee. Physical therapy and NSAIDs recommended.'
    },
  ];

  // Procedure records
  final procedureRecords = [
    {
      'title': 'ECG (Electrocardiogram)',
      'data': {'rhythm': 'Normal sinus rhythm', 'rate': '72 bpm', 'axis': 'Normal', 'intervals': 'PR 160ms, QRS 88ms, QTc 420ms', 'findings': 'No acute ST changes'},
      'notes': 'Normal ECG. No evidence of ischemia or arrhythmia.'
    },
    {
      'title': 'Spirometry',
      'data': {'fev1': '2.8L (78% predicted)', 'fvc': '3.5L (85% predicted)', 'fev1FvcRatio': '80%', 'interpretation': 'Mild obstruction'},
      'notes': 'Mild obstructive pattern consistent with asthma. Bronchodilator response positive.'
    },
    {
      'title': 'Blood Pressure Monitoring',
      'data': {'morningReadings': '138/88, 135/85, 140/90', 'eveningReadings': '130/82, 128/80, 132/84', 'averageBP': '134/85 mmHg'},
      'notes': 'Stage 1 hypertension. Lifestyle modifications initiated. Medication if not controlled.'
    },
    {
      'title': 'Wound Care',
      'data': {'woundLocation': 'Left lower leg', 'woundSize': '2cm x 3cm', 'appearance': 'Granulating well', 'treatment': 'Cleaned, dressed with hydrocolloid'},
      'notes': 'Healing appropriately. Continue daily dressing changes. Review in 1 week.'
    },
    {
      'title': 'Joint Injection',
      'data': {'joint': 'Right knee', 'medication': 'Triamcinolone 40mg + Lidocaine 1ml', 'technique': 'Anterolateral approach', 'complications': 'None'},
      'notes': 'Successful injection. Expect relief in 24-48 hours. Avoid strenuous activity for 48 hours.'
    },
  ];

  int medicalRecordCount = 0;

  // Add medical records for each patient
  for (int i = 0; i < patientIds.length; i++) {
    final numRecords = 2 + random.nextInt(5); // 2-6 records per patient
    
    for (int j = 0; j < numRecords; j++) {
      final recordType = recordTypes[random.nextInt(recordTypes.length)];
      final recordDate = today.subtract(Duration(days: random.nextInt(365)));
      
      String title, description, diagnosis, treatment, doctorNotes;
      Map<String, dynamic> dataJson = {};
      
      switch (recordType) {
        case 'general':
          final record = generalRecords[random.nextInt(generalRecords.length)];
          title = record['title'] as String;
          description = 'General consultation visit';
          diagnosis = record['diagnosis'] as String;
          treatment = record['treatment'] as String;
          doctorNotes = record['notes'] as String;
          break;
        case 'psychiatric_assessment':
          final record = psychiatricRecords[random.nextInt(psychiatricRecords.length)];
          title = record['title'] as String;
          description = 'Psychiatric evaluation and assessment';
          diagnosis = record['diagnosis'] as String;
          treatment = record['treatment'] as String;
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
          break;
        case 'lab_result':
          final record = labRecords[random.nextInt(labRecords.length)];
          title = record['title'] as String;
          description = 'Laboratory test results';
          diagnosis = 'See results';
          treatment = 'Based on results';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
          break;
        case 'imaging':
          final record = imagingRecords[random.nextInt(imagingRecords.length)];
          title = record['title'] as String;
          description = 'Imaging study report';
          diagnosis = 'See findings';
          treatment = 'Based on findings';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
          break;
        case 'procedure':
          final record = procedureRecords[random.nextInt(procedureRecords.length)];
          title = record['title'] as String;
          description = 'Medical procedure performed';
          diagnosis = 'Procedure completed';
          treatment = 'As documented';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
          break;
        default:
          title = 'General Visit';
          description = 'Routine visit';
          diagnosis = 'Under evaluation';
          treatment = 'Pending';
          doctorNotes = 'Notes pending';
      }
      
      await db.insertMedicalRecord(
        MedicalRecordsCompanion(
          patientId: Value(patientIds[i]),
          recordType: Value(recordType),
          title: Value(title),
          description: Value(description),
          dataJson: Value(jsonEncode(dataJson)),
          diagnosis: Value(diagnosis),
          treatment: Value(treatment),
          doctorNotes: Value(doctorNotes),
          recordDate: Value(recordDate),
        ),
      );
      medicalRecordCount++;
    }
  }
  print('✓ Inserted $medicalRecordCount medical records');

  // ========== INVOICES ==========
  final consultationFees = [500, 800, 1000, 1500, 2000, 2500, 3000];
  final labTests = [
    {'name': 'Complete Blood Count (CBC)', 'price': 800},
    {'name': 'Lipid Profile', 'price': 1200},
    {'name': 'Liver Function Test (LFT)', 'price': 1000},
    {'name': 'Kidney Function Test (KFT)', 'price': 900},
    {'name': 'Thyroid Panel (TSH, T3, T4)', 'price': 1500},
    {'name': 'HbA1c Test', 'price': 600},
    {'name': 'Vitamin D Level', 'price': 1800},
    {'name': 'Vitamin B12 Level', 'price': 1200},
    {'name': 'Urine Complete Examination', 'price': 300},
    {'name': 'Fasting Blood Sugar', 'price': 200},
    {'name': 'Random Blood Sugar', 'price': 150},
    {'name': 'Hepatitis B & C Panel', 'price': 2500},
    {'name': 'COVID-19 PCR Test', 'price': 3500},
  ];
  final imagingServices = [
    {'name': 'Chest X-Ray', 'price': 800},
    {'name': 'Abdominal Ultrasound', 'price': 2500},
    {'name': 'ECG', 'price': 500},
    {'name': 'Echocardiogram', 'price': 5000},
    {'name': 'MRI Scan', 'price': 15000},
    {'name': 'CT Scan', 'price': 10000},
  ];
  final procedures = [
    {'name': 'Wound Dressing', 'price': 500},
    {'name': 'IV Cannulation', 'price': 300},
    {'name': 'Injection Administration', 'price': 200},
    {'name': 'Nebulization', 'price': 400},
    {'name': 'Minor Surgical Procedure', 'price': 3000},
    {'name': 'Joint Injection', 'price': 2000},
  ];
  final paymentMethods = ['Cash', 'Card', 'JazzCash', 'EasyPaisa', 'Bank Transfer', 'Insurance'];
  final paymentStatuses = ['Paid', 'Pending', 'Partial', 'Overdue'];

  int invoiceCount = 0;
  int invoiceNumber = 1000;

  // Generate invoices for all patients
  for (int i = 0; i < patientIds.length; i++) {
    final numInvoices = 1 + random.nextInt(4); // 1-4 invoices per patient
    
    for (int j = 0; j < numInvoices; j++) {
      final invoiceDate = today.subtract(Duration(days: j * 15 + random.nextInt(30)));
      final dueDate = invoiceDate.add(const Duration(days: 30));
      
      // Build invoice items
      final items = <Map<String, dynamic>>[];
      
      // Always include consultation
      final consultFee = consultationFees[random.nextInt(consultationFees.length)];
      items.add({'description': 'Consultation Fee', 'quantity': 1, 'rate': consultFee, 'total': consultFee});
      
      // Randomly add lab tests (0-3)
      final numLabTests = random.nextInt(4);
      for (int k = 0; k < numLabTests; k++) {
        final test = labTests[random.nextInt(labTests.length)];
        items.add({'description': test['name'], 'quantity': 1, 'rate': test['price'], 'total': test['price']});
      }
      
      // Randomly add imaging (30% chance)
      if (random.nextInt(100) < 30) {
        final imaging = imagingServices[random.nextInt(imagingServices.length)];
        items.add({'description': imaging['name'], 'quantity': 1, 'rate': imaging['price'], 'total': imaging['price']});
      }
      
      // Randomly add procedures (20% chance)
      if (random.nextInt(100) < 20) {
        final procedure = procedures[random.nextInt(procedures.length)];
        items.add({'description': procedure['name'], 'quantity': 1, 'rate': procedure['price'], 'total': procedure['price']});
      }
      
      // Calculate totals
      final subtotal = items.fold<double>(0, (sum, item) => sum + (item['total'] as int).toDouble());
      final discountPercent = random.nextInt(100) < 30 ? [5.0, 10.0, 15.0][random.nextInt(3)] : 0.0;
      final discountAmount = subtotal * (discountPercent / 100);
      final afterDiscount = subtotal - discountAmount;
      final taxPercent = 0.0; // No tax on medical services
      final taxAmount = 0.0;
      final grandTotal = afterDiscount + taxAmount;
      
      final paymentMethod = paymentMethods[random.nextInt(paymentMethods.length)];
      String paymentStatus;
      if (invoiceDate.isBefore(today.subtract(const Duration(days: 30)))) {
        paymentStatus = random.nextInt(100) < 80 ? 'Paid' : 'Overdue';
      } else if (invoiceDate.isBefore(today.subtract(const Duration(days: 7)))) {
        paymentStatus = random.nextInt(100) < 60 ? 'Paid' : (random.nextInt(2) == 0 ? 'Pending' : 'Partial');
      } else {
        paymentStatus = random.nextInt(100) < 40 ? 'Paid' : 'Pending';
      }
      
      await db.insertInvoice(
        InvoicesCompanion(
          patientId: Value(patientIds[i]),
          invoiceNumber: Value('INV-${invoiceDate.year}-${invoiceNumber++}'),
          invoiceDate: Value(invoiceDate),
          dueDate: Value(dueDate),
          itemsJson: Value(jsonEncode(items)),
          subtotal: Value(subtotal),
          discountPercent: Value(discountPercent),
          discountAmount: Value(discountAmount),
          taxPercent: Value(taxPercent),
          taxAmount: Value(taxAmount),
          grandTotal: Value(grandTotal),
          paymentMethod: Value(paymentMethod),
          paymentStatus: Value(paymentStatus),
          notes: Value(paymentStatus == 'Partial' ? 'Partial payment received. Rs. ${(grandTotal * 0.5).toStringAsFixed(0)} pending.' : ''),
        ),
      );
      invoiceCount++;
    }
  }
  print('✓ Inserted $invoiceCount invoices');

  print('');
  print('═══════════════════════════════════════════════════════════');
  print('  DATABASE SEEDING COMPLETE');
  print('═══════════════════════════════════════════════════════════');
  print('  ✓ ${patientIds.length} Pakistani patients');
  print('  ✓ $appointmentCount appointments (past, today, future)');
  print('  ✓ $prescriptionCount prescriptions with medications');
  print('  ✓ $medicalRecordCount medical records (5 types)');
  print('  ✓ $invoiceCount invoices with varied items');
  print('═══════════════════════════════════════════════════════════');
}
