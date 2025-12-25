import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/services/logger_service.dart';

void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Filter out known harmless Flutter Web warnings
    final errorString = details.exceptionAsString();
    
    // Ignore AssetManifest.json errors on web - this is a known Flutter Web limitation
    // when importing services.dart, even if rootBundle is never used
    if (kIsWeb && errorString.contains('AssetManifest.json')) {
      // Silently ignore - this is expected behavior on Flutter Web
      // Don't log or dump to console - completely suppress
      return;
    }
    
    // Ignore disposed EngineFlutterView errors on web - known Flutter Web issue
    // that occurs during navigation transitions (fixed in Flutter 3.27.0+)
    if (kIsWeb && errorString.contains('disposed EngineFlutterView')) {
      // Silently ignore - this is a known Flutter Web framework issue
      // Don't log or dump to console - completely suppress
      return;
    }
    
    log.e('FLUTTER', errorString,
      error: details.exception,
      stackTrace: details.stack,
      extra: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
    
    // In debug mode, also print to console (only for non-suppressed errors)
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Catch async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Suppress known harmless Flutter Web errors
    final errorString = error.toString();
    
    // Ignore AssetManifest.json errors on web - this is a known Flutter Web limitation
    // when importing services.dart, even if rootBundle is never used
    if (kIsWeb && errorString.contains('AssetManifest.json')) {
      // Silently ignore - this is expected behavior on Flutter Web
      return true; // Handled
    }
    
    // Ignore disposed EngineFlutterView errors on web
    if (kIsWeb && errorString.contains('disposed EngineFlutterView')) {
      // Silently ignore - this is a known Flutter Web framework issue
      return true; // Handled
    }
    
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
