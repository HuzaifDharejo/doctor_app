import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/logger_service.dart';

void main() {
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

  // Ensure Flutter binding is initialized BEFORE runZonedGuarded
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logger
  log
    ..configure(
      minLevel: kDebugMode ? LogLevel.verbose : LogLevel.warning,
      enableConsoleOutput: kDebugMode,
    )
    ..i('APP', '═══════════════════════════════════════════════')
    ..i('APP', '  Doctor App Starting...')
    ..i('APP', '  Debug Mode: $kDebugMode')
    ..i('APP', '═══════════════════════════════════════════════');

  // Run app - no need for runZonedGuarded since we have other error handlers
  runApp(const ProviderScope(child: DoctorApp()));
  log.i('APP', 'App launched successfully');
}
