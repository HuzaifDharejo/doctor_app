import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/photo_service.dart';

/// A widget that displays a patient's photo or initials
/// With optional ability to pick a new photo
class PatientAvatar extends StatefulWidget {
  final int? patientId;
  final String firstName;
  final String lastName;
  final double size;
  final bool editable;
  final VoidCallback? onPhotoChanged;
  final double borderRadius;
  final bool showEditIcon;

  const PatientAvatar({
    super.key,
    this.patientId,
    required this.firstName,
    required this.lastName,
    this.size = 64,
    this.editable = false,
    this.onPhotoChanged,
    this.borderRadius = 18,
    this.showEditIcon = true,
  });

  @override
  State<PatientAvatar> createState() => _PatientAvatarState();
}

class _PatientAvatarState extends State<PatientAvatar> {
  String? _photoBase64;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant PatientAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    if (widget.patientId == null) {
      setState(() {
        _loading = false;
        _photoBase64 = null;
      });
      return;
    }

    final photo = await PhotoService.getPatientPhoto(widget.patientId!);
    if (mounted) {
      setState(() {
        _photoBase64 = photo;
        _loading = false;
      });
    }
  }

  String _getInitials() {
    final first = widget.firstName.isNotEmpty ? widget.firstName[0].toUpperCase() : '';
    final last = widget.lastName.isNotEmpty ? widget.lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Color _getAvatarColor() {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.info,
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
    ];
    final index = widget.firstName.hashCode % colors.length;
    return colors[index.abs()];
  }

  Future<void> _pickPhoto() async {
    if (!widget.editable || widget.patientId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Compress if needed (optional)
          final bytes = PhotoService.compressIfNeeded(file.bytes!);
          if (bytes != null) {
            final saved = await PhotoService.savePatientPhoto(
              widget.patientId!,
              bytes,
            );
            if (saved != null && mounted) {
              setState(() => _photoBase64 = saved);
              widget.onPhotoChanged?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Photo updated successfully'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
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

  Future<void> _removePhoto() async {
    if (widget.patientId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await PhotoService.deletePatientPhoto(widget.patientId!);
      if (success && mounted) {
        setState(() => _photoBase64 = null);
        widget.onPhotoChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    final avatarColor = _getAvatarColor();
    final hasPhoto = _photoBase64 != null && _photoBase64!.isNotEmpty;

    return GestureDetector(
      onTap: widget.editable ? _showPhotoOptions : null,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (hasPhoto ? Colors.black : avatarColor).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: _loading
                  ? Container(
                      color: avatarColor.withOpacity(0.3),
                      child: Center(
                        child: SizedBox(
                          width: widget.size * 0.3,
                          height: widget.size * 0.3,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: avatarColor,
                          ),
                        ),
                      ),
                    )
                  : hasPhoto
                      ? Image.memory(
                          base64Decode(_photoBase64!),
                          fit: BoxFit.cover,
                          width: widget.size,
                          height: widget.size,
                          errorBuilder: (_, __, ___) => _buildInitialsAvatar(
                            initials,
                            avatarColor,
                          ),
                        )
                      : _buildInitialsAvatar(initials, avatarColor),
            ),
          ),
          if (widget.editable && widget.showEditIcon)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(widget.size * 0.08),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  hasPhoto ? Icons.edit : Icons.camera_alt,
                  size: widget.size * 0.16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    final hasPhoto = _photoBase64 != null && _photoBase64!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Patient Photo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _pickPhoto();
              },
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.delete_outline,
                label: 'Remove Photo',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circular variant of PatientAvatar for profile headers
class PatientAvatarCircle extends StatelessWidget {
  final int? patientId;
  final String firstName;
  final String lastName;
  final double size;
  final bool editable;
  final VoidCallback? onPhotoChanged;

  const PatientAvatarCircle({
    super.key,
    this.patientId,
    required this.firstName,
    required this.lastName,
    this.size = 100,
    this.editable = false,
    this.onPhotoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PatientAvatar(
      patientId: patientId,
      firstName: firstName,
      lastName: lastName,
      size: size,
      editable: editable,
      onPhotoChanged: onPhotoChanged,
      borderRadius: size / 2, // Makes it circular
      showEditIcon: editable,
    );
  }
}
