/// Medical Record Templates Service
/// Provides categorized templates for quick-fill medical records
/// Similar to prescription_templates.dart for medications

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/components/app_input.dart';

// ==================== Template Classes ====================

/// Base template for any medical record type
class MedicalRecordTemplate {
  const MedicalRecordTemplate({
    required this.name,
    required this.recordType,
    required this.category,
    this.description = '',
    this.diagnosis = '',
    this.treatment = '',
    this.notes = '',
    this.data = const {},
  });

  final String name;
  final String recordType; // general, psychiatric_assessment, pulmonary_evaluation, etc.
  final String category;
  final String description;
  final String diagnosis;
  final String treatment;
  final String notes;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'name': name,
    'recordType': recordType,
    'category': category,
    'description': description,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'notes': notes,
    'data': data,
  };
}

// ==================== General Consultation Templates ====================

class GeneralConsultationTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Upper Respiratory Infection',
      recordType: 'general',
      category: 'Infectious',
      description: 'Acute upper respiratory tract infection with cough, cold, sore throat',
      diagnosis: 'Acute Upper Respiratory Tract Infection (URTI)',
      treatment: 'Symptomatic treatment with rest, hydration, antipyretics',
      notes: 'Advised to return if symptoms worsen or persist beyond 7 days',
    ),
    MedicalRecordTemplate(
      name: 'Viral Fever',
      recordType: 'general',
      category: 'Infectious',
      description: 'Acute febrile illness with body aches, fatigue',
      diagnosis: 'Viral Fever',
      treatment: 'Symptomatic treatment, rest, adequate hydration',
      notes: 'Monitor for warning signs. Follow up if fever persists >5 days',
    ),
    MedicalRecordTemplate(
      name: 'Gastroenteritis',
      recordType: 'general',
      category: 'GI',
      description: 'Acute diarrhea and/or vomiting, abdominal cramps',
      diagnosis: 'Acute Gastroenteritis',
      treatment: 'ORS, bland diet, antiemetics PRN',
      notes: 'Watch for dehydration signs. Return if bloody stools or high fever',
    ),
    MedicalRecordTemplate(
      name: 'Hypertension Follow-up',
      recordType: 'general',
      category: 'Cardiovascular',
      description: 'Routine follow-up for hypertension management',
      diagnosis: 'Essential Hypertension - controlled',
      treatment: 'Continue current antihypertensive medications',
      notes: 'BP at target. Continue lifestyle modifications. Review in 3 months',
    ),
    MedicalRecordTemplate(
      name: 'Diabetes Follow-up',
      recordType: 'general',
      category: 'Metabolic',
      description: 'Routine follow-up for diabetes management',
      diagnosis: 'Type 2 Diabetes Mellitus',
      treatment: 'Continue current oral hypoglycemics/insulin',
      notes: 'Review HbA1c results. Reinforce diet and exercise. Check feet',
    ),
    MedicalRecordTemplate(
      name: 'Headache/Migraine',
      recordType: 'general',
      category: 'Neurological',
      description: 'Recurrent headaches, with or without aura',
      diagnosis: 'Migraine without aura',
      treatment: 'Acute: analgesics, triptans PRN. Preventive if frequent',
      notes: 'Maintain headache diary. Avoid triggers. Sleep hygiene',
    ),
    MedicalRecordTemplate(
      name: 'Back Pain',
      recordType: 'general',
      category: 'Musculoskeletal',
      description: 'Lower back pain, mechanical',
      diagnosis: 'Mechanical Low Back Pain',
      treatment: 'NSAIDs, muscle relaxants, physiotherapy referral',
      notes: 'Posture correction, avoid heavy lifting. Red flags discussed',
    ),
    MedicalRecordTemplate(
      name: 'Urinary Tract Infection',
      recordType: 'general',
      category: 'Infectious',
      description: 'Dysuria, frequency, urgency',
      diagnosis: 'Acute Urinary Tract Infection',
      treatment: 'Empirical antibiotics, increased fluid intake',
      notes: 'Complete antibiotic course. Return if symptoms persist',
    ),
    MedicalRecordTemplate(
      name: 'Allergic Rhinitis',
      recordType: 'general',
      category: 'Allergy',
      description: 'Sneezing, nasal congestion, itchy eyes',
      diagnosis: 'Allergic Rhinitis',
      treatment: 'Antihistamines, nasal steroids, allergen avoidance',
      notes: 'Identify and avoid triggers. Consider allergy testing',
    ),
    MedicalRecordTemplate(
      name: 'Skin Rash',
      recordType: 'general',
      category: 'Dermatological',
      description: 'Erythematous rash, pruritus',
      diagnosis: 'Contact Dermatitis / Eczema',
      treatment: 'Topical steroids, emollients, antihistamines',
      notes: 'Identify triggering agent. Moisturize regularly',
    ),
  ];
}

// ==================== Psychiatric Assessment Templates ====================

class PsychiatricTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Major Depressive Episode',
      recordType: 'psychiatric_assessment',
      category: 'Mood Disorders',
      description: 'Persistent low mood, anhedonia, sleep disturbance',
      diagnosis: 'Major Depressive Disorder, single episode, moderate',
      treatment: 'SSRI initiated, psychotherapy referral',
      notes: 'Suicide risk assessed - low. Follow up in 2 weeks',
      data: {
        'symptoms': 'Low mood, anhedonia, insomnia, fatigue, poor concentration',
        'hopi': 'Gradual onset over 4 weeks following job loss',
        'mse': {
          'appearance': 'Casually dressed, poor eye contact',
          'behavior': 'Psychomotor retardation',
          'speech': 'Soft, slow',
          'mood': 'Depressed',
          'affect': 'Constricted, mood-congruent',
          'thought_content': 'Hopelessness, worthlessness',
          'thought_process': 'Linear, goal-directed',
          'perception': 'No hallucinations',
          'cognition': 'Intact',
          'insight': 'Fair',
          'judgment': 'Fair',
        },
        'risk_assessment': {
          'suicidal_risk': 'Low',
          'homicidal_risk': 'None',
          'notes': 'No active SI/HI. Has protective factors',
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Generalized Anxiety Disorder',
      recordType: 'psychiatric_assessment',
      category: 'Anxiety Disorders',
      description: 'Excessive worry, restlessness, physical tension',
      diagnosis: 'Generalized Anxiety Disorder',
      treatment: 'SSRI/SNRI, anxiolytics PRN, CBT referral',
      notes: 'Relaxation techniques discussed. Sleep hygiene',
      data: {
        'symptoms': 'Excessive worry, restlessness, muscle tension, poor sleep',
        'hopi': 'Chronic worry >6 months, worsening with work stress',
        'mse': {
          'appearance': 'Neat, appears anxious',
          'behavior': 'Fidgety, restless',
          'speech': 'Rapid, pressured',
          'mood': 'Anxious',
          'affect': 'Anxious, reactive',
          'thought_content': 'Excessive worry about multiple domains',
          'thought_process': 'Circumstantial at times',
          'perception': 'No hallucinations',
          'cognition': 'Intact but distractible',
          'insight': 'Good',
          'judgment': 'Good',
        },
        'risk_assessment': {
          'suicidal_risk': 'None',
          'homicidal_risk': 'None',
          'notes': 'No SI/HI',
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Panic Disorder',
      recordType: 'psychiatric_assessment',
      category: 'Anxiety Disorders',
      description: 'Recurrent panic attacks, anticipatory anxiety',
      diagnosis: 'Panic Disorder without agoraphobia',
      treatment: 'SSRI, benzodiazepine PRN for acute attacks, CBT',
      notes: 'Breathing exercises taught. Emergency plan discussed',
      data: {
        'symptoms': 'Recurrent panic attacks, palpitations, chest tightness, fear of dying',
        'hopi': 'First attack 3 months ago, now 2-3/week',
        'mse': {
          'appearance': 'Appropriate',
          'behavior': 'Mildly anxious',
          'speech': 'Normal',
          'mood': 'Anxious',
          'affect': 'Anxious',
          'thought_content': 'Fear of having another attack',
          'thought_process': 'Logical',
          'perception': 'No abnormalities',
          'cognition': 'Intact',
          'insight': 'Good',
          'judgment': 'Good',
        },
        'risk_assessment': {
          'suicidal_risk': 'None',
          'homicidal_risk': 'None',
          'notes': 'No SI/HI. Low risk',
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Bipolar Disorder - Manic Episode',
      recordType: 'psychiatric_assessment',
      category: 'Mood Disorders',
      description: 'Elevated mood, decreased sleep, increased activity',
      diagnosis: 'Bipolar I Disorder, current episode manic',
      treatment: 'Mood stabilizer + antipsychotic, hospitalization if needed',
      notes: 'High risk behavior discussed with family. Close monitoring',
      data: {
        'symptoms': 'Elevated mood, decreased need for sleep, racing thoughts, increased spending',
        'hopi': 'Symptoms escalating over 1 week, stopped medications 2 weeks ago',
        'mse': {
          'appearance': 'Flamboyant dress, makeup',
          'behavior': 'Hyperactive, distractible',
          'speech': 'Rapid, pressured, loud',
          'mood': 'Euphoric',
          'affect': 'Expansive, labile',
          'thought_content': 'Grandiose ideas',
          'thought_process': 'Flight of ideas',
          'perception': 'No hallucinations',
          'cognition': 'Distractible',
          'insight': 'Poor',
          'judgment': 'Poor',
        },
        'risk_assessment': {
          'suicidal_risk': 'Low',
          'homicidal_risk': 'None',
          'notes': 'Risk of impulsive behavior high',
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Schizophrenia - Stable',
      recordType: 'psychiatric_assessment',
      category: 'Psychotic Disorders',
      description: 'Chronic schizophrenia, on maintenance treatment',
      diagnosis: 'Schizophrenia, paranoid type, in remission',
      treatment: 'Continue current antipsychotic',
      notes: 'No active symptoms. Maintain follow-up and medication adherence',
      data: {
        'symptoms': 'No active positive symptoms. Some negative symptoms persist',
        'hopi': 'Stable on current medication for 6 months',
        'mse': {
          'appearance': 'Appropriate',
          'behavior': 'Calm, cooperative',
          'speech': 'Normal rate and volume',
          'mood': 'Euthymic',
          'affect': 'Mildly blunted',
          'thought_content': 'No delusions',
          'thought_process': 'Linear',
          'perception': 'No hallucinations',
          'cognition': 'Grossly intact',
          'insight': 'Fair',
          'judgment': 'Fair',
        },
        'risk_assessment': {
          'suicidal_risk': 'Low',
          'homicidal_risk': 'None',
          'notes': 'Stable, no active symptoms. Continue monitoring',
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Insomnia',
      recordType: 'psychiatric_assessment',
      category: 'Sleep Disorders',
      description: 'Difficulty initiating and/or maintaining sleep',
      diagnosis: 'Primary Insomnia',
      treatment: 'Sleep hygiene, CBT-I, short-term hypnotic if needed',
      notes: 'Sleep diary started. Avoid caffeine, screen time before bed',
      data: {
        'symptoms': 'Difficulty falling asleep, frequent awakenings, daytime fatigue',
        'hopi': 'Chronic insomnia >3 months, worse with stress',
        'mse': {
          'appearance': 'Tired appearing',
          'behavior': 'Cooperative',
          'speech': 'Normal',
          'mood': 'Tired, frustrated',
          'affect': 'Appropriate',
          'thought_content': 'Worry about sleep',
          'thought_process': 'Logical',
          'perception': 'Normal',
          'cognition': 'Intact',
          'insight': 'Good',
          'judgment': 'Good',
        },
        'risk_assessment': {
          'suicidal_risk': 'None',
          'homicidal_risk': 'None',
          'notes': 'No psychiatric comorbidity. Low risk',
        },
      },
    ),
  ];
}

// ==================== Pulmonary Evaluation Templates ====================

class PulmonaryTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Asthma - Acute Exacerbation',
      recordType: 'pulmonary_evaluation',
      category: 'Obstructive',
      description: 'Wheezing, breathlessness, cough',
      diagnosis: 'Bronchial Asthma - Acute Exacerbation',
      treatment: 'Bronchodilators, systemic steroids, oxygen PRN',
      notes: 'Peak flow monitoring. Action plan reviewed',
      data: {
        'chief_complaint': 'Breathlessness and wheezing',
        'duration': '2 days',
        'symptom_character': 'Episodic, worse at night and with exertion',
        'systemic_symptoms': ['Cough', 'Chest tightness'],
        'red_flags': <String>[],
        'chest_auscultation': {
          'breath_sounds': 'Bilateral wheeze',
          'added_sounds': ['Expiratory wheeze'],
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'COPD - Stable',
      recordType: 'pulmonary_evaluation',
      category: 'Obstructive',
      description: 'Chronic productive cough, exertional dyspnea',
      diagnosis: 'Chronic Obstructive Pulmonary Disease - GOLD II',
      treatment: 'Continue LABA/LAMA inhalers, PRN SABA',
      notes: 'Smoking cessation counseling. Pulmonary rehab referral',
      data: {
        'chief_complaint': 'Chronic cough with sputum, breathlessness on exertion',
        'duration': 'Chronic, years',
        'symptom_character': 'Progressive dyspnea, productive cough',
        'systemic_symptoms': ['Fatigue'],
        'past_pulmonary_history': 'Known COPD, ex-smoker 20 pack-years',
        'chest_auscultation': {
          'breath_sounds': 'Reduced bilaterally',
          'added_sounds': ['Scattered rhonchi'],
        },
      },
    ),
    MedicalRecordTemplate(
      name: 'Community Acquired Pneumonia',
      recordType: 'pulmonary_evaluation',
      category: 'Infectious',
      description: 'Fever, cough with sputum, pleuritic chest pain',
      diagnosis: 'Community Acquired Pneumonia',
      treatment: 'Empirical antibiotics, supportive care',
      notes: 'Chest X-ray ordered. Watch for deterioration',
      data: {
        'chief_complaint': 'Fever, cough with yellowish sputum',
        'duration': '5 days',
        'symptom_character': 'High grade fever, productive cough, right-sided chest pain',
        'systemic_symptoms': ['Fever', 'Malaise', 'Loss of appetite'],
        'red_flags': ['High fever', 'Tachypnea'],
        'chest_auscultation': {
          'breath_sounds': 'Bronchial breathing right lower zone',
          'added_sounds': ['Crepitations'],
          'right_lower_zone': 'Bronchial breathing, crepitations',
        },
        'investigations_required': ['Chest X-ray', 'CBC', 'Sputum C/S'],
      },
    ),
    MedicalRecordTemplate(
      name: 'Pulmonary Tuberculosis',
      recordType: 'pulmonary_evaluation',
      category: 'Infectious',
      description: 'Chronic cough, weight loss, night sweats',
      diagnosis: 'Pulmonary Tuberculosis',
      treatment: 'ATT as per DOTS protocol',
      notes: 'Contact tracing initiated. DOTS enrollment',
      data: {
        'chief_complaint': 'Cough >2 weeks, evening fever, weight loss',
        'duration': '6 weeks',
        'symptom_character': 'Productive cough, hemoptysis, night sweats',
        'systemic_symptoms': ['Fever', 'Night sweats', 'Weight loss', 'Anorexia'],
        'red_flags': ['Hemoptysis'],
        'past_pulmonary_history': 'No previous TB',
        'chest_auscultation': {
          'breath_sounds': 'Reduced right upper zone',
          'added_sounds': ['Post-tussive crepitations'],
        },
        'investigations_required': ['Chest X-ray', 'Sputum AFB x3', 'GeneXpert'],
      },
    ),
    MedicalRecordTemplate(
      name: 'Pleural Effusion',
      recordType: 'pulmonary_evaluation',
      category: 'Pleural',
      description: 'Breathlessness, dullness on percussion',
      diagnosis: 'Pleural Effusion - for evaluation',
      treatment: 'Diagnostic thoracentesis, treat underlying cause',
      notes: 'Work up for etiology - TB, malignancy, cardiac',
      data: {
        'chief_complaint': 'Progressive breathlessness',
        'duration': '2 weeks',
        'symptom_character': 'Gradually worsening dyspnea, dry cough',
        'systemic_symptoms': ['Fatigue'],
        'chest_auscultation': {
          'breath_sounds': 'Absent right base',
          'added_sounds': <String>[],
          'right_lower_zone': 'Stony dull, absent breath sounds',
        },
        'investigations_required': ['Chest X-ray', 'Pleural fluid analysis', 'CT Chest'],
      },
    ),
  ];
}

// ==================== Lab Result Templates ====================

class LabResultTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'CBC - Normal',
      recordType: 'lab_result',
      category: 'Hematology',
      description: 'Complete blood count within normal limits',
      diagnosis: 'Normal CBC',
      notes: 'All parameters within reference range',
      data: {
        'test_name': 'Complete Blood Count (CBC)',
        'result': 'WBC: 7.5, Hb: 14.0, Plt: 250',
        'reference_range': 'WBC: 4-11, Hb: 12-16, Plt: 150-400',
      },
    ),
    MedicalRecordTemplate(
      name: 'Anemia - Iron Deficiency',
      recordType: 'lab_result',
      category: 'Hematology',
      description: 'Microcytic hypochromic anemia',
      diagnosis: 'Iron Deficiency Anemia',
      treatment: 'Iron supplementation',
      data: {
        'test_name': 'CBC with Iron Studies',
        'result': 'Hb: 9.5, MCV: 68, Ferritin: 8',
        'reference_range': 'Hb: 12-16, MCV: 80-100, Ferritin: 12-150',
      },
    ),
    MedicalRecordTemplate(
      name: 'Diabetes - Uncontrolled',
      recordType: 'lab_result',
      category: 'Metabolic',
      description: 'Elevated HbA1c indicating poor glycemic control',
      diagnosis: 'Type 2 DM - Uncontrolled',
      treatment: 'Intensify treatment, diet counseling',
      data: {
        'test_name': 'HbA1c',
        'result': 'HbA1c: 9.2%',
        'reference_range': 'Target <7%',
      },
    ),
    MedicalRecordTemplate(
      name: 'Lipid Profile - Dyslipidemia',
      recordType: 'lab_result',
      category: 'Metabolic',
      description: 'Elevated LDL cholesterol',
      diagnosis: 'Dyslipidemia',
      treatment: 'Statin therapy, lifestyle modifications',
      data: {
        'test_name': 'Lipid Panel',
        'result': 'TC: 265, LDL: 180, HDL: 35, TG: 250',
        'reference_range': 'TC <200, LDL <100, HDL >40, TG <150',
      },
    ),
    MedicalRecordTemplate(
      name: 'Thyroid - Hypothyroid',
      recordType: 'lab_result',
      category: 'Endocrine',
      description: 'Elevated TSH, low T4',
      diagnosis: 'Primary Hypothyroidism',
      treatment: 'Levothyroxine replacement',
      data: {
        'test_name': 'Thyroid Function Tests',
        'result': 'TSH: 12.5, FT4: 0.5',
        'reference_range': 'TSH: 0.4-4.0, FT4: 0.8-1.8',
      },
    ),
    MedicalRecordTemplate(
      name: 'Kidney Function - CKD',
      recordType: 'lab_result',
      category: 'Renal',
      description: 'Elevated creatinine, reduced GFR',
      diagnosis: 'Chronic Kidney Disease Stage 3',
      treatment: 'Nephrology referral, BP control, avoid nephrotoxins',
      data: {
        'test_name': 'Renal Function Tests',
        'result': 'Creatinine: 2.1, BUN: 45, eGFR: 35',
        'reference_range': 'Creatinine: 0.7-1.3, BUN: 7-20, eGFR >90',
      },
    ),
    MedicalRecordTemplate(
      name: 'Liver Function - Hepatitis',
      recordType: 'lab_result',
      category: 'Hepatic',
      description: 'Elevated transaminases',
      diagnosis: 'Acute Hepatitis',
      treatment: 'Identify etiology, supportive care',
      data: {
        'test_name': 'Liver Function Tests',
        'result': 'ALT: 450, AST: 380, Bilirubin: 3.5',
        'reference_range': 'ALT: <40, AST: <40, Bilirubin: <1.2',
      },
    ),
  ];
}

// ==================== Imaging Templates ====================

class ImagingTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Chest X-ray - Normal',
      recordType: 'imaging',
      category: 'X-Ray',
      description: 'Normal chest radiograph',
      diagnosis: 'Normal chest X-ray',
      data: {
        'imaging_type': 'Chest X-ray PA view',
        'findings': 'Heart size normal. Lungs clear. No pleural effusion. Costophrenic angles clear.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Chest X-ray - Pneumonia',
      recordType: 'imaging',
      category: 'X-Ray',
      description: 'Consolidation suggestive of pneumonia',
      diagnosis: 'Right lower lobe pneumonia',
      data: {
        'imaging_type': 'Chest X-ray PA view',
        'findings': 'Homogeneous opacity in right lower zone with air bronchogram. Heart size normal. Left lung clear.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Ultrasound Abdomen - Fatty Liver',
      recordType: 'imaging',
      category: 'Ultrasound',
      description: 'Hepatic steatosis',
      diagnosis: 'Fatty Liver Grade II',
      data: {
        'imaging_type': 'Ultrasound Abdomen',
        'findings': 'Liver enlarged with increased echogenicity. No focal lesions. Biliary system normal. Spleen, kidneys normal.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Ultrasound Abdomen - Gallstones',
      recordType: 'imaging',
      category: 'Ultrasound',
      description: 'Cholelithiasis',
      diagnosis: 'Gallbladder calculi',
      data: {
        'imaging_type': 'Ultrasound Abdomen',
        'findings': 'Multiple echogenic foci with posterior acoustic shadowing in gallbladder. No wall thickening. CBD not dilated.',
      },
    ),
    MedicalRecordTemplate(
      name: 'CT Brain - Normal',
      recordType: 'imaging',
      category: 'CT Scan',
      description: 'Normal CT brain',
      diagnosis: 'Normal CT scan brain',
      data: {
        'imaging_type': 'CT Brain Plain',
        'findings': 'No evidence of infarct or hemorrhage. Ventricles normal size. No midline shift. No space-occupying lesion.',
      },
    ),
    MedicalRecordTemplate(
      name: 'CT Brain - Stroke',
      recordType: 'imaging',
      category: 'CT Scan',
      description: 'Acute infarct',
      diagnosis: 'Acute ischemic stroke',
      data: {
        'imaging_type': 'CT Brain Plain',
        'findings': 'Hypodense area in left MCA territory suggestive of acute infarct. No hemorrhagic transformation. Mild midline shift.',
      },
    ),
    MedicalRecordTemplate(
      name: 'MRI Spine - Disc Prolapse',
      recordType: 'imaging',
      category: 'MRI',
      description: 'Lumbar disc herniation',
      diagnosis: 'L4-L5 Disc Prolapse',
      data: {
        'imaging_type': 'MRI Lumbar Spine',
        'findings': 'Posterior disc bulge at L4-L5 with right paracentral protrusion causing thecal sac compression and right nerve root impingement.',
      },
    ),
    MedicalRecordTemplate(
      name: 'ECG - Normal',
      recordType: 'imaging',
      category: 'ECG',
      description: 'Normal sinus rhythm',
      diagnosis: 'Normal ECG',
      data: {
        'imaging_type': '12-Lead ECG',
        'findings': 'Normal sinus rhythm. Rate 72/min. Normal axis. No ST-T changes. PR and QT intervals normal.',
      },
    ),
    MedicalRecordTemplate(
      name: 'ECG - MI Changes',
      recordType: 'imaging',
      category: 'ECG',
      description: 'ST elevation myocardial infarction',
      diagnosis: 'Acute STEMI - Anterior wall',
      data: {
        'imaging_type': '12-Lead ECG',
        'findings': 'ST elevation in V1-V4 with reciprocal changes in inferior leads. Q waves in V1-V3. Suggestive of acute anterior wall MI.',
      },
    ),
  ];
}

// ==================== Procedure Templates ====================

class ProcedureTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Wound Dressing',
      recordType: 'procedure',
      category: 'Minor Procedures',
      description: 'Wound cleaning and dressing',
      diagnosis: 'Wound care',
      data: {
        'procedure_name': 'Wound Dressing',
        'procedure_notes': 'Wound cleaned with normal saline. No signs of infection. Sterile dressing applied.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Suture Removal',
      recordType: 'procedure',
      category: 'Minor Procedures',
      description: 'Removal of surgical sutures',
      diagnosis: 'Post-operative follow-up',
      data: {
        'procedure_name': 'Suture Removal',
        'procedure_notes': 'Sutures removed. Wound healed well. No signs of infection. Steri-strips applied.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Incision & Drainage',
      recordType: 'procedure',
      category: 'Minor Procedures',
      description: 'I&D of abscess',
      diagnosis: 'Abscess drained',
      data: {
        'procedure_name': 'Incision and Drainage',
        'procedure_notes': 'Local anesthesia given. Incision made. Pus drained. Wound irrigated. Packed with gauze. Antibiotics prescribed.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Ear Syringing',
      recordType: 'procedure',
      category: 'ENT Procedures',
      description: 'Ear wax removal',
      diagnosis: 'Cerumen impaction - cleared',
      data: {
        'procedure_name': 'Ear Syringing',
        'procedure_notes': 'Bilateral ear syringing done with warm saline. Wax removed. Tympanic membrane visualized - intact.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Nebulization',
      recordType: 'procedure',
      category: 'Respiratory',
      description: 'Nebulization therapy',
      diagnosis: 'Bronchospasm treated',
      data: {
        'procedure_name': 'Nebulization',
        'procedure_notes': 'Nebulization with salbutamol + ipratropium given. Patient tolerated well. Improved symptomatically.',
      },
    ),
    MedicalRecordTemplate(
      name: 'IV Cannulation',
      recordType: 'procedure',
      category: 'Vascular Access',
      description: 'IV line placement',
      diagnosis: 'IV access established',
      data: {
        'procedure_name': 'IV Cannulation',
        'procedure_notes': '20G cannula inserted in right forearm. Good backflow. Secured with tegaderm. IV fluids started.',
      },
    ),
    MedicalRecordTemplate(
      name: 'IM/IV Injection',
      recordType: 'procedure',
      category: 'Injections',
      description: 'Injection administration',
      diagnosis: 'Medication administered',
      data: {
        'procedure_name': 'Injection Administration',
        'procedure_notes': 'Injection given as prescribed. Patient observed for 30 minutes. No adverse reaction.',
      },
    ),
    MedicalRecordTemplate(
      name: 'ECG Recording',
      recordType: 'procedure',
      category: 'Diagnostic',
      description: '12-lead ECG done',
      diagnosis: 'ECG recorded',
      data: {
        'procedure_name': '12-Lead ECG',
        'procedure_notes': 'ECG recorded. See imaging report for interpretation.',
      },
    ),
  ];
}

// ==================== Follow-up Templates ====================

class FollowUpTemplates {
  static const List<MedicalRecordTemplate> common = [
    MedicalRecordTemplate(
      name: 'Hypertension Follow-up',
      recordType: 'follow_up',
      category: 'Cardiovascular',
      description: 'Routine BP follow-up',
      diagnosis: 'Essential Hypertension - review',
      notes: 'BP at target. Continue medications',
      data: {
        'follow_up_notes': 'BP well controlled. No side effects from medications. Continue current regimen. Next review in 3 months.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Diabetes Follow-up',
      recordType: 'follow_up',
      category: 'Metabolic',
      description: 'Diabetes management review',
      diagnosis: 'Type 2 DM - review',
      notes: 'Review HbA1c and adjust treatment',
      data: {
        'follow_up_notes': 'Blood sugars improved. Diet and exercise compliance good. Review labs and adjust medications as needed.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Post-Surgery Follow-up',
      recordType: 'follow_up',
      category: 'Surgical',
      description: 'Post-operative review',
      diagnosis: 'Post-operative follow-up',
      notes: 'Wound healing well',
      data: {
        'follow_up_notes': 'Wound healing satisfactorily. No signs of infection. Pain controlled. Sutures to be removed in 7 days.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Medication Review',
      recordType: 'follow_up',
      category: 'General',
      description: 'Medication efficacy and tolerance check',
      diagnosis: 'Medication review',
      notes: 'Assess response and side effects',
      data: {
        'follow_up_notes': 'Medications reviewed. Good response. No significant side effects. Continue current treatment.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Lab Results Review',
      recordType: 'follow_up',
      category: 'General',
      description: 'Discussion of investigation results',
      diagnosis: 'Results discussion',
      notes: 'Review and explain results to patient',
      data: {
        'follow_up_notes': 'Lab results reviewed with patient. Findings explained. Treatment plan adjusted accordingly.',
      },
    ),
    MedicalRecordTemplate(
      name: 'Chronic Disease Review',
      recordType: 'follow_up',
      category: 'General',
      description: 'Annual/periodic chronic disease review',
      diagnosis: 'Annual chronic disease review',
      notes: 'Comprehensive chronic disease assessment',
      data: {
        'follow_up_notes': 'Annual review completed. All parameters checked. Complications screening done. Medications continued.',
      },
    ),
  ];
}

// ==================== Main Templates Class ====================

class MedicalRecordTemplates {
  // Get all templates by record type
  static Map<String, List<MedicalRecordTemplate>> get byRecordType => {
    'general': GeneralConsultationTemplates.common,
    'psychiatric_assessment': PsychiatricTemplates.common,
    'pulmonary_evaluation': PulmonaryTemplates.common,
    'lab_result': LabResultTemplates.common,
    'imaging': ImagingTemplates.common,
    'procedure': ProcedureTemplates.common,
    'follow_up': FollowUpTemplates.common,
  };

  // Get templates for a specific record type
  static List<MedicalRecordTemplate> getTemplatesForType(String recordType) {
    return byRecordType[recordType] ?? [];
  }

  // Get all templates flat list
  static List<MedicalRecordTemplate> get allTemplates => [
    ...GeneralConsultationTemplates.common,
    ...PsychiatricTemplates.common,
    ...PulmonaryTemplates.common,
    ...LabResultTemplates.common,
    ...ImagingTemplates.common,
    ...ProcedureTemplates.common,
    ...FollowUpTemplates.common,
  ];

  // Search templates by name or diagnosis
  static List<MedicalRecordTemplate> searchTemplates(String query, {String? recordType}) {
    final lowerQuery = query.toLowerCase();
    var templates = recordType != null 
        ? getTemplatesForType(recordType) 
        : allTemplates;
    
    return templates.where((t) =>
      t.name.toLowerCase().contains(lowerQuery) ||
      t.diagnosis.toLowerCase().contains(lowerQuery) ||
      t.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get categories for a record type
  static List<String> getCategoriesForType(String recordType) {
    final templates = getTemplatesForType(recordType);
    return templates.map((t) => t.category).toSet().toList();
  }
}

// ==================== Bottom Sheet Widget ====================

class MedicalRecordTemplateBottomSheet extends StatefulWidget {
  const MedicalRecordTemplateBottomSheet({
    required this.recordType,
    required this.onSelect,
    super.key,
  });

  final String recordType;
  final void Function(MedicalRecordTemplate) onSelect;

  @override
  State<MedicalRecordTemplateBottomSheet> createState() => _MedicalRecordTemplateBottomSheetState();
}

class _MedicalRecordTemplateBottomSheetState extends State<MedicalRecordTemplateBottomSheet> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = MedicalRecordTemplates.getTemplatesForType(widget.recordType);
    final categories = MedicalRecordTemplates.getCategoriesForType(widget.recordType);
    
    List<MedicalRecordTemplate> displayTemplates;
    if (_searchQuery.isNotEmpty) {
      displayTemplates = MedicalRecordTemplates.searchTemplates(_searchQuery, recordType: widget.recordType);
    } else if (_selectedCategory != null) {
      displayTemplates = templates.where((t) => t.category == _selectedCategory).toList();
    } else {
      displayTemplates = templates;
    }

    final recordTypeLabel = _getRecordTypeLabel(widget.recordType);
    final recordTypeIcon = _getRecordTypeIcon(widget.recordType);
    final themeColor = _getRecordTypeColor(widget.recordType);

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
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  recordTypeIcon,
                  color: themeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$recordTypeLabel Templates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Quick fill common templates',
                      style: TextStyle(
                        fontSize: 13,
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
            hint: 'Search templates...',
            onChanged: (value) => setState(() {
              _searchQuery = value;
              if (value.isNotEmpty) _selectedCategory = null;
            }),
          ),
          const SizedBox(height: 16),
          
          // Category chips
          if (_searchQuery.isEmpty && categories.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        'All',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedCategory == null ? Colors.white : null,
                        ),
                      ),
                      selected: _selectedCategory == null,
                      onSelected: (selected) => setState(() {
                        _selectedCategory = null;
                      }),
                      selectedColor: themeColor,
                      checkmarkColor: Colors.white,
                    ),
                  ),
                  ...categories.map((category) {
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
                        selectedColor: themeColor,
                        checkmarkColor: Colors.white,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Templates list
          Expanded(
            child: displayTemplates.isEmpty
                ? Center(
                    child: Text(
                      'No templates found',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayTemplates.length,
                    itemBuilder: (context, index) {
                      final template = displayTemplates[index];
                      return _buildTemplateCard(template, isDark, themeColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(MedicalRecordTemplate template, bool isDark, Color themeColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getCategoryIcon(template.category),
            color: themeColor,
            size: 20,
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.diagnosis.isNotEmpty)
              Text(
                template.diagnosis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                template.category,
                style: TextStyle(
                  fontSize: 10,
                  color: themeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: themeColor),
          onPressed: () {
            widget.onSelect(template);
            Navigator.pop(context);
          },
        ),
        onTap: () {
          widget.onSelect(template);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getRecordTypeLabel(String type) {
    return {
      'general': 'General Consultation',
      'psychiatric_assessment': 'Psychiatric Assessment',
      'pulmonary_evaluation': 'Pulmonary Evaluation',
      'lab_result': 'Lab Result',
      'imaging': 'Imaging',
      'procedure': 'Procedure',
      'follow_up': 'Follow-up',
    }[type] ?? 'Medical Record';
  }

  IconData _getRecordTypeIcon(String type) {
    return {
      'general': Icons.medical_services_outlined,
      'psychiatric_assessment': Icons.psychology,
      'pulmonary_evaluation': Icons.air,
      'lab_result': Icons.science_outlined,
      'imaging': Icons.image_outlined,
      'procedure': Icons.healing_outlined,
      'follow_up': Icons.event_repeat,
    }[type] ?? Icons.description;
  }

  Color _getRecordTypeColor(String type) {
    return {
      'general': AppColors.primary,
      'psychiatric_assessment': Colors.purple,
      'pulmonary_evaluation': Colors.teal,
      'lab_result': Colors.orange,
      'imaging': Colors.indigo,
      'procedure': Colors.red,
      'follow_up': Colors.green,
    }[type] ?? AppColors.primary;
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('infectious')) return Icons.coronavirus;
    if (lower.contains('cardio')) return Icons.favorite;
    if (lower.contains('metabolic')) return Icons.monitor_heart;
    if (lower.contains('neuro')) return Icons.psychology;
    if (lower.contains('musculo')) return Icons.accessibility;
    if (lower.contains('allergy')) return Icons.warning;
    if (lower.contains('derma')) return Icons.face;
    if (lower.contains('mood')) return Icons.mood;
    if (lower.contains('anxiety')) return Icons.sentiment_dissatisfied;
    if (lower.contains('psychotic')) return Icons.psychology_alt;
    if (lower.contains('sleep')) return Icons.bedtime;
    if (lower.contains('obstructive')) return Icons.air;
    if (lower.contains('pleural')) return Icons.water;
    if (lower.contains('hematology')) return Icons.bloodtype;
    if (lower.contains('renal')) return Icons.water_drop;
    if (lower.contains('hepatic')) return Icons.local_pharmacy;
    if (lower.contains('endocrine')) return Icons.biotech;
    if (lower.contains('x-ray')) return Icons.photo;
    if (lower.contains('ultrasound')) return Icons.sensors;
    if (lower.contains('ct')) return Icons.view_in_ar;
    if (lower.contains('mri')) return Icons.view_in_ar;
    if (lower.contains('ecg')) return Icons.monitor_heart;
    if (lower.contains('minor')) return Icons.healing;
    if (lower.contains('ent')) return Icons.hearing;
    if (lower.contains('respiratory')) return Icons.air;
    if (lower.contains('vascular')) return Icons.water_drop;
    if (lower.contains('injection')) return Icons.vaccines;
    if (lower.contains('diagnostic')) return Icons.search;
    if (lower.contains('surgical')) return Icons.local_hospital;
    if (lower.contains('gi')) return Icons.restaurant;
    return Icons.folder;
  }
}
