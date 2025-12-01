import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'records/add_lab_result_screen.dart';

/// Screen to display lab results history with normal range indicators
class LabResultsScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const LabResultsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends ConsumerState<LabResultsScreen> with SingleTickerProviderStateMixin {
  List<MedicalRecord> _labResults = [];
  bool _isLoading = true;
  String _filterCategory = 'All';
  late TabController _tabController;
  
  // Common lab test categories
  static const List<String> _categories = [
    'All',
    'Blood Chemistry',
    'Hematology',
    'Urinalysis',
    'Lipid Panel',
    'Thyroid',
    'Liver Function',
    'Kidney Function',
    'Cardiac Markers',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLabResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLabResults() async {
    ref.read(doctorDbProvider).whenData((db) async {
      final records = await db.getMedicalRecordsForPatient(widget.patientId);
      final labResults = records.where((r) => r.recordType == 'lab_result').toList();
      
      if (mounted) {
        setState(() {
          _labResults = labResults;
          _isLoading = false;
        });
      }
    });
  }

  List<MedicalRecord> get _filteredResults {
    if (_filterCategory == 'All') return _labResults;
    return _labResults.where((r) {
      if (r.dataJson == null) return false;
      try {
        final data = jsonDecode(r.dataJson!) as Map<String, dynamic>;
        final category = data['test_category'] as String? ?? 'Other';
        return category == _filterCategory;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<MedicalRecord> get _abnormalResults {
    return _labResults.where((r) {
      if (r.dataJson == null) return false;
      try {
        final data = jsonDecode(r.dataJson!) as Map<String, dynamic>;
        final status = data['result_status'] as String? ?? 'Normal';
        return status != 'Normal';
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Lab Results - ${widget.patientName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_filteredResults.length}'),
                isLabelVisible: _filteredResults.isNotEmpty,
                child: const Icon(Icons.science),
              ),
              text: 'All Results',
            ),
            Tab(
              icon: Badge(
                label: Text('${_abnormalResults.length}'),
                isLabelVisible: _abnormalResults.isNotEmpty,
                backgroundColor: Colors.red,
                child: const Icon(Icons.warning_amber),
              ),
              text: 'Abnormal',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Lab Result',
            onPressed: () async {
              final db = ref.read(doctorDbProvider).value;
              if (db != null) {
                final patient = await db.getPatientById(widget.patientId);
                if (patient != null && mounted) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLabResultScreen(preselectedPatient: patient),
                    ),
                  );
                  if (result == true) {
                    _loadLabResults();
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                _buildCategoryFilter(isDark),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResultsList(_filteredResults, isDark),
                      _buildResultsList(_abnormalResults, isDark, showAbnormalOnly: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _filterCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _filterCategory = category);
              },
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList(List<MedicalRecord> results, bool isDark, {bool showAbnormalOnly = false}) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showAbnormalOnly ? Icons.check_circle_outline : Icons.science_outlined,
              size: 64,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              showAbnormalOnly 
                  ? 'No abnormal results' 
                  : 'No lab results found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (!showAbnormalOnly) ...[
              const SizedBox(height: 8),
              Text(
                'Add a new lab result to get started',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Group by test name for trend analysis
    final groupedByTest = <String, List<MedicalRecord>>{};
    for (final result in results) {
      final testName = _getTestName(result);
      groupedByTest.putIfAbsent(testName, () => []).add(result);
    }

    return RefreshIndicator(
      onRefresh: _loadLabResults,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return _buildLabResultCard(result, isDark, groupedByTest);
        },
      ),
    );
  }

  String _getTestName(MedicalRecord record) {
    if (record.dataJson == null) return 'Unknown Test';
    try {
      final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
      return data['test_name'] as String? ?? 'Unknown Test';
    } catch (_) {
      return 'Unknown Test';
    }
  }

  Widget _buildLabResultCard(MedicalRecord record, bool isDark, Map<String, List<MedicalRecord>> groupedByTest) {
    final data = record.dataJson != null 
        ? jsonDecode(record.dataJson!) as Map<String, dynamic>
        : <String, dynamic>{};
    
    final testName = data['test_name'] as String? ?? 'Lab Test';
    final result = data['result'] as String? ?? 'N/A';
    final units = data['units'] as String? ?? '';
    final referenceRange = data['reference_range'] as String? ?? '';
    final status = data['result_status'] as String? ?? 'Normal';
    final category = data['test_category'] as String? ?? '';
    final interpretation = data['interpretation'] as String? ?? '';
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Normal':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'High':
        statusColor = AppColors.error;
        statusIcon = Icons.arrow_upward;
      case 'Low':
        statusColor = AppColors.warning;
        statusIcon = Icons.arrow_downward;
      case 'Critical':
        statusColor = Colors.red.shade900;
        statusIcon = Icons.warning;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.info;
    }

    // Check if this test has history for trend
    final testHistory = groupedByTest[testName] ?? [];
    final hasTrend = testHistory.length > 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
      borderColor: status == 'Critical' ? Colors.red.shade900 : null,
      borderWidth: status == 'Critical' ? 2 : 0,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      onTap: () => _showResultDetails(record, data, isDark),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.science, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (category.isNotEmpty)
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Result Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Result',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              result,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            if (units.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                units,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (referenceRange.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reference Range',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            referenceRange,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Range Indicator Bar
              if (referenceRange.isNotEmpty && _canParseRange(result, referenceRange)) ...[
                const SizedBox(height: 12),
                _buildRangeIndicator(result, referenceRange, statusColor, isDark),
              ],
              
              // Trend indicator if multiple results exist
              if (hasTrend) ...[
                const SizedBox(height: 12),
                _buildTrendIndicator(testHistory, isDark),
              ],
              
              // Date and interpretation
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(record.recordDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  if (interpretation.isNotEmpty) ...[
                    const Spacer(),
                    Icon(
                      Icons.notes,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        interpretation,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canParseRange(String result, String referenceRange) {
    try {
      final resultValue = double.tryParse(result.replaceAll(RegExp(r'[^\d.]'), ''));
      if (resultValue == null) return false;
      
      // Try to parse range like "70-100" or "< 100" or "> 50"
      if (referenceRange.contains('-')) {
        final parts = referenceRange.split('-');
        if (parts.length == 2) {
          final low = double.tryParse(parts[0].replaceAll(RegExp(r'[^\d.]'), ''));
          final high = double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.]'), ''));
          return low != null && high != null;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Widget _buildRangeIndicator(String result, String referenceRange, Color statusColor, bool isDark) {
    try {
      final resultValue = double.parse(result.replaceAll(RegExp(r'[^\d.]'), ''));
      final parts = referenceRange.split('-');
      final low = double.parse(parts[0].replaceAll(RegExp(r'[^\d.]'), ''));
      final high = double.parse(parts[1].replaceAll(RegExp(r'[^\d.]'), ''));
      
      // Calculate position (0 = at low, 1 = at high)
      // Add 20% buffer on each side for out-of-range values
      final range = high - low;
      final bufferLow = low - (range * 0.2);
      final bufferHigh = high + (range * 0.2);
      final totalRange = bufferHigh - bufferLow;
      
      double position = (resultValue - bufferLow) / totalRange;
      position = position.clamp(0.0, 1.0);
      
      final normalStart = (low - bufferLow) / totalRange;
      final normalEnd = (high - bufferLow) / totalRange;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Normal range highlight
                Positioned(
                  left: normalStart * MediaQuery.of(context).size.width * 0.7,
                  width: (normalEnd - normalStart) * MediaQuery.of(context).size.width * 0.7,
                  top: 8,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Result indicator
                Positioned(
                  left: position * (MediaQuery.of(context).size.width * 0.7 - 16),
                  child: Container(
                    width: 16,
                    height: 24,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                low.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                'Normal Range',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                high.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildTrendIndicator(List<MedicalRecord> history, bool isDark) {
    // Sort by date
    history.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    
    if (history.length < 2) return const SizedBox.shrink();
    
    // Get the last two results
    final latest = history.last;
    final previous = history[history.length - 2];
    
    double? latestValue;
    double? previousValue;
    
    try {
      if (latest.dataJson != null) {
        final data = jsonDecode(latest.dataJson!) as Map<String, dynamic>;
        latestValue = double.tryParse((data['result'] as String? ?? '').replaceAll(RegExp(r'[^\d.]'), ''));
      }
      if (previous.dataJson != null) {
        final data = jsonDecode(previous.dataJson!) as Map<String, dynamic>;
        previousValue = double.tryParse((data['result'] as String? ?? '').replaceAll(RegExp(r'[^\d.]'), ''));
      }
    } catch (_) {}
    
    if (latestValue == null || previousValue == null) return const SizedBox.shrink();
    
    final diff = latestValue - previousValue;
    final percentChange = previousValue != 0 ? (diff / previousValue * 100).abs() : 0.0;
    
    IconData trendIcon;
    Color trendColor;
    String trendText;
    
    if (diff > 0) {
      trendIcon = Icons.trending_up;
      trendColor = AppColors.error;
      trendText = '+${percentChange.toStringAsFixed(1)}% from last';
    } else if (diff < 0) {
      trendIcon = Icons.trending_down;
      trendColor = AppColors.success;
      trendText = '-${percentChange.toStringAsFixed(1)}% from last';
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = AppColors.info;
      trendText = 'No change from last';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 16, color: trendColor),
          const SizedBox(width: 4),
          Text(
            trendText,
            style: TextStyle(
              fontSize: 12,
              color: trendColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${history.length} tests)',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDetails(MedicalRecord record, Map<String, dynamic> data, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    // Title
                    Text(
                      data['test_name'] as String? ?? 'Lab Test',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM dd, yyyy').format(record.recordDate),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Result
                    _buildDetailRow('Result', '${data['result'] ?? 'N/A'} ${data['units'] ?? ''}', isDark),
                    _buildDetailRow('Reference Range', data['reference_range'] as String? ?? 'N/A', isDark),
                    _buildDetailRow('Status', data['result_status'] as String? ?? 'Normal', isDark),
                    
                    if (data['test_category'] != null)
                      _buildDetailRow('Category', data['test_category'] as String, isDark),
                    if (data['specimen'] != null && (data['specimen'] as String).isNotEmpty)
                      _buildDetailRow('Specimen', data['specimen'] as String, isDark),
                    if (data['lab_name'] != null && (data['lab_name'] as String).isNotEmpty)
                      _buildDetailRow('Laboratory', data['lab_name'] as String, isDark),
                    if (data['ordering_physician'] != null && (data['ordering_physician'] as String).isNotEmpty)
                      _buildDetailRow('Ordering Physician', data['ordering_physician'] as String, isDark),
                    
                    if (data['interpretation'] != null && (data['interpretation'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Interpretation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(data['interpretation'] as String),
                      ),
                    ],
                    
                    if (record.doctorNotes != null && record.doctorNotes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Clinical Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(record.doctorNotes!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

