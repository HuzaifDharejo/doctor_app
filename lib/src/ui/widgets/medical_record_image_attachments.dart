import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Widget for managing multiple image attachments for medical records
class MedicalRecordImageAttachments extends StatefulWidget {
  const MedicalRecordImageAttachments({
    super.key,
    required this.patientId,
    required this.recordId,
    required this.onImagesChanged,
    this.initialImages = const [],
    this.maxImages = 10,
  });

  final int patientId;
  final int? recordId; // Null for new records, set for existing records
  final List<ImageAttachmentData> initialImages;
  final Function(List<ImageAttachmentData> images) onImagesChanged;
  final int maxImages;

  @override
  State<MedicalRecordImageAttachments> createState() => _MedicalRecordImageAttachmentsState();
}

class _MedicalRecordImageAttachmentsState extends State<MedicalRecordImageAttachments> {
  late List<ImageAttachmentData> _images;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(MedicalRecordImageAttachments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      _images = List.from(widget.initialImages);
    }
  }

  Future<void> _pickImagesFromGallery() async {
    if (_images.length >= widget.maxImages) {
      _showMaxImagesReached();
      return;
    }

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      final remainingSlots = widget.maxImages - _images.length;
      final filesToAdd = pickedFiles.take(remainingSlots).toList();

      if (filesToAdd.length < pickedFiles.length) {
        _showMaxImagesReached();
      }

      for (final file in filesToAdd) {
        final bytes = await file.readAsBytes();
        final attachment = ImageAttachmentData(
          fileName: path.basename(file.path),
          filePath: file.path,
          fileBytes: bytes,
          fileType: 'image/${path.extension(file.path).substring(1)}',
          fileSizeBytes: bytes.length,
        );
        _images.add(attachment);
      }

      setState(() {});
      widget.onImagesChanged(_images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_images.length >= widget.maxImages) {
      _showMaxImagesReached();
      return;
    }

    if (kIsWeb) {
      // On web, use file picker instead
      await _pickImagesFromGallery();
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final attachment = ImageAttachmentData(
          fileName: path.basename(photo.path),
          filePath: photo.path,
          fileBytes: bytes,
          fileType: 'image/jpeg',
          fileSizeBytes: bytes.length,
        );
        _images.add(attachment);
        setState(() {});
        widget.onImagesChanged(_images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromFiles() async {
    if (_images.length >= widget.maxImages) {
      _showMaxImagesReached();
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final remainingSlots = widget.maxImages - _images.length;
      final filesToAdd = result.files.take(remainingSlots).toList();

      if (filesToAdd.length < result.files.length) {
        _showMaxImagesReached();
      }

      for (final platformFile in filesToAdd) {
        Uint8List? bytes;
        String filePath = '';

        if (kIsWeb) {
          bytes = platformFile.bytes;
          filePath = platformFile.name;
        } else {
          if (platformFile.path != null) {
            filePath = platformFile.path!;
            final file = File(filePath);
            bytes = await file.readAsBytes();
          }
        }

        if (bytes != null) {
          final attachment = ImageAttachmentData(
            fileName: platformFile.name,
            filePath: filePath,
            fileBytes: bytes,
            fileType: platformFile.extension != null ? 'image/${platformFile.extension}' : 'image/jpeg',
            fileSizeBytes: bytes.length,
          );
          _images.add(attachment);
        }
      }

      setState(() {});
      widget.onImagesChanged(_images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      widget.onImagesChanged(_images);
    });
  }

  void _showMaxImagesReached() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery();
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: const Text('Choose from Files'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromFiles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewImage(ImageAttachmentData image, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: kIsWeb || image.filePath.startsWith('http')
                    ? Image.memory(image.fileBytes, fit: BoxFit.contain)
                    : Image.file(File(image.filePath), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images',
                        style: TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_images.length}/${widget.maxImages} images',
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_images.length < widget.maxImages)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: _showImagePickerOptions,
                    tooltip: 'Add Images',
                  ),
              ],
            ),
          ),
          if (_images.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No images attached',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showImagePickerOptions,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Images'),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < _images.length; i++)
                    _buildImageThumbnail(_images[i], i, isDark),
                  if (_images.length < widget.maxImages)
                    _buildAddButton(isDark),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(ImageAttachmentData image, int index, bool isDark) {
    return GestureDetector(
      onTap: () => _viewImage(image, index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: kIsWeb || image.filePath.startsWith('http')
                  ? Image.memory(
                      image.fileBytes,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Image.file(
                      File(image.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: isDark ? Colors.white70 : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: isDark ? Colors.white70 : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for image attachment
class ImageAttachmentData {
  final String fileName;
  final String filePath;
  final Uint8List fileBytes;
  final String fileType;
  final int fileSizeBytes;
  final int? attachmentId; // Set if loaded from database

  ImageAttachmentData({
    required this.fileName,
    required this.filePath,
    required this.fileBytes,
    required this.fileType,
    required this.fileSizeBytes,
    this.attachmentId,
  });

  ImageAttachmentData copyWith({
    String? fileName,
    String? filePath,
    Uint8List? fileBytes,
    String? fileType,
    int? fileSizeBytes,
    int? attachmentId,
  }) {
    return ImageAttachmentData(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileBytes: fileBytes ?? this.fileBytes,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      attachmentId: attachmentId ?? this.attachmentId,
    );
  }
}

