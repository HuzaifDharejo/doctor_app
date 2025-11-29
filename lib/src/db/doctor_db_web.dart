import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  // Simple WebDatabase using localStorage/IndexedDB
  // Works without sql.js setup for basic use cases
  return WebDatabase('doctor_app_db');
}
