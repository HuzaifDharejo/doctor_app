import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../db/doctor_db.dart';
import '../../services/ocr_extraction_service.dart';
import '../../services/pdf_template_config.dart';
import '../../services/pdf_service.dart';
import '../../services/doctor_settings_service.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';

class PrescriptionPadScannerScreen extends ConsumerStatefulWidget {
  const PrescriptionPadScannerScreen({super.key});

  @override
  ConsumerState<PrescriptionPadScannerScreen> createState() => _PrescriptionPadScannerScreenState();
}

class _PrescriptionPadScannerScreenState extends ConsumerState<PrescriptionPadScannerScreen> {
  File? _selectedImage;
  File? _selectedPdf;
  String? _selectedFileName;
  Map<String, dynamic>? _extractedData;
  bool _isProcessing = false;
  String? _errorMessage;
  
  // Controllers for extracted data
  final _clinic1NameController = TextEditingController();
  final _clinic1AddressController = TextEditingController();
  final _clinic1Phone1Controller = TextEditingController();
  final _clinic1Phone2Controller = TextEditingController();
  final _clinic1HoursController = TextEditingController();
  
  final _clinic2NameController = TextEditingController();
  final _clinic2AddressController = TextEditingController();
  final _clinic2Phone1Controller = TextEditingController();
  final _clinic2Phone2Controller = TextEditingController();
  final _clinic2HoursController = TextEditingController();
  
  final _expertInController = TextEditingController();
  final _workingExperienceController = TextEditingController();
  
  // Section management
  List<Map<String, dynamic>> _customSections = [];
  
  // Background image
  File? _backgroundImage;
  String? _backgroundImageBase64;

  @override
  void initState() {
    super.initState();
    // Load existing template data if available (after first frame)
    Future.microtask(() {
      if (mounted) {
        _loadExistingTemplate();
      }
    });
  }

  void _loadExistingTemplate() {
    final profile = ref.read(doctorSettingsProvider).profile;
    final config = profile.pdfTemplateConfig;
    
    // Only load if there's existing template data
    if (!_hasTemplateData(config)) return;
    
    // Parse clinic info from address lines
    if (config.clinicAddressLine1.isNotEmpty) {
      final lines = config.clinicAddressLine1.split('\n');
      if (lines.isNotEmpty) {
        _clinic1NameController.text = lines[0];
        if (lines.length > 1) {
          _clinic1AddressController.text = lines.sublist(1).join('\n');
        }
      }
    }
    
    if (config.clinicAddressLine2.isNotEmpty) {
      final lines = config.clinicAddressLine2.split('\n');
      if (lines.isNotEmpty) {
        _clinic2NameController.text = lines[0];
        if (lines.length > 1) {
          _clinic2AddressController.text = lines.sublist(1).join('\n');
        }
      }
    }
    
    _clinic1Phone1Controller.text = config.clinicPhone1;
    _clinic1Phone2Controller.text = config.clinicPhone2;
    _clinic1HoursController.text = config.clinicHours;
    _expertInController.text = config.expertInDiseases;
    _workingExperienceController.text = config.workingExperience;
    
    // Create a mock extractedData structure for display
    final List<Map<String, dynamic>> sectionsList = config.sectionLabels?.entries.map<Map<String, dynamic>>((e) => {
      'type': e.key,
      'label': e.value,
    }).toList() ?? <Map<String, dynamic>>[];
    
    // Load background image if exists
    if (config.backgroundImageType == 'custom' && config.customBackgroundData != null && config.customBackgroundData!.isNotEmpty) {
      _backgroundImageBase64 = config.customBackgroundData;
    }
    
    setState(() {
      _extractedData = {
        'clinics': <dynamic>[],
        'expertIn': config.expertInDiseases.isNotEmpty ? config.expertInDiseases.split(' - ') : <String>[],
        'workingExperience': config.workingExperience,
        'sections': sectionsList,
      };
      _customSections = List<Map<String, dynamic>>.from(sectionsList);
    });
  }
  
  bool _hasTemplateData(PdfTemplateConfig config) {
    return config.clinicAddressLine1.isNotEmpty || 
           config.clinicAddressLine2.isNotEmpty ||
           config.clinicPhone1.isNotEmpty ||
           config.clinicPhone2.isNotEmpty ||
           config.expertInDiseases.isNotEmpty ||
           config.workingExperience.isNotEmpty ||
           (config.sectionLabels != null && config.sectionLabels!.isNotEmpty);
  }

  @override
  void dispose() {
    _clinic1NameController.dispose();
    _clinic1AddressController.dispose();
    _clinic1Phone1Controller.dispose();
    _clinic1Phone2Controller.dispose();
    _clinic1HoursController.dispose();
    _clinic2NameController.dispose();
    _clinic2AddressController.dispose();
    _clinic2Phone1Controller.dispose();
    _clinic2Phone2Controller.dispose();
    _clinic2HoursController.dispose();
    _expertInController.dispose();
    _workingExperienceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 90);
      if (image == null || !mounted) return;
      
      setState(() {
        _selectedImage = File(image.path);
        _extractedData = null;
        _errorMessage = null;
        _isProcessing = true;
      });
      
      try {
        final data = await OcrExtractionService.extractFromImage(image.path);
        if (mounted) {
          _populateControllersFromData(data);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error extracting text: $e';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error picking image: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // On web, we need bytes; on mobile/desktop, use path
      );
      
      if (result == null || result.files.isEmpty || !mounted) return;
      
      final file = result.files.first;
      
      setState(() {
        _selectedImage = null;
        _selectedFileName = file.name;
        _extractedData = null;
        _errorMessage = null;
        _isProcessing = true;
        if (!kIsWeb && file.path != null) {
          _selectedPdf = File(file.path!);
        }
      });
      
      try {
        Map<String, dynamic> data;
        if (kIsWeb) {
          // On web, use bytes
          if (file.bytes == null) {
            throw Exception('Failed to read PDF file');
          }
          data = await OcrExtractionService.extractFromPdfBytes(file.bytes!);
        } else {
          // On mobile/desktop, use path
          final path = file.path;
          if (path == null) {
            throw Exception('Failed to get PDF file path');
          }
          data = await OcrExtractionService.extractFromPdf(path);
        }
        if (mounted) {
          _populateControllersFromData(data);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error extracting from PDF: $e. If this is a scanned PDF, please convert it to an image first.';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error picking PDF: $e';
          _isProcessing = false;
        });
      }
    }
  }
  
  void _populateControllersFromData(Map<String, dynamic> data) {
    // Populate controllers with extracted data
    final clinics = data['clinics'] as List<dynamic>;
    if (clinics.isNotEmpty) {
      final clinic1 = clinics[0] as Map<String, dynamic>;
      _clinic1NameController.text = clinic1['name']?.toString() ?? '';
      _clinic1AddressController.text = clinic1['address']?.toString() ?? '';
      _clinic1Phone1Controller.text = clinic1['phone1']?.toString() ?? '';
      _clinic1Phone2Controller.text = clinic1['phone2']?.toString() ?? '';
      _clinic1HoursController.text = clinic1['hours']?.toString() ?? '';
    }
    if (clinics.length > 1) {
      final clinic2 = clinics[1] as Map<String, dynamic>;
      _clinic2NameController.text = clinic2['name']?.toString() ?? '';
      _clinic2AddressController.text = clinic2['address']?.toString() ?? '';
      _clinic2Phone1Controller.text = clinic2['phone1']?.toString() ?? '';
      _clinic2Phone2Controller.text = clinic2['phone2']?.toString() ?? '';
      _clinic2HoursController.text = clinic2['hours']?.toString() ?? '';
    }
    
    final expertIn = data['expertIn'] as List<dynamic>? ?? [];
    _expertInController.text = expertIn.map((e) => e.toString()).join(' - ');
    
    _workingExperienceController.text = data['workingExperience']?.toString() ?? '';
    
    // Initialize custom sections from extracted sections
    final sections = data['sections'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> customSections = sections.map<Map<String, dynamic>>((s) => Map<String, dynamic>.from(s as Map)).toList();
    
    if (mounted) {
      setState(() {
        _extractedData = data;
        _customSections = customSections;
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _pickBackgroundImage() async {
    try {
      if (kIsWeb) {
        // On web, use FilePicker for better compatibility
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        
        if (result == null || result.files.isEmpty || !mounted) return;
        
        final file = result.files.first;
        if (file.bytes == null) return;
        
        final base64String = base64Encode(file.bytes!);
        
        if (mounted) {
          setState(() {
            _backgroundImage = null; // Can't use File on web
            _backgroundImageBase64 = base64String;
          });
        }
      } else {
        // On mobile/desktop, use ImagePicker
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (image == null || !mounted) return;
        
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final imageFile = File(image.path);
        
        if (mounted) {
          setState(() {
            _backgroundImage = imageFile;
            _backgroundImageBase64 = base64String;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }
  
  void _removeBackgroundImage() {
    setState(() {
      _backgroundImage = null;
      _backgroundImageBase64 = null;
    });
  }
  
  void _addSection() {
    // Show dialog to select section type
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        String selectedType = 'history';
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Section'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Section Type',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'history', child: Text('History')),
                    DropdownMenuItem(value: 'diagnosis', child: Text('Diagnosis')),
                    DropdownMenuItem(value: 'medications', child: Text('Medications')),
                    DropdownMenuItem(value: 'lab_tests', child: Text('Lab Tests')),
                    DropdownMenuItem(value: 'radiology', child: Text('Radiology')),
                    DropdownMenuItem(value: 'advice', child: Text('Advice')),
                    DropdownMenuItem(value: 'follow_up', child: Text('Follow-up')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value ?? 'history';
                      controller.text = _getDefaultSectionLabel(selectedType);
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Section Label',
                    hintText: 'e.g., Investigations Advised:',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _customSections.add({
                      'type': selectedType,
                      'label': controller.text.isNotEmpty ? controller.text : _getDefaultSectionLabel(selectedType),
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _getDefaultSectionLabel(String type) {
    switch (type) {
      case 'history': return 'History:';
      case 'diagnosis': return 'Diagnosis:';
      case 'medications': return 'Medications:';
      case 'lab_tests': return 'Investigations Advised:';
      case 'radiology': return 'Radiology:';
      case 'advice': return 'Instructions:';
      case 'follow_up': return 'Follow-up:';
      default: return '$type:';
    }
  }
  
  void _removeSection(int index) {
    setState(() {
      _customSections.removeAt(index);
    });
  }
  
  void _editSectionLabel(int index) {
    final section = _customSections[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: (section['label'] as String?) ?? '');
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Section Label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Section Label',
            hintText: 'e.g., Investigations Advised:',
            labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customSections[index]['label'] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _printSample() async {
    try {
      final profile = ref.read(doctorSettingsProvider).profile;
      final config = profile.pdfTemplateConfig;
      
      // Create dummy patient
      final dummyPatient = Patient(
        id: 0,
        firstName: 'John',
        lastName: 'Doe',
        age: 45,
        gender: 'Male',
        phone: '0300-1234567',
        email: 'john.doe@example.com',
        address: '123 Main Street, City',
        medicalHistory: 'Hypertension',
        allergies: 'Penicillin',
        bloodType: 'O+',
        chronicConditions: '',
        emergencyContactName: '',
        emergencyContactPhone: '',
        riskLevel: 0,
        tags: '',
        createdAt: DateTime.now(),
      );
      
      // Create dummy prescription
      final dummyPrescription = Prescription(
        id: 0,
        patientId: 0,
        createdAt: DateTime.now(),
        itemsJson: jsonEncode({
          'medications': [
            {
              'name': 'Paracetamol',
              'dosage': '500mg',
              'frequency': 'Twice daily',
              'duration': '5 days',
            },
            {
              'name': 'Amoxicillin',
              'dosage': '250mg',
              'frequency': 'Three times daily',
              'duration': '7 days',
            },
          ],
          'lab_tests': ['Complete Blood Count', 'Blood Sugar'],
          'follow_up': {
            'date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
            'notes': 'Review after one week',
          },
        }),
        instructions: 'Take with food. Complete the full course.',
        diagnosis: 'Upper respiratory tract infection',
        chiefComplaint: 'Fever and cough for 3 days',
        vitalsJson: jsonEncode({
          'bp': '120/80',
          'pulse': '72',
          'temperature': '98.6',
        }),
        isRefillable: false,
      );
      
      // Build section labels from custom sections
      Map<String, String> sectionLabels = {};
      for (var section in _customSections) {
        final type = section['type'] as String?;
        final label = section['label'] as String?;
        if (type != null && label != null) {
          sectionLabels[type] = label;
        }
      }
      
      // Create config with custom sections and background
      final sampleConfig = config.copyWith(
        sectionLabels: sectionLabels.isNotEmpty ? sectionLabels : null,
        backgroundImageType: _backgroundImageBase64 != null ? 'custom' : 'none',
        customBackgroundData: _backgroundImageBase64,
      );
      
      // Generate and share PDF
      await PdfService.sharePrescriptionPdf(
        patient: dummyPatient,
        prescription: dummyPrescription,
        doctorName: profile.displayName,
        clinicName: config.clinicAddressLine1.isNotEmpty 
          ? (config.clinicAddressLine1.split('\n').first) 
          : (profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic'),
        clinicPhone: config.clinicPhone1.isNotEmpty ? config.clinicPhone1 : profile.clinicPhone,
        clinicAddress: config.clinicAddressLine1,
        signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
        templateConfig: sampleConfig,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample PDF generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating sample: $e')),
        );
      }
    }
  }

  Future<void> _saveTemplate() async {
    try {
      final profile = ref.read(doctorSettingsProvider).profile;
      
      // Combine clinic info: Clinic 1 goes to line1, Clinic 2 to line2
      String clinicAddressLine1 = _clinic1AddressController.text;
      if (_clinic1NameController.text.isNotEmpty) {
        clinicAddressLine1 = '${_clinic1NameController.text}\n$clinicAddressLine1';
      }
      
      String clinicAddressLine2 = _clinic2AddressController.text;
      if (_clinic2NameController.text.isNotEmpty) {
        clinicAddressLine2 = '${_clinic2NameController.text}\n$clinicAddressLine2';
      }
      
      // Combine phone numbers (prioritize clinic 1, then clinic 2)
      String phone1 = _clinic1Phone1Controller.text;
      String phone2 = _clinic1Phone2Controller.text;
      if (phone2.isEmpty && _clinic2Phone1Controller.text.isNotEmpty) {
        phone2 = _clinic2Phone1Controller.text;
      }
      
      // Combine hours
      String hours = _clinic1HoursController.text;
      if (_clinic2HoursController.text.isNotEmpty) {
        hours = hours.isNotEmpty 
          ? '$hours\n${_clinic2HoursController.text}'
          : _clinic2HoursController.text;
      }
      
      // Extract section labels from custom sections
      Map<String, String>? sectionLabels;
      if (_customSections.isNotEmpty) {
        sectionLabels = {};
        for (final section in _customSections) {
          final type = section['type'] as String?;
          final label = section['label'] as String?;
          if (type != null && label != null) {
            sectionLabels[type] = label;
          }
        }
        if (sectionLabels.isEmpty) {
          sectionLabels = null;
        }
      }
      
      final updatedConfig = profile.pdfTemplateConfig.copyWith(
        clinicAddressLine1: clinicAddressLine1,
        clinicAddressLine2: clinicAddressLine2,
        clinicPhone1: phone1,
        clinicPhone2: phone2,
        clinicHours: hours,
        showExpertInDiseases: _expertInController.text.isNotEmpty,
        expertInDiseases: _expertInController.text,
        showWorkingExperience: _workingExperienceController.text.isNotEmpty,
        workingExperience: _workingExperienceController.text,
        // Enable fields that are in the example
        showRadiology: true,
        showMrNumber: true,
        showOccupation: true,
        sectionLabels: sectionLabels,
        backgroundImageType: _backgroundImageBase64 != null ? 'custom' : 'none',
        customBackgroundData: _backgroundImageBase64,
      );
      
      final updatedProfile = profile.copyWith(
        pdfTemplateConfig: updatedConfig,
      );
      
      await ref.read(doctorSettingsProvider).saveProfile(updatedProfile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(doctorSettingsProvider).profile;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Prescription Pad'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        elevation: 0,
      ),
      body: _extractedData == null
        ? _buildUploadSection(isDark, profile)
        : _buildReviewSection(isDark, profile),
    );
  }

  Widget _buildUploadSection(bool isDark, DoctorProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Show existing doctor info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Doctor Info', style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                )),
                const SizedBox(height: 8),
                Text('Name: ${profile.name}', style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                )),
                Text('Specialization: ${profile.specialization}', style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                )),
                Text('Qualifications: ${profile.qualifications}', style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                )),
                const SizedBox(height: 8),
                Text('We will extract clinic info, expert in, and experience from your pad.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  )),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMessage!, style: TextStyle(color: AppColors.error)),
            ),
          
          if (_selectedImage != null || _selectedPdf != null) ...[
            Container(
              height: 300,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        if (_selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
              ),
            ),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator()),
          ],
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    side: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    side: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Pick PDF File'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                side: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(bool isDark, DoctorProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          if (_selectedImage != null || _selectedPdf != null)
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        if (_selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
              ),
            ),
          
          // Prescription Sections Management
          _buildSection(
            title: 'Prescription Sections',
            icon: Icons.view_list,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage sections that will appear in your prescriptions:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._customSections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  final type = section['type'] as String? ?? '';
                  final label = section['label'] as String? ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getSectionIcon(type), color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getSectionName(type),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Label: "$label"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editSectionLabel(index),
                          color: AppColors.primary,
                          tooltip: 'Edit Label',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _removeSection(index),
                          color: AppColors.error,
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Background Image
          _buildSection(
            title: 'Background Image (Optional)',
            icon: Icons.image,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_backgroundImageBase64 != null) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _backgroundImage != null && !kIsWeb
                        ? Image.file(_backgroundImage!, fit: BoxFit.contain)
                        : Image.memory(
                            base64Decode(_backgroundImageBase64!),
                            fit: BoxFit.contain,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _removeBackgroundImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove Background'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickBackgroundImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Background Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a background image to be used in all prescription PDFs',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clinic 1
          _buildSection(
            title: 'Clinic 1',
            icon: Icons.business,
            isDark: isDark,
            child: Column(
              children: [
                TextField(
                  controller: _clinic1NameController,
                  decoration: InputDecoration(
                    labelText: 'Clinic Name',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clinic1AddressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clinic1Phone1Controller,
                        decoration: InputDecoration(
                          labelText: 'Phone 1',
                          labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _clinic1Phone2Controller,
                        decoration: InputDecoration(
                          labelText: 'Phone 2',
                          labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clinic1HoursController,
                  decoration: InputDecoration(
                    labelText: 'Working Hours',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clinic 2 (Optional)
          _buildSection(
            title: 'Clinic 2 (Optional)',
            icon: Icons.business_outlined,
            isDark: isDark,
            child: Column(
              children: [
                TextField(
                  controller: _clinic2NameController,
                  decoration: InputDecoration(
                    labelText: 'Clinic Name',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clinic2AddressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clinic2Phone1Controller,
                        decoration: InputDecoration(
                          labelText: 'Phone 1',
                          labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _clinic2Phone2Controller,
                        decoration: InputDecoration(
                          labelText: 'Phone 2',
                          labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clinic2HoursController,
                  decoration: InputDecoration(
                    labelText: 'Working Hours',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expert In
          _buildSection(
            title: 'Expert In Diseases',
            icon: Icons.medical_services,
            isDark: isDark,
            child: TextField(
              controller: _expertInController,
              decoration: InputDecoration(
                hintText: 'Asthma - Allergy - Vaccination - Sleep Disorders...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 3,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Working Experience
          _buildSection(
            title: 'Working Experience',
            icon: Icons.work_history,
            isDark: isDark,
            child: TextField(
              controller: _workingExperienceController,
              decoration: InputDecoration(
                hintText: 'Govt. Hospital Samanabad Lhr.\nMember Of Pakistan Chest Society...',
                hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 5,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Print Sample Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _printSample,
              icon: const Icon(Icons.print),
              label: const Text('Print Sample with Dummy Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'history': return Icons.history;
      case 'diagnosis': return Icons.medical_services;
      case 'medications': return Icons.medication;
      case 'lab_tests': return Icons.science;
      case 'radiology': return Icons.medical_information;
      case 'advice': return Icons.info;
      case 'follow_up': return Icons.calendar_today;
      default: return Icons.label;
    }
  }

  String _getSectionName(String type) {
    switch (type) {
      case 'history': return 'History';
      case 'diagnosis': return 'Impression/Diagnosis';
      case 'medications': return 'Medications';
      case 'lab_tests': return 'Lab Tests/Investigations';
      case 'radiology': return 'Radiology';
      case 'advice': return 'Advice/Instructions';
      case 'follow_up': return 'Follow-up';
      default: return type;
    }
  }
}

