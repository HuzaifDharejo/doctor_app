import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../db/doctor_db.dart';
import '../../../../theme/app_theme.dart';
import 'base_record_mixin.dart';
import 'date_picker_card.dart';
import 'form_progress_indicator.dart';
import 'patient_selector_card.dart';
import 'quick_fill_template_bar.dart';
import '../../../../core/extensions/context_extensions.dart';

/// An enhanced scaffold widget for medical record forms with full features
/// 
/// This is a more feature-rich alternative to [RecordFormScaffold] that includes:
/// - Gradient header with icon and title
/// - Section navigation bar
/// - Quick fill templates
/// - Patient selector
/// - Date picker
/// - Form progress indicator
/// - Floating save button
/// 
/// Example:
/// ```dart
/// EnhancedRecordScaffold(
///   title: 'Cardiac Exam',
///   subtitle: 'Record cardiac examination findings',
///   icon: Icons.monitor_heart_rounded,
///   gradientColors: [Colors.red, Colors.red.shade700],
///   sections: _sections,
///   sectionKeys: _sectionKeys,
///   onSectionTap: _scrollToSection,
///   templates: _templates,
///   onTemplateSelected: _applyTemplate,
///   db: database,
///   selectedPatientId: _selectedPatientId,
///   onPatientChanged: (id) => setState(() => _selectedPatientId = id),
///   recordDate: _recordDate,
///   onDateChanged: (date) => setState(() => _recordDate = date),
///   isSaving: _isSaving,
///   onSave: _saveRecord,
///   formKey: _formKey,
///   scrollController: _scrollController,
///   body: Column(children: [...sections]),
/// )
/// ```
class EnhancedRecordScaffold extends StatelessWidget {
  const EnhancedRecordScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.sections,
    required this.sectionKeys,
    required this.onSectionTap,
    required this.templates,
    required this.onTemplateSelected,
    required this.db,
    required this.selectedPatientId,
    required this.onPatientChanged,
    required this.recordDate,
    required this.onDateChanged,
    required this.isSaving,
    required this.onSave,
    required this.formKey,
    required this.scrollController,
    required this.body,
    this.preselectedPatient,
    this.isEditing = false,
    this.onReset,
    this.showPatientSelector = true,
    this.showDatePicker = true,
    this.showTemplates = true,
    this.showSectionNav = true,
    this.showProgress = true,
    this.progress = 0.0,
    this.additionalHeaderContent,
  });

  /// Title shown in header
  final String title;
  
  /// Subtitle shown below title
  final String subtitle;
  
  /// Icon displayed in header
  final IconData icon;
  
  /// Gradient colors for header [start, end]
  final List<Color> gradientColors;
  
  /// List of sections for navigation
  final List<RecordSection> sections;
  
  /// Map of section keys to GlobalKeys for scrolling
  final Map<String, GlobalKey> sectionKeys;
  
  /// Callback when a section nav button is tapped
  final void Function(String sectionKey) onSectionTap;
  
  /// Quick fill templates
  final List<QuickFillTemplateItem> templates;
  
  /// Callback when template is selected
  final void Function(QuickFillTemplateItem template) onTemplateSelected;
  
  /// Database instance for patient selector
  final DoctorDatabase db;
  
  /// Currently selected patient ID
  final int? selectedPatientId;
  
  /// Callback when patient changes
  final void Function(int?) onPatientChanged;
  
  /// Preselected patient (if any)
  final Patient? preselectedPatient;
  
  /// Currently selected record date
  final DateTime recordDate;
  
  /// Callback when date changes
  final void Function(DateTime) onDateChanged;
  
  /// Whether the form is currently saving
  final bool isSaving;
  
  /// Callback to save the record
  final VoidCallback onSave;
  
  /// Form key for validation
  final GlobalKey<FormState> formKey;
  
  /// Scroll controller for the form
  final ScrollController scrollController;
  
  /// The form body content
  final Widget body;
  
  /// Whether this is editing an existing record
  final bool isEditing;
  
  /// Optional reset callback
  final VoidCallback? onReset;
  
  /// Whether to show patient selector
  final bool showPatientSelector;
  
  /// Whether to show date picker
  final bool showDatePicker;
  
  /// Whether to show quick fill templates
  final bool showTemplates;
  
  /// Whether to show section navigation
  final bool showSectionNav;
  
  /// Whether to show progress indicator
  final bool showProgress;
  
  /// Form completion progress (0.0 - 1.0)
  final double progress;
  
  /// Additional content to show in header area
  final Widget? additionalHeaderContent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: Form(
        key: formKey,
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: _buildGradientHeader(context, isDark, isCompact),
            ),
            
            // Section Navigation Bar
            if (showSectionNav && sections.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildSectionNavBar(isDark),
                ),
              ),
            
            // Quick Fill Templates
            if (showTemplates && templates.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, 0),
                  child: QuickFillTemplateBar(
                    templates: templates,
                    onTemplateSelected: onTemplateSelected,
                  ),
                ),
              ),
            
            // Progress Indicator
            if (showProgress)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 0),
                  child: FormProgressIndicator(
                    completedSections: (progress * 10).round(), // Convert progress to sections
                    totalSections: 10,
                    accentColor: gradientColors.first,
                  ),
                ),
              ),
            
            // Patient Selector
            if (showPatientSelector)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 16, padding, 0),
                  child: PatientSelectorCard(
                    db: db,
                    selectedPatientId: selectedPatientId ?? preselectedPatient?.id,
                    onChanged: onPatientChanged,
                  ),
                ),
              ),
            
            // Date Picker
            if (showDatePicker)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 0),
                  child: DatePickerCard(
                    selectedDate: recordDate,
                    onDateSelected: onDateChanged,
                  ),
                ),
              ),
            
            // Additional Header Content
            if (additionalHeaderContent != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 12, padding, 0),
                  child: additionalHeaderContent,
                ),
              ),
            
            // Form Body
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([body]),
              ),
            ),
            
            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildGradientHeader(BuildContext context, bool isDark, bool isCompact) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: isCompact ? 16 : 24,
        right: isCompact ? 16 : 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          // Edit badge if editing
          if (isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final section = sections[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSectionTap(section.key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : gradientColors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gradientColors.first.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    section.icon,
                    size: 16,
                    color: gradientColors.first,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    section.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
      child: Row(
        children: [
          // Reset button (optional)
          if (onReset != null)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gradientColors.first,
                    side: BorderSide(color: gradientColors.first),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          if (onReset != null)
            const SizedBox(width: 12),
          // Save button
          Expanded(
            flex: onReset != null ? 2 : 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(isEditing ? Icons.update_rounded : Icons.save_rounded),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : isEditing
                          ? 'Update Record'
                          : 'Save Record',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gradientColors.first,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: gradientColors.first.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
