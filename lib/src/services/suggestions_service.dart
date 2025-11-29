/// Centralized suggestions for all input fields in the app
library;

/// Patient-related suggestions
abstract class PatientSuggestions {
  // Common first names (Indian)
  static const List<String> firstNames = [
    'Aarav', 'Aditya', 'Amit', 'Ananya', 'Arjun', 'Deepak', 'Divya', 'Gaurav',
    'Isha', 'Kiran', 'Krishna', 'Lakshmi', 'Manish', 'Neha', 'Pooja', 'Priya',
    'Rahul', 'Raj', 'Ravi', 'Rohit', 'Sandeep', 'Sanjay', 'Sapna', 'Shreya',
    'Sunil', 'Sunita', 'Vikram', 'Vinod',
  ];

  // Common last names (Indian)
  static const List<String> lastNames = [
    'Agarwal', 'Bansal', 'Choudhary', 'Gupta', 'Jain', 'Joshi', 'Kapoor',
    'Khan', 'Kumar', 'Malhotra', 'Mehta', 'Mishra', 'Nair', 'Patel', 'Rao',
    'Reddy', 'Saxena', 'Sharma', 'Singh', 'Srivastava', 'Thakur', 'Verma',
    'Yadav',
  ];

  // Blood groups
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // Gender options
  static const List<String> genders = [
    'Male', 'Female', 'Other',
  ];

  // Occupation suggestions
  static const List<String> occupations = [
    'Student', 'Homemaker', 'Business Owner', 'Self-Employed', 'Government Employee',
    'Private Sector Employee', 'IT Professional', 'Teacher', 'Doctor', 'Engineer',
    'Lawyer', 'Farmer', 'Retired', 'Unemployed', 'Daily Wage Worker',
  ];

  // Marital status
  static const List<String> maritalStatus = [
    'Single', 'Married', 'Divorced', 'Widowed', 'Separated',
  ];

  // Relationship to patient (for emergency contact)
  static const List<String> relationships = [
    'Spouse', 'Parent', 'Child', 'Sibling', 'Friend', 'Relative', 'Guardian',
  ];

  // Common allergies
  static const List<String> allergies = [
    'Penicillin', 'Sulfa drugs', 'Aspirin', 'Ibuprofen', 'Codeine',
    'Peanuts', 'Tree nuts', 'Milk/Dairy', 'Eggs', 'Wheat/Gluten',
    'Shellfish', 'Fish', 'Soy', 'Latex', 'Dust', 'Pollen', 'Pet dander',
    'Bee stings', 'None',
  ];

  // Common chronic conditions
  static const List<String> chronicConditions = [
    'Diabetes Type 1', 'Diabetes Type 2', 'Hypertension', 'Heart Disease',
    'Asthma', 'COPD', 'Thyroid Disorder', 'Arthritis', 'Kidney Disease',
    'Liver Disease', 'Cancer', 'Epilepsy', 'Depression', 'Anxiety',
    'Migraine', 'None',
  ];
}

/// Medical/Clinical suggestions
abstract class MedicalSuggestions {
  // Common diagnoses
  static const List<String> diagnoses = [
    'Acute Upper Respiratory Infection', 'Viral Fever', 'Acute Gastroenteritis',
    'Urinary Tract Infection', 'Migraine', 'Tension Headache', 'Hypertension',
    'Type 2 Diabetes Mellitus', 'Hyperlipidemia', 'Hypothyroidism',
    'Allergic Rhinitis', 'Bronchial Asthma', 'GERD', 'Peptic Ulcer Disease',
    'Lower Back Pain', 'Osteoarthritis', 'Rheumatoid Arthritis',
    'Anxiety Disorder', 'Depression', 'Insomnia', 'Anemia', 'Vitamin D Deficiency',
    'Skin Infection', 'Fungal Infection', 'Conjunctivitis',
  ];

  // Common symptoms
  static const List<String> symptoms = [
    'Fever', 'Cough', 'Cold', 'Sore throat', 'Headache', 'Body ache',
    'Fatigue', 'Weakness', 'Nausea', 'Vomiting', 'Diarrhea', 'Constipation',
    'Abdominal pain', 'Chest pain', 'Breathlessness', 'Dizziness',
    'Joint pain', 'Back pain', 'Rash', 'Itching', 'Swelling', 'Weight loss',
    'Weight gain', 'Loss of appetite', 'Difficulty sleeping', 'Anxiety',
  ];

  // Chief complaints
  static const List<String> chiefComplaints = [
    'Fever since 3 days', 'Cough and cold since 1 week', 'Headache',
    'Stomach pain', 'Body ache', 'Joint pain', 'Skin rash', 'Breathlessness',
    'Chest pain', 'Dizziness', 'Fatigue', 'Routine checkup', 'Follow-up visit',
    'Medication refill', 'Lab report review',
  ];

  // Vital signs suggestions
  static const List<String> temperatureCelsius = [
    '36.5', '37.0', '37.5', '38.0', '38.5', '39.0', '39.5', '40.0',
  ];

  static const List<String> temperatureFahrenheit = [
    '97.5', '98.0', '98.6', '99.0', '100.0', '101.0', '102.0', '103.0', '104.0',
  ];

  static const List<String> bloodPressure = [
    '90/60', '100/70', '110/70', '120/80', '130/85', '140/90', '150/95', '160/100',
  ];

  static const List<String> pulseRate = [
    '60', '65', '70', '72', '75', '80', '85', '90', '100', '110',
  ];

  static const List<String> respiratoryRate = [
    '12', '14', '16', '18', '20', '22', '24',
  ];

  static const List<String> oxygenSaturation = [
    '92', '94', '95', '96', '97', '98', '99', '100',
  ];

  static const List<String> weightKg = [
    '45', '50', '55', '60', '65', '70', '75', '80', '85', '90', '95', '100',
  ];

  static const List<String> heightCm = [
    '150', '155', '160', '165', '170', '175', '180', '185',
  ];
}

/// Prescription-related suggestions
abstract class PrescriptionSuggestions {
  // Common medications
  static const List<String> medications = [
    'Paracetamol 500mg', 'Paracetamol 650mg', 'Ibuprofen 400mg',
    'Azithromycin 500mg', 'Amoxicillin 500mg', 'Cefixime 200mg',
    'Metformin 500mg', 'Metformin 1000mg', 'Amlodipine 5mg', 'Amlodipine 10mg',
    'Losartan 50mg', 'Atorvastatin 10mg', 'Atorvastatin 20mg',
    'Omeprazole 20mg', 'Pantoprazole 40mg', 'Ranitidine 150mg',
    'Cetirizine 10mg', 'Montelukast 10mg', 'Salbutamol Inhaler',
    'Vitamin D3 60000IU', 'Vitamin B12', 'Multivitamin', 'Iron + Folic Acid',
    'Calcium + Vitamin D', 'Ondansetron 4mg', 'Domperidone 10mg',
  ];

  // Dosage options
  static const List<String> dosages = [
    '5mg', '10mg', '20mg', '25mg', '40mg', '50mg', '100mg', '200mg',
    '250mg', '500mg', '650mg', '1000mg', '1g', '2g',
    '5ml', '10ml', '15ml', '2.5ml',
  ];

  // Frequency options
  static const List<String> frequencies = [
    'Once daily', 'Twice daily', 'Three times daily', 'Four times daily',
    'Every 4 hours', 'Every 6 hours', 'Every 8 hours', 'Every 12 hours',
    'Once weekly', 'Twice weekly', 'As needed (SOS)', 'At bedtime',
    'Before meals', 'After meals', 'With meals', 'Empty stomach',
  ];

  // Duration options
  static const List<String> durations = [
    '3 days', '5 days', '7 days', '10 days', '14 days', '21 days',
    '1 month', '2 months', '3 months', '6 months', 'Ongoing', 'As directed',
  ];

  // Route of administration
  static const List<String> routes = [
    'Oral', 'Sublingual', 'Topical', 'Inhalation', 'Intramuscular',
    'Intravenous', 'Subcutaneous', 'Rectal', 'Eye drops', 'Ear drops',
    'Nasal spray',
  ];

  // Common instructions
  static const List<String> instructions = [
    'Take with food', 'Take on empty stomach', 'Take with plenty of water',
    'Do not crush or chew', 'Shake well before use', 'Store in cool place',
    'Keep refrigerated', 'Complete full course', 'Avoid alcohol',
    'May cause drowsiness', 'Avoid driving', 'Take at the same time daily',
    'Apply thin layer on affected area', 'Avoid sun exposure after applying',
  ];
}

/// Appointment-related suggestions
abstract class AppointmentSuggestions {
  // Visit reasons
  static const List<String> visitReasons = [
    'General Checkup', 'Follow-up Visit', 'New Complaint', 'Consultation',
    'Vaccination', 'Lab Report Review', 'Prescription Refill',
    'Pre-operative Assessment', 'Post-operative Follow-up',
    'Health Certificate', 'Insurance Medical', 'Annual Physical',
  ];

  // Appointment notes
  static const List<String> notes = [
    'First visit', 'Referred by Dr.', 'Urgent', 'Requires fasting',
    'Bring previous reports', 'Insurance patient', 'Corporate checkup',
    'Home visit required', 'Teleconsultation', 'VIP patient',
  ];

  // Duration in minutes
  static const List<String> durations = [
    '15', '30', '45', '60', '90', '120',
  ];
}

/// Billing-related suggestions
abstract class BillingSuggestions {
  // Service types
  static const List<String> serviceTypes = [
    'Consultation', 'Follow-up Consultation', 'New Patient Consultation',
    'Teleconsultation', 'Home Visit', 'Emergency Consultation',
    'Minor Procedure', 'Dressing', 'Injection', 'IV Drip',
    'ECG', 'Blood Pressure Check', 'Blood Sugar Check',
    'Health Certificate', 'Medical Report', 'Insurance Claim Processing',
  ];

  // Common service prices
  static const List<String> prices = [
    '100', '200', '300', '500', '700', '1000', '1500', '2000', '2500', '3000',
  ];

  // Payment methods
  static const List<String> paymentMethods = [
    'Cash', 'UPI', 'Card', 'Net Banking', 'Insurance', 'Credit',
  ];

  // Discount reasons
  static const List<String> discountReasons = [
    'Senior Citizen', 'Staff Discount', 'Loyalty Discount', 'Package Deal',
    'Insurance Adjustment', 'Charity Case', 'Promotional Offer',
  ];
}

/// Doctor profile suggestions
abstract class DoctorSuggestions {
  // Specializations
  static const List<String> specializations = [
    'General Physician', 'Family Medicine', 'Internal Medicine',
    'Pediatrics', 'Cardiology', 'Dermatology', 'Orthopedics', 'Gynecology',
    'Neurology', 'Psychiatry', 'ENT', 'Ophthalmology', 'Gastroenterology',
    'Pulmonology', 'Nephrology', 'Endocrinology', 'Oncology', 'Urology',
  ];

  // Qualifications
  static const List<String> qualifications = [
    'MBBS', 'MD', 'MS', 'DNB', 'DM', 'MCh', 'FRCP', 'MRCP', 'FCPS',
    'DCH', 'DTCD', 'DA', 'DOMS', 'DGO', 'PhD',
  ];

  // Clinic timings
  static const List<String> clinicTimings = [
    '9:00 AM - 1:00 PM', '2:00 PM - 6:00 PM', '6:00 PM - 9:00 PM',
    '9:00 AM - 5:00 PM', '10:00 AM - 2:00 PM', '4:00 PM - 8:00 PM',
  ];
}

/// Settings and preferences suggestions
abstract class SettingsSuggestions {
  // Languages
  static const List<String> languages = [
    'English', 'Hindi', 'Marathi', 'Gujarati', 'Tamil', 'Telugu',
    'Kannada', 'Malayalam', 'Bengali', 'Punjabi', 'Urdu',
  ];

  // Currency
  static const List<String> currencies = [
    '₹ (INR)', '\$ (USD)', '€ (EUR)', '£ (GBP)',
  ];

  // Date formats
  static const List<String> dateFormats = [
    'DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD', 'DD-MMM-YYYY',
  ];

  // Time formats
  static const List<String> timeFormats = [
    '12-hour (AM/PM)', '24-hour',
  ];
}

/// Medical Record specific suggestions
abstract class MedicalRecordSuggestions {
  // Lab test names
  static const List<String> labTestNames = [
    'Complete Blood Count (CBC)', 'Hemoglobin (Hb)', 'Platelet Count',
    'Blood Sugar Fasting (BSF)', 'Blood Sugar Random (BSR)', 'Blood Sugar PP',
    'HbA1c', 'Lipid Profile', 'Total Cholesterol', 'HDL', 'LDL', 'Triglycerides',
    'Liver Function Test (LFT)', 'SGOT/AST', 'SGPT/ALT', 'Bilirubin',
    'Kidney Function Test (KFT)', 'Serum Creatinine', 'Blood Urea', 'BUN',
    'Thyroid Profile (T3, T4, TSH)', 'TSH', 'Free T3', 'Free T4',
    'Urine Routine & Microscopy', 'Urine Culture', 'Stool Examination',
    'Serum Electrolytes', 'Sodium', 'Potassium', 'Calcium', 'Magnesium',
    'Vitamin D (25-OH)', 'Vitamin B12', 'Iron Studies', 'Ferritin',
    'CRP (C-Reactive Protein)', 'ESR', 'Procalcitonin',
    'HIV Test', 'HBsAg', 'Anti-HCV', 'VDRL', 'Dengue NS1', 'Malaria Antigen',
    'Covid-19 RT-PCR', 'Covid-19 Antigen',
  ];

  // Lab result reference ranges
  static const List<String> referenceRanges = [
    'Normal', 'Within normal limits', 'Borderline high', 'High', 'Low',
    'Hb: 12-16 g/dL (F), 14-18 g/dL (M)',
    'BSF: 70-100 mg/dL', 'BSR: <140 mg/dL', 'HbA1c: <5.7%',
    'Total Cholesterol: <200 mg/dL', 'LDL: <100 mg/dL', 'HDL: >40 mg/dL',
    'Triglycerides: <150 mg/dL', 'TSH: 0.4-4.0 mIU/L',
    'Creatinine: 0.7-1.3 mg/dL', 'Urea: 15-40 mg/dL',
    'Vitamin D: 30-100 ng/mL', 'Vitamin B12: 200-900 pg/mL',
  ];

  // Imaging types
  static const List<String> imagingTypes = [
    'X-Ray Chest PA View', 'X-Ray Chest AP View', 'X-Ray Abdomen', 
    'X-Ray Spine - Cervical', 'X-Ray Spine - Lumbar', 'X-Ray Pelvis',
    'X-Ray Knee', 'X-Ray Shoulder', 'X-Ray Hand', 'X-Ray Foot',
    'USG Abdomen', 'USG Pelvis', 'USG KUB', 'USG Thyroid', 'USG Breast',
    'USG Obstetric', 'USG Doppler', 'Echo (2D Echocardiography)',
    'CT Scan - Head', 'CT Scan - Chest', 'CT Scan - Abdomen', 'CT Scan - Spine',
    'MRI Brain', 'MRI Spine', 'MRI Knee', 'MRI Shoulder', 'MRI Abdomen',
    'PET Scan', 'Bone Densitometry (DEXA)', 'Mammography',
  ];

  // Imaging findings
  static const List<String> imagingFindings = [
    'Normal study', 'No significant abnormality', 'Unremarkable',
    'Mild degenerative changes', 'Moderate degenerative changes',
    'Disc bulge', 'Disc herniation', 'Spinal stenosis',
    'Consolidation', 'Infiltrates', 'Pleural effusion', 'Cardiomegaly',
    'Fatty liver Grade I', 'Fatty liver Grade II', 'Hepatomegaly',
    'Renal calculi', 'Cholelithiasis', 'Splenomegaly',
    'Fracture noted', 'No fracture seen', 'Soft tissue swelling',
    'Osteoporosis', 'Osteopenia', 'Joint space narrowing',
  ];

  // Procedure names
  static const List<String> procedureNames = [
    'ECG (12 Lead)', 'Holter Monitoring', 'TMT / Stress Test',
    'Spirometry / PFT', 'Peak Flow Measurement',
    'Wound Dressing', 'Suture Removal', 'Abscess Drainage',
    'Injection - IM', 'Injection - IV', 'Injection - Subcutaneous',
    'IV Cannulation', 'IV Fluid Administration', 'Blood Transfusion',
    'Nebulization', 'Oxygen Therapy', 'Catheterization',
    'NG Tube Insertion', 'Ryles Tube Feeding',
    'Minor Surgery', 'Excision Biopsy', 'Incision & Drainage',
    'Joint Aspiration', 'Intra-articular Injection',
    'Skin Biopsy', 'FNAC', 'Pap Smear',
    'Ear Syringing', 'Foreign Body Removal',
  ];

  // Procedure findings/notes
  static const List<String> procedureNotes = [
    'Procedure completed successfully', 'No complications',
    'Patient tolerated procedure well', 'Sterile technique maintained',
    'Local anesthesia administered', 'Hemostasis achieved',
    'Wound cleaned and dressed', 'Sutures placed',
    'Sent for histopathology', 'Follow-up advised',
    'Post-procedure vitals stable', 'Instructions given to patient',
  ];

  // Follow-up visit notes
  static const List<String> followUpNotes = [
    'Patient showing improvement', 'Symptoms resolved',
    'Symptoms persisting', 'Condition stable', 'Condition worsening',
    'Medication adjusted', 'Continue current treatment',
    'Lab tests reviewed - normal', 'Lab tests reviewed - abnormal',
    'Referred to specialist', 'Admitted for further management',
    'Discharged with advice', 'Next follow-up in 1 week',
    'Next follow-up in 2 weeks', 'Next follow-up in 1 month',
    'PRN basis - come if needed',
  ];

  // MSE - Appearance suggestions
  static const List<String> mseAppearance = [
    'Well groomed', 'Appropriately dressed', 'Disheveled', 'Unkempt',
    'Good hygiene', 'Poor hygiene', 'Age appropriate', 'Looks older than stated age',
    'Thin built', 'Average built', 'Obese', 'Cachectic',
    'Good eye contact', 'Poor eye contact', 'Avoiding eye contact',
  ];

  // MSE - Behavior suggestions
  static const List<String> mseBehavior = [
    'Cooperative', 'Uncooperative', 'Guarded', 'Suspicious',
    'Calm', 'Agitated', 'Restless', 'Psychomotor retardation',
    'Appropriate', 'Inappropriate', 'Withdrawn', 'Aggressive',
    'Good rapport', 'Difficult to establish rapport',
  ];

  // MSE - Speech suggestions
  static const List<String> mseSpeech = [
    'Normal rate and tone', 'Soft spoken', 'Loud', 'Pressured speech',
    'Slow', 'Hesitant', 'Spontaneous', 'Relevant and coherent',
    'Irrelevant', 'Incoherent', 'Poverty of speech', 'Mutism',
    'Normal prosody', 'Monotonous',
  ];

  // MSE - Mood suggestions
  static const List<String> mseMood = [
    'Euthymic', 'Depressed', 'Sad', 'Anxious', 'Irritable', 'Angry',
    'Euphoric', 'Elated', 'Labile', 'Dysphoric', 'Fearful', 'Hopeless',
    'Patient reports feeling fine', 'Patient reports low mood',
  ];

  // MSE - Affect suggestions
  static const List<String> mseAffect = [
    'Appropriate', 'Inappropriate', 'Congruent', 'Incongruent',
    'Full range', 'Restricted', 'Blunted', 'Flat', 'Labile',
    'Reactive', 'Non-reactive', 'Anxious', 'Tearful',
  ];

  // MSE - Thought Content suggestions
  static const List<String> mseThoughtContent = [
    'No abnormality detected', 'No delusions', 'No suicidal ideation',
    'Delusions of persecution', 'Delusions of reference', 'Delusions of grandeur',
    'Ideas of reference', 'Obsessive thoughts', 'Phobias present',
    'Suicidal ideation present', 'Homicidal ideation present',
    'Preoccupied with somatic complaints', 'Guilt feelings',
  ];

  // MSE - Thought Process suggestions
  static const List<String> mseThoughtProcess = [
    'Goal directed', 'Coherent', 'Logical', 'Relevant',
    'Circumstantial', 'Tangential', 'Loosening of associations',
    'Flight of ideas', 'Thought blocking', 'Perseveration',
    'Poverty of thought', 'Derailment',
  ];

  // MSE - Perception suggestions
  static const List<String> msePerception = [
    'No abnormality detected', 'No hallucinations',
    'Auditory hallucinations present', 'Visual hallucinations present',
    'Tactile hallucinations', 'Olfactory hallucinations',
    'Illusions reported', 'Depersonalization', 'Derealization',
  ];

  // MSE - Cognition suggestions
  static const List<String> mseCognition = [
    'Alert and oriented x3', 'Oriented to time, place, person',
    'Disoriented to time', 'Disoriented to place', 'Disoriented to person',
    'Attention intact', 'Concentration impaired', 'Memory intact',
    'Recent memory impaired', 'Remote memory intact',
    'MMSE score: __/30', 'Cognitive impairment noted',
  ];

  // MSE - Insight suggestions
  static const List<String> mseInsight = [
    'Good insight', 'Partial insight', 'Poor insight', 'No insight',
    'Aware of illness', 'Denies illness', 'Accepts need for treatment',
    'Reluctant to accept treatment',
  ];

  // MSE - Judgment suggestions
  static const List<String> mseJudgment = [
    'Intact', 'Impaired', 'Good social judgment', 'Poor social judgment',
    'Appropriate decision making', 'Impaired decision making',
    'Test judgment - appropriate response', 'Test judgment - inappropriate response',
  ];

  // Convenience aliases for MSE fields (shorter names)
  static const List<String> appearance = mseAppearance;
  static const List<String> behavior = mseBehavior;
  static const List<String> speech = mseSpeech;
  static const List<String> mood = mseMood;
  static const List<String> affect = mseAffect;
  static const List<String> thoughtContent = mseThoughtContent;
  static const List<String> thoughtProcess = mseThoughtProcess;
  static const List<String> perception = msePerception;
  static const List<String> cognition = mseCognition;
  static const List<String> insight = mseInsight;
  static const List<String> judgment = mseJudgment;
}

/// Comprehensive Psychiatric Assessment suggestions
abstract class PsychiatricSuggestions {
  // Sleep patterns
  static const List<String> sleep = [
    'Normal', 'Insomnia', 'Initial insomnia', 'Middle insomnia', 
    'Terminal insomnia', 'Hypersomnia', 'Disturbed sleep', 
    'Early morning awakening', 'Non-refreshing sleep', 'Nightmares',
    'Sleep walking', 'Night terrors', 'Reversed sleep cycle',
  ];

  // Appetite patterns
  static const List<String> appetite = [
    'Normal', 'Decreased', 'Increased', 'Loss of appetite', 
    'Binge eating', 'Anorexia', 'Craving for sweets', 
    'Weight loss', 'Weight gain', 'Unchanged',
  ];

  // Anxiety and Fear
  static const List<String> anxietyFear = [
    'Nil', 'Present', 'Generalized anxiety', 'Panic attacks',
    'Social anxiety', 'Performance anxiety', 'Health anxiety',
    'Fear of death', 'Fear of crowds', 'Fear of closed spaces',
    'Fear of heights', 'Fear of specific objects', 'Phobias',
    'Free floating anxiety', 'Anticipatory anxiety',
  ];

  // Epigastric symptoms
  static const List<String> epigastric = [
    'Nil', 'Present', 'Butterflies in stomach', 'Burning sensation',
    'Nausea', 'Vomiting', 'Churning sensation', 'Loss of appetite',
    'Acid reflux', 'Globus sensation',
  ];

  // Libido
  static const List<String> libido = [
    'Normal', 'Decreased', 'Increased', 'Absent', 
    'Erectile dysfunction', 'Anorgasmia', 'Premature ejaculation',
    'Delayed ejaculation', 'Dyspareunia', 'Not applicable',
  ];

  // OCD symptoms
  static const List<String> ocdSymptoms = [
    'Nil', 'Present', 'Contamination obsessions', 'Washing compulsions',
    'Checking compulsions', 'Ordering/symmetry', 'Hoarding',
    'Intrusive thoughts', 'Counting rituals', 'Religious obsessions',
    'Harm obsessions', 'Sexual obsessions', 'Pure O',
    'Doubt and incompleteness', 'Mental rituals',
  ];

  // PTSD symptoms
  static const List<String> ptsd = [
    'Nil', 'Present', 'Flashbacks', 'Nightmares', 'Intrusive memories',
    'Avoidance behavior', 'Emotional numbness', 'Hypervigilance',
    'Exaggerated startle response', 'Irritability', 'Difficulty concentrating',
    'Sleep disturbances', 'Negative mood', 'Dissociative symptoms',
  ];

  // Past medical history
  static const List<String> pastMedical = [
    'Nil', 'Diabetes Mellitus', 'Hypertension', 'DM + HTN',
    'Thyroid disorder', 'Cardiac disease', 'Respiratory illness',
    'Renal disease', 'Liver disease', 'Neurological disorder',
    'Autoimmune disease', 'Infectious disease',
  ];

  // Epilepsy and others
  static const List<String> epilepsyOthers = [
    'Nil', 'Epilepsy - GTCS', 'Epilepsy - Focal', 'Epilepsy - Absence',
    'Febrile seizures', 'Status epilepticus', 'Controlled on medication',
    'Uncontrolled', 'Last seizure date:', 'Pseudo-seizures',
  ];

  // Past surgical history
  static const List<String> pastSurgical = [
    'Nil', 'Appendectomy', 'Cholecystectomy', 'Hernia repair',
    'C-section', 'Hysterectomy', 'Thyroidectomy', 'Orthopedic surgery',
    'Cardiac surgery', 'Neurosurgery', 'Eye surgery',
  ];

  // Past psychiatric history
  static const List<String> pastPsychiatric = [
    'Nil', 'First episode', 'Recurrent episodes', 'Previous depression',
    'Previous mania', 'Previous psychosis', 'Previous anxiety disorder',
    'Previous OCD', 'Previous substance abuse', 'Previous suicide attempt',
    'Previous hospitalization', 'Treatment resistant',
  ];

  // Past ECT history
  static const List<String> pastEct = [
    'Nil', 'Yes - number of sessions:', 'Modified ECT', 'Unmodified ECT',
    'Good response', 'Partial response', 'No response',
    'Side effects reported', 'Memory impairment reported',
  ];

  // Family history
  static const List<String> familyHistory = [
    'Nil', 'Depression in family', 'Bipolar disorder in family',
    'Schizophrenia in family', 'Anxiety disorder in family',
    'OCD in family', 'Suicide in family', 'Substance abuse in family',
    'Dementia in family', 'Epilepsy in family', 'Mental retardation',
    'First degree relative', 'Second degree relative',
  ];

  // Substance abuse
  static const List<String> substanceAbuse = [
    'Nil', 'Tobacco - smoking', 'Tobacco - chewing', 'Alcohol - social',
    'Alcohol - dependent', 'Cannabis', 'Opioids', 'Benzodiazepines',
    'Inhalants', 'Stimulants', 'Hallucinogens', 'Multiple substances',
    'In remission', 'Currently using', 'Quantity/frequency:',
  ];

  // Head injury
  static const List<String> headInjury = [
    'Nil', 'Present', 'RTA', 'Fall', 'Assault', 'Sports injury',
    'Loss of consciousness', 'No LOC', 'Duration of LOC:',
    'Post-traumatic amnesia', 'Seizures post-injury', 'Subdural hematoma',
    'Concussion', 'Skull fracture',
  ];

  // Forensic history
  static const List<String> forensicHistory = [
    'Nil', 'Present', 'Arrested', 'Imprisoned', 'Pending case',
    'Acquitted', 'Violent offense', 'Non-violent offense',
    'Sexual offense', 'Property crime', 'Under trial',
  ];

  // Developmental milestones
  static const List<String> developmentalMilestones = [
    'Normal', 'Delayed', 'Speech delay', 'Motor delay',
    'Cognitive delay', 'Social delay', 'Learning disability',
    'Mental retardation - mild', 'Mental retardation - moderate',
    'Mental retardation - severe', 'Autism spectrum', 'ADHD',
  ];

  // Premorbid personality
  static const List<String> premorbidPersonality = [
    'Well adjusted', 'Introvert', 'Extrovert', 'Anxious personality',
    'Obsessive traits', 'Schizoid traits', 'Paranoid traits',
    'Histrionic traits', 'Dependent traits', 'Avoidant traits',
    'Antisocial traits', 'Borderline traits', 'Narcissistic traits',
  ];

  // Trauma history
  static const List<String> trauma = [
    'Nil', 'Physical abuse', 'Emotional abuse', 'Sexual abuse',
    'Neglect', 'Domestic violence', 'Accident', 'Natural disaster',
    'War/conflict', 'Witness to violence', 'Loss of loved one',
    'Childhood trauma', 'Adult trauma', 'Complex trauma',
  ];

  // Child abuse
  static const List<String> childAbuse = [
    'Nil', 'Physical abuse', 'Emotional abuse', 'Sexual abuse',
    'Neglect', 'Witness to domestic violence', 'Bullying',
    'School related trauma', 'Parental separation',
  ];

  // Deliberate self-harm
  static const List<String> dsh = [
    'Nil', 'Present', 'Cutting', 'Burning', 'Hitting', 'Hair pulling',
    'Skin picking', 'Head banging', 'Overdose', 'Multiple methods',
    'Recent episode', 'Past history', 'Chronic pattern',
  ];

  // Suicidal symptoms
  static const List<String> suicidal = [
    'Nil', 'Present', 'Passive ideation', 'Active ideation', 
    'Plan present', 'Intent present', 'Past attempt', 'Multiple attempts',
    'Hopelessness', 'Helplessness', 'Worthlessness', 
    'Death wishes', 'Command hallucinations for self-harm',
    'High risk', 'Moderate risk', 'Low risk',
  ];

  // Homicidal symptoms
  static const List<String> homicide = [
    'Nil', 'Present', 'Ideation only', 'Plan present', 'Intent present',
    'Specific target', 'Non-specific', 'Past violence',
    'Command hallucinations for violence', 'Threat made',
  ];

  // Drug allergy
  static const List<String> drugAllergy = [
    'Nil', 'Penicillin', 'Sulfa drugs', 'Aspirin', 'NSAIDs',
    'Antipsychotics', 'Antidepressants', 'Mood stabilizers',
    'Benzodiazepines', 'Contrast dye', 'Multiple drug allergies',
    'Rash', 'Anaphylaxis', 'Stevens-Johnson syndrome',
  ];

  // Attention
  static const List<String> attention = [
    'Intact', 'Easily distractible', 'Poor sustained attention',
    'Vigilant', 'Hypervigilant', 'Impaired', 'Unable to assess',
    'Selective attention impaired', 'Divided attention impaired',
  ];

  // Concentration
  static const List<String> concentration = [
    'Good', 'Impaired', 'Poor', 'Fair', 'Serial 7s intact',
    'Serial 7s impaired', 'Fluctuating', 'Unable to assess',
  ];

  // Memory - Recent
  static const List<String> memoryRecent = [
    'Intact', 'Impaired', 'Partial impairment', 'Unable to assess',
    'Recall 3/3 objects after 5 min', 'Recall 2/3 objects',
    'Recall 1/3 objects', 'Recall 0/3 objects',
  ];

  // Memory - Remote
  static const List<String> memoryRemote = [
    'Intact', 'Impaired', 'Partial impairment', 'Unable to assess',
    'Personal history recalled', 'Major events recalled',
    'Gaps in memory', 'Confabulation present',
  ];

  // Memory - Immediate
  static const List<String> memoryImmediate = [
    'Intact', 'Impaired', 'Digit span 7±2', 'Digit span reduced',
    'Registration intact', 'Registration impaired', 'Unable to assess',
  ];

  // Abstract thinking
  static const List<String> abstractThinking = [
    'Intact', 'Impaired', 'Concrete thinking', 'Proverb interpretation - appropriate',
    'Proverb interpretation - concrete', 'Similarities - appropriate',
    'Similarities - concrete', 'Unable to assess',
  ];

  // HOPI phrases
  static const List<String> hopiPhrases = [
    'Gradual onset', 'Sudden onset', 'Insidious onset',
    'Precipitating factor:', 'Progressive course', 'Static course',
    'Fluctuating course', 'Episodic course', 'Continuous symptoms',
    'Waxing and waning', 'Duration of illness:', 'First episode',
    'Recurrent episode', 'Number of previous episodes:',
    'Longest symptom-free interval:', 'Current episode duration:',
  ];

  // Treatment suggestions
  static const List<String> treatments = [
    'Tab. Escitalopram', 'Tab. Sertraline', 'Tab. Fluoxetine',
    'Tab. Paroxetine', 'Tab. Venlafaxine', 'Tab. Duloxetine',
    'Tab. Mirtazapine', 'Tab. Amitriptyline', 'Tab. Clomipramine',
    'Tab. Risperidone', 'Tab. Olanzapine', 'Tab. Quetiapine',
    'Tab. Aripiprazole', 'Tab. Haloperidol', 'Tab. Clozapine',
    'Tab. Lithium', 'Tab. Valproate', 'Tab. Carbamazepine',
    'Tab. Lamotrigine', 'Tab. Clonazepam', 'Tab. Lorazepam',
    'Tab. Alprazolam', 'Tab. Diazepam', 'Tab. Trihexyphenidyl',
    'Inj. Haloperidol', 'Inj. Lorazepam', 'Inj. Fluphenazine Decanoate',
    'Psychotherapy', 'CBT', 'IPT', 'Family therapy', 'ECT advised',
  ];

  // Follow-up suggestions
  static const List<String> followUp = [
    'Review after 2 weeks', 'Review after 1 month', 'Review after 3 months',
    'SOS if required', 'Bring all previous records', 'Lab investigations advised',
    'Continue same treatment', 'Dose adjustment done',
    'Side effects monitoring', 'Compliance reinforced',
  ];
}
