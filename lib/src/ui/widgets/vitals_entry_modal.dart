import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/encounter_provider.dart';
import '../../theme/app_theme.dart';

/// Quick Vitals Entry Modal for recording vitals during an encounter
class VitalsEntryModal extends ConsumerStatefulWidget {
  const VitalsEntryModal({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.onSaved,
  });

  final int encounterId;
  final int patientId;
  final void Function(int vitalId)? onSaved;

  @override
  ConsumerState<VitalsEntryModal> createState() => _VitalsEntryModalState();
}

class _VitalsEntryModalState extends ConsumerState<VitalsEntryModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for vital signs
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSatController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bloodGlucoseController = TextEditingController();
  final _notesController = TextEditingController();

  int _painLevel = 0;
  bool _isLoading = false;
  double? _calculatedBMI;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSatController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bloodGlucoseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    
    if (weight != null && height != null && height > 0) {
      setState(() {
        _calculatedBMI = weight / ((height / 100) * (height / 100));
      });
    } else {
      setState(() => _calculatedBMI = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildBloodPressureCard(),
                  const SizedBox(height: 16),
                  _buildHeartAndTempCard(),
                  const SizedBox(height: 16),
                  _buildRespiratoryCard(),
                  const SizedBox(height: 16),
                  _buildBodyMeasurementsCard(),
                  const SizedBox(height: 16),
                  _buildPainScaleCard(),
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Color(0xFFEC4899),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Vital Signs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Enter patient vital measurements',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    return _buildCard(
      title: 'Blood Pressure',
      icon: Icons.favorite,
      iconColor: const Color(0xFFEF4444),
      child: Row(
        children: [
          Expanded(
            child: _buildVitalField(
              controller: _systolicController,
              label: 'Systolic',
              hint: '120',
              suffix: 'mmHg',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = int.tryParse(value);
                  if (num == null || num < 50 || num > 300) {
                    return 'Invalid';
                  }
                }
                return null;
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text(
              '/',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: _buildVitalField(
              controller: _diastolicController,
              label: 'Diastolic',
              hint: '80',
              suffix: 'mmHg',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = int.tryParse(value);
                  if (num == null || num < 30 || num > 200) {
                    return 'Invalid';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAndTempCard() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Heart Rate',
            icon: Icons.timeline,
            iconColor: const Color(0xFFEC4899),
            child: _buildVitalField(
              controller: _heartRateController,
              label: '',
              hint: '72',
              suffix: 'bpm',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = int.tryParse(value);
                  if (num == null || num < 30 || num > 250) {
                    return 'Invalid';
                  }
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            title: 'Temperature',
            icon: Icons.thermostat,
            iconColor: const Color(0xFFF59E0B),
            child: _buildVitalField(
              controller: _temperatureController,
              label: '',
              hint: '37.0',
              suffix: '°C',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 34 || num > 43) {
                    return 'Invalid';
                  }
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRespiratoryCard() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Respiratory Rate',
            icon: Icons.air,
            iconColor: const Color(0xFF14B8A6),
            child: _buildVitalField(
              controller: _respiratoryRateController,
              label: '',
              hint: '16',
              suffix: '/min',
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            title: 'SpO2',
            icon: Icons.water_drop,
            iconColor: const Color(0xFF0EA5E9),
            child: _buildVitalField(
              controller: _oxygenSatController,
              label: '',
              hint: '98',
              suffix: '%',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 50 || num > 100) {
                    return 'Invalid';
                  }
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyMeasurementsCard() {
    return _buildCard(
      title: 'Body Measurements',
      icon: Icons.straighten,
      iconColor: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVitalField(
                  controller: _weightController,
                  label: 'Weight',
                  hint: '70',
                  suffix: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calculateBMI(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalField(
                  controller: _heightController,
                  label: 'Height',
                  hint: '170',
                  suffix: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calculateBMI(),
                ),
              ),
            ],
          ),
          if (_calculatedBMI != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBMIColor(_calculatedBMI!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'BMI: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _calculatedBMI!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getBMIColor(_calculatedBMI!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getBMICategory(_calculatedBMI!),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getBMIColor(_calculatedBMI!),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildVitalField(
            controller: _bloodGlucoseController,
            label: 'Blood Glucose',
            hint: '100',
            suffix: 'mg/dL',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPainScaleCard() {
    return _buildCard(
      title: 'Pain Level',
      icon: Icons.sentiment_dissatisfied,
      iconColor: const Color(0xFFEF4444),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0 - No Pain', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                _painLevel.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getPainColor(_painLevel),
                ),
              ),
              const Text('10 - Worst', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getPainColor(_painLevel),
              inactiveTrackColor: AppColors.divider,
              thumbColor: _getPainColor(_painLevel),
              overlayColor: _getPainColor(_painLevel).withValues(alpha: 0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: _painLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (value) {
                setState(() => _painLevel = value.toInt());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(11, (index) {
              return GestureDetector(
                onTap: () => setState(() => _painLevel = index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _painLevel == index
                        ? _getPainColor(index)
                        : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getPainColor(index).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _painLevel == index ? Colors.white : _getPainColor(index),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildCard(
      title: 'Notes',
      icon: Icons.notes,
      iconColor: AppColors.textSecondary,
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Additional notes about vitals...',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildVitalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: [
            if (keyboardType == TextInputType.number)
              FilteringTextInputFormatter.digitsOnly,
            if (keyboardType == const TextInputType.numberWithOptions(decimal: true))
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVitals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Vitals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPainColor(int level) {
    if (level <= 3) return AppColors.success;
    if (level <= 6) return AppColors.warning;
    return AppColors.error;
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return '(Underweight)';
    if (bmi < 25) return '(Normal)';
    if (bmi < 30) return '(Overweight)';
    return '(Obese)';
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one vital is entered
    final hasData = _systolicController.text.isNotEmpty ||
        _diastolicController.text.isNotEmpty ||
        _heartRateController.text.isNotEmpty ||
        _temperatureController.text.isNotEmpty ||
        _respiratoryRateController.text.isNotEmpty ||
        _oxygenSatController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _heightController.text.isNotEmpty ||
        _painLevel > 0;

    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one vital sign'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(encounterServiceProvider);
      
      final vitalId = await service.recordVitals(
        encounterId: widget.encounterId,
        patientId: widget.patientId,
        systolicBp: double.tryParse(_systolicController.text),
        diastolicBp: double.tryParse(_diastolicController.text),
        heartRate: int.tryParse(_heartRateController.text),
        temperature: double.tryParse(_temperatureController.text),
        respiratoryRate: int.tryParse(_respiratoryRateController.text),
        oxygenSaturation: double.tryParse(_oxygenSatController.text),
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
        painLevel: _painLevel > 0 ? _painLevel : null,
        bloodGlucose: _bloodGlucoseController.text.isNotEmpty
            ? _bloodGlucoseController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      widget.onSaved?.call(vitalId);
      ref.invalidate(encounterVitalsProvider(widget.encounterId));
      ref.invalidate(encounterSummaryProvider(widget.encounterId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vitals recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(vitalId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vitals: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Show vitals entry modal as a bottom sheet
Future<int?> showVitalsEntryModal({
  required BuildContext context,
  required int encounterId,
  required int patientId,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => VitalsEntryModal(
        encounterId: encounterId,
        patientId: patientId,
      ),
    ),
  );
}
