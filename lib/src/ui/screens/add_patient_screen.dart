import 'package:drift/drift.dart' hide Column;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/input_validators.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/photo_service.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _medicalHistory = TextEditingController();
  final _allergiesController = TextEditingController();
  int _riskLevel = 1;
  bool _isSaving = false;
  Uint8List? _selectedPhotoBytes;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _medicalHistory.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedPhotoBytes = file.bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: dbAsync.when(
        data: (db) => _buildForm(context, db),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DoctorDatabase? db) {
    if (db == null) {
      return _buildErrorState(context);
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;
    
    return CustomScrollView(
      slivers: [
        // Gradient Header
        SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Add New Patient',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Avatar Section
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        children: [
                          Container(
                            width: isCompact ? 90 : 110,
                            height: isCompact ? 90 : 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _selectedPhotoBytes != null
                                  ? Image.memory(
                                      _selectedPhotoBytes!,
                                      fit: BoxFit.cover,
                                      width: isCompact ? 90 : 110,
                                      height: isCompact ? 90 : 110,
                                    )
                                  : DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary.withValues(alpha: 0.1),
                                            AppColors.accent.withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        size: isCompact ? 40 : 50,
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(isCompact ? 8 : 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.accent, Color(0xFF7C4DFF)],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _selectedPhotoBytes != null ? Icons.edit : Icons.camera_alt,
                                size: isCompact ? 14 : 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add photo',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Form Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  // Personal Information Card
                  _buildSectionCard(
                    context,
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    iconColor: AppColors.primary,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppInput.text(
                              controller: _first,
                              label: 'First Name',
                              hint: 'John',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) {
                                final result = InputValidators.validateName(v, fieldName: 'First name');
                                return result.isValid ? null : result.errorMessage;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInput.text(
                              controller: _last,
                              label: 'Last Name',
                              hint: 'Doe',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) {
                                if (v == null || v.isEmpty) return null; // Optional
                                final result = InputValidators.validateName(v, fieldName: 'Last name');
                                return result.isValid ? null : result.errorMessage;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Information Card
                  _buildSectionCard(
                    context,
                    title: 'Contact Information',
                    icon: Icons.contact_phone_outlined,
                    iconColor: AppColors.teal,
                    children: [
                      AppInput.phone(
                        controller: _phone,
                        label: 'Phone Number',
                        hint: '+1 (555) 123-4567',
                        validator: (v) {
                          final result = InputValidators.validatePhone(v);
                          return result.isValid ? null : result.errorMessage;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppInput.email(
                        controller: _email,
                        label: 'Email Address',
                        hint: 'john.doe@email.com',
                        validator: (v) {
                          final result = InputValidators.validateEmail(v);
                          return result.isValid ? null : result.errorMessage;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppInput.text(
                        controller: _address,
                        label: 'Address',
                        hint: '123 Medical Ave, City, State',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Medical Information Card
                  _buildSectionCard(
                    context,
                    title: 'Medical Information',
                    icon: Icons.medical_information_outlined,
                    iconColor: AppColors.error,
                    children: [
                      _buildMedicalHistoryField(),
                      const SizedBox(height: 20),
                      Text(
                        'Risk Level',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRiskLevelSelector(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button with Gradient
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : () => _savePatient(db),
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  height: 26,
                                  width: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Save Patient',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      borderColor: isDark ? AppColors.darkDivider : AppColors.divider.withValues(alpha: 0.5),
      borderWidth: 1,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.divider.withValues(alpha: 0.5),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medical History with conditions suggestions
        SuggestionTextField(
          controller: _medicalHistory,
          label: 'Medical History',
          hint: 'Chronic conditions, past surgeries...',
          prefixIcon: Icons.history,
          maxLines: 2,
          suggestions: PatientSuggestions.chronicConditions,
        ),
        const SizedBox(height: 12),
        // Allergies field
        SuggestionTextField(
          controller: _allergiesController,
          label: 'Allergies',
          hint: 'Known allergies...',
          prefixIcon: Icons.warning_amber_outlined,
          suggestions: PatientSuggestions.allergies,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 400;
        
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  icon, 
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  size: isCompact ? 18 : 20,
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: isCompact ? 38 : 44,
                minHeight: isCompact ? 38 : 44,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16, 
                vertical: isCompact ? 12 : 14,
              ),
              isDense: isCompact,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskLevelSelector() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2) 
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = _riskLevel == level;
              Color color;
              if (level <= 2) {
                color = AppColors.riskLow;
              } else if (level == 3) {
                color = AppColors.riskMedium;
              } else if (level == 4) {
                color = AppColors.riskMedium;
              } else {
                color = AppColors.riskHigh;
              }
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskLevel = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withValues(alpha: 0.8)],
                            )
                          : null,
                      color: isSelected ? null : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : (isDark ? AppColors.darkDivider : AppColors.divider),
                        width: isSelected ? 0 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white.withValues(alpha: 0.8) 
                                : color.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _savePatient(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Combine medical history with allergies
      final combinedHistory = [
        if (_medicalHistory.text.isNotEmpty) _medicalHistory.text,
        if (_allergiesController.text.isNotEmpty) 'Allergies: ${_allergiesController.text}',
      ].join('\n');
      
      final companion = PatientsCompanion.insert(
        firstName: _first.text,
        lastName: Value(_last.text),
        phone: Value(_phone.text),
        email: Value(_email.text),
        address: Value(_address.text),
        medicalHistory: Value(combinedHistory),
        riskLevel: Value(_riskLevel),
      );
      final patientId = await db.insertPatient(companion);
      
      // Save photo if one was selected
      if (_selectedPhotoBytes != null) {
        await PhotoService.savePatientPhoto(patientId, _selectedPhotoBytes!);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Patient added successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Patient Photo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a photo for easier identification',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              _buildPhotoOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                subtitle: 'Select an existing photo',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto();
                },
              ),
              if (_selectedPhotoBytes != null) ...[
                const SizedBox(height: 12),
                _buildPhotoOptionTile(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  subtitle: 'Delete current photo',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton.tertiary(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  fullWidth: true,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoOptionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Database Not Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cannot add patients without database connection',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
