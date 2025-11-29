import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;

import '../db/doctor_db.dart';
import 'logger_service.dart';

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
  log.i('SEED', 'Seeding database with comprehensive sample data...');
  final random = Random();

  // Pakistani patient data - 75 patients with diverse conditions
  final patientData = [
    // Original 30 patients
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
    
    // Additional 45 patients for more comprehensive data
    {'firstName': 'Tariq', 'lastName': 'Jameel', 'dob': DateTime(1960, 2, 10), 'phone': '0300-1111111', 'email': 'tariq.jameel@gmail.com', 'address': 'House 12, Street 5, Gulshan, Karachi', 'history': 'Chronic Heart Failure, Atrial Fibrillation', 'tags': 'cardiac,chronic,elderly', 'risk': 5},
    {'firstName': 'Aisha', 'lastName': 'Farooq', 'dob': DateTime(1988, 4, 5), 'phone': '0321-1111112', 'email': 'aisha.farooq@yahoo.com', 'address': '45 F-8/1, Islamabad', 'history': 'Lupus, Chronic Fatigue', 'tags': 'rheumatology,autoimmune', 'risk': 4},
    {'firstName': 'Rizwan', 'lastName': 'Ahmed', 'dob': DateTime(1975, 8, 20), 'phone': '0333-1111113', 'email': 'rizwan.ahmed@hotmail.com', 'address': 'Plot 34, DHA Phase 2, Lahore', 'history': 'Chronic Pancreatitis', 'tags': 'gastro,chronic', 'risk': 4},
    {'firstName': 'Kiran', 'lastName': 'Baloch', 'dob': DateTime(1992, 6, 15), 'phone': '0345-1111114', 'email': 'kiran.baloch@gmail.com', 'address': '78 University Road, Quetta', 'history': 'Polycystic Kidney Disease', 'tags': 'nephrology,genetic', 'risk': 3},
    {'firstName': 'Farhan', 'lastName': 'Saeed', 'dob': DateTime(1985, 11, 30), 'phone': '0302-1111115', 'email': 'farhan.saeed@outlook.com', 'address': '23 Canal Road, Multan', 'history': 'Multiple Sclerosis', 'tags': 'neurology,chronic', 'risk': 5},
    {'firstName': 'Saba', 'lastName': 'Qamar', 'dob': DateTime(1990, 3, 8), 'phone': '0311-1111116', 'email': 'saba.qamar@yahoo.com', 'address': '56 Johar Town Block B, Lahore', 'history': 'Endometriosis, Infertility', 'tags': 'gynecology', 'risk': 2},
    {'firstName': 'Omar', 'lastName': 'Sharif', 'dob': DateTime(1958, 12, 25), 'phone': '0322-1111117', 'email': 'omar.sharif@gmail.com', 'address': 'House 89, G-11/2, Islamabad', 'history': 'Parkinson\'s Disease, Dementia', 'tags': 'neurology,elderly,chronic', 'risk': 5},
    {'firstName': 'Mahira', 'lastName': 'Khan', 'dob': DateTime(1984, 12, 21), 'phone': '0334-1111118', 'email': 'mahira.khan@hotmail.com', 'address': '12 Defence Phase 7, Karachi', 'history': 'Chronic Migraine, Vertigo', 'tags': 'neurology', 'risk': 2},
    {'firstName': 'Hamza', 'lastName': 'Ali', 'dob': DateTime(2010, 5, 18), 'phone': '0301-1111119', 'email': 'hamza.parent@gmail.com', 'address': '34 Bahria Town Phase 4, Rawalpindi', 'history': 'Childhood Asthma, Allergies', 'tags': 'pediatric,respiratory', 'risk': 2},
    {'firstName': 'Zara', 'lastName': 'Noor', 'dob': DateTime(2015, 9, 10), 'phone': '0312-1111120', 'email': 'zara.parent@yahoo.com', 'address': '67 Model Town, Gujranwala', 'history': 'ADHD, Learning Disability', 'tags': 'pediatric,psychiatric', 'risk': 2},
    {'firstName': 'Atif', 'lastName': 'Aslam', 'dob': DateTime(1983, 3, 12), 'phone': '0323-1111121', 'email': 'atif.aslam@outlook.com', 'address': '90 Gulberg V, Lahore', 'history': 'Vocal Cord Nodules, GERD', 'tags': 'ent,gastro', 'risk': 1},
    {'firstName': 'Humaima', 'lastName': 'Malik', 'dob': DateTime(1987, 11, 18), 'phone': '0335-1111122', 'email': 'humaima.malik@gmail.com', 'address': '23 Clifton Block 2, Karachi', 'history': 'Psoriasis, Psoriatic Arthritis', 'tags': 'dermatology,rheumatology', 'risk': 3},
    {'firstName': 'Shaan', 'lastName': 'Shahid', 'dob': DateTime(1971, 4, 27), 'phone': '0303-1111123', 'email': 'shaan.shahid@yahoo.com', 'address': '56 F-6/1, Islamabad', 'history': 'Type 1 Diabetes, Diabetic Retinopathy', 'tags': 'endocrine,ophthalmology,chronic', 'risk': 4},
    {'firstName': 'Urwa', 'lastName': 'Hocane', 'dob': DateTime(1991, 7, 2), 'phone': '0313-1111124', 'email': 'urwa.hocane@hotmail.com', 'address': '78 DHA Phase 5, Lahore', 'history': 'Celiac Disease, IBS', 'tags': 'gastro,autoimmune', 'risk': 2},
    {'firstName': 'Fawad', 'lastName': 'Khan', 'dob': DateTime(1981, 11, 29), 'phone': '0324-1111125', 'email': 'fawad.khan@gmail.com', 'address': '12 E-7, Islamabad', 'history': 'Ankylosing Spondylitis', 'tags': 'rheumatology,chronic', 'risk': 3},
    {'firstName': 'Sanam', 'lastName': 'Saeed', 'dob': DateTime(1985, 2, 2), 'phone': '0336-1111126', 'email': 'sanam.saeed@outlook.com', 'address': '34 Gulshan Block 13, Karachi', 'history': 'Graves\' Disease, Osteoporosis', 'tags': 'endocrine,rheumatology', 'risk': 3},
    {'firstName': 'Ahad', 'lastName': 'Raza', 'dob': DateTime(1993, 9, 24), 'phone': '0304-1111127', 'email': 'ahad.raza@yahoo.com', 'address': '67 Bahria Orchard, Lahore', 'history': 'Crohn\'s Disease', 'tags': 'gastro,autoimmune,chronic', 'risk': 4},
    {'firstName': 'Mawra', 'lastName': 'Hocane', 'dob': DateTime(1992, 9, 28), 'phone': '0314-1111128', 'email': 'mawra.hocane@gmail.com', 'address': '89 Garden Town, Lahore', 'history': 'Generalized Anxiety, Panic Disorder', 'tags': 'psychiatric', 'risk': 3},
    {'firstName': 'Danish', 'lastName': 'Taimoor', 'dob': DateTime(1983, 2, 16), 'phone': '0325-1111129', 'email': 'danish.taimoor@hotmail.com', 'address': '23 Askari 14, Rawalpindi', 'history': 'Chronic Back Pain, Sciatica', 'tags': 'orthopedic,chronic', 'risk': 2},
    {'firstName': 'Ayeza', 'lastName': 'Khan', 'dob': DateTime(1991, 1, 15), 'phone': '0337-1111130', 'email': 'ayeza.khan@outlook.com', 'address': '56 DHA Phase 8, Karachi', 'history': 'Post-partum Depression, Thyroid', 'tags': 'psychiatric,endocrine', 'risk': 3},
    {'firstName': 'Humayun', 'lastName': 'Saeed', 'dob': DateTime(1971, 7, 27), 'phone': '0305-1111131', 'email': 'humayun.saeed@gmail.com', 'address': '78 F-10/3, Islamabad', 'history': 'Coronary Artery Disease, Stent', 'tags': 'cardiac,chronic', 'risk': 4},
    {'firstName': 'Syra', 'lastName': 'Yousuf', 'dob': DateTime(1988, 4, 20), 'phone': '0315-1111132', 'email': 'syra.yousuf@yahoo.com', 'address': '12 Clifton Block 8, Karachi', 'history': 'Hashimoto\'s Thyroiditis', 'tags': 'endocrine,autoimmune', 'risk': 2},
    {'firstName': 'Osman', 'lastName': 'Khalid', 'dob': DateTime(1978, 10, 5), 'phone': '0326-1111133', 'email': 'osman.khalid@hotmail.com', 'address': '34 Model Town, Sialkot', 'history': 'Gout, Metabolic Syndrome', 'tags': 'rheumatology,metabolic', 'risk': 3},
    {'firstName': 'Sadia', 'lastName': 'Imam', 'dob': DateTime(1979, 2, 18), 'phone': '0338-1111134', 'email': 'sadia.imam@gmail.com', 'address': '67 Gulberg III, Lahore', 'history': 'Breast Cancer Survivor, Lymphedema', 'tags': 'oncology,follow-up', 'risk': 3},
    {'firstName': 'Shan', 'lastName': 'Masood', 'dob': DateTime(1989, 10, 14), 'phone': '0306-1111135', 'email': 'shan.masood@outlook.com', 'address': '89 DHA City, Karachi', 'history': 'Sports Injury, ACL Reconstruction', 'tags': 'orthopedic,sports', 'risk': 2},
    {'firstName': 'Hareem', 'lastName': 'Farooq', 'dob': DateTime(1993, 9, 26), 'phone': '0316-1111136', 'email': 'hareem.farooq@yahoo.com', 'address': '23 E-11/4, Islamabad', 'history': 'Anemia, Vitamin B12 Deficiency', 'tags': 'hematology,general', 'risk': 1},
    {'firstName': 'Wahab', 'lastName': 'Riaz', 'dob': DateTime(1985, 6, 28), 'phone': '0327-1111137', 'email': 'wahab.riaz@gmail.com', 'address': '56 Bahria Town Phase 7, Rawalpindi', 'history': 'Shoulder Injury, Rotator Cuff Tear', 'tags': 'orthopedic,sports', 'risk': 2},
    {'firstName': 'Kinza', 'lastName': 'Hashmi', 'dob': DateTime(1996, 1, 7), 'phone': '0339-1111138', 'email': 'kinza.hashmi@hotmail.com', 'address': '78 Johar Town Block E, Lahore', 'history': 'Eating Disorder, Body Dysmorphia', 'tags': 'psychiatric', 'risk': 4},
    {'firstName': 'Shoaib', 'lastName': 'Akhtar', 'dob': DateTime(1975, 8, 13), 'phone': '0307-1111139', 'email': 'shoaib.akhtar@outlook.com', 'address': '12 Model Town, Rawalpindi', 'history': 'Chronic Tendinitis, Lower Back Pain', 'tags': 'orthopedic,chronic', 'risk': 3},
    {'firstName': 'Yumna', 'lastName': 'Zaidi', 'dob': DateTime(1989, 7, 30), 'phone': '0317-1111140', 'email': 'yumna.zaidi@gmail.com', 'address': '34 Cantt Area, Lahore', 'history': 'Chronic Sinusitis, Nasal Polyps', 'tags': 'ent', 'risk': 1},
    {'firstName': 'Wasim', 'lastName': 'Akram', 'dob': DateTime(1966, 6, 3), 'phone': '0328-1111141', 'email': 'wasim.akram@yahoo.com', 'address': '67 Defence Phase 4, Karachi', 'history': 'Diabetes Type 2, Neuropathy, Kidney Disease Stage 2', 'tags': 'endocrine,nephrology,chronic,elderly', 'risk': 5},
    {'firstName': 'Zarnish', 'lastName': 'Khan', 'dob': DateTime(1994, 5, 10), 'phone': '0300-1111142', 'email': 'zarnish.khan@hotmail.com', 'address': '89 G-9/1, Islamabad', 'history': 'Chronic Urticaria, Allergies', 'tags': 'dermatology,immunology', 'risk': 2},
    {'firstName': 'Azhar', 'lastName': 'Ali', 'dob': DateTime(1985, 2, 19), 'phone': '0310-1111143', 'email': 'azhar.ali@gmail.com', 'address': '23 Gulberg II, Lahore', 'history': 'Tension Headaches, Neck Pain', 'tags': 'neurology', 'risk': 1},
    {'firstName': 'Naimal', 'lastName': 'Khawar', 'dob': DateTime(1993, 11, 18), 'phone': '0329-1111144', 'email': 'naimal.khawar@outlook.com', 'address': '56 F-7/3, Islamabad', 'history': 'Anxiety, Chronic Stress', 'tags': 'psychiatric', 'risk': 2},
    {'firstName': 'Shadab', 'lastName': 'Khan', 'dob': DateTime(1998, 10, 4), 'phone': '0301-1111145', 'email': 'shadab.khan@yahoo.com', 'address': '78 Bahria Town Phase 8, Rawalpindi', 'history': 'Sports Asthma, Exercise-Induced Bronchospasm', 'tags': 'respiratory,sports', 'risk': 2},
    {'firstName': 'Hania', 'lastName': 'Amir', 'dob': DateTime(1997, 2, 12), 'phone': '0320-1111146', 'email': 'hania.amir@gmail.com', 'address': '12 DHA Phase 6, Lahore', 'history': 'Acne, Hirsutism, PCOS', 'tags': 'dermatology,endocrine', 'risk': 2},
    {'firstName': 'Hasan', 'lastName': 'Ali', 'dob': DateTime(1994, 2, 2), 'phone': '0311-1111147', 'email': 'hasan.ali@hotmail.com', 'address': '34 Askari 11, Lahore', 'history': 'Shoulder Impingement', 'tags': 'orthopedic,sports', 'risk': 1},
    {'firstName': 'Anoushay', 'lastName': 'Abbasi', 'dob': DateTime(1991, 10, 11), 'phone': '0330-1111148', 'email': 'anoushay.abbasi@outlook.com', 'address': '67 Clifton Block 5, Karachi', 'history': 'Irritable Bowel Syndrome, Food Intolerances', 'tags': 'gastro', 'risk': 2},
    {'firstName': 'Mohammad', 'lastName': 'Rizwan', 'dob': DateTime(1992, 6, 1), 'phone': '0302-1111149', 'email': 'mohammad.rizwan@gmail.com', 'address': '89 Peshawar Road, Rawalpindi', 'history': 'Eye Strain, Dry Eyes', 'tags': 'ophthalmology', 'risk': 1},
    {'firstName': 'Sumbul', 'lastName': 'Iqbal', 'dob': DateTime(1990, 8, 27), 'phone': '0321-1111150', 'email': 'sumbul.iqbal@yahoo.com', 'address': '23 Johar Town Block J, Lahore', 'history': 'Hypothyroidism, Weight Gain', 'tags': 'endocrine,metabolic', 'risk': 2},
    {'firstName': 'Fakhar', 'lastName': 'Zaman', 'dob': DateTime(1990, 4, 10), 'phone': '0312-1111151', 'email': 'fakhar.zaman@hotmail.com', 'address': '56 Mardan Road, Peshawar', 'history': 'Hand Fracture (healed), Carpal Tunnel', 'tags': 'orthopedic', 'risk': 1},
    {'firstName': 'Aiman', 'lastName': 'Khan', 'dob': DateTime(1998, 11, 20), 'phone': '0331-1111152', 'email': 'aiman.khan@gmail.com', 'address': '78 G-10/4, Islamabad', 'history': 'Allergic Rhinitis, Sinusitis', 'tags': 'ent,respiratory', 'risk': 1},
    {'firstName': 'Inzamam', 'lastName': 'ul-Haq', 'dob': DateTime(1970, 3, 3), 'phone': '0303-1111153', 'email': 'inzamam.ulhaq@outlook.com', 'address': '12 Gulberg Main, Lahore', 'history': 'Type 2 Diabetes, Obesity, Sleep Apnea', 'tags': 'endocrine,metabolic,respiratory,elderly', 'risk': 4},
    {'firstName': 'Ramsha', 'lastName': 'Khan', 'dob': DateTime(1996, 11, 25), 'phone': '0322-1111154', 'email': 'ramsha.khan@yahoo.com', 'address': '34 E-11/2, Islamabad', 'history': 'Migraine with Aura', 'tags': 'neurology', 'risk': 2},
    {'firstName': 'Younis', 'lastName': 'Khan', 'dob': DateTime(1977, 11, 29), 'phone': '0313-1111155', 'email': 'younis.khan@gmail.com', 'address': '67 Hayatabad Phase 3, Peshawar', 'history': 'Knee Osteoarthritis, Previous Meniscus Surgery', 'tags': 'orthopedic,elderly', 'risk': 3},
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
  log.i('SEED', '✓ Inserted ${patientIds.length} patients');

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
    'Pulmonary function test',
    'Neurological assessment',
    'Pre-operative consultation',
    'Post-operative follow-up',
    'Chronic disease management',
    'Weight management consultation',
    'Nutritional counseling',
    'Vaccination visit',
    'Travel medicine consultation',
    'Second opinion consultation',
  ];

  int appointmentCount = 0;

  // Past appointments (last 90 days - increased from 30)
  for (int dayOffset = 90; dayOffset > 0; dayOffset--) {
    final appointmentDay = today.subtract(Duration(days: dayOffset));
    final appointmentsPerDay = 8 + random.nextInt(8); // 8-15 per day (increased)
    
    for (int i = 0; i < appointmentsPerDay; i++) {
      final patientIndex = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(9); // 9am to 6pm
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

  // Today's appointments (increased from 6 to 12)
  for (int i = 0; i < 12; i++) {
    final patientIndex = i % patientIds.length;
    final hour = 9 + (i * 0.75).floor();
    
    await db.insertAppointment(
      AppointmentsCompanion(
        patientId: Value(patientIds[patientIndex]),
        appointmentDateTime: Value(today.add(Duration(hours: hour, minutes: (i % 4) * 15))),
        durationMinutes: Value([15, 30, 30, 45, 30, 20, 45, 30, 15, 20, 30, 45][i]),
        reason: Value(appointmentReasons[i % appointmentReasons.length]),
        status: Value(i < 5 ? 'completed' : (i < 8 ? 'in-progress' : 'confirmed')),
        notes: Value('Today\'s appointment for ${patientData[patientIndex]['firstName']}'),
      ),
    );
    appointmentCount++;
  }

  // Future appointments (next 30 days - increased from 14)
  for (int dayOffset = 1; dayOffset <= 30; dayOffset++) {
    final appointmentDay = today.add(Duration(days: dayOffset));
    final appointmentsPerDay = 5 + random.nextInt(10); // 5-14 per day (increased)
    
    for (int i = 0; i < appointmentsPerDay; i++) {
      final patientIndex = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(9);
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
  log.i('SEED', '✓ Inserted $appointmentCount appointments');

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
  for (int i = 0; i < patientIds.length; i++) {
    // Multiple prescriptions per patient over time - more for chronic patients
    final isChronic = (patientData[i]['tags'] as String).contains('chronic');
    final numPrescriptions = isChronic ? (3 + random.nextInt(4)) : (1 + random.nextInt(3)); // 1-3 or 3-6 for chronic
    
    for (int j = 0; j < numPrescriptions; j++) {
      // Use modulo to cycle through medication templates
      final medIndex = (i + j) % medications.length;
      await db.insertPrescription(
        PrescriptionsCompanion(
          patientId: Value(patientIds[i]),
          itemsJson: Value(jsonEncode(medications[medIndex])),
          instructions: Value(instructions[medIndex]),
          isRefillable: Value(random.nextInt(3) != 0), // 66% refillable
          createdAt: Value(today.subtract(Duration(days: j * 30 + random.nextInt(15)))),
        ),
      );
      prescriptionCount++;
    }
  }
  log.i('SEED', '✓ Inserted $prescriptionCount prescriptions');

  // ========== MEDICAL RECORDS ==========
  final recordTypes = ['general', 'psychiatric_assessment', 'lab_result', 'imaging', 'procedure', 'pulmonary_evaluation'];
  
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

  // Pulmonary evaluation records
  final pulmonaryRecords = [
    {
      'title': 'Chronic Cough Evaluation',
      'data': {
        'chiefComplaint': 'Persistent dry cough for 3 months',
        'duration': '3 months',
        'symptomCharacter': 'Dry, non-productive, worse at night and early morning',
        'systemicSymptoms': ['Fatigue', 'Mild weight loss'],
        'redFlags': <String>[],
        'pastPulmonaryHistory': 'No previous lung disease',
        'exposureHistory': 'Non-smoker, no occupational exposure',
        'allergyHistory': 'Seasonal allergic rhinitis',
        'currentMedications': 'ACE inhibitor for hypertension',
        'comorbidities': 'Hypertension, GERD',
        'chestAuscultation': {
          'leftUpper': 'Clear',
          'rightUpper': 'Clear',
          'leftMiddle': 'Clear',
          'rightMiddle': 'Clear',
          'leftLower': 'Clear',
          'rightLower': 'Clear',
          'adventitiousSounds': 'None',
        },
        'impressionDiagnosis': 'ACE inhibitor-induced cough vs GERD-related cough',
        'investigationsRequired': ['Chest X-Ray', 'Spirometry'],
        'treatmentPlan': 'Switch ACE inhibitor to ARB. PPI therapy. Follow-up in 4 weeks.',
      },
      'notes': 'Consider drug-induced cough. Trial of ACE inhibitor withdrawal recommended.'
    },
    {
      'title': 'Acute Asthma Exacerbation',
      'data': {
        'chiefComplaint': 'Severe breathlessness and wheeze for 2 days',
        'duration': '2 days',
        'symptomCharacter': 'Progressive dyspnea, audible wheeze, difficulty speaking in sentences',
        'systemicSymptoms': ['Fever', 'Cough'],
        'redFlags': ['Severe dyspnea', 'Cyanosis'],
        'pastPulmonaryHistory': 'Known asthmatic since childhood',
        'exposureHistory': 'Recent viral URTI, dust exposure at workplace',
        'allergyHistory': 'Allergic to house dust mites, pollen',
        'currentMedications': 'Inhaled budesonide/formoterol 200/6, Salbutamol PRN',
        'comorbidities': 'Allergic rhinitis',
        'chestAuscultation': {
          'leftUpper': 'Wheeze',
          'rightUpper': 'Wheeze',
          'leftMiddle': 'Wheeze',
          'rightMiddle': 'Wheeze',
          'leftLower': 'Wheeze, prolonged expiration',
          'rightLower': 'Wheeze, prolonged expiration',
          'adventitiousSounds': 'Bilateral polyphonic wheeze',
        },
        'impressionDiagnosis': 'Acute severe asthma exacerbation, likely infective trigger',
        'investigationsRequired': ['Peak Flow', 'Chest X-Ray', 'ABG'],
        'treatmentPlan': 'Nebulized bronchodilators, IV corticosteroids, oxygen therapy. Monitor closely.',
      },
      'notes': 'Severe exacerbation requiring close monitoring. Consider ICU if not responding.'
    },
    {
      'title': 'COPD Follow-up',
      'data': {
        'chiefComplaint': 'Routine follow-up for COPD management',
        'duration': 'Chronic - diagnosed 5 years ago',
        'symptomCharacter': 'Baseline dyspnea on exertion, productive cough with white sputum',
        'systemicSymptoms': <String>[],
        'redFlags': <String>[],
        'pastPulmonaryHistory': 'COPD GOLD Stage 2, 2 exacerbations last year',
        'exposureHistory': '30 pack-year smoking history, quit 2 years ago',
        'allergyHistory': 'None',
        'currentMedications': 'Tiotropium 18mcg OD, Budesonide/Formoterol 400/12 BD',
        'comorbidities': 'Osteoporosis, Depression',
        'chestAuscultation': {
          'leftUpper': 'Reduced breath sounds',
          'rightUpper': 'Reduced breath sounds',
          'leftMiddle': 'Reduced breath sounds, occasional rhonchi',
          'rightMiddle': 'Reduced breath sounds, occasional rhonchi',
          'leftLower': 'Prolonged expiration',
          'rightLower': 'Prolonged expiration',
          'adventitiousSounds': 'Scattered rhonchi, no crackles',
        },
        'impressionDiagnosis': 'COPD GOLD Stage 2, stable on current therapy',
        'investigationsRequired': ['Spirometry', 'Chest X-Ray Annual'],
        'treatmentPlan': 'Continue current inhalers. Pulmonary rehabilitation referral. Vaccination due.',
      },
      'notes': 'Stable COPD. Good inhaler technique. Encourage continued smoking abstinence.'
    },
    {
      'title': 'Pneumonia Evaluation',
      'data': {
        'chiefComplaint': 'High fever, productive cough with yellow sputum, chest pain',
        'duration': '5 days',
        'symptomCharacter': 'Fever 102°F, productive cough, right-sided pleuritic chest pain',
        'systemicSymptoms': ['Fever', 'Fatigue', 'Night sweats', 'Loss of appetite'],
        'redFlags': ['Fever', 'Hemoptysis'],
        'pastPulmonaryHistory': 'Previous pneumonia 3 years ago',
        'exposureHistory': 'No TB contact, no travel history',
        'allergyHistory': 'Penicillin allergy',
        'currentMedications': 'None',
        'comorbidities': 'Type 2 Diabetes Mellitus',
        'chestAuscultation': {
          'leftUpper': 'Clear',
          'rightUpper': 'Clear',
          'leftMiddle': 'Clear',
          'rightMiddle': 'Bronchial breathing',
          'leftLower': 'Clear',
          'rightLower': 'Crackles, bronchial breathing, increased vocal resonance',
          'adventitiousSounds': 'Right lower zone crackles with bronchial breathing',
        },
        'impressionDiagnosis': 'Right lower lobe Community Acquired Pneumonia',
        'investigationsRequired': ['Chest X-Ray', 'CBC', 'CRP', 'Blood culture', 'Sputum culture'],
        'treatmentPlan': 'Azithromycin 500mg OD + Cefuroxime 500mg BD for 7 days. Adequate hydration.',
      },
      'notes': 'CAP with diabetic comorbidity. Close monitoring for response. Avoid penicillins.'
    },
    {
      'title': 'Interstitial Lung Disease Workup',
      'data': {
        'chiefComplaint': 'Progressive breathlessness over 6 months with dry cough',
        'duration': '6 months',
        'symptomCharacter': 'Gradual onset dyspnea, now at rest, dry non-productive cough',
        'systemicSymptoms': ['Fatigue', 'Weight loss'],
        'redFlags': ['Severe dyspnea'],
        'pastPulmonaryHistory': 'No previous lung disease',
        'exposureHistory': 'Worked in textile factory for 20 years, asbestos exposure possible',
        'allergyHistory': 'None',
        'currentMedications': 'Methotrexate for rheumatoid arthritis',
        'comorbidities': 'Rheumatoid arthritis for 10 years',
        'chestAuscultation': {
          'leftUpper': 'Fine end-inspiratory crackles',
          'rightUpper': 'Fine end-inspiratory crackles',
          'leftMiddle': 'Velcro crackles',
          'rightMiddle': 'Velcro crackles',
          'leftLower': 'Velcro crackles, clubbing noted',
          'rightLower': 'Velcro crackles, clubbing noted',
          'adventitiousSounds': 'Bilateral basal Velcro crackles, finger clubbing present',
        },
        'impressionDiagnosis': 'Suspected Interstitial Lung Disease - RA-ILD vs Occupational lung disease',
        'investigationsRequired': ['HRCT Chest', 'Spirometry with DLCO', 'ANA', 'RF', 'Anti-CCP', 'Bronchoscopy if needed'],
        'treatmentPlan': 'HRCT chest urgently. Rheumatology consultation. Consider methotrexate-induced pneumonitis.',
      },
      'notes': 'High suspicion for ILD. Multiple risk factors. Expedite workup.'
    },
  ];

  int medicalRecordCount = 0;

  // Add medical records for each patient - more comprehensive
  for (int i = 0; i < patientIds.length; i++) {
    // More records for chronic patients
    final isChronic = (patientData[i]['tags'] as String).contains('chronic');
    final numRecords = isChronic ? (5 + random.nextInt(6)) : (3 + random.nextInt(5)); // 3-7 or 5-10 for chronic
    
    for (int j = 0; j < numRecords; j++) {
      final recordType = recordTypes[random.nextInt(recordTypes.length)];
      final recordDate = today.subtract(Duration(days: random.nextInt(730))); // Last 2 years
      
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
        case 'psychiatric_assessment':
          final record = psychiatricRecords[random.nextInt(psychiatricRecords.length)];
          title = record['title'] as String;
          description = 'Psychiatric evaluation and assessment';
          diagnosis = record['diagnosis'] as String;
          treatment = record['treatment'] as String;
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
        case 'lab_result':
          final record = labRecords[random.nextInt(labRecords.length)];
          title = record['title'] as String;
          description = 'Laboratory test results';
          diagnosis = 'See results';
          treatment = 'Based on results';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
        case 'imaging':
          final record = imagingRecords[random.nextInt(imagingRecords.length)];
          title = record['title'] as String;
          description = 'Imaging study report';
          diagnosis = 'See findings';
          treatment = 'Based on findings';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
        case 'procedure':
          final record = procedureRecords[random.nextInt(procedureRecords.length)];
          title = record['title'] as String;
          description = 'Medical procedure performed';
          diagnosis = 'Procedure completed';
          treatment = 'As documented';
          doctorNotes = record['notes'] as String;
          dataJson = record['data'] as Map<String, dynamic>;
        case 'pulmonary_evaluation':
          final record = pulmonaryRecords[random.nextInt(pulmonaryRecords.length)];
          title = record['title'] as String;
          description = 'Pulmonary clinical evaluation';
          final data = record['data'] as Map<String, dynamic>;
          diagnosis = data['impressionDiagnosis'] as String? ?? 'Under evaluation';
          treatment = data['treatmentPlan'] as String? ?? 'Pending';
          doctorNotes = record['notes'] as String;
          dataJson = data;
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
  log.i('SEED', '✓ Inserted $medicalRecordCount medical records');

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

  int invoiceCount = 0;
  int invoiceNumber = 1000;

  // Generate invoices for all patients - more comprehensive
  for (int i = 0; i < patientIds.length; i++) {
    // More invoices for chronic patients
    final isChronic = (patientData[i]['tags'] as String).contains('chronic');
    final numInvoices = isChronic ? (4 + random.nextInt(5)) : (2 + random.nextInt(4)); // 2-5 or 4-8 for chronic
    
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
  log.i('SEED', '✓ Inserted $invoiceCount invoices');

  log
    ..i('SEED', '')
    ..i('SEED', '═══════════════════════════════════════════════════════════')
    ..i('SEED', '  DATABASE SEEDING COMPLETE')
    ..i('SEED', '═══════════════════════════════════════════════════════════')
    ..i('SEED', '  ✓ ${patientIds.length} Pakistani patients')
    ..i('SEED', '  ✓ $appointmentCount appointments (past, today, future)')
    ..i('SEED', '  ✓ $prescriptionCount prescriptions with medications')
    ..i('SEED', '  ✓ $medicalRecordCount medical records (5 types)')
    ..i('SEED', '  ✓ $invoiceCount invoices with varied items')
    ..i('SEED', '═══════════════════════════════════════════════════════════');
}
