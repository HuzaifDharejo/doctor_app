import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../services/problem_list_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient problem list (diagnoses)
class ProblemListScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const ProblemListScreen({super.key, this.patientId});

  @override
  ConsumerState<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends ConsumerState<ProblemListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _problemListService = ProblemListService();
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
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                        ? [AppColors.darkBackground, AppColors.darkSurface]
                        : [AppColors.background, surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxxxl, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.list_alt,
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
                                'Problem List',
                                style: TextStyle(
                                  fontSize: AppFontSize.xxxl,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Active conditions & diagnoses',
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
                    hintText: 'Search problems or ICD-10 codes...',
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
                  onChanged: (value) => setState(() {}),
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
                  _buildProblemsList('active'),
                  _buildProblemsList('chronic'),
                  _buildProblemsList('resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.patientId != null
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddProblemDialog(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Problem',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
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
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: -AppSpacing.sm),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(AppRadius.md),
        tabs: [
          _buildProblemTab('Active', Icons.assignment_rounded),
          _buildProblemTab('Chronic', Icons.schedule_rounded),
          _buildProblemTab('Resolved', Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildProblemTab(String label, IconData icon) {
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

  Widget _buildProblemsList(String status) {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    return FutureBuilder<List<ProblemListData>>(
      future: _fetchProblems(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(status);
        }

        final problems = snapshot.data!
            .where((p) => _matchesSearch(p))
            .toList();

        if (problems.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: problems.length,
            itemBuilder: (context, index) {
              return _buildProblemCard(problems[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ProblemListData>> _fetchProblems(String status) async {
    if (widget.patientId == null) return [];
    
    switch (status) {
      case 'active':
        return _problemListService.getActiveProblems(widget.patientId!);
      case 'chronic':
        return _problemListService.getChronicProblems(widget.patientId!);
      case 'resolved':
        return _problemListService.getResolvedProblems(widget.patientId!);
      default:
        return _problemListService.getProblemListForPatient(widget.patientId!);
    }
  }

  bool _matchesSearch(ProblemListData problem) {
    if (_searchController.text.isEmpty) return true;
    final query = _searchController.text.toLowerCase();
    return problem.problemName.toLowerCase().contains(query) ||
        (problem.icdCode?.toLowerCase().contains(query) ?? false) ||
        (problem.notes?.toLowerCase().contains(query) ?? false);
  }

  Widget _buildProblemCard(ProblemListData problem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _problemListService.toModel(problem);
    final statusColor = _getStatusColor(problem.status);
    final severityColor = _getSeverityColor(problem.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showProblemDetails(problem),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _getProblemIcon(problem.problemName),
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
                          problem.problemName,
                          style: TextStyle(
                            fontSize: AppFontSize.xl,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (problem.icdCode != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'ICD-10: ${problem.icdCode}',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(problem.status, statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (problem.severity != null) ...[
                    _buildInfoChip(
                      Icons.speed,
                      model.severity.displayName,
                      severityColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (problem.onsetDate != null)
                    _buildInfoChip(
                      Icons.calendar_today,
                      'Since ${_formatDate(problem.onsetDate!)}',
                      Colors.grey,
                    ),
                  const Spacer(),
                  if (problem.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Priority ${problem.priority}',
                        style: const TextStyle(
                          fontSize: AppFontSize.xs,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (problem.notes != null && problem.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  problem.notes!,
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
              fontSize: AppFontSize.xs,
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
      case 'active':
        return Colors.orange;
      case 'chronic':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getProblemIcon(String problemName) {
    final lower = problemName.toLowerCase();
    if (lower.contains('diabetes')) return Icons.bloodtype;
    if (lower.contains('hypertension') || lower.contains('blood pressure')) return Icons.favorite;
    if (lower.contains('asthma') || lower.contains('respiratory')) return Icons.air;
    if (lower.contains('arthritis') || lower.contains('joint')) return Icons.accessibility;
    if (lower.contains('depression') || lower.contains('anxiety')) return Icons.psychology;
    if (lower.contains('cancer') || lower.contains('tumor')) return Icons.coronavirus;
    if (lower.contains('heart') || lower.contains('cardiac')) return Icons.favorite;
    if (lower.contains('kidney') || lower.contains('renal')) return Icons.water_drop;
    if (lower.contains('liver') || lower.contains('hepat')) return Icons.medical_services;
    return Icons.medical_information;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'resolved' ? Icons.check_circle : Icons.list_alt,
            size: AppIconSize.xxl,
            color: status == 'resolved' ? Colors.green[300] : (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            status == 'resolved' 
                ? 'No resolved problems'
                : 'No $status problems',
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add problems to track patient conditions',
            style: TextStyle(
              fontSize: AppFontSize.lg,
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
            size: AppIconSize.xxl,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Select a patient',
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showProblemDetails(ProblemListData problem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _problemListService.toModel(problem);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                          color: _getStatusColor(problem.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          _getProblemIcon(problem.problemName),
                          color: _getStatusColor(problem.status),
                          size: AppIconSize.lg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.problemName,
                              style: const TextStyle(
                                fontSize: AppFontSize.xxxl,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (problem.icdCode != null)
                              Text(
                                'ICD-10: ${problem.icdCode}',
                                style: const TextStyle(
                                  fontSize: AppFontSize.lg,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusChip(problem.status, _getStatusColor(problem.status)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildDetailSection('Status', model.status.displayName),
                  if (problem.severity != null)
                    _buildDetailSection('Severity', model.severity.displayName),
                  if (problem.onsetDate != null)
                    _buildDetailSection('Onset Date', _formatFullDate(problem.onsetDate!)),
                  if (problem.resolvedDate != null)
                    _buildDetailSection('Resolved Date', _formatFullDate(problem.resolvedDate!)),
                  if (problem.priority != null)
                    _buildDetailSection('Priority', 'Level ${problem.priority}'),
                  if (problem.notes != null && problem.notes!.isNotEmpty)
                    _buildDetailSection('Notes', problem.notes!),
                  const SizedBox(height: AppSpacing.xxl),
                  if (problem.status != 'resolved')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _resolveProblem(problem.id),
                            icon: const Icon(Icons.check),
                            label: const Text('Resolve'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditDialog(problem);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _reactivateProblem(problem.id),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reactivate'),
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

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _resolveProblem(int id) async {
    await _problemListService.resolveProblem(id);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem marked as resolved')),
      );
    }
  }

  Future<void> _reactivateProblem(int id) async {
    await _problemListService.reactivateProblem(id);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem reactivated')),
      );
    }
  }

  void _showEditDialog(ProblemListData problem) {
    _showAddProblemDialog(context, editProblem: problem);
  }

  void _showAddProblemDialog(BuildContext context, {ProblemListData? editProblem}) {
    final nameController = TextEditingController(text: editProblem?.problemName);
    final icdController = TextEditingController(text: editProblem?.icdCode);
    final notesController = TextEditingController(text: editProblem?.notes);
    String selectedStatus = editProblem?.status ?? 'active';
    String selectedSeverity = editProblem?.severity ?? 'moderate';
    DateTime? onsetDate = editProblem?.onsetDate;

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
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        editProblem != null ? 'Edit Problem' : 'Add Problem',
                        style: const TextStyle(
                          fontSize: AppFontSize.xxxl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Problem Name *',
                          hintText: 'e.g., Type 2 Diabetes Mellitus',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: icdController,
                        decoration: const InputDecoration(
                          labelText: 'ICD-10 Code',
                          hintText: 'e.g., E11.9',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: ['active', 'chronic', 'resolved', 'inactive'].map((s) => 
                                DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))
                              ).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedStatus = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSeverity,
                              decoration: const InputDecoration(
                                labelText: 'Severity',
                                border: OutlineInputBorder(),
                              ),
                              items: ['mild', 'moderate', 'severe'].map((s) => 
                                DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))
                              ).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedSeverity = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: onsetDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setModalState(() => onsetDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Onset Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            onsetDate != null ? _formatFullDate(onsetDate!) : 'Select date',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter problem name')),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a patient first')),
                              );
                              return;
                            }

                            if (editProblem != null) {
                              await _problemListService.updateProblem(
                                id: editProblem.id,
                                problemName: nameController.text,
                                icdCode: icdController.text.isNotEmpty ? icdController.text : null,
                                status: selectedStatus,
                                severity: selectedSeverity,
                                onsetDate: onsetDate,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            } else {
                              await _problemListService.addProblem(
                                patientId: widget.patientId!,
                                problemName: nameController.text,
                                icdCode: icdController.text.isNotEmpty ? icdController.text : null,
                                status: selectedStatus,
                                severity: selectedSeverity,
                                onsetDate: onsetDate,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(editProblem != null 
                                      ? 'Problem updated successfully' 
                                      : 'Problem added successfully'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                          child: Text(editProblem != null ? 'Update Problem' : 'Add Problem'),
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
