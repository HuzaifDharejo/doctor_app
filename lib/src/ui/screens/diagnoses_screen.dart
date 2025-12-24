import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';

/// Screen to display all diagnoses for a patient across all medical records
class DiagnosesScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const DiagnosesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<DiagnosesScreen> createState() => _DiagnosesScreenState();
}

class _DiagnosesScreenState extends ConsumerState<DiagnosesScreen> {
  List<_DiagnosisEntry> _diagnoses = [];
  bool _isLoading = true;
  String _filterStatus = 'All';
  
  static const List<String> _statusFilters = [
    'All',
    'Active',
    'Resolved',
    'Chronic',
    'Under Evaluation',
  ];

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  Future<void> _loadDiagnoses() async {
    ref.read(doctorDbProvider).whenData((db) async {
      final records = await db.getMedicalRecordsForPatient(widget.patientId);
      final treatments = await db.getTreatmentOutcomesForPatient(widget.patientId);
      
      final diagnoses = <_DiagnosisEntry>[];
      
      // Extract diagnoses from medical records
      for (final record in records) {
        if (record.diagnosis != null && record.diagnosis!.isNotEmpty) {
          String status = 'Active';
          String treatment = record.treatment ?? '';
          
          // Try to get more info from dataJson
          if (record.dataJson != null) {
            try {
              final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
              // Check if there's a status in the data
              if (data.containsKey('diagnosis_status')) {
                status = data['diagnosis_status'] as String;
              }
            } catch (_) {}
          }
          
          diagnoses.add(_DiagnosisEntry(
            diagnosis: record.diagnosis!,
            date: record.recordDate,
            source: _getRecordTypeLabel(record.recordType),
            status: status,
            treatment: treatment,
            notes: record.doctorNotes ?? '',
            recordId: record.id,
            recordType: record.recordType,
          ));
        }
      }
      
      // Extract diagnoses from treatment outcomes
      for (final treatment in treatments) {
        if (treatment.diagnosis.isNotEmpty) {
          // Check if this diagnosis is already added from a linked medical record
          final alreadyAdded = diagnoses.any((d) => 
              d.diagnosis.toLowerCase() == treatment.diagnosis.toLowerCase() &&
              d.date.year == treatment.startDate.year &&
              d.date.month == treatment.startDate.month &&
              d.date.day == treatment.startDate.day);
          
          if (!alreadyAdded) {
            diagnoses.add(_DiagnosisEntry(
              diagnosis: treatment.diagnosis,
              date: treatment.startDate,
              source: 'Treatment: ${treatment.treatmentType}',
              status: _mapOutcomeToStatus(treatment.outcome),
              treatment: treatment.treatmentDescription,
              notes: treatment.notes ?? '',
              recordId: treatment.id,
              recordType: 'treatment_outcome',
            ));
          }
        }
      }
      
      // Sort by date (most recent first)
      diagnoses.sort((a, b) => b.date.compareTo(a.date));
      
      if (mounted) {
        setState(() {
          _diagnoses = diagnoses;
          _isLoading = false;
        });
      }
    });
  }

  String _getRecordTypeLabel(String recordType) {
    switch (recordType) {
      case 'general':
        return 'General Consultation';
      case 'follow_up':
        return 'Follow-up Visit';
      case 'procedure':
        return 'Procedure';
      case 'imaging':
        return 'Imaging Study';
      case 'lab_result':
        return 'Lab Result';
      case 'pulmonary_evaluation':
        return 'Pulmonary Evaluation';
      default:
        return recordType;
    }
  }

  String _mapOutcomeToStatus(String outcome) {
    switch (outcome) {
      case 'resolved':
        return 'Resolved';
      case 'improved':
        return 'Active';
      case 'stable':
        return 'Chronic';
      case 'ongoing':
        return 'Active';
      case 'worsened':
        return 'Active';
      default:
        return 'Under Evaluation';
    }
  }

  List<_DiagnosisEntry> get _filteredDiagnoses {
    if (_filterStatus == 'All') return _diagnoses;
    return _diagnoses.where((d) => d.status == _filterStatus).toList();
  }

  // Group diagnoses by unique diagnosis name
  Map<String, List<_DiagnosisEntry>> get _groupedDiagnoses {
    final grouped = <String, List<_DiagnosisEntry>>{};
    for (final d in _filteredDiagnoses) {
      final key = d.diagnosis.toLowerCase().trim();
      grouped.putIfAbsent(key, () => []).add(d);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.filter_list,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onSelected: (value) => setState(() => _filterStatus = value),
                  itemBuilder: (context) => _statusFilters.map((status) => 
                    PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          if (_filterStatus == status)
                            const Icon(Icons.check, size: 18, color: AppColors.primary),
                          if (_filterStatus == status)
                            const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medical_information_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diagnoses',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.patientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_diagnoses.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_diagnoses.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _diagnoses.isEmpty
                ? _buildEmptyState(isDark)
                : _buildDiagnosesList(isDark, textColor, cardColor, borderColor),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFFA78BFA).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_information_outlined,
                size: 56,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Diagnoses Recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diagnoses from medical records\nwill appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosesList(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    final grouped = _groupedDiagnoses;
    final diagnosisNames = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: diagnosisNames.length,
      itemBuilder: (context, index) {
        final diagnosisKey = diagnosisNames[index];
        final entries = grouped[diagnosisKey]!;
        final latestEntry = entries.first;
        
        return _buildDiagnosisCard(
          latestEntry,
          entries.length,
          isDark,
          textColor,
          cardColor,
          borderColor,
        );
      },
    );
  }

  Widget _buildDiagnosisCard(
    _DiagnosisEntry entry,
    int occurrenceCount,
    bool isDark,
    Color textColor,
    Color cardColor,
    Color borderColor,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor(entry.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getStatusIcon(entry.status),
              color: statusColor,
              size: 26,
            ),
          ),
          title: Text(
            entry.diagnosis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.15),
                          statusColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (occurrenceCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$occurrenceCount records',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'First recorded: ${dateFormat.format(entry.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.03) 
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Source',
                    entry.source,
                    Icons.folder_outlined,
                    isDark,
                    textColor,
                  ),
                  if (entry.treatment.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Treatment',
                      entry.treatment,
                      Icons.medical_services_outlined,
                      isDark,
                      textColor,
                    ),
                  ],
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Notes',
                      entry.notes,
                      Icons.notes_outlined,
                      isDark,
                      textColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Chronic':
        return Colors.blue;
      case 'Under Evaluation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.warning_amber_rounded;
      case 'Resolved':
        return Icons.check_circle_outline;
      case 'Chronic':
        return Icons.history;
      case 'Under Evaluation':
        return Icons.search;
      default:
        return Icons.help_outline;
    }
  }
}

class _DiagnosisEntry {
  final String diagnosis;
  final DateTime date;
  final String source;
  final String status;
  final String treatment;
  final String notes;
  final int recordId;
  final String recordType;

  _DiagnosisEntry({
    required this.diagnosis,
    required this.date,
    required this.source,
    required this.status,
    required this.treatment,
    required this.notes,
    required this.recordId,
    required this.recordType,
  });
}
