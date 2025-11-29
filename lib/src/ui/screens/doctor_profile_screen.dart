import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/db_provider.dart';
import '../../services/doctor_settings_service.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

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

  // Achievements (placeholder for future implementation)
  final List<String> _achievements = [];

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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
    
    _nameController.text = profile.name;
    _specializationController.text = profile.specialization;
    _qualificationsController.text = profile.qualifications;
    _licenseController.text = profile.licenseNumber;
    _experienceController.text = profile.experienceYears > 0 ? profile.experienceYears.toString() : '';
    _bioController.text = profile.bio;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _clinicNameController.text = profile.clinicName;
    _clinicAddressController.text = profile.clinicAddress;
    _clinicPhoneController.text = profile.clinicPhone;
    _consultationFeeController.text = profile.consultationFee > 0 ? profile.consultationFee.toStringAsFixed(0) : '';
    _followUpFeeController.text = profile.followUpFee > 0 ? profile.followUpFee.toStringAsFixed(0) : '';
    _emergencyFeeController.text = profile.emergencyFee > 0 ? profile.emergencyFee.toStringAsFixed(0) : '';
    _workingHours = Map.from(profile.workingHours.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))));
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
  }

  @override
  void dispose() {
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

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
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
      );

      await ref.read(doctorSettingsProvider).saveProfile(newProfile);

      setState(() => _isEditing = false);

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
            backgroundColor: Colors.green,
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
    final profile = ref.watch(doctorSettingsProvider).profile;
    
    // Initialize controllers from profile
    _initializeFromProfile(profile);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Save', style: TextStyle(color: Colors.white)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _toggleEdit,
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withBlue(200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  _getInitials(_nameController.text),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isEditing)
                          SizedBox(
                            width: 250,
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          )
                        else
                          Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          _specializationController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _licenseController.text,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
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

            // Stats Row
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.access_time,
                      value: '${_experienceController.text}+',
                      label: 'Years Exp.',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.people,
                      value: '5000+',
                      label: 'Patients',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.star,
                      value: '4.9',
                      label: 'Rating',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.article,
                      value: '15+',
                      label: 'Publications',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            // Content Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // About Section
                    _buildSection(
                      title: 'About',
                      icon: Icons.person_outline,
                      colorScheme: colorScheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            TextFormField(
                              controller: _bioController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                            )
                          else
                            Text(
                              _bioController.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.school, 'Qualifications', 
                            _qualificationsController, _isEditing, colorScheme),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.work_history, 'Experience', 
                            _experienceController, _isEditing, colorScheme, suffix: ' years'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Section
                    _buildSection(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_outlined,
                      colorScheme: colorScheme,
                      child: Column(
                        children: [
                          _buildContactTile(Icons.phone, 'Phone', 
                            _phoneController, _isEditing, colorScheme),
                          const Divider(),
                          _buildContactTile(Icons.email, 'Email', 
                            _emailController, _isEditing, colorScheme),
                          const Divider(),
                          _buildContactTile(Icons.business, 'Clinic Name', 
                            _clinicNameController, _isEditing, colorScheme),
                          const Divider(),
                          _buildContactTile(Icons.location_on, 'Clinic Address', 
                            _clinicAddressController, _isEditing, colorScheme, maxLines: 2),
                          const Divider(),
                          _buildContactTile(Icons.call, 'Clinic Phone', 
                            _clinicPhoneController, _isEditing, colorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Working Hours Section
                    _buildSection(
                      title: 'Working Hours',
                      icon: Icons.schedule,
                      colorScheme: colorScheme,
                      child: Column(
                        children: _workingHours.entries.map((entry) {
                          return _buildWorkingHourTile(
                            entry.key,
                            entry.value,
                            colorScheme,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Consultation Fees Section
                    _buildSection(
                      title: 'Consultation Fees',
                      icon: Icons.payments_outlined,
                      colorScheme: colorScheme,
                      child: Column(
                        children: [
                          _buildFeeRow('Consultation', _consultationFeeController, 
                            Icons.chat_outlined, colorScheme),
                          const SizedBox(height: 12),
                          _buildFeeRow('Follow-up', _followUpFeeController, 
                            Icons.replay, colorScheme),
                          const SizedBox(height: 12),
                          _buildFeeRow('Emergency', _emergencyFeeController, 
                            Icons.emergency_outlined, colorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Languages Section
                    _buildSection(
                      title: 'Languages',
                      icon: Icons.language,
                      colorScheme: colorScheme,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _languages.map((lang) {
                          return Chip(
                            label: Text(lang),
                            backgroundColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Achievements Section
                    _buildSection(
                      title: 'Achievements & Awards',
                      icon: Icons.emoji_events_outlined,
                      colorScheme: colorScheme,
                      child: Column(
                        children: _achievements.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    size: 14,
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    if (!_isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share profile feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('QR Code generation coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Generate QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required Widget child,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, TextEditingController controller,
      bool isEditing, ColorScheme colorScheme, {String suffix = ''}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                  ),
                )
              : Text(
                  '${controller.text}$suffix',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String label, TextEditingController controller,
      bool isEditing, ColorScheme colorScheme, {int maxLines = 1}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      subtitle: isEditing
          ? TextFormField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                isDense: true,
                border: UnderlineInputBorder(),
              ),
            )
          : Text(
              controller.text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildWorkingHourTile(String day, Map<String, dynamic> hours, ColorScheme colorScheme) {
    final isEnabled = hours['enabled'] as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          if (_isEditing)
            Switch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  _workingHours[day]!['enabled'] = value;
                });
              },
            ),
          Expanded(
            child: Text(
              isEnabled ? '${hours['start']} - ${hours['end']}' : 'Closed',
              style: TextStyle(
                color: isEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Open',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, TextEditingController controller, 
      IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_isEditing)
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: 'Rs. ',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else
            Text(
              'Rs. ${controller.text}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
