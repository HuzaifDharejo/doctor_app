import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/theme/design_tokens.dart';

/// Comprehensive Treatment Progress Screen
/// Shows treatment sessions, medication responses, goals progress, and side effect monitoring
class TreatmentProgressScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const TreatmentProgressScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<TreatmentProgressScreen> createState() => _TreatmentProgressScreenState();
}

class _TreatmentProgressScreenState extends ConsumerState<TreatmentProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Data
  List<TreatmentSession> _sessions = [];
  List<MedicationResponse> _medications = [];
  List<TreatmentGoal> _goals = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dbAsync = ref.read(doctorDbProvider);
    dbAsync.whenData((db) async {
      final sessions = await db.getTreatmentSessionsForPatient(widget.patientId);
      final medications = await db.getMedicationResponsesForPatient(widget.patientId);
      final goals = await db.getTreatmentGoalsForPatient(widget.patientId);
      // outcomes loaded but used for summary calculations
      await db.getTreatmentOutcomesForPatient(widget.patientId);
      final summary = await db.getTreatmentProgressSummary(widget.patientId);
      
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _medications = medications;
          _goals = goals;
          _summary = summary;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                  ),
                  onPressed: () => Navigator.pop(context),
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
                        : [Colors.white, const Color(0xFFF8F9FA)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Treatment Progress',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.patientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF6B7280),
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
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF8B5CF6),
              indicatorWeight: 3,
              labelColor: isDark ? Colors.white : const Color(0xFF8B5CF6),
              unselectedLabelColor: isDark 
                  ? Colors.white.withValues(alpha: 0.5)
                  : const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Sessions'),
                Tab(text: 'Medications'),
                Tab(text: 'Goals'),
                Tab(text: 'Side Effects'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSummaryCards(context),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSessionsTab(context),
                        _buildMedicationsTab(context),
                        _buildGoalsTab(context),
                        _buildSideEffectsTab(context),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddMenu(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSummaryCard(
              context,
              icon: Icons.event_note,
              title: 'Sessions',
              value: '${_summary['totalSessions'] ?? 0}',
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              icon: Icons.medication,
              title: 'Active Meds',
              value: '${_summary['activeMedications'] ?? 0}',
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              icon: Icons.track_changes,
              title: 'Goals Progress',
              value: '${(_summary['averageProgress'] ?? 0).toStringAsFixed(0)}%',
              color: AppColors.info,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              icon: Icons.warning_amber,
              title: 'Side Effects',
              value: '${_summary['medicationsWithSideEffects'] ?? 0}',
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SESSIONS TAB ====================
  Widget _buildSessionsTab(BuildContext context) {
    if (_sessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_note_outlined,
        title: 'No Sessions Yet',
        subtitle: 'Add therapy or psychiatry sessions to track progress',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(context, _sessions[index]),
    );
  }

  Widget _buildSessionCard(BuildContext context, TreatmentSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    Color providerColor;
    IconData providerIcon;
    switch (session.providerType) {
      case 'therapist':
        providerColor = AppColors.success;
        providerIcon = Icons.psychology;
        break;
      case 'psychiatrist':
        providerColor = AppColors.primary;
        providerIcon = Icons.medical_services;
        break;
      case 'counselor':
        providerColor = AppColors.info;
        providerIcon = Icons.support_agent;
        break;
      default:
        providerColor = AppColors.textSecondary;
        providerIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSessionDetails(context, session),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: providerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(providerIcon, color: providerColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${session.providerType.toUpperCase()} SESSION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: providerColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormat.format(session.sessionDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mood indicator
                    if (session.moodRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: _getMoodColor(session.moodRating!).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getMoodIcon(session.moodRating!),
                              size: 16,
                              color: _getMoodColor(session.moodRating!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${session.moodRating}/10',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getMoodColor(session.moodRating!),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (session.sessionNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    session.sessionNotes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (session.homeworkAssigned.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.assignment, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Homework: ${session.homeworkAssigned}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Risk indicator
                if (session.riskAssessment.isNotEmpty && session.riskAssessment != 'none') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _getRiskColor(session.riskAssessment).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 12, color: _getRiskColor(session.riskAssessment)),
                        const SizedBox(width: 4),
                        Text(
                          'Risk: ${session.riskAssessment.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRiskColor(session.riskAssessment),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== MEDICATIONS TAB ====================
  Widget _buildMedicationsTab(BuildContext context) {
    if (_medications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication_outlined,
        title: 'No Medication Tracking',
        subtitle: 'Add medications to monitor responses and effectiveness',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _medications.length,
      itemBuilder: (context, index) => _buildMedicationCard(context, _medications[index]),
    );
  }

  Widget _buildMedicationCard(BuildContext context, MedicationResponse med) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    
    Color statusColor;
    IconData statusIcon;
    switch (med.responseStatus) {
      case 'effective':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        statusIcon = Icons.timelapse;
        break;
      case 'ineffective':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'discontinued':
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.stop_circle;
        break;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: med.endDate != null
              ? (isDark ? AppColors.darkDivider : AppColors.divider)
              : statusColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMedicationDetails(context, med),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medication, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.medicationName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (med.dosage.isNotEmpty)
                            Text(
                              '${med.dosage} - ${med.frequency}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            med.responseStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Effectiveness score
                if (med.effectivenessScore != null) ...[
                  Row(
                    children: [
                      Text(
                        'Effectiveness:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: med.effectivenessScore! / 10,
                          backgroundColor: (isDark ? AppColors.darkDivider : AppColors.divider),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${med.effectivenessScore}/10',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
                // Side effects indicator
                if (med.sideEffectSeverity != 'none' && med.sideEffectSeverity.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(med.sideEffectSeverity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 12,
                          color: _getSeverityColor(med.sideEffectSeverity),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Side Effects: ${med.sideEffectSeverity.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(med.sideEffectSeverity),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Adherence indicator
                if (!med.adherent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'NON-ADHERENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== GOALS TAB ====================
  Widget _buildGoalsTab(BuildContext context) {
    if (_goals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.track_changes_outlined,
        title: 'No Treatment Goals',
        subtitle: 'Set goals to track treatment progress',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _goals.length,
      itemBuilder: (context, index) => _buildGoalCard(context, _goals[index]),
    );
  }

  Widget _buildGoalCard(BuildContext context, TreatmentGoal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color statusColor;
    IconData statusIcon;
    switch (goal.status) {
      case 'achieved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'modified':
        statusColor = AppColors.warning;
        statusIcon = Icons.edit;
        break;
      case 'discontinued':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.flag;
    }

    Color priorityColor;
    switch (goal.priority) {
      case 1:
        priorityColor = AppColors.error;
        break;
      case 2:
        priorityColor = AppColors.warning;
        break;
      default:
        priorityColor = AppColors.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.status == 'achieved'
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showGoalDetails(context, goal),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  goal.priority == 1 ? 'HIGH' : goal.priority == 2 ? 'MED' : 'LOW',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                goal.goalCategory.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal.goalDescription,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${goal.progressPercent}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progressPercent / 100,
                        backgroundColor: (isDark ? AppColors.darkDivider : AppColors.divider),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                // Baseline -> Current -> Target
                if (goal.baselineMeasure.isNotEmpty || goal.targetMeasure.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (goal.baselineMeasure.isNotEmpty)
                        Flexible(child: _buildMeasureChip('Baseline', goal.baselineMeasure, AppColors.textSecondary)),
                      if (goal.currentMeasure.isNotEmpty)
                        Flexible(child: _buildMeasureChip('Current', goal.currentMeasure, AppColors.primary)),
                      if (goal.targetMeasure.isNotEmpty)
                        Flexible(child: _buildMeasureChip('Target', goal.targetMeasure, AppColors.success)),
                    ],
                  ),
                ],
                // Barriers
                if (goal.barriers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.block, size: 12, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Barriers: ${goal.barriers}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasureChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: color),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SIDE EFFECTS TAB ====================
  Widget _buildSideEffectsTab(BuildContext context) {
    final medsWithSideEffects = _medications
        .where((m) => m.sideEffectSeverity != 'none' && m.sideEffectSeverity.isNotEmpty)
        .toList();

    if (medsWithSideEffects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Side Effects Reported',
        subtitle: 'All medications are being tolerated well',
        isPositive: true,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: medsWithSideEffects.length,
      itemBuilder: (context, index) => _buildSideEffectCard(context, medsWithSideEffects[index]),
    );
  }

  Widget _buildSideEffectCard(BuildContext context, MedicationResponse med) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(med.sideEffectSeverity);
    
    List<String> sideEffectsList = [];
    try {
      if (med.sideEffects.isNotEmpty) {
        final decoded = jsonDecode(med.sideEffects);
        if (decoded is List) {
          // Handle both string arrays and object arrays
          sideEffectsList = decoded.map((item) {
            if (item is String) return item;
            if (item is Map) return item['name']?.toString() ?? item.toString();
            return item.toString();
          }).toList();
        }
      }
    } catch (_) {
      if (med.sideEffects.isNotEmpty) {
        sideEffectsList = [med.sideEffects];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber, color: severityColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.medicationName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${med.dosage} - ${med.frequency}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    med.sideEffectSeverity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            if (sideEffectsList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sideEffectsList.map((effect) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    effect,
                    style: TextStyle(
                      fontSize: 12,
                      color: severityColor,
                    ),
                  ),
                )).toList(),
              ),
            ],
            if (med.providerNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        med.providerNotes,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPositive = false,
  }) {
    final color = isPositive ? AppColors.success : AppColors.textSecondary;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  Color _getMoodColor(int rating) {
    if (rating <= 3) return AppColors.error;
    if (rating <= 5) return AppColors.warning;
    if (rating <= 7) return AppColors.info;
    return AppColors.success;
  }

  IconData _getMoodIcon(int rating) {
    if (rating <= 3) return Icons.sentiment_very_dissatisfied;
    if (rating <= 5) return Icons.sentiment_dissatisfied;
    if (rating <= 7) return Icons.sentiment_neutral;
    return Icons.sentiment_satisfied;
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'mild':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  // ==================== DIALOGS ====================
  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event_note, color: AppColors.primary),
              ),
              title: const Text('Add Session'),
              subtitle: const Text('Record a therapy or psychiatry session'),
              onTap: () {
                Navigator.pop(context);
                _showAddSessionDialog(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medication, color: AppColors.success),
              ),
              title: const Text('Add Medication Response'),
              subtitle: const Text('Track medication effectiveness'),
              onTap: () {
                Navigator.pop(context);
                _showAddMedicationDialog(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.track_changes, color: AppColors.info),
              ),
              title: const Text('Add Treatment Goal'),
              subtitle: const Text('Set a new treatment goal'),
              onTap: () {
                Navigator.pop(context);
                _showAddGoalDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, TreatmentSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${session.providerType.toUpperCase()} SESSION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(session.sessionDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (session.providerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Provider: ${session.providerName}',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (session.moodRating != null)
              _buildDetailSection('Mood Rating', '${session.moodRating}/10 - ${session.patientMood}'),
            if (session.presentingConcerns.isNotEmpty)
              _buildDetailSection('Presenting Concerns', session.presentingConcerns),
            if (session.sessionNotes.isNotEmpty)
              _buildDetailSection('Session Notes', session.sessionNotes),
            if (session.interventionsUsed.isNotEmpty)
              _buildDetailSection('Interventions', session.interventionsUsed),
            if (session.progressNotes.isNotEmpty)
              _buildDetailSection('Progress Notes', session.progressNotes),
            if (session.homeworkAssigned.isNotEmpty)
              _buildDetailSection('Homework Assigned', session.homeworkAssigned),
            if (session.homeworkReview.isNotEmpty)
              _buildDetailSection('Previous Homework Review', session.homeworkReview),
            if (session.riskAssessment.isNotEmpty && session.riskAssessment != 'none')
              _buildDetailSection('Risk Assessment', session.riskAssessment.toUpperCase(), 
                color: _getRiskColor(session.riskAssessment)),
            if (session.planForNextSession.isNotEmpty)
              _buildDetailSection('Plan for Next Session', session.planForNextSession),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, MedicationResponse med) {
    // Similar detail view for medications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Medication details: ${med.medicationName}')),
    );
  }

  void _showGoalDetails(BuildContext context, TreatmentGoal goal) {
    // Similar detail view for goals
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Goal details: ${goal.goalDescription}')),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    // Add session dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add session dialog coming soon')),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    // Add medication dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add medication response dialog coming soon')),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    // Add goal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add treatment goal dialog coming soon')),
    );
  }
}


