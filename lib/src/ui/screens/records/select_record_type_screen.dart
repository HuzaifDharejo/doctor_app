import 'package:flutter/material.dart';
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
class SelectRecordTypeScreen extends StatelessWidget {
  const SelectRecordTypeScreen({
    super.key,
    this.preselectedPatient,
  });

  final Patient? preselectedPatient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: _buildHeader(context, padding),
          ),
          // Record Types Grid
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 600 ? 3 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate(
                _buildRecordTypeCards(context, isDark),
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

  Widget _buildHeader(BuildContext context, double padding) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // App Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Medical Record',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_chart_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose Record Type',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (preselectedPatient != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${preselectedPatient!.firstName} ${preselectedPatient!.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecordTypeCards(BuildContext context, bool isDark) {
    final recordTypes = [
      _RecordTypeInfo(
        title: 'General\nConsultation',
        icon: Icons.medical_services_rounded,
        description: 'Standard medical visit',
        gradientColors: [AppColors.primary, AppColors.primaryDark],
        onTap: () => _navigateToScreen(
          context,
          AddGeneralRecordScreen(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Pulmonary\nEvaluation',
        icon: Icons.air_rounded,
        description: 'Respiratory assessment',
        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        onTap: () => _navigateToScreen(
          context,
          AddPulmonaryScreen(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Psychiatric\nAssessment',
        icon: Icons.psychology_rounded,
        description: 'Mental health evaluation',
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
        onTap: () => _navigateToScreen(
          context,
          PsychiatricAssessmentScreenModern(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Lab\nResult',
        icon: Icons.science_rounded,
        description: 'Laboratory tests',
        gradientColors: [AppColors.info, const Color(0xFF0284C7)],
        onTap: () => _navigateToScreen(
          context,
          AddLabResultScreen(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Imaging /\nRadiology',
        icon: Icons.image_rounded,
        description: 'X-Ray, CT, MRI, etc.',
        gradientColors: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
        onTap: () => _navigateToScreen(
          context,
          AddImagingScreen(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Medical\nProcedure',
        icon: Icons.healing_rounded,
        description: 'Surgical procedures',
        gradientColors: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
        onTap: () => _navigateToScreen(
          context,
          AddProcedureScreen(preselectedPatient: preselectedPatient),
        ),
      ),
      _RecordTypeInfo(
        title: 'Follow-up\nVisit',
        icon: Icons.event_repeat_rounded,
        description: 'Progress check',
        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
        onTap: () => _navigateToScreen(
          context,
          AddFollowUpScreen(preselectedPatient: preselectedPatient),
        ),
      ),
    ];

    return recordTypes
        .map((info) => _buildRecordTypeCard(context, info, isDark))
        .toList();
  }

  Widget _buildRecordTypeCard(
    BuildContext context,
    _RecordTypeInfo info,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: info.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: info.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: info.gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  info.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                info.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.pop(context, true);
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

