import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  // Use WebDatabase with IndexedDB storage for persistence
  // This is the simplest web setup that works without external WASM files
  return WebDatabase.withStorage(
    DriftWebStorage.indexedDb('doctor_app_db'),
    logStatements: false,
  );
}
