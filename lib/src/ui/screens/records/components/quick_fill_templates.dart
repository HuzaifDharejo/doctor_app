import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

/// Data class for a quick fill template
class QuickFillTemplate {
  const QuickFillTemplate({
    required this.label,
    required this.icon,
    required this.color,
    required this.data,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> data;
}

/// A reusable quick fill templates section for medical record forms
class QuickFillSection extends StatelessWidget {
  const QuickFillSection({
    super.key,
    required this.templates,
    required this.onTemplateSelected,
    this.title = 'Quick Fill Templates',
  });

  final List<QuickFillTemplate> templates;
  final Function(QuickFillTemplate) onTemplateSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.amber.shade900.withValues(alpha: 0.2), Colors.orange.shade900.withValues(alpha: 0.1)]
              : [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.amber.shade700.withValues(alpha: 0.3) : Colors.amber.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.shade600.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Tap to auto-fill common conditions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: templates.map((template) => _buildTemplateChip(
              context,
              template,
              isDark,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(BuildContext context, QuickFillTemplate template, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTemplateSelected(template);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? template.color.withValues(alpha: 0.2) 
                : template.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: template.color.withValues(alpha: isDark ? 0.4 : 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(template.icon, size: 16, color: template.color),
              const SizedBox(width: 6),
              Text(
                template.label,
                style: TextStyle(
                  color: template.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a snackbar when a template is applied
void showTemplateAppliedSnackbar(BuildContext context, String templateName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            '$templateName template applied',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    ),
  );
}

// =============================================================================
// GENERAL CONSULTATION TEMPLATES
// =============================================================================

class GeneralConsultationTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'Hypertension',
      icon: Icons.favorite_rounded,
      color: Colors.red,
      data: {
        'chief_complaints': 'Headache, dizziness, occasional chest discomfort',
        'history': 'Known hypertensive on medication. Compliant with treatment.',
        'diagnosis': 'Essential Hypertension',
        'treatment': 'Continue antihypertensives. Low salt diet. Regular BP monitoring. Follow-up in 2 weeks.',
        'vitals': {'bp_systolic': '140', 'bp_diastolic': '90'},
      },
    ),
    QuickFillTemplate(
      label: 'Diabetes',
      icon: Icons.bloodtype_rounded,
      color: Colors.purple,
      data: {
        'chief_complaints': 'Routine diabetes follow-up, polyuria, polydipsia',
        'history': 'Type 2 DM on oral hypoglycemics. Diet controlled.',
        'diagnosis': 'Type 2 Diabetes Mellitus',
        'treatment': 'Continue OHAs. Diet control. Regular glucose monitoring. HbA1c every 3 months.',
        'vitals': {'weight': '75'},
      },
    ),
    QuickFillTemplate(
      label: 'Fever',
      icon: Icons.thermostat_rounded,
      color: Colors.orange,
      data: {
        'chief_complaints': 'Fever for 2-3 days, body aches, malaise',
        'history': 'Acute onset. No travel history. No contact with sick persons.',
        'examination': 'Febrile, mild pharyngitis, no lymphadenopathy',
        'diagnosis': 'Viral Fever',
        'treatment': 'Symptomatic treatment. Paracetamol 500mg TDS. Adequate hydration. Rest.',
        'vitals': {'temperature': '38.5'},
      },
    ),
    QuickFillTemplate(
      label: 'GERD',
      icon: Icons.local_fire_department_rounded,
      color: Colors.amber.shade700,
      data: {
        'chief_complaints': 'Heartburn, acid reflux, epigastric discomfort',
        'history': 'Symptoms worse after meals, especially spicy food. No alarm symptoms.',
        'examination': 'Epigastric tenderness, no organomegaly',
        'diagnosis': 'Gastroesophageal Reflux Disease (GERD)',
        'treatment': 'PPI (Omeprazole 20mg) before breakfast. Avoid trigger foods. Elevate head during sleep.',
      },
    ),
    QuickFillTemplate(
      label: 'Headache',
      icon: Icons.psychology_rounded,
      color: Colors.indigo,
      data: {
        'chief_complaints': 'Throbbing headache, photophobia, nausea',
        'history': 'Recurrent episodes. No aura. Triggered by stress/lack of sleep.',
        'examination': 'No neurological deficits. Neck supple.',
        'diagnosis': 'Migraine without aura',
        'treatment': 'NSAIDs for acute attack. Avoid triggers. Consider prophylaxis if frequent.',
      },
    ),
    QuickFillTemplate(
      label: 'UTI',
      icon: Icons.water_drop_rounded,
      color: Colors.teal,
      data: {
        'chief_complaints': 'Burning micturition, frequency, urgency',
        'history': 'Onset 2-3 days ago. No fever. No flank pain.',
        'examination': 'Suprapubic tenderness. No CVA tenderness.',
        'diagnosis': 'Uncomplicated Urinary Tract Infection',
        'treatment': 'Antibiotics (Nitrofurantoin 100mg BD x 5 days). Adequate hydration. Follow-up if symptoms persist.',
      },
    ),
  ];
}

// =============================================================================
// LAB RESULT TEMPLATES
// =============================================================================

class LabResultTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'CBC',
      icon: Icons.bloodtype_rounded,
      color: Colors.red,
      data: {
        'test_name': 'Complete Blood Count (CBC)',
        'category': 'Hematology',
        'specimen': 'Whole Blood (EDTA)',
        'reference_range': 'Hb: 12-16 g/dL, WBC: 4-11 x10³/µL, Platelets: 150-400 x10³/µL',
        'units': 'Multiple',
      },
    ),
    QuickFillTemplate(
      label: 'LFT',
      icon: Icons.science_rounded,
      color: Colors.amber.shade700,
      data: {
        'test_name': 'Liver Function Test (LFT)',
        'category': 'Biochemistry',
        'specimen': 'Serum',
        'reference_range': 'Bilirubin: 0.1-1.2 mg/dL, ALT: 7-56 U/L, AST: 10-40 U/L, ALP: 44-147 U/L',
        'units': 'Multiple',
      },
    ),
    QuickFillTemplate(
      label: 'KFT',
      icon: Icons.water_drop_rounded,
      color: Colors.blue,
      data: {
        'test_name': 'Kidney Function Test (KFT)',
        'category': 'Biochemistry',
        'specimen': 'Serum',
        'reference_range': 'Creatinine: 0.7-1.3 mg/dL, BUN: 7-20 mg/dL, eGFR: >90 mL/min',
        'units': 'Multiple',
      },
    ),
    QuickFillTemplate(
      label: 'Lipid Panel',
      icon: Icons.favorite_rounded,
      color: Colors.pink,
      data: {
        'test_name': 'Lipid Profile',
        'category': 'Biochemistry',
        'specimen': 'Serum (Fasting)',
        'reference_range': 'Total Chol: <200, LDL: <100, HDL: >40, TG: <150 mg/dL',
        'units': 'mg/dL',
      },
    ),
    QuickFillTemplate(
      label: 'Thyroid',
      icon: Icons.ac_unit_rounded,
      color: Colors.purple,
      data: {
        'test_name': 'Thyroid Function Test',
        'category': 'Endocrinology',
        'specimen': 'Serum',
        'reference_range': 'TSH: 0.4-4.0 mIU/L, T3: 80-200 ng/dL, T4: 4.5-12 µg/dL',
        'units': 'Multiple',
      },
    ),
    QuickFillTemplate(
      label: 'HbA1c',
      icon: Icons.donut_large_rounded,
      color: Colors.teal,
      data: {
        'test_name': 'Glycated Hemoglobin (HbA1c)',
        'category': 'Biochemistry',
        'specimen': 'Whole Blood (EDTA)',
        'reference_range': 'Normal: <5.7%, Prediabetes: 5.7-6.4%, Diabetes: ≥6.5%',
        'units': '%',
      },
    ),
  ];
}

// =============================================================================
// PROCEDURE TEMPLATES
// =============================================================================

class ProcedureTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'Wound Care',
      icon: Icons.healing_rounded,
      color: Colors.red,
      data: {
        'procedure_name': 'Wound Dressing & Care',
        'indication': 'Wound care and dressing change',
        'anesthesia': 'None / Local anesthesia',
        'procedure_notes': 'Wound cleaned with normal saline. Old dressing removed. Wound bed inspected - healthy granulation tissue noted. Fresh sterile dressing applied.',
        'post_op_instructions': 'Keep wound dry. Change dressing daily. Watch for signs of infection.',
      },
    ),
    QuickFillTemplate(
      label: 'Suturing',
      icon: Icons.content_cut_rounded,
      color: Colors.blue,
      data: {
        'procedure_name': 'Wound Suturing',
        'indication': 'Laceration requiring closure',
        'anesthesia': 'Local anesthesia (Lidocaine 2%)',
        'procedure_notes': 'Wound irrigated and cleaned. Local anesthesia infiltrated. Wound edges approximated. Interrupted sutures placed. Sterile dressing applied.',
        'post_op_instructions': 'Keep sutures dry for 24 hours. Suture removal in 7-10 days. Watch for infection signs.',
      },
    ),
    QuickFillTemplate(
      label: 'I&D Abscess',
      icon: Icons.local_hospital_rounded,
      color: Colors.orange,
      data: {
        'procedure_name': 'Incision & Drainage of Abscess',
        'indication': 'Localized abscess requiring drainage',
        'anesthesia': 'Local anesthesia (Lidocaine 2%)',
        'procedure_notes': 'Area prepped and draped. Local anesthesia given. Cruciate incision made. Pus drained and sent for culture. Cavity irrigated. Wick placed. Sterile dressing applied.',
        'post_op_instructions': 'Keep area clean. Daily dressing change. Complete antibiotic course. Follow-up in 48-72 hours.',
        'specimen': 'Pus for culture & sensitivity',
      },
    ),
    QuickFillTemplate(
      label: 'IM Injection',
      icon: Icons.vaccines_rounded,
      color: Colors.green,
      data: {
        'procedure_name': 'Intramuscular Injection',
        'indication': 'Medication administration',
        'anesthesia': 'None',
        'procedure_notes': 'Site cleaned with alcohol swab. Medication drawn up and verified. IM injection given in deltoid/gluteal region using Z-track technique. Post-injection site observed for reaction.',
        'post_op_instructions': 'Observe for 15-30 minutes. Report any adverse reactions.',
      },
    ),
    QuickFillTemplate(
      label: 'IV Cannulation',
      icon: Icons.water_drop_rounded,
      color: Colors.purple,
      data: {
        'procedure_name': 'Peripheral IV Cannulation',
        'indication': 'IV access for medication/fluids',
        'anesthesia': 'None',
        'procedure_notes': 'Site selected and prepped. Tourniquet applied. Vein cannulated on first attempt. Blood flash confirmed. Cannula secured with transparent dressing.',
        'post_op_instructions': 'Monitor insertion site. Report pain, swelling, or redness. Keep dressing dry.',
      },
    ),
    QuickFillTemplate(
      label: 'Nebulization',
      icon: Icons.air_rounded,
      color: Colors.cyan,
      data: {
        'procedure_name': 'Nebulization Therapy',
        'indication': 'Acute bronchospasm / Respiratory distress',
        'anesthesia': 'None',
        'procedure_notes': 'Pre-nebulization vitals recorded. Medication (Salbutamol/Ipratropium) nebulized. Patient tolerated procedure well. Post-nebulization assessment shows improvement.',
        'post_op_instructions': 'May repeat every 4-6 hours as needed. Monitor for tremors/palpitations.',
      },
    ),
  ];
}

/// Imaging study templates for common radiology studies
class ImagingTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'Chest X-Ray',
      icon: Icons.image_rounded,
      color: Colors.indigo,
      data: {
        'imaging_type': 'X-Ray',
        'body_part': 'Chest PA/Lateral',
        'indication': 'Evaluation for pneumonia / respiratory symptoms',
        'technique': 'Standard PA and lateral views obtained',
        'findings': 'Heart size normal. Lungs clear bilaterally. No pleural effusion. Costophrenic angles sharp. Bony thorax intact. No mediastinal widening.',
        'impression': 'Normal chest radiograph',
        'recommendations': 'No further imaging required at this time',
      },
    ),
    QuickFillTemplate(
      label: 'Chest X-Ray Abnormal',
      icon: Icons.image_rounded,
      color: Colors.red,
      data: {
        'imaging_type': 'X-Ray',
        'body_part': 'Chest PA/Lateral',
        'indication': 'Evaluation for pneumonia / respiratory symptoms',
        'technique': 'Standard PA and lateral views obtained',
        'findings': 'Patchy opacity noted in right lower lobe. Heart size normal. No pleural effusion. Costophrenic angles sharp bilaterally.',
        'impression': 'Right lower lobe consolidation, suggestive of pneumonia',
        'recommendations': 'Clinical correlation recommended. Consider follow-up chest X-ray in 4-6 weeks to document resolution.',
      },
    ),
    QuickFillTemplate(
      label: 'Abdominal US',
      icon: Icons.monitor_heart_rounded,
      color: Colors.teal,
      data: {
        'imaging_type': 'Ultrasound',
        'body_part': 'Abdomen Complete',
        'indication': 'Abdominal pain evaluation',
        'technique': 'Real-time gray scale imaging with color Doppler',
        'findings': 'Liver: Normal size and echogenicity. No focal lesion. Portal vein patent.\nGallbladder: Normal wall thickness. No calculi or polyps.\nPancreas: Normal.\nSpleen: Normal size.\nKidneys: Bilateral normal size, shape, and echogenicity. No hydronephrosis or calculi.\nBladder: Adequately distended, normal wall.',
        'impression': 'Normal abdominal ultrasound',
        'recommendations': 'No further imaging required',
      },
    ),
    QuickFillTemplate(
      label: 'KUB X-Ray',
      icon: Icons.image_rounded,
      color: Colors.orange,
      data: {
        'imaging_type': 'X-Ray',
        'body_part': 'KUB (Kidney-Ureter-Bladder)',
        'indication': 'Evaluation for renal calculi / abdominal pain',
        'technique': 'Single AP view of abdomen obtained',
        'findings': 'Normal bowel gas pattern. No abnormal calcifications. Psoas shadows preserved. No free air.',
        'impression': 'Normal KUB radiograph. No radio-opaque calculi identified.',
        'recommendations': 'If clinical suspicion persists, consider CT KUB or ultrasound',
      },
    ),
    QuickFillTemplate(
      label: 'Echocardiogram',
      icon: Icons.favorite_rounded,
      color: Colors.pink,
      data: {
        'imaging_type': '2D Echocardiography',
        'body_part': 'Heart',
        'indication': 'Cardiac evaluation / murmur assessment',
        'technique': 'Transthoracic 2D Echo with Doppler and color flow imaging',
        'findings': 'LV: Normal size and systolic function. EF 55-60%.\nRV: Normal size and function.\nValves: All valves structurally normal. No significant regurgitation or stenosis.\nNo pericardial effusion.\nNo intracardiac thrombus.',
        'impression': 'Normal echocardiographic study',
        'recommendations': 'Routine follow-up as clinically indicated',
      },
    ),
    QuickFillTemplate(
      label: 'CT Abdomen',
      icon: Icons.view_in_ar_rounded,
      color: Colors.deepPurple,
      data: {
        'imaging_type': 'CT Scan',
        'body_part': 'Abdomen and Pelvis',
        'indication': 'Abdominal pain / mass evaluation',
        'technique': 'Helical CT with oral and IV contrast',
        'findings': 'Liver, gallbladder, pancreas, spleen: Normal.\nKidneys: Normal enhancement, no hydronephrosis.\nBowel: No obstruction or wall thickening.\nNo lymphadenopathy. No free fluid.',
        'impression': 'Normal CT abdomen and pelvis',
        'recommendations': 'Clinical correlation. No further imaging needed at this time.',
      },
    ),
    QuickFillTemplate(
      label: 'MRI Brain',
      icon: Icons.psychology_rounded,
      color: Colors.blue,
      data: {
        'imaging_type': 'MRI',
        'body_part': 'Brain',
        'indication': 'Headache / neurological symptoms evaluation',
        'technique': 'Multiplanar imaging with T1, T2, FLAIR, DWI sequences',
        'findings': 'No acute infarct or hemorrhage. Ventricles normal in size. No mass lesion. Gray-white matter differentiation preserved. No abnormal enhancement.',
        'impression': 'Normal MRI brain',
        'recommendations': 'Clinical correlation. Symptomatic management as needed.',
      },
    ),
    QuickFillTemplate(
      label: 'Thyroid US',
      icon: Icons.monitor_heart_rounded,
      color: Colors.cyan,
      data: {
        'imaging_type': 'Ultrasound',
        'body_part': 'Thyroid',
        'indication': 'Thyroid nodule / goiter evaluation',
        'technique': 'High-resolution gray scale imaging with color Doppler',
        'findings': 'Right lobe: Normal size and echogenicity.\nLeft lobe: Normal size and echogenicity.\nIsthmus: Normal.\nNo discrete nodules identified. Normal vascularity.',
        'impression': 'Normal thyroid ultrasound',
        'recommendations': 'No further imaging required',
      },
    ),
  ];
}

/// Follow-up visit templates
class FollowUpTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'HTN Follow-up',
      icon: Icons.favorite_rounded,
      color: Colors.red,
      data: {
        'reason': 'Hypertension follow-up',
        'interval_history': 'Patient returns for routine BP monitoring. Reports compliance with medications. No headaches, chest pain, or visual disturbances.',
        'current_status': 'Blood pressure well controlled on current regimen',
        'medications_reviewed': 'Current antihypertensive medications reviewed and continued',
        'plan': 'Continue current medications. Maintain low salt diet. Regular exercise. Return in 3 months or sooner if needed.',
      },
    ),
    QuickFillTemplate(
      label: 'DM Follow-up',
      icon: Icons.bloodtype_rounded,
      color: Colors.orange,
      data: {
        'reason': 'Diabetes mellitus follow-up',
        'interval_history': 'Patient returns for routine diabetes monitoring. Reports good compliance with diet and medications. No hypoglycemic episodes. Regular SMBG showing adequate control.',
        'current_status': 'Diabetes well controlled. Recent HbA1c reviewed.',
        'medications_reviewed': 'Current diabetes medications reviewed and continued',
        'plan': 'Continue current regimen. Diabetic diet reinforced. Annual eye and foot exam due. Return in 3 months with HbA1c.',
      },
    ),
    QuickFillTemplate(
      label: 'Post-Op Follow-up',
      icon: Icons.local_hospital_rounded,
      color: Colors.purple,
      data: {
        'reason': 'Post-operative follow-up',
        'interval_history': 'Patient returns after recent procedure. Wound healing well. No fever, excessive pain, or discharge.',
        'current_status': 'Recovery progressing satisfactorily',
        'medications_reviewed': 'Post-operative medications completed/continued as needed',
        'plan': 'Wound care instructions reinforced. Suture removal scheduled if applicable. Activity restrictions reviewed. Return if any concerns.',
      },
    ),
    QuickFillTemplate(
      label: 'Chronic Disease',
      icon: Icons.healing_rounded,
      color: Colors.teal,
      data: {
        'reason': 'Chronic disease management follow-up',
        'interval_history': 'Patient returns for routine chronic disease monitoring. Overall stable. No new symptoms or concerns.',
        'current_status': 'Condition stable on current management',
        'medications_reviewed': 'Current medications reviewed, compliance assessed',
        'plan': 'Continue current management. Lifestyle modifications reinforced. Routine labs ordered. Return in 3 months.',
      },
    ),
    QuickFillTemplate(
      label: 'Lab Review',
      icon: Icons.science_rounded,
      color: Colors.blue,
      data: {
        'reason': 'Laboratory results review',
        'interval_history': 'Patient returns to review recent laboratory investigations.',
        'current_status': 'Lab results reviewed and discussed with patient',
        'medications_reviewed': 'Medications adjusted based on lab findings if needed',
        'plan': 'Management plan discussed. Further investigations ordered if needed. Follow-up as scheduled.',
      },
    ),
    QuickFillTemplate(
      label: 'Medication Refill',
      icon: Icons.medication_rounded,
      color: Colors.green,
      data: {
        'reason': 'Routine prescription refill',
        'interval_history': 'Patient returns for medication refill. No new symptoms. Tolerating medications well.',
        'current_status': 'Stable on current medications',
        'medications_reviewed': 'Prescription refilled for continued management',
        'plan': 'Continue current medications. Report any side effects. Return in 3 months.',
      },
    ),
  ];
}

/// Psychiatric assessment templates for mental health evaluations
class PsychiatricTemplates {
  static List<QuickFillTemplate> get templates => [
    QuickFillTemplate(
      label: 'Depression',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      color: Colors.indigo,
      data: {
        'chief_complaint': 'Low mood, loss of interest, hopelessness',
        'duration': '2-4 weeks',
        'symptoms': ['Sleep Disturbance', 'Appetite Change', 'Fatigue', 'Concentration Issues', 'Weight Change'],
        'mood': 'Depressed, hopeless, sad',
        'affect': 'Flat, blunted, constricted',
        'speech': 'Slow, low volume, decreased spontaneity',
        'thought': 'Negative ruminations, worthlessness, guilt. No suicidal ideation.',
        'perception': 'No hallucinations',
        'cognition': 'Attention and concentration mildly impaired',
        'insight': 'Good - aware of illness',
        'suicide_risk': 'Low',
        'diagnosis': 'Major Depressive Disorder, Single Episode, Moderate',
        'treatment': 'SSRI (Escitalopram 10mg OD), Supportive psychotherapy, Sleep hygiene counseling',
        'follow_up': 'Review in 2 weeks to assess response to treatment',
      },
    ),
    QuickFillTemplate(
      label: 'Anxiety (GAD)',
      icon: Icons.psychology_alt_rounded,
      color: Colors.orange,
      data: {
        'chief_complaint': 'Excessive worry, restlessness, inability to relax',
        'duration': '6 months or more',
        'symptoms': ['Anxiety', 'Sleep Disturbance', 'Concentration Issues', 'Fatigue'],
        'mood': 'Anxious, tense, apprehensive',
        'affect': 'Anxious, worried',
        'speech': 'Normal rate, slightly pressured',
        'thought': 'Excessive worry about multiple domains (work, health, family). No obsessions.',
        'perception': 'No hallucinations',
        'cognition': 'Difficulty concentrating due to worry',
        'insight': 'Good',
        'suicide_risk': 'None',
        'diagnosis': 'Generalized Anxiety Disorder',
        'treatment': 'SSRI (Sertraline 50mg OD), CBT referral, Relaxation techniques, Lifestyle modifications',
        'follow_up': 'Review in 2-4 weeks',
      },
    ),
    QuickFillTemplate(
      label: 'Panic Disorder',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
      data: {
        'chief_complaint': 'Recurrent unexpected panic attacks with fear of dying',
        'duration': '1-3 months',
        'symptoms': ['Panic Attacks', 'Anxiety', 'Sleep Disturbance'],
        'mood': 'Anxious between attacks, fearful of next episode',
        'affect': 'Apprehensive',
        'speech': 'Normal',
        'thought': 'Fear of having heart attack/dying during attacks. Avoidance behavior developing.',
        'perception': 'Derealization during attacks (occasional)',
        'cognition': 'Intact',
        'insight': 'Good',
        'suicide_risk': 'None',
        'diagnosis': 'Panic Disorder without Agoraphobia',
        'treatment': 'SSRI (Paroxetine 20mg OD), PRN Alprazolam 0.25mg for acute attacks, Breathing exercises',
        'follow_up': 'Review in 2 weeks',
      },
    ),
    QuickFillTemplate(
      label: 'OCD',
      icon: Icons.repeat_rounded,
      color: Colors.purple,
      data: {
        'chief_complaint': 'Intrusive thoughts, repetitive behaviors, excessive cleaning/checking',
        'duration': 'Several months to years',
        'symptoms': ['Obsessions', 'Compulsions', 'Anxiety', 'Sleep Disturbance'],
        'mood': 'Anxious, distressed by symptoms',
        'affect': 'Anxious',
        'speech': 'Normal',
        'thought': 'Obsessional thoughts (contamination/harm/symmetry). Recognizes thoughts as excessive.',
        'perception': 'No hallucinations',
        'cognition': 'Intact but preoccupied with obsessions',
        'insight': 'Good - ego-dystonic symptoms',
        'suicide_risk': 'None',
        'diagnosis': 'Obsessive-Compulsive Disorder',
        'treatment': 'High-dose SSRI (Fluoxetine 40-60mg), ERP therapy referral, Psychoeducation',
        'follow_up': 'Review in 4 weeks',
      },
    ),
    QuickFillTemplate(
      label: 'PTSD',
      icon: Icons.flash_on_rounded,
      color: Colors.deepOrange,
      data: {
        'chief_complaint': 'Nightmares, flashbacks, avoidance after traumatic event',
        'duration': '1 month or more post-trauma',
        'symptoms': ['Sleep Disturbance', 'Anxiety', 'Concentration Issues', 'Memory Problems'],
        'mood': 'Anxious, irritable, emotionally numb',
        'affect': 'Restricted, hypervigilant',
        'speech': 'Normal',
        'thought': 'Intrusive memories, flashbacks of trauma. Avoidance of reminders.',
        'perception': 'Flashbacks (dissociative), hypervigilance',
        'cognition': 'Concentration impaired, memory gaps around trauma',
        'insight': 'Good',
        'suicide_risk': 'Low to Moderate - assess carefully',
        'diagnosis': 'Post-Traumatic Stress Disorder',
        'treatment': 'SSRI (Sertraline 50mg), Trauma-focused CBT or EMDR referral, Sleep hygiene',
        'follow_up': 'Review in 2 weeks',
      },
    ),
    QuickFillTemplate(
      label: 'Bipolar (Mania)',
      icon: Icons.trending_up_rounded,
      color: Colors.amber,
      data: {
        'chief_complaint': 'Elevated mood, decreased sleep, increased energy, impulsive behavior',
        'duration': '1 week or more',
        'symptoms': ['Sleep Disturbance', 'Concentration Issues'],
        'mood': 'Elevated, euphoric, irritable',
        'affect': 'Expansive, labile',
        'speech': 'Pressured, rapid, loud',
        'thought': 'Grandiose ideas, flight of ideas, decreased need for sleep',
        'perception': 'May have grandiose delusions in severe cases',
        'cognition': 'Distractible, poor judgment',
        'insight': 'Poor - lacks awareness of illness',
        'suicide_risk': 'Moderate - impulsivity risk',
        'diagnosis': 'Bipolar I Disorder, Current Episode Manic',
        'treatment': 'Mood stabilizer (Lithium/Valproate), Antipsychotic if severe, Hospitalization if needed',
        'follow_up': 'Urgent review in 1 week, consider admission',
      },
    ),
    QuickFillTemplate(
      label: 'Schizophrenia',
      icon: Icons.blur_on_rounded,
      color: Colors.blueGrey,
      data: {
        'chief_complaint': 'Hearing voices, paranoid beliefs, social withdrawal',
        'duration': '6 months or more',
        'symptoms': ['Sleep Disturbance', 'Concentration Issues', 'Memory Problems'],
        'mood': 'Flat, suspicious',
        'affect': 'Blunted, inappropriate at times',
        'speech': 'May be disorganized, poverty of speech',
        'thought': 'Paranoid delusions, thought broadcasting/insertion. Disorganized thinking.',
        'perception': 'Auditory hallucinations (voices commenting/commanding)',
        'cognition': 'Impaired attention and executive function',
        'insight': 'Poor',
        'suicide_risk': 'Moderate - especially in command hallucinations',
        'diagnosis': 'Schizophrenia, Paranoid type',
        'treatment': 'Atypical antipsychotic (Risperidone 2-4mg), Family psychoeducation, Rehabilitation',
        'follow_up': 'Review in 1-2 weeks',
      },
    ),
    QuickFillTemplate(
      label: 'Insomnia',
      icon: Icons.nightlight_round,
      color: Colors.teal,
      data: {
        'chief_complaint': 'Difficulty falling asleep, frequent awakenings, non-restorative sleep',
        'duration': '3 months or more',
        'symptoms': ['Sleep Disturbance', 'Fatigue', 'Concentration Issues'],
        'mood': 'Tired, irritable',
        'affect': 'Appropriate',
        'speech': 'Normal',
        'thought': 'Worry about sleep, daytime fatigue',
        'perception': 'No hallucinations',
        'cognition': 'Mild concentration difficulties due to fatigue',
        'insight': 'Good',
        'suicide_risk': 'None',
        'diagnosis': 'Chronic Insomnia Disorder',
        'treatment': 'Sleep hygiene education, CBT-I referral, Short-term hypnotic if severe (Zolpidem 5mg)',
        'follow_up': 'Review in 2-4 weeks',
      },
    ),
  ];
}
