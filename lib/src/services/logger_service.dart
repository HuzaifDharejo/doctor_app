import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Log level enum for filtering logs
enum LogLevel {
  verbose(0, 'V', '\x1B[37m'),   // White
  debug(1, 'D', '\x1B[36m'),      // Cyan
  info(2, 'I', '\x1B[32m'),       // Green
  warning(3, 'W', '\x1B[33m'),    // Yellow
  error(4, 'E', '\x1B[31m'),      // Red
  fatal(5, 'F', '\x1B[35m');      // Magenta

  const LogLevel(this.priority, this.prefix, this.color);

  final int priority;
  final String prefix;
  final String color;
  
  /// Get emoji for log level
  String get emoji {
    switch (this) {
      case LogLevel.verbose: return '📝';
      case LogLevel.debug: return '🔍';
      case LogLevel.info: return '✅';
      case LogLevel.warning: return '⚠️';
      case LogLevel.error: return '❌';
      case LogLevel.fatal: return '💀';
    }
  }
}

/// A single log entry
class LogEntry {

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.extra,
    this.caller,
  });
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;
  final String? caller; // File:line info

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'tag': tag,
    'message': message,
    if (caller != null) 'caller': caller,
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    if (extra != null) 'extra': extra,
  };

  String toFormattedString() {
    final buffer = StringBuffer();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    
    // Format: [LEVEL] TIME [TAG] message (file:line)
    buffer.write('${level.color}[${level.prefix}] $timeStr [$tag] $message');
    if (caller != null) {
      buffer.write(' \x1B[90m($caller)\x1B[0m'); // Gray color for file:line
    }
    buffer.write('\x1B[0m');
    
    if (error != null) {
      buffer.write('\n    ${level.color}└─ Error: $error\x1B[0m');
    }
    if (stackTrace != null) {
      buffer.write('\n    └─ StackTrace:');
      final lines = stackTrace.toString().split('\n').take(5);
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          buffer.write('\n       $line');
        }
      }
    }
    
    return buffer.toString();
  }
}

/// Performance metrics tracker
class PerformanceMetric {

  PerformanceMetric({
    required this.name,
    required this.startTime,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> metadata;

  Duration? get duration => endTime?.difference(startTime);

  void stop() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationMs': duration?.inMilliseconds,
    'metadata': metadata,
  };
}

/// Analytics event for tracking user actions
class AnalyticsEvent {

  AnalyticsEvent({
    required this.timestamp,
    required this.name,
    this.screen,
    this.properties,
  });
  final DateTime timestamp;
  final String name;
  final String? screen;
  final Map<String, dynamic>? properties;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'name': name,
    if (screen != null) 'screen': screen,
    if (properties != null) 'properties': properties,
  };
}

/// Main Logger Service - Singleton
class AppLogger {
  factory AppLogger() => _instance;
  AppLogger._internal();
  static final AppLogger _instance = AppLogger._internal();

  // Configuration
  LogLevel _minLevel = kDebugMode ? LogLevel.verbose : LogLevel.warning;
  bool _enableConsoleOutput = kDebugMode;
  // ignore: unused_field
  bool _enableFileLogging = false;
  int _maxLogEntries = 1000;
  final int _maxPerformanceMetrics = 100;
  final int _maxAnalyticsEvents = 500;

  // Storage
  final List<LogEntry> _logs = [];
  final List<PerformanceMetric> _metrics = [];
  final List<AnalyticsEvent> _events = [];
  final Map<String, PerformanceMetric> _activeMetrics = {};

  // Stream for real-time log updates
  final _logController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get logStream => _logController.stream;

  // Error tracking stats
  int _errorCount = 0;
  int _warningCount = 0;
  DateTime? _lastError;
  final Map<String, int> _errorsByTag = {};

  // Getters
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<LogEntry> get errors => _logs.where((l) => l.level == LogLevel.error || l.level == LogLevel.fatal).toList();
  List<LogEntry> get warnings => _logs.where((l) => l.level == LogLevel.warning).toList();
  List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);
  List<AnalyticsEvent> get events => List.unmodifiable(_events);
  int get errorCount => _errorCount;
  int get warningCount => _warningCount;
  DateTime? get lastError => _lastError;
  Map<String, int> get errorsByTag => Map.unmodifiable(_errorsByTag);

  /// Configure the logger
  void configure({
    LogLevel? minLevel,
    bool? enableConsoleOutput,
    bool? enableFileLogging,
    int? maxLogEntries,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (enableConsoleOutput != null) _enableConsoleOutput = enableConsoleOutput;
    if (enableFileLogging != null) _enableFileLogging = enableFileLogging;
    if (maxLogEntries != null) _maxLogEntries = maxLogEntries;
  }

  /// Core logging method
  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
    int stackFramesToSkip = 2, // Skip _log and the convenience method
  }) {
    if (level.priority < _minLevel.priority) return;

    // Extract caller info from stack trace
    String? caller;
    if (kDebugMode) {
      caller = _getCallerInfo(stackFramesToSkip);
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
      caller: caller,
    );

    // Add to storage
    _logs.add(entry);
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }

    // Update stats
    if (level == LogLevel.error || level == LogLevel.fatal) {
      _errorCount++;
      _lastError = entry.timestamp;
      _errorsByTag[tag] = (_errorsByTag[tag] ?? 0) + 1;
    } else if (level == LogLevel.warning) {
      _warningCount++;
    }

    // Console output
    if (_enableConsoleOutput) {
      debugPrint(entry.toFormattedString());
    }

    // Stream update
    _logController.add(entry);
  }

  /// Extract file:line from stack trace
  String? _getCallerInfo(int framesToSkip) {
    try {
      final frames = StackTrace.current.toString().split('\n');
      // Skip the specified frames plus the _getCallerInfo frame itself
      final targetFrameIndex = framesToSkip + 1;
      
      if (frames.length > targetFrameIndex) {
        final frame = frames[targetFrameIndex];
        // Parse the stack frame to extract file and line
        // Format: #N      functionName (package:app/path/file.dart:line:col)
        final match = RegExp(r'\((.+?):(\d+):\d+\)').firstMatch(frame);
        if (match != null) {
          final fullPath = match.group(1)!;
          final line = match.group(2)!;
          // Extract just the filename from the path
          final fileName = fullPath.split('/').last;
          return '$fileName:$line';
        }
        // Alternative format: package:app/path/file.dart line:col
        final altMatch = RegExp(r'([^/\s]+\.dart)[:\s]+(\d+)').firstMatch(frame);
        if (altMatch != null) {
          return '${altMatch.group(1)}:${altMatch.group(2)}';
        }
      }
    } catch (_) {
      // Silently fail - caller info is optional
    }
    return null;
  }

  // Convenience logging methods
  void v(String tag, String message, {Map<String, dynamic>? extra}) =>
      _log(LogLevel.verbose, tag, message, extra: extra);

  void d(String tag, String message, {Map<String, dynamic>? extra}) =>
      _log(LogLevel.debug, tag, message, extra: extra);

  void i(String tag, String message, {Map<String, dynamic>? extra}) =>
      _log(LogLevel.info, tag, message, extra: extra);

  void w(String tag, String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) =>
      _log(LogLevel.warning, tag, message, error: error, stackTrace: stackTrace, extra: extra);

  void e(String tag, String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace, extra: extra);

  void f(String tag, String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) =>
      _log(LogLevel.fatal, tag, message, error: error, stackTrace: stackTrace, extra: extra);

  // Performance tracking
  void startMetric(String name, {Map<String, dynamic>? metadata}) {
    final metric = PerformanceMetric(
      name: name,
      startTime: DateTime.now(),
      metadata: metadata,
    );
    _activeMetrics[name] = metric;
    v('PERF', 'Started: $name');
  }

  Duration? stopMetric(String name) {
    final metric = _activeMetrics.remove(name);
    if (metric == null) {
      w('PERF', 'Metric not found: $name');
      return null;
    }
    metric.stop();
    _metrics.add(metric);
    if (_metrics.length > _maxPerformanceMetrics) {
      _metrics.removeAt(0);
    }
    d('PERF', 'Completed: $name in ${metric.duration!.inMilliseconds}ms');
    return metric.duration;
  }

  /// Measure async operation
  Future<T> measureAsync<T>(String name, Future<T> Function() operation, {Map<String, dynamic>? metadata}) async {
    startMetric(name, metadata: metadata);
    try {
      final result = await operation();
      stopMetric(name);
      return result;
    } catch (e, st) {
      stopMetric(name);
      this.e('PERF', 'Failed: $name', error: e, stackTrace: st);
      rethrow;
    }
  }

  // Analytics tracking
  void trackEvent(String name, {String? screen, Map<String, dynamic>? properties}) {
    final event = AnalyticsEvent(
      timestamp: DateTime.now(),
      name: name,
      screen: screen,
      properties: properties,
    );
    _events.add(event);
    if (_events.length > _maxAnalyticsEvents) {
      _events.removeAt(0);
    }
    v('ANALYTICS', '$name${screen != null ? ' on $screen' : ''}', extra: properties);
  }

  void trackScreen(String screenName) {
    trackEvent('screen_view', screen: screenName);
  }

  // Database operations logging
  void logDbQuery(String operation, String table, {int? rowsAffected, Duration? duration, Object? error}) {
    if (error != null) {
      e('DB', '$operation on $table failed', error: error);
    } else {
      d('DB', '$operation on $table${rowsAffected != null ? ' ($rowsAffected rows)' : ''}${duration != null ? ' in ${duration.inMilliseconds}ms' : ''}');
    }
  }

  // Network logging
  void logRequest(String method, String url, {int? statusCode, Duration? duration, Object? error}) {
    if (error != null) {
      e('HTTP', '$method $url failed', error: error);
    } else if (statusCode != null && statusCode >= 400) {
      w('HTTP', '$method $url returned $statusCode in ${duration?.inMilliseconds}ms');
    } else {
      d('HTTP', '$method $url ${statusCode ?? ''} in ${duration?.inMilliseconds}ms');
    }
  }

  // Navigation logging
  void logNavigation(String from, String to, {Map<String, dynamic>? arguments}) {
    i('NAV', '$from → $to', extra: arguments);
  }

  // User action logging
  void logUserAction(String action, {String? target, Map<String, dynamic>? details}) {
    d('USER', '$action${target != null ? ' on $target' : ''}', extra: details);
  }

  // Workflow logging
  void logWorkflow(String step, String action, {Map<String, dynamic>? data}) {
    i('WORKFLOW', '$step: $action', extra: data);
  }

  // State change logging
  void logStateChange(String component, String from, String to, {Map<String, dynamic>? details}) {
    d('STATE', '$component: $from → $to', extra: details);
  }

  // Form logging
  void logFormSubmit(String formName, {bool success = true, Map<String, dynamic>? data, Object? error}) {
    if (success) {
      i('FORM', '$formName submitted successfully', extra: data);
    } else {
      w('FORM', '$formName submission failed', error: error, extra: data);
    }
  }

  // Business logic logging
  void logBusiness(String operation, {Map<String, dynamic>? context, Object? result}) {
    d('BIZ', operation, extra: {
      if (context != null) ...context,
      if (result != null) 'result': result.toString(),
    });
  }

  // Lifecycle logging
  void logLifecycle(String component, String event, {Map<String, dynamic>? details}) {
    v('LIFECYCLE', '$component.$event', extra: details);
  }

  // Security logging (always logged, never filtered)
  void logSecurity(String event, {Map<String, dynamic>? details, bool isAlert = false}) {
    if (isAlert) {
      w('SECURITY', '🔒 $event', extra: details);
    } else {
      i('SECURITY', '🔒 $event', extra: details);
    }
  }

  // Validation logging
  void logValidation(String field, bool isValid, {String? error, Map<String, dynamic>? details}) {
    if (isValid) {
      v('VALIDATION', '$field: valid', extra: details);
    } else {
      d('VALIDATION', '$field: invalid - $error', extra: details);
    }
  }

  // Feature flag logging
  void logFeatureFlag(String feature, bool enabled, {String? reason}) {
    d('FEATURE', '$feature: ${enabled ? 'enabled' : 'disabled'}${reason != null ? ' ($reason)' : ''}');
  }

  // Export logs
  String exportLogsAsJson({LogLevel? minLevel, DateTime? since}) {
    final filtered = _logs.where((l) {
      if (minLevel != null && l.level.priority < minLevel.priority) return false;
      if (since != null && l.timestamp.isBefore(since)) return false;
      return true;
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'stats': {
        'totalErrors': _errorCount,
        'totalWarnings': _warningCount,
        'lastError': _lastError?.toIso8601String(),
        'errorsByTag': _errorsByTag,
      },
      'logs': filtered.map((l) => l.toJson()).toList(),
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'events': _events.map((e) => e.toJson()).toList(),
    });
  }

  // Get summary
  Map<String, dynamic> getSummary() => {
    'totalLogs': _logs.length,
    'errors': _errorCount,
    'warnings': _warningCount,
    'lastError': _lastError?.toIso8601String(),
    'errorsByTag': _errorsByTag,
    'metricsCount': _metrics.length,
    'eventsCount': _events.length,
  };

  // Filter logs
  List<LogEntry> filterLogs({
    LogLevel? level,
    String? tag,
    DateTime? since,
    DateTime? until,
    String? contains,
  }) {
    return _logs.where((log) {
      if (level != null && log.level != level) return false;
      if (tag != null && log.tag != tag) return false;
      if (since != null && log.timestamp.isBefore(since)) return false;
      if (until != null && log.timestamp.isAfter(until)) return false;
      if (contains != null && !log.message.toLowerCase().contains(contains.toLowerCase())) return false;
      return true;
    }).toList();
  }

  // Clear logs
  void clear() {
    _logs.clear();
    _metrics.clear();
    _events.clear();
    _errorCount = 0;
    _warningCount = 0;
    _lastError = null;
    _errorsByTag.clear();
    i('LOGGER', 'Logs cleared');
  }

  void dispose() {
    _logController.close();
  }
}

// Global instance for easy access
final log = AppLogger();

/// Mixin for classes that need logging
mixin Loggable {
  String get logTag => runtimeType.toString();
  
  void logVerbose(String message, {Map<String, dynamic>? extra}) =>
      log.v(logTag, message, extra: extra);
  
  void logDebug(String message, {Map<String, dynamic>? extra}) =>
      log.d(logTag, message, extra: extra);
  
  void logInfo(String message, {Map<String, dynamic>? extra}) =>
      log.i(logTag, message, extra: extra);
  
  void logWarning(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) =>
      log.w(logTag, message, error: error, stackTrace: stackTrace, extra: extra);
  
  void logError(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) =>
      log.e(logTag, message, error: error, stackTrace: stackTrace, extra: extra);
}

/// Extension for catching and logging errors
extension LoggingFuture<T> on Future<T> {
  Future<T> logErrors(String tag, String context) async {
    try {
      return await this;
    } catch (e, st) {
      log.e(tag, 'Error in $context', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<T?> logErrorsOrNull(String tag, String context) async {
    try {
      return await this;
    } catch (e, st) {
      log.e(tag, 'Error in $context', error: e, stackTrace: st);
      return null;
    }
  }
}
