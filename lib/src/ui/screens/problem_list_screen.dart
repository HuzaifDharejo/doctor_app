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
                            Icons.list_alt,
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
                                'Problem List',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active conditions & diagnoses',
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
                Tab(text: 'Active'),
                Tab(text: 'Chronic'),
                Tab(text: 'Resolved'),
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
                  hintText: 'Search problems or ICD-10 codes...',
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
          ? FloatingActionButton.extended(
              onPressed: () => _showAddProblemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Problem'),
              backgroundColor: const Color(0xFF3B82F6),
            )
          : null,
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProblemIcon(problem.problemName),
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
                          problem.problemName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        if (problem.icdCode != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'ICD-10: ${problem.icdCode}',
                            style: TextStyle(
                              fontSize: 12,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  if (problem.severity != null) ...[
                    _buildInfoChip(
                      Icons.speed,
                      model.severity.displayName,
                      severityColor,
                    ),
                    const SizedBox(width: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Priority ${problem.priority}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (problem.notes != null && problem.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  problem.notes!,
                  style: TextStyle(
                    fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
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
            size: 64,
            color: status == 'resolved' ? Colors.green[300] : (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            status == 'resolved' 
                ? 'No resolved problems'
                : 'No $status problems',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add problems to track patient conditions',
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
                          color: _getStatusColor(problem.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProblemIcon(problem.problemName),
                          color: _getStatusColor(problem.status),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.problemName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (problem.icdCode != null)
                              Text(
                                'ICD-10: ${problem.icdCode}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusChip(problem.status, _getStatusColor(problem.status)),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                        const SizedBox(width: 12),
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
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        editProblem != null ? 'Edit Problem' : 'Add Problem',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Problem Name *',
                          hintText: 'e.g., Type 2 Diabetes Mellitus',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: icdController,
                        decoration: const InputDecoration(
                          labelText: 'ICD-10 Code',
                          hintText: 'e.g., E11.9',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
