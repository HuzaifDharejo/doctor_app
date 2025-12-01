import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/audit_logging_service.dart';

/// Audit Log Viewer Screen - View all system audit logs for HIPAA compliance
class AuditLogViewerScreen extends ConsumerStatefulWidget {
  final int? patientId;
  final String? patientName;
  final String? doctorName;

  const AuditLogViewerScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.doctorName,
  });

  @override
  ConsumerState<AuditLogViewerScreen> createState() => _AuditLogViewerScreenState();
}

class _AuditLogViewerScreenState extends ConsumerState<AuditLogViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<AuditLog> _logs = [];
  String _filterAction = 'ALL';
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    try {
      final dbAsync = ref.read(doctorDbProvider);
      dbAsync.whenData((db) async {
        List<AuditLog> logs;

        if (widget.patientId != null) {
          logs = await db.getAuditLogsForPatient(widget.patientId!, limit: 500);
        } else if (widget.doctorName != null) {
          logs = await db.getAuditLogsByDoctor(widget.doctorName!, limit: 500);
        } else {
          logs = await db.getRecentAuditLogs(days: 30, limit: 500);
        }

        if (mounted) {
          setState(() {
            _logs = logs;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  List<AuditLog> get _filteredLogs {
    var filtered = _logs;

    if (_filterAction != 'ALL') {
      filtered = filtered.where((log) => log.action == _filterAction).toList();
    }

    filtered = filtered
        .where((log) => log.createdAt.isAfter(_dateRange.start) && log.createdAt.isBefore(_dateRange.end.add(const Duration(days: 1))))
        .toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = widget.patientId != null
        ? 'Patient Audit Log - ${widget.patientName}'
        : widget.doctorName != null
            ? 'Doctor Audit Log - ${widget.doctorName}'
            : 'System Audit Log';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All Logs'),
            Tab(icon: Icon(Icons.warning), text: 'Failed Access'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLogsTab(isDark),
                _buildFailedAccessTab(isDark),
                _buildStatisticsTab(isDark),
              ],
            ),
    );
  }

  Widget _buildLogsTab(bool isDark) {
    return Column(
      children: [
        // Filter controls
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            spacing: 12,
            children: [
              // Date range picker
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(
                  '${DateFormat('MMM dd').format(_dateRange.start)} - ${DateFormat('MMM dd').format(_dateRange.end)}',
                ),
                onTap: () async {
                  final newRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    currentDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (newRange != null) {
                    setState(() => _dateRange = newRange);
                  }
                },
              ),
              // Action filter
              DropdownButton<String>(
                isExpanded: true,
                value: _filterAction,
                items: [
                  const DropdownMenuItem(value: 'ALL', child: Text('All Actions')),
                  ...{'LOGIN', 'LOGOUT', 'VIEW_PATIENT', 'CREATE_PATIENT', 'UPDATE_PATIENT', 'VIEW_VITAL_SIGNS', 'VIEW_PRESCRIPTIONS', 'EXPORT_DATA', 'ACCESS_DENIED'}.map(
                    (action) => DropdownMenuItem(
                      value: action,
                      child: Text(action.replaceAll('_', ' ')),
                    ),
                  ),
                ].toList(),
                onChanged: (value) {
                  setState(() => _filterAction = value ?? 'ALL');
                },
              ),
            ],
          ),
        ),
        // Logs list
        Expanded(
          child: _filteredLogs.isEmpty
              ? Center(
                  child: Text(
                    'No audit logs found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) => _buildAuditLogCard(
                    _filteredLogs[index],
                    isDark,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAuditLogCard(AuditLog log, bool isDark) {
    final time = DateFormat('MMM dd, HH:mm:ss').format(log.createdAt);
    final actionColor = _getActionColor(log.action);
    final resultColor = log.result == 'SUCCESS' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.action.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: actionColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: resultColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.result,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: resultColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        log.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (log.patientName.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    log.patientName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            if (log.actionDetails.isNotEmpty)
              ExpansionTile(
                title: const Text('Details', style: TextStyle(fontSize: 12)),
                childrenPadding: const EdgeInsets.only(left: 16),
                children: [
                  SelectableText(
                    log.actionDetails,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            if (log.notes.isNotEmpty)
              Text(
                'Notes: ${log.notes}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedAccessTab(bool isDark) {
    final failedLogs = _filteredLogs.where((log) => log.result != 'SUCCESS').toList();

    return failedLogs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                Text(
                  'No failed access attempts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (widget.patientId == null && widget.doctorName == null)
                  Text(
                    'System is operating normally',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: failedLogs.length,
            itemBuilder: (context, index) => _buildAuditLogCard(failedLogs[index], isDark),
          );
  }

  Widget _buildStatisticsTab(bool isDark) {
    final stats = _calculateStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard('Total Actions', stats['total'].toString(), Colors.blue, isDark),
              _buildStatCard('Logins', stats['logins'].toString(), Colors.green, isDark),
              _buildStatCard('Logouts', stats['logouts'].toString(), Colors.green, isDark),
              _buildStatCard('Data Access', stats['dataAccess'].toString(), Colors.orange, isDark),
              _buildStatCard('Modifications', stats['modifications'].toString(), Colors.purple, isDark),
              _buildStatCard('Failed Attempts', stats['failed'].toString(), Colors.red, isDark),
            ],
          ),
          // Action breakdown
          const SizedBox(height: 16),
          Text(
            'Actions by Type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          ..._buildActionBreakdown(isDark),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    final filtered = _filteredLogs;
    return {
      'total': filtered.length,
      'logins': filtered.where((l) => l.action == 'LOGIN').length,
      'logouts': filtered.where((l) => l.action == 'LOGOUT').length,
      'dataAccess': filtered.where((l) => l.action.contains('VIEW')).length,
      'modifications': filtered.where((l) => l.action.contains('CREATE') || l.action.contains('UPDATE') || l.action.contains('DELETE')).length,
      'failed': filtered.where((l) => l.result != 'SUCCESS').length,
    };
  }

  List<Widget> _buildActionBreakdown(bool isDark) {
    final actionMap = <String, int>{};
    for (final log in _filteredLogs) {
      actionMap[log.action] = (actionMap[log.action] ?? 0) + 1;
    }

    return actionMap.entries.map((e) {
      final percentage = _filteredLogs.isEmpty ? 0 : (e.value / _filteredLogs.length * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                e.key.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _filteredLogs.isEmpty ? 0 : e.value / _filteredLogs.length,
                  minHeight: 8,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${e.value} ($percentage%)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.analytics, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('LOGIN') || action.contains('LOGOUT')) return Colors.blue;
    if (action.contains('VIEW') || action.contains('ACCESS')) return Colors.orange;
    if (action.contains('CREATE') || action.contains('UPDATE') || action.contains('DELETE')) return Colors.purple;
    if (action.contains('EXPORT')) return Colors.green;
    if (action.contains('DENIED') || action.contains('FAILED')) return Colors.red;
    return Colors.grey;
  }
}

