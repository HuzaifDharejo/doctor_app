import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../core/components/app_button.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/medical_record_widgets.dart';
import 'records/records.dart';

/// A modern, accessible medical record detail screen
/// 
/// Displays comprehensive medical record information with:
/// - Type-specific content rendering (pulmonary, psychiatric, etc.)
/// - Modern gradient header design
/// - Accessible semantic labels
/// - Dark mode support
class MedicalRecordDetailScreen extends ConsumerWidget {

  const MedicalRecordDetailScreen({
    required this.record, required this.patient, super.key,
  });
  final MedicalRecord record;
  final Patient patient;

  /// Cached parsed JSON data with error handling
  Map<String, dynamic> get _data {
    if (record.dataJson.isEmpty || record.dataJson == '{}') return {};
    try {
      return jsonDecode(record.dataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing medical record data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recordInfo = RecordTypeInfo.fromType(record.recordType);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              record: record,
              patient: patient,
              recordInfo: recordInfo,
              ref: ref,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PatientCard(patient: patient, isDark: isDark),
                const SizedBox(height: MedicalRecordConstants.paddingLarge),
                _RecordContent(record: record, data: _data, isDark: isDark),
                ..._buildCommonSections(isDark),
                const SizedBox(height: 32),
                // Show all stored data section - displays any remaining fields
                if (_data.isNotEmpty)
                  _AllDataSection(data: _data, isDark: isDark),
                const SizedBox(height: 32),
                _ActionButtons(
                  record: record,
                  patient: patient,
                  isDark: isDark,
                  ref: ref,
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommonSections(bool isDark) {
    return [
      if (record.diagnosis.isNotEmpty) ...[
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        InfoCard(
          title: 'Diagnosis',
          content: record.diagnosis,
          icon: Icons.medical_information_outlined,
          color: AppColors.error,
          isDark: isDark,
        ),
      ],
      if (record.treatment.isNotEmpty) ...[
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        InfoCard(
          title: 'Treatment Plan',
          content: record.treatment,
          icon: Icons.healing_outlined,
          color: AppColors.success,
          isDark: isDark,
        ),
      ],
      if (record.doctorNotes.isNotEmpty) ...[
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        InfoCard(
          title: "Doctor's Notes",
          content: record.doctorNotes,
          icon: Icons.note_alt_outlined,
          color: AppColors.info,
          isDark: isDark,
        ),
      ],
    ];
  }
}

// ============================================================================
// HEADER SECTION
// ============================================================================

class _Header extends StatelessWidget {

  const _Header({
    required this.record,
    required this.patient,
    required this.recordInfo,
    required this.ref,
  });
  final MedicalRecord record;
  final Patient patient;
  final RecordTypeInfo recordInfo;
  final WidgetRef ref;

  static final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(MedicalRecordConstants.radiusHeader),
          bottomRight: Radius.circular(MedicalRecordConstants.radiusHeader),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context, isDark),
              const SizedBox(height: 24),
              _buildTitleSection(isDark),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.share_outlined,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => _handleShare(context),
            tooltip: 'Share record',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.print_outlined,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => _handlePrint(context),
            tooltip: 'Print record',
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [recordInfo.color, recordInfo.color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: recordInfo.color.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            recordInfo.icon,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildTypeBadge(isDark),
              const SizedBox(height: 8),
              _buildDateDisplay(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: recordInfo.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        recordInfo.label,
        style: TextStyle(
          color: recordInfo.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateDisplay(bool isDark) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Text(
          _dateFormat.format(record.recordDate),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _handleShare(BuildContext context) {
    final doctorSettings = ref.read(doctorSettingsProvider);
    final profile = doctorSettings.profile;
    PdfService.shareMedicalRecordPdf(
      patient: patient, 
      record: record,
      doctorName: profile.displayName,
      clinicName: profile.clinicName,
      clinicPhone: profile.clinicPhone.isNotEmpty ? profile.clinicPhone : null,
      clinicAddress: profile.clinicAddress.isNotEmpty ? profile.clinicAddress : null,
    );
  }

  void _handlePrint(BuildContext context) {
    final doctorSettings = ref.read(doctorSettingsProvider);
    final profile = doctorSettings.profile;
    PdfService.printMedicalRecordPdf(
      patient: patient, 
      record: record,
      doctorName: profile.displayName,
      clinicName: profile.clinicName,
      clinicPhone: profile.clinicPhone.isNotEmpty ? profile.clinicPhone : null,
      clinicAddress: profile.clinicAddress.isNotEmpty ? profile.clinicAddress : null,
    );
  }
}

// ============================================================================
// PATIENT CARD
// ============================================================================

class _PatientCard extends StatelessWidget {

  const _PatientCard({required this.patient, required this.isDark});
  final Patient patient;
  final bool isDark;

  String get _initials => '${patient.firstName[0]}${patient.lastName[0]}';
  String get _fullName => '${patient.firstName} ${patient.lastName}';
  int get _age => patient.age ?? 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Patient: $_fullName, $_age years old',
      child: Container(
        padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo()),
            _buildIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: MedicalRecordConstants.fontTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'ID: ${patient.id} • $_age years old',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: MedicalRecordConstants.fontBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
    );
  }
}

// ============================================================================
// RECORD CONTENT DISPATCHER
// ============================================================================

class _RecordContent extends StatelessWidget {

  const _RecordContent({
    required this.record,
    required this.data,
    required this.isDark,
  });
  final MedicalRecord record;
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    switch (record.recordType) {
      case 'pulmonary_evaluation':
        return _PulmonaryContent(data: data, isDark: isDark);
      case 'psychiatric_assessment':
        return _PsychiatricContent(data: data, isDark: isDark);
      case 'lab_result':
        return _LabResultContent(data: data, isDark: isDark);
      case 'imaging':
        return _ImagingContent(data: data, isDark: isDark);
      case 'procedure':
        return _ProcedureContent(data: data, isDark: isDark);
      case 'follow_up':
        return _FollowUpContent(data: data, isDark: isDark);
      default:
        return _GeneralContent(record: record, data: data, isDark: isDark);
    }
  }
}

// ============================================================================
// TYPE-SPECIFIC CONTENT WIDGETS
// ============================================================================

class _PulmonaryContent extends StatelessWidget {

  const _PulmonaryContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chief Complaint
        if (data.hasValue('chief_complaint'))
          InfoCard(
            title: 'Chief Complaint',
            content: data.getString('chief_complaint'),
            icon: Icons.air,
            color: MedicalRecordConstants.pulmonaryColor,
            isDark: isDark,
          ),
        // Duration
        if (data.hasValue('duration')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          StatCard(
            label: 'Duration',
            value: data.getString('duration'),
            icon: Icons.schedule,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Symptom Character (new form)
        if (data.hasValue('symptom_character')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Symptom Character',
            content: data.getString('symptom_character'),
            icon: Icons.description_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Vitals Section
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark, isPulmonary: true),
        // Presenting Symptoms (legacy format - Map<String, bool>)
        if (data.hasValue('symptoms')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Presenting Symptoms',
            items: data.getStringList('symptoms'),
            color: AppColors.primary,
            icon: Icons.sick_outlined,
            isDark: isDark,
          ),
        ],
        // Systemic Symptoms (new form - List<String>)
        if (data.hasValue('systemic_symptoms')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Systemic Symptoms',
            items: data.getStringList('systemic_symptoms'),
            color: AppColors.warning,
            icon: Icons.sick_outlined,
            isDark: isDark,
          ),
        ],
        // Red Flags (both formats - Map<String, bool> or List<String>)
        if (data.hasValue('red_flags')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Red Flags',
            items: data.getStringList('red_flags'),
            color: AppColors.error,
            icon: Icons.flag,
            isDark: isDark,
          ),
        ],
        // ====== HISTORY SECTION (new form) ======
        if (data.hasValue('past_pulmonary_history') || 
            data.hasValue('exposure_history') || 
            data.hasValue('allergy_atopy_history')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _SectionHeader(title: 'Medical History', icon: Icons.history, isDark: isDark),
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
        ],
        if (data.hasValue('past_pulmonary_history'))
          InfoCard(
            title: 'Past Pulmonary History',
            content: data.getString('past_pulmonary_history'),
            icon: Icons.history,
            color: AppColors.info,
            isDark: isDark,
          ),
        if (data.hasValue('exposure_history')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Exposure History',
            content: data.getString('exposure_history'),
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        if (data.hasValue('allergy_atopy_history')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Allergy/Atopy History',
            content: data.getString('allergy_atopy_history'),
            icon: Icons.local_florist_outlined,
            color: AppColors.error,
            isDark: isDark,
          ),
        ],
        // Current Medications (new form - List<String>)
        if (data.hasValue('current_medications')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Current Medications',
            items: data.getStringList('current_medications'),
            color: AppColors.info,
            icon: Icons.medication_outlined,
            isDark: isDark,
          ),
        ],
        // Comorbidities (new form - List<String>)
        if (data.hasValue('comorbidities')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          ChipsSection(
            title: 'Comorbidities',
            items: data.getStringList('comorbidities'),
            color: AppColors.warning,
            icon: Icons.medical_services_outlined,
            isDark: isDark,
          ),
        ],
        // ====== CHEST EXAMINATION SECTION ======
        // Chest Findings (legacy format - nested object)
        if (data.hasValue('chest_findings'))
          _ChestFindingsSection(findings: data.getMap('chest_findings'), isDark: isDark),
        // Chest Auscultation (new form - nested object with zones)
        if (data.hasValue('chest_auscultation'))
          _ChestAuscultationSection(auscultation: data.getMap('chest_auscultation'), isDark: isDark),
        // Breath Sounds (legacy format - Map<String, bool>)
        if (data.hasValue('breath_sounds')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Breath Sounds',
            items: data.getStringList('breath_sounds'),
            color: AppColors.info,
            icon: Icons.hearing,
            isDark: isDark,
          ),
        ],
        // ====== DIAGNOSIS & INVESTIGATIONS ======
        // Diagnosis
        if (data.hasValue('diagnosis')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Diagnosis',
            content: data.getString('diagnosis'),
            icon: Icons.medical_information,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Differential Diagnosis
        if (data.hasValue('differential')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Differential Diagnosis',
            content: data.getString('differential'),
            icon: Icons.compare_arrows,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Investigations (legacy format - Map<String, bool>)
        if (data.hasValue('investigations')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Investigations Ordered',
            items: data.getStringList('investigations'),
            color: AppColors.primary,
            icon: Icons.biotech,
            isDark: isDark,
          ),
        ],
        // Investigations Required (new form - List<String>)
        if (data.hasValue('investigations_required')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Investigations Required',
            items: data.getStringList('investigations_required'),
            color: AppColors.primary,
            icon: Icons.biotech,
            isDark: isDark,
          ),
        ],
        // ====== TREATMENT & FOLLOW-UP ======
        // Treatment Plan (legacy)
        if (data.hasValue('treatment_plan')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Treatment Plan',
            content: data.getString('treatment_plan'),
            icon: Icons.healing,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Medications (legacy)
        if (data.hasValue('medications')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Medications',
            content: data.getString('medications'),
            icon: Icons.medication,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Follow-up (legacy)
        if (data.hasValue('follow_up')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Follow-up Plan',
            content: data.getString('follow_up'),
            icon: Icons.event_repeat,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Follow-up Plan (new form)
        if (data.hasValue('follow_up_plan')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Follow-up Plan',
            content: data.getString('follow_up_plan'),
            icon: Icons.event_repeat,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

/// Section header for organizing content
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });
  
  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Displays chest auscultation findings from new pulmonary form
class _ChestAuscultationSection extends StatelessWidget {
  const _ChestAuscultationSection({
    required this.auscultation,
    required this.isDark,
  });
  
  final Map<String, dynamic> auscultation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (auscultation.isEmpty) return const SizedBox.shrink();
    
    final breathSounds = auscultation['breath_sounds'] as String?;
    final addedSounds = auscultation['added_sounds'];
    final additionalFindings = auscultation['additional_findings'] as String?;
    
    // Zone findings
    final zones = <String, String?>{
      'Right Upper Zone': auscultation['right_upper_zone'] as String?,
      'Right Middle Zone': auscultation['right_middle_zone'] as String?,
      'Right Lower Zone': auscultation['right_lower_zone'] as String?,
      'Left Upper Zone': auscultation['left_upper_zone'] as String?,
      'Left Middle Zone': auscultation['left_middle_zone'] as String?,
      'Left Lower Zone': auscultation['left_lower_zone'] as String?,
    };
    
    final hasZoneData = zones.values.any((v) => v != null && v.isNotEmpty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        _SectionHeader(title: 'Chest Auscultation', icon: Icons.hearing, isDark: isDark),
        const SizedBox(height: MedicalRecordConstants.paddingMedium),
        
        // Breath Sounds
        if (breathSounds != null && breathSounds.isNotEmpty)
          InfoCard(
            title: 'Breath Sounds',
            content: breathSounds,
            icon: Icons.hearing,
            color: AppColors.info,
            isDark: isDark,
          ),
        
        // Added Sounds (chips)
        if (addedSounds != null) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          ChipsSection(
            title: 'Added Sounds',
            items: addedSounds is List 
                ? List<String>.from(addedSounds)
                : [addedSounds.toString()],
            color: AppColors.warning,
            icon: Icons.volume_up,
            isDark: isDark,
          ),
        ],
        
        // Zone-by-zone findings
        if (hasZoneData) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          Container(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zone Findings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...zones.entries
                    .where((e) => e.value != null && e.value!.isNotEmpty)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 130,
                                child: Text(
                                  '${e.key}:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
          ),
        ],
        
        // Additional Findings
        if (additionalFindings != null && additionalFindings.isNotEmpty) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Additional Findings',
            content: additionalFindings,
            icon: Icons.note_add_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _PsychiatricContent extends StatelessWidget {

  const _PsychiatricContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Check if MSE fields are stored directly or nested
    final hasFlatMse = data.hasValue('mood') || data.hasValue('affect') || 
                       data.hasValue('speech') || data.hasValue('thought');
    
    return Column(
      children: [
        // Patient demographics if available
        if (data.hasValue('name') || data.hasValue('age') || data.hasValue('gender')) ...[
          Container(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              children: [
                if (data.hasValue('name'))
                  Expanded(
                    child: _buildDemoItem('Name', data.getString('name')),
                  ),
                if (data.hasValue('age'))
                  Expanded(
                    child: _buildDemoItem('Age', data.getString('age')),
                  ),
                if (data.hasValue('gender'))
                  Expanded(
                    child: _buildDemoItem('Gender', data.getString('gender')),
                  ),
                if (data.hasValue('marital_status'))
                  Expanded(
                    child: _buildDemoItem('Status', data.getString('marital_status')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
        ],
        // Chief complaint
        if (data.hasValue('chief_complaint'))
          InfoCard(
            title: 'Chief Complaint',
            content: data.getString('chief_complaint'),
            icon: Icons.assignment_outlined,
            color: AppColors.warning,
            isDark: isDark,
          ),
        // Duration
        if (data.hasValue('duration')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          StatCard(
            label: 'Duration',
            value: data.getString('duration'),
            icon: Icons.schedule,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Presenting symptoms
        if (data.hasValue('symptoms')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          if (data['symptoms'] is List)
            ChipsSection(
              title: 'Presenting Symptoms',
              items: data.getStringList('symptoms'),
              color: AppColors.primary,
              icon: Icons.sick_outlined,
              isDark: isDark,
            )
          else
            InfoCard(
              title: 'Presenting Symptoms',
              content: data.getString('symptoms'),
              icon: Icons.sick_outlined,
              color: AppColors.primary,
              isDark: isDark,
            ),
        ],
        // History of present illness
        if (data.hasValue('hopi')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'History of Present Illness',
            content: data.getString('hopi'),
            icon: Icons.history,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Past History
        if (data.hasValue('past_history')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Past Psychiatric History',
            content: data.getString('past_history'),
            icon: Icons.history_edu,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Family History
        if (data.hasValue('family_history')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Family History',
            content: data.getString('family_history'),
            icon: Icons.family_restroom,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Socioeconomic History
        if (data.hasValue('socioeconomic')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          InfoCard(
            title: 'Socioeconomic History',
            content: data.getString('socioeconomic'),
            icon: Icons.work_outline,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ],
        // Mental State Examination - Nested format
        if (data.hasValue('mse')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _MseSection(mse: data.getMap('mse'), isDark: isDark),
        ],
        // Mental State Examination - Flat format (direct fields)
        if (hasFlatMse && !data.hasValue('mse')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildFlatMseSection(),
        ],
        // Risk assessment - Nested format
        if (data.hasValue('risk_assessment')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _RiskAssessmentSection(risk: data.getMap('risk_assessment'), isDark: isDark),
        ],
        // Risk assessment - Flat format
        if ((data.hasValue('suicide_risk') || data.hasValue('homicide_risk')) && !data.hasValue('risk_assessment')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildFlatRiskSection(),
        ],
        // Safety plan
        if (data.hasValue('safety_plan')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Safety Plan',
            content: data.getString('safety_plan'),
            icon: Icons.shield_outlined,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Diagnosis
        if (data.hasValue('diagnosis')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Diagnosis',
            content: data.getString('diagnosis'),
            icon: Icons.medical_information_outlined,
            color: AppColors.error,
            isDark: isDark,
          ),
        ],
        // Treatment plan
        if (data.hasValue('treatment_plan')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Treatment Plan',
            content: data.getString('treatment_plan'),
            icon: Icons.healing_outlined,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Medications
        if (data.hasValue('medications')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Medications',
            content: data.getString('medications'),
            icon: Icons.medication_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ],
        // Follow-up
        if (data.hasValue('follow_up')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Follow-up Plan',
            content: data.getString('follow_up'),
            icon: Icons.event_repeat,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Vitals
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }
  
  Widget _buildDemoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: MedicalRecordConstants.fontSmall,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: MedicalRecordConstants.fontBody,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFlatMseSection() {
    final mseFields = [
      ('Mood', data.getString('mood'), Icons.mood),
      ('Affect', data.getString('affect'), Icons.sentiment_satisfied_alt),
      ('Speech', data.getString('speech'), Icons.record_voice_over),
      ('Thought', data.getString('thought'), Icons.psychology),
      ('Perception', data.getString('perception'), Icons.visibility),
      ('Cognition', data.getString('cognition'), Icons.memory),
      ('Insight', data.getString('insight'), Icons.lightbulb_outline),
    ].where((f) => f.$2.isNotEmpty).toList();
    
    if (mseFields.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              size: MedicalRecordConstants.iconMedium,
              color: AppColors.primary,
            ),
            const SizedBox(width: MedicalRecordConstants.paddingSmall),
            Text(
              'Mental State Examination',
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontLarge,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: MedicalRecordConstants.paddingMedium),
        ...mseFields.map((field) => Padding(
          padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingSmall),
          child: Container(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(field.$3, size: MedicalRecordConstants.iconSmall, color: AppColors.primary),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.$1,
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        field.$2,
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontBody,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildFlatRiskSection() {
    final suicideRisk = data.getString('suicide_risk');
    final homicideRisk = data.getString('homicide_risk');
    
    Color getRiskColor(String risk) {
      switch (risk.toLowerCase()) {
        case 'high':
          return AppColors.error;
        case 'moderate':
        case 'medium':
          return AppColors.warning;
        case 'low':
          return AppColors.success;
        default:
          return AppColors.info;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: MedicalRecordConstants.iconMedium,
              color: AppColors.error,
            ),
            const SizedBox(width: MedicalRecordConstants.paddingSmall),
            Text(
              'Risk Assessment',
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontLarge,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: MedicalRecordConstants.paddingMedium),
        Row(
          children: [
            if (suicideRisk.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: getRiskColor(suicideRisk).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
                    border: Border.all(color: getRiskColor(suicideRisk).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_off, color: getRiskColor(suicideRisk)),
                      const SizedBox(height: 8),
                      Text(
                        'Suicide Risk',
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontSmall,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suicideRisk.toUpperCase(),
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontLarge,
                          fontWeight: FontWeight.bold,
                          color: getRiskColor(suicideRisk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (suicideRisk.isNotEmpty && homicideRisk.isNotEmpty)
              const SizedBox(width: MedicalRecordConstants.paddingMedium),
            if (homicideRisk.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: getRiskColor(homicideRisk).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
                    border: Border.all(color: getRiskColor(homicideRisk).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.dangerous, color: getRiskColor(homicideRisk)),
                      const SizedBox(height: 8),
                      Text(
                        'Homicide Risk',
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontSmall,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        homicideRisk.toUpperCase(),
                        style: TextStyle(
                          fontSize: MedicalRecordConstants.fontLarge,
                          fontWeight: FontWeight.bold,
                          color: getRiskColor(homicideRisk),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LabResultContent extends StatelessWidget {

  const _LabResultContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main result card
        Container(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              _buildResult(),
              if (data.hasValue('units')) ...[
                const SizedBox(height: MedicalRecordConstants.paddingSmall),
                Text(
                  'Units: ${data.getString('units')}',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
              if (data.hasValue('reference_range')) ...[
                const SizedBox(height: MedicalRecordConstants.paddingMedium),
                _buildReferenceRange(),
              ],
              if (data.hasValue('result_status')) ...[
                const SizedBox(height: MedicalRecordConstants.paddingMedium),
                _buildResultStatus(),
              ],
            ],
          ),
        ),
        // Additional info cards
        if (data.hasValue('test_category')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildInfoRow(Icons.category_outlined, 'Test Category', data.getString('test_category')),
        ],
        if (data.hasValue('specimen')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _buildInfoRow(Icons.science_outlined, 'Specimen', data.getString('specimen')),
        ],
        if (data.hasValue('lab_name')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _buildInfoRow(Icons.local_hospital_outlined, 'Laboratory', data.getString('lab_name')),
        ],
        if (data.hasValue('ordering_physician')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _buildInfoRow(Icons.person_outline, 'Ordering Physician', data.getString('ordering_physician')),
        ],
        if (data.hasValue('interpretation')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Interpretation',
            content: data.getString('interpretation'),
            icon: Icons.analytics_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: MedicalRecordConstants.iconMedium, color: AppColors.primary),
          const SizedBox(width: MedicalRecordConstants.paddingMedium),
          Text(
            label,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontLarge,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatus() {
    final status = data.getString('result_status');
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'normal':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
      case 'abnormal':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber_outlined;
      case 'critical':
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedicalRecordConstants.paddingMedium,
        vertical: MedicalRecordConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: MedicalRecordConstants.iconSmall, color: statusColor),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Text(
            status,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.science_outlined, color: AppColors.warning, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        Expanded(
          child: Text(
            data.getString('test_name').isEmpty ? 'Lab Test' : data.getString('test_name'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result',
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.getString('result').isEmpty ? 'N/A' : data.getString('result'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceRange() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten, size: MedicalRecordConstants.iconLarge, color: AppColors.info),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Text(
            'Reference: ${data.getString('reference_range')}',
            style: const TextStyle(
              color: AppColors.info,
              fontSize: MedicalRecordConstants.fontMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagingContent extends StatelessWidget {

  const _ImagingContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Imaging type and body part
        if (data.hasValue('imaging_type') || data.hasValue('body_part'))
          _buildHeaderCard(),
        // Urgency badge
        if (data.hasValue('urgency')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _buildUrgencyBadge(),
        ],
        // Indication
        if (data.hasValue('indication')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Indication',
            content: data.getString('indication'),
            icon: Icons.help_outline,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Technique
        if (data.hasValue('technique')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Technique',
            content: data.getString('technique'),
            icon: Icons.settings_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Contrast used
        if (data.hasValue('contrast_used') && data['contrast_used'] == true) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MedicalRecordConstants.paddingMedium,
              vertical: MedicalRecordConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.contrast, size: MedicalRecordConstants.iconSmall, color: AppColors.warning),
                SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  'Contrast Used',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Findings
        if (data.hasValue('findings')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Findings',
            content: data.getString('findings'),
            icon: Icons.find_in_page_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ],
        // Impression
        if (data.hasValue('impression')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Impression',
            content: data.getString('impression'),
            icon: Icons.summarize_outlined,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Recommendations
        if (data.hasValue('recommendations')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Recommendations',
            content: data.getString('recommendations'),
            icon: Icons.recommend_outlined,
            color: AppColors.accent,
            isDark: isDark,
          ),
        ],
        // Radiologist & Facility
        if (data.hasValue('radiologist') || data.hasValue('facility')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildProviderInfo(),
        ],
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
            ),
            child: const Icon(Icons.image_search_outlined, color: AppColors.info, size: 28),
          ),
          const SizedBox(width: MedicalRecordConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.hasValue('imaging_type'))
                  Text(
                    data.getString('imaging_type'),
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontTitle,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                if (data.hasValue('body_part'))
                  Text(
                    data.getString('body_part'),
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontLarge,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    final urgency = data.getString('urgency');
    Color urgencyColor;
    
    switch (urgency.toLowerCase()) {
      case 'stat':
      case 'emergency':
        urgencyColor = AppColors.error;
      case 'urgent':
        urgencyColor = AppColors.warning;
      default:
        urgencyColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MedicalRecordConstants.paddingMedium,
        vertical: MedicalRecordConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: MedicalRecordConstants.iconSmall, color: urgencyColor),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Text(
            urgency,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody,
              fontWeight: FontWeight.w600,
              color: urgencyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        children: [
          if (data.hasValue('radiologist'))
            Row(
              children: [
                const Icon(Icons.person_outline, size: MedicalRecordConstants.iconMedium, color: AppColors.primary),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  'Radiologist:',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  data.getString('radiologist'),
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontLarge,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          if (data.hasValue('radiologist') && data.hasValue('facility'))
            const Divider(height: MedicalRecordConstants.paddingLarge),
          if (data.hasValue('facility'))
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: MedicalRecordConstants.iconMedium, color: AppColors.info),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  'Facility:',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    data.getString('facility'),
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontLarge,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProcedureContent extends StatelessWidget {

  const _ProcedureContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Procedure header with name and code
        if (data.hasValue('procedure_name'))
          _buildHeaderCard(),
        // Status and timing
        if (data.hasValue('procedure_status') || data.hasValue('start_time') || data.hasValue('end_time')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _buildStatusTimingRow(),
        ],
        // Indication
        if (data.hasValue('indication')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Indication',
            content: data.getString('indication'),
            icon: Icons.help_outline,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Anesthesia
        if (data.hasValue('anesthesia')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Anesthesia',
            content: data.getString('anesthesia'),
            icon: Icons.medication_liquid_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Procedure notes
        if (data.hasValue('procedure_notes')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Procedure Notes',
            content: data.getString('procedure_notes'),
            icon: Icons.note_alt_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ],
        // Findings
        if (data.hasValue('findings')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Findings',
            content: data.getString('findings'),
            icon: Icons.search,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Complications
        if (data.hasValue('complications')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Complications',
            content: data.getString('complications'),
            icon: Icons.warning_amber_outlined,
            color: AppColors.error,
            isDark: isDark,
          ),
        ],
        // Specimen
        if (data.hasValue('specimen')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Specimen Collected',
            content: data.getString('specimen'),
            icon: Icons.science_outlined,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Post-op instructions
        if (data.hasValue('post_op_instructions')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Post-Operative Instructions',
            content: data.getString('post_op_instructions'),
            icon: Icons.assignment_outlined,
            color: AppColors.accent,
            isDark: isDark,
          ),
        ],
        // Providers
        if (data.hasValue('performed_by') || data.hasValue('assisted_by')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildProvidersCard(),
        ],
        // Vitals (pre/post procedure)
        if (data.hasValue('vitals'))
          _ProcedureVitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
            ),
            child: const Icon(Icons.healing_outlined, color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: MedicalRecordConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.getString('procedure_name'),
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                if (data.hasValue('procedure_code'))
                  Text(
                    'Code: ${data.getString('procedure_code')}',
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontBody,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimingRow() {
    final status = data.getString('procedure_status');
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
      case 'in progress':
        statusColor = AppColors.warning;
      case 'cancelled':
        statusColor = AppColors.error;
      default:
        statusColor = AppColors.info;
    }

    return Wrap(
      spacing: MedicalRecordConstants.paddingSmall,
      runSpacing: MedicalRecordConstants.paddingSmall,
      children: [
        if (data.hasValue('procedure_status'))
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MedicalRecordConstants.paddingMedium,
              vertical: MedicalRecordConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontBody,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        if (data.hasValue('start_time'))
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MedicalRecordConstants.paddingMedium,
              vertical: MedicalRecordConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: MedicalRecordConstants.iconSmall, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Start: ${data.getString('start_time')}',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        if (data.hasValue('end_time'))
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MedicalRecordConstants.paddingMedium,
              vertical: MedicalRecordConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stop, size: MedicalRecordConstants.iconSmall, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  'End: ${data.getString('end_time')}',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProvidersCard() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        children: [
          if (data.hasValue('performed_by'))
            Row(
              children: [
                const Icon(Icons.person, size: MedicalRecordConstants.iconMedium, color: AppColors.primary),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  'Performed by:',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  data.getString('performed_by'),
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontLarge,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          if (data.hasValue('performed_by') && data.hasValue('assisted_by'))
            const Divider(height: MedicalRecordConstants.paddingLarge),
          if (data.hasValue('assisted_by'))
            Row(
              children: [
                const Icon(Icons.group, size: MedicalRecordConstants.iconMedium, color: AppColors.info),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  'Assisted by:',
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    data.getString('assisted_by'),
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontLarge,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Special vitals section for procedures showing pre/post comparison
class _ProcedureVitalsSection extends StatelessWidget {
  const _ProcedureVitalsSection({required this.vitals, required this.isDark});
  final Map<String, dynamic> vitals;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasPre = vitals['bp_pre'] != null || vitals['pulse_pre'] != null || vitals['spo2_pre'] != null;
    final hasPost = vitals['bp_post'] != null || vitals['pulse_post'] != null || vitals['spo2_post'] != null;
    
    if (!hasPre && !hasPost) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        Container(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(MedicalRecordConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
                    ),
                    child: const Icon(Icons.monitor_heart_outlined, color: AppColors.error, size: MedicalRecordConstants.iconLarge),
                  ),
                  const SizedBox(width: MedicalRecordConstants.paddingMedium),
                  Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontSize: MedicalRecordConstants.fontTitle,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              Row(
                children: [
                  if (hasPre)
                    Expanded(child: _buildVitalsColumn('Pre-Procedure', 'pre')),
                  if (hasPre && hasPost)
                    Container(
                      width: 1,
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: MedicalRecordConstants.paddingMedium),
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  if (hasPost)
                    Expanded(child: _buildVitalsColumn('Post-Procedure', 'post')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsColumn(String title, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: MedicalRecordConstants.fontBody,
            fontWeight: FontWeight.w600,
            color: suffix == 'pre' ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(height: MedicalRecordConstants.paddingSmall),
        if (vitals['bp_$suffix'] != null)
          _buildVitalRow('BP', vitals['bp_$suffix'].toString(), 'mmHg'),
        if (vitals['pulse_$suffix'] != null)
          _buildVitalRow('Pulse', vitals['pulse_$suffix'].toString(), 'bpm'),
        if (vitals['spo2_$suffix'] != null)
          _buildVitalRow('SpO2', vitals['spo2_$suffix'].toString(), '%'),
      ],
    );
  }

  Widget _buildVitalRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontLarge,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}class _FollowUpContent extends StatelessWidget {

  const _FollowUpContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress notes / follow_up_notes (support both keys)
        if (data.hasValue('progress_notes') || data.hasValue('follow_up_notes'))
          InfoCard(
            title: 'Progress Notes',
            content: data.getString('progress_notes').isNotEmpty 
                ? data.getString('progress_notes') 
                : data.getString('follow_up_notes'),
            icon: Icons.note_alt_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
        // Current symptoms
        if (data.hasValue('symptoms')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Current Symptoms',
            content: data.getString('symptoms'),
            icon: Icons.sick_outlined,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        // Overall progress
        if (data.hasValue('overall_progress')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          _ProgressIndicator(progress: data.getString('overall_progress'), isDark: isDark),
        ],
        // Medication compliance
        if (data.hasValue('compliance')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Medication Compliance',
            content: data.getString('compliance'),
            icon: Icons.medication_outlined,
            color: AppColors.success,
            isDark: isDark,
          ),
        ],
        // Side effects
        if (data.hasValue('side_effects')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Side Effects Reported',
            content: data.getString('side_effects'),
            icon: Icons.warning_amber_outlined,
            color: AppColors.error,
            isDark: isDark,
          ),
        ],
        // Medication review
        if (data.hasValue('medication_review')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Medication Review',
            content: data.getString('medication_review'),
            icon: Icons.medical_services_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        // Investigations
        if (data.hasValue('investigations')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Investigations',
            content: data.getString('investigations'),
            icon: Icons.biotech,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ],
        // Next follow-up info
        if (data.hasValue('next_follow_up_notes') || data.hasValue('next_follow_up_date')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _NextFollowUpCard(data: data, isDark: isDark),
        ],
        // Vitals section
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }
}

/// Widget that displays ALL data stored in the record as a summary
/// This ensures no data is hidden from the user
class _AllDataSection extends StatelessWidget {
  const _AllDataSection({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  // Keys that are already displayed by type-specific widgets
  static const _displayedKeys = {
    // Common
    'vitals',
    // Pulmonary
    'chief_complaint', 'duration', 'symptom_character', 'systemic_symptoms',
    'red_flags', 'past_pulmonary_history', 'exposure_history', 
    'allergy_atopy_history', 'current_medications', 'comorbidities',
    'chest_auscultation', 'investigations_required', 'follow_up_plan',
    // Psychiatric
    'name', 'age', 'gender', 'marital_status', 'symptoms', 'hopi',
    'mse', 'mood', 'affect', 'speech', 'thought', 'perception', 'cognition',
    'insight', 'risk_assessment', 'suicide_risk', 'homicide_risk', 
    'safety_plan', 'diagnosis', 'treatment_plan', 'medications', 'follow_up',
    // Lab
    'test_name', 'test_category', 'result', 'reference_range', 'units',
    'specimen', 'lab_name', 'ordering_physician', 'interpretation', 'result_status',
    // Imaging
    'imaging_type', 'body_part', 'indication', 'technique', 'findings',
    'impression', 'recommendations', 'radiologist', 'facility', 'contrast_used', 'urgency',
    // Procedure
    'procedure_name', 'procedure_code', 'anesthesia', 'procedure_notes',
    'complications', 'post_op_instructions', 'performed_by', 'assisted_by',
    'procedure_status', 'start_time', 'end_time',
    // Follow-up
    'progress_notes', 'follow_up_notes', 'compliance', 'side_effects',
    'medication_review', 'investigations', 'overall_progress', 
    'next_follow_up_date', 'next_follow_up_notes',
  };

  @override
  Widget build(BuildContext context) {
    // Find any keys that aren't already displayed
    final additionalData = <String, dynamic>{};
    for (final entry in data.entries) {
      if (!_displayedKeys.contains(entry.key) && 
          entry.value != null &&
          !(entry.value is String && (entry.value as String).isEmpty) &&
          !(entry.value is List && (entry.value as List).isEmpty) &&
          !(entry.value is Map && (entry.value as Map).isEmpty)) {
        additionalData[entry.key] = entry.value;
      }
    }

    if (additionalData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        Row(
          children: [
            Icon(
              Icons.data_object,
              size: MedicalRecordConstants.iconMedium,
              color: AppColors.info,
            ),
            const SizedBox(width: MedicalRecordConstants.paddingSmall),
            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontLarge,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: MedicalRecordConstants.paddingMedium),
        ...additionalData.entries.map((entry) {
          final title = _formatKey(entry.key);
          final value = entry.value;
          
          if (value is Map) {
            final mapContent = (value as Map<String, dynamic>).entries
                .where((e) => e.value != null && e.value.toString().isNotEmpty)
                .map((e) => '${_formatKey(e.key)}: ${e.value}')
                .join('\n');
            if (mapContent.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingMedium),
              child: InfoCard(
                title: title,
                content: mapContent,
                icon: Icons.info_outline,
                color: AppColors.info,
                isDark: isDark,
              ),
            );
          } else if (value is List) {
            final listItems = value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
            if (listItems.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingMedium),
              child: ChipsSection(
                title: title,
                items: listItems,
                color: AppColors.info,
                icon: Icons.list,
                isDark: isDark,
              ),
            );
          } else {
            final content = value.toString();
            if (content.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingMedium),
              child: InfoCard(
                title: title,
                content: content,
                icon: Icons.info_outline,
                color: AppColors.info,
                isDark: isDark,
              ),
            );
          }
        }),
      ],
    );
  }
  
  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ')
        .trim();
  }
}

class _GeneralContent extends StatelessWidget {

  const _GeneralContent({required this.record, required this.data, required this.isDark});
  final MedicalRecord record;
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Build widgets for all data fields dynamically
    final dataWidgets = <Widget>[];
    
    // First show description if available
    if (record.description.isNotEmpty) {
      dataWidgets.add(
        InfoCard(
          title: 'Description',
          content: record.description,
          icon: Icons.description_outlined,
          color: AppColors.info,
          isDark: isDark,
        ),
      );
    }
    
    // Then show all data from JSON
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Skip empty values and vitals (handled separately)
      if (value == null || key == 'vitals') continue;
      if (value is String && value.isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      if (value is Map && value.isEmpty) continue;
      
      // Format the key as a readable title
      final title = _formatKey(key);
      
      // Handle different value types
      if (value is Map) {
        // Show map as formatted key-value pairs
        final mapContent = (value as Map<String, dynamic>).entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .map((e) => '${_formatKey(e.key)}: ${e.value}')
            .join('\n');
        if (mapContent.isNotEmpty) {
          dataWidgets.add(const SizedBox(height: MedicalRecordConstants.paddingLarge));
          dataWidgets.add(
            InfoCard(
              title: title,
              content: mapContent,
              icon: _getIconForKey(key),
              color: _getColorForKey(key),
              isDark: isDark,
            ),
          );
        }
      } else if (value is List) {
        // Show list as chips or comma-separated
        final listItems = value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        if (listItems.isNotEmpty) {
          dataWidgets.add(const SizedBox(height: MedicalRecordConstants.paddingLarge));
          dataWidgets.add(
            ChipsSection(
              title: title,
              items: listItems,
              color: _getColorForKey(key),
              icon: _getIconForKey(key),
              isDark: isDark,
            ),
          );
        }
      } else {
        // Show as text
        final content = value.toString();
        if (content.isNotEmpty) {
          dataWidgets.add(const SizedBox(height: MedicalRecordConstants.paddingLarge));
          dataWidgets.add(
            InfoCard(
              title: title,
              content: content,
              icon: _getIconForKey(key),
              color: _getColorForKey(key),
              isDark: isDark,
            ),
          );
        }
      }
    }
    
    // Add vitals section at the end if available
    if (data.hasValue('vitals')) {
      dataWidgets.add(_VitalsSection(vitals: data.getMap('vitals'), isDark: isDark));
    }
    
    return Column(children: dataWidgets);
  }
  
  String _formatKey(String key) {
    // Convert snake_case or camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ')
        .trim();
  }
  
  IconData _getIconForKey(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('complaint') || lowerKey.contains('symptom')) return Icons.sick_outlined;
    if (lowerKey.contains('history')) return Icons.history;
    if (lowerKey.contains('diagnosis')) return Icons.medical_information_outlined;
    if (lowerKey.contains('treatment') || lowerKey.contains('plan')) return Icons.healing_outlined;
    if (lowerKey.contains('medication') || lowerKey.contains('drug')) return Icons.medication_outlined;
    if (lowerKey.contains('note')) return Icons.note_alt_outlined;
    if (lowerKey.contains('exam') || lowerKey.contains('finding')) return Icons.search;
    if (lowerKey.contains('investigation') || lowerKey.contains('test') || lowerKey.contains('lab')) return Icons.biotech;
    if (lowerKey.contains('risk')) return Icons.warning_amber;
    if (lowerKey.contains('follow')) return Icons.event_repeat;
    if (lowerKey.contains('mood') || lowerKey.contains('affect') || lowerKey.contains('mental')) return Icons.psychology;
    return Icons.info_outline;
  }
  
  Color _getColorForKey(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('complaint') || lowerKey.contains('symptom')) return AppColors.warning;
    if (lowerKey.contains('diagnosis')) return AppColors.error;
    if (lowerKey.contains('treatment') || lowerKey.contains('plan')) return AppColors.success;
    if (lowerKey.contains('risk') || lowerKey.contains('warning')) return AppColors.error;
    if (lowerKey.contains('investigation') || lowerKey.contains('test')) return AppColors.primary;
    return AppColors.info;
  }
}

// ============================================================================
// SPECIALIZED SECTIONS
// ============================================================================

/// Progress indicator for follow-up records
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress, required this.isDark});
  final String progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    IconData progressIcon;
    
    switch (progress.toLowerCase()) {
      case 'improved':
        progressColor = AppColors.success;
        progressIcon = Icons.trending_up;
      case 'stable':
        progressColor = AppColors.info;
        progressIcon = Icons.trending_flat;
      case 'worsened':
        progressColor = AppColors.error;
        progressIcon = Icons.trending_down;
      default:
        progressColor = AppColors.warning;
        progressIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: progressColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingMedium),
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
            ),
            child: Icon(progressIcon, color: progressColor, size: 24),
          ),
          const SizedBox(width: MedicalRecordConstants.paddingLarge),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: MedicalRecordConstants.fontBody,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress,
                style: TextStyle(
                  fontSize: MedicalRecordConstants.fontTitle,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card showing next follow-up information
class _NextFollowUpCard extends StatelessWidget {
  const _NextFollowUpCard({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateStr = data.getString('next_follow_up_date');
    final notes = data.getString('next_follow_up_notes');
    
    DateTime? nextDate;
    if (dateStr.isNotEmpty) {
      try {
        nextDate = DateTime.parse(dateStr);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MedicalRecordConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
                ),
                child: const Icon(Icons.event_repeat, color: AppColors.success, size: MedicalRecordConstants.iconLarge),
              ),
              const SizedBox(width: MedicalRecordConstants.paddingMedium),
              Text(
                'Next Follow-up',
                style: TextStyle(
                  fontSize: MedicalRecordConstants.fontTitle,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (nextDate != null) ...[
            const SizedBox(height: MedicalRecordConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MedicalRecordConstants.paddingMedium,
                vertical: MedicalRecordConstants.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
              ),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(nextDate),
                style: const TextStyle(
                  fontSize: MedicalRecordConstants.fontLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: MedicalRecordConstants.paddingMedium),
            Text(
              notes,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontLarge,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalsSection extends StatelessWidget {

  const _VitalsSection({
    required this.vitals,
    required this.isDark,
    this.isPulmonary = false,
  });
  final Map<String, dynamic> vitals;
  final bool isDark;
  final bool isPulmonary;

  @override
  Widget build(BuildContext context) {
    final vitalWidgets = _buildVitalWidgets();
    if (vitalWidgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        Container(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              Wrap(
                spacing: MedicalRecordConstants.paddingMedium,
                runSpacing: MedicalRecordConstants.paddingMedium,
                children: vitalWidgets,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite_border, color: AppColors.error, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        const Text(
          'Vital Signs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
        ),
      ],
    );
  }

  List<Widget> _buildVitalWidgets() {
    final widgets = <Widget>[];

    if (vitals.hasValue('bp')) {
      widgets.add(VitalItem(label: 'BP', value: vitals.getString('bp'), unit: 'mmHg', icon: Icons.favorite, color: AppColors.error));
    }
    if (vitals.hasValue('pulse')) {
      widgets.add(VitalItem(label: 'Pulse', value: vitals.getString('pulse'), unit: 'bpm', icon: Icons.monitor_heart, color: AppColors.error));
    }
    if (vitals.hasValue('temperature')) {
      widgets.add(VitalItem(label: 'Temp', value: vitals.getString('temperature'), unit: '°F', icon: Icons.thermostat, color: AppColors.warning));
    }
    if (isPulmonary) {
      if (vitals.hasValue('respiratory_rate')) {
        widgets.add(VitalItem(label: 'RR', value: vitals.getString('respiratory_rate'), unit: '/min', icon: Icons.air, color: MedicalRecordConstants.pulmonaryColor));
      }
      if (vitals.hasValue('spo2')) {
        widgets.add(VitalItem(label: 'SpO₂', value: vitals.getString('spo2'), unit: '%', icon: Icons.bloodtype, color: AppColors.info));
      }
      if (vitals.hasValue('peak_flow_rate')) {
        widgets.add(VitalItem(label: 'PEFR', value: vitals.getString('peak_flow_rate'), unit: 'L/min', icon: Icons.speed, color: AppColors.primary));
      }
    }
    if (vitals.hasValue('weight')) {
      widgets.add(VitalItem(label: 'Weight', value: vitals.getString('weight'), unit: 'kg', icon: Icons.monitor_weight, color: AppColors.accent));
    }

    return widgets;
  }
}

class _MseSection extends StatelessWidget {

  const _MseSection({required this.mse, required this.isDark});
  final Map<String, dynamic> mse;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final validItems = MseItemConfig.allItems.where((item) => mse.hasValue(item.key)).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _buildGrid(validItems),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.psychology, color: AppColors.primary, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        const Text(
          'Mental State Examination',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
        ),
      ],
    );
  }

  Widget _buildGrid(List<MseItemConfig> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: MedicalRecordConstants.paddingSmall,
        crossAxisSpacing: MedicalRecordConstants.paddingSmall,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MseGridItem(
          config: item,
          value: mse.getString(item.key),
          isDark: isDark,
        );
      },
    );
  }
}

class _MseGridItem extends StatelessWidget {

  const _MseGridItem({
    required this.config,
    required this.value,
    required this.isDark,
  });
  final MseItemConfig config;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(config.icon, size: MedicalRecordConstants.fontTitle, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontSmall,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: MedicalRecordConstants.fontBody,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAssessmentSection extends StatelessWidget {

  const _RiskAssessmentSection({required this.risk, required this.isDark});
  final Map<String, dynamic> risk;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final suicidalRisk = risk.getString('suicidal_risk').isEmpty ? 'None' : risk.getString('suicidal_risk');
    final homicidalRisk = risk.getString('homicidal_risk').isEmpty ? 'None' : risk.getString('homicidal_risk');
    final notes = risk.getString('notes');

    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          Row(
            children: [
              Expanded(child: RiskBadge(label: 'Suicidal Risk', level: suicidalRisk)),
              const SizedBox(width: MedicalRecordConstants.paddingMedium),
              Expanded(child: RiskBadge(label: 'Homicidal Risk', level: homicidalRisk)),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: MedicalRecordConstants.paddingMedium),
            Text(
              notes,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontMedium,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        const Text(
          'Risk Assessment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
        ),
      ],
    );
  }
}

// Chest Findings Section for Pulmonary Evaluation
class _ChestFindingsSection extends StatelessWidget {
  const _ChestFindingsSection({required this.findings, required this.isDark});
  final Map<String, dynamic> findings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Filter non-empty findings
    final nonEmptyFindings = findings.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    
    if (nonEmptyFindings.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: MedicalRecordConstants.paddingLarge),
        Container(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: MedicalRecordConstants.pulmonaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.air, color: MedicalRecordConstants.pulmonaryColor, size: MedicalRecordConstants.iconLarge),
                  ),
                  const SizedBox(width: MedicalRecordConstants.paddingMedium),
                  const Text(
                    'Chest Examination',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
                  ),
                ],
              ),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              ...nonEmptyFindings.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: MedicalRecordConstants.fontMedium,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: MedicalRecordConstants.fontMedium,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _LungZonesDisplay extends StatelessWidget {

  const _LungZonesDisplay({required this.auscultation, required this.isDark});
  final Map<String, dynamic> auscultation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            'Zone-wise Findings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: MedicalRecordConstants.fontLarge,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          Row(
            children: [
              Expanded(child: _buildLungColumn('RIGHT', ['right_upper_zone', 'right_middle_zone', 'right_lower_zone'])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MedicalRecordConstants.paddingSmall),
                child: Icon(
                  Icons.air,
                  size: 40,
                  color: MedicalRecordConstants.pulmonaryColor.withValues(alpha: 0.3),
                ),
              ),
              Expanded(child: _buildLungColumn('LEFT', ['left_upper_zone', 'left_middle_zone', 'left_lower_zone'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLungColumn(String side, List<String> zones) {
    final zoneLabels = ['Upper', 'Middle', 'Lower'];
    return Column(
      children: [
        Text(side, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontBody)),
        const SizedBox(height: MedicalRecordConstants.paddingSmall),
        ...zones.asMap().entries.map((entry) {
          final finding = auscultation.getString(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _ZoneBox(zone: zoneLabels[entry.key], finding: finding.isEmpty ? '-' : finding, isDark: isDark),
          );
        }),
      ],
    );
  }
}

class _ZoneBox extends StatelessWidget {

  const _ZoneBox({required this.zone, required this.finding, required this.isDark});
  final String zone;
  final String finding;
  final bool isDark;

  bool get _hasValue => finding.isNotEmpty && finding != '-';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingSmall),
      decoration: BoxDecoration(
        color: _hasValue
            ? MedicalRecordConstants.pulmonaryColor.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
        border: Border.all(
          color: _hasValue ? MedicalRecordConstants.pulmonaryColor.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            zone,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontSmall,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            finding,
            style: TextStyle(
              fontSize: MedicalRecordConstants.fontBody - 1,
              fontWeight: _hasValue ? FontWeight.w600 : FontWeight.normal,
              color: _hasValue
                  ? MedicalRecordConstants.pulmonaryColor
                  : (isDark ? AppColors.darkTextHint : AppColors.textHint),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTONS
// ============================================================================

class _ActionButtons extends StatelessWidget {

  const _ActionButtons({
    required this.record,
    required this.patient,
    required this.isDark,
    required this.ref,
  });
  final MedicalRecord record;
  final Patient patient;
  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppButton.gradient(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: () => _handleEdit(context),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withBlue(200)],
              ),
            ),
          ),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: IconButton(
            onPressed: () => _handleDelete(context),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete record',
          ),
        ),
      ],
    );
  }

  void _handleEdit(BuildContext context) {
    Widget targetScreen;
    
    // Route to the appropriate edit screen based on record type
    switch (record.recordType) {
      case 'general':
        targetScreen = AddGeneralRecordScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      case 'pulmonary_evaluation':
        targetScreen = AddPulmonaryScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      case 'lab_result':
        targetScreen = AddLabResultScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      case 'imaging':
        targetScreen = AddImagingScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      case 'procedure':
        targetScreen = AddProcedureScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      case 'follow_up':
        targetScreen = AddFollowUpScreen(
          preselectedPatient: patient,
          existingRecord: record,
        );
      default:
        // For psychiatric and other types, navigate to selection screen
        targetScreen = SelectRecordTypeScreen(preselectedPatient: patient);
    }
    
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _handleDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final db = await ref.read(doctorDbProvider.future);
                await db.deleteMedicalRecord(record.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Record deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Go back to previous screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete record: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

