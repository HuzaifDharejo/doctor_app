import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/clinical_calculator_service.dart';
import '../../theme/app_theme.dart';

/// Clinical Calculators Screen
/// Provides common medical calculations for doctors
class ClinicalCalculatorsScreen extends ConsumerStatefulWidget {
  const ClinicalCalculatorsScreen({super.key, this.patient});
  
  final dynamic patient; // Optional patient for auto-fill

  @override
  ConsumerState<ClinicalCalculatorsScreen> createState() => _ClinicalCalculatorsScreenState();
}

class _ClinicalCalculatorsScreenState extends ConsumerState<ClinicalCalculatorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_CalculatorCategory> _categories = [
    _CalculatorCategory(
      name: 'Basic',
      icon: Icons.straighten,
      color: const Color(0xFF10B981),
      calculators: ['BMI', 'BSA', 'IBW'],
    ),
    _CalculatorCategory(
      name: 'Renal',
      icon: Icons.water_drop,
      color: const Color(0xFF3B82F6),
      calculators: ['eGFR', 'CrCl'],
    ),
    _CalculatorCategory(
      name: 'Cardiac',
      icon: Icons.favorite,
      color: const Color(0xFFEF4444),
      calculators: ['CHADS-VASc'],
    ),
    _CalculatorCategory(
      name: 'Scores',
      icon: Icons.calculate,
      color: const Color(0xFF8B5CF6),
      calculators: ['Wells DVT', 'CURB-65'],
    ),
    _CalculatorCategory(
      name: 'Pediatric',
      icon: Icons.child_care,
      color: const Color(0xFFEC4899),
      calculators: ['Dose', 'Fluids'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Clinical Calculators'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          tabs: _categories.map((c) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 18),
                const SizedBox(width: 6),
                Text(c.name),
              ],
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BasicCalculatorsTab(patient: widget.patient),
          _RenalCalculatorsTab(patient: widget.patient),
          _CardiacCalculatorsTab(patient: widget.patient),
          _ClinicalScoresTab(patient: widget.patient),
          _PediatricCalculatorsTab(patient: widget.patient),
        ],
      ),
    );
  }
}

class _CalculatorCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> calculators;

  _CalculatorCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.calculators,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// BASIC CALCULATORS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _BasicCalculatorsTab extends StatefulWidget {
  const _BasicCalculatorsTab({this.patient});
  final dynamic patient;

  @override
  State<_BasicCalculatorsTab> createState() => _BasicCalculatorsTabState();
}

class _BasicCalculatorsTabState extends State<_BasicCalculatorsTab> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool _isMale = true;
  BmiResult? _bmiResult;
  double? _bsaResult;
  double? _ibwResult;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      if (widget.patient.weight != null) {
        _weightController.text = widget.patient.weight.toString();
      }
      if (widget.patient.height != null) {
        _heightController.text = widget.patient.height.toString();
      }
      _isMale = widget.patient.gender?.toLowerCase() != 'female';
    }
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (weight != null && height != null && weight > 0 && height > 0) {
      setState(() {
        _bmiResult = ClinicalCalculatorService.calculateBmi(
          weightKg: weight,
          heightCm: height,
        );
        _bsaResult = ClinicalCalculatorService.calculateBsa(
          weightKg: weight,
          heightCm: height,
        );
        _ibwResult = ClinicalCalculatorService.calculateIbw(
          heightCm: height,
          isMale: _isMale,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            context,
            title: 'BMI, BSA & Ideal Body Weight',
            icon: Icons.straighten,
            color: const Color(0xFF10B981),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Gender: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: _isMale,
                      onSelected: (selected) {
                        setState(() => _isMale = true);
                        _calculate();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: !_isMale,
                      onSelected: (selected) {
                        setState(() => _isMale = false);
                        _calculate();
                      },
                    ),
                  ],
                ),
                if (_bmiResult != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ResultRow(label: 'BMI', value: '${_bmiResult!.bmi} kg/m²', highlight: true),
                  _ResultRow(label: 'Category', value: _bmiResult!.category),
                  _ResultRow(label: 'Risk', value: _bmiResult!.risk),
                  _ResultRow(
                    label: 'Ideal Weight Range',
                    value: '${_bmiResult!.idealWeightRange.$1} - ${_bmiResult!.idealWeightRange.$2} kg',
                  ),
                  const Divider(),
                  _ResultRow(label: 'BSA', value: '$_bsaResult m²', highlight: true),
                  _ResultRow(label: 'Ideal Body Weight', value: '$_ibwResult kg', highlight: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RENAL CALCULATORS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _RenalCalculatorsTab extends StatefulWidget {
  const _RenalCalculatorsTab({this.patient});
  final dynamic patient;

  @override
  State<_RenalCalculatorsTab> createState() => _RenalCalculatorsTabState();
}

class _RenalCalculatorsTabState extends State<_RenalCalculatorsTab> {
  final _creatinineController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isMale = true;
  GfrResult? _gfrResult;
  double? _crclResult;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      if (widget.patient.age != null) {
        _ageController.text = widget.patient.age.toString();
      }
      if (widget.patient.weight != null) {
        _weightController.text = widget.patient.weight.toString();
      }
      _isMale = widget.patient.gender?.toLowerCase() != 'female';
    }
  }

  void _calculate() {
    final creatinine = double.tryParse(_creatinineController.text);
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);

    if (creatinine != null && age != null && creatinine > 0 && age > 0) {
      setState(() {
        _gfrResult = ClinicalCalculatorService.calculateGfr(
          creatinine: creatinine,
          age: age,
          isMale: _isMale,
        );
        
        if (weight != null && weight > 0) {
          _crclResult = ClinicalCalculatorService.calculateCrCl(
            creatinine: creatinine,
            age: age,
            weightKg: weight,
            isMale: _isMale,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            context,
            title: 'eGFR & Creatinine Clearance',
            icon: Icons.water_drop,
            color: const Color(0xFF3B82F6),
            child: Column(
              children: [
                TextField(
                  controller: _creatinineController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Serum Creatinine (mg/dL)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  ),
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age (years)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          helperText: 'For CrCl',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Gender: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Male'),
                      selected: _isMale,
                      onSelected: (selected) {
                        setState(() => _isMale = true);
                        _calculate();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Female'),
                      selected: !_isMale,
                      onSelected: (selected) {
                        setState(() => _isMale = false);
                        _calculate();
                      },
                    ),
                  ],
                ),
                if (_gfrResult != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ResultRow(label: 'eGFR (CKD-EPI 2021)', value: '${_gfrResult!.gfr} mL/min/1.73m²', highlight: true),
                  _ResultRow(label: 'CKD Stage', value: _gfrResult!.stage),
                  _ResultRow(label: 'Description', value: _gfrResult!.description),
                  if (_crclResult != null) ...[
                    const Divider(),
                    _ResultRow(label: 'CrCl (Cockcroft-Gault)', value: '$_crclResult mL/min', highlight: true),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARDIAC CALCULATORS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CardiacCalculatorsTab extends StatefulWidget {
  const _CardiacCalculatorsTab({this.patient});
  final dynamic patient;

  @override
  State<_CardiacCalculatorsTab> createState() => _CardiacCalculatorsTabState();
}

class _CardiacCalculatorsTabState extends State<_CardiacCalculatorsTab> {
  bool _hasChf = false;
  bool _hasHypertension = false;
  bool _hasDiabetes = false;
  bool _hasStrokeTiaVte = false;
  bool _hasVascularDisease = false;
  bool _isFemale = false;
  int _age = 65;
  ChadsVascResult? _result;

  void _calculate() {
    setState(() {
      _result = ClinicalCalculatorService.calculateChadsVasc(
        hasChf: _hasChf,
        hasHypertension: _hasHypertension,
        age: _age,
        hasDiabetes: _hasDiabetes,
        hasStrokeTiaVte: _hasStrokeTiaVte,
        hasVascularDisease: _hasVascularDisease,
        isFemale: _isFemale,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _age = (widget.patient?.age as int?) ?? 65;
      _isFemale = widget.patient?.gender?.toLowerCase() == 'female';
    }
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            context,
            title: 'CHA₂DS₂-VASc Score',
            subtitle: 'Atrial Fibrillation Stroke Risk',
            icon: Icons.favorite,
            color: const Color(0xFFEF4444),
            child: Column(
              children: [
                _buildCheckboxTile('Congestive Heart Failure', _hasChf, (v) {
                  setState(() => _hasChf = v ?? false);
                  _calculate();
                }),
                _buildCheckboxTile('Hypertension', _hasHypertension, (v) {
                  setState(() => _hasHypertension = v ?? false);
                  _calculate();
                }),
                _buildCheckboxTile('Diabetes', _hasDiabetes, (v) {
                  setState(() => _hasDiabetes = v ?? false);
                  _calculate();
                }),
                _buildCheckboxTile('Stroke / TIA / VTE', _hasStrokeTiaVte, (v) {
                  setState(() => _hasStrokeTiaVte = v ?? false);
                  _calculate();
                }),
                _buildCheckboxTile('Vascular Disease (MI, PAD, Aortic plaque)', _hasVascularDisease, (v) {
                  setState(() => _hasVascularDisease = v ?? false);
                  _calculate();
                }),
                _buildCheckboxTile('Female', _isFemale, (v) {
                  setState(() => _isFemale = v ?? false);
                  _calculate();
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Age: '),
                    Expanded(
                      child: Slider(
                        value: _age.toDouble(),
                        min: 18,
                        max: 100,
                        divisions: 82,
                        label: '$_age years',
                        onChanged: (v) {
                          setState(() => _age = v.round());
                          _calculate();
                        },
                      ),
                    ),
                    Text('$_age years'),
                  ],
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _ResultRow(label: 'Score', value: '${_result!.score}', highlight: true),
                  _ResultRow(label: 'Risk Level', value: _result!.risk),
                  _ResultRow(label: 'Annual Stroke Risk', value: '${_result!.annualStrokeRisk}%'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _result!.recommendation,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLINICAL SCORES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ClinicalScoresTab extends StatefulWidget {
  const _ClinicalScoresTab({this.patient});
  final dynamic patient;

  @override
  State<_ClinicalScoresTab> createState() => _ClinicalScoresTabState();
}

class _ClinicalScoresTabState extends State<_ClinicalScoresTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            context,
            title: 'Wells Score for DVT',
            icon: Icons.bloodtype,
            color: const Color(0xFF8B5CF6),
            child: const _WellsDvtCalculator(),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'CURB-65 Pneumonia Severity',
            icon: Icons.air,
            color: const Color(0xFFF59E0B),
            child: const _Curb65Calculator(),
          ),
        ],
      ),
    );
  }
}

class _WellsDvtCalculator extends StatefulWidget {
  const _WellsDvtCalculator();

  @override
  State<_WellsDvtCalculator> createState() => _WellsDvtCalculatorState();
}

class _WellsDvtCalculatorState extends State<_WellsDvtCalculator> {
  bool _activeCancer = false;
  bool _paralysis = false;
  bool _bedridden = false;
  bool _tenderness = false;
  bool _legSwollen = false;
  bool _calfSwelling = false;
  bool _pittingEdema = false;
  bool _collateralVeins = false;
  bool _previousDvt = false;
  bool _alternativeDx = false;
  WellsDvtResult? _result;

  void _calculate() {
    setState(() {
      _result = ClinicalCalculatorService.calculateWellsDvt(
        activeCancer: _activeCancer,
        paralysisParesis: _paralysis,
        recentBedridden: _bedridden,
        localizedTenderness: _tenderness,
        entireLegSwollen: _legSwollen,
        calfSwelling3cm: _calfSwelling,
        pittingEdema: _pittingEdema,
        collateralVeins: _collateralVeins,
        previousDvt: _previousDvt,
        alternativeDiagnosisLikely: _alternativeDx,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCheck('Active cancer (treatment within 6 months)', _activeCancer, (v) {
          setState(() => _activeCancer = v ?? false);
          _calculate();
        }),
        _buildCheck('Paralysis/paresis of lower extremity', _paralysis, (v) {
          setState(() => _paralysis = v ?? false);
          _calculate();
        }),
        _buildCheck('Recently bedridden >3 days or major surgery', _bedridden, (v) {
          setState(() => _bedridden = v ?? false);
          _calculate();
        }),
        _buildCheck('Localized tenderness along deep venous system', _tenderness, (v) {
          setState(() => _tenderness = v ?? false);
          _calculate();
        }),
        _buildCheck('Entire leg swollen', _legSwollen, (v) {
          setState(() => _legSwollen = v ?? false);
          _calculate();
        }),
        _buildCheck('Calf swelling >3cm compared to other leg', _calfSwelling, (v) {
          setState(() => _calfSwelling = v ?? false);
          _calculate();
        }),
        _buildCheck('Pitting edema (greater in symptomatic leg)', _pittingEdema, (v) {
          setState(() => _pittingEdema = v ?? false);
          _calculate();
        }),
        _buildCheck('Collateral superficial veins', _collateralVeins, (v) {
          setState(() => _collateralVeins = v ?? false);
          _calculate();
        }),
        _buildCheck('Previous documented DVT', _previousDvt, (v) {
          setState(() => _previousDvt = v ?? false);
          _calculate();
        }),
        _buildCheck('Alternative diagnosis as likely (-2)', _alternativeDx, (v) {
          setState(() => _alternativeDx = v ?? false);
          _calculate();
        }),
        if (_result != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _ResultRow(label: 'Score', value: '${_result!.score}', highlight: true),
          _ResultRow(label: 'Risk', value: _result!.risk),
          _ResultRow(label: 'DVT Probability', value: '~${_result!.probability}%'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(child: Text(_result!.recommendation)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheck(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _Curb65Calculator extends StatefulWidget {
  const _Curb65Calculator();

  @override
  State<_Curb65Calculator> createState() => _Curb65CalculatorState();
}

class _Curb65CalculatorState extends State<_Curb65Calculator> {
  bool _confusion = false;
  final _ureaController = TextEditingController(text: '15');
  final _rrController = TextEditingController(text: '20');
  final _sbpController = TextEditingController(text: '120');
  final _dbpController = TextEditingController(text: '80');
  int _age = 60;
  Curb65Result? _result;

  void _calculate() {
    final urea = double.tryParse(_ureaController.text) ?? 15;
    final rr = int.tryParse(_rrController.text) ?? 20;
    final sbp = int.tryParse(_sbpController.text) ?? 120;
    final dbp = int.tryParse(_dbpController.text) ?? 80;

    setState(() {
      _result = ClinicalCalculatorService.calculateCurb65(
        confusion: _confusion,
        urea: urea,
        respiratoryRate: rr,
        systolicBp: sbp,
        diastolicBp: dbp,
        age: _age,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Confusion (new disorientation)'),
          value: _confusion,
          onChanged: (v) {
            setState(() => _confusion = v ?? false);
            _calculate();
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ureaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Urea (mg/dL)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rrController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'RR (/min)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sbpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Systolic BP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _dbpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Diastolic BP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  isDense: true,
                ),
                onChanged: (_) => _calculate(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Age: '),
            Expanded(
              child: Slider(
                value: _age.toDouble(),
                min: 18,
                max: 100,
                divisions: 82,
                label: '$_age years',
                onChanged: (v) {
                  setState(() => _age = v.round());
                  _calculate();
                },
              ),
            ),
            Text('$_age'),
          ],
        ),
        if (_result != null) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _ResultRow(label: 'CURB-65 Score', value: '${_result!.score}/5', highlight: true),
          _ResultRow(label: 'Severity', value: _result!.severity),
          _ResultRow(label: '30-Day Mortality', value: '${_result!.mortality30Day}%'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(_result!.recommendation)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PEDIATRIC CALCULATORS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PediatricCalculatorsTab extends StatefulWidget {
  const _PediatricCalculatorsTab({this.patient});
  final dynamic patient;

  @override
  State<_PediatricCalculatorsTab> createState() => _PediatricCalculatorsTabState();
}

class _PediatricCalculatorsTabState extends State<_PediatricCalculatorsTab> {
  final _weightController = TextEditingController();
  final _dosePerKgController = TextEditingController();
  final _maxDoseController = TextEditingController();
  final _frequencyController = TextEditingController(text: 'Three times daily');
  PediatricDoseResult? _doseResult;
  MaintenanceFluidsResult? _fluidResult;

  void _calculateDose() {
    final weight = double.tryParse(_weightController.text);
    final dosePerKg = double.tryParse(_dosePerKgController.text);
    final maxDose = double.tryParse(_maxDoseController.text);

    if (weight != null && dosePerKg != null && maxDose != null) {
      setState(() {
        _doseResult = ClinicalCalculatorService.calculatePediatricDose(
          weightKg: weight,
          dosePerKg: dosePerKg,
          maxDose: maxDose,
          frequency: _frequencyController.text,
        );
      });
    }
  }

  void _calculateFluids() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      setState(() {
        _fluidResult = ClinicalCalculatorService.calculateMaintenanceFluids(
          weightKg: weight,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            context,
            title: 'Weight-Based Dosing',
            icon: Icons.medication,
            color: const Color(0xFFEC4899),
            child: Column(
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Patient Weight (kg)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  ),
                  onChanged: (_) {
                    _calculateDose();
                    _calculateFluids();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dosePerKgController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Dose (mg/kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculateDose(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxDoseController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Dose (mg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        ),
                        onChanged: (_) => _calculateDose(),
                      ),
                    ),
                  ],
                ),
                if (_doseResult != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  _ResultRow(label: 'Calculated Dose', value: '${_doseResult!.calculatedDose} mg'),
                  _ResultRow(label: 'Final Dose', value: '${_doseResult!.finalDose} mg', highlight: true),
                  if (_doseResult!.warning != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_doseResult!.warning!, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'Maintenance Fluids (Holliday-Segar)',
            icon: Icons.local_drink,
            color: const Color(0xFF06B6D4),
            child: Column(
              children: [
                Text(
                  'Enter weight above to calculate',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                if (_fluidResult != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  _ResultRow(label: 'Daily Requirement', value: '${_fluidResult!.mlPerDay} mL/day', highlight: true),
                  _ResultRow(label: 'Hourly Rate', value: '${_fluidResult!.mlPerHour} mL/hr', highlight: true),
                  const SizedBox(height: 8),
                  Text(
                    _fluidResult!.formula,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _buildCard(
  BuildContext context, {
  required String title,
  String? subtitle,
  required IconData icon,
  required Color color,
  required Widget child,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              fontSize: highlight ? 16 : 14,
              color: highlight ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
