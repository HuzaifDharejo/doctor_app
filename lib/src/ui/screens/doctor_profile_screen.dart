import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../providers/db_provider.dart';
import '../../services/doctor_settings_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/signature_pad.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasChanges = false;
  final _formKey = GlobalKey<FormState>();
  
  // Store initial values to detect changes
  late DoctorProfile _initialProfile;

  // Profile Controllers
  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _qualificationsController;
  late TextEditingController _licenseController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;

  // Contact Controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _clinicPhoneController;

  // Consultation Fees
  late TextEditingController _consultationFeeController;
  late TextEditingController _followUpFeeController;
  late TextEditingController _emergencyFeeController;

  // Timings
  late Map<String, Map<String, dynamic>> _workingHours;

  // Languages
  late List<String> _languages;

  // Signature
  String? _signatureData;
  String? _photoData;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController();
    _specializationController = TextEditingController();
    _qualificationsController = TextEditingController();
    _licenseController = TextEditingController();
    _experienceController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _clinicNameController = TextEditingController();
    _clinicAddressController = TextEditingController();
    _clinicPhoneController = TextEditingController();
    _consultationFeeController = TextEditingController();
    _followUpFeeController = TextEditingController();
    _emergencyFeeController = TextEditingController();
    _workingHours = {};
    _languages = [];
  }

  void _initializeFromProfile(DoctorProfile profile) {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _initialProfile = profile;
    _nameController.text = profile.name;
    
    // Add listeners to detect changes
    _addChangeListeners();
    _specializationController.text = profile.specialization;
    _qualificationsController.text = profile.qualifications;
    _licenseController.text = profile.licenseNumber;
    _experienceController.text =
        profile.experienceYears > 0 ? profile.experienceYears.toString() : '';
    _bioController.text = profile.bio;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _clinicNameController.text = profile.clinicName;
    _clinicAddressController.text = profile.clinicAddress;
    _clinicPhoneController.text = profile.clinicPhone;
    _consultationFeeController.text =
        profile.consultationFee > 0 ? profile.consultationFee.toStringAsFixed(0) : '';
    _followUpFeeController.text =
        profile.followUpFee > 0 ? profile.followUpFee.toStringAsFixed(0) : '';
    _emergencyFeeController.text =
        profile.emergencyFee > 0 ? profile.emergencyFee.toStringAsFixed(0) : '';
    _workingHours = Map.from(
        profile.workingHours.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),);
    if (_workingHours.isEmpty) {
      _workingHours = {
        'Monday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Tuesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Wednesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Thursday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Friday': {'enabled': true, 'start': '09:00', 'end': '13:00'},
        'Saturday': {'enabled': true, 'start': '10:00', 'end': '14:00'},
        'Sunday': {'enabled': false, 'start': '09:00', 'end': '17:00'},
      };
    }
    _languages = List.from(profile.languages);
    if (_languages.isEmpty) {
      _languages = ['English'];
    }
    _signatureData = profile.signatureData;
    _photoData = profile.photoData;
  }
  
  void _addChangeListeners() {
    final controllers = [
      _nameController, _specializationController, _qualificationsController,
      _licenseController, _experienceController, _bioController,
      _phoneController, _emailController, _clinicNameController,
      _clinicAddressController, _clinicPhoneController,
      _consultationFeeController, _followUpFeeController, _emergencyFeeController,
    ];
    for (final controller in controllers) {
      controller.addListener(_checkForChanges);
    }
  }
  
  void _checkForChanges() {
    final hasChanges = _nameController.text != _initialProfile.name ||
        _specializationController.text != _initialProfile.specialization ||
        _qualificationsController.text != _initialProfile.qualifications ||
        _licenseController.text != _initialProfile.licenseNumber ||
        _experienceController.text != (_initialProfile.experienceYears > 0 ? _initialProfile.experienceYears.toString() : '') ||
        _bioController.text != _initialProfile.bio ||
        _phoneController.text != _initialProfile.phone ||
        _emailController.text != _initialProfile.email ||
        _clinicNameController.text != _initialProfile.clinicName ||
        _clinicAddressController.text != _initialProfile.clinicAddress ||
        _clinicPhoneController.text != _initialProfile.clinicPhone ||
        _consultationFeeController.text != (_initialProfile.consultationFee > 0 ? _initialProfile.consultationFee.toStringAsFixed(0) : '') ||
        _followUpFeeController.text != (_initialProfile.followUpFee > 0 ? _initialProfile.followUpFee.toStringAsFixed(0) : '') ||
        _emergencyFeeController.text != (_initialProfile.emergencyFee > 0 ? _initialProfile.emergencyFee.toStringAsFixed(0) : '') ||
        _signatureData != _initialProfile.signatureData ||
        _photoData != _initialProfile.photoData;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _qualificationsController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _consultationFeeController.dispose();
    _followUpFeeController.dispose();
    _emergencyFeeController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'DR';
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  Future<void> _pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          setState(() {
            _photoData = base64Encode(bytes);
          });
          _checkForChanges();
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final newProfile = DoctorProfile(
        name: _nameController.text,
        specialization: _specializationController.text,
        qualifications: _qualificationsController.text,
        licenseNumber: _licenseController.text,
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        bio: _bioController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        clinicName: _clinicNameController.text,
        clinicAddress: _clinicAddressController.text,
        clinicPhone: _clinicPhoneController.text,
        consultationFee: double.tryParse(_consultationFeeController.text) ?? 0,
        followUpFee: double.tryParse(_followUpFeeController.text) ?? 0,
        emergencyFee: double.tryParse(_emergencyFeeController.text) ?? 0,
        languages: _languages,
        workingHours: _workingHours,
        signatureData: _signatureData,
        photoData: _photoData,
      );

      await ref.read(doctorSettingsProvider).saveProfile(newProfile);
      
      // Update initial profile to reflect saved state
      _initialProfile = newProfile;
      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(doctorSettingsProvider).profile;
    final isDark = context.isDarkMode;
    final isCompact = context.isCompact;

    _initializeFromProfile(profile);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDark, isCompact),
            SliverFillRemaining(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor:
                          isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: [
                        _buildTab(Icons.person_outline, 'Profile'),
                        _buildTab(Icons.business_outlined, 'Clinic'),
                        _buildTab(Icons.schedule_outlined, 'Schedule'),
                        _buildTab(Icons.draw_outlined, 'Signature'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(isDark, isCompact),
                        _buildClinicTab(isDark, isCompact),
                        _buildScheduleTab(isDark, isCompact),
                        _buildSignatureTab(isDark, isCompact),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _hasChanges
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saveProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, bool isCompact) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: _photoData != null
                              ? MemoryImage(base64Decode(_photoData!))
                              : null,
                          child: _photoData == null
                              ? Text(
                                  _getInitials(_nameController.text),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.isNotEmpty
                      ? 'Dr. ${_nameController.text}'
                      : 'Doctor Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _specializationController.text.isNotEmpty
                      ? _specializationController.text
                      : 'Specialization',
                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuickStat(Icons.work_history,
                        '${_experienceController.text.isNotEmpty ? _experienceController.text : "0"}+ yrs',),
                    _buildStatDivider(),
                    _buildQuickStat(Icons.verified,
                        _licenseController.text.isNotEmpty ? _licenseController.text : 'License #',),
                    _buildStatDivider(),
                    _buildQuickStat(Icons.language, '${_languages.length} Languages'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 12,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildProfileTab(bool isDark, bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          _buildCard(
            isDark: isDark,
            title: 'Personal Information',
            icon: Icons.person_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditableField(label: 'Display Name', controller: _nameController, isDark: isDark, icon: Icons.badge_outlined, hint: 'Dr. John Smith'),
                const SizedBox(height: 16),
                _buildEditableField(label: 'Bio', controller: _bioController, isDark: isDark, maxLines: 4, hint: 'Write a brief description...'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            isDark: isDark,
            title: 'Professional Details',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildEditableField(label: 'Specialization', controller: _specializationController, isDark: isDark, icon: Icons.medical_services_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditableField(label: 'Experience (Years)', controller: _experienceController, isDark: isDark, icon: Icons.work_history_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditableField(label: 'Qualifications', controller: _qualificationsController, isDark: isDark, icon: Icons.school_outlined, hint: 'MBBS, MD, etc.'),
                const SizedBox(height: 16),
                _buildEditableField(label: 'License Number', controller: _licenseController, isDark: isDark, icon: Icons.verified_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            isDark: isDark,
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            child: Row(
              children: [
                Expanded(child: _buildEditableField(label: 'Phone', controller: _phoneController, isDark: isDark, icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
                const SizedBox(width: 12),
                Expanded(child: _buildEditableField(label: 'Email', controller: _emailController, isDark: isDark, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            isDark: isDark,
            title: 'Languages',
            icon: Icons.language,
            trailing: IconButton(onPressed: _addLanguage, icon: const Icon(Icons.add_circle_outline), color: AppColors.primary),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.asMap().entries.map((entry) => _buildLanguageChip(entry.value, entry.key, isDark)).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildClinicTab(bool isDark, bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          _buildCard(
            isDark: isDark,
            title: 'Clinic Details',
            icon: Icons.business_outlined,
            child: Column(
              children: [
                _buildEditableField(label: 'Clinic Name', controller: _clinicNameController, isDark: isDark, icon: Icons.local_hospital_outlined),
                const SizedBox(height: 16),
                _buildEditableField(label: 'Address', controller: _clinicAddressController, isDark: isDark, icon: Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: 16),
                _buildEditableField(label: 'Clinic Phone', controller: _clinicPhoneController, isDark: isDark, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            isDark: isDark,
            title: 'Consultation Fees',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                _buildFeeField(label: 'Consultation Fee', controller: _consultationFeeController, isDark: isDark, icon: Icons.chat_outlined, color: AppColors.primary),
                const SizedBox(height: 12),
                _buildFeeField(label: 'Follow-up Fee', controller: _followUpFeeController, isDark: isDark, icon: Icons.replay, color: AppColors.accent),
                const SizedBox(height: 12),
                _buildFeeField(label: 'Emergency Fee', controller: _emergencyFeeController, isDark: isDark, icon: Icons.emergency_outlined, color: AppColors.error),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(bool isDark, bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          _buildCard(
            isDark: isDark,
            title: 'Working Hours',
            icon: Icons.schedule,
            child: Column(children: _workingHours.entries.map((e) => _buildDaySchedule(e.key, e.value, isDark)).toList()),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSignatureTab(bool isDark, bool isCompact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        children: [
          _buildCard(
            isDark: isDark,
            title: 'Digital Signature',
            icon: Icons.draw,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your signature will be automatically added to prescriptions and invoices',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),),
                const SizedBox(height: 16),
                SignaturePad(initialSignature: _signatureData, onSignatureChanged: (data) { setState(() => _signatureData = data); _checkForChanges(); }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            isDark: isDark,
            title: 'Signature Preview',
            icon: Icons.preview_outlined,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: Column(
                children: [
                  const Text('This is how your signature will appear on documents:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Container(
                        height: 60,
                        width: 150,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider))),
                        child: _signatureData != null
                            ? _buildSignaturePreviewWidget(_signatureData!, isDark)
                            : Center(child: Text('No signature', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint, fontStyle: FontStyle.italic))),
                      ),
                      const SizedBox(height: 8),
                      Text('Dr. ${_nameController.text.isNotEmpty ? _nameController.text : "Your Name"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_specializationController.text.isNotEmpty ? _specializationController.text : 'Specialization',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSignaturePreviewWidget(String data, bool isDark) {
    try {
      // Try to parse as JSON (stroke data or image data)
      final jsonData = jsonDecode(data);
      if (jsonData is Map) {
        // Handle stroke format
        if (jsonData['strokes'] != null) {
          final strokesData = jsonData['strokes'] as List;
          final strokes = strokesData.map((stroke) {
            return (stroke as List).map((point) {
              return Offset(
                (point['x'] as num).toDouble(),
                (point['y'] as num).toDouble(),
              );
            }).toList();
          }).toList();
          
          return CustomPaint(
            size: const Size(150, 60),
            painter: _SignaturePreviewPainter(strokes: strokes),
          );
        }
        // Handle image format from camera/gallery
        if (jsonData['image'] != null) {
          final imageBytes = base64Decode(jsonData['image'] as String);
          return Image.memory(imageBytes, fit: BoxFit.contain);
        }
      }
    } catch (_) {
      // Try as raw base64 image
      try {
        return Image.memory(base64Decode(data), fit: BoxFit.contain);
      } catch (_) {}
    }
    return Center(child: Text('No signature', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.textHint, fontStyle: FontStyle.italic)));
  }

  Widget _buildCard({required bool isDark, required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary))),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({required String label, required TextEditingController controller, required bool isDark, IconData? icon, int maxLines = 1, String? hint, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  Widget _buildFeeField({required String label, required TextEditingController controller, required bool isDark, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day, Map<String, dynamic> hours, bool isDark) {
    final isEnabled = hours['enabled'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.success.withValues(alpha: 0.05) : (isDark ? AppColors.darkBackground : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isEnabled ? AppColors.success.withValues(alpha: 0.2) : (isDark ? AppColors.darkDivider : AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: isEnabled ? AppColors.success.withValues(alpha: 0.1) : (isDark ? AppColors.darkDivider : Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(day.substring(0, 3), style: TextStyle(fontWeight: FontWeight.bold, color: isEnabled ? AppColors.success : (isDark ? AppColors.darkTextHint : AppColors.textHint)))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(isEnabled ? '${hours['start']} - ${hours['end']}' : 'Closed', style: TextStyle(fontSize: 13, color: isEnabled ? AppColors.success : (isDark ? AppColors.darkTextHint : AppColors.textHint))),
              ],
            ),
          ),
          Switch.adaptive(value: isEnabled, onChanged: (value) { setState(() => _workingHours[day]!['enabled'] = value); _checkForChanges(); }, activeTrackColor: AppColors.success.withValues(alpha: 0.5), activeThumbColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String language, int index, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primaryLight.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(language, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          GestureDetector(onTap: () { setState(() => _languages.removeAt(index)); _checkForChanges(); }, child: Icon(Icons.close, size: 16, color: AppColors.error.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  void _addLanguage() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Language'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter language', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (controller.text.isNotEmpty) { setState(() => _languages.add(controller.text)); Navigator.pop(context); } }, child: const Text('Add')),
        ],
      ),
    );
  }
}

/// Custom painter for signature preview
class _SignaturePreviewPainter extends CustomPainter {

  _SignaturePreviewPainter({required this.strokes});
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;
    
    // Calculate bounds of the signature
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final stroke in strokes) {
      for (final point in stroke) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }
    
    final signatureWidth = maxX - minX;
    final signatureHeight = maxY - minY;
    
    if (signatureWidth <= 0 || signatureHeight <= 0) return;
    
    // Calculate scale to fit in preview
    final scaleX = (size.width - 10) / signatureWidth;
    final scaleY = (size.height - 10) / signatureHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calculate offset to center
    final offsetX = (size.width - signatureWidth * scale) / 2 - minX * scale;
    final offsetY = (size.height - signatureHeight * scale) / 2 - minY * scale;
    
    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * scale + offsetX, stroke.first.dy * scale + offsetY);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * scale + offsetX, stroke[i].dy * scale + offsetY);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
