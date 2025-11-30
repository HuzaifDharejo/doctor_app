import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_card.dart';
import '../../services/clinical_analytics_service.dart';
import '../widgets/analytics_widgets.dart';

/// Clinical Analytics Screen
/// Provides comprehensive analytics with 4 tabs: Trends, Success Rates, Treatment Outcomes, Demographics
class ClinicalAnalyticsScreen extends ConsumerStatefulWidget {
  const ClinicalAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ClinicalAnalyticsScreen> createState() => _ClinicalAnalyticsScreenState();
}

class _ClinicalAnalyticsScreenState extends ConsumerState<ClinicalAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  String? _selectedDiagnosis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDateRange(DateTimeRange? range) {
    setState(() => _selectedDateRange = range);
  }

  void _updateDiagnosis(String? diagnosis) {
    setState(() => _selectedDiagnosis = diagnosis);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = const ClinicalAnalyticsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Analytics'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Success Rates', icon: Icon(Icons.assessment)),
            Tab(text: 'Outcomes', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Demographics', icon: Icon(Icons.people_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Diagnosis Trends
          _buildTrendsTab(context, analyticsService),

          // Tab 2: Success Rates by Specialty
          _buildSuccessRatesTab(context, analyticsService),

          // Tab 3: Treatment Outcomes
          _buildOutcomesTab(context, analyticsService),

          // Tab 4: Patient Demographics
          _buildDemographicsTab(context, analyticsService),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 1: Diagnosis Trends
  // ============================================================================

  Widget _buildTrendsTab(BuildContext context, ClinicalAnalyticsService analyticsService) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter panel
            FilterPanel(
              availableDiagnoses: const ['Hypertension', 'Diabetes Type 2', 'Asthma', 'COPD'],
              onDateRangeChanged: _updateDateRange,
              onDiagnosisChanged: _updateDiagnosis,
            ),
            const SizedBox(height: 24),

            // Trends chart
            TrendChart(
              trendDataFuture: analyticsService.getTrendsByDiagnosis(
                diagnosisFilter: _selectedDiagnosis,
                startDate: _selectedDateRange?.start,
                endDate: _selectedDateRange?.end,
              ),
              title: 'Success Rate Trends',
            ),
            const SizedBox(height: 24),

            // Top trending diagnosis summary
            _buildTrendingSummary(analyticsService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSummary(ClinicalAnalyticsService analyticsService) {
    return FutureBuilder<List<DiagnosisTrend>>(
      future: analyticsService.getTrendsByDiagnosis(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find diagnosis with highest success rate
        final latestTrends = <String, DiagnosisTrend>{};
        for (var trend in snapshot.data!) {
          if (!latestTrends.containsKey(trend.diagnosis) ||
              trend.date.isAfter(latestTrends[trend.diagnosis]!.date)) {
            latestTrends[trend.diagnosis] = trend;
          }
        }

        final sortedTrends = latestTrends.values.toList()
          ..sort((a, b) => b.successRate.compareTo(a.successRate));

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...sortedTrends.map((trend) {
                  final color = trend.successRate >= 90
                      ? Colors.green
                      : trend.successRate >= 80
                          ? Colors.blue
                          : Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trend.diagnosis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${trend.casesReported} cases • ${trend.avgTreatmentDays} days avg',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${trend.successRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: color,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // Tab 2: Success Rates by Specialty
  // ============================================================================

  Widget _buildSuccessRatesTab(BuildContext context, ClinicalAnalyticsService analyticsService) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialty comparison chart
            SpecialtyComparisonChart(
              specialtyDataFuture: analyticsService.getSuccessRatesBySpecialty(),
              title: 'Success Rates by Specialty',
            ),
            const SizedBox(height: 24),

            // Detailed specialty cards
            _buildSpecialtyCards(analyticsService),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyCards(ClinicalAnalyticsService analyticsService) {
    return FutureBuilder<List<SpecialtySuccessRate>>(
      future: analyticsService.getSuccessRatesBySpecialty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No specialty data available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.map((specialty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialty.specialty,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        // Metrics grid
                        GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildMetricItem(
                              'Success Rate',
                              '${specialty.successRate.toStringAsFixed(1)}%',
                              Colors.green,
                            ),
                            _buildMetricItem(
                              'Readmission Rate',
                              '${specialty.readmissionRate.toStringAsFixed(1)}%',
                              Colors.orange,
                            ),
                            _buildMetricItem(
                              'Avg Treatment Days',
                              '${specialty.avgTreatmentDays}',
                              Colors.blue,
                            ),
                            _buildMetricItem(
                              'Total Patients',
                              '${specialty.totalPatients}',
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 3: Treatment Outcomes
  // ============================================================================

  Widget _buildOutcomesTab(BuildContext context, ClinicalAnalyticsService analyticsService) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall outcomes summary
            FutureBuilder<TreatmentOutcomes>(
              future: analyticsService.getTreatmentOutcomes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No data available'));
                }

                final outcomes = snapshot.data!;
                return _buildOutcomeSummary(context, outcomes);
              },
            ),
            const SizedBox(height: 24),

            // Diagnosis-specific metrics
            _buildDiagnosisMetricsSection(analyticsService),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeSummary(BuildContext context, TreatmentOutcomes outcomes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Treatment Outcomes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            SuccessRateCard(
              title: 'Success Rate',
              successRate: outcomes.successRate,
              totalCases: outcomes.totalCases,
              accentColor: Colors.green,
            ),
            SuccessRateCard(
              title: 'Improvement Rate',
              successRate: outcomes.improvementRate,
              totalCases: outcomes.successfulCases,
              accentColor: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildOutcomeRow('Successful', outcomes.successfulCases, Colors.green),
                _buildOutcomeRow('Partially Successful', outcomes.partiallySuccessful, Colors.orange),
                _buildOutcomeRow('Unsuccessful', outcomes.unsuccessful, Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutcomeRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisMetricsSection(ClinicalAnalyticsService analyticsService) {
    return FutureBuilder<DiagnosisMetrics?>(
      future: analyticsService.getDiagnosisMetrics('Hypertension'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final metrics = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnosis-Specific Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metrics.diagnosis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildMetricRow('Total Cases', metrics.totalCases.toString()),
                    _buildMetricRow(
                      'Success Rate',
                      '${metrics.successRate.toStringAsFixed(1)}%',
                    ),
                    _buildMetricRow(
                      'Avg Treatment Days',
                      '${metrics.averageTreatmentDays}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Common Comorbidities',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: metrics.commonComorbidities
                          .map((c) => Chip(label: Text(c)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Frequent Outcomes',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: metrics.frequentOutcomes
                          .map((o) => Chip(label: Text(o)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 4: Patient Demographics
  // ============================================================================

  Widget _buildDemographicsTab(BuildContext context, ClinicalAnalyticsService analyticsService) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age distribution pie chart
            DemographicsVisualization(
              demographicsDataFuture: analyticsService.getPatientDemographics(),
              demographicType: 'age',
              title: 'Patient Distribution by Age',
            ),
            const SizedBox(height: 24),

            // Gender distribution pie chart
            DemographicsVisualization(
              demographicsDataFuture: analyticsService.getPatientDemographics(),
              demographicType: 'gender',
              title: 'Patient Distribution by Gender',
            ),
            const SizedBox(height: 24),

            // Location distribution pie chart
            DemographicsVisualization(
              demographicsDataFuture: analyticsService.getPatientDemographics(),
              demographicType: 'location',
              title: 'Patient Distribution by Location',
            ),
            const SizedBox(height: 24),

            // Total patients summary
            FutureBuilder<PatientDemographics>(
              future: analyticsService.getPatientDemographics(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Patients',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.data!.totalPatients.toString(),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3B82F6),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
