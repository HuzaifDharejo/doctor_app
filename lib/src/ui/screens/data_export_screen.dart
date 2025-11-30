import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/data_export_service.dart';
import '../widgets/report_widgets.dart';

/// Data Export & Reporting Screen
/// Comprehensive interface for exporting data in multiple formats with flexible filtering
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  String _selectedReportType = 'patients';
  String _selectedFormat = 'pdf';
  late DateTime _dateFrom;
  late DateTime _dateTo;
  bool _includeArchived = false;
  bool _includeInactive = false;
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _dateTo = DateTime.now();
    _dateFrom = _dateTo.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export & Reporting'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selector
              ReportTypeSelector(
                selectedReportType: _selectedReportType,
                onReportTypeChanged: (newType) {
                  setState(() {
                    _selectedReportType = newType;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date Range Selector
              DateRangeSelector(
                fromDate: _dateFrom,
                toDate: _dateTo,
                onDateRangeChanged: (range) {
                  setState(() {
                    _dateFrom = range.start;
                    _dateTo = range.end;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Export Format Selector
              ExportFormatSelector(
                selectedFormat: _selectedFormat,
                onFormatChanged: (newFormat) {
                  setState(() {
                    _selectedFormat = newFormat;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Filter Panel
              ExportFilterPanel(
                includeArchived: _includeArchived,
                includeInactive: _includeInactive,
                selectedStatuses: _selectedStatuses,
                onFiltersChanged: (filters) {
                  setState(() {
                    _includeArchived = filters['includeArchived'] as bool;
                    _includeInactive = filters['includeInactive'] as bool;
                    _selectedStatuses = List<String>.from(filters['selectedStatuses'] as List);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Export Summary
              ExportSummary(
                reportType: _selectedReportType,
                format: _selectedFormat,
                recordCount: _estimateRecordCount(),
                dateFrom: _dateFrom,
                dateTo: _dateTo,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleExport,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _handlePreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Information Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Data Export',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        'PDF Format',
                        'Best for printing and sharing formatted reports with professional layout',
                      ),
                      _buildInfoItem(
                        'CSV Format',
                        'Ideal for importing data into spreadsheet applications like Excel',
                      ),
                      _buildInfoItem(
                        'JSON Format',
                        'Perfect for data integration and programmatic access',
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle export action
  void _handleExport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportProgressDialog(
        reportType: _selectedReportType,
        format: _selectedFormat,
        onExportComplete: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      '$_selectedReportType report exported successfully!',
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Handle preview action
  void _handlePreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewRow('Report Type:', _selectedReportType),
              _buildPreviewRow('Format:', _selectedFormat.toUpperCase()),
              _buildPreviewRow('Date From:', _formatDate(_dateFrom)),
              _buildPreviewRow('Date To:', _formatDate(_dateTo)),
              _buildPreviewRow('Include Archived:', _includeArchived ? 'Yes' : 'No'),
              _buildPreviewRow('Include Inactive:', _includeInactive ? 'Yes' : 'No'),
              if (_selectedStatuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selected Statuses:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Wrap(
                  spacing: 4,
                  children: _selectedStatuses
                      .map((status) => Chip(label: Text(status)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleExport();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  /// Build info item
  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build security note
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data is exported securely. Ensure exported files are stored safely.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Build preview row
  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Estimate record count based on report type
  int _estimateRecordCount() {
    switch (_selectedReportType) {
      case 'patients':
        return 150;
      case 'appointments':
        return 280;
      case 'billing':
        return 95;
      case 'prescriptions':
        return 420;
      case 'analytics':
        return 1;
      default:
        return 0;
    }
  }
}
