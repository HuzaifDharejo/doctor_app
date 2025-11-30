import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';

/// Comprehensive Treatment Dashboard
/// Displays all treatments, progress tracking, medication effectiveness,
/// session notes, and treatment outcomes for a patient
class TreatmentDashboard extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const TreatmentDashboard({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<TreatmentDashboard> createState() => _TreatmentDashboardState();
}

class _TreatmentDashboardState extends ConsumerState<TreatmentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Data
  List<TreatmentOutcome> _treatments = [];
  List<TreatmentGoal> _goals = [];
  List<MedicationResponse> _medications = [];
  List<TreatmentSession> _sessions = [];
  Map<String, dynamic> _stats = {
    'activeCount': 0,
    'completedCount': 0,
    'avgEffectiveness': 0.0,
    'totalSessions': 0,
    'sideEffectCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final dbAsync = ref.read(doctorDbProvider);
      dbAsync.when(
        data: (db) async {
          final treatments = await db.getTreatmentOutcomesForPatient(widget.patientId);
          final goals = await db.getTreatmentGoalsForPatient(widget.patientId);
          final medications = await db.getMedicationResponsesForPatient(widget.patientId);
          final sessions = await db.getTreatmentSessionsForPatient(widget.patientId);

          if (mounted) {
            setState(() {
              _treatments = treatments;
              _goals = goals;
              _medications = medications;
              _sessions = sessions;
              _calculateStats();
              _isLoading = false;
            });
          }
        },
        loading: () {},
        error: (_, __) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    final activeCount = _treatments.where((t) => t.outcome == 'ongoing').length;
    final completedCount = _treatments.where((t) => t.outcome == 'resolved' || t.outcome == 'improved').length;
    
    double totalEffectiveness = 0;
    int effectivenessCount = 0;
    int sideEffectCount = 0;

    for (final med in _medications) {
      if (med.effectivenessScore != null) {
        totalEffectiveness += med.effectivenessScore!;
        effectivenessCount++;
      }
      if (med.sideEffects.isNotEmpty && med.sideEffects != '[]') {
        sideEffectCount++;
      }
    }

    _stats = {
      'activeCount': activeCount,
      'completedCount': completedCount,
      'avgEffectiveness': effectivenessCount > 0 ? totalEffectiveness / effectivenessCount : 0.0,
      'totalSessions': _sessions.length,
      'sideEffectCount': sideEffectCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Dashboard - ${widget.patientName}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Active Treatments'),
            Tab(text: 'Medications'),
            Tab(text: 'Goals'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, colorScheme, isDark),
                _buildActiveTreatmentsTab(colorScheme, isDark),
                _buildMedicationsTab(colorScheme, isDark),
                _buildGoalsTab(colorScheme, isDark),
                _buildSessionsTab(colorScheme, isDark),
              ],
            ),
    );
  }

  /// Tab 1: Overview with key metrics and quick stats
  Widget _buildOverviewTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Stats Cards
          _buildStatsGrid(colorScheme, isDark),
          
          const SizedBox(height: 8),
          
          // Recent Sessions Section
          if (_sessions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ..._sessions.take(3).map((session) =>
                  _buildSessionCard(session, colorScheme, isDark),
                ),
              ],
            ),

          // Active Treatments Section
          if (_treatments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Active Treatments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ..._treatments
                    .where((t) => t.outcome == 'ongoing')
                    .take(3)
                    .map((treatment) =>
                  _buildActiveTreatmentCard(treatment, colorScheme, isDark),
                ),
              ],
            ),

          // Treatment Goals Progress
          if (_goals.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  'Treatment Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ..._goals
                    .where((g) => g.status == 'active')
                    .take(3)
                    .map((goal) =>
                  _buildGoalCard(goal, colorScheme, isDark),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build stats grid with key metrics
  Widget _buildStatsGrid(ColorScheme colorScheme, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.healing_rounded,
          title: 'Active',
          value: '${_stats['activeCount']}',
          color: Colors.blue,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          title: 'Completed',
          value: '${_stats['completedCount']}',
          color: Colors.green,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          title: 'Effectiveness',
          value: '${(_stats['avgEffectiveness'] as double).toStringAsFixed(1)}/10',
          color: Colors.amber,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.event_note_rounded,
          title: 'Sessions',
          value: '${_stats['totalSessions']}',
          color: Colors.purple,
          isDark: isDark,
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Color.alphaBlend(color.withValues(alpha: 0.1), Colors.grey[900]!)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tab 2: Active Treatments
  Widget _buildActiveTreatmentsTab(ColorScheme colorScheme, bool isDark) {
    final activeTreatments = _treatments.where((t) => t.outcome == 'ongoing').toList();
    
    if (activeTreatments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(Icons.healing_rounded, size: 48, color: Colors.grey[400]),
            Text(
              'No active treatments',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTreatments.length,
      itemBuilder: (context, index) => _buildActiveTreatmentCard(
        activeTreatments[index],
        colorScheme,
        isDark,
      ),
    );
  }

  /// Build active treatment card with details
  Widget _buildActiveTreatmentCard(
    TreatmentOutcome treatment,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final startDate = DateFormat('MMM dd, yyyy').format(treatment.startDate);
    final daysActive = DateTime.now().difference(treatment.startDate).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        treatment.treatmentDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Since $startDate ($daysActive days)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTreatmentStatusColor(treatment.outcome).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    treatment.treatmentType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTreatmentStatusColor(treatment.outcome),
                    ),
                  ),
                ),
              ],
            ),
            if (treatment.diagnosis.isNotEmpty)
              Text(
                'Diagnosis: ${treatment.diagnosis}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            if (treatment.effectivenessScore != null)
              Row(
                spacing: 8,
                children: [
                  const Text('Effectiveness:', style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildEffectivenessBadge(treatment.effectivenessScore!.toDouble(), colorScheme),
                ],
              ),
            if (treatment.sideEffects.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                    Expanded(
                      child: Text(
                        'Side Effects: ${treatment.sideEffects}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (treatment.notes.isNotEmpty)
              Text(
                'Notes: ${treatment.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// Tab 3: Medications
  Widget _buildMedicationsTab(ColorScheme colorScheme, bool isDark) {
    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(Icons.medication_rounded, size: 48, color: Colors.grey[400]),
            Text(
              'No medications tracked',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) => _buildMedicationCard(
        _medications[index],
        colorScheme,
        isDark,
      ),
    );
  }

  /// Build medication card
  Widget _buildMedicationCard(
    MedicationResponse medication,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final startDate = DateFormat('MMM dd, yyyy').format(medication.startDate);
    final isActive = medication.endDate == null || medication.endDate!.isAfter(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        medication.medicationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (medication.dosage.isNotEmpty)
                        Text(
                          '${medication.dosage} - ${medication.frequency}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        'Started: $startDate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'STOPPED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            // Response Status
            if (medication.responseStatus.isNotEmpty)
              Row(
                spacing: 8,
                children: [
                  const Text('Response:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMedicationResponseColor(medication.responseStatus).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      medication.responseStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getMedicationResponseColor(medication.responseStatus),
                      ),
                    ),
                  ),
                ],
              ),
            
            // Effectiveness Score
            if (medication.effectivenessScore != null)
              Row(
                spacing: 8,
                children: [
                  const Text('Effectiveness:', style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildEffectivenessBadge(medication.effectivenessScore!.toDouble(), colorScheme),
                ],
              ),

            // Target Symptoms
            if (medication.targetSymptoms.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text('Target Symptoms:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    medication.targetSymptoms,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

            // Side Effects
            if (medication.sideEffects.isNotEmpty && medication.sideEffects != '[]')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.info_rounded, color: Colors.orange, size: 16),
                    Expanded(
                      child: Text(
                        'Side Effects: ${medication.sideEffects}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Adherence
            Row(
              spacing: 8,
              children: [
                Icon(
                  medication.adherent ? Icons.check_circle : Icons.warning_rounded,
                  color: medication.adherent ? Colors.green : Colors.orange,
                  size: 18,
                ),
                Text(
                  medication.adherent ? 'Good Adherence' : 'Adherence Issues',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: medication.adherent ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 4: Goals
  Widget _buildGoalsTab(ColorScheme colorScheme, bool isDark) {
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(Icons.flag_rounded, size: 48, color: Colors.grey[400]),
            Text(
              'No treatment goals',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) => _buildGoalCard(
        _goals[index],
        colorScheme,
        isDark,
      ),
    );
  }

  /// Build goal card with progress
  Widget _buildGoalCard(
    TreatmentGoal goal,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final progressPercent = goal.progressPercent.toDouble();
    final statusColor = _getGoalStatusColor(goal.status, progressPercent, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.goalDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    goal.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.goalCategory.isNotEmpty)
              Text(
                'Category: ${goal.goalCategory}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
              ],
            ),

            if (goal.targetMeasure.isNotEmpty || goal.currentMeasure.isNotEmpty)
              Row(
                spacing: 16,
                children: [
                  if (goal.baselineMeasure.isNotEmpty)
                    Expanded(
                      child: _buildMeasureItem('Baseline', goal.baselineMeasure),
                    ),
                  if (goal.currentMeasure.isNotEmpty)
                    Expanded(
                      child: _buildMeasureItem('Current', goal.currentMeasure),
                    ),
                  if (goal.targetMeasure.isNotEmpty)
                    Expanded(
                      child: _buildMeasureItem('Target', goal.targetMeasure),
                    ),
                ],
              ),

            if (goal.barriers.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.block_rounded, color: Colors.amber, size: 16),
                    Expanded(
                      child: Text(
                        'Barriers: ${goal.barriers}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build measure item for goals
  Widget _buildMeasureItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Tab 5: Sessions
  Widget _buildSessionsTab(ColorScheme colorScheme, bool isDark) {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[400]),
            Text(
              'No sessions recorded',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(
        _sessions[index],
        colorScheme,
        isDark,
      ),
    );
  }

  /// Build session card
  Widget _buildSessionCard(
    TreatmentSession session,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final sessionDate = DateFormat('MMM dd, yyyy').format(session.sessionDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      session.sessionType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sessionDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${session.durationMinutes} min',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            if (session.providerName.isNotEmpty || session.providerType.isNotEmpty)
              Text(
                'Provider: ${session.providerName} (${session.providerType})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

            if (session.presentingConcerns.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text('Concerns:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    session.presentingConcerns,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            // Mood Rating
            if (session.moodRating != null && session.moodRating! > 0)
              Row(
                spacing: 8,
                children: [
                  const Text('Mood Rating:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Row(
                    spacing: 2,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: index < session.moodRating!
                            ? Colors.amber
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                  Text('${session.moodRating}/5'),
                ],
              ),

            if (session.sessionNotes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    session.sessionNotes,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            if (session.riskAssessment.isNotEmpty && session.riskAssessment != 'none')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getRiskColor(session.riskAssessment).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getRiskColor(session.riskAssessment).withValues(alpha: 0.3)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: _getRiskColor(session.riskAssessment),
                      size: 16,
                    ),
                    Text(
                      'Risk: ${session.riskAssessment.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(session.riskAssessment),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  Color _getTreatmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'improved':
      case 'resolved':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'worsened':
        return Colors.red;
      case 'ongoing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getMedicationResponseColor(String status) {
    switch (status.toLowerCase()) {
      case 'effective':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'ineffective':
      case 'discontinued':
        return Colors.red;
      case 'monitoring':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getGoalStatusColor(String status, double progress, ColorScheme colorScheme) {
    if (status.toLowerCase() == 'achieved') return Colors.green;
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  Widget _buildEffectivenessBadge(double score, ColorScheme colorScheme) {
    Color scoreColor;
    if (score >= 8) {
      scoreColor = Colors.green;
    } else if (score >= 6) {
      scoreColor = Colors.blue;
    } else if (score >= 4) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${score.toStringAsFixed(1)}/10',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: scoreColor,
        ),
      ),
    );
  }
}
