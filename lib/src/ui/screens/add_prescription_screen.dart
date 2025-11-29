import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/prescription_templates.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {
  final int? patientId;
  final String? patientName;
  final Patient? preselectedPatient;

  const AddPrescriptionScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.preselectedPatient,
  });

  @override
  ConsumerState<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends ConsumerState<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Patient Selection
  int? _selectedPatientId;
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  final _searchController = TextEditingController();

  // Diagnosis
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();

  // Medications List
  final List<MedicationEntry> _medications = [];

  // Last Visit Vitals (read-only from previous prescription)
  Map<String, dynamic>? _lastVisitVitals;
  DateTime? _lastVisitDate;
  bool _loadingVitals = false;

  // Additional Notes
  final _notesController = TextEditingController();
  final _adviceController = TextEditingController();

  // Follow-up
  DateTime? _followUpDate;
  final _followUpNotesController = TextEditingController();

  // Lab Tests
  final List<String> _selectedLabTests = [];
  final List<String> _availableLabTests = [
    'Complete Blood Count (CBC)',
    'Blood Sugar Fasting',
    'Blood Sugar Random',
    'HbA1c',
    'Lipid Profile',
    'Liver Function Test (LFT)',
    'Kidney Function Test (KFT)',
    'Thyroid Profile',
    'Urine Complete',
    'X-Ray Chest',
    'ECG',
    'Ultrasound',
    'CT Scan',
    'MRI',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) {
      _selectedPatientId = widget.patientId;
    } else if (widget.preselectedPatient != null) {
      _selectedPatientId = widget.preselectedPatient?.id;
      _selectedPatient = widget.preselectedPatient;
    }
    // Add one empty medication entry by default
    _medications.add(MedicationEntry());
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final db = await ref.read(doctorDbProvider.future);
    final patients = await db.getAllPatients();
    setState(() {
      _patients = patients;
      if (_selectedPatientId != null && _selectedPatient == null) {
        _selectedPatient = _patients.where((p) => p.id == _selectedPatientId).firstOrNull;
        if (_selectedPatient != null) {
          _loadLastVisitVitals(_selectedPatientId!);
        }
      }
    });
  }

  Future<void> _loadLastVisitVitals(int patientId) async {
    setState(() => _loadingVitals = true);
    try {
      final db = await ref.read(doctorDbProvider.future);
      final lastPrescription = await db.getLastPrescriptionForPatient(patientId);
      
      if (lastPrescription != null) {
        final data = jsonDecode(lastPrescription.itemsJson) as Map<String, dynamic>;
        setState(() {
          _lastVisitVitals = data['vitals'] as Map<String, dynamic>?;
          _lastVisitDate = lastPrescription.createdAt;
          _loadingVitals = false;
        });
      } else {
        setState(() {
          _lastVisitVitals = null;
          _lastVisitDate = null;
          _loadingVitals = false;
        });
      }
    } catch (e) {
      setState(() {
        _lastVisitVitals = null;
        _lastVisitDate = null;
        _loadingVitals = false;
      });
    }
  }

  String _getPatientName(Patient patient) {
    return '${patient.firstName} ${patient.lastName}'.trim();
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    _adviceController.dispose();
    _followUpNotesController.dispose();
    for (var med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationEntry());
    });
  }

  void _showMedicationTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => MedicationTemplateBottomSheet(
          onSelect: (template) {
            setState(() {
              final entry = MedicationEntry();
              entry.nameController.text = template.name;
              entry.dosageController.text = template.dosage;
              entry.durationController.text = template.duration;
              // Parse frequency from template to match existing format
              entry.frequency = _parseFrequency(template.frequency);
              entry.instructionsController.text = template.notes;
              _medications.add(entry);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${template.name} added'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  String _parseFrequency(String frequency) {
    final lower = frequency.toLowerCase();
    if (lower.contains('once daily') || lower.contains('once a day')) return 'OD';
    if (lower.contains('twice daily') || lower.contains('every 12')) return 'BD';
    if (lower.contains('three times') || lower.contains('every 8 hours')) return 'TDS';
    if (lower.contains('four times') || lower.contains('every 6 hours')) return 'QID';
    if (lower.contains('as needed') || lower.contains('prn')) return 'SOS';
    if (lower.contains('every 4 hours')) return 'Q4H';
    return 'OD';
  }

  void _removeMedication(int index) {
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  Future<void> _selectFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Map<String, dynamic> _buildPrescriptionJson() {
    final selectedPatient = _selectedPatient;
    
    Map<String, dynamic> patientData = {};
    if (selectedPatient != null) {
      patientData = {
        'id': selectedPatient.id,
        'name': _getPatientName(selectedPatient),
        'age': _calculateAge(selectedPatient.dateOfBirth),
      };
    }

    return {
      'prescription_date': DateTime.now().toIso8601String(),
      'patient': patientData,
      'vitals': _lastVisitVitals ?? {},  // Use last visit vitals (read-only reference)
      'symptoms': _symptomsController.text,
      'diagnosis': _diagnosisController.text,
      'medications': _medications.map((med) => med.toJson()).toList(),
      'lab_tests': _selectedLabTests,
      'advice': _adviceController.text,
      'notes': _notesController.text,
      'follow_up': {
        'date': _followUpDate?.toIso8601String(),
        'notes': _followUpNotesController.text,
      },
    };
  }

  void _savePrescription() {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a patient'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final jsonData = _buildPrescriptionJson();
      debugPrint('=== NEW PRESCRIPTION DATA ===');
      debugPrint(jsonData.toString());
      debugPrint('=============================');

      final patientName = _selectedPatient != null ? _getPatientName(_selectedPatient!) : 'Patient';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Prescription saved for $patientName'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _printPrescription() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.print, color: Colors.white),
            SizedBox(width: 12),
            Text('Preparing prescription for print...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning, AppColors.warning.withRed(255)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Custom App Bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'New Prescription',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _printPrescription,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.print, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Prescription Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Doctor Header
              _buildDoctorHeader(colorScheme),
              const SizedBox(height: 16),

              // Patient Selection
              _buildSectionCard(
                title: 'Patient',
                icon: Icons.person,
                colorScheme: colorScheme,
                child: _buildPatientSelector(colorScheme),
              ),
              const SizedBox(height: 16),

              // Last Visit Vitals (read-only)
              _buildSectionCard(
                title: 'Last Visit Vitals',
                icon: Icons.favorite,
                colorScheme: colorScheme,
                child: _buildLastVisitVitalsSection(colorScheme),
              ),
              const SizedBox(height: 16),

              // Symptoms & Diagnosis
              _buildSectionCard(
                title: 'Symptoms & Diagnosis',
                icon: Icons.medical_information,
                colorScheme: colorScheme,
                child: Column(
                  children: [
                    SuggestionTextField(
                      controller: _symptomsController,
                      label: 'Symptoms / Chief Complaints',
                      hint: 'Tap to see suggestions...',
                      prefixIcon: Icons.sick_outlined,
                      maxLines: 2,
                      suggestions: MedicalSuggestions.symptoms,
                      appendMode: true,
                      separator: ', ',
                    ),
                    const SizedBox(height: 16),
                    SuggestionTextField(
                      controller: _diagnosisController,
                      label: 'Diagnosis *',
                      hint: 'Tap to see suggestions...',
                      prefixIcon: Icons.assignment_outlined,
                      maxLines: 2,
                      suggestions: MedicalSuggestions.diagnoses,
                      appendMode: true,
                      separator: ', ',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter diagnosis';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medications
              _buildSectionCard(
                title: 'Medications',
                icon: Icons.medication,
                colorScheme: colorScheme,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showMedicationTemplates,
                      icon: const Icon(Icons.library_books, size: 16),
                      label: const Text('Templates'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _addMedication,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                child: _buildMedicationsSection(colorScheme),
              ),
              const SizedBox(height: 16),

              // Lab Tests
              _buildSectionCard(
                title: 'Lab Tests',
                icon: Icons.science,
                colorScheme: colorScheme,
                child: _buildLabTestsSection(colorScheme),
              ),
              const SizedBox(height: 16),

              // Advice & Notes
              _buildSectionCard(
                title: 'Advice & Notes',
                icon: Icons.note_alt,
                colorScheme: colorScheme,
                child: Column(
                  children: [
                    SuggestionTextField(
                      controller: _adviceController,
                      label: 'Advice / Instructions',
                      hint: 'Tap to see suggestions...',
                      prefixIcon: Icons.tips_and_updates_outlined,
                      maxLines: 3,
                      separator: '\n',
                      suggestions: PrescriptionSuggestions.instructions,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',
                        hintText: 'Any additional notes...',
                        prefixIcon: const Icon(Icons.note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Follow-up
              _buildSectionCard(
                title: 'Follow-up',
                icon: Icons.event_repeat,
                colorScheme: colorScheme,
                child: _buildFollowUpSection(colorScheme),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printPrescription,
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _savePrescription,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Prescription'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Text(
              ref.watch(doctorSettingsProvider).profile.initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(doctorSettingsProvider).profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ref.watch(doctorSettingsProvider).profile.qualifications.isNotEmpty 
                      ? ref.watch(doctorSettingsProvider).profile.qualifications 
                      : ref.watch(doctorSettingsProvider).profile.specialization,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd MMM yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelector(ColorScheme colorScheme) {
    if (_selectedPatient != null) {
      final patient = _selectedPatient!;
      final patientName = _getPatientName(patient);
      final age = _calculateAge(patient.dateOfBirth);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0] : '?',
                style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${age > 0 ? "$age years" : "Age unknown"} • ${patient.phone.isNotEmpty ? patient.phone : "No phone"}',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectedPatientId = null;
                _selectedPatient = null;
                _lastVisitVitals = null;
                _lastVisitDate = null;
              }),
            ),
          ],
        ),
      );
    }

    // Filter patients based on search
    final searchQuery = _searchController.text.toLowerCase();
    final filteredPatients = searchQuery.isEmpty
        ? _patients
        : _patients.where((p) => _getPatientName(p).toLowerCase().contains(searchQuery)).toList();

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search patient...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('Loading patients...'),
          )
        else if (filteredPatients.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text('No patients found'),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                final patientName = _getPatientName(patient);
                final age = _calculateAge(patient.dateOfBirth);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Text(patient.firstName.isNotEmpty ? patient.firstName[0] : '?'),
                  ),
                  title: Text(patientName),
                  subtitle: Text(age > 0 ? '$age years' : 'Age unknown'),
                  dense: true,
                  onTap: () {
                    setState(() {
                      _selectedPatientId = patient.id;
                      _selectedPatient = patient;
                    });
                    _loadLastVisitVitals(patient.id);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLastVisitVitalsSection(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_loadingVitals) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_selectedPatient == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_search, size: 40, color: colorScheme.outline),
              const SizedBox(height: 8),
              Text(
                'Select a patient to see last visit vitals',
                style: TextStyle(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_lastVisitVitals == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 40, color: colorScheme.outline),
              const SizedBox(height: 8),
              Text(
                'No previous visit data available',
                style: TextStyle(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }
    
    final bp = _lastVisitVitals!['bp'] ?? '-';
    final pulse = _lastVisitVitals!['pulse'] ?? '-';
    final temp = _lastVisitVitals!['temperature'] ?? '-';
    final weight = _lastVisitVitals!['weight'] ?? '-';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last visit date header
          if (_lastVisitDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Last Visit: ${DateFormat('dd MMM yyyy').format(_lastVisitDate!)}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Vitals grid
          Row(
            children: [
              Expanded(
                child: _buildVitalDisplayCard(
                  label: 'Blood Pressure',
                  value: bp.toString(),
                  suffix: 'mmHg',
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.red,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVitalDisplayCard(
                  label: 'Pulse Rate',
                  value: pulse.toString(),
                  suffix: 'bpm',
                  icon: Icons.monitor_heart_rounded,
                  iconColor: Colors.pink,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildVitalDisplayCard(
                  label: 'Temperature',
                  value: temp.toString(),
                  suffix: '°C',
                  icon: Icons.thermostat_rounded,
                  iconColor: Colors.orange,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildVitalDisplayCard(
                  label: 'Weight',
                  value: weight.toString(),
                  suffix: 'kg',
                  icon: Icons.monitor_weight_rounded,
                  iconColor: Colors.blue,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVitalDisplayCard({
    required String label,
    required String value,
    required String suffix,
    required IconData icon,
    required Color iconColor,
    required ColorScheme colorScheme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.isNotEmpty && value != '-' && value != 'null';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasValue ? value : '-',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hasValue ? colorScheme.onSurface : colorScheme.outline,
                ),
              ),
              if (hasValue) ...[
                const SizedBox(width: 4),
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsSection(ColorScheme colorScheme) {
    return Column(
      children: [
        for (int i = 0; i < _medications.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _medications[i].nameController,
                        decoration: InputDecoration(
                          labelText: 'Medicine Name *',
                          hintText: 'e.g., Paracetamol 500mg',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_medications.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: colorScheme.error),
                        onPressed: () => _removeMedication(i),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (f) => setState(() => _medications[i].dosageFocused = f),
                        child: TextFormField(
                          controller: _medications[i].dosageController,
                          focusNode: _medications[i].dosageFocus,
                          decoration: InputDecoration(
                            labelText: 'Dosage',
                            hintText: '1 tablet',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _medications[i].frequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          isDense: true,
                        ),
                        items: ['OD', 'BD', 'TDS', 'QID', 'SOS', 'HS', 'AC', 'PC']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) => setState(() => _medications[i].frequency = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Focus(
                        onFocusChange: (f) => setState(() => _medications[i].durationFocused = f),
                        child: TextFormField(
                          controller: _medications[i].durationController,
                          focusNode: _medications[i].durationFocus,
                          decoration: InputDecoration(
                            labelText: 'Duration',
                            hintText: '7 days',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Dosage Quick Picks - shown when dosage focused
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _medications[i].dosageFocused
                      ? Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text('Dose: ', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                                ...PrescriptionSuggestions.dosages.take(8).map((d) =>
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        _medications[i].dosageController.text = d;
                                        setState(() {});
                                        Future.delayed(const Duration(milliseconds: 50), () {
                                          _medications[i].dosageFocus.requestFocus();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                        ),
                                        child: Text(d, style: const TextStyle(fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Duration Quick Picks - shown when duration focused
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _medications[i].durationFocused
                      ? Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text('Days: ', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                                ...PrescriptionSuggestions.durations.map((d) =>
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        _medications[i].durationController.text = d;
                                        setState(() {});
                                        Future.delayed(const Duration(milliseconds: 50), () {
                                          _medications[i].durationFocus.requestFocus();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                        ),
                                        child: Text(d, style: const TextStyle(fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: ['Before Food', 'After Food', 'With Food'].map((timing) {
                          final isSelected = _medications[i].timing == timing;
                          return ChoiceChip(
                            label: Text(timing, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _medications[i].timing = timing);
                              }
                            },
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medications[i].instructionsController,
                  decoration: InputDecoration(
                    labelText: 'Special Instructions',
                    hintText: 'e.g., Take with warm water',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLabTestsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLabTests.map((test) {
            final isSelected = _selectedLabTests.contains(test);
            return FilterChip(
              label: Text(test, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLabTests.add(test);
                  } else {
                    _selectedLabTests.remove(test);
                  }
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
            );
          }).toList(),
        ),
        if (_selectedLabTests.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.checklist, color: colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedLabTests.length} test(s) selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFollowUpSection(ColorScheme colorScheme) {
    return Column(
      children: [
        InkWell(
          onTap: _selectFollowUpDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Follow-up Date',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            child: Text(
              _followUpDate != null
                  ? DateFormat('EEEE, dd MMM yyyy').format(_followUpDate!)
                  : 'Select follow-up date',
              style: TextStyle(
                color: _followUpDate != null
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Follow-up Quick Picks
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFollowUpChip('3 days', 3, colorScheme),
              _buildFollowUpChip('1 week', 7, colorScheme),
              _buildFollowUpChip('2 weeks', 14, colorScheme),
              _buildFollowUpChip('1 month', 30, colorScheme),
              _buildFollowUpChip('2 months', 60, colorScheme),
              _buildFollowUpChip('3 months', 90, colorScheme),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _followUpNotesController,
          decoration: InputDecoration(
            labelText: 'Follow-up Notes',
            hintText: 'What to check on follow-up...',
            prefixIcon: const Icon(Icons.note_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpChip(String label, int days, ColorScheme colorScheme) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = _followUpDate != null && 
        _followUpDate!.year == targetDate.year && 
        _followUpDate!.month == targetDate.month && 
        _followUpDate!.day == targetDate.day;
    
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _followUpDate = targetDate);
          }
        },
        visualDensity: VisualDensity.compact,
        selectedColor: colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// Medication Entry Class
class MedicationEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  final FocusNode dosageFocus = FocusNode();
  final FocusNode durationFocus = FocusNode();
  bool dosageFocused = false;
  bool durationFocused = false;
  String frequency = 'OD';
  String timing = 'After Food';

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
    dosageFocus.dispose();
    durationFocus.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'dosage': dosageController.text,
      'frequency': frequency,
      'duration': durationController.text,
      'timing': timing,
      'instructions': instructionsController.text,
    };
  }
}
