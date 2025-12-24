import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/logger_service.dart';
import '../../core/components/app_input.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Debug console widget for viewing logs in-app
/// Only visible in debug mode
class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<LogEntry> _logSubscription;
  final ScrollController _scrollController = ScrollController();
  
  LogLevel? _filterLevel;
  String _searchQuery = '';
  bool _autoScroll = true;
  bool _showErrors = true;
  bool _showWarnings = true;
  bool _showInfo = true;
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _logSubscription = log.logStream.listen((_) {
      if (mounted) {
        setState(() {});
        if (_autoScroll && _scrollController.hasClients && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<LogEntry> get _filteredLogs {
    return log.logs.where((entry) {
      // Level filter
      if (!_showErrors && (entry.level == LogLevel.error || entry.level == LogLevel.fatal)) return false;
      if (!_showWarnings && entry.level == LogLevel.warning) return false;
      if (!_showInfo && entry.level == LogLevel.info) return false;
      if (!_showDebug && (entry.level == LogLevel.debug || entry.level == LogLevel.verbose)) return false;
      
      // Specific level filter
      if (_filterLevel != null && entry.level != _filterLevel) return false;
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return entry.message.toLowerCase().contains(query) ||
               entry.tag.toLowerCase().contains(query) ||
               (entry.error?.toString().toLowerCase().contains(query) ?? false);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Debug Console'),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy all logs',
            onPressed: _copyLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              log.clear();
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Logs'),
            Tab(text: 'Errors'),
            Tab(text: 'Performance'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogsTab(isDark),
                _buildErrorsTab(isDark),
                _buildPerformanceTab(isDark),
                _buildStatsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      child: Column(
        children: [
          AppInput(
            hint: 'Search logs...',
            prefixIcon: Icons.search,
            suffixIcon: _searchQuery.isNotEmpty ? Icons.clear : null,
            onSuffixIconPressed: () => setState(() => _searchQuery = ''),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Errors', _showErrors, LogLevel.error, isDark, (v) => setState(() => _showErrors = v)),
                const SizedBox(width: 6),
                _buildFilterChip('Warnings', _showWarnings, LogLevel.warning, isDark, (v) => setState(() => _showWarnings = v)),
                const SizedBox(width: 6),
                _buildFilterChip('Info', _showInfo, LogLevel.info, isDark, (v) => setState(() => _showInfo = v)),
                const SizedBox(width: 6),
                _buildFilterChip('Debug', _showDebug, LogLevel.debug, isDark, (v) => setState(() => _showDebug = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, LogLevel level, bool isDark, ValueChanged<bool> onChanged) {
    final color = _getLevelColor(level);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
      selected: selected,
      onSelected: onChanged,
      selectedColor: color,
      backgroundColor: isDark ? const Color(0xFF3D3D3D) : Colors.grey[300],
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLogsTab(bool isDark) {
    final logs = _filteredLogs;
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No logs to display', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemBuilder: (context, index) {
        final entry = logs[index];
        return _buildLogEntry(entry, isDark);
      },
    );
  }

  Widget _buildLogEntry(LogEntry entry, bool isDark) {
    final color = _getLevelColor(entry.level);
    final timeStr = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: entry.level.priority >= LogLevel.error.priority
              ? color.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(entry),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.level.prefix,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.tag,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (entry.error != null)
                    Icon(Icons.error_outline, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
              if (entry.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.error.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorsTab(bool isDark) {
    final errors = log.errors;
    
    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text('No errors! 🎉', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: errors.length,
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemBuilder: (context, index) {
        return _buildLogEntry(errors[errors.length - 1 - index], isDark);
      },
    );
  }

  Widget _buildPerformanceTab(bool isDark) {
    final metrics = log.metrics;
    
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No performance metrics yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: metrics.length,
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemBuilder: (context, index) {
        final metric = metrics[metrics.length - 1 - index];
        final durationMs = metric.duration?.inMilliseconds ?? 0;
        final color = durationMs > 1000 ? AppColors.error : (durationMs > 500 ? AppColors.warning : AppColors.success);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${durationMs}ms',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${metric.startTime.hour}:${metric.startTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(bool isDark) {
    final summary = log.getSummary();
    final errorsByTag = log.errorsByTag;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Overview', [
            _buildStatRow('Total Logs', '${summary['totalLogs']}', isDark),
            _buildStatRow('Errors', '${summary['errors']}', isDark, color: AppColors.error),
            _buildStatRow('Warnings', '${summary['warnings']}', isDark, color: AppColors.warning),
            _buildStatRow('Performance Metrics', '${summary['metricsCount']}', isDark),
            _buildStatRow('Analytics Events', '${summary['eventsCount']}', isDark),
          ], isDark,),
          const SizedBox(height: 16),
          if (errorsByTag.isNotEmpty) ...[
            _buildStatCard('Errors by Tag', 
              errorsByTag.entries.map((e) => 
                _buildStatRow(e.key, '${e.value}', isDark, color: AppColors.error),
              ).toList(),
            isDark,),
            const SizedBox(height: 16),
          ],
          if (summary['lastError'] != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last Error', style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                        Text((summary['lastError'] as String?) ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.info:
        return AppColors.success;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  void _showLogDetails(LogEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogDetailsSheet(entry: entry),
    );
  }

  void _copyLogs() {
    final text = log.exportLogsAsJson();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }
}

class _LogDetailsSheet extends StatelessWidget {

  const _LogDetailsSheet({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Log Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.toFormattedString()));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Timestamp', entry.timestamp.toString(), isDark),
                  _buildDetailRow('Level', entry.level.name.toUpperCase(), isDark),
                  _buildDetailRow('Tag', entry.tag, isDark),
                  _buildDetailRow('Message', entry.message, isDark),
                  if (entry.error != null)
                    _buildDetailRow('Error', entry.error.toString(), isDark),
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    Text('Stack Trace', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.stackTrace.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                  if (entry.extra != null) ...[
                    const SizedBox(height: 12),
                    Text('Extra Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(entry.extra),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}

/// Floating debug button that shows when in debug mode
class DebugButton extends StatelessWidget {
  const DebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton.small(
        heroTag: 'debug_console',
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const DebugConsole()),
          );
        },
        child: const Icon(Icons.bug_report, color: Colors.white, size: 20),
      ),
    );
  }
}

