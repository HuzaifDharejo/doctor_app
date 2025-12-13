/// Lab Test Templates Service
/// Provides categorized lab test templates for quick selection
/// Similar to prescription_templates.dart for medications

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/components/app_input.dart';

class LabTestTemplate {
  const LabTestTemplate({
    required this.name,
    required this.category,
    this.testCode,
    this.specimenType = 'blood',
    this.urgency = 'routine',
    this.clinicalIndication,
    this.notes,
  });

  final String name;
  final String category;
  final String? testCode;
  final String specimenType;
  final String urgency;
  final String? clinicalIndication;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'testCode': testCode,
    'specimenType': specimenType,
    'urgency': urgency,
    'clinicalIndication': clinicalIndication,
    'notes': notes,
  };
}

/// Predefined test panel templates that include multiple tests
class LabTestPanel {
  const LabTestPanel({
    required this.name,
    required this.description,
    required this.tests,
    this.clinicalIndication,
  });

  final String name;
  final String description;
  final List<LabTestTemplate> tests;
  final String? clinicalIndication;
}

class LabTestTemplates {
  // ==================== Basic Blood Tests ====================
  static const List<LabTestTemplate> basicBlood = [
    LabTestTemplate(
      name: 'Complete Blood Count (CBC)',
      category: 'Hematology',
      testCode: 'CBC',
      specimenType: 'blood',
      clinicalIndication: 'Routine screening, infection, anemia',
    ),
    LabTestTemplate(
      name: 'Hemoglobin (Hb)',
      category: 'Hematology',
      testCode: 'HB',
      specimenType: 'blood',
      clinicalIndication: 'Anemia screening',
    ),
    LabTestTemplate(
      name: 'Erythrocyte Sedimentation Rate (ESR)',
      category: 'Hematology',
      testCode: 'ESR',
      specimenType: 'blood',
      clinicalIndication: 'Inflammation marker',
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
    ),
    LabTestTemplate(
      name: 'Serum Calcium',
      category: 'Chemistry',
      testCode: 'CA',
      specimenType: 'blood',
      clinicalIndication: 'Bone health, parathyroid',
    ),
    LabTestTemplate(
      name: 'Serum Magnesium',
      category: 'Chemistry',
      testCode: 'MG',
      specimenType: 'blood',
      clinicalIndication: 'Muscle, nerve function',
    ),
    LabTestTemplate(
      name: 'Serum Phosphorus',
      category: 'Chemistry',
      testCode: 'PHOS',
      specimenType: 'blood',
      clinicalIndication: 'Bone health, kidney function',
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
    ),
    LabTestTemplate(
      name: 'ALT (SGPT)',
      category: 'Hepatic',
      testCode: 'ALT',
      specimenType: 'blood',
      clinicalIndication: 'Liver enzyme',
    ),
    LabTestTemplate(
      name: 'AST (SGOT)',
      category: 'Hepatic',
      testCode: 'AST',
      specimenType: 'blood',
      clinicalIndication: 'Liver enzyme',
    ),
    LabTestTemplate(
      name: 'Alkaline Phosphatase (ALP)',
      category: 'Hepatic',
      testCode: 'ALP',
      specimenType: 'blood',
      clinicalIndication: 'Liver, bone disease',
    ),
    LabTestTemplate(
      name: 'Gamma GT (GGT)',
      category: 'Hepatic',
      testCode: 'GGT',
      specimenType: 'blood',
      clinicalIndication: 'Liver, bile duct',
    ),
    LabTestTemplate(
      name: 'Serum Bilirubin (Total & Direct)',
      category: 'Hepatic',
      testCode: 'BILI',
      specimenType: 'blood',
      clinicalIndication: 'Jaundice, liver function',
    ),
    LabTestTemplate(
      name: 'Serum Albumin',
      category: 'Hepatic',
      testCode: 'ALB',
      specimenType: 'blood',
      clinicalIndication: 'Liver synthetic function',
    ),
    LabTestTemplate(
      name: 'Total Protein',
      category: 'Hepatic',
      testCode: 'TP',
      specimenType: 'blood',
      clinicalIndication: 'Nutritional status, liver',
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
    ),
    LabTestTemplate(
      name: 'Serum Creatinine',
      category: 'Renal',
      testCode: 'CREAT',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function',
    ),
    LabTestTemplate(
      name: 'Blood Urea Nitrogen (BUN)',
      category: 'Renal',
      testCode: 'BUN',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function',
    ),
    LabTestTemplate(
      name: 'Serum Uric Acid',
      category: 'Renal',
      testCode: 'UA',
      specimenType: 'blood',
      clinicalIndication: 'Gout, kidney stones',
    ),
    LabTestTemplate(
      name: 'eGFR (Estimated GFR)',
      category: 'Renal',
      testCode: 'EGFR',
      specimenType: 'blood',
      clinicalIndication: 'Kidney function staging',
    ),
    LabTestTemplate(
      name: 'Urine Creatinine Clearance',
      category: 'Renal',
      testCode: 'CR-CL',
      specimenType: 'urine',
      clinicalIndication: 'Kidney function',
      notes: '24-hour urine collection required',
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
    ),
    LabTestTemplate(
      name: 'Random Blood Glucose (RBG)',
      category: 'Diabetes',
      testCode: 'RBG',
      specimenType: 'blood',
      clinicalIndication: 'Immediate glucose assessment',
    ),
    LabTestTemplate(
      name: 'HbA1c (Glycated Hemoglobin)',
      category: 'Diabetes',
      testCode: 'HBA1C',
      specimenType: 'blood',
      clinicalIndication: '3-month glucose control',
    ),
    LabTestTemplate(
      name: 'Oral Glucose Tolerance Test (OGTT)',
      category: 'Diabetes',
      testCode: 'OGTT',
      specimenType: 'blood',
      clinicalIndication: 'Diabetes diagnosis',
      notes: '75g glucose load, 2-hour test',
    ),
    LabTestTemplate(
      name: 'Fasting Insulin',
      category: 'Diabetes',
      testCode: 'INS',
      specimenType: 'blood',
      clinicalIndication: 'Insulin resistance',
    ),
    LabTestTemplate(
      name: 'C-Peptide',
      category: 'Diabetes',
      testCode: 'CPEP',
      specimenType: 'blood',
      clinicalIndication: 'Insulin production assessment',
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
    ),
    LabTestTemplate(
      name: 'HDL Cholesterol',
      category: 'Lipids',
      testCode: 'HDL',
      specimenType: 'blood',
      clinicalIndication: 'Good cholesterol level',
    ),
    LabTestTemplate(
      name: 'LDL Cholesterol',
      category: 'Lipids',
      testCode: 'LDL',
      specimenType: 'blood',
      clinicalIndication: 'Bad cholesterol level',
    ),
    LabTestTemplate(
      name: 'Triglycerides',
      category: 'Lipids',
      testCode: 'TG',
      specimenType: 'blood',
      clinicalIndication: 'Lipid assessment',
    ),
    LabTestTemplate(
      name: 'VLDL Cholesterol',
      category: 'Lipids',
      testCode: 'VLDL',
      specimenType: 'blood',
      clinicalIndication: 'Lipid assessment',
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
    ),
    LabTestTemplate(
      name: 'Free T4 (FT4)',
      category: 'Endocrine',
      testCode: 'FT4',
      specimenType: 'blood',
      clinicalIndication: 'Thyroid hormone level',
    ),
    LabTestTemplate(
      name: 'Free T3 (FT3)',
      category: 'Endocrine',
      testCode: 'FT3',
      specimenType: 'blood',
      clinicalIndication: 'Active thyroid hormone',
    ),
    LabTestTemplate(
      name: 'Anti-TPO Antibodies',
      category: 'Endocrine',
      testCode: 'TPO-AB',
      specimenType: 'blood',
      clinicalIndication: 'Autoimmune thyroid disease',
    ),
    LabTestTemplate(
      name: 'Thyroglobulin',
      category: 'Endocrine',
      testCode: 'TG',
      specimenType: 'blood',
      clinicalIndication: 'Thyroid cancer monitoring',
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
    ),
    LabTestTemplate(
      name: 'Troponin T',
      category: 'Cardiac',
      testCode: 'TROP-T',
      specimenType: 'blood',
      urgency: 'urgent',
      clinicalIndication: 'Acute MI diagnosis',
    ),
    LabTestTemplate(
      name: 'CK-MB',
      category: 'Cardiac',
      testCode: 'CKMB',
      specimenType: 'blood',
      clinicalIndication: 'Cardiac muscle damage',
    ),
    LabTestTemplate(
      name: 'BNP (B-type Natriuretic Peptide)',
      category: 'Cardiac',
      testCode: 'BNP',
      specimenType: 'blood',
      clinicalIndication: 'Heart failure marker',
    ),
    LabTestTemplate(
      name: 'NT-proBNP',
      category: 'Cardiac',
      testCode: 'NTPROBNP',
      specimenType: 'blood',
      clinicalIndication: 'Heart failure assessment',
    ),
    LabTestTemplate(
      name: 'High Sensitivity CRP (hs-CRP)',
      category: 'Cardiac',
      testCode: 'HSCRP',
      specimenType: 'blood',
      clinicalIndication: 'Cardiovascular inflammation',
    ),
    LabTestTemplate(
      name: 'Homocysteine',
      category: 'Cardiac',
      testCode: 'HCYS',
      specimenType: 'blood',
      clinicalIndication: 'Cardiovascular risk factor',
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
    ),
    LabTestTemplate(
      name: 'aPTT (Activated Partial Thromboplastin Time)',
      category: 'Coagulation',
      testCode: 'APTT',
      specimenType: 'blood',
      clinicalIndication: 'Heparin monitoring, bleeding disorders',
    ),
    LabTestTemplate(
      name: 'D-Dimer',
      category: 'Coagulation',
      testCode: 'DDIMER',
      specimenType: 'blood',
      clinicalIndication: 'DVT/PE screening',
    ),
    LabTestTemplate(
      name: 'Fibrinogen',
      category: 'Coagulation',
      testCode: 'FIB',
      specimenType: 'blood',
      clinicalIndication: 'Clotting factor assessment',
    ),
    LabTestTemplate(
      name: 'Bleeding Time',
      category: 'Coagulation',
      testCode: 'BT',
      specimenType: 'blood',
      clinicalIndication: 'Platelet function',
    ),
    LabTestTemplate(
      name: 'Clotting Time',
      category: 'Coagulation',
      testCode: 'CT',
      specimenType: 'blood',
      clinicalIndication: 'Pre-operative screening',
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
      name: 'Urine Protein',
      category: 'Urine',
      testCode: 'UP',
      specimenType: 'urine',
      clinicalIndication: 'Kidney disease',
    ),
    LabTestTemplate(
      name: 'Urine Albumin/Creatinine Ratio (UACR)',
      category: 'Urine',
      testCode: 'UACR',
      specimenType: 'urine',
      clinicalIndication: 'Diabetic nephropathy screening',
    ),
    LabTestTemplate(
      name: '24-Hour Urine Protein',
      category: 'Urine',
      testCode: '24HR-UP',
      specimenType: 'urine',
      clinicalIndication: 'Proteinuria quantification',
      notes: '24-hour collection required',
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
      name: 'Dengue IgM/IgG',
      category: 'Infectious',
      testCode: 'DENGUE-AB',
      specimenType: 'blood',
      clinicalIndication: 'Dengue serology',
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
      name: 'Typhoid (Widal Test)',
      category: 'Infectious',
      testCode: 'WIDAL',
      specimenType: 'blood',
      clinicalIndication: 'Typhoid fever screening',
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
    LabTestTemplate(
      name: 'Tuberculosis (GeneXpert)',
      category: 'Infectious',
      testCode: 'TB-GENEX',
      specimenType: 'other',
      clinicalIndication: 'TB diagnosis',
      notes: 'Sputum sample required',
    ),
  ];

  // ==================== Hormone Tests ====================
  static const List<LabTestTemplate> hormones = [
    LabTestTemplate(
      name: 'Vitamin D (25-OH)',
      category: 'Vitamins',
      testCode: 'VIT-D',
      specimenType: 'blood',
      clinicalIndication: 'Vitamin D deficiency',
    ),
    LabTestTemplate(
      name: 'Vitamin B12',
      category: 'Vitamins',
      testCode: 'VIT-B12',
      specimenType: 'blood',
      clinicalIndication: 'Anemia, neuropathy',
    ),
    LabTestTemplate(
      name: 'Folate (Folic Acid)',
      category: 'Vitamins',
      testCode: 'FOLATE',
      specimenType: 'blood',
      clinicalIndication: 'Anemia, pregnancy',
    ),
    LabTestTemplate(
      name: 'Serum Iron',
      category: 'Vitamins',
      testCode: 'FE',
      specimenType: 'blood',
      clinicalIndication: 'Iron deficiency',
    ),
    LabTestTemplate(
      name: 'Ferritin',
      category: 'Vitamins',
      testCode: 'FERR',
      specimenType: 'blood',
      clinicalIndication: 'Iron stores assessment',
    ),
    LabTestTemplate(
      name: 'TIBC (Total Iron Binding Capacity)',
      category: 'Vitamins',
      testCode: 'TIBC',
      specimenType: 'blood',
      clinicalIndication: 'Iron deficiency anemia',
    ),
    LabTestTemplate(
      name: 'Prolactin',
      category: 'Hormones',
      testCode: 'PRL',
      specimenType: 'blood',
      clinicalIndication: 'Pituitary assessment',
    ),
    LabTestTemplate(
      name: 'Cortisol (AM)',
      category: 'Hormones',
      testCode: 'CORT-AM',
      specimenType: 'blood',
      clinicalIndication: 'Adrenal function',
      notes: 'Morning sample (8-10 AM)',
    ),
    LabTestTemplate(
      name: 'Testosterone',
      category: 'Hormones',
      testCode: 'TEST',
      specimenType: 'blood',
      clinicalIndication: 'Male hypogonadism',
    ),
    LabTestTemplate(
      name: 'Estradiol',
      category: 'Hormones',
      testCode: 'E2',
      specimenType: 'blood',
      clinicalIndication: 'Female hormone assessment',
    ),
    LabTestTemplate(
      name: 'FSH (Follicle Stimulating Hormone)',
      category: 'Hormones',
      testCode: 'FSH',
      specimenType: 'blood',
      clinicalIndication: 'Fertility, menopause',
    ),
    LabTestTemplate(
      name: 'LH (Luteinizing Hormone)',
      category: 'Hormones',
      testCode: 'LH',
      specimenType: 'blood',
      clinicalIndication: 'Fertility assessment',
    ),
    LabTestTemplate(
      name: 'Beta HCG',
      category: 'Hormones',
      testCode: 'BHCG',
      specimenType: 'blood',
      clinicalIndication: 'Pregnancy confirmation',
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
    ),
    LabTestTemplate(
      name: 'CA-125',
      category: 'Tumor Markers',
      testCode: 'CA125',
      specimenType: 'blood',
      clinicalIndication: 'Ovarian cancer marker',
    ),
    LabTestTemplate(
      name: 'CA 19-9',
      category: 'Tumor Markers',
      testCode: 'CA199',
      specimenType: 'blood',
      clinicalIndication: 'Pancreatic cancer marker',
    ),
    LabTestTemplate(
      name: 'CEA (Carcinoembryonic Antigen)',
      category: 'Tumor Markers',
      testCode: 'CEA',
      specimenType: 'blood',
      clinicalIndication: 'Colorectal cancer marker',
    ),
    LabTestTemplate(
      name: 'AFP (Alpha-Fetoprotein)',
      category: 'Tumor Markers',
      testCode: 'AFP',
      specimenType: 'blood',
      clinicalIndication: 'Liver cancer, prenatal screening',
    ),
  ];

  // ==================== Stool Tests ====================
  static const List<LabTestTemplate> stoolTests = [
    LabTestTemplate(
      name: 'Stool Routine & Microscopy',
      category: 'Stool',
      testCode: 'ST-RM',
      specimenType: 'stool',
      clinicalIndication: 'GI infection, parasites',
    ),
    LabTestTemplate(
      name: 'Stool Occult Blood',
      category: 'Stool',
      testCode: 'FOB',
      specimenType: 'stool',
      clinicalIndication: 'GI bleeding, colon cancer screening',
    ),
    LabTestTemplate(
      name: 'Stool Culture & Sensitivity',
      category: 'Stool',
      testCode: 'SC-S',
      specimenType: 'stool',
      clinicalIndication: 'Bacterial diarrhea',
    ),
    LabTestTemplate(
      name: 'H. Pylori Stool Antigen',
      category: 'Stool',
      testCode: 'HP-AG',
      specimenType: 'stool',
      clinicalIndication: 'H. pylori infection',
    ),
  ];

  // ==================== Quick Fill Panels ====================
  static const List<LabTestPanel> quickPanels = [
    // Routine Health Checkup Panel
    LabTestPanel(
      name: 'Routine Health Checkup',
      description: 'Basic screening tests for annual health assessment',
      clinicalIndication: 'Annual health checkup',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Fasting Blood Glucose (FBG)', category: 'Diabetes', testCode: 'FBG', specimenType: 'blood'),
        LabTestTemplate(name: 'Lipid Panel (Complete)', category: 'Lipids', testCode: 'LIPID', specimenType: 'blood'),
        LabTestTemplate(name: 'Liver Function Tests (LFT)', category: 'Hepatic', testCode: 'LFT', specimenType: 'blood'),
        LabTestTemplate(name: 'Renal Function Tests (RFT)', category: 'Renal', testCode: 'RFT', specimenType: 'blood'),
        LabTestTemplate(name: 'Urinalysis (Complete)', category: 'Urine', testCode: 'UA-COMP', specimenType: 'urine'),
      ],
    ),
    // Diabetic Panel
    LabTestPanel(
      name: 'Diabetic Workup',
      description: 'Complete tests for diabetic patients',
      clinicalIndication: 'Diabetes monitoring/screening',
      tests: [
        LabTestTemplate(name: 'Fasting Blood Glucose (FBG)', category: 'Diabetes', testCode: 'FBG', specimenType: 'blood'),
        LabTestTemplate(name: 'HbA1c (Glycated Hemoglobin)', category: 'Diabetes', testCode: 'HBA1C', specimenType: 'blood'),
        LabTestTemplate(name: 'Lipid Panel (Complete)', category: 'Lipids', testCode: 'LIPID', specimenType: 'blood'),
        LabTestTemplate(name: 'Renal Function Tests (RFT)', category: 'Renal', testCode: 'RFT', specimenType: 'blood'),
        LabTestTemplate(name: 'Urine Albumin/Creatinine Ratio (UACR)', category: 'Urine', testCode: 'UACR', specimenType: 'urine'),
      ],
    ),
    // Cardiac Panel
    LabTestPanel(
      name: 'Cardiac Risk Assessment',
      description: 'Tests for cardiovascular risk evaluation',
      clinicalIndication: 'Cardiac risk assessment',
      tests: [
        LabTestTemplate(name: 'Lipid Panel (Complete)', category: 'Lipids', testCode: 'LIPID', specimenType: 'blood'),
        LabTestTemplate(name: 'High Sensitivity CRP (hs-CRP)', category: 'Cardiac', testCode: 'HSCRP', specimenType: 'blood'),
        LabTestTemplate(name: 'Fasting Blood Glucose (FBG)', category: 'Diabetes', testCode: 'FBG', specimenType: 'blood'),
        LabTestTemplate(name: 'HbA1c (Glycated Hemoglobin)', category: 'Diabetes', testCode: 'HBA1C', specimenType: 'blood'),
        LabTestTemplate(name: 'Renal Function Tests (RFT)', category: 'Renal', testCode: 'RFT', specimenType: 'blood'),
      ],
    ),
    // Thyroid Panel
    LabTestPanel(
      name: 'Thyroid Assessment',
      description: 'Complete thyroid function evaluation',
      clinicalIndication: 'Thyroid disorder workup',
      tests: [
        LabTestTemplate(name: 'TSH (Thyroid Stimulating Hormone)', category: 'Endocrine', testCode: 'TSH', specimenType: 'blood'),
        LabTestTemplate(name: 'Free T4 (FT4)', category: 'Endocrine', testCode: 'FT4', specimenType: 'blood'),
        LabTestTemplate(name: 'Free T3 (FT3)', category: 'Endocrine', testCode: 'FT3', specimenType: 'blood'),
        LabTestTemplate(name: 'Anti-TPO Antibodies', category: 'Endocrine', testCode: 'TPO-AB', specimenType: 'blood'),
      ],
    ),
    // Anemia Panel
    LabTestPanel(
      name: 'Anemia Workup',
      description: 'Tests for anemia evaluation',
      clinicalIndication: 'Anemia diagnosis and classification',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Serum Iron', category: 'Vitamins', testCode: 'FE', specimenType: 'blood'),
        LabTestTemplate(name: 'Ferritin', category: 'Vitamins', testCode: 'FERR', specimenType: 'blood'),
        LabTestTemplate(name: 'TIBC (Total Iron Binding Capacity)', category: 'Vitamins', testCode: 'TIBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Vitamin B12', category: 'Vitamins', testCode: 'VIT-B12', specimenType: 'blood'),
        LabTestTemplate(name: 'Folate (Folic Acid)', category: 'Vitamins', testCode: 'FOLATE', specimenType: 'blood'),
      ],
    ),
    // Liver Disease Panel
    LabTestPanel(
      name: 'Liver Disease Workup',
      description: 'Comprehensive liver assessment',
      clinicalIndication: 'Liver disease evaluation',
      tests: [
        LabTestTemplate(name: 'Liver Function Tests (LFT)', category: 'Hepatic', testCode: 'LFT', specimenType: 'blood'),
        LabTestTemplate(name: 'Hepatitis B Surface Antigen (HBsAg)', category: 'Infectious', testCode: 'HBSAG', specimenType: 'blood'),
        LabTestTemplate(name: 'Hepatitis C Antibody (Anti-HCV)', category: 'Infectious', testCode: 'HCV-AB', specimenType: 'blood'),
        LabTestTemplate(name: 'PT/INR', category: 'Coagulation', testCode: 'PT-INR', specimenType: 'blood'),
        LabTestTemplate(name: 'Serum Albumin', category: 'Hepatic', testCode: 'ALB', specimenType: 'blood'),
      ],
    ),
    // Pre-Operative Panel
    LabTestPanel(
      name: 'Pre-Operative Assessment',
      description: 'Tests required before surgery',
      clinicalIndication: 'Pre-surgical evaluation',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'PT/INR', category: 'Coagulation', testCode: 'PT-INR', specimenType: 'blood'),
        LabTestTemplate(name: 'aPTT (Activated Partial Thromboplastin Time)', category: 'Coagulation', testCode: 'APTT', specimenType: 'blood'),
        LabTestTemplate(name: 'Blood Group & Rh Factor', category: 'Hematology', testCode: 'BG-RH', specimenType: 'blood'),
        LabTestTemplate(name: 'Hepatitis B Surface Antigen (HBsAg)', category: 'Infectious', testCode: 'HBSAG', specimenType: 'blood'),
        LabTestTemplate(name: 'Hepatitis C Antibody (Anti-HCV)', category: 'Infectious', testCode: 'HCV-AB', specimenType: 'blood'),
        LabTestTemplate(name: 'Fasting Blood Glucose (FBG)', category: 'Diabetes', testCode: 'FBG', specimenType: 'blood'),
        LabTestTemplate(name: 'Renal Function Tests (RFT)', category: 'Renal', testCode: 'RFT', specimenType: 'blood'),
      ],
    ),
    // Pregnancy Panel
    LabTestPanel(
      name: 'Pregnancy Workup',
      description: 'Tests for antenatal assessment',
      clinicalIndication: 'Antenatal screening',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Blood Group & Rh Factor', category: 'Hematology', testCode: 'BG-RH', specimenType: 'blood'),
        LabTestTemplate(name: 'Fasting Blood Glucose (FBG)', category: 'Diabetes', testCode: 'FBG', specimenType: 'blood'),
        LabTestTemplate(name: 'Urinalysis (Complete)', category: 'Urine', testCode: 'UA-COMP', specimenType: 'urine'),
        LabTestTemplate(name: 'Hepatitis B Surface Antigen (HBsAg)', category: 'Infectious', testCode: 'HBSAG', specimenType: 'blood'),
        LabTestTemplate(name: 'HIV Screening Test', category: 'Infectious', testCode: 'HIV', specimenType: 'blood'),
        LabTestTemplate(name: 'TSH (Thyroid Stimulating Hormone)', category: 'Endocrine', testCode: 'TSH', specimenType: 'blood'),
      ],
    ),
    // Fever Workup Panel
    LabTestPanel(
      name: 'Fever Workup',
      description: 'Tests for pyrexia of unknown origin',
      clinicalIndication: 'Fever evaluation',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Malaria Parasite (MP)', category: 'Infectious', testCode: 'MP', specimenType: 'blood'),
        LabTestTemplate(name: 'Typhidot (IgM/IgG)', category: 'Infectious', testCode: 'TYPHIDOT', specimenType: 'blood'),
        LabTestTemplate(name: 'Dengue NS1 Antigen', category: 'Infectious', testCode: 'DENGUE-NS1', specimenType: 'blood'),
        LabTestTemplate(name: 'Urine Culture & Sensitivity', category: 'Urine', testCode: 'UC-S', specimenType: 'urine'),
      ],
    ),
    // Arthritis Panel
    LabTestPanel(
      name: 'Arthritis Workup',
      description: 'Tests for joint disease evaluation',
      clinicalIndication: 'Arthritis/joint pain workup',
      tests: [
        LabTestTemplate(name: 'Complete Blood Count (CBC)', category: 'Hematology', testCode: 'CBC', specimenType: 'blood'),
        LabTestTemplate(name: 'Erythrocyte Sedimentation Rate (ESR)', category: 'Hematology', testCode: 'ESR', specimenType: 'blood'),
        LabTestTemplate(name: 'High Sensitivity CRP (hs-CRP)', category: 'Cardiac', testCode: 'HSCRP', specimenType: 'blood'),
        LabTestTemplate(name: 'Serum Uric Acid', category: 'Renal', testCode: 'UA', specimenType: 'blood'),
        LabTestTemplate(name: 'Rheumatoid Factor (RF)', category: 'Immunology', testCode: 'RF', specimenType: 'blood'),
      ],
    ),
  ];

  // Category grouping for UI
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
    'Hormones & Vitamins': hormones,
    'Tumor Markers': tumorMarkers,
    'Stool Tests': stoolTests,
  };

  // Get all tests flat list
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
    ...hormones,
    ...tumorMarkers,
    ...stoolTests,
  ];

  // Search tests by name
  static List<LabTestTemplate> searchTests(String query) {
    final lowerQuery = query.toLowerCase();
    return allTests.where((test) =>
      test.name.toLowerCase().contains(lowerQuery) ||
      test.category.toLowerCase().contains(lowerQuery) ||
      (test.testCode?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}

// ==================== Lab Test Template Bottom Sheet Widget ====================

class LabTestTemplateBottomSheet extends StatefulWidget {
  const LabTestTemplateBottomSheet({
    required this.onSelect,
    this.onSelectPanel,
    this.onSelectMultiple,
    super.key,
  });

  final void Function(LabTestTemplate) onSelect;
  final void Function(LabTestPanel)? onSelectPanel;
  final void Function(List<LabTestTemplate>)? onSelectMultiple;

  @override
  State<LabTestTemplateBottomSheet> createState() => _LabTestTemplateBottomSheetState();
}

class _LabTestTemplateBottomSheetState extends State<LabTestTemplateBottomSheet> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showPanels = true;
  final Set<String> _selectedTests = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = LabTestTemplates.allCategories;
    
    List<LabTestTemplate> displayTemplates;
    if (_searchQuery.isNotEmpty) {
      displayTemplates = LabTestTemplates.searchTests(_searchQuery);
    } else if (_selectedCategory != null) {
      displayTemplates = categories[_selectedCategory] ?? [];
    } else {
      displayTemplates = [];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science,
                  color: Color(0xFFEC4899),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lab Test Templates',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Quick add common lab tests',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search box
          AppInput.search(
            hint: 'Search lab tests...',
            onChanged: (value) => setState(() {
              _searchQuery = value;
              if (value.isNotEmpty) {
                _selectedCategory = null;
                _showPanels = false;
              }
            }),
          ),
          const SizedBox(height: 16),
          
          // Toggle for Panels vs Individual Tests
          if (_searchQuery.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    'Quick Panels',
                    Icons.dashboard,
                    _showPanels,
                    () => setState(() {
                      _showPanels = true;
                      _selectedCategory = null;
                    }),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    'Individual Tests',
                    Icons.list,
                    !_showPanels,
                    () => setState(() {
                      _showPanels = false;
                    }),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Category chips (only for individual tests)
          if (_searchQuery.isEmpty && !_showPanels) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categories.keys.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) => setState(() {
                        _selectedCategory = selected ? category : null;
                      }),
                      selectedColor: const Color(0xFFEC4899),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Add Selected button (for multi-select)
          if (!_showPanels && _selectedTests.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Get all selected templates
                      final allTemplates = _searchQuery.isNotEmpty
                          ? LabTestTemplates.searchTests(_searchQuery)
                          : (_selectedCategory != null ? categories[_selectedCategory] ?? [] : <LabTestTemplate>[]);
                      
                      final selectedTemplates = allTemplates
                          .where((t) => _selectedTests.contains(t.name))
                          .toList();
                      
                      if (widget.onSelectMultiple != null) {
                        widget.onSelectMultiple!(selectedTemplates);
                      } else {
                        // Fallback to individual selection
                        for (final template in selectedTemplates) {
                          widget.onSelect(template);
                        }
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: Text('Add ${_selectedTests.length} Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTests.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Content
          Expanded(
            child: _showPanels && _searchQuery.isEmpty
                ? _buildPanelsList(isDark)
                : displayTemplates.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty && _selectedCategory == null
                              ? 'Select a category or search'
                              : 'No tests found',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayTemplates.length,
                        itemBuilder: (context, index) {
                          final template = displayTemplates[index];
                          return _buildTestCard(template, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC4899).withValues(alpha: 0.1)
              : (isDark ? AppColors.darkSurface : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFEC4899) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFFEC4899) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFEC4899) : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelsList(bool isDark) {
    return ListView.builder(
      itemCount: LabTestTemplates.quickPanels.length,
      itemBuilder: (context, index) {
        final panel = LabTestTemplates.quickPanels[index];
        return _buildPanelCard(panel, isDark);
      },
    );
  }

  Widget _buildPanelCard(LabTestPanel panel, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (widget.onSelectPanel != null) {
            widget.onSelectPanel!(panel);
          } else {
            _showPanelDetails(panel);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPanelIcon(panel.name),
                  color: const Color(0xFFEC4899),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      panel.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      panel.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${panel.tests.length} tests included',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFFEC4899),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPanelDetails(LabTestPanel panel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPanelIcon(panel.name),
              color: const Color(0xFFEC4899),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                panel.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                panel.description,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tests in this panel:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...panel.tests.map((test) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              // Return panel to parent
              if (widget.onSelectPanel != null) {
                widget.onSelectPanel!(panel);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
            ),
            child: Text('Select (${panel.tests.length} tests)'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(LabTestTemplate template, bool isDark) {
    final isSelected = _selectedTests.contains(template.name);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? const Color(0xFFEC4899).withValues(alpha: 0.5)
              : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      color: isSelected 
          ? const Color(0xFFEC4899).withValues(alpha: 0.1)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                : const Color(0xFFEC4899).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? Icons.check : _getTestIcon(template.name), 
            color: const Color(0xFFEC4899),
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.testCode != null)
              Text('Code: ${template.testCode}'),
            Text(
              '${template.specimenType[0].toUpperCase()}${template.specimenType.substring(1)} • ${template.category}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedTests.add(template.name);
              } else {
                _selectedTests.remove(template.name);
              }
            });
          },
          activeColor: const Color(0xFFEC4899),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTests.remove(template.name);
            } else {
              _selectedTests.add(template.name);
            }
          });
        },
      ),
    );
  }

  IconData _getTestIcon(String testName) {
    final lower = testName.toLowerCase();
    if (lower.contains('blood') || lower.contains('cbc') || lower.contains('hemoglobin')) {
      return Icons.bloodtype;
    }
    if (lower.contains('urine') || lower.contains('urinal')) return Icons.water_drop;
    if (lower.contains('glucose') || lower.contains('sugar') || lower.contains('hba1c')) {
      return Icons.monitor_heart;
    }
    if (lower.contains('cholesterol') || lower.contains('lipid')) return Icons.favorite;
    if (lower.contains('thyroid') || lower.contains('tsh')) return Icons.biotech;
    if (lower.contains('liver') || lower.contains('hepat') || lower.contains('ast') || lower.contains('alt')) {
      return Icons.medical_services;
    }
    if (lower.contains('kidney') || lower.contains('creatinine') || lower.contains('bun')) {
      return Icons.water_drop;
    }
    if (lower.contains('culture') || lower.contains('bacteria')) return Icons.coronavirus;
    return Icons.science;
  }

  IconData _getPanelIcon(String panelName) {
    final lower = panelName.toLowerCase();
    if (lower.contains('diabetic')) return Icons.monitor_heart;
    if (lower.contains('cardiac')) return Icons.favorite;
    if (lower.contains('thyroid')) return Icons.biotech;
    if (lower.contains('anemia')) return Icons.bloodtype;
    if (lower.contains('liver')) return Icons.medical_services;
    if (lower.contains('operative') || lower.contains('surgery')) return Icons.local_hospital;
    if (lower.contains('pregnancy')) return Icons.pregnant_woman;
    if (lower.contains('fever')) return Icons.thermostat;
    if (lower.contains('arthritis')) return Icons.accessibility_new;
    if (lower.contains('routine') || lower.contains('checkup')) return Icons.health_and_safety;
    return Icons.science;
  }
}
