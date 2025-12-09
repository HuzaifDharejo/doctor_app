import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/allergy_checking_service.dart';
import '../../services/drug_interaction_service.dart';
import '../../services/logger_service.dart';
import '../../services/pdf_service.dart';
import '../../services/prescription_templates.dart';
import '../../services/suggestions_service.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../core/widgets/app_card.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';
import '../widgets/allergy_check_dialog.dart';
import '../widgets/drug_interaction_dialog.dart';
import 'add_prescription/add_prescription.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {

  const AddPrescriptionScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.preselectedPatient,
    this.appointmentId,
    this.encounterId,
    this.diagnosis,
    this.symptoms,
  });
  final int? patientId;
  final String? patientName;
  final Patient? preselectedPatient;
  final int? appointmentId;
  final int? encounterId;
  /// Pre-filled diagnosis from workflow
  final String? diagnosis;
  /// Pre-filled symptoms from workflow
  final String? symptoms;

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

  // Safety Alerts
  List<DrugInteraction> _drugInteractions = [];
  List<AllergyCheckResult> _allergyAlerts = [];
  String _patientAllergies = '';

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
    // Pre-fill diagnosis and symptoms from workflow if provided
    if (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) {
      _diagnosisController.text = widget.diagnosis!;
    }
    if (widget.symptoms != null && widget.symptoms!.isNotEmpty) {
      _symptomsController.text = widget.symptoms!;
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
      
      // Load actual latest vitals from vitals table (not from prescription)
      final latestVitals = await db.getLatestVitalSignsForPatient(patientId);
      
      if (latestVitals != null) {
        setState(() {
          _lastVisitVitals = {
            'bp': '${latestVitals.systolicBp?.toInt() ?? '-'}/${latestVitals.diastolicBp?.toInt() ?? '-'}',
            'pulse': latestVitals.heartRate?.toString() ?? '-',
            'temperature': latestVitals.temperature?.toStringAsFixed(1) ?? '-',
            'weight': latestVitals.weight?.toStringAsFixed(1) ?? '-',
            'height': latestVitals.height?.toStringAsFixed(1) ?? '-',
            'respiratoryRate': latestVitals.respiratoryRate?.toString() ?? '-',
            'oxygenSaturation': latestVitals.oxygenSaturation?.toStringAsFixed(0) ?? '-',
          };
          _lastVisitDate = latestVitals.recordedAt;
          _loadingVitals = false;
        });
      } else {
        // Fallback: try getting from last prescription if no vitals in table
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
      }
      
      // Load patient allergies from medical history
      if (_selectedPatient != null) {
        // Parse allergies from medical history if available
        final history = _selectedPatient!.medicalHistory;
        // Check for allergy-related keywords in medical history
        if (history.toLowerCase().contains('allerg')) {
          _patientAllergies = _extractAllergies(history);
        }
      }
    } catch (e) {
      setState(() {
        _lastVisitVitals = null;
        _lastVisitDate = null;
        _loadingVitals = false;
      });
    }
  }

  /// Check for drug interactions and allergy conflicts
  void _checkSafetyAlerts() {
    final drugs = _medications
        .map((m) => m.nameController.text)
        .where((name) => name.isNotEmpty)
        .toList();

    if (drugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medications to check')),
      );
      return;
    }

    // Check allergies
    final allergyResults = <AllergyCheckResult>[];
    String? firstAllergyMed;
    AllergyCheckResult? firstAllergyResult;
    
    for (final drug in drugs) {
      final result = AllergyCheckingService.checkDrugSafety(
        allergyHistory: _patientAllergies,
        proposedDrug: drug,
      );
      if (result.hasConcern) {
        allergyResults.add(result);
        if (firstAllergyMed == null) {
          firstAllergyMed = drug;
          firstAllergyResult = result;
        }
      }
    }

    // Check interactions
    final interactions = DrugInteractionService.checkInteractions(drugs);
    String? firstNewMed = drugs.isNotEmpty ? drugs.last : null;
    List<String> currentMeds = drugs.length > 1 ? drugs.sublist(0, drugs.length - 1) : [];

    setState(() {
      _drugInteractions = interactions;
      _allergyAlerts = allergyResults;
    });

    // Show dialogs for any safety concerns
    if (firstAllergyMed != null && firstAllergyResult != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AllergyCheckDialog(
          medicationName: firstAllergyMed!,
          patientAllergies: _patientAllergies,
          allergyResult: firstAllergyResult!,
          onConfirm: () {
            Navigator.pop(context);
            if (interactions.isNotEmpty && firstNewMed != null) {
              _showInteractionDialog(firstNewMed, currentMeds, interactions);
            }
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      );
    } else if (interactions.isNotEmpty && firstNewMed != null) {
      _showInteractionDialog(firstNewMed, currentMeds, interactions);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ All medications are safe'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showInteractionDialog(String newMedication, List<String> currentMedications, List<DrugInteraction> interactions) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DrugInteractionDialog(
        newMedication: newMedication,
        currentMedications: currentMedications,
        interactions: interactions,
        onConfirm: () {
          Navigator.pop(context);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }


  String _getPatientName(Patient patient) {
    return '${patient.firstName} ${patient.lastName}'.trim();
  }

  /// Extract allergies from medical history text
  String _extractAllergies(String medicalHistory) {
    // Common allergy keywords to look for
    final allergyPatterns = [
      RegExp(r'allerg(?:y|ies|ic)[\s:]+([^,.;]+)', caseSensitive: false),
      RegExp(r'allergic to[\s:]+([^,.;]+)', caseSensitive: false),
    ];
    
    final allergies = <String>[];
    for (final pattern in allergyPatterns) {
      final matches = pattern.allMatches(medicalHistory);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          allergies.add(match.group(1)!.trim());
        }
      }
    }
    
    // Also check for common drug names if mentioned with "allergy"
    final commonAllergens = ['penicillin', 'sulfa', 'aspirin', 'nsaid', 'codeine', 'latex', 'iodine'];
    for (final allergen in commonAllergens) {
      if (medicalHistory.toLowerCase().contains(allergen)) {
        if (!allergies.any((a) => a.toLowerCase().contains(allergen))) {
          allergies.add(allergen.substring(0, 1).toUpperCase() + allergen.substring(1));
        }
      }
    }
    
    return allergies.isNotEmpty ? allergies.join(', ') : medicalHistory;
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
    for (final med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    _openMedicationManager();
  }

  void _addEmptyMedication() {
    setState(() {
      _medications.add(MedicationEntry());
    });
  }

  /// Opens the full medication manager popup
  void _openMedicationManager() {
    // Convert current medications to MedicationData format
    final medicationDataList = _medications.map((m) => MedicationData(
      name: m.nameController.text,
      dosage: m.dosageController.text,
      frequency: m.frequency,
      duration: m.durationController.text,
      timing: m.timing,
      instructions: m.instructionsController.text,
    )).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MedicationManagerPopup(
          medications: medicationDataList,
          patientAllergies: _patientAllergies,
          onSave: (updatedMeds) {
            // Clear existing medications
            for (final med in _medications) {
              med.dispose();
            }
            _medications.clear();

            // Add updated medications
            for (final medData in updatedMeds) {
              if (medData.isValid) {
                final entry = MedicationEntry();
                entry.nameController.text = medData.name;
                entry.dosageController.text = medData.dosage;
                entry.frequency = medData.frequency;
                entry.durationController.text = medData.duration;
                entry.timing = medData.timing;
                entry.instructionsController.text = medData.instructions;
                _medications.add(entry);
              }
            }
            setState(() {});
            _runSafetyCheck();
          },
        ),
      ),
    );
  }

  void _showQuickMedicineSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _QuickMedicineSelectorSheet(
          onSelectMedicine: (name, dosage) {
            setState(() {
              final entry = MedicationEntry();
              entry.nameController.text = name;
              if (dosage.isNotEmpty) {
                entry.dosageController.text = dosage;
              }
              _medications.add(entry);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name added'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onAddCustom: () {
            Navigator.pop(context);
            _addEmptyMedication();
          },
        ),
      ),
    );
  }

  void _showMedicationTemplates() {
    showModalBottomSheet<void>(
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
    if (index < 0 || index >= _medications.length) return;
    setState(() {
      final med = _medications[index];
      _medications.removeAt(index);
      // Dispose after removal to avoid using disposed controllers
      med.dispose();
    });
    // Re-check safety after removing medication
    _runSafetyCheck();
  }

  void _runSafetyCheck() {
    // Only run if there are medications to check
    if (_medications.isEmpty) {
      setState(() {
        _drugInteractions = [];
        _allergyAlerts = [];
      });
      return;
    }
    
    final drugs = _medications
        .map((m) => m.nameController.text)
        .where((name) => name.isNotEmpty)
        .toList();
    
    if (drugs.isEmpty) {
      setState(() {
        _drugInteractions = [];
        _allergyAlerts = [];
      });
      return;
    }

    // Check for drug interactions
    final interactions = DrugInteractionService.checkInteractions(drugs);
    
    // Check for allergies
    final allergyAlerts = <AllergyCheckResult>[];
    if (_patientAllergies.isNotEmpty) {
      for (final drug in drugs) {
        final result = AllergyCheckingService.checkDrugSafety(
          allergyHistory: _patientAllergies,
          proposedDrug: drug,
        );
        if (result.hasConcern) {
          allergyAlerts.add(result);
        }
      }
    }

    setState(() {
      _drugInteractions = interactions;
      _allergyAlerts = allergyAlerts;
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
        'age': selectedPatient.age ?? 0,
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

  void _savePrescription() async {
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

    // Check safety before saving
    _checkSafetyAlerts();

    if (_formKey.currentState!.validate()) {
      final jsonData = _buildPrescriptionJson();
      
      if (kDebugMode) {
        log.d('PRESCRIPTION', 'New prescription data', extra: jsonData);
      }

      try {
        // Save to database
        final db = await ref.read(doctorDbProvider.future);
        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: _selectedPatientId!,
            itemsJson: jsonEncode(jsonData['medications']),
            instructions: Value(jsonData['advice'] as String? ?? ''),
            diagnosis: Value(jsonData['diagnosis'] as String? ?? ''),
            chiefComplaint: Value(jsonData['symptoms'] as String? ?? ''),
            vitalsJson: Value(jsonEncode(jsonData['vitals'] ?? {})),
            appointmentId: Value(widget.appointmentId),
            encounterId: Value(widget.encounterId),
          ),
        );
        
        log.i('PRESCRIPTION', 'Prescription saved', extra: {
          'prescriptionId': prescriptionId,
          'patientId': _selectedPatientId,
          'medicationCount': _medications.length,
        });

        // Get the created prescription to return
        final createdPrescription = await db.getPrescriptionById(prescriptionId);

        final patientName = _selectedPatient != null ? _getPatientName(_selectedPatient!) : 'Patient';
        if (mounted) {
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
          Navigator.pop(context, createdPrescription);
        }
      } catch (e, st) {
        log.e('PRESCRIPTION', 'Failed to save prescription', error: e, stackTrace: st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving prescription: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  void _printPrescription() async {
    if (_selectedPatientId == null || _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a patient first'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please add at least one medication'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating prescription PDF...'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // Create a temporary prescription object for PDF generation
      final itemsJson = jsonEncode(_medications.map((med) => med.toJson()).toList());
      final vitalsJson = jsonEncode(_lastVisitVitals ?? {});
      
      final tempPrescription = Prescription(
        id: 0, // Temporary ID
        patientId: _selectedPatientId!,
        createdAt: DateTime.now(),
        itemsJson: itemsJson,
        instructions: _adviceController.text,
        isRefillable: false,
        diagnosis: _diagnosisController.text,
        chiefComplaint: _symptomsController.text,
        vitalsJson: vitalsJson,
      );

      final doctorSettings = ref.read(doctorSettingsProvider);
      final profile = doctorSettings.profile;

      await PdfService.sharePrescriptionPdf(
        patient: _selectedPatient!,
        prescription: tempPrescription,
        doctorName: profile.displayName,
        clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
        clinicPhone: profile.clinicPhone,
        clinicAddress: profile.clinicAddress,
        signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error generating PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 22,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: _printPrescription,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Print',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                          : [Colors.white, const Color(0xFFF8F9FA)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.medication_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'New Prescription',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              // Patient Selection
              _buildModernSectionCard(
                title: 'Patient Information',
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF6366F1),
                isDark: isDark,
                child: _buildPatientSelector(colorScheme),
              ),
              const SizedBox(height: 16),

              // Last Visit Vitals (read-only)
              if (_selectedPatient != null)
                _buildModernSectionCard(
                  title: 'Previous Vitals',
                  icon: Icons.monitor_heart_rounded,
                  iconColor: const Color(0xFFEF4444),
                  isDark: isDark,
                  child: _buildLastVisitVitalsSection(colorScheme),
                ),
              if (_selectedPatient != null)
                const SizedBox(height: 16),

              // Symptoms & Diagnosis
              _buildModernSectionCard(
                title: 'Clinical Assessment',
                icon: Icons.medical_information_rounded,
                iconColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                child: Column(
                  children: [
                    SuggestionTextField(
                      controller: _symptomsController,
                      label: 'Chief Complaints',
                      hint: 'Enter symptoms or tap for suggestions...',
                      prefixIcon: Icons.sick_outlined,
                      maxLines: 2,
                      suggestions: MedicalSuggestions.symptoms,
                    ),
                    const SizedBox(height: 16),
                    SuggestionTextField(
                      controller: _diagnosisController,
                      label: 'Diagnosis *',
                      hint: 'Enter diagnosis or tap for suggestions...',
                      prefixIcon: Icons.assignment_outlined,
                      maxLines: 2,
                      suggestions: MedicalSuggestions.diagnoses,
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

              // Medications - Opens full popup
              _buildModernSectionCard(
                title: 'Medications',
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFFF59E0B),
                isDark: isDark,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSmallActionButton(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Check',
                      color: const Color(0xFF10B981),
                      onTap: _checkSafetyAlerts,
                    ),
                    const SizedBox(width: 6),
                    _buildSmallActionButton(
                      icon: Icons.fullscreen,
                      label: 'Manage',
                      color: AppColors.primary,
                      onTap: _openMedicationManager,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Safety Alerts Banner
                    if (_drugInteractions.isNotEmpty || _allergyAlerts.isNotEmpty)
                      _buildSafetyAlertsBanner(colorScheme),
                    // Patient Allergies Display
                    if (_patientAllergies.isNotEmpty)
                      _buildPatientAllergiesChip(colorScheme),
                    // Medications summary - tap to open full popup
                    _buildMedicationsSummary(colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lab Tests
              _buildModernSectionCard(
                title: 'Investigations',
                icon: Icons.science_rounded,
                iconColor: const Color(0xFF14B8A6),
                isDark: isDark,
                child: _buildLabTestsSection(colorScheme),
              ),
              const SizedBox(height: 16),

              // Advice & Notes
              _buildModernSectionCard(
                title: 'Instructions & Notes',
                icon: Icons.note_alt_rounded,
                iconColor: const Color(0xFFEC4899),
                isDark: isDark,
                child: Column(
                  children: [
                    SuggestionTextField(
                      controller: _adviceController,
                      label: 'Patient Instructions',
                      hint: 'Enter advice or tap for suggestions...',
                      prefixIcon: Icons.tips_and_updates_outlined,
                      maxLines: 3,
                      separator: '\n',
                      suggestions: PrescriptionSuggestions.instructions,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      controller: _notesController,
                      label: 'Clinical Notes (Private)',
                      hint: 'Notes for your reference...',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 2,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Follow-up
              _buildModernSectionCard(
                title: 'Follow-up',
                icon: Icons.event_repeat_rounded,
                iconColor: const Color(0xFF3B82F6),
                isDark: isDark,
                child: _buildFollowUpSection(colorScheme),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _printPrescription,
                        icon: const Icon(Icons.print_rounded, size: 20),
                        label: const Text('Preview'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _savePrescription,
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('Save Prescription'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.3,
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

  Widget _buildDoctorHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_selectedPatient != null) {
      final patient = _selectedPatient!;
      final patientName = _getPatientName(patient);
      final age = patient.age ?? 0;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFF8B5CF6).withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.cake_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        age > 0 ? '$age years' : 'Age unknown',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        patient.phone.isNotEmpty ? patient.phone : 'No phone',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _selectedPatientId = null;
                _selectedPatient = null;
                _lastVisitVitals = null;
                _lastVisitDate = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
              ),
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
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search patient by name...',
              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[400] : Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_patients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.white54 : Colors.grey),
                const SizedBox(height: 12),
                Text('Loading patients...', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          )
        else if (filteredPatients.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.person_search_rounded, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No patients found', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filteredPatients.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                final patientName = _getPatientName(patient);
                final age = patient.age ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Text(
                      patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  title: Text(patientName, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text(age > 0 ? '$age years' : 'Age unknown', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (_selectedPatient == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
    
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      borderRadius: BorderRadius.circular(12),
      borderColor: colorScheme.outline.withValues(alpha: 0.1),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAlertsBanner(ColorScheme colorScheme) {
    final hasInteractions = _drugInteractions.isNotEmpty;
    final hasAllergyAlerts = _allergyAlerts.isNotEmpty;
    final hasSevere = _drugInteractions.any((i) => i.severity == InteractionSeverity.severe) ||
                      _allergyAlerts.any((a) => a.severity == AllergySeverity.severe);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasSevere ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSevere ? Colors.red.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSevere ? Icons.error : Icons.warning_amber,
                color: hasSevere ? Colors.red.shade700 : Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasSevere ? 'Critical Safety Alert!' : 'Safety Warning',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasSevere ? Colors.red.shade700 : Colors.orange.shade700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              AppButton.tertiary(
                label: 'View Details',
                onPressed: _checkSafetyAlerts,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasInteractions)
            Text(
              '⚠️ ${_drugInteractions.length} drug interaction(s) detected',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          if (hasAllergyAlerts)
            Text(
              '🚨 ${_allergyAlerts.length} allergy conflict(s) detected',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientAllergiesChip(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Patient Allergies: $_patientAllergies',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Simplified medication summary - tap to open full popup
  Widget _buildMedicationsSummary(ColorScheme colorScheme) {
    final validMeds = _medications.where((m) => m.nameController.text.isNotEmpty).toList();

    if (validMeds.isEmpty) {
      return EmptyMedicationsState(onTap: _openMedicationManager);
    }

    return InkWell(
      onTap: _openMedicationManager,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          for (int i = 0; i < validMeds.length && i < 5; i++)
            MedicationSummaryCard(
              name: validMeds[i].nameController.text,
              dosage: validMeds[i].dosageController.text,
              frequency: validMeds[i].frequency,
              timing: validMeds[i].timing,
              duration: validMeds[i].durationController.text,
              instructions: validMeds[i].instructionsController.text,
              index: i,
            ),
          if (validMeds.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${validMeds.length - 5} more medications',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tap to manage medications (${validMeds.length})',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
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
                      child: AppInput.text(
                        controller: _medications[i].nameController,
                        label: 'Medicine Name *',
                        hint: 'e.g., Paracetamol 500mg',
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
                        child: AppInput(
                          controller: _medications[i].dosageController,
                          focusNode: _medications[i].dosageFocus,
                          label: 'Dosage',
                          hint: '1 tablet',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _medications[i].frequency,
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
                        child: AppInput(
                          controller: _medications[i].durationController,
                          focusNode: _medications[i].durationFocus,
                          label: 'Duration',
                          hint: '7 days',
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
                                Text('Dose: ', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
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
                                Text('Days: ', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
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
                AppInput.text(
                  controller: _medications[i].instructionsController,
                  label: 'Special Instructions',
                  hint: 'e.g., Take with warm water',
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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
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
                    : colorScheme.onSurface.withValues(alpha: 0.6),
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
        AppInput(
          controller: _followUpNotesController,
          label: 'Follow-up Notes',
          hint: 'What to check on follow-up...',
          prefixIcon: Icons.note_outlined,
          maxLines: 3,
          keyboardType: TextInputType.multiline,
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
    return AppCard(
      borderRadius: BorderRadius.circular(16),
      borderColor: colorScheme.outlineVariant,
      borderWidth: 1,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
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

// Quick Medicine Selector Bottom Sheet
class _QuickMedicineSelectorSheet extends StatefulWidget {
  const _QuickMedicineSelectorSheet({
    required this.onSelectMedicine,
    required this.onAddCustom,
  });
  
  final void Function(String name, String dosage) onSelectMedicine;
  final VoidCallback onAddCustom;

  @override
  State<_QuickMedicineSelectorSheet> createState() => _QuickMedicineSelectorSheetState();
}

class _QuickMedicineSelectorSheetState extends State<_QuickMedicineSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  // Medicine categories with common medicines
  static const Map<String, List<Map<String, String>>> _medicineDatabase = {
    'Pain Relief': [
      {'name': 'Paracetamol', 'dosage': '500mg'},
      {'name': 'Paracetamol', 'dosage': '650mg'},
      {'name': 'Ibuprofen', 'dosage': '400mg'},
      {'name': 'Diclofenac', 'dosage': '50mg'},
      {'name': 'Tramadol', 'dosage': '50mg'},
      {'name': 'Aspirin', 'dosage': '75mg'},
      {'name': 'Naproxen', 'dosage': '500mg'},
    ],
    'Antibiotics': [
      {'name': 'Amoxicillin', 'dosage': '500mg'},
      {'name': 'Azithromycin', 'dosage': '500mg'},
      {'name': 'Ciprofloxacin', 'dosage': '500mg'},
      {'name': 'Cefixime', 'dosage': '200mg'},
      {'name': 'Metronidazole', 'dosage': '400mg'},
      {'name': 'Levofloxacin', 'dosage': '500mg'},
      {'name': 'Doxycycline', 'dosage': '100mg'},
      {'name': 'Augmentin', 'dosage': '625mg'},
    ],
    'Antacids & GI': [
      {'name': 'Omeprazole', 'dosage': '20mg'},
      {'name': 'Pantoprazole', 'dosage': '40mg'},
      {'name': 'Ranitidine', 'dosage': '150mg'},
      {'name': 'Domperidone', 'dosage': '10mg'},
      {'name': 'Ondansetron', 'dosage': '4mg'},
      {'name': 'Sucralfate', 'dosage': '1g'},
    ],
    'Antihistamines': [
      {'name': 'Cetirizine', 'dosage': '10mg'},
      {'name': 'Loratadine', 'dosage': '10mg'},
      {'name': 'Fexofenadine', 'dosage': '120mg'},
      {'name': 'Chlorpheniramine', 'dosage': '4mg'},
      {'name': 'Montelukast', 'dosage': '10mg'},
    ],
    'Diabetes': [
      {'name': 'Metformin', 'dosage': '500mg'},
      {'name': 'Metformin', 'dosage': '1000mg'},
      {'name': 'Glimepiride', 'dosage': '1mg'},
      {'name': 'Glimepiride', 'dosage': '2mg'},
      {'name': 'Sitagliptin', 'dosage': '100mg'},
      {'name': 'Empagliflozin', 'dosage': '10mg'},
    ],
    'Cardiovascular': [
      {'name': 'Amlodipine', 'dosage': '5mg'},
      {'name': 'Amlodipine', 'dosage': '10mg'},
      {'name': 'Losartan', 'dosage': '50mg'},
      {'name': 'Telmisartan', 'dosage': '40mg'},
      {'name': 'Atorvastatin', 'dosage': '10mg'},
      {'name': 'Atorvastatin', 'dosage': '20mg'},
      {'name': 'Clopidogrel', 'dosage': '75mg'},
      {'name': 'Metoprolol', 'dosage': '25mg'},
    ],
    'Vitamins': [
      {'name': 'Vitamin D3', 'dosage': '60000IU'},
      {'name': 'Vitamin B12', 'dosage': '1500mcg'},
      {'name': 'Vitamin C', 'dosage': '500mg'},
      {'name': 'Calcium + D3', 'dosage': '500mg'},
      {'name': 'Iron + Folic Acid', 'dosage': ''},
      {'name': 'Multivitamin', 'dosage': ''},
    ],
    'Respiratory': [
      {'name': 'Salbutamol', 'dosage': '4mg'},
      {'name': 'Salbutamol Inhaler', 'dosage': '100mcg'},
      {'name': 'Budesonide Inhaler', 'dosage': '200mcg'},
      {'name': 'Montelukast', 'dosage': '10mg'},
      {'name': 'Theophylline', 'dosage': '300mg'},
      {'name': 'Ambroxol', 'dosage': '30mg'},
    ],
  };

  List<Map<String, String>> get _filteredMedicines {
    List<Map<String, String>> medicines = [];
    
    if (_selectedCategory == 'All') {
      for (final category in _medicineDatabase.values) {
        medicines.addAll(category);
      }
    } else {
      medicines = _medicineDatabase[_selectedCategory] ?? [];
    }
    
    if (_searchQuery.isEmpty) {
      return medicines;
    }
    
    final query = _searchQuery.toLowerCase();
    return medicines.where((med) {
      final name = med['name']?.toLowerCase() ?? '';
      final dosage = med['dosage']?.toLowerCase() ?? '';
      return name.contains(query) || dosage.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final categories = ['All', ..._medicineDatabase.keys];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Medicine',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Select from list or add custom',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'All';
                            });
                          },
                          selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          checkmarkColor: const Color(0xFFF59E0B),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected 
                                ? const Color(0xFFF59E0B) 
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Add Custom button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: widget.onAddCustom,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Add Custom Medicine',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Medicine list
          Expanded(
            child: _filteredMedicines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Select a category to view medicines'
                              : 'No medicines found',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      final name = medicine['name'] ?? '';
                      final dosage = medicine['dosage'] ?? '';
                      final displayName = dosage.isNotEmpty ? '$name $dosage' : name;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.medication, color: Color(0xFFF59E0B), size: 20),
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
                            onPressed: () {
                              widget.onSelectMedicine(displayName, '1 tablet');
                              Navigator.pop(context);
                            },
                          ),
                          onTap: () {
                            widget.onSelectMedicine(displayName, '1 tablet');
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
