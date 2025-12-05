import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../db/doctor_db.dart';
import '../../providers/audit_provider.dart';
import '../../services/audit_service.dart';

/// Screen to view audit logs for HIPAA compliance
class AuditLogViewerScreen extends ConsumerStatefulWidget {
  const AuditLogViewerScreen({super.key});

  @override
  ConsumerState<AuditLogViewerScreen> createState() => _AuditLogViewerScreenState();
}

class _AuditLogViewerScreenState extends ConsumerState<AuditLogViewerScreen> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String _filterAction = 'ALL';
  int _filterDays = 7;
  
  final List<String> _actionFilters = [
    'ALL',
    'LOGIN',
    'VIEW_PATIENT',
    'CREATE_PATIENT',
    'UPDATE_PATIENT',
    'CREATE_VITAL_SIGN',
    'CREATE_APPOINTMENT',
    'CREATE_PRESCRIPTION',
    'EXPORT_DATA',
  ];
  
  final List<int> _dayFilters = [1, 7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final auditService = ref.read(auditServiceProvider);
      List<AuditLog> logs;
      
      if (_filterAction == 'ALL') {
        logs = await auditService.getRecentLogs(days: _filterDays, limit: 500);
      } else {
        final action = AuditAction.values.firstWhere(
          (a) => a.value == _filterAction,
          orElse: () => AuditAction.viewPatient,
        );
        logs = await auditService.getLogsByAction(action, limit: 500);
        // Filter by days
        final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
        logs = logs.where((log) => log.createdAt.isAfter(cutoff)).toList();
      }
      
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit logs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                // Action filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterAction,
                    decoration: InputDecoration(
                      labelText: 'Action',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    items: _actionFilters.map((action) {
                      return DropdownMenuItem(
                        value: action,
                        child: Text(
                          action.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: AppFontSize.sm),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterAction = value);
                        _loadLogs();
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Days filter
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _filterDays,
                    decoration: InputDecoration(
                      labelText: 'Time Range',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    items: _dayFilters.map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text(
                          days == 1 ? 'Last 24 hours' : 'Last $days days',
                          style: const TextStyle(fontSize: AppFontSize.sm),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterDays = value);
                        _loadLogs();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${_logs.length} entries found',
                  style: TextStyle(
                    fontSize: AppFontSize.sm,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Log list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return _buildLogCard(_logs[index], theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: AppFontSize.lg,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Actions will be logged as you use the app',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final actionIcon = _getActionIcon(log.action);
    final actionColor = _getActionColor(log.action, theme);
    final resultColor = _getResultColor(log.result, theme);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  actionIcon,
                  size: 20,
                  color: actionColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.action.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: AppFontSize.md,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            log.result,
                            style: TextStyle(
                              fontSize: AppFontSize.xs,
                              fontWeight: FontWeight.w500,
                              color: resultColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'By ${log.doctorName}',
                      style: TextStyle(
                        fontSize: AppFontSize.sm,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (log.patientName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Patient: ${log.patientName}',
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dateFormat.format(log.createdAt),
                      style: TextStyle(
                        fontSize: AppFontSize.xs,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('LOGIN') || action.contains('LOGOUT')) {
      return Icons.login;
    }
    if (action.contains('LOCK') || action.contains('UNLOCK')) {
      return Icons.lock;
    }
    if (action.contains('PATIENT')) {
      return Icons.person;
    }
    if (action.contains('VITAL')) {
      return Icons.favorite;
    }
    if (action.contains('APPOINTMENT')) {
      return Icons.calendar_today;
    }
    if (action.contains('PRESCRIPTION')) {
      return Icons.medication;
    }
    if (action.contains('RECORD')) {
      return Icons.folder;
    }
    if (action.contains('INVOICE')) {
      return Icons.receipt;
    }
    if (action.contains('EXPORT') || action.contains('PDF')) {
      return Icons.file_download;
    }
    if (action.contains('SETTINGS')) {
      return Icons.settings;
    }
    return Icons.history;
  }

  Color _getActionColor(String action, ThemeData theme) {
    if (action.contains('CREATE')) {
      return Colors.green;
    }
    if (action.contains('UPDATE')) {
      return Colors.orange;
    }
    if (action.contains('DELETE')) {
      return Colors.red;
    }
    if (action.contains('VIEW') || action.contains('SEARCH')) {
      return Colors.blue;
    }
    if (action.contains('LOGIN') || action.contains('UNLOCK')) {
      return Colors.purple;
    }
    if (action.contains('LOGOUT') || action.contains('LOCK')) {
      return Colors.grey;
    }
    if (action.contains('EXPORT')) {
      return Colors.teal;
    }
    return theme.colorScheme.primary;
  }

  Color _getResultColor(String result, ThemeData theme) {
    switch (result) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILURE':
        return Colors.red;
      case 'DENIED':
        return Colors.orange;
      default:
        return theme.colorScheme.outline;
    }
  }

  void _showLogDetails(AuditLog log) {
    final dateFormat = DateFormat('EEEE, MMMM d, y • h:mm:ss a');
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    'Audit Log Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Details
                  _buildDetailRow('Action', log.action.replaceAll('_', ' '), theme),
                  _buildDetailRow('Result', log.result, theme),
                  _buildDetailRow('Doctor', log.doctorName, theme),
                  _buildDetailRow('Role', log.doctorRole, theme),
                  if (log.patientId != null)
                    _buildDetailRow('Patient ID', log.patientId.toString(), theme),
                  if (log.patientName.isNotEmpty)
                    _buildDetailRow('Patient Name', log.patientName, theme),
                  if (log.entityType.isNotEmpty)
                    _buildDetailRow('Entity Type', log.entityType, theme),
                  if (log.entityId != null)
                    _buildDetailRow('Entity ID', log.entityId.toString(), theme),
                  if (log.deviceInfo.isNotEmpty)
                    _buildDetailRow('Device', log.deviceInfo, theme),
                  _buildDetailRow('Timestamp', dateFormat.format(log.createdAt), theme),
                  if (log.notes.isNotEmpty)
                    _buildDetailRow('Notes', log.notes, theme),
                  if (log.actionDetails.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Action Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        log.actionDetails,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: AppFontSize.sm,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
