import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/db_provider.dart';
import '../../../services/specialty_service.dart';
import 'add_follow_up_screen.dart';
import 'add_general_record_screen.dart';
import 'add_imaging_screen.dart';
import 'add_lab_result_screen.dart';
import 'add_procedure_screen.dart';
import 'add_pulmonary_screen.dart';
import 'add_vitals_record_screen.dart';
import 'add_certificate_screen.dart';
import 'add_referral_screen.dart';
import '../psychiatric_assessment_screen_modern.dart';
import '../add_prescription_screen.dart';
import 'add_cardiac_exam_screen.dart';
import 'add_pediatric_checkup_screen.dart';
import 'add_eye_exam_screen.dart';
import 'add_skin_exam_screen.dart';
import 'add_ent_exam_screen.dart';
import 'add_orthopedic_exam_screen.dart';
import 'add_gyn_exam_screen.dart';
import 'add_neuro_exam_screen.dart';
import 'add_gi_exam_screen.dart';

/// Screen for selecting which type of medical record to add
/// Redesigned with modern theme-consistent styling and specialty awareness
class SelectRecordTypeScreen extends ConsumerStatefulWidget {
  const SelectRecordTypeScreen({
    super.key,
    this.preselectedPatient,
    this.encounterId,
    this.appointmentId,
    this.chiefComplaint,
    this.historyOfPresentIllness,
  });

  final Patient? preselectedPatient;
  /// Associated encounter ID from workflow
  final int? encounterId;
  /// Associated appointment ID from workflow
  final int? appointmentId;
  /// Chief complaint from workflow for pre-filling
  final String? chiefComplaint;
  /// History of present illness from workflow
  final String? historyOfPresentIllness;

  @override
  ConsumerState<SelectRecordTypeScreen> createState() => _SelectRecordTypeScreenState();
}

class _SelectRecordTypeScreenState extends ConsumerState<SelectRecordTypeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  DoctorSpecialty? _doctorSpecialty;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
    
    // Load doctor's specialty from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorSpecialty();
    });
  }
  
  void _loadDoctorSpecialty() {
    final profile = ref.read(doctorSettingsProvider).profile;
    final specialty = DoctorSpecialtyExtension.fromDisplayName(profile.specialization);
    if (mounted) {
      setState(() => _doctorSpecialty = specialty);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Mapping from screen IDs to settings IDs
  static const Map<String, String> _idToSettingsType = {
    // Core types
    'general': 'general',
    'follow_up': 'follow_up',
    'lab': 'lab_result',
    'imaging': 'imaging',
    'procedure': 'procedure',
    // Mental health types
    'pulmonary': 'pulmonary_evaluation',
    'psychiatric': 'psychiatric_assessment',
    'therapy': 'therapy_session',
    'psychiatrist': 'psychiatrist_note',
    // Specialty examination types
    'cardiac': 'cardiac_exam',
    'pediatric': 'pediatric_checkup',
    'eye': 'eye_exam',
    'skin': 'skin_exam',
    'ent': 'ent_exam',
    'orthopedic': 'orthopedic_exam',
    'gyn': 'gyn_exam',
    'neuro': 'neuro_exam',
    'gi': 'gi_exam',
  };

  bool _isTypeEnabled(String typeId, List<String> enabledTypes) {
    final settingsType = _idToSettingsType[typeId];
    // If not in mapping, always show (prescription, vitals, certificate, referral)
    if (settingsType == null) return true;
    return enabledTypes.contains(settingsType);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? AppSpacing.md : AppSpacing.xl;
    
    // Get enabled record types from settings
    final enabledTypes = ref.watch(appSettingsProvider).settings.enabledMedicalRecordTypes;
    
    // Filter record types based on settings
    final allRecordTypes = _getRecordTypes(context)
        .where((t) => _isTypeEnabled(t.id, enabledTypes)).toList();
    final recommendedTypes = _getRecommendedRecordTypes(context)
        .where((t) => _isTypeEnabled(t.id, enabledTypes)).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern Sliver App Bar
          _buildSliverAppBar(context, isDark, isCompact),
          // Patient Info Card (if preselected)
          if (widget.preselectedPatient != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, 0, padding, AppSpacing.lg),
                child: _buildPatientInfoCard(context, isDark),
              ),
            ),
          
          // Recommended for You Section
          if (recommendedTypes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildSectionHeader(
                  isDark: isDark,
                  title: 'Recommended for You',
                  subtitle: _doctorSpecialty != null 
                      ? 'Based on ${_doctorSpecialty!.shortName}'
                      : 'Most commonly used',
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 600 ? 4 : 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: screenWidth > 600 ? 1.0 : 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return FadeTransition(
                      opacity: _animationController,
                      child: _buildCompactRecordCard(context, recommendedTypes[index], isDark),
                    );
                  },
                  childCount: recommendedTypes.length,
                ),
              ),
            ),
          ],
          
          // All Record Types Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildSectionHeader(
                isDark: isDark,
                title: 'All Record Types',
                subtitle: '${allRecordTypes.length} types available',
                icon: Icons.apps_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ),
          // Record Types Grid
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 600 ? 3 : 2,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: screenWidth > 600 ? 1.0 : 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return FadeTransition(
                    opacity: _animationController,
                    child: _buildRecordTypeCard(context, allRecordTypes[index], isDark, isCompact),
                  );
                },
                childCount: allRecordTypes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactRecordCard(BuildContext context, _RecordTypeInfo info, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        info.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : info.gradientColors[0].withValues(alpha: 0.2),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: info.gradientColors[0].withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: info.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                info.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                info.title.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, bool isCompact) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 24,
                60,
                isCompact ? 16 : 24,
                20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Container with gradient
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_chart_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Record',
                          style: TextStyle(
                            fontSize: isCompact ? 24 : 28,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose record type to add',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 15,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(BuildContext context, bool isDark) {
    final patient = widget.preselectedPatient!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                patient.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient.firstName} ${patient.lastName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adding record for this patient',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Record Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Get recommended record types based on doctor's specialty
  List<_RecordTypeInfo> _getRecommendedRecordTypes(BuildContext context) {
    final allTypes = _getRecordTypes(context);
    
    // Define recommended types based on specialty
    final recommendedIds = <String>[];
    
    switch (_doctorSpecialty) {
      case DoctorSpecialty.pulmonology:
        recommendedIds.addAll(['general', 'pulmonary', 'lab', 'imaging']);
        break;
      case DoctorSpecialty.psychiatry:
        recommendedIds.addAll(['general', 'psychiatric', 'follow_up', 'prescription']);
        break;
      case DoctorSpecialty.cardiology:
        recommendedIds.addAll(['general', 'cardiac', 'lab', 'imaging', 'procedure']);
        break;
      case DoctorSpecialty.pediatrics:
        recommendedIds.addAll(['general', 'pediatric', 'vitals', 'prescription', 'certificate']);
        break;
      case DoctorSpecialty.orthopedics:
        recommendedIds.addAll(['general', 'orthopedic', 'imaging', 'procedure', 'referral']);
        break;
      case DoctorSpecialty.dermatology:
        recommendedIds.addAll(['general', 'skin', 'procedure', 'prescription', 'follow_up']);
        break;
      case DoctorSpecialty.ophthalmology:
        recommendedIds.addAll(['general', 'eye', 'procedure', 'prescription', 'follow_up']);
        break;
      case DoctorSpecialty.ent:
        recommendedIds.addAll(['general', 'ent', 'imaging', 'procedure', 'referral']);
        break;
      case DoctorSpecialty.gynecology:
        recommendedIds.addAll(['general', 'gyn', 'imaging', 'lab', 'procedure']);
        break;
      case DoctorSpecialty.neurology:
        recommendedIds.addAll(['general', 'neuro', 'imaging', 'lab', 'referral']);
        break;
      case DoctorSpecialty.gastroenterology:
        recommendedIds.addAll(['general', 'gi', 'imaging', 'lab', 'procedure']);
        break;
      case DoctorSpecialty.generalPractice:
      case DoctorSpecialty.internalMedicine:
      default:
        recommendedIds.addAll(['general', 'prescription', 'lab', 'vitals', 'follow_up', 'referral']);
        break;
    }
    
    return allTypes.where((t) => recommendedIds.contains(t.id)).take(6).toList();
  }

  List<_RecordTypeInfo> _getRecordTypes(BuildContext context) {
    return [
      // === UNIVERSAL RECORD TYPES ===
      _RecordTypeInfo(
        id: 'general',
        title: 'General\nConsultation',
        icon: Icons.medical_services_rounded,
        description: 'Standard medical visit',
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => _navigateToScreen(
          context,
          AddGeneralRecordScreen(
            preselectedPatient: widget.preselectedPatient,
            encounterId: widget.encounterId,
            appointmentId: widget.appointmentId,
          ),
        ),
      ),
      _RecordTypeInfo(
        id: 'follow_up',
        title: 'Follow-up\nVisit',
        icon: Icons.event_repeat_rounded,
        description: 'Progress check',
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => _navigateToScreen(
          context,
          AddFollowUpScreen(
            preselectedPatient: widget.preselectedPatient,
            encounterId: widget.encounterId,
          ),
        ),
      ),
      _RecordTypeInfo(
        id: 'prescription',
        title: 'Prescription\nRecord',
        icon: Icons.medication_rounded,
        description: 'Medication records',
        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        onTap: () => _navigateToScreen(
          context,
          AddPrescriptionScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'vitals',
        title: 'Vitals\nRecord',
        icon: Icons.monitor_heart_rounded,
        description: 'BP, weight, temperature',
        gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        onTap: () => _navigateToScreen(
          context,
          AddVitalsRecordScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'lab',
        title: 'Lab\nResult',
        icon: Icons.science_rounded,
        description: 'Laboratory tests',
        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        onTap: () => _navigateToScreen(
          context,
          AddLabResultScreen(
            preselectedPatient: widget.preselectedPatient,
            encounterId: widget.encounterId,
            appointmentId: widget.appointmentId,
          ),
        ),
      ),
      _RecordTypeInfo(
        id: 'imaging',
        title: 'Imaging /\nRadiology',
        icon: Icons.image_rounded,
        description: 'X-Ray, CT, MRI, etc.',
        gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        onTap: () => _navigateToScreen(
          context,
          AddImagingScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'procedure',
        title: 'Medical\nProcedure',
        icon: Icons.healing_rounded,
        description: 'Surgical procedures',
        gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        onTap: () => _navigateToScreen(
          context,
          AddProcedureScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      
      // === DOCUMENTATION TYPES ===
      _RecordTypeInfo(
        id: 'certificate',
        title: 'Medical\nCertificate',
        icon: Icons.description_rounded,
        description: 'Fitness, sick leave',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => _navigateToScreen(
          context,
          AddCertificateScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'referral',
        title: 'Referral\nLetter',
        icon: Icons.send_rounded,
        description: 'Specialist referral',
        gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
        onTap: () => _navigateToScreen(
          context,
          AddReferralScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      
      // === SPECIALTY-SPECIFIC TYPES ===
      _RecordTypeInfo(
        id: 'pulmonary',
        title: 'Pulmonary\nEvaluation',
        icon: Icons.air_rounded,
        description: 'Respiratory assessment',
        gradientColors: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
        onTap: () => _navigateToScreen(
          context,
          AddPulmonaryScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'psychiatric',
        title: 'Psychiatric\nAssessment',
        icon: Icons.psychology_rounded,
        description: 'Mental health evaluation',
        gradientColors: [const Color(0xFFA855F7), const Color(0xFF9333EA)],
        onTap: () => _navigateToScreen(
          context,
          PsychiatricAssessmentScreenModern(
            preselectedPatient: widget.preselectedPatient,
            encounterId: widget.encounterId,
            appointmentId: widget.appointmentId,
            chiefComplaint: widget.chiefComplaint,
            historyOfPresentIllness: widget.historyOfPresentIllness,
          ),
        ),
      ),
      _RecordTypeInfo(
        id: 'therapy',
        title: 'Therapy\nSession',
        icon: Icons.self_improvement_rounded,
        description: 'Counseling notes',
        gradientColors: [const Color(0xFFA78BFA), const Color(0xFF8B5CF6)],
        onTap: () => _navigateToScreen(
          context,
          PsychiatricAssessmentScreenModern(
            preselectedPatient: widget.preselectedPatient,
            encounterId: widget.encounterId,
            appointmentId: widget.appointmentId,
            chiefComplaint: widget.chiefComplaint,
            historyOfPresentIllness: widget.historyOfPresentIllness,
            isTherapySession: true,
          ),
        ),
      ),
      
      // === SPECIALTY EXAMINATION TYPES ===
      _RecordTypeInfo(
        id: 'cardiac',
        title: 'Cardiac\nExamination',
        icon: Icons.favorite_rounded,
        description: 'Heart sounds, ECG, Echo',
        gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        onTap: () => _navigateToScreen(
          context,
          AddCardiacExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'pediatric',
        title: 'Pediatric\nCheckup',
        icon: Icons.child_care_rounded,
        description: 'Growth, development',
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => _navigateToScreen(
          context,
          AddPediatricCheckupScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'eye',
        title: 'Eye\nExamination',
        icon: Icons.visibility_rounded,
        description: 'Visual acuity, IOP',
        gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
        onTap: () => _navigateToScreen(
          context,
          AddEyeExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'skin',
        title: 'Skin\nExamination',
        icon: Icons.face_retouching_natural_rounded,
        description: 'Dermatology exam',
        gradientColors: [const Color(0xFFF97316), const Color(0xFFEA580C)],
        onTap: () => _navigateToScreen(
          context,
          AddSkinExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'ent',
        title: 'ENT\nExamination',
        icon: Icons.hearing_rounded,
        description: 'Ear, Nose, Throat',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => _navigateToScreen(
          context,
          AddEntExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'orthopedic',
        title: 'Orthopedic\nExamination',
        icon: Icons.accessibility_new_rounded,
        description: 'Joints, ROM, strength',
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => _navigateToScreen(
          context,
          AddOrthopedicExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'gyn',
        title: 'GYN/OB\nExamination',
        icon: Icons.pregnant_woman_rounded,
        description: 'Gynecologic exam',
        gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        onTap: () => _navigateToScreen(
          context,
          AddGynExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'neuro',
        title: 'Neuro\nExamination',
        icon: Icons.psychology_alt_rounded,
        description: 'Neurological exam',
        gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        onTap: () => _navigateToScreen(
          context,
          AddNeuroExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        id: 'gi',
        title: 'GI\nExamination',
        icon: Icons.medical_information_rounded,
        description: 'Abdominal exam',
        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        onTap: () => _navigateToScreen(
          context,
          AddGIExamScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
    ];
  }

  Widget _buildRecordTypeCard(
    BuildContext context,
    _RecordTypeInfo info,
    bool isDark,
    bool isCompact,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        info.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : info.gradientColors[0].withValues(alpha: 0.15),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: info.gradientColors[0].withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient accent
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      info.gradientColors[0].withValues(alpha: 0.15),
                      info.gradientColors[1].withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient background
                  Container(
                    padding: EdgeInsets.all(isCompact ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: info.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: info.gradientColors[0].withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      info.icon,
                      color: Colors.white,
                      size: isCompact ? 22 : 26,
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    info.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    info.description,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: isCompact ? 11 : 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Arrow indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: info.gradientColors[0].withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: info.gradientColors[0],
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToScreen(BuildContext context, Widget screen) async {
    final result = await Navigator.push(
      context,
      AppRouter.route(screen),
    );
    
    // Always pop back to previous screen (workflow) after returning from record screen
    if (context.mounted) {
      Navigator.pop(context, result);
    }
  }
}

class _RecordTypeInfo {
  const _RecordTypeInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;
}

