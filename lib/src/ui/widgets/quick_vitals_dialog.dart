import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/context_extensions.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';

/// Quick vitals entry dialog for fast vital sign recording
/// 
/// Usage:
/// ```dart
/// final result = await showQuickVitalsDialog(context, db, patient);
/// if (result != null) {
///   // Vitals saved successfully
/// }
/// ```
Future<VitalSign?> showQuickVitalsDialog(
  BuildContext context,
  DoctorDatabase db,
  Patient patient, {
  int? encounterId,
}) async {
  return showDialog<VitalSign>(
    context: context,
    builder: (context) => _QuickVitalsDialog(
      db: db,
      patient: patient,
      encounterId: encounterId,
    ),
  );
}

class _QuickVitalsDialog extends StatefulWidget {
  const _QuickVitalsDialog({
    required this.db,
    required this.patient,
    this.encounterId,
  });

  final DoctorDatabase db;
  final Patient patient;
  final int? encounterId;

  @override
  State<_QuickVitalsDialog> createState() => _QuickVitalsDialogState();
}

class _QuickVitalsDialogState extends State<_QuickVitalsDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSaving = false;
  
  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _oxygenController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error,
                    AppColors.error.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Vitals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.patient.firstName} ${widget.patient.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.responsivePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blood Pressure
                      Text(
                        'Blood Pressure',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _systolicController,
                              label: 'Systolic',
                              suffix: 'mmHg',
                              keyboardType: TextInputType.number,
                              icon: Icons.arrow_upward,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _diastolicController,
                              label: 'Diastolic',
                              suffix: 'mmHg',
                              keyboardType: TextInputType.number,
                              icon: Icons.arrow_downward,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Heart Rate & Temperature
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _heartRateController,
                              label: 'Heart Rate',
                              suffix: 'bpm',
                              keyboardType: TextInputType.number,
                              icon: Icons.favorite,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _temperatureController,
                              label: 'Temperature',
                              suffix: '°C',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              icon: Icons.thermostat,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // O2 & Weight
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _oxygenController,
                              label: 'SpO2',
                              suffix: '%',
                              keyboardType: TextInputType.number,
                              icon: Icons.air,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              label: 'Weight',
                              suffix: 'kg',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              icon: Icons.monitor_weight,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Notes
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes (optional)',
                        icon: Icons.notes,
                        color: AppColors.primary,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveVitals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Save Vitals'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    TextInputType? keyboardType,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : keyboardType == const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))]
              : null,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
  
  Future<void> _saveVitals() async {
    // Check if at least one field has a value
    if (_systolicController.text.isEmpty &&
        _diastolicController.text.isEmpty &&
        _heartRateController.text.isEmpty &&
        _temperatureController.text.isEmpty &&
        _oxygenController.text.isEmpty &&
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one vital sign'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final companion = VitalSignsCompanion(
        patientId: Value(widget.patient.id),
        encounterId: Value(widget.encounterId),
        recordedAt: Value(DateTime.now()),
        systolicBp: Value(_systolicController.text.isNotEmpty 
            ? double.parse(_systolicController.text) 
            : null),
        diastolicBp: Value(_diastolicController.text.isNotEmpty 
            ? double.parse(_diastolicController.text) 
            : null),
        heartRate: Value(_heartRateController.text.isNotEmpty 
            ? int.parse(_heartRateController.text) 
            : null),
        temperature: Value(_temperatureController.text.isNotEmpty 
            ? double.parse(_temperatureController.text) 
            : null),
        oxygenSaturation: Value(_oxygenController.text.isNotEmpty 
            ? double.parse(_oxygenController.text) 
            : null),
        weight: Value(_weightController.text.isNotEmpty 
            ? double.parse(_weightController.text) 
            : null),
        notes: Value(_notesController.text),
      );
      
      final id = await widget.db.insertVitalSigns(companion);
      final saved = await widget.db.getVitalSignById(id);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, saved);
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
        setState(() => _isSaving = false);
      }
    }
  }
}
