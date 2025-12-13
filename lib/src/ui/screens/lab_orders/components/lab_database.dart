/// Lab Test Database
/// 
/// Comprehensive database of common lab tests organized by category.
/// Includes quick panels for common test combinations.

import 'lab_models.dart';

/// Database of common lab tests with templates
class LabTestDatabase {
  LabTestDatabase._();

  // ==================== Basic Blood Tests ====================
  static const List<LabTestTemplate> basicBlood = [
    LabTestTemplate(
      name: 'Complete Blood Count (CBC)',
      category: 'Hematology',
      testCode: 'CBC',
      specimenType: 'blood',
      clinicalIndication: 'Routine screening, infection, anemia',
      referenceRange: 'WBC: 4.5-11.0 K/uL, RBC: 4.5-5.5 M/uL, Hgb: 12-16 g/dL, Plt: 150-400 K/uL',
    ),
    LabTestTemplate(
      name: 'Hemoglobin (Hb)',
      category: 'Hematology',
      testCode: 'HB',
      specimenType: 'blood',
      clinicalIndication: 'Anemia screening',
      referenceRange: 'Male: 14-18 g/dL, Female: 12-16 g/dL',
    ),
    LabTestTemplate(
      name: 'Erythrocyte Sedimentation Rate (ESR)',
      category: 'Hematology',
      testCode: 'ESR',
      specimenType: 'blood',
      clinicalIndication: 'Inflammation marker',
      referenceRange: 'Male: 0-15 mm/hr, Female: 0-20 mm/hr',
    ),
    LabTestTemplate(
      name: 'Blood Group & Rh Factor',
      category: 'Hematology',
      testCode: 'BG-RH',
      specimenType: 'blood',
      clinicalIndication: 'Pre-operative, transfusion',
    ),
    LabTestTemplate(
      name: 'Peripheral Blood Smear',
      category: 'Hematology',
      testCode: 'PBS',
      specimenType: 'blood',
      clinicalIndication: 'Blood cell morphology',
    ),
  ];

  // ==================== Metabolic Panel ====================
  static const List<LabTestTemplate> metabolicPanel = [
    LabTestTemplate(
      name: 'Basic Metabolic Panel (BMP)',
      category: 'Chemistry',
      testCode: 'BMP',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function, electrolytes, glucose',
    ),
    LabTestTemplate(
      name: 'Comprehensive Metabolic Panel (CMP)',
      category: 'Chemistry',
      testCode: 'CMP',
      specimenType: 'blood',
      clinicalIndication: 'Complete metabolic assessment',
    ),
    LabTestTemplate(
      name: 'Electrolytes (Na, K, Cl, CO2)',
      category: 'Chemistry',
      testCode: 'ELEC',
      specimenType: 'blood',
      clinicalIndication: 'Electrolyte balance',
      referenceRange: 'Na: 136-145, K: 3.5-5.0, Cl: 98-106, CO2: 23-29 mEq/L',
    ),
    LabTestTemplate(
      name: 'Serum Calcium',
      category: 'Chemistry',
      testCode: 'CA',
      specimenType: 'blood',
      clinicalIndication: 'Bone health, parathyroid',
      referenceRange: '8.5-10.5 mg/dL',
    ),
    LabTestTemplate(
      name: 'Serum Magnesium',
      category: 'Chemistry',
      testCode: 'MG',
      specimenType: 'blood',
      clinicalIndication: 'Muscle, nerve function',
      referenceRange: '1.7-2.2 mg/dL',
    ),
  ];

  // ==================== Liver Function Tests ====================
  static const List<LabTestTemplate> liverFunction = [
    LabTestTemplate(
      name: 'Liver Function Tests (LFT)',
      category: 'Hepatic',
      testCode: 'LFT',
      specimenType: 'blood',
      clinicalIndication: 'Liver disease screening',
      referenceRange: 'ALT: 7-56 U/L, AST: 10-40 U/L, ALP: 44-147 U/L',
    ),
    LabTestTemplate(
      name: 'ALT (SGPT)',
      category: 'Hepatic',
      testCode: 'ALT',
      specimenType: 'blood',
      clinicalIndication: 'Liver enzyme',
      referenceRange: '7-56 U/L',
    ),
    LabTestTemplate(
      name: 'AST (SGOT)',
      category: 'Hepatic',
      testCode: 'AST',
      specimenType: 'blood',
      clinicalIndication: 'Liver enzyme',
      referenceRange: '10-40 U/L',
    ),
    LabTestTemplate(
      name: 'Alkaline Phosphatase (ALP)',
      category: 'Hepatic',
      testCode: 'ALP',
      specimenType: 'blood',
      clinicalIndication: 'Liver, bone disease',
      referenceRange: '44-147 U/L',
    ),
    LabTestTemplate(
      name: 'Gamma GT (GGT)',
      category: 'Hepatic',
      testCode: 'GGT',
      specimenType: 'blood',
      clinicalIndication: 'Liver, bile duct',
      referenceRange: '9-48 U/L',
    ),
    LabTestTemplate(
      name: 'Serum Bilirubin (Total & Direct)',
      category: 'Hepatic',
      testCode: 'BILI',
      specimenType: 'blood',
      clinicalIndication: 'Jaundice, liver function',
      referenceRange: 'Total: 0.1-1.2 mg/dL, Direct: 0-0.3 mg/dL',
    ),
    LabTestTemplate(
      name: 'Serum Albumin',
      category: 'Hepatic',
      testCode: 'ALB',
      specimenType: 'blood',
      clinicalIndication: 'Liver synthetic function',
      referenceRange: '3.4-5.4 g/dL',
    ),
  ];

  // ==================== Kidney Function Tests ====================
  static const List<LabTestTemplate> kidneyFunction = [
    LabTestTemplate(
      name: 'Renal Function Tests (RFT)',
      category: 'Renal',
      testCode: 'RFT',
      specimenType: 'blood',
      clinicalIndication: 'Kidney disease screening',
      referenceRange: 'Creatinine: 0.7-1.3 mg/dL, BUN: 7-20 mg/dL',
    ),
    LabTestTemplate(
      name: 'Serum Creatinine',
      category: 'Renal',
      testCode: 'CREAT',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function',
      referenceRange: '0.7-1.3 mg/dL',
    ),
    LabTestTemplate(
      name: 'Blood Urea Nitrogen (BUN)',
      category: 'Renal',
      testCode: 'BUN',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function',
      referenceRange: '7-20 mg/dL',
    ),
    LabTestTemplate(
      name: 'Serum Uric Acid',
      category: 'Renal',
      testCode: 'UA',
      specimenType: 'blood',
      clinicalIndication: 'Gout, kidney stones',
      referenceRange: 'Male: 3.4-7.0, Female: 2.4-6.0 mg/dL',
    ),
    LabTestTemplate(
      name: 'eGFR (Estimated GFR)',
      category: 'Renal',
      testCode: 'EGFR',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function staging',
      referenceRange: '>90 mL/min/1.73m²',
    ),
  ];

  // ==================== Diabetes Tests ====================
  static const List<LabTestTemplate> diabetes = [
    LabTestTemplate(
      name: 'Fasting Blood Glucose (FBG)',
      category: 'Diabetes',
      testCode: 'FBG',
      specimenType: 'blood',
      clinicalIndication: 'Diabetes screening',
      notes: 'Fasting for 8-12 hours required',
      referenceRange: '70-100 mg/dL',
    ),
    LabTestTemplate(
      name: 'Random Blood Glucose (RBG)',
      category: 'Diabetes',
      testCode: 'RBG',
      specimenType: 'blood',
      clinicalIndication: 'Immediate glucose assessment',
      referenceRange: '<140 mg/dL',
    ),
    LabTestTemplate(
      name: 'HbA1c (Glycated Hemoglobin)',
      category: 'Diabetes',
      testCode: 'HBA1C',
      specimenType: 'blood',
      clinicalIndication: '3-month glucose control',
      referenceRange: '<5.7% (normal), 5.7-6.4% (prediabetes), ≥6.5% (diabetes)',
    ),
    LabTestTemplate(
      name: 'Oral Glucose Tolerance Test (OGTT)',
      category: 'Diabetes',
      testCode: 'OGTT',
      specimenType: 'blood',
      clinicalIndication: 'Diabetes diagnosis',
      notes: '75g glucose load, 2-hour test',
      referenceRange: '<140 mg/dL at 2 hours',
    ),
    LabTestTemplate(
      name: 'Fasting Insulin',
      category: 'Diabetes',
      testCode: 'INS',
      specimenType: 'blood',
      clinicalIndication: 'Insulin resistance',
      referenceRange: '2.6-24.9 μIU/mL',
    ),
  ];

  // ==================== Lipid Profile ====================
  static const List<LabTestTemplate> lipidProfile = [
    LabTestTemplate(
      name: 'Lipid Panel (Complete)',
      category: 'Lipids',
      testCode: 'LIPID',
      specimenType: 'blood',
      clinicalIndication: 'Cardiovascular risk assessment',
      notes: 'Fasting for 9-12 hours preferred',
    ),
    LabTestTemplate(
      name: 'Total Cholesterol',
      category: 'Lipids',
      testCode: 'CHOL',
      specimenType: 'blood',
      clinicalIndication: 'Lipid screening',
      referenceRange: '<200 mg/dL (desirable)',
    ),
    LabTestTemplate(
      name: 'HDL Cholesterol',
      category: 'Lipids',
      testCode: 'HDL',
      specimenType: 'blood',
      clinicalIndication: 'Good cholesterol level',
      referenceRange: '>40 mg/dL (male), >50 mg/dL (female)',
    ),
    LabTestTemplate(
      name: 'LDL Cholesterol',
      category: 'Lipids',
      testCode: 'LDL',
      specimenType: 'blood',
      clinicalIndication: 'Bad cholesterol level',
      referenceRange: '<100 mg/dL (optimal)',
    ),
    LabTestTemplate(
      name: 'Triglycerides',
      category: 'Lipids',
      testCode: 'TG',
      specimenType: 'blood',
      clinicalIndication: 'Lipid assessment',
      referenceRange: '<150 mg/dL',
    ),
  ];

  // ==================== Thyroid Function ====================
  static const List<LabTestTemplate> thyroid = [
    LabTestTemplate(
      name: 'Thyroid Panel (TSH, T3, T4)',
      category: 'Endocrine',
      testCode: 'THY-PNL',
      specimenType: 'blood',
      clinicalIndication: 'Thyroid function screening',
    ),
    LabTestTemplate(
      name: 'TSH (Thyroid Stimulating Hormone)',
      category: 'Endocrine',
      testCode: 'TSH',
      specimenType: 'blood',
      clinicalIndication: 'Primary thyroid screening',
      referenceRange: '0.4-4.0 mIU/L',
    ),
    LabTestTemplate(
      name: 'Free T4 (FT4)',
      category: 'Endocrine',
      testCode: 'FT4',
      specimenType: 'blood',
      clinicalIndication: 'Thyroid hormone level',
      referenceRange: '0.8-1.8 ng/dL',
    ),
    LabTestTemplate(
      name: 'Free T3 (FT3)',
      category: 'Endocrine',
      testCode: 'FT3',
      specimenType: 'blood',
      clinicalIndication: 'Active thyroid hormone',
      referenceRange: '2.3-4.2 pg/mL',
    ),
    LabTestTemplate(
      name: 'Anti-TPO Antibodies',
      category: 'Endocrine',
      testCode: 'TPO-AB',
      specimenType: 'blood',
      clinicalIndication: 'Autoimmune thyroid disease',
      referenceRange: '<35 IU/mL',
    ),
  ];

  // ==================== Cardiac Markers ====================
  static const List<LabTestTemplate> cardiac = [
    LabTestTemplate(
      name: 'Cardiac Panel',
      category: 'Cardiac',
      testCode: 'CARD-PNL',
      specimenType: 'blood',
      clinicalIndication: 'Cardiac risk assessment',
    ),
    LabTestTemplate(
      name: 'Troponin I',
      category: 'Cardiac',
      testCode: 'TROP-I',
      specimenType: 'blood',
      urgency: 'urgent',
      clinicalIndication: 'Acute MI diagnosis',
      referenceRange: '<0.04 ng/mL',
    ),
    LabTestTemplate(
      name: 'Troponin T',
      category: 'Cardiac',
      testCode: 'TROP-T',
      specimenType: 'blood',
      urgency: 'urgent',
      clinicalIndication: 'Acute MI diagnosis',
      referenceRange: '<0.01 ng/mL',
    ),
    LabTestTemplate(
      name: 'BNP (B-type Natriuretic Peptide)',
      category: 'Cardiac',
      testCode: 'BNP',
      specimenType: 'blood',
      clinicalIndication: 'Heart failure marker',
      referenceRange: '<100 pg/mL',
    ),
    LabTestTemplate(
      name: 'High Sensitivity CRP (hs-CRP)',
      category: 'Cardiac',
      testCode: 'HSCRP',
      specimenType: 'blood',
      clinicalIndication: 'Cardiovascular inflammation',
      referenceRange: '<1.0 mg/L (low risk)',
    ),
  ];

  // ==================== Coagulation Tests ====================
  static const List<LabTestTemplate> coagulation = [
    LabTestTemplate(
      name: 'Coagulation Panel',
      category: 'Coagulation',
      testCode: 'COAG-PNL',
      specimenType: 'blood',
      clinicalIndication: 'Bleeding/clotting disorders',
    ),
    LabTestTemplate(
      name: 'PT/INR',
      category: 'Coagulation',
      testCode: 'PT-INR',
      specimenType: 'blood',
      clinicalIndication: 'Warfarin monitoring, liver function',
      referenceRange: 'PT: 11-13.5 sec, INR: 0.8-1.2 (2-3 on warfarin)',
    ),
    LabTestTemplate(
      name: 'aPTT',
      category: 'Coagulation',
      testCode: 'APTT',
      specimenType: 'blood',
      clinicalIndication: 'Heparin monitoring, bleeding disorders',
      referenceRange: '25-35 seconds',
    ),
    LabTestTemplate(
      name: 'D-Dimer',
      category: 'Coagulation',
      testCode: 'DDIMER',
      specimenType: 'blood',
      clinicalIndication: 'DVT/PE screening',
      referenceRange: '<500 ng/mL',
    ),
    LabTestTemplate(
      name: 'Fibrinogen',
      category: 'Coagulation',
      testCode: 'FIB',
      specimenType: 'blood',
      clinicalIndication: 'Clotting factor assessment',
      referenceRange: '200-400 mg/dL',
    ),
  ];

  // ==================== Urine Tests ====================
  static const List<LabTestTemplate> urineTests = [
    LabTestTemplate(
      name: 'Urinalysis (Complete)',
      category: 'Urine',
      testCode: 'UA-COMP',
      specimenType: 'urine',
      clinicalIndication: 'UTI, kidney disease screening',
    ),
    LabTestTemplate(
      name: 'Urine Routine & Microscopy (R/M)',
      category: 'Urine',
      testCode: 'UR-RM',
      specimenType: 'urine',
      clinicalIndication: 'UTI screening',
    ),
    LabTestTemplate(
      name: 'Urine Culture & Sensitivity',
      category: 'Urine',
      testCode: 'UC-S',
      specimenType: 'urine',
      clinicalIndication: 'UTI diagnosis, antibiotic selection',
    ),
    LabTestTemplate(
      name: 'Urine Albumin/Creatinine Ratio (UACR)',
      category: 'Urine',
      testCode: 'UACR',
      specimenType: 'urine',
      clinicalIndication: 'Diabetic nephropathy screening',
      referenceRange: '<30 mg/g (normal)',
    ),
  ];

  // ==================== Infectious Disease ====================
  static const List<LabTestTemplate> infectious = [
    LabTestTemplate(
      name: 'Hepatitis B Surface Antigen (HBsAg)',
      category: 'Infectious',
      testCode: 'HBSAG',
      specimenType: 'blood',
      clinicalIndication: 'Hepatitis B screening',
    ),
    LabTestTemplate(
      name: 'Hepatitis C Antibody (Anti-HCV)',
      category: 'Infectious',
      testCode: 'HCV-AB',
      specimenType: 'blood',
      clinicalIndication: 'Hepatitis C screening',
    ),
    LabTestTemplate(
      name: 'HIV Screening Test',
      category: 'Infectious',
      testCode: 'HIV',
      specimenType: 'blood',
      clinicalIndication: 'HIV screening',
    ),
    LabTestTemplate(
      name: 'Dengue NS1 Antigen',
      category: 'Infectious',
      testCode: 'DENGUE-NS1',
      specimenType: 'blood',
      urgency: 'urgent',
      clinicalIndication: 'Acute dengue diagnosis',
    ),
    LabTestTemplate(
      name: 'Malaria Parasite (MP)',
      category: 'Infectious',
      testCode: 'MP',
      specimenType: 'blood',
      urgency: 'urgent',
      clinicalIndication: 'Malaria diagnosis',
    ),
    LabTestTemplate(
      name: 'Typhidot (IgM/IgG)',
      category: 'Infectious',
      testCode: 'TYPHIDOT',
      specimenType: 'blood',
      clinicalIndication: 'Typhoid fever diagnosis',
    ),
    LabTestTemplate(
      name: 'COVID-19 RT-PCR',
      category: 'Infectious',
      testCode: 'COVID-PCR',
      specimenType: 'swab',
      clinicalIndication: 'Active COVID-19 infection',
    ),
  ];

  // ==================== Vitamins & Hormones ====================
  static const List<LabTestTemplate> vitaminsHormones = [
    LabTestTemplate(
      name: 'Vitamin D (25-OH)',
      category: 'Vitamins',
      testCode: 'VIT-D',
      specimenType: 'blood',
      clinicalIndication: 'Vitamin D deficiency',
      referenceRange: '30-100 ng/mL',
    ),
    LabTestTemplate(
      name: 'Vitamin B12',
      category: 'Vitamins',
      testCode: 'VIT-B12',
      specimenType: 'blood',
      clinicalIndication: 'Anemia, neuropathy',
      referenceRange: '200-900 pg/mL',
    ),
    LabTestTemplate(
      name: 'Folate (Folic Acid)',
      category: 'Vitamins',
      testCode: 'FOLATE',
      specimenType: 'blood',
      clinicalIndication: 'Anemia, pregnancy',
      referenceRange: '>3.0 ng/mL',
    ),
    LabTestTemplate(
      name: 'Serum Iron',
      category: 'Vitamins',
      testCode: 'FE',
      specimenType: 'blood',
      clinicalIndication: 'Iron deficiency',
      referenceRange: '60-170 μg/dL',
    ),
    LabTestTemplate(
      name: 'Ferritin',
      category: 'Vitamins',
      testCode: 'FERR',
      specimenType: 'blood',
      clinicalIndication: 'Iron stores assessment',
      referenceRange: 'Male: 12-300, Female: 12-150 ng/mL',
    ),
  ];

  // ==================== Tumor Markers ====================
  static const List<LabTestTemplate> tumorMarkers = [
    LabTestTemplate(
      name: 'PSA (Prostate Specific Antigen)',
      category: 'Tumor Markers',
      testCode: 'PSA',
      specimenType: 'blood',
      clinicalIndication: 'Prostate cancer screening',
      referenceRange: '<4.0 ng/mL',
    ),
    LabTestTemplate(
      name: 'CA-125',
      category: 'Tumor Markers',
      testCode: 'CA125',
      specimenType: 'blood',
      clinicalIndication: 'Ovarian cancer marker',
      referenceRange: '<35 U/mL',
    ),
    LabTestTemplate(
      name: 'CEA (Carcinoembryonic Antigen)',
      category: 'Tumor Markers',
      testCode: 'CEA',
      specimenType: 'blood',
      clinicalIndication: 'Colorectal cancer marker',
      referenceRange: '<3.0 ng/mL (non-smoker)',
    ),
    LabTestTemplate(
      name: 'AFP (Alpha-Fetoprotein)',
      category: 'Tumor Markers',
      testCode: 'AFP',
      specimenType: 'blood',
      clinicalIndication: 'Liver cancer, prenatal screening',
      referenceRange: '<10 ng/mL',
    ),
  ];

  // ==================== Quick Fill Panels ====================
  static List<LabTestPanel> get quickPanels => [
    LabTestPanel(
      name: 'Routine Health Checkup',
      description: 'Basic screening tests for annual health assessment',
      clinicalIndication: 'Annual health checkup',
      tests: [
        basicBlood[0].toLabTestData(),     // CBC
        diabetes[0].toLabTestData(),        // FBG
        lipidProfile[0].toLabTestData(),    // Lipid Panel
        liverFunction[0].toLabTestData(),   // LFT
        kidneyFunction[0].toLabTestData(),  // RFT
        urineTests[0].toLabTestData(),      // Urinalysis
      ],
    ),
    LabTestPanel(
      name: 'Diabetic Workup',
      description: 'Complete tests for diabetic patients',
      clinicalIndication: 'Diabetes monitoring/screening',
      tests: [
        diabetes[0].toLabTestData(),        // FBG
        diabetes[2].toLabTestData(),        // HbA1c
        lipidProfile[0].toLabTestData(),    // Lipid Panel
        kidneyFunction[0].toLabTestData(),  // RFT
        urineTests[3].toLabTestData(),      // UACR
      ],
    ),
    LabTestPanel(
      name: 'Cardiac Risk Assessment',
      description: 'Tests for cardiovascular risk evaluation',
      clinicalIndication: 'Cardiac risk assessment',
      tests: [
        lipidProfile[0].toLabTestData(),    // Lipid Panel
        cardiac[4].toLabTestData(),         // hs-CRP
        diabetes[0].toLabTestData(),        // FBG
        diabetes[2].toLabTestData(),        // HbA1c
        kidneyFunction[0].toLabTestData(),  // RFT
      ],
    ),
    LabTestPanel(
      name: 'Thyroid Assessment',
      description: 'Complete thyroid function evaluation',
      clinicalIndication: 'Thyroid disorder workup',
      tests: [
        thyroid[1].toLabTestData(),  // TSH
        thyroid[2].toLabTestData(),  // Free T4
        thyroid[3].toLabTestData(),  // Free T3
        thyroid[4].toLabTestData(),  // Anti-TPO
      ],
    ),
    LabTestPanel(
      name: 'Anemia Workup',
      description: 'Tests for anemia evaluation',
      clinicalIndication: 'Anemia diagnosis and classification',
      tests: [
        basicBlood[0].toLabTestData(),     // CBC
        vitaminsHormones[3].toLabTestData(), // Iron
        vitaminsHormones[4].toLabTestData(), // Ferritin
        vitaminsHormones[1].toLabTestData(), // B12
        vitaminsHormones[2].toLabTestData(), // Folate
      ],
    ),
    LabTestPanel(
      name: 'Liver Disease Workup',
      description: 'Comprehensive liver assessment',
      clinicalIndication: 'Liver disease evaluation',
      tests: [
        liverFunction[0].toLabTestData(), // LFT
        infectious[0].toLabTestData(),    // HBsAg
        infectious[1].toLabTestData(),    // Anti-HCV
        coagulation[1].toLabTestData(),   // PT/INR
        liverFunction[6].toLabTestData(), // Albumin
      ],
    ),
    LabTestPanel(
      name: 'Pre-Operative Assessment',
      description: 'Tests required before surgery',
      clinicalIndication: 'Pre-surgical evaluation',
      tests: [
        basicBlood[0].toLabTestData(),    // CBC
        coagulation[1].toLabTestData(),   // PT/INR
        coagulation[2].toLabTestData(),   // aPTT
        basicBlood[3].toLabTestData(),    // Blood Group
        infectious[0].toLabTestData(),    // HBsAg
        infectious[1].toLabTestData(),    // Anti-HCV
        diabetes[0].toLabTestData(),      // FBG
        kidneyFunction[0].toLabTestData(), // RFT
      ],
    ),
    LabTestPanel(
      name: 'Fever Workup',
      description: 'Tests for pyrexia of unknown origin',
      clinicalIndication: 'Fever evaluation',
      tests: [
        basicBlood[0].toLabTestData(),  // CBC
        infectious[4].toLabTestData(),  // Malaria
        infectious[5].toLabTestData(),  // Typhidot
        infectious[3].toLabTestData(),  // Dengue NS1
        urineTests[2].toLabTestData(),  // Urine C&S
      ],
    ),
    LabTestPanel(
      name: 'Pregnancy Workup',
      description: 'Tests for antenatal assessment',
      clinicalIndication: 'Antenatal screening',
      tests: [
        basicBlood[0].toLabTestData(),    // CBC
        basicBlood[3].toLabTestData(),    // Blood Group
        diabetes[0].toLabTestData(),      // FBG
        urineTests[0].toLabTestData(),    // Urinalysis
        infectious[0].toLabTestData(),    // HBsAg
        infectious[2].toLabTestData(),    // HIV
        thyroid[1].toLabTestData(),       // TSH
      ],
    ),
  ];

  /// Get all test categories
  static Map<String, List<LabTestTemplate>> get allCategories => {
    'Basic Blood Tests': basicBlood,
    'Metabolic Panel': metabolicPanel,
    'Liver Function': liverFunction,
    'Kidney Function': kidneyFunction,
    'Diabetes': diabetes,
    'Lipid Profile': lipidProfile,
    'Thyroid': thyroid,
    'Cardiac': cardiac,
    'Coagulation': coagulation,
    'Urine Tests': urineTests,
    'Infectious Disease': infectious,
    'Vitamins & Hormones': vitaminsHormones,
    'Tumor Markers': tumorMarkers,
  };

  /// Get all tests as flat list
  static List<LabTestTemplate> get allTests => [
    ...basicBlood,
    ...metabolicPanel,
    ...liverFunction,
    ...kidneyFunction,
    ...diabetes,
    ...lipidProfile,
    ...thyroid,
    ...cardiac,
    ...coagulation,
    ...urineTests,
    ...infectious,
    ...vitaminsHormones,
    ...tumorMarkers,
  ];

  /// Get category names
  static List<String> get categoryNames => allCategories.keys.toList();

  /// Get tests by category name
  static List<LabTestTemplate> getByCategory(String categoryName) {
    return allCategories[categoryName] ?? [];
  }

  /// Search tests by name, code, or category
  static List<LabTestTemplate> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return allTests.where((test) =>
      test.name.toLowerCase().contains(lowerQuery) ||
      test.category.toLowerCase().contains(lowerQuery) ||
      (test.testCode?.toLowerCase().contains(lowerQuery) ?? false) ||
      (test.clinicalIndication?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Get test by code
  static LabTestTemplate? getByCode(String code) {
    try {
      return allTests.firstWhere(
        (t) => t.testCode?.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get tests that require fasting
  static List<LabTestTemplate> get fastingTests {
    return allTests.where((t) {
      final lower = t.name.toLowerCase();
      return lower.contains('fasting') || 
             lower.contains('lipid') ||
             (t.notes?.toLowerCase().contains('fasting') ?? false);
    }).toList();
  }
}
