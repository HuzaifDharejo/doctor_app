import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

// ============================================================================
// Export Format Selector Widget
// ============================================================================

class ExportFormatSelector extends StatefulWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;

  const ExportFormatSelector({
    Key? key,
    required this.selectedFormat,
    required this.onFormatChanged,
  }) : super(key: key);

  @override
  State<ExportFormatSelector> createState() => _ExportFormatSelectorState();
}

class _ExportFormatSelectorState extends State<ExportFormatSelector> {
  late String _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.selectedFormat;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFormatChip('PDF', 'pdf', Icons.picture_as_pdf, Colors.red),
                _buildFormatChip('CSV', 'csv', Icons.table_chart, Colors.green),
                _buildFormatChip('JSON', 'json', Icons.code, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedFormat == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFormat = value;
          });
          widget.onFormatChanged(value);
        }
      },
      backgroundColor: Colors.transparent,
      selectedColor: color.withValues(alpha: 0.3),
    );
  }
}

// ============================================================================
// Report Type Selector Widget
// ============================================================================

class ReportTypeSelector extends StatefulWidget {
  final String selectedReportType;
  final ValueChanged<String> onReportTypeChanged;

  const ReportTypeSelector({
    Key? key,
    required this.selectedReportType,
    required this.onReportTypeChanged,
  }) : super(key: key);

  @override
  State<ReportTypeSelector> createState() => _ReportTypeSelectorState();
}

class _ReportTypeSelectorState extends State<ReportTypeSelector> {
  late String _selectedReportType;

  @override
  void initState() {
    super.initState();
    _selectedReportType = widget.selectedReportType;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReportOption('Patients', 'patients', Icons.people),
                _buildReportOption('Appointments', 'appointments', Icons.calendar_today),
                _buildReportOption('Billing', 'billing', Icons.receipt),
                _buildReportOption('Prescriptions', 'prescriptions', Icons.medication),
                _buildReportOption('Analytics', 'analytics', Icons.analytics),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String label, String value, IconData icon) {
    final isSelected = _selectedReportType == value;

    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      value: value,
      groupValue: _selectedReportType,
      // ignore: deprecated_member_use
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedReportType = newValue;
          });
          widget.onReportTypeChanged(newValue);
        }
      },
    );
  }
}

// ============================================================================
// Date Range Selector Widget
// ============================================================================

class DateRangeSelector extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTimeRange> onDateRangeChanged;

  const DateRangeSelector({
    Key? key,
    this.fromDate,
    this.toDate,
    required this.onDateRangeChanged,
  }) : super(key: key);

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _toDate = widget.toDate ?? DateTime.now();
    _fromDate = widget.fromDate ?? _toDate.subtract(const Duration(days: 30));
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      widget.onDateRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        _formatDate(_fromDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[500]),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        _formatDate(_toDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Change Date Range'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// Filter Panel Widget
// ============================================================================

class ExportFilterPanel extends StatefulWidget {
  final bool includeArchived;
  final bool includeInactive;
  final List<String> selectedStatuses;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;

  const ExportFilterPanel({
    Key? key,
    this.includeArchived = false,
    this.includeInactive = false,
    this.selectedStatuses = const [],
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<ExportFilterPanel> createState() => _ExportFilterPanelState();
}

class _ExportFilterPanelState extends State<ExportFilterPanel> {
  late bool _includeArchived;
  late bool _includeInactive;
  late List<String> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _includeArchived = widget.includeArchived;
    _includeInactive = widget.includeInactive;
    _selectedStatuses = List.from(widget.selectedStatuses);
  }

  void _updateFilters() {
    widget.onFiltersChanged({
      'includeArchived': _includeArchived,
      'includeInactive': _includeInactive,
      'selectedStatuses': _selectedStatuses,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Include Archived Records'),
              value: _includeArchived,
              onChanged: (value) {
                setState(() {
                  _includeArchived = value ?? false;
                });
                _updateFilters();
              },
            ),
            CheckboxListTile(
              title: const Text('Include Inactive Items'),
              value: _includeInactive,
              onChanged: (value) {
                setState(() {
                  _includeInactive = value ?? false;
                });
                _updateFilters();
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Status Filters',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Pending', 'Completed', 'Cancelled', 'In Progress']
                  .map((status) {
                return FilterChip(
                  label: Text(status),
                  selected: _selectedStatuses.contains(status),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedStatuses.add(status);
                      } else {
                        _selectedStatuses.remove(status);
                      }
                    });
                    _updateFilters();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Export Summary Widget
// ============================================================================

class ExportSummary extends StatelessWidget {
  final String reportType;
  final String format;
  final int recordCount;
  final DateTime dateFrom;
  final DateTime dateTo;

  const ExportSummary({
    Key? key,
    required this.reportType,
    required this.format,
    required this.recordCount,
    required this.dateFrom,
    required this.dateTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Report Type:', _capitalize(reportType)),
            _buildSummaryRow('Format:', format.toUpperCase()),
            _buildSummaryRow('Records:', recordCount.toString()),
            _buildSummaryRow(
              'Date Range:',
              '${_formatDate(dateFrom)} to ${_formatDate(dateTo)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _capitalize(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ============================================================================
// Export Progress Widget
// ============================================================================

class ExportProgressDialog extends StatefulWidget {
  final String reportType;
  final String format;
  final VoidCallback onExportComplete;

  const ExportProgressDialog({
    Key? key,
    required this.reportType,
    required this.format,
    required this.onExportComplete,
  }) : super(key: key);

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  late Future<void> _exportFuture;

  @override
  void initState() {
    super.initState();
    _exportFuture = Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onExportComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exporting ${widget.reportType}...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Format: ${widget.format.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while your report is being prepared...',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


