import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/logger_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logger
  log.configure(
    minLevel: kDebugMode ? LogLevel.verbose : LogLevel.warning,
    enableConsoleOutput: kDebugMode,
  );

  log.i('APP', '═══════════════════════════════════════════════');
  log.i('APP', '  Doctor App Starting...');
  log.i('APP', '  Debug Mode: $kDebugMode');
  log.i('APP', '═══════════════════════════════════════════════');

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    log.e('FLUTTER', details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
      extra: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
    
    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    log.f('PLATFORM', 'Uncaught platform error',
      error: error,
      stackTrace: stack,
    );
    return true; // Handled
  };

  // Run app in guarded zone to catch all errors
  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: DoctorApp()));
      log.i('APP', 'App launched successfully');
    },
    (error, stackTrace) {
      log.f('ZONE', 'Uncaught zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
