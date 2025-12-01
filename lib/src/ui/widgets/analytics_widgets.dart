import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/clinical_analytics_service.dart';

// ============================================================================
// Trend Chart Widget - LineChart visualization
// ============================================================================

class TrendChart extends ConsumerWidget {
  final Future<List<DiagnosisTrend>> trendDataFuture;
  final String? title;

  const TrendChart({
    Key? key,
    required this.trendDataFuture,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<DiagnosisTrend>>(
      future: trendDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading trends: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No trend data available'));
        }

        final trends = snapshot.data!;
        return _buildTrendChart(context, trends);
      },
    );
  }

  Widget _buildTrendChart(BuildContext context, List<DiagnosisTrend> trends) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Group by diagnosis and get latest 5 data points
    final Map<String, List<DiagnosisTrend>> groupedTrends = {};
    for (var trend in trends) {
      if (!groupedTrends.containsKey(trend.diagnosis)) {
        groupedTrends[trend.diagnosis] = [];
      }
      groupedTrends[trend.diagnosis]!.add(trend);
    }

    // Sort each group by date
    groupedTrends.forEach((_, trendList) {
      trendList.sort((a, b) => a.date.compareTo(b.date));
    });

    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green
      Color(0xFFEF4444), // Red
      Color(0xFFF59E0B), // Amber
    ];

    final spots = <String, List<FlSpot>>{};
    groupedTrends.forEach((diagnosis, trendList) {
      spots[diagnosis] = trendList
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.successRate))
          .toList();
    });

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          'W${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: spots.entries.map((entry) {
                    final colorIndex = spots.keys.toList().indexOf(entry.key);
                    return LineChartBarData(
                      spots: entry.value,
                      isCurved: true,
                      color: colors[colorIndex % colors.length],
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: colors[colorIndex % colors.length],
                        ),
                      ),
                    );
                  }).toList(),
                  minY: 60,
                  maxY: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              children: groupedTrends.keys.map((diagnosis) {
                final colorIndex = groupedTrends.keys.toList().indexOf(diagnosis);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[colorIndex % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      diagnosis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Success Rate Card Widget - KPI display with comparison
// ============================================================================

class SuccessRateCard extends StatelessWidget {
  final String title;
  final double successRate;
  final double? previousRate;
  final int totalCases;
  final Color? accentColor;

  const SuccessRateCard({
    Key? key,
    required this.title,
    required this.successRate,
    this.previousRate,
    required this.totalCases,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? const Color(0xFF3B82F6);
    final improvement = previousRate != null ? successRate - previousRate! : null;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Rate percentage display
            Row(
              children: [
                Text(
                  '${successRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 12),
                if (improvement != null)
                  Chip(
                    label: Text(
                      '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: improvement > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: improvement > 0
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Cases count
            Text(
              '$totalCases cases',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: successRate / 100,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Specialty Comparison Chart Widget - BarChart
// ============================================================================

class SpecialtyComparisonChart extends ConsumerWidget {
  final Future<List<SpecialtySuccessRate>> specialtyDataFuture;
  final String? title;

  const SpecialtyComparisonChart({
    Key? key,
    required this.specialtyDataFuture,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<SpecialtySuccessRate>>(
      future: specialtyDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No specialty data available'));
        }

        return _buildComparisonChart(context, snapshot.data!);
      },
    );
  }

  Widget _buildComparisonChart(
    BuildContext context,
    List<SpecialtySuccessRate> specialties,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barGroups = specialties
        .asMap()
        .entries
        .map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.successRate,
                  color: _getColorForRate(entry.value.successRate),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ))
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < specialties.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                specialties[index].specialty,
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 90) return const Color(0xFF10B981); // Green
    if (rate >= 80) return const Color(0xFF3B82F6); // Blue
    if (rate >= 70) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }
}

// ============================================================================
// Demographics Visualization Widget - PieChart
// ============================================================================

class DemographicsVisualization extends ConsumerWidget {
  final Future<PatientDemographics> demographicsDataFuture;
  final String demographicType; // 'age', 'gender', 'location'
  final String title;

  const DemographicsVisualization({
    Key? key,
    required this.demographicsDataFuture,
    required this.demographicType,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PatientDemographics>(
      future: demographicsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final Map<String, int> data;
        switch (demographicType) {
          case 'age':
            data = snapshot.data!.ageGroups;
            break;
          case 'gender':
            data = snapshot.data!.genderDistribution;
            break;
          case 'location':
            data = snapshot.data!.locationDistribution;
            break;
          default:
            data = snapshot.data!.ageGroups;
        }

        return _buildPieChart(context, data);
      },
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, int> data) {
    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green
      Color(0xFFEF4444), // Red
      Color(0xFFF59E0B), // Amber
      Color(0xFF8B5CF6), // Purple
    ];

    final total = data.values.fold<int>(0, (sum, val) => sum + val);
    final sections = data.entries
        .toList()
        .asMap()
        .entries
        .map((entry) => PieChartSectionData(
              value: entry.value.value.toDouble(),
              title: '${((entry.value.value / total) * 100).toStringAsFixed(1)}%',
              color: colors[entry.key % colors.length],
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ))
        .toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(sections: sections),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[entry.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value.key} (${entry.value.value})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Filter Panel Widget - Diagnosis & Date Range Filters
// ============================================================================

class FilterPanel extends StatefulWidget {
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function(String?) onDiagnosisChanged;
  final List<String> availableDiagnoses;

  const FilterPanel({
    Key? key,
    required this.onDateRangeChanged,
    required this.onDiagnosisChanged,
    required this.availableDiagnoses,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  DateTimeRange? _selectedDateRange;
  String? _selectedDiagnosis;

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      setState(() => _selectedDateRange = pickedRange);
      widget.onDateRangeChanged(pickedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Date range picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDateRange != null
                    ? '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}'
                    : 'Select Date Range',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: _selectDateRange,
            ),
            const Divider(),
            // Diagnosis dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('All Diagnoses'),
                value: _selectedDiagnosis,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Diagnoses'),
                  ),
                  ...widget.availableDiagnoses.map((diagnosis) {
                    return DropdownMenuItem<String>(
                      value: diagnosis,
                      child: Text(diagnosis),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedDiagnosis = value);
                  widget.onDiagnosisChanged(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Clear filters button
            if (_selectedDateRange != null || _selectedDiagnosis != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;
                    _selectedDiagnosis = null;
                  });
                  widget.onDateRangeChanged(null);
                  widget.onDiagnosisChanged(null);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }
}

