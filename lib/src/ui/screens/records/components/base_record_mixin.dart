import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../db/doctor_db.dart';
import '../../../../providers/db_provider.dart';

/// Mixin providing common state and functionality for all medical record screens
/// 
/// This mixin reduces code duplication by providing:
/// - Form key and scroll controller
/// - Section navigation with GlobalKeys
/// - Section expansion state management
/// - Common saving/loading utilities
/// - Patient selection state
/// 
/// Usage:
/// ```dart
/// class _AddCardiacExamScreenState extends ConsumerState<AddCardiacExamScreen>
///     with BaseRecordMixin {
///   @override
///   List<RecordSection> get sections => [
///     RecordSection(key: 'complaint', name: 'Complaint', icon: Icons.report_problem),
///     // ...
///   ];
/// }
/// ```
mixin BaseRecordMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // ============================================================
  // FORM STATE - Common to all record forms
  // ============================================================
  
  /// Form key for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  /// Scroll controller for the form
  final ScrollController scrollController = ScrollController();
  
  /// Whether the form is currently saving
  bool isSaving = false;
  
  /// Selected patient ID
  int? selectedPatientId;
  
  /// Record date (defaults to now)
  DateTime recordDate = DateTime.now();
  
  // ============================================================
  // SECTION NAVIGATION - For scrolling to sections
  // ============================================================
  
  /// Map of section keys to their GlobalKeys for scroll navigation
  final Map<String, GlobalKey> sectionKeys = {};
  
  /// Map of section keys to their expansion state
  final Map<String, bool> expandedSections = {};
  
  /// Override this to define the sections for your record type
  /// Each section has a key, display name, and icon
  List<RecordSection> get sections;
  
  /// Initialize section keys and expansion states based on [sections]
  void initializeSections() {
    for (final section in sections) {
      sectionKeys[section.key] = GlobalKey();
      expandedSections[section.key] = section.initiallyExpanded;
    }
  }
  
  /// Get the GlobalKey for a section
  GlobalKey? getSectionKey(String key) => sectionKeys[key];
  
  /// Check if a section is expanded
  bool isSectionExpanded(String key) => expandedSections[key] ?? true;
  
  /// Toggle a section's expansion state
  void toggleSection(String key) {
    if (mounted) {
      setState(() {
        expandedSections[key] = !(expandedSections[key] ?? true);
      });
    }
  }
  
  /// Scroll to a specific section
  void scrollToSection(String key) {
    if (!mounted) return;
    final sectionKey = sectionKeys[key];
    if (sectionKey?.currentContext != null && mounted) {
      Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }
  
  // ============================================================
  // SAVING UTILITIES
  // ============================================================
  
  /// Set saving state with mounted check
  void setSaving(bool value) {
    if (mounted) {
      setState(() => isSaving = value);
    }
  }
  
  /// Update patient selection with mounted check
  void setPatientId(int? id) {
    if (mounted) {
      setState(() => selectedPatientId = id);
    }
  }
  
  /// Update record date with mounted check
  void setRecordDate(DateTime date) {
    if (mounted) {
      setState(() => recordDate = date);
    }
  }
  
  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
  
  /// Show a template applied snackbar with custom color
  void showTemplateAppliedSnackbar(BuildContext context, String templateName, {Color? color}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Applied "$templateName" template',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: color ?? Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // ============================================================
  // LIFECYCLE
  // ============================================================
  
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

/// Represents a section in a medical record form
class RecordSection {
  const RecordSection({
    required this.key,
    required this.name,
    required this.icon,
    this.initiallyExpanded = true,
  });
  
  /// Unique key for this section (e.g., 'complaint', 'vitals')
  final String key;
  
  /// Display name (e.g., 'Chief Complaint', 'Vital Signs')
  final String name;
  
  /// Icon for the section
  final IconData icon;
  
  /// Whether the section starts expanded
  final bool initiallyExpanded;
}

/// Extension for loading existing record data
extension BaseRecordLoadingExtension<T extends ConsumerStatefulWidget> on BaseRecordMixin<T> {
  /// Get the database instance
  Future<DoctorDatabase> getDatabase() async {
    return ref.read(doctorDbProvider.future);
  }
  
  /// Load record fields using the normalized table with fallback
  Future<Map<String, dynamic>> loadRecordFields(int recordId) async {
    final db = await getDatabase();
    return db.getMedicalRecordFieldsCompat(recordId);
  }
}
