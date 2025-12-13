// Patient View - Clinical Tab (Combined: Prescriptions + Records + Documents)
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../theme/app_theme.dart';
import '../edit_prescription_screen.dart';
import '../medical_record_detail_screen.dart';
import '../records/records.dart';

/// Combined Clinical Tab with sub-tabs for Prescriptions, Records, Documents
class PatientClinicalTab extends ConsumerStatefulWidget {
  const PatientClinicalTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  ConsumerState<PatientClinicalTab> createState() => _PatientClinicalTabState();
}

class _PatientClinicalTabState extends ConsumerState<PatientClinicalTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  
  // Prescriptions data
  List<Prescription> _prescriptions = [];
  bool _isLoadingRx = true;
  
  // Documents data
  List<_PatientDocument> _documents = [];
  bool _isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadPrescriptions();
    _loadDocuments();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoadingRx = true);
    try {
      final db = await ref.read(doctorDbProvider.future);
      final prescriptions = await db.getPrescriptionsForPatient(widget.patient.id);
      if (mounted) {
        setState(() {
          _prescriptions = prescriptions;
          _isLoadingRx = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRx = false);
      }
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(p.join(appDir.path, 'patient_documents', widget.patient.id.toString()));
      
      if (!await patientDocsDir.exists()) {
        if (mounted) setState(() {
          _documents = [];
          _isLoadingDocs = false;
        });
        return;
      }

      final files = await patientDocsDir.list().toList();
      final docs = <_PatientDocument>[];
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          docs.add(_PatientDocument(
            name: p.basename(file.path),
            path: file.path,
            size: stat.size,
            date: stat.modified,
            extension: p.extension(file.path).toLowerCase(),
          ));
        }
      }
      
      docs.sort((a, b) => b.date.compareTo(a.date));
      
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Sub-tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.medication_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Rx'),
                    if (_prescriptions.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_prescriptions.length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Records'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Docs'),
                    if (_documents.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_documents.length}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Sub-tab content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildPrescriptionsSubTab(isDark),
              _buildRecordsSubTab(isDark),
              _buildDocumentsSubTab(isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== PRESCRIPTIONS SUB-TAB ====================
  Widget _buildPrescriptionsSubTab(bool isDark) {
    if (_isLoadingRx) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No prescriptions yet',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date descending
    final sortedRx = List<Prescription>.from(_prescriptions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        primary: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: sortedRx.length,
        itemBuilder: (context, index) => _buildPrescriptionCard(sortedRx[index], isDark),
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription rx, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    // V5: Use FutureBuilder to load medications from normalized table
    final dbAsync = ref.read(doctorDbProvider);
    final db = dbAsync.when(
      data: (db) => db,
      loading: () => null,
      error: (_, __) => null,
    );

    return FutureBuilder<List<dynamic>>(
      future: db != null 
          ? db.getMedicationsForPrescriptionCompat(rx.id)
          : Future.value(<dynamic>[]),
      builder: (context, snapshot) {
        final meds = snapshot.data ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showPrescriptionDetails(rx),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.medication, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                            dateFormat.format(rx.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${meds.length} medication${meds.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54),
                      onSelected: (value) => _handleRxAction(value, rx),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'share', child: Text('Share')),
                        const PopupMenuItem(value: 'print', child: Text('Print PDF')),
                      ],
                    ),
                  ],
                ),
                if (meds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meds.take(3).map((med) {
                      final name = med is Map ? (med['name']?.toString() ?? 'Unknown') : med.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (meds.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${meds.length - 3} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
      }, // End of FutureBuilder builder
    ); // End of FutureBuilder
  }

  void _showPrescriptionDetails(Prescription rx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPrescriptionScreen(prescription: rx),
      ),
    ).then((_) => _loadPrescriptions());
  }

  Future<void> _handleRxAction(String action, Prescription rx) async {
    switch (action) {
      case 'edit':
        _showPrescriptionDetails(rx);
        break;
      case 'share':
        await PdfService.sharePrescriptionPdf(
          prescription: rx,
          patient: widget.patient,
          doctorName: 'Doctor',
          clinicName: 'Clinic',
        );
        break;
      case 'print':
        await PdfService.sharePrescriptionPdf(
          prescription: rx,
          patient: widget.patient,
          doctorName: 'Doctor',
          clinicName: 'Clinic',
        );
        break;
    }
  }

  // ==================== RECORDS SUB-TAB ====================
  Widget _buildRecordsSubTab(bool isDark) {
    final dbAsync = ref.watch(doctorDbProvider);
    final enabledTypes = ref.watch(appSettingsProvider).settings.enabledMedicalRecordTypes;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<MedicalRecord>>(
        // Key forces rebuild when enabled types change
        key: ValueKey('records_${enabledTypes.join('_')}'),
        future: db.getMedicalRecordsForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          // Filter records based on enabled types in settings
          final allRecords = snapshot.data ?? [];
          final records = allRecords.where((r) => enabledTypes.contains(r.recordType)).toList();

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medical records',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddRecord(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Record'),
                  ),
                ],
              ),
            );
          }

          records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

          return ListView.builder(
            primary: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            itemBuilder: (context, index) => _buildRecordCard(records[index], isDark),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildRecordCard(MedicalRecord record, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    
    Map<String, dynamic> data = {};
    try {
      if (record.dataJson != null) {
        data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
      }
    } catch (_) {}

    final typeLabel = _getRecordTypeLabel(record.recordType);
    final typeColor = _getRecordTypeColor(record.recordType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalRecordDetailScreen(record: record, patient: widget.patient),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getRecordTypeIcon(record.recordType), color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (record.diagnosis != null && record.diagnosis!.isNotEmpty)
                        Text(
                          record.diagnosis!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        dateFormat.format(record.recordDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectRecordTypeScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  String _getRecordTypeLabel(String recordType) {
    switch (recordType) {
      case 'psychiatric_assessment': return 'Psychiatric Assessment';
      case 'pulmonary_evaluation': return 'Pulmonary Evaluation';
      case 'therapy_session': return 'Therapy Session';
      case 'general': return 'General Consultation';
      case 'follow_up': return 'Follow-up';
      case 'lab_result': return 'Lab Result';
      default: return recordType.replaceAll('_', ' ').split(' ').map((w) => 
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
      ).join(' ');
    }
  }

  Color _getRecordTypeColor(String recordType) {
    switch (recordType) {
      case 'psychiatric_assessment': return const Color(0xFF8B5CF6);
      case 'pulmonary_evaluation': return const Color(0xFF3B82F6);
      case 'therapy_session': return const Color(0xFF10B981);
      case 'lab_result': return const Color(0xFFF59E0B);
      default: return AppColors.primary;
    }
  }

  IconData _getRecordTypeIcon(String recordType) {
    switch (recordType) {
      case 'psychiatric_assessment': return Icons.psychology;
      case 'pulmonary_evaluation': return Icons.air;
      case 'therapy_session': return Icons.chat_bubble_outline;
      case 'lab_result': return Icons.science;
      default: return Icons.description;
    }
  }

  // ==================== DOCUMENTS SUB-TAB ====================
  Widget _buildDocumentsSubTab(bool isDark) {
    if (_isLoadingDocs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents uploaded',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _uploadDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDocuments,
            child: ListView.builder(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _documents.length,
              itemBuilder: (context, index) => _buildDocumentCard(_documents[index], isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(_PatientDocument doc, bool isDark) {
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final iconData = _getDocumentIcon(doc.extension);
    final iconColor = _getDocumentColor(doc.extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDocument(doc),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${doc.formattedSize} • ${doc.formattedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54),
                  onSelected: (value) => _handleDocAction(value, doc),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Open')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(
        p.join(appDir.path, 'patient_documents', widget.patient.id.toString()),
      );

      if (!await patientDocsDir.exists()) {
        await patientDocsDir.create(recursive: true);
      }

      final newPath = p.join(patientDocsDir.path, result.files.single.name);
      await file.copy(newPath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        _loadDocuments();
      }
    }
  }

  void _openDocument(_PatientDocument doc) async {
    final uri = Uri.file(doc.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleDocAction(String action, _PatientDocument doc) async {
    switch (action) {
      case 'open':
        _openDocument(doc);
        break;
      case 'share':
        await Share.shareXFiles([XFile(doc.path)]);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text('Are you sure you want to delete "${doc.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await File(doc.path).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document deleted')),
            );
            _loadDocuments();
          }
        }
        break;
    }
  }

  IconData _getDocumentIcon(String ext) {
    switch (ext) {
      case '.pdf': return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png': return Icons.image;
      case '.doc':
      case '.docx': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String ext) {
    switch (ext) {
      case '.pdf': return Colors.red;
      case '.jpg':
      case '.jpeg':
      case '.png': return Colors.blue;
      case '.doc':
      case '.docx': return Colors.indigo;
      default: return Colors.grey;
    }
  }
}

/// Internal document model
class _PatientDocument {
  final String name;
  final String path;
  final int size;
  final DateTime date;
  final String extension;

  _PatientDocument({
    required this.name,
    required this.path,
    required this.size,
    required this.date,
    required this.extension,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate => DateFormat('MMM d, yyyy').format(date);
}
