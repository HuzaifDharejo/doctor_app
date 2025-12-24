import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/drift_extensions.dart';
import '../../services/growth_chart_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';

/// Screen for pediatric growth charts and measurements
class GrowthChartScreen extends ConsumerStatefulWidget {
  final int? patientId;

  const GrowthChartScreen({super.key, this.patientId});

  @override
  ConsumerState<GrowthChartScreen> createState() => _GrowthChartScreenState();
}

class _GrowthChartScreenState extends ConsumerState<GrowthChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _growthService = GrowthChartService();
  String _selectedChartType = 'weight';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.show_chart,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onPressed: _showGrowthChart,
                    tooltip: 'View chart',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.child_care,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Growth Charts',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pediatric growth tracking',
                                style: TextStyle(
                                  fontSize: 14,
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
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Measurements'),
                Tab(text: 'Percentiles'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMeasurementsTab(),
            _buildPercentilesTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Measurement'),
        backgroundColor: const Color(0xFFEC4899),
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    return FutureBuilder<List<GrowthMeasurementData>>(
      future: _growthService.getAllMeasurements(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // Get latest measurement
        final latest = snapshot.data!.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLatestMeasurementCard(latest),
              const SizedBox(height: 16),
              _buildQuickStats(snapshot.data!),
              const SizedBox(height: 16),
              _buildChartTypeSelector(),
              const SizedBox(height: 16),
              _buildMiniChart(snapshot.data!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLatestMeasurementCard(GrowthMeasurementData measurement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Latest: ${_formatDate(measurement.measurementDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (measurement.ageMonths != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatAge(measurement.ageMonths!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMeasurementValue(
                  'Weight',
                  '${measurement.weightKg?.toStringAsFixed(1) ?? '-'} kg',
                  Icons.monitor_weight,
                  Colors.blue,
                ),
                _buildMeasurementValue(
                  'Height',
                  '${measurement.heightCm?.toStringAsFixed(1) ?? '-'} cm',
                  Icons.height,
                  Colors.green,
                ),
                _buildMeasurementValue(
                  'Head',
                  '${measurement.headCircumferenceCm?.toStringAsFixed(1) ?? '-'} cm',
                  Icons.circle_outlined,
                  Colors.orange,
                ),
              ],
            ),
            if (measurement.bmi != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getBmiColor(measurement.bmi!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'BMI: ',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          measurement.bmi!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getBmiColor(measurement.bmi!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementValue(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<GrowthMeasurementData> measurements) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate growth velocity if we have at least 2 measurements
    String weightChange = '-';
    String heightChange = '-';

    if (measurements.length >= 2) {
      final latest = measurements.first;
      final previous = measurements[1];

      if (latest.weightKg != null && previous.weightKg != null) {
        final change = latest.weightKg! - previous.weightKg!;
        weightChange = '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg';
      }

      if (latest.heightCm != null && previous.heightCm != null) {
        final change = latest.heightCm! - previous.heightCm!;
        heightChange = '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} cm';
      }
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Column(
                children: [
                  Text(
                    'Weight Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weightChange,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: weightChange.startsWith('+') ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Column(
                children: [
                  Text(
                    'Height Change',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    heightChange,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: heightChange.startsWith('+') ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Column(
                children: [
                  Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${measurements.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChartChip('weight', 'Weight', Icons.monitor_weight, Colors.blue),
          const SizedBox(width: 8),
          _buildChartChip('height', 'Height', Icons.height, Colors.green),
          const SizedBox(width: 8),
          _buildChartChip('head', 'Head Circ.', Icons.circle_outlined, Colors.orange),
          const SizedBox(width: 8),
          _buildChartChip('bmi', 'BMI', Icons.analytics, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildChartChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedChartType == type;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      onSelected: (selected) {
        setState(() => _selectedChartType = type);
      },
    );
  }

  Widget _buildMiniChart(List<GrowthMeasurementData> measurements) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simple visual representation
    final values = measurements.take(10).toList().reversed.map((m) {
      switch (_selectedChartType) {
        case 'weight':
          return m.weightKg ?? 0.0;
        case 'height':
          return m.heightCm ?? 0.0;
        case 'head':
          return m.headCircumferenceCm ?? 0.0;
        case 'bmi':
          return m.bmi ?? 0.0;
        default:
          return 0.0;
      }
    }).toList();

    if (values.isEmpty) return const SizedBox();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Growth Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final normalizedHeight = range > 0
                      ? ((value - minVal) / range * 80) + 20
                      : 50.0;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: normalizedHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _getChartColor(_selectedChartType),
                            _getChartColor(_selectedChartType).withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earlier',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(String type) {
    switch (type) {
      case 'weight':
        return Colors.blue;
      case 'height':
        return Colors.green;
      case 'head':
        return Colors.orange;
      case 'bmi':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPercentilesTab() {
    return FutureBuilder<List<GrowthMeasurementData>>(
      future: _growthService.getAllMeasurements(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final latest = snapshot.data!.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildPercentileCard(
                'Weight-for-Age',
                latest.weightPercentile,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildPercentileCard(
                'Height-for-Age',
                latest.heightPercentile,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildPercentileCard(
                'Head Circumference',
                latest.headPercentile,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildPercentileCard(
                'BMI-for-Age',
                latest.bmiPercentile,
                Colors.purple,
              ),
              const SizedBox(height: 24),
              _buildPercentileInterpretation(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPercentileCard(String label, double? percentile, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = percentile ?? 50.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(0)}th',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0%',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '50%',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileInterpretation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Percentile Interpretation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInterpretationRow('< 5th', 'Below normal range', Colors.red),
            _buildInterpretationRow('5th - 85th', 'Normal range', Colors.green),
            _buildInterpretationRow('85th - 95th', 'At risk', Colors.orange),
            _buildInterpretationRow('> 95th', 'Above normal range', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpretationRow(String range, String meaning, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(range, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text('- $meaning'),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<GrowthMeasurementData>>(
      future: _growthService.getAllMeasurements(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(GrowthMeasurementData measurement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(measurement.measurementDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (measurement.ageMonths != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatAge(measurement.ageMonths!),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (measurement.weightKg != null)
                  _buildHistoryItem('Weight', '${measurement.weightKg!.toStringAsFixed(1)} kg', Colors.blue),
                if (measurement.heightCm != null)
                  _buildHistoryItem('Height', '${measurement.heightCm!.toStringAsFixed(1)} cm', Colors.green),
                if (measurement.headCircumferenceCm != null)
                  _buildHistoryItem('Head', '${measurement.headCircumferenceCm!.toStringAsFixed(1)} cm', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No growth measurements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a measurement to start tracking',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatAge(int months) {
    if (months < 12) {
      return '$months mo';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years yr';
      }
      return '$years yr $remainingMonths mo';
    }
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showGrowthChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: EdgeInsets.all(context.responsivePadding),
                  child: Row(
                    children: [
                      Icon(Icons.show_chart, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Full Growth Chart',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Chart content
                Expanded(
                  child: FutureBuilder<List<GrowthMeasurementData>>(
                    future: _growthService.getAllMeasurements(widget.patientId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No growth data available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final measurements = snapshot.data!.reversed.toList();
                      return _buildFullChart(measurements, scrollController, isDark);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFullChart(List<GrowthMeasurementData> measurements, ScrollController scrollController, bool isDark) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(context.responsivePadding),
      children: [
        // Weight Chart
        _buildFullChartCard('Weight (kg)', measurements, 'weight', Colors.blue, isDark),
        const SizedBox(height: 16),
        // Height Chart
        _buildFullChartCard('Height (cm)', measurements, 'height', Colors.green, isDark),
        const SizedBox(height: 16),
        // Head Circumference Chart
        _buildFullChartCard('Head Circumference (cm)', measurements, 'head', Colors.orange, isDark),
        const SizedBox(height: 16),
        // BMI Chart
        _buildFullChartCard('BMI', measurements, 'bmi', Colors.purple, isDark),
        const SizedBox(height: 24),
        // Data Table
        _buildDataTable(measurements, isDark),
      ],
    );
  }
  
  Widget _buildFullChartCard(String title, List<GrowthMeasurementData> measurements, String type, Color color, bool isDark) {
    final values = measurements.map((m) {
      switch (type) {
        case 'weight':
          return m.weightKg ?? 0.0;
        case 'height':
          return m.heightCm ?? 0.0;
        case 'head':
          return m.headCircumferenceCm ?? 0.0;
        case 'bmi':
          return m.bmi ?? 0.0;
        default:
          return 0.0;
      }
    }).toList();
    
    // Filter out zero values
    final nonZeroValues = values.where((v) => v > 0).toList();
    if (nonZeroValues.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final maxVal = nonZeroValues.reduce((a, b) => a > b ? a : b);
    final minVal = nonZeroValues.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;
    
    return Card(
      color: isDark ? AppColors.darkBackground : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Latest: ${nonZeroValues.isNotEmpty ? nonZeroValues.last.toStringAsFixed(1) : "N/A"}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _GrowthChartPainter(
                  values: values,
                  color: color,
                  minVal: range > 0 ? minVal : minVal - 1,
                  maxVal: range > 0 ? maxVal : maxVal + 1,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  measurements.isNotEmpty ? _formatDate(measurements.first.measurementDate) : '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                Text(
                  measurements.isNotEmpty ? _formatDate(measurements.last.measurementDate) : '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataTable(List<GrowthMeasurementData> measurements, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkBackground : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Height')),
                  DataColumn(label: Text('Head')),
                  DataColumn(label: Text('BMI')),
                ],
                rows: measurements.take(10).map((m) => DataRow(
                  cells: [
                    DataCell(Text(_formatDate(m.measurementDate))),
                    DataCell(Text(m.weightKg != null ? '${m.weightKg!.toStringAsFixed(1)} kg' : '-')),
                    DataCell(Text(m.heightCm != null ? '${m.heightCm!.toStringAsFixed(1)} cm' : '-')),
                    DataCell(Text(m.headCircumferenceCm != null ? '${m.headCircumferenceCm!.toStringAsFixed(1)} cm' : '-')),
                    DataCell(Text(m.bmi != null ? m.bmi!.toStringAsFixed(1) : '-')),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final headController = TextEditingController();
    final ageController = TextEditingController();
    DateTime measurementDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add Measurement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: measurementDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() => measurementDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Measurement Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDate(measurementDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (months)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                                suffixText: 'kg',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: heightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Height',
                                suffixText: 'cm',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: headController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Head Circumference',
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final weight = double.tryParse(weightController.text);
                            final height = double.tryParse(heightController.text);

                            await _growthService.recordMeasurement(
                              patientId: widget.patientId ?? 1,
                              measurementDate: measurementDate,
                              weightKg: weight,
                              heightCm: height,
                              headCircumferenceCm: double.tryParse(headController.text),
                              ageMonths: int.tryParse(ageController.text),
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Measurement recorded')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save Measurement'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Custom painter for growth chart lines
class _GrowthChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double minVal;
  final double maxVal;
  final bool isDark;

  _GrowthChartPainter({
    required this.values,
    required this.color,
    required this.minVal,
    required this.maxVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    final range = maxVal - minVal;

    List<Offset> points = [];
    
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1).clamp(1, values.length);
      final normalizedY = range > 0 
          ? (values[i] - minVal) / range 
          : 0.5;
      final y = size.height - (normalizedY * size.height * 0.9 + size.height * 0.05);
      
      if (values[i] > 0) {
        points.add(Offset(x, y));
      }
    }

    if (points.isEmpty) return;

    // Draw path
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = isDark ? AppColors.darkSurface : Colors.white,
      );
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
