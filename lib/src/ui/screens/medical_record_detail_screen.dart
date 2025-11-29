import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';
import '../widgets/medical_record_widgets.dart';

/// A modern, accessible medical record detail screen
/// 
/// Displays comprehensive medical record information with:
/// - Type-specific content rendering (pulmonary, psychiatric, etc.)
/// - Modern gradient header design
/// - Accessible semantic labels
/// - Dark mode support
class MedicalRecordDetailScreen extends StatelessWidget {

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recordInfo = RecordTypeInfo.fromType(record.recordType);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(record: record, patient: patient, recordInfo: recordInfo)),
          SliverPadding(
            padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PatientCard(patient: patient, isDark: isDark),
                const SizedBox(height: MedicalRecordConstants.paddingLarge),
                _RecordContent(record: record, data: _data, isDark: isDark),
                ..._buildCommonSections(isDark),
                const SizedBox(height: 32),
                _ActionButtons(isDark: isDark),
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
  });
  final MedicalRecord record;
  final Patient patient;
  final RecordTypeInfo recordInfo;

  static final _dateFormat = DateFormat('EEEE, MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [recordInfo.color, recordInfo.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(MedicalRecordConstants.radiusHeader),
          bottomRight: Radius.circular(MedicalRecordConstants.radiusHeader),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              const SizedBox(height: 24),
              _buildRecordIcon(),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              _buildTitle(),
              const SizedBox(height: MedicalRecordConstants.paddingSmall),
              _buildMetadata(),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.pop(context),
          semanticLabel: 'Go back',
        ),
        const Spacer(),
        HeaderIconButton(
          icon: Icons.share_outlined,
          onTap: () => _handleShare(context),
          semanticLabel: 'Share record',
        ),
        const SizedBox(width: MedicalRecordConstants.paddingSmall),
        HeaderIconButton(
          icon: Icons.print_outlined,
          onTap: () => _handlePrint(context),
          semanticLabel: 'Print record',
        ),
      ],
    );
  }

  Widget _buildRecordIcon() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
      ),
      child: Icon(recordInfo.icon, size: MedicalRecordConstants.iconHeader, color: Colors.white),
    );
  }

  Widget _buildTitle() {
    return Semantics(
      header: true,
      child: Text(
        record.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: MedicalRecordConstants.fontXLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        _buildTypeBadge(),
        const Spacer(),
        _buildDateDisplay(),
      ],
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
      ),
      child: Text(
        recordInfo.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: MedicalRecordConstants.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          color: Colors.white.withValues(alpha: 0.8),
          size: MedicalRecordConstants.iconSmall,
        ),
        const SizedBox(width: 6),
        Text(
          _dateFormat.format(record.recordDate),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: MedicalRecordConstants.fontMedium,
          ),
        ),
      ],
    );
  }

  void _handleShare(BuildContext context) {
    // TODO(developer): Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _handlePrint(BuildContext context) {
    // TODO(developer): Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print feature coming soon')),
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
  int get _age => patient.dateOfBirth?.ageInYears ?? 0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Patient: $_fullName, $_age years old',
      child: Container(
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
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
            fontSize: MedicalRecordConstants.fontTitle,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${patient.id} • $_age years old',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: MedicalRecordConstants.fontMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person, color: AppColors.primary, size: MedicalRecordConstants.iconLarge),
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
        if (data.hasValue('chief_complaint'))
          InfoCard(
            title: 'Chief Complaint',
            content: data.getString('chief_complaint'),
            icon: Icons.air,
            color: MedicalRecordConstants.pulmonaryColor,
            isDark: isDark,
          ),
        if (data.hasValue('duration') || data.hasValue('symptom_character')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingMedium),
          Row(
            children: [
              if (data.hasValue('duration'))
                Expanded(
                  child: StatCard(
                    label: 'Duration',
                    value: data.getString('duration'),
                    icon: Icons.schedule,
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                ),
              if (data.hasValue('duration') && data.hasValue('symptom_character'))
                const SizedBox(width: MedicalRecordConstants.paddingMedium),
              if (data.hasValue('symptom_character'))
                Expanded(
                  child: StatCard(
                    label: 'Character',
                    value: data.getString('symptom_character'),
                    icon: Icons.description,
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark, isPulmonary: true),
        if (data.hasValue('systemic_symptoms')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Systemic Symptoms',
            items: data.getStringList('systemic_symptoms'),
            color: AppColors.warning,
            icon: Icons.warning_amber_outlined,
            isDark: isDark,
          ),
        ],
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
        if (data.hasValue('chest_auscultation'))
          _ChestAuscultationSection(auscultation: data.getMap('chest_auscultation'), isDark: isDark),
        if (data.hasValue('investigations_required')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          ChipsSection(
            title: 'Investigations Ordered',
            items: data.getStringList('investigations_required'),
            color: AppColors.primary,
            icon: Icons.biotech,
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
    return Column(
      children: [
        if (data.hasValue('symptoms'))
          InfoCard(
            title: 'Presenting Symptoms',
            content: data.getString('symptoms'),
            icon: Icons.sick_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
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
        if (data.hasValue('mse')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _MseSection(mse: data.getMap('mse'), isDark: isDark),
        ],
        if (data.hasValue('risk_assessment')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          _RiskAssessmentSection(risk: data.getMap('risk_assessment'), isDark: isDark),
        ],
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
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
          _buildResult(),
          if (data.hasValue('reference_range')) ...[
            const SizedBox(height: MedicalRecordConstants.paddingMedium),
            _buildReferenceRange(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
        if (data.hasValue('imaging_type'))
          InfoCard(
            title: 'Imaging Type',
            content: data.getString('imaging_type'),
            icon: Icons.image_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
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
      ],
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
        if (data.hasValue('procedure_name'))
          InfoCard(
            title: 'Procedure',
            content: data.getString('procedure_name'),
            icon: Icons.healing_outlined,
            color: AppColors.accent,
            isDark: isDark,
          ),
        if (data.hasValue('procedure_notes')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Procedure Notes',
            content: data.getString('procedure_notes'),
            icon: Icons.note_alt_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        ],
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }
}

class _FollowUpContent extends StatelessWidget {

  const _FollowUpContent({required this.data, required this.isDark});
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (data.hasValue('follow_up_notes'))
          InfoCard(
            title: 'Follow-up Notes',
            content: data.getString('follow_up_notes'),
            icon: Icons.event_repeat,
            color: AppColors.primary,
            isDark: isDark,
          ),
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }
}

class _GeneralContent extends StatelessWidget {

  const _GeneralContent({required this.record, required this.data, required this.isDark});
  final MedicalRecord record;
  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (record.description.isNotEmpty)
          InfoCard(
            title: 'Description',
            content: record.description,
            icon: Icons.description_outlined,
            color: AppColors.info,
            isDark: isDark,
          ),
        if (data.hasValue('chief_complaints')) ...[
          const SizedBox(height: MedicalRecordConstants.paddingLarge),
          InfoCard(
            title: 'Chief Complaints',
            content: data.getString('chief_complaints'),
            icon: Icons.sick_outlined,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
        if (data.hasValue('vitals'))
          _VitalsSection(vitals: data.getMap('vitals'), isDark: isDark),
      ],
    );
  }
}

// ============================================================================
// SPECIALIZED SECTIONS
// ============================================================================

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
          padding: const EdgeInsets.all(10),
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
          padding: const EdgeInsets.all(10),
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
      padding: const EdgeInsets.all(10),
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
          padding: const EdgeInsets.all(10),
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

class _ChestAuscultationSection extends StatelessWidget {

  const _ChestAuscultationSection({required this.auscultation, required this.isDark});
  final Map<String, dynamic> auscultation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
              if (auscultation.hasValue('breath_sounds'))
                _buildRow('Breath Sounds', auscultation.getString('breath_sounds')),
              if (auscultation.hasValue('added_sounds')) ...[
                const SizedBox(height: MedicalRecordConstants.paddingMedium),
                _buildAddedSounds(),
              ],
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
              _LungZonesDisplay(auscultation: auscultation, isDark: isDark),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MedicalRecordConstants.pulmonaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.hearing, color: MedicalRecordConstants.pulmonaryColor, size: MedicalRecordConstants.iconLarge),
        ),
        const SizedBox(width: MedicalRecordConstants.paddingMedium),
        const Text(
          'Chest Auscultation',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: MedicalRecordConstants.fontTitle),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontMedium,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: MedicalRecordConstants.fontMedium,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedSounds() {
    final sounds = auscultation.getStringList('added_sounds');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Added Sounds',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: MedicalRecordConstants.fontMedium,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: MedicalRecordConstants.paddingSmall),
        Wrap(
          spacing: MedicalRecordConstants.paddingSmall,
          runSpacing: MedicalRecordConstants.paddingSmall,
          children: sounds.map((sound) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              sound,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: MedicalRecordConstants.fontBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),).toList(),
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

  const _ActionButtons({required this.isDark});
  final bool isDark;

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
            child: ElevatedButton.icon(
              onPressed: () => _handleEdit(context),
              icon: const Icon(Icons.edit_outlined, size: MedicalRecordConstants.iconLarge),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    // TODO(developer): Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
    );
  }

  void _handleDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Implement actual deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete feature coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
