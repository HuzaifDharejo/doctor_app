import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/logger_service.dart';

/// Debug Log Viewer Screen - View and filter app logs in real-time
class DebugLogViewerScreen extends ConsumerStatefulWidget {
  const DebugLogViewerScreen({super.key});

  @override
  ConsumerState<DebugLogViewerScreen> createState() => _DebugLogViewerScreenState();
}

class _DebugLogViewerScreenState extends ConsumerState<DebugLogViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StreamSubscription<LogEntry> _logSubscription;
  
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  List<LogEntry> _filteredLogs = [];
  LogLevel? _selectedLevel;
  String? _selectedTag;
  bool _autoScroll = true;
  bool _showTimestamp = true;
  bool _showExtras = false;
  
  // Available tags from logs
  Set<String> _availableTags = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateFilteredLogs();
    _updateAvailableTags();
    
    // Subscribe to real-time log updates
    _logSubscription = log.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _updateFilteredLogs();
          _updateAvailableTags();
        });
        if (_autoScroll && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
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
    _searchController.dispose();
    super.dispose();
  }
  
  void _updateFilteredLogs() {
    _filteredLogs = log.filterLogs(
      level: _selectedLevel,
      tag: _selectedTag,
      contains: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }
  
  void _updateAvailableTags() {
    _availableTags = log.logs.map((l) => l.tag).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = log.getSummary();
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Auto-scroll toggle
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll OFF',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          // Settings menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'timestamp':
                  setState(() => _showTimestamp = !_showTimestamp);
                  break;
                case 'extras':
                  setState(() => _showExtras = !_showExtras);
                  break;
                case 'copy':
                  _copyLogsToClipboard();
                  break;
                case 'export':
                  _exportLogs();
                  break;
                case 'clear':
                  _clearLogs();
                  break;
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'timestamp',
                checked: _showTimestamp,
                child: const Text('Show Timestamps'),
              ),
              CheckedPopupMenuItem(
                value: 'extras',
                checked: _showExtras,
                child: const Text('Show Extra Data'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Clear Logs', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.list_alt, size: 20),
              text: 'Logs (${_filteredLogs.length})',
            ),
            Tab(
              icon: Badge(
                label: Text('${summary['errors']}'),
                isLabelVisible: (summary['errors'] as int) > 0,
                backgroundColor: Colors.red,
                child: const Icon(Icons.error_outline, size: 20),
              ),
              text: 'Errors',
            ),
            Tab(
              icon: const Icon(Icons.speed, size: 20),
              text: 'Perf (${summary['metricsCount']})',
            ),
            Tab(
              icon: const Icon(Icons.analytics_outlined, size: 20),
              text: 'Events',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(isDark, summary),
          // Filter bar
          _buildFilterBar(isDark),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogsTab(isDark),
                _buildErrorsTab(isDark),
                _buildPerformanceTab(isDark),
                _buildEventsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsBar(bool isDark, Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.indigo.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.indigo.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.article_outlined,
            label: 'Total',
            value: '${summary['totalLogs']}',
            color: Colors.blue,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.error_outline,
            label: 'Errors',
            value: '${summary['errors']}',
            color: Colors.red,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Icons.warning_amber_rounded,
            label: 'Warnings',
            value: '${summary['warnings']}',
            color: Colors.orange,
            isDark: isDark,
          ),
          const Spacer(),
          if (summary['lastError'] != null)
            Text(
              'Last error: ${_formatTime(DateTime.parse(summary['lastError'] as String))}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _updateFilteredLogs());
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() => _updateFilteredLogs());
              },
            ),
          ),
          const SizedBox(width: 8),
          // Level filter
          _buildDropdown<LogLevel?>(
            value: _selectedLevel,
            hint: 'Level',
            items: [
              const DropdownMenuItem(value: null, child: Text('All Levels')),
              ...LogLevel.values.map((l) => DropdownMenuItem(
                value: l,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getLevelColor(l),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(l.name.toUpperCase()),
                  ],
                ),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLevel = value;
                _updateFilteredLogs();
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Tag filter
          _buildDropdown<String?>(
            value: _selectedTag,
            hint: 'Tag',
            items: [
              const DropdownMenuItem(value: null, child: Text('All Tags')),
              ..._availableTags.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTag = value;
                _updateFilteredLogs();
              });
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
        items: items,
        onChanged: onChanged,
        underline: const SizedBox(),
        isDense: true,
        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
        dropdownColor: isDark ? const Color(0xFF2A2A3E) : Colors.white,
      ),
    );
  }
  
  Widget _buildLogsTab(bool isDark) {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No logs found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (_searchController.text.isNotEmpty || _selectedLevel != null || _selectedTag != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedLevel = null;
                    _selectedTag = null;
                    _updateFilteredLogs();
                  });
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final entry = _filteredLogs[index];
        return _buildLogEntry(entry, isDark);
      },
    );
  }
  
  Widget _buildLogEntry(LogEntry entry, bool isDark) {
    final levelColor = _getLevelColor(entry.level);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: entry.level == LogLevel.error || entry.level == LogLevel.fatal
              ? Colors.red.withValues(alpha: 0.3)
              : isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(entry),
        onLongPress: () => _copyLogEntry(entry),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Level indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.level.prefix,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Timestamp
                  if (_showTimestamp)
                    Text(
                      _formatTimestamp(entry.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Message
              Text(
                entry.message,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'monospace',
                ),
              ),
              // Error
              if (entry.error != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.error.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              // Extra data
              if (_showExtras && entry.extra != null && entry.extra!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.extra.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontFamily: 'monospace',
                    ),
                  ),
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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              'No errors! 🎉',
              style: TextStyle(fontSize: 18, color: Colors.green.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your app is running smoothly',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    // Group errors by tag
    final errorsByTag = <String, List<LogEntry>>{};
    for (final error in errors) {
      errorsByTag.putIfAbsent(error.tag, () => []).add(error);
    }
    
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary card
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${errors.length} Errors Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: errorsByTag.entries.map((e) => Chip(
                    label: Text('${e.key}: ${e.value.length}'),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Error list
        ...errors.reversed.map((e) => _buildLogEntry(e, isDark)),
      ],
    );
  }
  
  Widget _buildPerformanceTab(bool isDark) {
    final metrics = log.metrics;
    
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No performance metrics',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    // Calculate averages by name
    final metricsByName = <String, List<PerformanceMetric>>{};
    for (final metric in metrics) {
      metricsByName.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Averages card
        Card(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...metricsByName.entries.map((e) {
                  final avgMs = e.value
                      .where((m) => m.duration != null)
                      .map((m) => m.duration!.inMilliseconds)
                      .fold<int>(0, (a, b) => a + b) ~/
                      e.value.where((m) => m.duration != null).length;
                  final color = avgMs < 100 ? Colors.green : avgMs < 500 ? Colors.orange : Colors.red;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
                        Text(
                          '${avgMs}ms avg',
                          style: TextStyle(fontWeight: FontWeight.w600, color: color),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${e.value.length}x)',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Recent metrics
        Text(
          'Recent Metrics',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        ...metrics.reversed.take(50).map((m) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.timer_outlined,
              color: m.duration != null && m.duration!.inMilliseconds < 100
                  ? Colors.green
                  : m.duration != null && m.duration!.inMilliseconds < 500
                      ? Colors.orange
                      : Colors.red,
            ),
            title: Text(m.name),
            subtitle: Text(_formatTimestamp(m.startTime)),
            trailing: Text(
              m.duration != null ? '${m.duration!.inMilliseconds}ms' : 'Running...',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildEventsTab(bool isDark) {
    final events = log.events;
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No analytics events',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    // Group by event name
    final eventsByName = <String, int>{};
    for (final event in events) {
      eventsByName[event.name] = (eventsByName[event.name] ?? 0) + 1;
    }
    
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Event counts
        Card(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: eventsByName.entries.map((e) => Chip(
                    label: Text('${e.key}: ${e.value}'),
                    backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade100,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Recent events
        ...events.reversed.take(100).map((e) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.touch_app, color: Colors.purple),
            title: Text(e.name),
            subtitle: Text(e.screen ?? 'No screen'),
            trailing: Text(
              _formatTimestamp(e.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        )),
      ],
    );
  }
  
  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }
  
  String _formatTimestamp(DateTime dt) {
    return DateFormat('HH:mm:ss.SSS').format(dt);
  }
  
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('HH:mm:ss').format(dt);
    }
    return DateFormat('MMM d, HH:mm').format(dt);
  }
  
  void _showLogDetails(LogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogDetailsSheet(entry: entry),
    );
  }
  
  void _copyLogEntry(LogEntry entry) {
    final text = '[${entry.level.prefix}] ${entry.timestamp.toIso8601String()} [${entry.tag}] ${entry.message}'
        '${entry.error != null ? '\nError: ${entry.error}' : ''}'
        '${entry.stackTrace != null ? '\nStack: ${entry.stackTrace}' : ''}'
        '${entry.extra != null ? '\nExtra: ${entry.extra}' : ''}';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log entry copied'), duration: Duration(seconds: 1)),
    );
  }
  
  void _copyLogsToClipboard() {
    final text = _filteredLogs.map((e) => e.toFormattedString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_filteredLogs.length} logs copied'), duration: const Duration(seconds: 1)),
    );
  }
  
  void _exportLogs() {
    final json = log.exportLogsAsJson();
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs exported to clipboard as JSON')),
    );
  }
  
  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('This will delete all logs, performance metrics, and analytics events.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              log.clear();
              setState(() => _updateFilteredLogs());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Log details bottom sheet
class _LogDetailsSheet extends StatelessWidget {
  final LogEntry entry;
  
  const _LogDetailsSheet({required this.entry});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getLevelColor(entry.level).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.level.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getLevelColor(entry.level),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(entry.tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Timestamp
                  _buildDetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(entry.timestamp), isDark),
                  const SizedBox(height: 12),
                  // Message
                  _buildDetailRow('Message', entry.message, isDark),
                  // Error
                  if (entry.error != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Error', entry.error.toString(), isDark, isError: true),
                  ],
                  // Stack trace
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Stack Trace', entry.stackTrace.toString(), isDark, isCode: true),
                  ],
                  // Extra
                  if (entry.extra != null && entry.extra!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Extra Data', entry.extra.toString(), isDark, isCode: true),
                  ],
                  const SizedBox(height: 20),
                  // Copy button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final text = entry.toFormattedString();
                        Clipboard.setData(ClipboardData(text: text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Log Entry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, bool isDark, {bool isError = false, bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.withValues(alpha: 0.1)
                : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: isError ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
          ),
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: isCode ? 11 : 13,
              fontFamily: isCode ? 'monospace' : null,
              color: isError ? Colors.red.shade700 : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose: return Colors.grey;
      case LogLevel.debug: return Colors.cyan;
      case LogLevel.info: return Colors.green;
      case LogLevel.warning: return Colors.orange;
      case LogLevel.error: return Colors.red;
      case LogLevel.fatal: return Colors.purple;
    }
  }
}
