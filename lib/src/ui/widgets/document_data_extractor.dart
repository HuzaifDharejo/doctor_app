import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_theme.dart';

/// Widget for extracting data from images and PDFs
class DocumentDataExtractor extends StatefulWidget {
  final Function(Map<String, String> extractedData) onDataExtracted;
  final VoidCallback? onClose;

  const DocumentDataExtractor({
    super.key,
    required this.onDataExtracted,
    this.onClose,
  });

  @override
  State<DocumentDataExtractor> createState() => _DocumentDataExtractorState();
}

class _DocumentDataExtractorState extends State<DocumentDataExtractor> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isProcessing = false;
  OcrResult? _result;
  String? _selectedFileName;

  Future<void> _captureFromCamera() async {
    if (kIsWeb) {
      _showWebNotSupportedMessage();
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null) {
        await _processImage(photo.path, photo.name);
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await _processImageBytes(bytes, image.name);
        } else {
          await _processImage(image.path, image.name);
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
        });

        if (file.bytes != null) {
          await _processPdfBytes(file.bytes!, file.name);
        } else if (file.path != null) {
          await _processPdf(file.path!, file.name);
        }
      }
    } catch (e) {
      _showError('Failed to pick PDF: $e');
    }
  }

  Future<void> _processImage(String path, String name) async {
    setState(() {
      _isProcessing = true;
      _selectedFileName = name;
      _result = null;
    });

    final result = await _ocrService.extractTextFromImage(path);

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  Future<void> _processImageBytes(Uint8List bytes, String name) async {
    setState(() {
      _isProcessing = true;
      _selectedFileName = name;
      _result = null;
    });

    final result = await _ocrService.extractTextFromImageBytes(bytes, name);

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  Future<void> _processPdf(String path, String name) async {
    setState(() {
      _isProcessing = true;
      _selectedFileName = name;
      _result = null;
    });

    final result = await _ocrService.extractTextFromPdf(path);

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  Future<void> _processPdfBytes(Uint8List bytes, String name) async {
    setState(() {
      _isProcessing = true;
      _selectedFileName = name;
      _result = null;
    });

    final result = await _ocrService.extractTextFromPdfBytes(bytes);

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  void _showWebNotSupportedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Camera OCR is only available on mobile devices'),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _applyExtractedData() {
    if (_result?.parsedData != null) {
      widget.onDataExtracted(_result!.parsedData!);
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extract Data from Document',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scan images or PDFs to auto-fill fields',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source buttons
                Row(
                  children: [
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        subtitle: 'Take photo',
                        onTap: _isProcessing ? null : _captureFromCamera,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        subtitle: 'Pick image',
                        onTap: _isProcessing ? null : _pickImage,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.picture_as_pdf,
                        label: 'PDF',
                        subtitle: 'Select file',
                        onTap: _isProcessing ? null : _pickPdf,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                // Processing indicator
                if (_isProcessing) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Processing document...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (_selectedFileName != null)
                                Text(
                                  _selectedFileName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Results
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _buildResultsSection(isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(bool isDark) {
    if (!_result!.success) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _result!.errorMessage ?? 'Failed to extract text',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    final parsedData = _result!.parsedData ?? {};
    final displayFields = parsedData.entries
        .where((e) => e.key != 'full_text')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Found ${displayFields.length} data field${displayFields.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (displayFields.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Extracted Data',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Display extracted fields
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Column(
              children: displayFields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: index < displayFields.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: isDark ? AppColors.darkDivider : AppColors.divider,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatFieldName(field.key),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          field.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Raw text preview
        if (_result!.rawText != null && _result!.rawText!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text(
              'View Raw Text',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    _result!.rawText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Apply button
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: displayFields.isNotEmpty ? _applyExtractedData : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Apply Extracted Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDark;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
