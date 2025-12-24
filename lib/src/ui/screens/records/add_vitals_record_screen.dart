import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import 'components/patient_selector_card.dart';
import 'components/record_components.dart';
import '../../../core/extensions/context_extensions.dart';

/// Screen for quickly recording patient vitals
class AddVitalsRecordScreen extends ConsumerStatefulWidget {
  const AddVitalsRecordScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddVitalsRecordScreen> createState() => _AddVitalsRecordScreenState();
}

class _AddVitalsRecordScreenState extends ConsumerState<AddVitalsRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Theme colors
  static const _primaryColor = Color(0xFFEF4444);
  static const _secondaryColor = Color(0xFFDC2626);

  // Patient selection
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Vitals controllers
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _spO2Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _notesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty && mounted) {
      setState(() {
        _bpSystolicController.text = data['bp_systolic']?.toString() ?? '';
        _bpDiastolicController.text = data['bp_diastolic']?.toString() ?? '';
        _heartRateController.text = data['heart_rate']?.toString() ?? '';
        _temperatureController.text = data['temperature']?.toString() ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _heightController.text = data['height']?.toString() ?? '';
        _spO2Controller.text = data['spo2']?.toString() ?? '';
        _respiratoryRateController.text = data['respiratory_rate']?.toString() ?? '';
        _bloodSugarController.text = data['blood_sugar']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _heartRateController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _spO2Controller.dispose();
    _respiratoryRateController.dispose();
    _bloodSugarController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      // V6: Build data for normalized storage
      final recordData = {
        'bp_systolic': _bpSystolicController.text.isNotEmpty 
            ? int.tryParse(_bpSystolicController.text) : null,
        'bp_diastolic': _bpDiastolicController.text.isNotEmpty 
            ? int.tryParse(_bpDiastolicController.text) : null,
        'heart_rate': _heartRateController.text.isNotEmpty 
            ? int.tryParse(_heartRateController.text) : null,
        'temperature': _temperatureController.text.isNotEmpty 
            ? double.tryParse(_temperatureController.text) : null,
        'weight': _weightController.text.isNotEmpty 
            ? double.tryParse(_weightController.text) : null,
        'height': _heightController.text.isNotEmpty 
            ? double.tryParse(_heightController.text) : null,
        'spo2': _spO2Controller.text.isNotEmpty 
            ? int.tryParse(_spO2Controller.text) : null,
        'respiratory_rate': _respiratoryRateController.text.isNotEmpty 
            ? int.tryParse(_respiratoryRateController.text) : null,
        'blood_sugar': _bloodSugarController.text.isNotEmpty 
            ? int.tryParse(_bloodSugarController.text) : null,
      };

      // Build title summary
      final titleParts = <String>[];
      if (_bpSystolicController.text.isNotEmpty && _bpDiastolicController.text.isNotEmpty) {
        titleParts.add('BP: ${_bpSystolicController.text}/${_bpDiastolicController.text}');
      }
      if (_heartRateController.text.isNotEmpty) {
        titleParts.add('HR: ${_heartRateController.text}');
      }
      if (_temperatureController.text.isNotEmpty) {
        titleParts.add('Temp: ${_temperatureController.text}°F');
      }
      
      final title = titleParts.isNotEmpty 
          ? titleParts.join(' | ')
          : 'Vitals Record - ${DateFormat('MMM d, yyyy').format(_recordDate)}';

      if (widget.existingRecord != null) {
        // Update existing record - create full record object
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'vitals',
          title: title,
          description: '',
          dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: '',
          treatment: '',
          doctorNotes: _notesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        // V6: Delete old fields and re-insert
        await db.deleteFieldsForMedicalRecord(widget.existingRecord!.id);
        await db.insertMedicalRecordFieldsBatch(widget.existingRecord!.id, _selectedPatientId!, recordData);
      } else {
        // Create new record
        final recordId = await db.insertMedicalRecord(
          MedicalRecordsCompanion.insert(
            patientId: _selectedPatientId!,
            recordType: 'vitals',
            title: title,
            dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
            doctorNotes: Value(_notesController.text),
            recordDate: _recordDate,
          ),
        );
        // V6: Save fields to normalized table
        await db.insertMedicalRecordFieldsBatch(recordId, _selectedPatientId!, recordData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRecord != null 
                ? 'Vitals record updated' 
                : 'Vitals record saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.existingRecord != null ? 'Edit Vitals' : 'Record Vitals'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRecord,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(context.responsivePadding),
          children: [
            // Patient Selection
            if (widget.preselectedPatient != null)
              _buildPatientInfoCard(isDark)
            else
              FutureBuilder<DoctorDatabase>(
                future: ref.read(doctorDbProvider.future),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return PatientSelectorCard(
                    db: snapshot.data,
                    selectedPatientId: _selectedPatientId,
                    onPatientSelected: (patient) {
                      setState(() => _selectedPatientId = patient?.id);
                    },
                    label: 'Select Patient',
                  );
                },
              ),
            const SizedBox(height: 16),

            // Date Selection
            _buildDateCard(isDark),
            const SizedBox(height: 16),

            // Blood Pressure
            _buildSectionCard(
              isDark: isDark,
              title: 'Blood Pressure',
              icon: Icons.favorite,
              iconColor: Colors.red,
              child: Row(
                children: [
                  Expanded(
                    child: _buildVitalField(
                      controller: _bpSystolicController,
                      label: 'Systolic',
                      hint: '120',
                      suffix: 'mmHg',
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 24,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildVitalField(
                      controller: _bpDiastolicController,
                      label: 'Diastolic',
                      hint: '80',
                      suffix: 'mmHg',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Heart Rate & SpO2
            Row(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'Heart Rate',
                    icon: Icons.monitor_heart,
                    iconColor: Colors.pink,
                    child: _buildVitalField(
                      controller: _heartRateController,
                      label: 'BPM',
                      hint: '72',
                      suffix: 'bpm',
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'SpO2',
                    icon: Icons.bloodtype,
                    iconColor: Colors.blue,
                    child: _buildVitalField(
                      controller: _spO2Controller,
                      label: 'Oxygen',
                      hint: '98',
                      suffix: '%',
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Temperature & Respiratory Rate
            Row(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'Temperature',
                    icon: Icons.thermostat,
                    iconColor: Colors.orange,
                    child: _buildVitalField(
                      controller: _temperatureController,
                      label: 'Temp',
                      hint: '98.6',
                      suffix: '°F',
                      isDark: isDark,
                      isDecimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'Resp. Rate',
                    icon: Icons.air,
                    iconColor: Colors.teal,
                    child: _buildVitalField(
                      controller: _respiratoryRateController,
                      label: 'Breaths',
                      hint: '16',
                      suffix: '/min',
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight & Height
            Row(
              children: [
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'Weight',
                    icon: Icons.monitor_weight,
                    iconColor: Colors.green,
                    child: _buildVitalField(
                      controller: _weightController,
                      label: 'Weight',
                      hint: '70',
                      suffix: 'kg',
                      isDark: isDark,
                      isDecimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSectionCard(
                    isDark: isDark,
                    title: 'Height',
                    icon: Icons.height,
                    iconColor: Colors.purple,
                    child: _buildVitalField(
                      controller: _heightController,
                      label: 'Height',
                      hint: '170',
                      suffix: 'cm',
                      isDark: isDark,
                      isDecimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Blood Sugar
            _buildSectionCard(
              isDark: isDark,
              title: 'Blood Sugar',
              icon: Icons.water_drop,
              iconColor: Colors.amber,
              child: _buildVitalField(
                controller: _bloodSugarController,
                label: 'Blood Sugar',
                hint: '100',
                suffix: 'mg/dL',
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _buildSectionCard(
              isDark: isDark,
              title: 'Clinical Notes',
              icon: Icons.note,
              iconColor: Colors.grey,
              child: RecordTextField(
                controller: _notesController,
                label: 'Clinical Notes',
                hint: 'Additional notes...',
                maxLines: 3,
                enableVoice: true,
                suggestions: clinicalNotesSuggestions,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : Text(
                      widget.existingRecord != null ? 'Update Vitals' : 'Save Vitals',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_recordDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _recordDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _recordDate = date);
              }
            },
            icon: Icon(
              Icons.edit_calendar,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(bool isDark) {
    final patient = widget.preselectedPatient!;
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                patient.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient.firstName} ${patient.lastName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Recording vitals',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
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
    required bool isDark,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        suffixStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
