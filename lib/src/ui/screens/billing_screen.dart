import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/components/app_button.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/pagination.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_loading.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import 'add_invoice_screen.dart';
import 'patient_view/patient_view.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final Map<String, PaginationController<Invoice>> _paginationControllers = {};
  final Map<String, ScrollController> _scrollControllers = {};
  Timer? _debounceTimer;

  // Theme color for billing
  static const _themeColor = Color(0xFF8B5CF6); // Purple theme (matches AppColors.billing)

  String get _selectedFilter {
    switch (_tabController.index) {
      case 0:
        return 'All';
      case 1:
        return 'Paid';
      case 2:
        return 'Pending';
      case 3:
        return 'Overdue';
      default:
        return 'All';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _initPaginationControllers();
  }

  void _initPaginationControllers() {
    final filters = ['All', 'Paid', 'Pending', 'Overdue'];
    for (final filter in filters) {
      _scrollControllers[filter] = ScrollController();
      _scrollControllers[filter]!.addListener(() => _onScroll(filter));
      
      _paginationControllers[filter] = PaginationController<Invoice>(
        fetchPage: (pageIndex, pageSize) => _fetchPage(pageIndex, pageSize, filter),
      );
      _paginationControllers[filter]!.addListener(() {
        if (mounted && _selectedFilter == filter) {
          setState(() {});
        }
      });
      _paginationControllers[filter]!.loadInitial();
    }
  }

  Future<(List<Invoice>, int)> _fetchPage(int pageIndex, int pageSize, String filter) async {
    final db = await ref.read(doctorDbProvider.future);
    final status = filter == 'All' ? null : filter;
    return db.getInvoicesPaginated(
      offset: pageIndex * pageSize,
      limit: pageSize,
      status: status,
      searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  void _onScroll(String filter) {
    if (!mounted) return;
    final scrollController = _scrollControllers[filter];
    final paginationController = _paginationControllers[filter];
    if (scrollController != null && 
        paginationController != null && 
        scrollController.hasClients) {
      paginationController.onScroll(
        scrollPosition: scrollController.position.pixels,
        maxScrollExtent: scrollController.position.maxScrollExtent,
        threshold: 200,
      );
    }
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Refresh all pagination controllers when search changes
      for (final controller in _paginationControllers.values) {
        controller.refresh();
      }
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounceTimer?.cancel();
    for (final controller in _paginationControllers.values) {
      controller.dispose();
    }
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: dbAsync.when(
        data: (db) => _buildContent(context, db, isDark),
        loading: () => const InvoiceListSkeleton(itemCount: 5),
        error: (err, stack) => ErrorState.generic(
          message: err.toString(),
          onRetry: () => ref.invalidate(doctorDbProvider),
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildContent(BuildContext context, DoctorDatabase db, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildModernSliverAppBar(context, isDark, colorScheme),
      ],
      body: Column(
        children: [
          // Modern Search Bar
          _buildSearchBar(isDark),
          
          // Tab Bar
          _buildTabBar(isDark),
          
          // Summary Cards
          FutureBuilder<Map<String, double>>(
            future: db.getInvoiceStats(),
            builder: (context, statsSnapshot) {
              final stats = statsSnapshot.data ?? {
                'totalRevenue': 0.0,
                'pending': 0.0,
                'pendingCount': 0.0,
              };
              return _buildSummaryCards(context, stats);
            },
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoiceList('All', isDark),
                _buildInvoiceList('Paid', isDark),
                _buildInvoiceList('Pending', isDark),
                _buildInvoiceList('Overdue', isDark),
              ],
            ),
          ),
        ],
      ),
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
                    padding: EdgeInsets.all(context.responsivePadding),
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
                      Icons.account_balance_wallet_rounded,
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
                          'Billing',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage invoices & payments',
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
            hintText: 'Search invoices...',
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
          _buildBillingTab('All', Icons.list_alt_rounded),
          _buildBillingTab('Paid', Icons.check_circle_rounded),
          _buildBillingTab('Pending', Icons.pending_actions_rounded),
          _buildBillingTab('Overdue', Icons.error_rounded),
        ],
      ),
    );
  }

  Widget _buildBillingTab(String label, IconData icon) {
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

  Widget _buildInvoiceList(String filter, bool isDark) {
    final paginationController = _paginationControllers[filter]!;
    final scrollController = _scrollControllers[filter]!;
    final dbAsync = ref.watch(doctorDbProvider);

    if (!paginationController.hasInitialized) {
      return const InvoiceListSkeleton(itemCount: 5);
    }

    if (paginationController.error != null) {
      return Center(
        child: ErrorState.generic(
          message: paginationController.error!,
          onRetry: () => paginationController.loadInitial(),
        ),
      );
    }

    final invoices = paginationController.items;

    if (invoices.isEmpty && !paginationController.isLoading) {
      return _buildEmptyState(context);
    }

    return dbAsync.when(
      data: (db) => ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: invoices.length + (paginationController.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= invoices.length) {
            // Loading indicator at the end
            if (paginationController.hasMore && paginationController.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

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
            child: _buildInvoiceCard(context, db, invoices[index]),
          );
        },
      ),
      loading: () => const InvoiceListSkeleton(itemCount: 5),
      error: (err, stack) => Center(
        child: ErrorState.generic(
          message: err.toString(),
          onRetry: () => ref.invalidate(doctorDbProvider),
        ),
      ),
    );
  }


  Widget _buildSummaryCards(BuildContext context, Map<String, double> stats) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 16.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              'Total Revenue',
              currencyFormat.format(stats['totalRevenue'] ?? 0),
              Icons.trending_up_rounded,
            AppColors.success,
            'All time',
            useGradient: true,
          ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: _buildSummaryCard(
              context,
              'Pending',
              currencyFormat.format(stats['pending'] ?? 0),
              Icons.schedule_rounded,
              AppColors.warning,
              '${(stats['pendingCount'] ?? 0).toInt()} invoices',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    bool useGradient = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        gradient: useGradient 
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: useGradient ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: useGradient ? null : Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: useGradient 
                ? color.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: useGradient 
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: useGradient ? Colors.white : color, 
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: useGradient 
                        ? Colors.white.withValues(alpha: 0.85)
                        : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: useGradient 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: useGradient ? Colors.white.withValues(alpha: 0.7) : color,
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildInvoiceCard(BuildContext context, DoctorDatabase db, Invoice invoice) {
    Color statusColor;
    IconData statusIcon;
    switch (invoice.paymentStatus) {
      case 'Paid':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
      case 'Pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule_rounded;
      case 'Overdue':
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
      case 'Partial':
        statusColor = AppColors.info;
        statusIcon = Icons.pie_chart_rounded;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.receipt_long_rounded;
    }

    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return FutureBuilder<Patient?>(
      future: db.getPatientById(invoice.patientId),
      builder: (context, patientSnapshot) {
        final patient = patientSnapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}'
            : 'Patient #${invoice.patientId}';

        return AppCard(
          margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          borderColor: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
          borderWidth: 1,
          boxShadow: [
            BoxShadow(
              color: AppColors.billing.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          onTap: () => _showInvoiceDetails(context, db, invoice, patient),
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: Row(
                  children: [
                    // Invoice icon with gradient
                    Container(
                      padding: EdgeInsets.all(isCompact ? 12 : 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.billing,
                            AppColors.billing.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.billing.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: isCompact ? 22 : 24,
                      ),
                    ),
                    SizedBox(width: isCompact ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: isCompact ? 13 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withValues(alpha: 0.2),
                                      statusColor.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 12, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      invoice.paymentStatus,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: patient != null ? () {
                                    if (!mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => PatientViewScreenModern(patient: patient),
                                      ),
                                    );
                                  } : null,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          patientName,
                                          style: TextStyle(
                                            fontSize: isCompact ? 10 : 11,
                                            fontWeight: FontWeight.w500,
                                            color: patient != null 
                                                ? AppColors.primary 
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(invoice.grandTotal),
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFormat.format(invoice.invoiceDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showInvoiceDetails(BuildContext context, DoctorDatabase db, Invoice invoice, Patient? patient) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    // V5: Use getLineItemsForInvoiceCompat for backwards compatibility
    db.getLineItemsForInvoiceCompat(invoice.id).then((loadedItems) {
      List<dynamic> items = loadedItems;

      Color statusColor;
      switch (invoice.paymentStatus) {
        case 'Paid':
          statusColor = AppColors.success;
        case 'Pending':
          statusColor = AppColors.warning;
        case 'Overdue':
          statusColor = AppColors.error;
        default:
          statusColor = AppColors.info;
      }

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkDivider : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVOICE',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        invoice.paymentStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn('Invoice Date', dateFormat.format(invoice.invoiceDate)),
                    ),
                    if (invoice.dueDate != null)
                      Expanded(
                        child: _buildInfoColumn('Due Date', dateFormat.format(invoice.dueDate!)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Patient
                if (patient != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            patient.firstName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${patient.firstName} ${patient.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (patient.phone.isNotEmpty)
                                Text(
                                  patient.phone,
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () {
                            if (!mounted) return;
                            Navigator.pop(context);
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => PatientViewScreenModern(patient: patient),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                
                // Items
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item as Map<String, dynamic>)['description'] as String? ?? 'Item',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Qty: ${item['quantity']} × ${currencyFormat.format((item['rate'] as num?) ?? 0)}',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item['total'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Totals
                _buildTotalRow('Subtotal', invoice.subtotal, currencyFormat),
                if (invoice.discountAmount > 0)
                  _buildTotalRow('Discount (${invoice.discountPercent}%)', -invoice.discountAmount, currencyFormat, isDiscount: true),
                if (invoice.taxAmount > 0)
                  _buildTotalRow('Tax (${invoice.taxPercent}%)', invoice.taxAmount, currencyFormat),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(invoice.grandTotal),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: AppButton.tertiary(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf,
                        onPressed: () async {
                          Navigator.pop(context);
                          if (patient != null) {
                            try {
                              final db = await ref.read(doctorDbProvider.future);
                              final lineItems = await db.getLineItemsForInvoiceCompat(invoice.id);
                              
                              final doctorSettings = ref.read(doctorSettingsProvider);
                              final profile = doctorSettings.profile;
                              await PdfService.shareInvoicePdf(
                                patient: patient,
                                invoice: invoice,
                                clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                                clinicPhone: profile.clinicPhone,
                                clinicAddress: profile.clinicAddress,
                                signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
                                doctorName: profile.displayName.isNotEmpty ? profile.displayName : null,
                                lineItemsList: lineItems,
                                templateConfig: profile.pdfTemplateConfig,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error generating PDF: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        label: 'WhatsApp',
                        icon: Icons.chat,
                        variant: AppButtonVariant.tertiary,
                        foregroundColor: const Color(0xFF25D366),
                        borderColor: const Color(0xFF25D366),
                        onPressed: () async {
                          Navigator.pop(context);
                          if (patient != null) {
                            final doctorSettings = ref.read(doctorSettingsProvider);
                            final profile = doctorSettings.profile;
                            await WhatsAppService.shareInvoice(
                              patient: patient,
                              invoice: invoice,
                              clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                              clinicPhone: profile.clinicPhone,
                              lineItemsList: items.cast<Map<String, dynamic>>(), // V5: Pass pre-loaded items
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient information not available'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (invoice.paymentStatus != 'Paid')
                      Expanded(
                        child: AppButton.primary(
                          label: 'Mark Paid',
                          icon: Icons.check_circle,
                          onPressed: () async {
                            await db.updateInvoice(invoice.copyWith(paymentStatus: 'Paid'));
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    }); // End of .then()
  }

  Widget _buildInfoColumn(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double amount, NumberFormat format, {bool isDiscount = false}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              Text(
                isDiscount ? '- ${format.format(amount.abs())}' : format.format(amount),
                style: TextStyle(
                  color: isDiscount ? AppColors.error : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Invoices Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Invoices will appear here when created from patient details',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

          ],
        ),
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
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(builder: (_) => const AddInvoiceScreen()),
                          );
                        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Invoice',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
