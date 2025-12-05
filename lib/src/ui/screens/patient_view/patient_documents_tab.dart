// Patient View - Documents Tab
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/app_button.dart';
import 'patient_view_widgets.dart' hide Text;

/// Model for patient document
class PatientDocument {
  PatientDocument({
    required this.name,
    required this.path,
    required this.size,
    required this.date,
    required this.extension,
  });

  final String name;
  final String path;
  final int size;
  final DateTime date;
  final String extension;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class PatientDocumentsTab extends StatefulWidget {
  const PatientDocumentsTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  State<PatientDocumentsTab> createState() => _PatientDocumentsTabState();
}

class _PatientDocumentsTabState extends State<PatientDocumentsTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return FutureBuilder<List<PatientDocument>>(
      future: _getPatientDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return PatientTabEmptyState(
            icon: Icons.folder_outlined,
            title: 'No Documents',
            subtitle: 'Upload documents for this patient',
            actionLabel: 'Upload Document',
            onAction: _uploadDocument,
          );
        }

        return Column(
          children: [
            // Upload button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ),
            // Documents list
            Expanded(
              child: ListView.builder(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _getDocTypeColor(doc.extension).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getDocTypeIcon(doc.extension),
                          color: _getDocTypeColor(doc.extension),
                        ),
                      ),
                      title: Text(
                        doc.name,
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${doc.formattedSize} • ${doc.formattedDate}',
                        style: TextStyle(color: secondaryColor, fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) => _handleDocumentAction(value, doc),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              leading: Icon(Icons.open_in_new),
                              title: Text('Open'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: AppColors.error),
                              title: Text('Delete', style: TextStyle(color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<PatientDocument>> _getPatientDocuments() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(p.join(docsDir.path, 'patient_documents', '${widget.patient.id}'));

      if (!await patientDocsDir.exists()) {
        return [];
      }

      final files = patientDocsDir.listSync().whereType<File>().toList();
      return files.map((file) {
        final stat = file.statSync();
        return PatientDocument(
          name: p.basename(file.path),
          path: file.path,
          size: stat.size,
          date: stat.modified,
          extension: p.extension(file.path).toLowerCase().replaceAll('.', ''),
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      return [];
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Uploading document...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Create patient documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(p.join(docsDir.path, 'patient_documents', '${widget.patient.id}'));
      if (!await patientDocsDir.exists()) {
        await patientDocsDir.create(recursive: true);
      }

      // Copy file to patient's documents folder
      final sourceFile = File(file.path!);
      final destPath = p.join(patientDocsDir.path, file.name);
      await sourceFile.copy(destPath);

      // Refresh and show success
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Document uploaded successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleDocumentAction(String action, PatientDocument doc) async {
    switch (action) {
      case 'open':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${doc.name}...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text('Are you sure you want to delete "${doc.name}"?'),
            actions: [
              AppButton.tertiary(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context, false),
              ),
              AppButton.danger(
                label: 'Delete',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await File(doc.path).delete();
            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting document: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
        break;
    }
  }

  IconData _getDocTypeIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocTypeColor(String extension) {
    switch (extension) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFF4CAF50);
      case 'doc':
      case 'docx':
        return const Color(0xFF2196F3);
      case 'txt':
        return const Color(0xFF9E9E9E);
      default:
        return AppColors.primary;
    }
  }
}
