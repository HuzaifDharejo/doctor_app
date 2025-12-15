import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../models/lab_order.dart';
import '../../providers/db_provider.dart';
import '../../services/lab_order_service.dart';
import '../../services/lab_test_templates.dart';
import '../../theme/app_theme.dart';
import 'medical_record_detail_screen.dart';
import 'records/add_lab_result_screen.dart';

/// Screen for managing lab orders and results
class LabOrdersScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const LabOrdersScreen({super.key, this.patientId});

  @override
  ConsumerState<LabOrdersScreen> createState() => _LabOrdersScreenState();
}

class _LabOrdersScreenState extends ConsumerState<LabOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _labOrderService = LabOrderService();
  final _searchController = TextEditingController();

  // Cache for display names (V5: fetched from LabTestResults table)
  final Map<int, String> _displayNameCache = {};
  final Map<int, String?> _displayCodeCache = {};

  // Theme color for lab orders
  static const _themeColor = Color(0xFF8B5CF6); // Purple theme

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Get display name for an order (V5: from LabTestResults)
  Future<String> _getDisplayName(LabOrderData order) async {
    if (_displayNameCache.containsKey(order.id)) {
      return _displayNameCache[order.id]!;
    }
    final name = await _labOrderService.getDisplayTestName(order.id);
    _displayNameCache[order.id] = name;
    return name;
  }

  /// Get display code for an order (V5: from LabTestResults)
  Future<String?> _getDisplayCode(LabOrderData order) async {
    if (_displayCodeCache.containsKey(order.id)) {
      return _displayCodeCache[order.id];
    }
    final code = await _labOrderService.getDisplayTestCode(order.id);
    _displayCodeCache[order.id] = code;
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildModernSliverAppBar(context, isDark, colorScheme),
        ],
        body: Column(
          children: [
            // Modern Search Bar
            _buildSearchBar(isDark),
            
            // Tab Bar
            _buildTabBar(isDark),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLabOrdersList(null),
                  _buildLabOrdersList('ordered'),
                  _buildLabOrdersList('in_progress'),
                  _buildLabOrdersList('completed'),
                  _buildLabResultsList(), // From medical records
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.patientId != null ? _buildModernFAB() : null,
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppColors.textPrimary,
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
                  ? [const Color(0xFF1A1A2E), colorScheme.surface]
                  : [colorScheme.surface, Theme.of(context).scaffoldBackgroundColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lab Orders',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order & track laboratory tests',
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
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search lab orders...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: _themeColor,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicator: BoxDecoration(
          color: _themeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: -8),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(12),
        tabs: [
          _buildLabTab('All', Icons.list_alt_rounded),
          _buildLabTab('Pending', Icons.pending_actions_rounded),
          _buildLabTab('In Progress', Icons.hourglass_top_rounded),
          _buildLabTab('Completed', Icons.check_circle_rounded),
          _buildLabTab('Results', Icons.assignment_rounded),
        ],
      ),
    );
  }

  Widget _buildLabTab(String label, IconData icon) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreateOrderDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLabOrdersList(String? statusFilter) {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    return FutureBuilder<List<LabOrderData>>(
      future: _fetchLabOrders(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading lab orders...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        final orders = snapshot.data!
            .where((o) => _matchesSearch(o))
            .toList();

        if (orders.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _displayNameCache.clear();
            _displayCodeCache.clear();
            setState(() {});
          },
          color: _themeColor,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildLabOrderCard(orders[index]),
              );
            },
          ),
        );
      },
    );
  }

  /// Build lab results list from medical records (recordType = 'lab_result')
  Widget _buildLabResultsList() {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    final dbAsync = ref.watch(doctorDbProvider);
    
    return dbAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_themeColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading lab results...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (db) => FutureBuilder<List<MedicalRecord>>(
        future: _fetchLabResults(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _themeColor));
          }

          final results = snapshot.data ?? [];
          
          if (results.isEmpty) {
            return _buildEmptyLabResultsState();
          }

          // Filter by search
          final filteredResults = results.where((r) {
            if (_searchController.text.isEmpty) return true;
            final query = _searchController.text.toLowerCase();
            final testName = r.diagnosis ?? '';
            final notes = r.doctorNotes ?? '';
            return testName.toLowerCase().contains(query) ||
                   notes.toLowerCase().contains(query);
          }).toList();

          if (filteredResults.isEmpty) {
            return _buildEmptyLabResultsState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: _themeColor,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                return _buildLabResultCard(filteredResults[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<MedicalRecord>> _fetchLabResults(DoctorDatabase db) async {
    final records = await db.getMedicalRecordsForPatient(widget.patientId!);
    return records.where((r) => r.recordType == 'lab_result').toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
  }

  Widget _buildEmptyLabResultsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.science_outlined,
              size: 48,
              color: _themeColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Lab Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lab results from medical records will appear here',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final db = ref.read(doctorDbProvider).value;
              if (db != null) {
                final patient = await db.getPatientById(widget.patientId!);
                if (patient != null && mounted) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLabResultScreen(preselectedPatient: patient),
                    ),
                  );
                  if (result == true) setState(() {});
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Lab Result'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResultCard(MedicalRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    
    // Parse data from dataJson
    Map<String, dynamic> data = {};
    if (record.dataJson != null) {
      try {
        data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
      } catch (_) {}
    }
    
    final testName = data['test_name'] as String? ?? record.diagnosis ?? 'Lab Result';
    final testCategory = data['test_category'] as String? ?? 'General';
    final resultStatus = data['result_status'] as String? ?? 'Normal';
    final isAbnormal = resultStatus != 'Normal';
    
    Color statusColor;
    switch (resultStatus.toLowerCase()) {
      case 'critical':
        statusColor = AppColors.error;
      case 'abnormal':
      case 'high':
      case 'low':
        statusColor = AppColors.warning;
      default:
        statusColor = AppColors.success;
    }

    return GestureDetector(
      onTap: () async {
        final db = ref.read(doctorDbProvider).value;
        if (db != null) {
          final patient = await db.getPatientById(widget.patientId!);
          if (patient != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalRecordDetailScreen(
                  record: record,
                  patient: patient,
                ),
              ),
            ).then((_) => setState(() {}));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isAbnormal 
              ? Border.all(color: statusColor.withValues(alpha: 0.5), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      color: _themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          testCategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resultStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(record.recordDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<LabOrderData>> _fetchLabOrders(String? statusFilter) async {
    if (widget.patientId == null) return [];
    
    if (statusFilter != null) {
      return _labOrderService.getLabOrdersByStatus(widget.patientId!, statusFilter);
    }
    return _labOrderService.getLabOrdersForPatient(widget.patientId!);
  }

  bool _matchesSearch(LabOrderData order) {
    if (_searchController.text.isEmpty) return true;
    final query = _searchController.text.toLowerCase();
    // Check cached display name if available
    final cachedName = _displayNameCache[order.id]?.toLowerCase() ?? '';
    final cachedCode = _displayCodeCache[order.id]?.toLowerCase() ?? '';
    return cachedName.contains(query) ||
        cachedCode.contains(query) ||
        order.orderNumber.toLowerCase().contains(query) ||
        (order.labName?.toLowerCase().contains(query) ?? false);
  }

  Widget _buildLabOrderCard(LabOrderData order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _labOrderService.toModel(order);
    final statusColor = _getStatusColor(order.status);
    final urgencyColor = _getUrgencyColor(order.urgency);
    final hasAbnormalResults = order.isAbnormal ?? false;

    // Use FutureBuilder to get display names from LabTestResults table (V5)
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getDisplayName(order), _getDisplayCode(order)]),
      builder: (context, snapshot) {
        final displayName = snapshot.data?[0] as String? ?? 'Loading...';
        final displayCode = snapshot.data?[1] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: hasAbnormalResults 
                ? Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showOrderDetails(order),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildLabOrderCardContent(
                  order: order,
                  model: model,
                  displayName: displayName,
                  displayCode: displayCode,
                  statusColor: statusColor,
                  urgencyColor: urgencyColor,
                  hasAbnormalResults: hasAbnormalResults,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabOrderCardContent({
    required LabOrderData order,
    required LabOrderModel model,
    required String displayName,
    required String? displayCode,
    required Color statusColor,
    required Color urgencyColor,
    required bool hasAbnormalResults,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.2),
                    statusColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getTestIcon(displayName),
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (hasAbnormalResults)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_rounded, size: 12, color: AppColors.error),
                              const SizedBox(width: 4),
                              Text(
                                'ABNORMAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (displayCode != null && displayCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Code: $displayCode',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusChip(order.status, statusColor),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Flexible(
              flex: 0,
              child: _buildInfoChip(
                Icons.priority_high_rounded,
                model.urgency.displayName,
                urgencyColor,
              ),
            ),
            const SizedBox(width: 8),
            if (order.labName != null && order.labName!.isNotEmpty)
              Flexible(
                child: _buildInfoChip(
                  Icons.business_rounded,
                  order.labName!,
                  Colors.grey,
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (order.status == 'completed' && order.resultSummary != null && order.resultSummary!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (hasAbnormalResults ? AppColors.error : AppColors.success).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (hasAbnormalResults ? AppColors.error : AppColors.success).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasAbnormalResults ? Icons.warning_rounded : Icons.check_circle_rounded,
                  size: 18,
                  color: hasAbnormalResults ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.resultSummary!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ordered':
        return Colors.blue;
      case 'collected':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'stat':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'routine':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTestIcon(String testName) {
    final lower = testName.toLowerCase();
    if (lower.contains('blood') || lower.contains('cbc') || lower.contains('hemoglobin')) {
      return Icons.bloodtype;
    }
    if (lower.contains('urine') || lower.contains('urinal')) return Icons.water_drop;
    if (lower.contains('glucose') || lower.contains('sugar') || lower.contains('hba1c')) {
      return Icons.monitor_heart;
    }
    if (lower.contains('cholesterol') || lower.contains('lipid')) return Icons.favorite;
    if (lower.contains('thyroid') || lower.contains('tsh')) return Icons.biotech;
    if (lower.contains('liver') || lower.contains('hepat') || lower.contains('ast') || lower.contains('alt')) {
      return Icons.medical_services;
    }
    if (lower.contains('kidney') || lower.contains('creatinine') || lower.contains('bun')) {
      return Icons.water_drop;
    }
    if (lower.contains('culture') || lower.contains('bacteria')) return Icons.coronavirus;
    if (lower.contains('xray') || lower.contains('ct') || lower.contains('mri')) return Icons.medical_information;
    return Icons.science;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String? statusFilter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message = 'No lab orders';
    String subtitle = 'Create a new lab order to get started';
    if (statusFilter != null) {
      message = 'No ${statusFilter.replaceAll('_', ' ')} orders';
      subtitle = 'Orders with this status will appear here';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.science_rounded,
                size: 64,
                color: _themeColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (widget.patientId != null && statusFilter == null) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateOrderDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'Create Lab Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPatientState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: Colors.orange.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Patient',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open this screen from a patient\'s profile\nto view and create lab orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(LabOrderData order) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _labOrderService.toModel(order);
    final statusColor = _getStatusColor(order.status);
    
    // V5: Get display name and code from LabTestResults table
    final displayName = await _getDisplayName(order);
    final displayCode = await _getDisplayCode(order);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.2),
                              statusColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getTestIcon(displayName),
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            if (displayCode != null && displayCode.isNotEmpty)
                              Text(
                                'Code: $displayCode',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusChip(order.status, statusColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Details Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Order Date', _formatDate(order.orderDate), Icons.calendar_today_rounded),
                        _buildDetailRow('Urgency', model.urgency.displayName, Icons.priority_high_rounded),
                        if (order.labName != null && order.labName!.isNotEmpty)
                          _buildDetailRow('Laboratory', order.labName!, Icons.business_rounded),
                        if (order.specimenType != null && order.specimenType!.isNotEmpty)
                          _buildDetailRow('Specimen Type', order.specimenType!, Icons.water_drop_rounded),
                        if (order.collectionDate != null)
                          _buildDetailRow('Collection Date', _formatDate(order.collectionDate!), Icons.access_time_rounded),
                        if (order.resultDate != null)
                          _buildDetailRow('Result Date', _formatDate(order.resultDate!), Icons.check_circle_rounded),
                        if (order.clinicalIndication != null && order.clinicalIndication!.isNotEmpty)
                          _buildDetailRow('Clinical Indication', order.clinicalIndication!, Icons.medical_information_rounded, isLast: true),
                      ],
                    ),
                  ),
                  
                  // Results Section
                  if (order.resultSummary != null && order.resultSummary!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          (order.isAbnormal ?? false) ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: (order.isAbnormal ?? false) ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Results',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: (order.isAbnormal ?? false) ? AppColors.error : AppColors.success,
                          ),
                        ),
                        if (order.isAbnormal ?? false) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ABNORMAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ((order.isAbnormal ?? false) ? AppColors.error : AppColors.success).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: ((order.isAbnormal ?? false) ? AppColors.error : AppColors.success).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        order.resultSummary!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  
                  // Notes
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.note_rounded,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        order.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  
                  // Action Buttons
                  const SizedBox(height: 24),
                  if (order.status == 'ordered' || order.status == 'collected')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelOrder(order.id),
                            icon: const Icon(Icons.cancel_rounded),
                            label: const Text('Cancel Order'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _updateOrderStatus(order),
                              icon: const Icon(Icons.update_rounded, color: Colors.white),
                              label: Text(
                                order.status == 'ordered' ? 'Mark Collected' : 'Mark In Progress',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (order.status == 'in_progress')
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEnterResultsDialog(order);
                        },
                        icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
                        label: const Text(
                          'Enter Results',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isLast = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: _themeColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
            height: 1,
          ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(int id) async {
    await _labOrderService.cancelLabOrder(id, 'Cancelled by user');
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    }
  }

  Future<void> _updateOrderStatus(LabOrderData order) async {
    final newStatus = order.status == 'ordered' ? 'collected' : 'in_progress';
    await _labOrderService.updateLabOrderStatus(id: order.id, status: newStatus);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as ${newStatus.replaceAll('_', ' ')}')),
      );
    }
  }

  void _showEnterResultsDialog(LabOrderData order) {
    final resultController = TextEditingController();
    bool isAbnormal = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _themeColor.withValues(alpha: 0.2),
                                _themeColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.add_chart_rounded,
                            color: _themeColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                order.testName,
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
                    const SizedBox(height: 24),
                    
                    // Result Input
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: resultController,
                        maxLines: 5,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Result Summary *',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          hintText: 'Enter the lab results...',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Abnormal Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isAbnormal 
                            ? AppColors.error.withValues(alpha: 0.1)
                            : (isDark 
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAbnormal 
                              ? AppColors.error.withValues(alpha: 0.3)
                              : (isDark 
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Abnormal Results',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAbnormal 
                                ? AppColors.error
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                        subtitle: Text(
                          'Mark if results are outside normal range',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                        value: isAbnormal,
                        onChanged: (value) {
                          setModalState(() => isAbnormal = value);
                        },
                        activeColor: AppColors.error,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (resultController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Please enter results'),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          await _labOrderService.enterLabResults(
                            orderId: order.id,
                            resultSummary: resultController.text,
                            isAbnormal: isAbnormal,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Results saved successfully'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateOrderDialog(BuildContext context) {
    final testNameController = TextEditingController();
    final testCodeController = TextEditingController();
    final labController = TextEditingController();
    final indicationController = TextEditingController();
    final notesController = TextEditingController();
    String selectedUrgency = 'routine';
    String selectedSpecimen = 'blood';
    String selectedCategory = 'Quick Panels';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Categories for navigation
    final categories = ['Quick Panels', ...LabTestTemplates.allCategories.keys];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _themeColor.withValues(alpha: 0.2),
                                  _themeColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.science_rounded,
                              color: _themeColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Lab Order',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Select a test or enter details',
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
                      const SizedBox(height: 24),
                      
                      // Quick Fill Templates Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                              _themeColor.withValues(alpha: isDark ? 0.1 : 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _themeColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.flash_on_rounded,
                                  size: 18,
                                  color: _themeColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Fill Templates',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            
                            // Category selector
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories.map((category) {
                                  final isSelected = selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setModalState(() => selectedCategory = category);
                                      },
                                      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
                                      selectedColor: _themeColor,
                                      checkmarkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(
                                        color: isSelected 
                                            ? _themeColor
                                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            
                            // Templates based on selected category
                            if (selectedCategory == 'Quick Panels')
                              _buildQuickPanelsSection(
                                setModalState,
                                testNameController,
                                testCodeController,
                                indicationController,
                                isDark,
                              )
                            else
                              _buildCategoryTestsSection(
                                selectedCategory,
                                setModalState,
                                testNameController,
                                testCodeController,
                                (specimen) => setModalState(() => selectedSpecimen = specimen),
                                indicationController,
                                isDark,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Fields
                      _buildFormField(
                        controller: testNameController,
                        label: 'Test Name *',
                        hint: 'Enter test name',
                        icon: Icons.biotech_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // Test Code and Specimen Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: testCodeController,
                              label: 'Test Code',
                              hint: 'Optional',
                              icon: Icons.qr_code_rounded,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              value: selectedSpecimen,
                              label: 'Specimen',
                              icon: Icons.water_drop_rounded,
                              items: ['blood', 'urine', 'stool', 'swab', 'tissue', 'other'],
                              onChanged: (value) => setModalState(() => selectedSpecimen = value!),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Urgency and Lab Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              value: selectedUrgency,
                              label: 'Urgency',
                              icon: Icons.priority_high_rounded,
                              items: ['routine', 'urgent', 'stat'],
                              onChanged: (value) => setModalState(() => selectedUrgency = value!),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              controller: labController,
                              label: 'Laboratory',
                              hint: 'Optional',
                              icon: Icons.business_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Clinical Indication
                      _buildFormField(
                        controller: indicationController,
                        label: 'Clinical Indication',
                        hint: 'Reason for ordering',
                        icon: Icons.medical_information_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      
                      // Notes
                      _buildFormField(
                        controller: notesController,
                        label: 'Notes',
                        hint: 'Additional instructions',
                        icon: Icons.note_rounded,
                        isDark: isDark,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      
                      // Create Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _themeColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (testNameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Please enter test name'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Please select a patient first'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            await _labOrderService.createOrder(
                              patientId: widget.patientId!,
                              testName: testNameController.text,
                              testCode: testCodeController.text.isNotEmpty ? testCodeController.text : null,
                              urgency: selectedUrgency,
                              specimenType: selectedSpecimen,
                              labName: labController.text.isNotEmpty ? labController.text : null,
                              clinicalIndication: indicationController.text.isNotEmpty ? indicationController.text : null,
                              notes: notesController.text.isNotEmpty ? notesController.text : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Lab order created successfully'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text(
                            'Create Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          prefixIcon: Icon(icon, color: _themeColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: _themeColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items.map((s) => 
          DropdownMenuItem(
            value: s, 
            child: Text(
              s[0].toUpperCase() + s.substring(1),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildQuickPanelsSection(
    StateSetter setModalState,
    TextEditingController testNameController,
    TextEditingController testCodeController,
    TextEditingController indicationController,
    bool isDark,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LabTestTemplates.quickPanels.map((panel) {
        return ActionChip(
          avatar: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPanelIcon(panel.name),
              size: 14,
              color: _themeColor,
            ),
          ),
          label: Text(
            panel.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () {
            // Show panel details dialog
            _showPanelDetailsDialog(panel);
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoryTestsSection(
    String category,
    StateSetter setModalState,
    TextEditingController testNameController,
    TextEditingController testCodeController,
    Function(String) updateSpecimen,
    TextEditingController indicationController,
    bool isDark,
  ) {
    final tests = LabTestTemplates.allCategories[category] ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tests.map((test) {
        return ActionChip(
          label: Text(
            test.name.length > 25 ? '${test.name.substring(0, 22)}...' : test.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () {
            setModalState(() {
              testNameController.text = test.name;
              testCodeController.text = test.testCode ?? '';
              updateSpecimen(test.specimenType);
              indicationController.text = test.clinicalIndication ?? '';
            });
          },
        );
      }).toList(),
    );
  }

  void _showPanelDetailsDialog(LabTestPanel panel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _themeColor.withValues(alpha: 0.2),
                          _themeColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPanelIcon(panel.name),
                      color: _themeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      panel.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark 
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  panel.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Tests Header
              Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 18, color: _themeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Tests in this panel (${panel.tests.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tests List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: panel.tests.map((test) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded, 
                              size: 16, 
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                test.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close bottom sheet
                          
                          // Create orders for all tests in the panel
                          if (widget.patientId != null) {
                            for (final test in panel.tests) {
                              await _labOrderService.createOrder(
                                patientId: widget.patientId!,
                                testName: test.name,
                                testCode: test.testCode,
                                urgency: test.urgency,
                                specimenType: test.specimenType,
                                clinicalIndication: panel.clinicalIndication ?? test.clinicalIndication,
                              );
                            }
                            
                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text('${panel.tests.length} lab orders created'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'Order All (${panel.tests.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  IconData _getPanelIcon(String panelName) {
    final lower = panelName.toLowerCase();
    if (lower.contains('diabetic')) return Icons.monitor_heart;
    if (lower.contains('cardiac')) return Icons.favorite;
    if (lower.contains('thyroid')) return Icons.biotech;
    if (lower.contains('anemia')) return Icons.bloodtype;
    if (lower.contains('liver')) return Icons.medical_services;
    if (lower.contains('operative') || lower.contains('surgery')) return Icons.local_hospital;
    if (lower.contains('pregnancy')) return Icons.pregnant_woman;
    if (lower.contains('fever')) return Icons.thermostat;
    if (lower.contains('arthritis')) return Icons.accessibility_new;
    if (lower.contains('routine') || lower.contains('checkup')) return Icons.health_and_safety;
    return Icons.science;
  }
}