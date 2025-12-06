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
