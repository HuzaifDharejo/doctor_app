import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routing/app_router.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_loading.dart';
import '../../core/utils/pagination.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/empty_state.dart';
import '../../services/patient_status_service.dart';
import '../widgets/patient_status_badge.dart';
import '../widgets/batch_operations_bar.dart';
import '../widgets/selectable_item_wrapper.dart';
import 'add_patient_screen.dart';
import 'patient_view/patient_view.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _searchQuery = '';
  String _filterRisk = 'All';
  
  // Pagination using PaginationController
  late PaginationController<Patient> _paginationController;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  
  // Batch operations
  bool _isSelectionMode = false;
  final Set<int> _selectedPatientIds = <int>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initPaginationController();
  }

  void _initPaginationController() {
    _paginationController = PaginationController<Patient>(
      fetchPage: _fetchPage,
      pageSize: 20,
    );
    _paginationController.addListener(_onPaginationUpdate);
  }

  void _onPaginationUpdate() {
    if (mounted) {
      setState(() {
        _error = _paginationController.error;
      });
    }
  }

  Future<(List<Patient>, int)> _fetchPage(int pageIndex, int pageSize) async {
    final db = await ref.read(doctorDbProvider.future);

    // Convert filter to risk level
    int? riskLevel;
    switch (_filterRisk) {
      case 'Low Risk':
        riskLevel = 1;
      case 'Medium':
        riskLevel = 2;
      case 'High Risk':
        riskLevel = 3;
    }

    return db.getPatientsPaginated(
      offset: pageIndex * pageSize,
      limit: pageSize,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      riskLevel: riskLevel,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paginationController.removeListener(_onPaginationUpdate);
    _paginationController.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _paginationController.onScroll(
      scrollPosition: _scrollController.position.pixels,
      maxScrollExtent: _scrollController.position.maxScrollExtent,
      threshold: 200,
    );
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
        });
        _refreshList();
      }
    });
  }

  void _onFilterChanged(String filter) {
    if (_filterRisk != filter) {
      setState(() {
        _filterRisk = filter;
      });
      _refreshList();
    }
  }

  void _refreshList() {
    // Recreate pagination controller with new filters
    _paginationController.removeListener(_onPaginationUpdate);
    _paginationController.dispose();
    _initPaginationController();
    _paginationController.loadInitial();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    // Refresh the pagination controller - this will reload from page 0
    await _paginationController.refresh();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? AppSpacing.lg : AppSpacing.xl;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [AppColors.darkSurface, AppColors.darkBackground]
                          : [AppColors.surface, AppColors.background],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xxxxxl + 2,
                        AppSpacing.xl,
                        0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md + 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              boxShadow: AppShadow.medium,
                            ),
                            child: Icon(
                              Icons.people_rounded,
                              color: AppColors.surface,
                              size: AppIconSize.lg,
                            ),
                          ),
                          SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Patients',
                                  style: TextStyle(
                                    fontSize: AppFontSize.displayMedium,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                // Show patient count in header
                                Text(
                                  _paginationController.hasInitialized
                                      ? '${_paginationController.totalItems} patients'
                                      : 'Manage your patients',
                                  style: TextStyle(
                                    fontSize: AppFontSize.bodyMedium,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
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
            // Search and Filter
            SliverToBoxAdapter(
              child: _buildModernSearchAndFilter(context, isDark),
            ),
            // Patient List
            dbAsync.when(
              data: (db) => _buildModernPatientList(context, db, isDark, padding),
              loading: () => const SliverFillRemaining(child: LoadingState()),
              error: (err, stack) => SliverFillRemaining(
                child: ErrorState.generic(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(doctorDbProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isSelectionMode && _selectedPatientIds.isNotEmpty
          ? BatchOperationsBar<Patient>(
              selectedCount: _selectedPatientIds.length,
              totalCount: _paginationController.totalItems,
              onSelectAll: () {
                setState(() {
                  _selectedPatientIds.addAll(
                    _paginationController.items.map((p) => p.id),
                  );
                });
              },
              onDeselectAll: () {
                setState(() {
                  _selectedPatientIds.clear();
                });
              },
              actions: [
                BatchAction<Patient>(
                  label: 'Send Reminder',
                  icon: Icons.notifications_rounded,
                  onAction: () => _handleBatchSendReminder(),
                ),
                BatchAction<Patient>(
                  label: 'Generate Invoices',
                  icon: Icons.receipt_long_rounded,
                  onAction: () => _handleBatchGenerateInvoices(),
                ),
                BatchAction<Patient>(
                  label: 'Export',
                  icon: Icons.file_download_rounded,
                  onAction: () => _handleBatchExport(),
                ),
              ],
            )
          : null,
      floatingActionButton: !_isSelectionMode ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push<Patient?>(
                context,
                MaterialPageRoute<Patient?>(builder: (_) => const AddPatientScreen()),
              );
              // Refresh list if a patient was added - use full refresh to reset pagination
              if (result != null && mounted) {
                _refreshList();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ) : null,
    );
  }

  // Batch operation handlers
  Future<void> _handleBatchSendReminder() async {
    if (_selectedPatientIds.isEmpty) return;
    
    final selectedPatients = _paginationController.items
        .where((p) => _selectedPatientIds.contains(p.id))
        .toList();
    
    // TODO: Implement batch reminder sending
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending reminders to ${selectedPatients.length} patients...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Clear selection after action
      setState(() {
        _selectedPatientIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _handleBatchGenerateInvoices() async {
    if (_selectedPatientIds.isEmpty) return;
    
    final selectedPatients = _paginationController.items
        .where((p) => _selectedPatientIds.contains(p.id))
        .toList();
    
    // TODO: Implement batch invoice generation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating invoices for ${selectedPatients.length} patients...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Clear selection after action
      setState(() {
        _selectedPatientIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _handleBatchExport() async {
    if (_selectedPatientIds.isEmpty) return;
    
    final selectedPatients = _paginationController.items
        .where((p) => _selectedPatientIds.contains(p.id))
        .toList();
    
    // TODO: Implement batch export (CSV, PDF, etc.)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exporting ${selectedPatients.length} patients...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Clear selection after action
      setState(() {
        _selectedPatientIds.clear();
        _isSelectionMode = false;
      });
    }
  }
  
  Widget _buildModernSearchAndFilter(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(context.responsivePadding),
      child: Column(
        children: [
          // Modern Search Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: Icon(Icons.close_rounded, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Modern Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Low Risk', 'Medium', 'High Risk'].map((filter) {
                final isSelected = _filterRisk == filter;
                Color chipColor;
                if (filter == 'Low Risk') {
                  chipColor = const Color(0xFF10B981);
                } else if (filter == 'Medium') {
                  chipColor = const Color(0xFFF59E0B);
                } else if (filter == 'High Risk') {
                  chipColor = const Color(0xFFEF4444);
                } else {
                  chipColor = const Color(0xFF6366F1);
                }
                
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => _onFilterChanged(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(colors: [chipColor, chipColor.withValues(alpha: 0.8)]) : null,
                        color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: chipColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernPatientList(BuildContext context, DoctorDatabase db, bool isDark, double padding) {
    final controller = _paginationController;
    
    // Initialize pagination on first load
    if (!controller.hasInitialized && !controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadInitial();
      });
    }

    // Show error state
    if (_error != null && controller.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDark ? Colors.red[300] : Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load patients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => controller.refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading on initial load
    if (!controller.hasInitialized && controller.isLoading) {
      return const SliverToBoxAdapter(
        child: PatientListSkeleton(itemCount: 6),
      );
    }

    // Show empty state
    if (controller.isEmpty) {
      return SliverFillRemaining(
        child: EmptyPatientList(
          onAddPatient: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          ),
        ),
      );
    }

    final patients = controller.items;
    final hasMore = controller.hasMore;
    final isLoading = controller.isLoading;
    final totalItems = controller.totalItems;

    // Build paginated list
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Pagination info at the end
            if (index == patients.length) {
              return _buildPaginationFooter(
                isDark: isDark,
                loadedCount: patients.length,
                totalCount: totalItems,
                hasMore: hasMore,
                isLoading: isLoading,
                onLoadMore: () => controller.loadNextPage(),
              );
            }

            final patient = patients[index];
            final dbAsync = ref.watch(doctorDbProvider);
            return dbAsync.when(
              data: (db) => _buildModernPatientCard(context, patient, isDark, db),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => _buildModernPatientCard(context, patient, isDark, null),
            );
          },
          childCount: patients.length + 1, // +1 for pagination footer
        ),
      ),
    );
  }

  Widget _buildPaginationFooter({
    required bool isDark,
    required int loadedCount,
    required int totalCount,
    required bool hasMore,
    required bool isLoading,
    required VoidCallback onLoadMore,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          // Progress indicator
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          
          // Pagination info
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasMore 
                  ? 'Showing $loadedCount of $totalCount patients'
                  : '$totalCount patients total',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Load more button (alternative to scroll)
          if (hasMore && !isLoading) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLoadMore,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.expand_more_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Load More', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          
          // Safe area padding at bottom
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
  
  Widget _buildModernPatientCard(BuildContext context, Patient patient, bool isDark, DoctorDatabase? db) {
    Color riskColor;
    String riskLabel;
    if (patient.riskLevel <= 2) {
      riskColor = const Color(0xFF10B981);
      riskLabel = 'Low';
    } else if (patient.riskLevel <= 4) {
      riskColor = const Color(0xFFF59E0B);
      riskLabel = 'Medium';
    } else {
      riskColor = const Color(0xFFEF4444);
      riskLabel = 'High';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PatientViewScreenModern(patient: patient),
              settings: const RouteSettings(name: AppRoutes.patientView),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (patient.phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            const SizedBox(width: 6),
                            Text(
                              patient.phone,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      // Patient Status Badges
                      if (db != null)
                        FutureBuilder<List<PatientStatus>>(
                          future: PatientStatusService(db: db).getPatientStatuses(
                            patient: patient,
                            appointment: null,
                          ),
                          builder: (context, statusSnapshot) {
                            if (!statusSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final statuses = statusSnapshot.data!;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: PatientStatusBadges(
                                statuses: statuses,
                                size: BadgeSize.small,
                                maxBadges: 2,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Risk Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernEmptyState(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xxxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsivePadding),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Patients Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterRisk != 'All'
                ? 'Try adjusting your search or filters'
                : 'Add your first patient to get started',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
