import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../core/theme/design_tokens.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/vital_thresholds_service.dart' as vital_service;
import '../widgets/vital_signs_alert_dialog.dart';
import '../widgets/quick_vital_entry_modal.dart';

/// Screen to view and add vital signs for a patient
class VitalSignsScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const VitalSignsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<VitalSignsScreen> createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends ConsumerState<VitalSignsScreen> with SingleTickerProviderStateMixin {
  List<VitalSign> _vitalSigns = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVitalSigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVitalSigns() async {
    final dbAsync = ref.read(doctorDbProvider);
    dbAsync.when(
      data: (db) async {
        final vitals = await db.getVitalSignsForPatient(widget.patientId);
        if (mounted) {
          setState(() {
            _vitalSigns = vitals;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Vital Signs - ${widget.patientName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History', icon: Icon(Icons.list)),
            Tab(text: 'Blood Pressure', icon: Icon(Icons.favorite)),
            Tab(text: 'Weight & BMI', icon: Icon(Icons.monitor_weight)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(colorScheme),
                _buildBloodPressureChart(colorScheme),
                _buildWeightChart(colorScheme),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickVitalEntryModal.showAdaptive(
          context: context,
          patientId: widget.patientId,
          patientName: widget.patientName,
          onSaved: _loadVitalSigns,
        ),
        tooltip: 'Quick Vital Entry',
        child: const Icon(Icons.speed_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHistoryTab(ColorScheme colorScheme) {
    if (_vitalSigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No vital signs recorded yet',
              style: TextStyle(fontSize: 18, color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            const Text('Tap the button below to add vitals'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _vitalSigns.length,
      itemBuilder: (context, index) {
        final vital = _vitalSigns[index];
        return _buildVitalCard(vital, colorScheme);
      },
    );
  }

  Widget _buildVitalCard(VitalSign vital, ColorScheme colorScheme) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.monitor_heart, color: colorScheme.primary),
        ),
        title: Text(dateFormat.format(vital.recordedAt)),
        subtitle: Text(_buildQuickSummary(vital)),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildVitalRow('Blood Pressure', 
                  vital.systolicBp != null && vital.diastolicBp != null
                    ? '${vital.systolicBp!.toInt()}/${vital.diastolicBp!.toInt()} mmHg'
                    : '--',
                  _getBpStatus(vital.systolicBp, vital.diastolicBp),
                  colorScheme,
                ),
                _buildVitalRow('Heart Rate', 
                  vital.heartRate != null ? '${vital.heartRate} bpm' : '--',
                  _getHeartRateStatus(vital.heartRate),
                  colorScheme,
                ),
                _buildVitalRow('Temperature', 
                  vital.temperature != null ? '${vital.temperature!.toStringAsFixed(1)}°C' : '--',
                  _getTempStatus(vital.temperature),
                  colorScheme,
                ),
                _buildVitalRow('SpO2', 
                  vital.oxygenSaturation != null ? '${vital.oxygenSaturation!.toStringAsFixed(0)}%' : '--',
                  _getSpO2Status(vital.oxygenSaturation),
                  colorScheme,
                ),
                _buildVitalRow('Respiratory Rate', 
                  vital.respiratoryRate != null ? '${vital.respiratoryRate} /min' : '--',
                  _getRespRateStatus(vital.respiratoryRate),
                  colorScheme,
                ),
                _buildVitalRow('Weight', 
                  vital.weight != null ? '${vital.weight!.toStringAsFixed(1)} kg' : '--',
                  null,
                  colorScheme,
                ),
                _buildVitalRow('Height', 
                  vital.height != null ? '${vital.height!.toStringAsFixed(0)} cm' : '--',
                  null,
                  colorScheme,
                ),
                _buildVitalRow('BMI', 
                  vital.bmi != null ? vital.bmi!.toStringAsFixed(1) : '--',
                  _getBmiStatus(vital.bmi),
                  colorScheme,
                ),
                _buildVitalRow('Pain Level', 
                  vital.painLevel != null ? '${vital.painLevel}/10' : '--',
                  _getPainStatus(vital.painLevel),
                  colorScheme,
                ),
                _buildVitalRow('Blood Glucose', 
                  vital.bloodGlucose.isNotEmpty ? '${vital.bloodGlucose} mg/dL' : '--',
                  null,
                  colorScheme,
                ),
                if (vital.notes.isNotEmpty) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Notes'),
                    subtitle: Text(vital.notes),
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteVital(vital.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, String? status, ColorScheme colorScheme) {
    Color? statusColor;
    if (status == 'normal') {
      statusColor = Colors.green;
    } else if (status == 'warning') {
      statusColor = Colors.orange;
    } else if (status == 'critical') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: colorScheme.outline)),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status!,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  String _buildQuickSummary(VitalSign vital) {
    final parts = <String>[];
    if (vital.systolicBp != null && vital.diastolicBp != null) {
      parts.add('BP: ${vital.systolicBp!.toInt()}/${vital.diastolicBp!.toInt()}');
    }
    if (vital.heartRate != null) {
      parts.add('HR: ${vital.heartRate}');
    }
    if (vital.oxygenSaturation != null) {
      parts.add('SpO2: ${vital.oxygenSaturation!.toInt()}%');
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'No measurements';
  }

  String? _getBpStatus(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return null;
    if (systolic >= 180 || diastolic >= 120) return 'critical';
    if (systolic >= 140 || diastolic >= 90) return 'warning';
    if (systolic < 90 || diastolic < 60) return 'warning';
    return 'normal';
  }

  String? _getHeartRateStatus(int? hr) {
    if (hr == null) return null;
    if (hr > 100 || hr < 60) return 'warning';
    if (hr > 120 || hr < 50) return 'critical';
    return 'normal';
  }

  String? _getTempStatus(double? temp) {
    if (temp == null) return null;
    if (temp >= 39 || temp < 35) return 'critical';
    if (temp >= 37.5 || temp < 36) return 'warning';
    return 'normal';
  }

  String? _getSpO2Status(double? spo2) {
    if (spo2 == null) return null;
    if (spo2 < 90) return 'critical';
    if (spo2 < 95) return 'warning';
    return 'normal';
  }

  String? _getRespRateStatus(int? rate) {
    if (rate == null) return null;
    if (rate > 25 || rate < 10) return 'critical';
    if (rate > 20 || rate < 12) return 'warning';
    return 'normal';
  }

  String? _getBmiStatus(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'warning'; // underweight
    if (bmi >= 30) return 'critical'; // obese
    if (bmi >= 25) return 'warning'; // overweight
    return 'normal';
  }

  String? _getPainStatus(int? pain) {
    if (pain == null) return null;
    if (pain >= 7) return 'critical';
    if (pain >= 4) return 'warning';
    return 'normal';
  }

  Widget _buildBloodPressureChart(ColorScheme colorScheme) {
    final bpData = _vitalSigns
        .where((v) => v.systolicBp != null && v.diastolicBp != null)
        .take(14)
        .toList()
        .reversed
        .toList();

    if (bpData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No blood pressure data available', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text('Blood Pressure Trend (Last ${bpData.length} readings)', 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Systolic', Colors.red),
              const SizedBox(width: 24),
              _buildLegend('Diastolic', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < bpData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(bpData[value.toInt()].recordedAt),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: colorScheme.outline)),
                minY: 40,
                maxY: 200,
                lineBarsData: [
                  // Systolic
                  LineChartBarData(
                    spots: bpData.asMap().entries.map((e) => 
                      FlSpot(e.key.toDouble(), e.value.systolicBp!)).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // Diastolic
                  LineChartBarData(
                    spots: bpData.asMap().entries.map((e) => 
                      FlSpot(e.key.toDouble(), e.value.diastolicBp!)).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final color = spot.barIndex == 0 ? Colors.red : Colors.blue;
                        final label = spot.barIndex == 0 ? 'Sys' : 'Dia';
                        return LineTooltipItem(
                          '$label: ${spot.y.toInt()}',
                          TextStyle(color: color, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBpStatsCard(bpData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWeightChart(ColorScheme colorScheme) {
    final weightData = _vitalSigns
        .where((v) => v.weight != null)
        .take(14)
        .toList()
        .reversed
        .toList();

    if (weightData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No weight data available', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      );
    }

    final minWeight = weightData.map((e) => e.weight!).reduce((a, b) => a < b ? a : b);
    final maxWeight = weightData.map((e) => e.weight!).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text('Weight Trend (Last ${weightData.length} readings)', 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weightData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(weightData[value.toInt()].recordedAt),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toStringAsFixed(1)}kg', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: colorScheme.outline)),
                minY: minWeight - 5,
                maxY: maxWeight + 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: weightData.asMap().entries.map((e) => 
                      FlSpot(e.key.toDouble(), e.value.weight!)).toList(),
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final vital = weightData[spot.x.toInt()];
                        return LineTooltipItem(
                          'Weight: ${spot.y.toStringAsFixed(1)}kg${vital.bmi != null ? '\nBMI: ${vital.bmi!.toStringAsFixed(1)}' : ''}',
                          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildWeightStatsCard(weightData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBpStatsCard(List<VitalSign> data, ColorScheme colorScheme) {
    final avgSys = data.map((e) => e.systolicBp!).reduce((a, b) => a + b) / data.length;
    final avgDia = data.map((e) => e.diastolicBp!).reduce((a, b) => a + b) / data.length;
    final maxSys = data.map((e) => e.systolicBp!).reduce((a, b) => a > b ? a : b);
    final minSys = data.map((e) => e.systolicBp!).reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Average', '${avgSys.toInt()}/${avgDia.toInt()}', colorScheme),
            _buildStatColumn('Highest', '${maxSys.toInt()} mmHg', colorScheme),
            _buildStatColumn('Lowest', '${minSys.toInt()} mmHg', colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightStatsCard(List<VitalSign> data, ColorScheme colorScheme) {
    final current = data.last.weight!;
    final first = data.first.weight!;
    final change = current - first;
    final changeStr = change >= 0 ? '+${change.toStringAsFixed(1)}' : change.toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Current', '${current.toStringAsFixed(1)} kg', colorScheme),
            _buildStatColumn('Change', '$changeStr kg', colorScheme, 
              color: change == 0 ? null : (change > 0 ? Colors.orange : Colors.green)),
            if (data.last.bmi != null)
              _buildStatColumn('Current BMI', data.last.bmi!.toStringAsFixed(1), colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ColorScheme colorScheme, {Color? color}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Future<void> _deleteVital(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vital Signs'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dbAsync = ref.read(doctorDbProvider);
      dbAsync.whenData((db) async {
        await db.deleteVitalSigns(id);
        await _loadVitalSigns();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vital signs deleted')),
          );
        }
      });
    }
  }

  void _showAddVitalSignsDialog() {
    // Controllers for form fields
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final heartRateController = TextEditingController();
    final temperatureController = TextEditingController();
    final respRateController = TextEditingController();
    final spo2Controller = TextEditingController();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final painLevelController = TextEditingController();
    final glucoseController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Vital Signs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicController,
                      decoration: const InputDecoration(
                        labelText: 'Systolic BP',
                        suffixText: 'mmHg',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('/'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic BP',
                        suffixText: 'mmHg',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heartRateController,
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate',
                        suffixText: 'bpm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: spo2Controller,
                      decoration: const InputDecoration(
                        labelText: 'SpO2',
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: temperatureController,
                      decoration: const InputDecoration(
                        labelText: 'Temperature',
                        suffixText: '°C',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: respRateController,
                      decoration: const InputDecoration(
                        labelText: 'Resp Rate',
                        suffixText: '/min',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: painLevelController,
                      decoration: const InputDecoration(
                        labelText: 'Pain Level',
                        suffixText: '/10',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: glucoseController,
                      decoration: const InputDecoration(
                        labelText: 'Blood Glucose',
                        suffixText: 'mg/dL',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppInput.multiline(
                controller: notesController,
                label: 'Notes',
                hint: 'Any additional notes...',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppButton.primary(
            label: 'Save',
            onPressed: () async {
              final systolic = double.tryParse(systolicController.text);
              final diastolic = double.tryParse(diastolicController.text);
              final heartRate = int.tryParse(heartRateController.text);
              final temp = double.tryParse(temperatureController.text);
              final respRate = int.tryParse(respRateController.text);
              final spo2 = double.tryParse(spo2Controller.text);
              final weight = double.tryParse(weightController.text);
              final height = double.tryParse(heightController.text);
              final painLevel = int.tryParse(painLevelController.text);

              // Calculate BMI if weight and height are provided
              double? bmi;
              if (weight != null && height != null && height > 0) {
                bmi = weight / ((height / 100) * (height / 100));
              }

              final dbAsync = ref.read(doctorDbProvider);
              dbAsync.whenData((db) async {
                await db.insertVitalSigns(VitalSignsCompanion.insert(
                  patientId: widget.patientId,
                  recordedAt: DateTime.now(),
                  systolicBp: Value(systolic),
                  diastolicBp: Value(diastolic),
                  heartRate: Value(heartRate),
                  temperature: Value(temp),
                  respiratoryRate: Value(respRate),
                  oxygenSaturation: Value(spo2),
                  weight: Value(weight),
                  height: Value(height),
                  bmi: Value(bmi),
                  painLevel: Value(painLevel),
                  bloodGlucose: Value(glucoseController.text),
                  notes: Value(notesController.text),
                ));

                // Check vital signs against clinical thresholds
                final vitalsList = <vital_service.VitalSign>[];
                if (systolic != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'Systolic BP',
                    value: systolic,
                    unit: 'mmHg',
                    minNormal: 90,
                    maxNormal: 130,
                    criticalLow: 80,
                    criticalHigh: 180,
                  ));
                }
                if (diastolic != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'Diastolic BP',
                    value: diastolic,
                    unit: 'mmHg',
                    minNormal: 60,
                    maxNormal: 85,
                    criticalLow: 50,
                    criticalHigh: 120,
                  ));
                }
                if (heartRate != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'Heart Rate',
                    value: heartRate.toDouble(),
                    unit: 'bpm',
                    minNormal: 60,
                    maxNormal: 100,
                    criticalLow: 40,
                    criticalHigh: 120,
                  ));
                }
                if (temp != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'Temperature',
                    value: temp,
                    unit: '°C',
                    minNormal: 36.5,
                    maxNormal: 37.5,
                    criticalLow: 35,
                    criticalHigh: 38.5,
                  ));
                }
                if (spo2 != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'O2 Saturation',
                    value: spo2,
                    unit: '%',
                    minNormal: 95,
                    maxNormal: 100,
                    criticalLow: 90,
                    criticalHigh: 100,
                  ));
                }
                if (respRate != null) {
                  vitalsList.add(vital_service.VitalSign(
                    name: 'Respiratory Rate',
                    value: respRate.toDouble(),
                    unit: '/min',
                    minNormal: 12,
                    maxNormal: 20,
                    criticalLow: 10,
                    criticalHigh: 24,
                  ));
                }

                // Get abnormal and critical vitals
                final abnormalVitals = vitalsList.where((v) => v.isAbnormal).toList();
                final criticalVitals = vitalsList.where((v) => v.isCritical).toList();

                Navigator.pop(context);
                await _loadVitalSigns();

                // Show alert if there are abnormal/critical vitals
                if (abnormalVitals.isNotEmpty || criticalVitals.isNotEmpty) {
                  if (mounted) {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => VitalSignsAlertDialog(
                        abnormalVitals: abnormalVitals,
                        criticalVitals: criticalVitals,
                        onAcknowledge: () {
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vital signs recorded and acknowledged'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vital signs recorded successfully')),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }
}


