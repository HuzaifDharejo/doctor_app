import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
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
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                            Icons.swap_horiz_rounded,
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
                                'Specialist Referrals',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Refer patients to external specialists',
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
                Tab(text: 'Scheduled'),
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
                  hintText: 'Search referrals...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReferralDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Referral'),
        backgroundColor: const Color(0xFF8B5CF6),
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
            'Create a new referral to get started',
            style: TextStyle(
              fontSize: 14,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSpecialtyIcon(referral.specialty),
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
                          referral.specialty,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (referral.referredToName != null)
                          Text(
                            'To: ${referral.referredToName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(referral.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                referral.reasonForReferral,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.priority_high,
                    _formatUrgency(referral.urgency),
                    urgencyColor,
                  ),
                  const SizedBox(width: 8),
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
                      fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
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
                          color: _getStatusColor(referral.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getSpecialtyIcon(referral.specialty),
                          color: _getStatusColor(referral.status),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              referral.specialty,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Referral #${referral.id}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(referral.status, _getStatusColor(referral.status)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection('Referred To', referral.referredToName.isEmpty ? 'Not specified' : referral.referredToName),
                  _buildDetailSection('Reason', referral.reasonForReferral),
                  _buildDetailSection('Urgency', _formatUrgency(referral.urgency)),
                  _buildDetailSection('Referral Date', _formatDate(referral.referralDate)),
                  if (referral.appointmentDate != null)
                    _buildDetailSection('Appointment Date', _formatDate(referral.appointmentDate!)),
                  if (referral.clinicalHistory.isNotEmpty)
                    _buildDetailSection('Clinical History', referral.clinicalHistory),
                  const SizedBox(height: 24),
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
                      const SizedBox(width: 12),
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
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Referral',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: specialtyController,
                        decoration: const InputDecoration(
                          labelText: 'Specialty *',
                          hintText: 'e.g., Cardiology, Neurology',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: referredToController,
                        decoration: const InputDecoration(
                          labelText: 'Referred To (Doctor/Facility)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Referral *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Urgency'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Clinical Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
