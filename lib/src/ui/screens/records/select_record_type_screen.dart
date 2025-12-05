import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import 'add_follow_up_screen.dart';
import 'add_general_record_screen.dart';
import 'add_imaging_screen.dart';
import 'add_lab_result_screen.dart';
import 'add_procedure_screen.dart';
import 'add_pulmonary_screen.dart';
import '../psychiatric_assessment_screen_modern.dart';

/// Screen for selecting which type of medical record to add
/// Redesigned with modern theme-consistent styling
class SelectRecordTypeScreen extends StatefulWidget {
  const SelectRecordTypeScreen({
    super.key,
    this.preselectedPatient,
  });

  final Patient? preselectedPatient;

  @override
  State<SelectRecordTypeScreen> createState() => _SelectRecordTypeScreenState();
}

class _SelectRecordTypeScreenState extends State<SelectRecordTypeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create staggered animations for each card
    _cardAnimations = List.generate(7, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _animationController,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutBack),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? AppSpacing.md : AppSpacing.xl;

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
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildSectionTitle(isDark),
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
                  final recordTypes = _getRecordTypes(context);
                  return AnimatedBuilder(
                    animation: _cardAnimations[index],
                    builder: (context, child) {
                      // Clamp opacity to valid range (0.0-1.0) since easeOutBack can overshoot
                      final opacityValue = _cardAnimations[index].value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _cardAnimations[index].value)),
                        child: Opacity(
                          opacity: opacityValue,
                          child: child,
                        ),
                      );
                    },
                    child: _buildRecordTypeCard(context, recordTypes[index], isDark, isCompact),
                  );
                },
                childCount: 7,
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

  List<_RecordTypeInfo> _getRecordTypes(BuildContext context) {
    return [
      _RecordTypeInfo(
        title: 'General\nConsultation',
        icon: Icons.medical_services_rounded,
        description: 'Standard medical visit',
        gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        onTap: () => _navigateToScreen(
          context,
          AddGeneralRecordScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Pulmonary\nEvaluation',
        icon: Icons.air_rounded,
        description: 'Respiratory assessment',
        gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
        onTap: () => _navigateToScreen(
          context,
          AddPulmonaryScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Psychiatric\nAssessment',
        icon: Icons.psychology_rounded,
        description: 'Mental health evaluation',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        onTap: () => _navigateToScreen(
          context,
          PsychiatricAssessmentScreenModern(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Lab\nResult',
        icon: Icons.science_rounded,
        description: 'Laboratory tests',
        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        onTap: () => _navigateToScreen(
          context,
          AddLabResultScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
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
        title: 'Medical\nProcedure',
        icon: Icons.healing_rounded,
        description: 'Surgical procedures',
        gradientColors: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        onTap: () => _navigateToScreen(
          context,
          AddProcedureScreen(preselectedPatient: widget.preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Follow-up\nVisit',
        icon: Icons.event_repeat_rounded,
        description: 'Progress check',
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        onTap: () => _navigateToScreen(
          context,
          AddFollowUpScreen(preselectedPatient: widget.preselectedPatient),
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

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((result) {
      if (result != null && context.mounted) {
        Navigator.pop(context, result);
      }
    });
  }
}

class _RecordTypeInfo {
  const _RecordTypeInfo({
    required this.title,
    required this.icon,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;
}

