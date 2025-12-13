import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../providers/db_provider.dart';
import '../../services/insurance_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient insurance and billing
class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _insuranceService = InsuranceService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                      Icons.analytics,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onPressed: _showBillingStats,
                    tooltip: 'Billing statistics',
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
                              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
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
                                'Insurance & Billing',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Claims, pre-authorizations & coverage',
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
                Tab(text: 'Coverage'),
                Tab(text: 'Claims'),
                Tab(text: 'Pre-Auth'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCoverageTab(),
            _buildClaimsTab(),
            _buildPreAuthTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildCoverageTab() {
    return FutureBuilder<List<InsuranceInfoData>>(
      future: _insuranceService.getAllInsuranceInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('coverage');
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildInsuranceCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildClaimsTab() {
    return FutureBuilder<List<InsuranceClaimData>>(
      future: _insuranceService.getAllClaims(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('claims');
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildClaimCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPreAuthTab() {
    return FutureBuilder<List<PreAuthorizationData>>(
      future: _insuranceService.getAllPreAuthorizations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('preauth');
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildPreAuthCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildInsuranceCard(InsuranceInfoData insurance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _insuranceService.insuranceToModel(insurance);
    final isPrimary = insurance.isPrimary == true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showInsuranceDetails(insurance),
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insurance.insurerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          insurance.planName ?? 'Standard Plan',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRIMARY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.badge, 'ID: ${insurance.policyNumber}', Colors.blue),
                  const SizedBox(width: 8),
                  if (insurance.groupNumber != null)
                    _buildInfoChip(Icons.group, 'Group: ${insurance.groupNumber}', Colors.purple),
                ],
              ),
              if (insurance.effectiveDate != null || insurance.terminationDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (insurance.effectiveDate != null)
                      _buildInfoChip(
                        Icons.play_arrow,
                        'From: ${_formatDate(insurance.effectiveDate!)}',
                        Colors.green,
                      ),
                    if (insurance.terminationDate != null) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.stop,
                        'To: ${_formatDate(insurance.terminationDate!)}',
                        Colors.orange,
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verifyEligibility(insurance),
                      icon: const Icon(Icons.verified, size: 16),
                      label: const Text('Verify'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showNewClaimDialog(insurance),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('New Claim'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildClaimCard(InsuranceClaimData claim) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _insuranceService.claimToModel(claim);
    final statusColor = _getClaimStatusColor(claim.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showClaimDetails(claim),
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
                      Icons.receipt_long,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.claimNumber ?? 'Claim #${claim.id}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Patient #${claim.patientId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(claim.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Filed: ${_formatDate(claim.serviceDate ?? DateTime.now())}',
                    Colors.grey,
                  ),
                  const Spacer(),
                  Text(
                    '\$${claim.billedAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (claim.paidAmount != null && claim.paidAmount! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Paid: \$${claim.paidAmount?.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (claim.patientResponsibility != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Patient: \$${claim.patientResponsibility?.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (claim.denialReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          claim.denialReason!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
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
      ),
    );
  }

  Widget _buildPreAuthCard(PreAuthorizationData preAuth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _insuranceService.preAuthToModel(preAuth);
    final statusColor = _getPreAuthStatusColor(preAuth.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showPreAuthDetails(preAuth),
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
                      Icons.assignment_turned_in,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preAuth.procedureCode ?? 'Pre-Authorization',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (preAuth.procedureDescription != null)
                          Text(
                            preAuth.procedureDescription!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(preAuth.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.send,
                    'Requested: ${_formatDate(preAuth.requestDate)}',
                    Colors.blue,
                  ),
                  if (preAuth.expirationDate != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.timer,
                      'Expires: ${_formatDate(preAuth.expirationDate!)}',
                      preAuth.expirationDate!.isBefore(DateTime.now()) ? Colors.red : Colors.orange,
                    ),
                  ],
                ],
              ),
              if (preAuth.authorizationNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Auth #: ${preAuth.authorizationNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
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

  Color _getClaimStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'paid':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'appealed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getPreAuthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildEmptyState(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message;
    IconData icon;

    switch (type) {
      case 'coverage':
        message = 'No insurance information';
        icon = Icons.account_balance_wallet;
        break;
      case 'claims':
        message = 'No claims found';
        icon = Icons.receipt_long;
        break;
      case 'preauth':
        message = 'No pre-authorizations';
        icon = Icons.assignment_turned_in;
        break;
      default:
        message = 'No data';
        icon = Icons.info;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_hospital, color: Colors.blue),
                title: const Text('Add Insurance'),
                subtitle: const Text('Add patient insurance coverage'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddInsuranceDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green),
                title: const Text('New Claim'),
                subtitle: const Text('Submit a new insurance claim'),
                onTap: () {
                  Navigator.pop(context);
                  _showNewClaimDialog(null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_turned_in, color: Colors.orange),
                title: const Text('Pre-Authorization'),
                subtitle: const Text('Request pre-authorization'),
                onTap: () {
                  Navigator.pop(context);
                  _showPreAuthDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInsuranceDetails(InsuranceInfoData insurance) {
    // Show details modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Insurance: ${insurance.insurerName}')),
    );
  }

  void _showClaimDetails(InsuranceClaimData claim) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Claim: ${claim.claimNumber ?? claim.id}')),
    );
  }

  void _showPreAuthDetails(PreAuthorizationData preAuth) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pre-Auth: ${preAuth.procedureCode}')),
    );
  }

  void _verifyEligibility(InsuranceInfoData insurance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Verifying eligibility...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eligibility verified - Active coverage'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showBillingStats() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Billing Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Total Billed (MTD)', '\$12,450.00', Colors.blue),
              _buildStatRow('Paid', '\$9,800.00', Colors.green),
              _buildStatRow('Pending', '\$1,850.00', Colors.orange),
              _buildStatRow('Denied', '\$800.00', Colors.red),
              const Divider(height: 32),
              _buildStatRow('Collection Rate', '78.7%', Colors.green),
              _buildStatRow('Average Days to Pay', '18 days', Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddInsuranceDialog() {
    final insurerController = TextEditingController();
    final policyController = TextEditingController();
    final groupController = TextEditingController();
    bool isPrimary = true;
    int? selectedPatientId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add Insurance',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Patient selector
                      FutureBuilder<List<Patient>>(
                        future: ref.read(doctorDbProvider).value?.getAllPatients() ?? Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final patientList = snapshot.data ?? [];
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Select Patient *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            value: selectedPatientId,
                            items: patientList.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.firstName} ${p.lastName}'),
                            )).toList(),
                            onChanged: (value) {
                              setModalState(() => selectedPatientId = value);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    TextField(
                      controller: insurerController,
                      decoration: const InputDecoration(
                        labelText: 'Insurance Company',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: policyController,
                      decoration: const InputDecoration(
                        labelText: 'Policy Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: groupController,
                      decoration: const InputDecoration(
                        labelText: 'Group Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Primary Insurance'),
                      value: isPrimary,
                      onChanged: (value) => setModalState(() => isPrimary = value),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedPatientId == null ? null : () async {
                          await _insuranceService.addInsuranceInfo(
                            patientId: selectedPatientId!,
                            insurerName: insurerController.text,
                            policyNumber: policyController.text,
                            groupNumber: groupController.text.isNotEmpty ? groupController.text : null,
                            isPrimary: isPrimary,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Insurance added')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Add Insurance'),
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

  void _showNewClaimDialog(InsuranceInfoData? insurance) {
    final amountController = TextEditingController();
    final cptController = TextEditingController();
    final diagnosisController = TextEditingController();
    int? selectedPatientId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Claim',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Patient selector
                      FutureBuilder<List<Patient>>(
                        future: ref.read(doctorDbProvider).value?.getAllPatients() ?? Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final patientList = snapshot.data ?? [];
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Select Patient *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            value: selectedPatientId,
                            items: patientList.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.firstName} ${p.lastName}'),
                            )).toList(),
                            onChanged: (value) {
                              setModalState(() => selectedPatientId = value);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: cptController,
                        decoration: const InputDecoration(
                          labelText: 'CPT Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: diagnosisController,
                        decoration: const InputDecoration(
                          labelText: 'Diagnosis Code (ICD-10)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Billed Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedPatientId == null ? null : () async {
                            await _insuranceService.submitClaim(
                              patientId: selectedPatientId!,
                              insuranceId: insurance?.id ?? 1,
                              serviceDate: DateTime.now(),
                              billedAmount: double.tryParse(amountController.text),
                              diagnosisCodes: diagnosisController.text.isNotEmpty ? diagnosisController.text : null,
                              procedureCodes: cptController.text.isNotEmpty ? cptController.text : null,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Claim submitted')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Claim'),
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

  void _showPreAuthDialog() {
    final procedureController = TextEditingController();
    final descriptionController = TextEditingController();
    final reasonController = TextEditingController();
    int? selectedPatientId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pre-Authorization Request',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Patient selector
                      FutureBuilder<List<Patient>>(
                        future: ref.read(doctorDbProvider).value?.getAllPatients() ?? Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final patientList = snapshot.data ?? [];
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Select Patient *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            value: selectedPatientId,
                            items: patientList.map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.firstName} ${p.lastName}'),
                            )).toList(),
                            onChanged: (value) {
                              setModalState(() => selectedPatientId = value);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: procedureController,
                        decoration: const InputDecoration(
                          labelText: 'Procedure Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Procedure Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medical Necessity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedPatientId == null ? null : () async {
                            await _insuranceService.requestPreAuthorization(
                              patientId: selectedPatientId!,
                              insuranceId: 1,
                              procedureCode: procedureController.text.isNotEmpty ? procedureController.text : null,
                              procedureDescription: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                              clinicalReason: reasonController.text.isNotEmpty ? reasonController.text : null,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pre-authorization requested')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Request'),
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
