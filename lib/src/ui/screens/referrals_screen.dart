import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/referral_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient referrals to external specialists
/// 
/// This screen allows the doctor to:
/// - Create referrals to outside specialists
/// - Track referral status and outcomes
/// - Manage patient care coordination with external providers
class ReferralsScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const ReferralsScreen({super.key, this.patientId});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _referralService = ReferralService();
  String _statusFilter = 'all';
  String _searchQuery = '';

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
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onPressed: _showFilterDialog,
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxxl, AppSpacing.xl, AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: AppIconSize.lg,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Specialist Referrals',
                                style: TextStyle(
                                  fontSize: AppFontSize.xxxl,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Refer patients to external specialists',
                                style: TextStyle(
                                  fontSize: AppFontSize.lg,
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
          ),
        ],
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
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
                    hintText: 'Search referrals...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
            // Tab Bar
            _buildTabBar(isDark),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReferralsList(null),
                  _buildReferralsList('pending'),
                  _buildReferralsList('scheduled'),
                  _buildReferralsList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
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
          onPressed: () => _showAddReferralDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Referral',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicator: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: -AppSpacing.sm),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(AppRadius.md),
        tabs: [
          _buildReferralTab('All', Icons.list_alt_rounded),
          _buildReferralTab('Pending', Icons.pending_actions_rounded),
          _buildReferralTab('Scheduled', Icons.event_rounded),
          _buildReferralTab('Completed', Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildReferralTab(String label, IconData icon) {
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

  Widget _buildReferralsList(String? statusFilter) {
    return FutureBuilder<List<ReferralData>>(
      future: _fetchReferrals(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        final referrals = snapshot.data!
            .where((r) => _matchesSearch(r))
            .toList();

        if (referrals.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              return _buildReferralCard(referrals[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ReferralData>> _fetchReferrals(String? statusFilter) async {
    if (widget.patientId != null) {
      if (statusFilter != null) {
        final all = await _referralService.getReferralsForPatient(widget.patientId!);
        return all.where((r) => r.status == statusFilter).toList();
      }
      return _referralService.getReferralsForPatient(widget.patientId!);
    }
    
    if (statusFilter != null) {
      return _referralService.getAllReferralsByStatus(statusFilter);
    }
    
    // Return all referrals - this would need a method in the service
    return _referralService.getAllReferralsByStatus('pending');
  }

  bool _matchesSearch(ReferralData referral) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return referral.specialty.toLowerCase().contains(query) ||
        referral.referredToName.toLowerCase().contains(query) ||
        referral.reasonForReferral.toLowerCase().contains(query);
  }

  Widget _buildEmptyState(String? statusFilter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message = 'No referrals found';
    if (statusFilter != null) {
      message = 'No $statusFilter referrals';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            size: AppIconSize.xxl,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create a new referral to get started',
            style: TextStyle(
              fontSize: AppFontSize.lg,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(ReferralData referral) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(referral.status);
    final urgencyColor = _getUrgencyColor(referral.urgency);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showReferralDetails(referral),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _getSpecialtyIcon(referral.specialty),
                      color: statusColor,
                      size: AppIconSize.md,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referral.specialty,
                          style: TextStyle(
                            fontSize: AppFontSize.xl,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (referral.referredToName != null)
                          Text(
                            'To: ${referral.referredToName}',
                            style: TextStyle(
                              fontSize: AppFontSize.lg,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(referral.status, statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                referral.reasonForReferral,
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.priority_high,
                    _formatUrgency(referral.urgency),
                    urgencyColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (referral.appointmentDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      _formatDate(referral.appointmentDate!),
                      Colors.blue,
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(referral.referralDate),
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: AppFontSize.xs,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.xs, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.sm,
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
      case 'pending':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      case 'scheduled':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
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

  IconData _getSpecialtyIcon(String specialty) {
    final lower = specialty.toLowerCase();
    if (lower.contains('cardio')) return Icons.favorite;
    if (lower.contains('neuro')) return Icons.psychology;
    if (lower.contains('ortho')) return Icons.accessibility;
    if (lower.contains('dermato')) return Icons.face;
    if (lower.contains('gastro')) return Icons.restaurant;
    if (lower.contains('pulmo')) return Icons.air;
    if (lower.contains('endo')) return Icons.biotech;
    if (lower.contains('onco')) return Icons.medical_services;
    if (lower.contains('psych')) return Icons.psychology_alt;
    if (lower.contains('ophthal')) return Icons.visibility;
    if (lower.contains('ent') || lower.contains('otolar')) return Icons.hearing;
    return Icons.local_hospital;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatUrgency(String? urgency) {
    if (urgency == null || urgency.isEmpty) return 'Routine';
    return urgency[0].toUpperCase() + urgency.substring(1).toLowerCase();
  }

  void _showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Referrals',
                style: TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == 'all',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'all');
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _statusFilter == 'pending',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'pending');
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    label: const Text('Urgent'),
                    selected: _statusFilter == 'urgent',
                    onSelected: (selected) {
                      setState(() => _statusFilter = 'urgent');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReferralDetails(ReferralData referral) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
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
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _getStatusColor(referral.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          _getSpecialtyIcon(referral.specialty),
                          color: _getStatusColor(referral.status),
                          size: AppIconSize.lg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              referral.specialty,
                              style: const TextStyle(
                                fontSize: AppFontSize.xxxl,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Referral #${referral.id}',
                              style: TextStyle(
                                fontSize: AppFontSize.lg,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(referral.status, _getStatusColor(referral.status)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildDetailSection('Referred To', referral.referredToName.isEmpty ? 'Not specified' : referral.referredToName),
                  _buildDetailSection('Reason', referral.reasonForReferral),
                  _buildDetailSection('Urgency', _formatUrgency(referral.urgency)),
                  _buildDetailSection('Referral Date', _formatDate(referral.referralDate)),
                  if (referral.appointmentDate != null)
                    _buildDetailSection('Appointment Date', _formatDate(referral.appointmentDate!)),
                  if (referral.clinicalHistory.isNotEmpty)
                    _buildDetailSection('Clinical History', referral.clinicalHistory),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateReferralStatus(referral.id, 'cancelled'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateReferralStatus(referral.id, 'completed'),
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.xl,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReferralStatus(int id, String status) async {
    await _referralService.updateStatus(id, status);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral $status')),
      );
    }
  }

  void _showAddReferralDialog(BuildContext context) {
    final specialtyController = TextEditingController();
    final reasonController = TextEditingController();
    final referredToController = TextEditingController();
    final notesController = TextEditingController();
    String selectedUrgency = 'routine';

    showModalBottomSheet<void>(
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
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'New Referral',
                        style: TextStyle(
                          fontSize: AppFontSize.xxxl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: specialtyController,
                        decoration: const InputDecoration(
                          labelText: 'Specialty *',
                          hintText: 'e.g., Cardiology, Neurology',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: referredToController,
                        decoration: const InputDecoration(
                          labelText: 'Referred To (Doctor/Facility)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Referral *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Urgency'),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: ['routine', 'urgent', 'stat'].map((urgency) {
                          return ChoiceChip(
                            label: Text(urgency.toUpperCase()),
                            selected: selectedUrgency == urgency,
                            selectedColor: _getUrgencyColor(urgency).withValues(alpha: 0.2),
                            onSelected: (selected) {
                              setModalState(() => selectedUrgency = urgency);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (specialtyController.text.isEmpty ||
                                reasonController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill required fields'),
                                ),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a patient first'),
                                ),
                              );
                              return;
                            }

                            await _referralService.createReferral(
                              patientId: widget.patientId!,
                              specialty: specialtyController.text,
                              reasonForReferral: reasonController.text,
                              referralDate: DateTime.now(),
                              urgency: selectedUrgency,
                              referredToName: referredToController.text.isNotEmpty
                                  ? referredToController.text
                                  : null,
                              clinicalHistory: notesController.text.isNotEmpty
                                  ? notesController.text
                                  : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Referral created successfully'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                          child: const Text('Create Referral'),
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
