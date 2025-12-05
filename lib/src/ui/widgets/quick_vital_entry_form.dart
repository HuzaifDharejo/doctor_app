import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../screens/vital_signs_screen.dart';

/// Quick Vital Entry Form - Optimized for fast data entry during patient visits
/// Features:
/// - Large, touch-friendly input fields (exam-room friendly)
/// - Quick presets for common vital sign values
/// - Auto-save with visual feedback
/// - Threshold-based alerts with color coding
/// - Minimal interface for focus and speed
/// - Voice input ready structure
class QuickVitalEntryForm extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;
  final VoidCallback? onSaved;

  const QuickVitalEntryForm({
    super.key,
    required this.patientId,
    required this.patientName,
    this.onSaved,
  });

  @override
  ConsumerState<QuickVitalEntryForm> createState() => _QuickVitalEntryFormState();
}

class _QuickVitalEntryFormState extends ConsumerState<QuickVitalEntryForm> {
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _hrController;
  late TextEditingController _tempController;
  late TextEditingController _respRateController;
  late TextEditingController _spo2Controller;
  late TextEditingController _weightController;
  late TextEditingController _painLevelController;
  late TextEditingController _glucoseController;

  bool _isSaving = false;
  bool _autoSaveEnabled = true;
  String _lastSavedTime = '';
  Map<String, bool> _alertFlags = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _systolicController = TextEditingController();
    _diastolicController = TextEditingController();
    _hrController = TextEditingController();
    _tempController = TextEditingController();
    _respRateController = TextEditingController();
    _spo2Controller = TextEditingController();
    _weightController = TextEditingController();
    _painLevelController = TextEditingController();
    _glucoseController = TextEditingController();

    // Add listeners for auto-save
    _systolicController.addListener(_checkAndAutoSave);
    _diastolicController.addListener(_checkAndAutoSave);
    _hrController.addListener(_checkAndAutoSave);
    _tempController.addListener(_checkAndAutoSave);
    _respRateController.addListener(_checkAndAutoSave);
    _spo2Controller.addListener(_checkAndAutoSave);
    _weightController.addListener(_checkAndAutoSave);
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _respRateController.dispose();
    _spo2Controller.dispose();
    _weightController.dispose();
    _painLevelController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  void _checkAndAutoSave() {
    if (_autoSaveEnabled && _hasAnyInput()) {
      _autoSaveVitals();
    }
  }

  bool _hasAnyInput() {
    return _systolicController.text.isNotEmpty ||
        _diastolicController.text.isNotEmpty ||
        _hrController.text.isNotEmpty ||
        _tempController.text.isNotEmpty ||
        _respRateController.text.isNotEmpty ||
        _spo2Controller.text.isNotEmpty ||
        _weightController.text.isNotEmpty;
  }

  void _setPreset(String field, String value) {
    switch (field) {
      case 'systolic':
        _systolicController.text = value;
        FocusScope.of(context).nextFocus();
        break;
      case 'diastolic':
        _diastolicController.text = value;
        FocusScope.of(context).nextFocus();
        break;
      case 'hr':
        _hrController.text = value;
        FocusScope.of(context).nextFocus();
        break;
      case 'temp':
        _tempController.text = value;
        FocusScope.of(context).nextFocus();
        break;
      case 'rr':
        _respRateController.text = value;
        FocusScope.of(context).nextFocus();
        break;
      case 'spo2':
        _spo2Controller.text = value;
        FocusScope.of(context).nextFocus();
        break;
    }
  }

  void _setNormalPresets() {
    _systolicController.text = '120';
    _diastolicController.text = '80';
    _hrController.text = '72';
    _tempController.text = '37.0';
    _respRateController.text = '16';
    _spo2Controller.text = '98';
  }

  Future<void> _autoSaveVitals() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Properly await the database provider
      final db = await ref.read(doctorDbProvider.future);
      
      final vitalSign = VitalSignsCompanion(
        patientId: Value(widget.patientId),
        recordedAt: Value(DateTime.now()),
        systolicBp: _systolicController.text.isNotEmpty
            ? Value(double.tryParse(_systolicController.text))
            : const Value(null),
        diastolicBp: _diastolicController.text.isNotEmpty
            ? Value(double.tryParse(_diastolicController.text))
            : const Value(null),
        heartRate: _hrController.text.isNotEmpty
            ? Value(int.tryParse(_hrController.text))
            : const Value(null),
        temperature: _tempController.text.isNotEmpty
            ? Value(double.tryParse(_tempController.text))
            : const Value(null),
        respiratoryRate: _respRateController.text.isNotEmpty
            ? Value(int.tryParse(_respRateController.text))
            : const Value(null),
        oxygenSaturation: _spo2Controller.text.isNotEmpty
            ? Value(double.tryParse(_spo2Controller.text))
            : const Value(null),
        weight: _weightController.text.isNotEmpty
            ? Value(double.tryParse(_weightController.text))
            : const Value(null),
        painLevel: _painLevelController.text.isNotEmpty
            ? Value(int.tryParse(_painLevelController.text))
            : const Value(null),
        bloodGlucose: Value(_glucoseController.text),
      );

      await db.insertVitalSigns(vitalSign);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _lastSavedTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });

        // Check thresholds
        _checkThresholds();

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vitals saved at $_lastSavedTime'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vitals: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkThresholds() {
    _alertFlags.clear();

    // Check BP
    if (_systolicController.text.isNotEmpty) {
      final systolic = double.tryParse(_systolicController.text) ?? 0;
      if (systolic > 180) {
        _alertFlags['bp_high'] = true;
      }
    }

    // Check HR
    if (_hrController.text.isNotEmpty) {
      final hr = int.tryParse(_hrController.text) ?? 0;
      if (hr < 40 || hr > 120) {
        _alertFlags['hr_abnormal'] = true;
      }
    }

    // Check SpO2
    if (_spo2Controller.text.isNotEmpty) {
      final spo2 = double.tryParse(_spo2Controller.text) ?? 0;
      if (spo2 < 94) {
        _alertFlags['spo2_low'] = true;
      }
    }

    // Show alerts if any
    if (_alertFlags.isNotEmpty) {
      _showThresholdAlerts();
    }
  }

  void _showThresholdAlerts() {
    String alertMessage = 'ALERT: ';
    final alerts = <String>[];

    if (_alertFlags['bp_high'] == true) {
      alerts.add('BP critically high (>180)');
    }
    if (_alertFlags['hr_abnormal'] == true) {
      alerts.add('Heart rate abnormal (<40 or >120)');
    }
    if (_alertFlags['spo2_low'] == true) {
      alerts.add('SpO2 low (<94%)');
    }

    alertMessage += alerts.join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vital Sign Alert'),
        content: Text(alertMessage),
        actions: [
          AppButton.primary(
            label: 'Acknowledge',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with auto-save status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text(
                    'Quick Vital Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_lastSavedTime.isNotEmpty)
                    Text(
                      'Last saved: $_lastSavedTime',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (_isSaving)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_lastSavedTime.isNotEmpty)
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),

          // Blood Pressure Section
          _buildVitalSection(
            title: 'Blood Pressure',
            icon: Icons.favorite,
            color: Colors.red,
            isDark: isDark,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Systolic',
                      controller: _systolicController,
                      suffix: 'mmHg',
                    ),
                  ),
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Diastolic',
                      controller: _diastolicController,
                      suffix: 'mmHg',
                    ),
                  ),
                ],
              ),
              // Quick presets for BP
              Row(
                spacing: 8,
                children: [
                  _buildPresetButton('Normal\n120/80', () {
                    _systolicController.text = '120';
                    _diastolicController.text = '80';
                  }),
                  _buildPresetButton('Elevated\n130/80', () {
                    _systolicController.text = '130';
                    _diastolicController.text = '80';
                  }),
                  _buildPresetButton('Stage 1\n140/90', () {
                    _systolicController.text = '140';
                    _diastolicController.text = '90';
                  }),
                ],
              ),
            ],
          ),

          // Heart Rate Section
          _buildVitalSection(
            title: 'Heart Rate & Respiration',
            icon: Icons.favorite_border,
            color: Colors.orange,
            isDark: isDark,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Heart Rate',
                      controller: _hrController,
                      suffix: 'bpm',
                    ),
                  ),
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Resp. Rate',
                      controller: _respRateController,
                      suffix: 'br/min',
                    ),
                  ),
                ],
              ),
              // Quick presets
              Row(
                spacing: 8,
                children: [
                  _buildPresetButton('HR: 60', () => _setPreset('hr', '60')),
                  _buildPresetButton('HR: 72', () => _setPreset('hr', '72')),
                  _buildPresetButton('HR: 80', () => _setPreset('hr', '80')),
                  _buildPresetButton('RR: 16', () => _setPreset('rr', '16')),
                ],
              ),
            ],
          ),

          // Temperature & Oxygen Section
          _buildVitalSection(
            title: 'Temperature & Oxygen',
            icon: Icons.thermostat_outlined,
            color: Colors.blue,
            isDark: isDark,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Temperature',
                      controller: _tempController,
                      suffix: '°C',
                    ),
                  ),
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'SpO2',
                      controller: _spo2Controller,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
              // Quick presets
              Row(
                spacing: 8,
                children: [
                  _buildPresetButton('Temp: 37°', () => _setPreset('temp', '37.0')),
                  _buildPresetButton('Temp: 38°', () => _setPreset('temp', '38.0')),
                  _buildPresetButton('SpO2: 98%', () => _setPreset('spo2', '98')),
                  _buildPresetButton('SpO2: 95%', () => _setPreset('spo2', '95')),
                ],
              ),
            ],
          ),

          // Weight Section
          _buildVitalSection(
            title: 'Weight',
            icon: Icons.monitor_weight,
            color: Colors.purple,
            isDark: isDark,
            children: [
              _buildLargeInputField(
                label: 'Weight',
                controller: _weightController,
                suffix: 'kg',
              ),
            ],
          ),

          // Pain & Blood Glucose Section
          _buildVitalSection(
            title: 'Pain & Blood Glucose',
            icon: Icons.health_and_safety_outlined,
            color: Colors.teal,
            isDark: isDark,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Pain Level',
                      controller: _painLevelController,
                      suffix: '/10',
                    ),
                  ),
                  Expanded(
                    child: _buildLargeInputField(
                      label: 'Blood Glucose',
                      controller: _glucoseController,
                      suffix: 'mg/dL',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Action Buttons
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Vitals'),
                  onPressed: _isSaving ? null : _autoSaveVitals,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Set Normal'),
                  onPressed: _setNormalPresets,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),
              ),
            ],
          ),

          // View History Link
          Center(
            child: AppButton.tertiary(
              label: 'View History & Charts',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VitalSignsScreen(
                      patientId: widget.patientId,
                      patientName: widget.patientName,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a vital sign section with title, icon, and children
  Widget _buildVitalSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  /// Build large input field optimized for touch input
  Widget _buildLargeInputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffix: Text(suffix, style: const TextStyle(fontSize: 12)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      ),
    );
  }

  /// Build preset button for quick value entry
  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.blue.shade900,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

