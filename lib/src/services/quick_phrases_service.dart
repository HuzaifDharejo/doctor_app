/// Quick Phrases Service
/// Provides text expansion shortcuts for clinical documentation
class QuickPhrasesService {
  /// Default quick phrases to seed the database
  static const List<Map<String, String>> defaultPhrases = [
    // Diagnoses
    {'shortcut': '.dm', 'expansion': 'Diabetes Mellitus Type 2', 'category': 'diagnosis'},
    {'shortcut': '.dm1', 'expansion': 'Diabetes Mellitus Type 1', 'category': 'diagnosis'},
    {'shortcut': '.htn', 'expansion': 'Essential Hypertension', 'category': 'diagnosis'},
    {'shortcut': '.cad', 'expansion': 'Coronary Artery Disease', 'category': 'diagnosis'},
    {'shortcut': '.ckd', 'expansion': 'Chronic Kidney Disease', 'category': 'diagnosis'},
    {'shortcut': '.copd', 'expansion': 'Chronic Obstructive Pulmonary Disease', 'category': 'diagnosis'},
    {'shortcut': '.gerd', 'expansion': 'Gastroesophageal Reflux Disease', 'category': 'diagnosis'},
    {'shortcut': '.uti', 'expansion': 'Urinary Tract Infection', 'category': 'diagnosis'},
    {'shortcut': '.urti', 'expansion': 'Upper Respiratory Tract Infection', 'category': 'diagnosis'},
    {'shortcut': '.lrti', 'expansion': 'Lower Respiratory Tract Infection', 'category': 'diagnosis'},
    {'shortcut': '.af', 'expansion': 'Atrial Fibrillation', 'category': 'diagnosis'},
    {'shortcut': '.chf', 'expansion': 'Congestive Heart Failure', 'category': 'diagnosis'},
    {'shortcut': '.oa', 'expansion': 'Osteoarthritis', 'category': 'diagnosis'},
    {'shortcut': '.ra', 'expansion': 'Rheumatoid Arthritis', 'category': 'diagnosis'},
    {'shortcut': '.mdd', 'expansion': 'Major Depressive Disorder', 'category': 'diagnosis'},
    {'shortcut': '.gad', 'expansion': 'Generalized Anxiety Disorder', 'category': 'diagnosis'},
    {'shortcut': '.bpad', 'expansion': 'Bipolar Affective Disorder', 'category': 'diagnosis'},
    
    // Physical Examination
    {'shortcut': '.nad', 'expansion': 'No abnormality detected', 'category': 'exam'},
    {'shortcut': '.wnl', 'expansion': 'Within normal limits', 'category': 'exam'},
    {'shortcut': '.nsr', 'expansion': 'Normal sinus rhythm', 'category': 'exam'},
    {'shortcut': '.s1s2', 'expansion': 'S1 S2 heard, no murmurs', 'category': 'exam'},
    {'shortcut': '.nvae', 'expansion': 'Normal vesicular breath sounds, no added sounds', 'category': 'exam'},
    {'shortcut': '.bae', 'expansion': 'Bilateral air entry equal, no added sounds', 'category': 'exam'},
    {'shortcut': '.snt', 'expansion': 'Soft, non-tender abdomen', 'category': 'exam'},
    {'shortcut': '.norg', 'expansion': 'No organomegaly', 'category': 'exam'},
    {'shortcut': '.bs+', 'expansion': 'Bowel sounds present', 'category': 'exam'},
    {'shortcut': '.cnorm', 'expansion': 'Chest - Normal inspection, no deformity, central trachea', 'category': 'exam'},
    {'shortcut': '.cva', 'expansion': 'CVA tenderness absent bilaterally', 'category': 'exam'},
    {'shortcut': '.pe', 'expansion': 'Pedal edema present bilaterally', 'category': 'exam'},
    {'shortcut': '.nope', 'expansion': 'No pedal edema', 'category': 'exam'},
    {'shortcut': '.perrl', 'expansion': 'Pupils equal, round, reactive to light', 'category': 'exam'},
    {'shortcut': '.gcs15', 'expansion': 'GCS 15/15, alert and oriented', 'category': 'exam'},
    
    // Mental Status Exam
    {'shortcut': '.msenl', 'expansion': 'Mental status exam within normal limits - patient is alert, oriented to person/place/time, cooperative, appropriate affect, no psychotic features', 'category': 'exam'},
    {'shortcut': '.ori', 'expansion': 'Oriented to person, place, time, and situation', 'category': 'exam'},
    {'shortcut': '.coop', 'expansion': 'Patient cooperative and engaged in interview', 'category': 'exam'},
    {'shortcut': '.euth', 'expansion': 'Euthymic mood with congruent affect', 'category': 'exam'},
    {'shortcut': '.nsi', 'expansion': 'No suicidal or homicidal ideation', 'category': 'exam'},
    {'shortcut': '.noavh', 'expansion': 'No auditory or visual hallucinations', 'category': 'exam'},
    
    // History
    {'shortcut': '.nkda', 'expansion': 'No known drug allergies', 'category': 'history'},
    {'shortcut': '.nkfa', 'expansion': 'No known food allergies', 'category': 'history'},
    {'shortcut': '.nosurg', 'expansion': 'No previous surgical history', 'category': 'history'},
    {'shortcut': '.nsfh', 'expansion': 'No significant family history', 'category': 'history'},
    {'shortcut': '.exsm', 'expansion': 'Ex-smoker, quit', 'category': 'history'},
    {'shortcut': '.nonsm', 'expansion': 'Non-smoker', 'category': 'history'},
    {'shortcut': '.noalc', 'expansion': 'No alcohol consumption', 'category': 'history'},
    {'shortcut': '.socdr', 'expansion': 'Social drinker', 'category': 'history'},
    
    // Plans
    {'shortcut': '.contmeds', 'expansion': 'Continue current medications', 'category': 'plan'},
    {'shortcut': '.fu1w', 'expansion': 'Follow up in 1 week', 'category': 'plan'},
    {'shortcut': '.fu2w', 'expansion': 'Follow up in 2 weeks', 'category': 'plan'},
    {'shortcut': '.fu1m', 'expansion': 'Follow up in 1 month', 'category': 'plan'},
    {'shortcut': '.fu3m', 'expansion': 'Follow up in 3 months', 'category': 'plan'},
    {'shortcut': '.prn', 'expansion': 'Return if symptoms worsen or new symptoms develop', 'category': 'plan'},
    {'shortcut': '.refspec', 'expansion': 'Referred to specialist for further evaluation', 'category': 'plan'},
    {'shortcut': '.labs', 'expansion': 'Laboratory investigations ordered', 'category': 'plan'},
    {'shortcut': '.diet', 'expansion': 'Dietary modification advised', 'category': 'plan'},
    {'shortcut': '.exer', 'expansion': 'Regular exercise recommended', 'category': 'plan'},
    {'shortcut': '.rest', 'expansion': 'Rest advised, avoid strenuous activity', 'category': 'plan'},
    {'shortcut': '.hydrate', 'expansion': 'Increase fluid intake, stay well hydrated', 'category': 'plan'},
    
    // General phrases
    {'shortcut': '.stable', 'expansion': 'Patient is clinically stable', 'category': 'general'},
    {'shortcut': '.improved', 'expansion': 'Patient reports improvement in symptoms', 'category': 'general'},
    {'shortcut': '.nochange', 'expansion': 'No significant change from previous visit', 'category': 'general'},
    {'shortcut': '.compliant', 'expansion': 'Patient compliant with prescribed medications', 'category': 'general'},
    {'shortcut': '.poor', 'expansion': 'Poor compliance with medications reported', 'category': 'general'},
    {'shortcut': '.ref', 'expansion': 'Referred by', 'category': 'general'},
    {'shortcut': '.self', 'expansion': 'Self-referred', 'category': 'general'},
    
    // Vitals commentary
    {'shortcut': '.bpnl', 'expansion': 'Blood pressure within normal limits', 'category': 'vitals'},
    {'shortcut': '.bphigh', 'expansion': 'Blood pressure elevated', 'category': 'vitals'},
    {'shortcut': '.tachyc', 'expansion': 'Tachycardia noted', 'category': 'vitals'},
    {'shortcut': '.brady', 'expansion': 'Bradycardia noted', 'category': 'vitals'},
    {'shortcut': '.febrile', 'expansion': 'Patient febrile', 'category': 'vitals'},
    {'shortcut': '.afebrile', 'expansion': 'Patient afebrile', 'category': 'vitals'},
    {'shortcut': '.spo2nl', 'expansion': 'Oxygen saturation normal on room air', 'category': 'vitals'},
  ];

  /// Categories for organizing quick phrases
  static const List<String> categories = [
    'diagnosis',
    'exam',
    'history',
    'plan',
    'vitals',
    'general',
  ];

  /// Get display name for category
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'diagnosis':
        return 'Diagnoses';
      case 'exam':
        return 'Physical Exam';
      case 'history':
        return 'History';
      case 'plan':
        return 'Plans';
      case 'vitals':
        return 'Vitals';
      case 'general':
        return 'General';
      default:
        return category;
    }
  }
}
