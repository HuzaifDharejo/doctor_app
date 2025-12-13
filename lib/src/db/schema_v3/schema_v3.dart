// ═══════════════════════════════════════════════════════════════════════════════
// SCHEMA V3: FULLY NORMALIZED DATABASE
// ═══════════════════════════════════════════════════════════════════════════════
//
// This module contains the redesigned database schema that properly normalizes
// all JSON fields into separate, queryable tables with proper relationships.
//
// Files:
// - schema_v3_design.dart: New table definitions using Drift
// - schema_v3_migration.dart: SQL statements to create new tables
// - schema_v3_data_migrator.dart: Service to migrate existing JSON data
//
// ═══════════════════════════════════════════════════════════════════════════════

export 'schema_v3_design.dart';
export 'schema_v3_migration.dart';
export 'schema_v3_data_migrator.dart';
