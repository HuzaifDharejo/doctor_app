import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VitalSign {
  VitalSign({
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.respiratoryRate,
    this.temperature,
    this.spO2,
    this.weight,
    this.height,
    this.notes = '',
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  final int? systolicBP;
  final int? diastolicBP;
  final int? heartRate;
  final int? respiratoryRate;
  final double? temperature;
  final int? spO2;
  final double? weight;
  final double? height;
  final String notes;
  final DateTime recordedAt;

  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  Map<String, dynamic> toJson() => {
    'systolicBP': systolicBP,
    'diastolicBP': diastolicBP,
    'heartRate': heartRate,
    'respiratoryRate': respiratoryRate,
    'temperature': temperature,
    'spO2': spO2,
    'weight': weight,
    'height': height,
    'notes': notes,
    'recordedAt': recordedAt.toIso8601String(),
  };
}

class QuickVitalsEntry extends StatefulWidget {
  const QuickVitalsEntry({
    required this.onSave,
    this.initialVital,
    super.key,
  });

  final Function(VitalSign) onSave;
  final VitalSign? initialVital;

  @override
  State<QuickVitalsEntry> createState() => _QuickVitalsEntryState();
}

class _QuickVitalsEntryState extends State<QuickVitalsEntry> {
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late TextEditingController _hrController;
  late TextEditingController _rrController;
  late TextEditingController _tempController;
  late TextEditingController _o2Controller;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final vital = widget.initialVital;
    _systolicController = TextEditingController(text: vital?.systolicBP?.toString() ?? '');
    _diastolicController = TextEditingController(text: vital?.diastolicBP?.toString() ?? '');
    _hrController = TextEditingController(text: vital?.heartRate?.toString() ?? '');
    _rrController = TextEditingController(text: vital?.respiratoryRate?.toString() ?? '');
    _tempController = TextEditingController(text: vital?.temperature?.toString() ?? '');
    _o2Controller = TextEditingController(text: vital?.spO2?.toString() ?? '');
    _weightController = TextEditingController(text: vital?.weight?.toString() ?? '');
    _heightController = TextEditingController(text: vital?.height?.toString() ?? '');
    _notesController = TextEditingController(text: vital?.notes ?? '');
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _hrController.dispose();
    _rrController.dispose();
    _tempController.dispose();
    _o2Controller.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  VitalSign _buildVital() => VitalSign(
    systolicBP: int.tryParse(_systolicController.text),
    diastolicBP: int.tryParse(_diastolicController.text),
    heartRate: int.tryParse(_hrController.text),
    respiratoryRate: int.tryParse(_rrController.text),
    temperature: double.tryParse(_tempController.text),
    spO2: int.tryParse(_o2Controller.text),
    weight: double.tryParse(_weightController.text),
    height: double.tryParse(_heightController.text),
    notes: _notesController.text,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Record Vital Signs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text('Blood Pressure (mmHg)', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Systolic'),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('/')),
                  Expanded(
                    child: TextField(
                      controller: _diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Diastolic'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Heart Rate (bpm)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _hrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Heart Rate'),
              ),
              const SizedBox(height: 12),
              const Text('Respiratory Rate (/min)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _rrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'RR'),
              ),
              const SizedBox(height: 12),
              const Text('Temperature (°C)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _tempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Temperature'),
              ),
              const SizedBox(height: 12),
              const Text('SpO₂ (%)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _o2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'SpO₂'),
              ),
              const SizedBox(height: 12),
              const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Weight'),
              ),
              const SizedBox(height: 12),
              const Text('Height (cm)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Height'),
              ),
              const SizedBox(height: 12),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Additional notes...'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(_buildVital());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Vitals'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
