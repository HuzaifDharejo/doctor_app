import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/services/logger_service.dart';

void main() {
  late AppLogger logger;
  int initialLogCount = 0;

  setUp(() {
    logger = AppLogger();
    logger.clear(); // Clear any existing logs (this adds one "Logs cleared" entry)
    logger.configure(
      enableConsoleOutput: false, // Disable console output in tests
      minLevel: LogLevel.verbose,
    );
    initialLogCount = logger.logs.length; // Track initial count after clear
  });

  group('LogLevel', () {
    test('should have correct priorities', () {
      expect(LogLevel.verbose.priority, lessThan(LogLevel.debug.priority));
      expect(LogLevel.debug.priority, lessThan(LogLevel.info.priority));
      expect(LogLevel.info.priority, lessThan(LogLevel.warning.priority));
      expect(LogLevel.warning.priority, lessThan(LogLevel.error.priority));
      expect(LogLevel.error.priority, lessThan(LogLevel.fatal.priority));
    });

    test('should have correct prefixes', () {
      expect(LogLevel.verbose.prefix, equals('V'));
      expect(LogLevel.debug.prefix, equals('D'));
      expect(LogLevel.info.prefix, equals('I'));
      expect(LogLevel.warning.prefix, equals('W'));
      expect(LogLevel.error.prefix, equals('E'));
      expect(LogLevel.fatal.prefix, equals('F'));
    });
  });

  group('LogEntry', () {
    test('should create log entry with all fields', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 6, 15, 10, 30),
        level: LogLevel.info,
        tag: 'TEST',
        message: 'Test message',
        error: Exception('Test error'),
        stackTrace: StackTrace.current,
        extra: {'key': 'value'},
      );

      expect(entry.timestamp, equals(DateTime(2024, 6, 15, 10, 30)));
      expect(entry.level, equals(LogLevel.info));
      expect(entry.tag, equals('TEST'));
      expect(entry.message, equals('Test message'));
      expect(entry.error, isA<Exception>());
      expect(entry.stackTrace, isNotNull);
      expect(entry.extra, equals({'key': 'value'}));
    });

    test('should convert to JSON', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 6, 15, 10, 30),
        level: LogLevel.info,
        tag: 'TEST',
        message: 'Test message',
        extra: {'key': 'value'},
      );

      final json = entry.toJson();

      expect(json['level'], equals('info'));
      expect(json['tag'], equals('TEST'));
      expect(json['message'], equals('Test message'));
      expect(json['extra'], equals({'key': 'value'}));
    });

    test('should format to string', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 6, 15, 10, 30, 45, 123),
        level: LogLevel.info,
        tag: 'TEST',
        message: 'Test message',
      );

      final formatted = entry.toFormattedString();

      expect(formatted, contains('[I]'));
      expect(formatted, contains('[TEST]'));
      expect(formatted, contains('Test message'));
      expect(formatted, contains('10:30:45.123'));
    });
  });

  group('PerformanceMetric', () {
    test('should calculate duration', () {
      final metric = PerformanceMetric(
        name: 'test_metric',
        startTime: DateTime(2024, 6, 15, 10, 0, 0),
      );
      metric.endTime = DateTime(2024, 6, 15, 10, 0, 5);

      expect(metric.duration, equals(const Duration(seconds: 5)));
    });

    test('should stop and set end time', () {
      final metric = PerformanceMetric(
        name: 'test_metric',
        startTime: DateTime.now(),
      );

      expect(metric.endTime, isNull);

      metric.stop();

      expect(metric.endTime, isNotNull);
      expect(metric.duration, isNotNull);
    });

    test('should convert to JSON', () {
      final metric = PerformanceMetric(
        name: 'test_metric',
        startTime: DateTime(2024, 6, 15, 10, 0, 0),
        metadata: {'key': 'value'},
      );
      metric.endTime = DateTime(2024, 6, 15, 10, 0, 1);

      final json = metric.toJson();

      expect(json['name'], equals('test_metric'));
      expect(json['durationMs'], equals(1000));
      expect(json['metadata'], equals({'key': 'value'}));
    });
  });

  group('AnalyticsEvent', () {
    test('should create event with all fields', () {
      final event = AnalyticsEvent(
        timestamp: DateTime(2024, 6, 15),
        name: 'button_click',
        screen: 'home',
        properties: {'button_id': 'submit'},
      );

      expect(event.name, equals('button_click'));
      expect(event.screen, equals('home'));
      expect(event.properties, equals({'button_id': 'submit'}));
    });

    test('should convert to JSON', () {
      final event = AnalyticsEvent(
        timestamp: DateTime(2024, 6, 15),
        name: 'button_click',
        screen: 'home',
        properties: {'button_id': 'submit'},
      );

      final json = event.toJson();

      expect(json['name'], equals('button_click'));
      expect(json['screen'], equals('home'));
      expect(json['properties'], equals({'button_id': 'submit'}));
    });
  });

  group('AppLogger Basic Logging', () {
    test('should log verbose message', () {
      logger.v('TEST', 'Verbose message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.verbose));
      expect(logger.logs.last.message, equals('Verbose message'));
    });

    test('should log debug message', () {
      logger.d('TEST', 'Debug message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.debug));
    });

    test('should log info message', () {
      logger.i('TEST', 'Info message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.info));
    });

    test('should log warning message', () {
      logger.w('TEST', 'Warning message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.warning));
      expect(logger.warningCount, equals(1));
    });

    test('should log error message', () {
      logger.e('TEST', 'Error message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.error));
      expect(logger.errorCount, equals(1));
      expect(logger.lastError, isNotNull);
    });

    test('should log fatal message', () {
      logger.f('TEST', 'Fatal message');

      expect(logger.logs.length, equals(initialLogCount + 1));
      expect(logger.logs.last.level, equals(LogLevel.fatal));
      expect(logger.errorCount, equals(1));
    });

    test('should log with extra data', () {
      logger.i('TEST', 'Message', extra: {'key': 'value'});

      expect(logger.logs.last.extra, equals({'key': 'value'}));
    });

    test('should log with error and stack trace', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      logger.e('TEST', 'Error message', error: error, stackTrace: stackTrace);

      expect(logger.logs.last.error, equals(error));
      expect(logger.logs.last.stackTrace, isNotNull);
    });
  });

  group('AppLogger Configuration', () {
    test('should respect minimum log level', () {
      logger.configure(minLevel: LogLevel.warning);
      final countBefore = logger.logs.length;

      logger.v('TEST', 'Verbose');
      logger.d('TEST', 'Debug');
      logger.i('TEST', 'Info');
      logger.w('TEST', 'Warning');
      logger.e('TEST', 'Error');

      expect(logger.logs.length - countBefore, equals(2)); // Only warning and error
    });

    test('should limit max log entries', () {
      logger.configure(maxLogEntries: 5);
      logger.clear(); // Reset with new limit

      for (var i = 0; i < 10; i++) {
        logger.i('TEST', 'Message $i');
      }

      expect(logger.logs.length, lessThanOrEqualTo(5));
    });
  });

  group('AppLogger Statistics', () {
    test('should track error count', () {
      logger.e('TAG1', 'Error 1');
      logger.e('TAG2', 'Error 2');
      logger.e('TAG1', 'Error 3');

      expect(logger.errorCount, equals(3));
    });

    test('should track warning count', () {
      logger.w('TEST', 'Warning 1');
      logger.w('TEST', 'Warning 2');

      expect(logger.warningCount, equals(2));
    });

    test('should track errors by tag', () {
      logger.e('TAG1', 'Error 1');
      logger.e('TAG2', 'Error 2');
      logger.e('TAG1', 'Error 3');

      expect(logger.errorsByTag['TAG1'], equals(2));
      expect(logger.errorsByTag['TAG2'], equals(1));
    });

    test('should track last error timestamp', () {
      final beforeError = DateTime.now();
      logger.e('TEST', 'Error');
      final afterError = DateTime.now();

      expect(logger.lastError, isNotNull);
      expect(
        logger.lastError!.isAfter(beforeError.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        logger.lastError!.isBefore(afterError.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('should get errors list', () {
      logger.i('TEST', 'Info');
      logger.e('TEST', 'Error 1');
      logger.w('TEST', 'Warning');
      logger.e('TEST', 'Error 2');
      logger.f('TEST', 'Fatal');

      expect(logger.errors.length, equals(3)); // 2 errors + 1 fatal
    });

    test('should get warnings list', () {
      logger.i('TEST', 'Info');
      logger.w('TEST', 'Warning 1');
      logger.e('TEST', 'Error');
      logger.w('TEST', 'Warning 2');

      expect(logger.warnings.length, equals(2));
    });

    test('should get summary', () {
      logger.i('TEST', 'Info');
      logger.w('TEST', 'Warning');
      logger.e('TEST', 'Error');

      final summary = logger.getSummary();

      expect(summary['totalLogs'], greaterThanOrEqualTo(3));
      expect(summary['errors'], equals(1));
      expect(summary['warnings'], equals(1));
    });
  });

  group('AppLogger Performance Tracking', () {
    test('should start and stop metric', () async {
      logger.startMetric('test_operation');
      await Future.delayed(const Duration(milliseconds: 50));
      final duration = logger.stopMetric('test_operation');

      expect(duration, isNotNull);
      expect(duration!.inMilliseconds, greaterThanOrEqualTo(40));
      expect(logger.metrics.length, equals(1));
    });

    test('should handle stopping non-existent metric', () {
      final duration = logger.stopMetric('non_existent');

      expect(duration, isNull);
    });

    test('should measure async operation', () async {
      final result = await logger.measureAsync(
        'async_operation',
        () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'done';
        },
      );

      expect(result, equals('done'));
      expect(logger.metrics.length, equals(1));
      expect(logger.metrics.first.name, equals('async_operation'));
    });

    test('should log error from async measurement', () async {
      try {
        await logger.measureAsync(
          'failing_operation',
          () async {
            throw Exception('Test error');
          },
        );
      } catch (_) {
        // Expected
      }

      expect(logger.errors.length, equals(1));
      expect(logger.errors.first.message, contains('Failed'));
    });
  });

  group('AppLogger Analytics', () {
    test('should track event', () {
      logger.trackEvent('button_click', properties: {'id': 'submit'});

      expect(logger.events.length, equals(1));
      expect(logger.events.first.name, equals('button_click'));
      expect(logger.events.first.properties, equals({'id': 'submit'}));
    });

    test('should track event with screen', () {
      logger.trackEvent('button_click', screen: 'home');

      expect(logger.events.first.screen, equals('home'));
    });

    test('should track screen view', () {
      logger.trackScreen('dashboard');

      expect(logger.events.length, equals(1));
      expect(logger.events.first.name, equals('screen_view'));
      expect(logger.events.first.screen, equals('dashboard'));
    });
  });

  group('AppLogger Specialized Logging', () {
    test('should log database query success', () {
      final countBefore = logger.logs.length;
      logger.logDbQuery('INSERT', 'patients', rowsAffected: 1);

      expect(logger.logs.length - countBefore, equals(1));
      expect(logger.logs.last.tag, equals('DB'));
      expect(logger.logs.last.message, contains('INSERT'));
      expect(logger.logs.last.message, contains('patients'));
    });

    test('should log database query error', () {
      logger.logDbQuery('INSERT', 'patients', error: Exception('DB error'));

      expect(logger.errors.length, greaterThanOrEqualTo(1));
    });

    test('should log HTTP request success', () {
      final countBefore = logger.logs.length;
      logger.logRequest(
        'GET',
        '/api/patients',
        statusCode: 200,
        duration: const Duration(milliseconds: 150),
      );

      expect(logger.logs.length - countBefore, equals(1));
      expect(logger.logs.last.tag, equals('HTTP'));
    });

    test('should log HTTP request error', () {
      logger.logRequest('GET', '/api/patients', error: Exception('Network error'));

      expect(logger.errors.length, greaterThanOrEqualTo(1));
    });

    test('should log HTTP request with error status', () {
      logger.logRequest('GET', '/api/patients', statusCode: 404);

      expect(logger.warnings.length, greaterThanOrEqualTo(1));
    });

    test('should log navigation', () {
      final countBefore = logger.logs.length;
      logger.logNavigation('home', 'patients', arguments: {'id': 1});

      expect(logger.logs.length - countBefore, equals(1));
      expect(logger.logs.last.tag, equals('NAV'));
      expect(logger.logs.last.message, contains('home → patients'));
    });

    test('should log user action', () {
      final countBefore = logger.logs.length;
      logger.logUserAction('tap', target: 'submit_button', details: {'form': 'patient'});

      expect(logger.logs.length - countBefore, equals(1));
      expect(logger.logs.last.tag, equals('USER'));
    });
  });

  group('AppLogger Filtering', () {
    test('should filter logs by level', () {
      logger.i('TEST', 'Info');
      logger.w('TEST', 'Warning');
      logger.e('TEST', 'Error');

      final filtered = logger.filterLogs(level: LogLevel.warning);

      expect(filtered.length, equals(1));
      expect(filtered.first.level, equals(LogLevel.warning));
    });

    test('should filter logs by tag', () {
      logger.i('TAG1', 'Message 1');
      logger.i('TAG2', 'Message 2');
      logger.i('TAG1', 'Message 3');

      final filtered = logger.filterLogs(tag: 'TAG1');

      expect(filtered.length, equals(2));
    });

    test('should filter logs by time range', () {
      final countBefore = logger.logs.length;
      logger.i('TEST', 'Message');

      final now = DateTime.now();
      final future = now.add(const Duration(hours: 1));
      final past = now.subtract(const Duration(hours: 1));

      final filteredSince = logger.filterLogs(since: past);
      expect(filteredSince.length, greaterThanOrEqualTo(1));

      final filteredFuture = logger.filterLogs(since: future);
      expect(filteredFuture.length, equals(0));
    });

    test('should filter logs by content', () {
      logger.i('TEST', 'Hello world');
      logger.i('TEST', 'Goodbye world');
      logger.i('TEST', 'Hello there');

      final filtered = logger.filterLogs(contains: 'hello');

      expect(filtered.length, equals(2));
    });
  });

  group('AppLogger Export', () {
    test('should export logs as JSON', () {
      logger.i('TEST', 'Info message');
      logger.e('TEST', 'Error message');

      final json = logger.exportLogsAsJson();

      expect(json, contains('Info message'));
      expect(json, contains('Error message'));
      expect(json, contains('stats'));
      expect(json, contains('logs'));
    });

    test('should filter export by level', () {
      logger.i('TEST', 'Info');
      logger.e('TEST', 'Error');

      final json = logger.exportLogsAsJson(minLevel: LogLevel.error);

      expect(json, contains('Error'));
      expect(json, isNot(contains('"message": "Info"')));
    });
  });

  group('AppLogger Clear', () {
    test('should clear all data', () {
      logger.i('TEST', 'Message');
      logger.e('TEST', 'Error');
      logger.w('TEST', 'Warning');
      logger.trackEvent('event');
      logger.startMetric('metric');
      logger.stopMetric('metric');

      logger.clear();

      // Clear adds one log entry ("Logs cleared")
      expect(logger.logs.length, equals(1));
      expect(logger.errorCount, equals(0));
      expect(logger.warningCount, equals(0));
      expect(logger.lastError, isNull);
      expect(logger.errorsByTag, isEmpty);
      expect(logger.metrics, isEmpty);
      expect(logger.events, isEmpty);
    });
  });

  group('AppLogger Stream', () {
    test('should stream log entries', () async {
      final entries = <LogEntry>[];
      final subscription = logger.logStream.listen(entries.add);

      logger.i('TEST', 'Message 1');
      logger.i('TEST', 'Message 2');

      await Future.delayed(const Duration(milliseconds: 10));

      expect(entries.length, equals(2));

      await subscription.cancel();
    });
  });

  group('Loggable Mixin', () {
    test('should use class name as tag', () {
      final testClass = _TestLoggable();
      testClass.testLog();

      // Find the log entry with the _TestLoggable tag
      final testLogs = logger.logs.where((l) => l.tag == '_TestLoggable').toList();
      expect(testLogs.isNotEmpty, isTrue);
    });

    test('should have all logging methods', () {
      final testClass = _TestLoggable();
      final logsBefore = logger.logs.where((l) => l.tag == '_TestLoggable').length;

      testClass.logVerbose('Verbose');
      testClass.logDebug('Debug');
      testClass.logInfo('Info');
      testClass.logWarning('Warning');
      testClass.logError('Error');

      final logsAfter = logger.logs.where((l) => l.tag == '_TestLoggable').length;
      expect(logsAfter - logsBefore, equals(5));
    });
  });

  group('LoggingFuture Extension', () {
    test('should log and rethrow error', () async {
      final future = Future<int>.error(Exception('Test error'));

      try {
        await future.logErrors('TEST', 'test operation');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(logger.errors.length, equals(1));
      expect(logger.errors.first.message, contains('test operation'));
    });

    test('should return null on error', () async {
      final future = Future<int>.error(Exception('Test error'));

      final result = await future.logErrorsOrNull('TEST', 'test operation');

      expect(result, isNull);
      expect(logger.errors.length, equals(1));
    });

    test('should return value on success', () async {
      final future = Future.value(42);

      final result = await future.logErrors('TEST', 'test operation');

      expect(result, equals(42));
      expect(logger.errors, isEmpty);
    });
  });
}

class _TestLoggable with Loggable {
  void testLog() {
    logInfo('Test message');
  }
}
