import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../models/lab_order.dart';
import '../../providers/db_provider.dart';
import '../../services/lab_order_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                            Icons.science,
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
                                'Lab Orders',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
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
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'In Progress'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search lab orders...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLabOrdersList(null),
                  _buildLabOrdersList('ordered'),
                  _buildLabOrdersList('in_progress'),
                  _buildLabOrdersList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.patientId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrderDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
              backgroundColor: const Color(0xFFEC4899),
            )
          : null,
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
          return const Center(child: CircularProgressIndicator());
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
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildLabOrderCard(orders[index]);
            },
          ),
        );
      },
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
    return order.testName.toLowerCase().contains(query) ||
        (order.testCode?.toLowerCase().contains(query) ?? false) ||
        (order.labName?.toLowerCase().contains(query) ?? false);
  }

  Widget _buildLabOrderCard(LabOrderData order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _labOrderService.toModel(order);
    final statusColor = _getStatusColor(order.status);
    final urgencyColor = _getUrgencyColor(order.urgency);
    final hasAbnormalResults = order.isAbnormal ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: hasAbnormalResults 
            ? BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTestIcon(order.testName),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.testName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (hasAbnormalResults)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning, size: 12, color: Colors.red[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      'ABNORMAL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (order.testCode != null)
                          Text(
                            'Code: ${order.testCode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.priority_high,
                    model.urgency.displayName,
                    urgencyColor,
                  ),
                  const SizedBox(width: 8),
                  if (order.labName != null)
                    _buildInfoChip(
                      Icons.business,
                      order.labName!,
                      Colors.grey,
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(order.orderDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (order.status == 'completed' && order.resultSummary != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (hasAbnormalResults ? Colors.red : Colors.green).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (hasAbnormalResults ? Colors.red : Colors.green).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: hasAbnormalResults ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
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
    if (statusFilter != null) {
      message = 'No ${statusFilter.replaceAll('_', ' ')} orders';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new lab order to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPatientState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a patient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(LabOrderData order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _labOrderService.toModel(order);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ListView(
                controller: scrollController,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTestIcon(order.testName),
                          color: _getStatusColor(order.status),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.testName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (order.testCode != null)
                              Text(
                                'Code: ${order.testCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusChip(order.status, _getStatusColor(order.status)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection('Order Date', _formatDate(order.orderDate)),
                  _buildDetailSection('Urgency', model.urgency.displayName),
                  if (order.labName != null)
                    _buildDetailSection('Laboratory', order.labName!),
                  if (order.specimenType != null)
                    _buildDetailSection('Specimen Type', order.specimenType!),
                  if (order.collectionDate != null)
                    _buildDetailSection('Collection Date', _formatDate(order.collectionDate!)),
                  if (order.resultDate != null)
                    _buildDetailSection('Result Date', _formatDate(order.resultDate!)),
                  if (order.clinicalIndication != null)
                    _buildDetailSection('Clinical Indication', order.clinicalIndication!),
                  if (order.resultSummary != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: (order.isAbnormal ?? false) ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (order.isAbnormal ?? false) ? Colors.red : Colors.green,
                          ),
                        ),
                        if (order.isAbnormal ?? false) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ABNORMAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ((order.isAbnormal ?? false) ? Colors.red : Colors.green).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ((order.isAbnormal ?? false) ? Colors.red : Colors.green).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        order.resultSummary!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildDetailSection('Notes', order.notes!),
                  const SizedBox(height: 24),
                  if (order.status == 'ordered' || order.status == 'collected')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelOrder(order.id),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(order),
                            icon: const Icon(Icons.update),
                            label: Text(order.status == 'ordered' ? 'Mark Collected' : 'Mark In Progress'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC4899),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (order.status == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEnterResultsDialog(order);
                        },
                        icon: const Icon(Icons.add_chart),
                        label: const Text('Enter Results'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
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
                    Text(
                      'Enter Results: ${order.testName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: resultController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Result Summary *',
                        hintText: 'Enter the lab results...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Abnormal Results'),
                      subtitle: const Text('Mark if results are outside normal range'),
                      value: isAbnormal,
                      onChanged: (value) {
                        setModalState(() => isAbnormal = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (resultController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter results')),
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
                              const SnackBar(content: Text('Results saved successfully')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Results'),
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

    final commonTests = [
      'Complete Blood Count (CBC)',
      'Basic Metabolic Panel (BMP)',
      'Comprehensive Metabolic Panel (CMP)',
      'Lipid Panel',
      'Thyroid Panel (TSH, T3, T4)',
      'Hemoglobin A1C',
      'Liver Function Tests',
      'Urinalysis',
      'Fasting Blood Glucose',
      'PT/INR',
    ];

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
                        'New Lab Order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Common Tests',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: commonTests.map((test) {
                          return ActionChip(
                            label: Text(test, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              setModalState(() {
                                testNameController.text = test;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: testNameController,
                        decoration: const InputDecoration(
                          labelText: 'Test Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: testCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Test Code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSpecimen,
                              decoration: const InputDecoration(
                                labelText: 'Specimen',
                                border: OutlineInputBorder(),
                              ),
                              items: ['blood', 'urine', 'stool', 'swab', 'tissue', 'other'].map((s) => 
                                DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))
                              ).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedSpecimen = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedUrgency,
                              decoration: const InputDecoration(
                                labelText: 'Urgency',
                                border: OutlineInputBorder(),
                              ),
                              items: ['routine', 'urgent', 'stat'].map((s) => 
                                DropdownMenuItem(value: s, child: Text(s.toUpperCase()))
                              ).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedUrgency = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: labController,
                              decoration: const InputDecoration(
                                labelText: 'Laboratory',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: indicationController,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Indication',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (testNameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter test name')),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a patient first')),
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
                                const SnackBar(content: Text('Lab order created successfully')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC4899),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Create Order'),
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
