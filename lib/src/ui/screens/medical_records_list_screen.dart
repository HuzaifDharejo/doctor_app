import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/mixins/responsive_mixin.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/components/app_button.dart';
import '../widgets/medical_record_widgets.dart';
import 'medical_record_detail_screen.dart';
import 'records/records.dart';

/// A modern screen to list all medical records with filtering and search
/// 
/// Features:
/// - Type-based filtering via chips
/// - Debounced search for performance
/// - Grouped by date display
/// - Pull-to-refresh support
/// - Empty states with contextual messages
class MedicalRecordsListScreen extends ConsumerStatefulWidget {
  
  const MedicalRecordsListScreen({
    super.key,
    this.filterRecordType,
  });
  /// Optional filter to show only specific record type
  final String? filterRecordType;

  @override
  ConsumerState<MedicalRecordsListScreen> createState() => _MedicalRecordsListScreenState();
}

class _MedicalRecordsListScreenState extends ConsumerState<MedicalRecordsListScreen>
    with ResponsiveConsumerStateMixin {
  // State
  String _searchQuery = '';
  String? _selectedRecordType;
  
  // Controllers
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Debounce timer for search
  Timer? _debounceTimer;
  
  // Date formatter (cached for performance)
  static final _dateFormat = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _selectedRecordType = widget.filterRecordType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Handle search with debouncing for performance
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.toLowerCase());
      }
    });
  }

  /// Clear search and reset
  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: dbAsync.when(
        data: (db) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorDbProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Header(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: _onSearchChanged,
                onClearSearch: _clearSearch,
              ),),
              SliverToBoxAdapter(child: _FilterChipsRow(
                selectedRecordType: _selectedRecordType,
                onTypeSelected: (type) => setState(() => _selectedRecordType = type),
                isDark: isDark,
              ),),
              SliverPadding(
                padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
                sliver: _RecordsList(
                  db: db,
                  searchQuery: _searchQuery,
                  selectedRecordType: _selectedRecordType,
                  isDark: isDark,
                  dateFormat: _dateFormat,
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _ErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(doctorDbProvider),
        ),
      ),
      floatingActionButton: _AddRecordFAB(selectedRecordType: _selectedRecordType),
    );
  }
}

// ============================================================================
// HEADER SECTION
// ============================================================================

class _Header extends StatelessWidget {

  const _Header({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(MedicalRecordConstants.radiusHeader),
          bottomRight: Radius.circular(MedicalRecordConstants.radiusHeader),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(MedicalRecordConstants.paddingXLarge),
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              const SizedBox(height: MedicalRecordConstants.paddingXLarge),
              _buildTitleSection(isDark),
              const SizedBox(height: MedicalRecordConstants.paddingXLarge),
              _buildSearchBar(isDark),
              const SizedBox(height: MedicalRecordConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.folder_special_rounded,
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
                'Medical Records',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient histories & clinical documents',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.6) 
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MedicalRecordConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search records...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                  onPressed: onClearSearch,
                  tooltip: 'Clear search',
                )
              : null,
        ),
        onChanged: onSearchChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

// ============================================================================
// FILTER CHIPS
// ============================================================================

class _FilterChipsRow extends StatelessWidget {

  const _FilterChipsRow({
    required this.selectedRecordType,
    required this.onTypeSelected,
    required this.isDark,
  });
  final String? selectedRecordType;
  final ValueChanged<String?> onTypeSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final allTypes = RecordTypeInfo.allTypes;
    
    return Padding(
      padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: allTypes.map((type) {
            final typeValue = type.recordType.isEmpty ? null : type.recordType;
            final isSelected = selectedRecordType == typeValue;
            
            return Padding(
              padding: const EdgeInsets.only(right: MedicalRecordConstants.paddingSmall),
              child: RecordTypeFilterChip(
                recordType: type,
                isSelected: isSelected,
                onTap: () => onTypeSelected(typeValue),
                isDark: isDark,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// RECORDS LIST
// ============================================================================

class _RecordsList extends StatelessWidget {

  const _RecordsList({
    required this.db,
    required this.searchQuery,
    required this.selectedRecordType,
    required this.isDark,
    required this.dateFormat,
  });
  final DoctorDatabase db;
  final String searchQuery;
  final String? selectedRecordType;
  final bool isDark;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MedicalRecordWithPatient>>(
      future: _getFilteredRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _ErrorState(
              error: snapshot.error.toString(),
              onRetry: () {}, // Will be handled by parent RefreshIndicator
            ),
          );
        }

        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return SliverFillRemaining(
            child: _EmptyState(
              selectedRecordType: selectedRecordType,
              hasSearchQuery: searchQuery.isNotEmpty,
            ),
          );
        }

        // Group records by date
        final groupedRecords = _groupByDate(records);
        final dateKeys = groupedRecords.keys.toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _DateGroupSection(
              dateKey: dateKeys[index],
              records: groupedRecords[dateKeys[index]]!,
              isFirst: index == 0,
              isDark: isDark,
              dateFormat: dateFormat,
            ),
            childCount: dateKeys.length,
          ),
        );
      },
    );
  }

  Future<List<MedicalRecordWithPatient>> _getFilteredRecords() async {
    final records = await db.getAllMedicalRecordsWithPatients();
    
    return records.where((r) {
      // Filter by record type
      if (selectedRecordType != null && r.record.recordType != selectedRecordType) {
        return false;
      }
      
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final searchableText = [
          r.record.title,
          r.record.diagnosis,
          r.record.treatment,
          r.patient.firstName,
          r.patient.lastName,
        ].join(' ').toLowerCase();
        
        return searchableText.contains(searchQuery);
      }
      
      return true;
    }).toList()
      ..sort((a, b) => b.record.recordDate.compareTo(a.record.recordDate));
  }

  Map<String, List<MedicalRecordWithPatient>> _groupByDate(List<MedicalRecordWithPatient> records) {
    final grouped = <String, List<MedicalRecordWithPatient>>{};
    for (final record in records) {
      final dateKey = dateFormat.format(record.record.recordDate);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }
    return grouped;
  }
}

// ============================================================================
// DATE GROUP SECTION
// ============================================================================

class _DateGroupSection extends StatelessWidget {

  const _DateGroupSection({
    required this.dateKey,
    required this.records,
    required this.isFirst,
    required this.isDark,
    required this.dateFormat,
  });
  final String dateKey;
  final List<MedicalRecordWithPatient> records;
  final bool isFirst;
  final bool isDark;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateHeader(dateKey: dateKey, recordCount: records.length, isFirst: isFirst, isDark: isDark),
        ...records.map((record) => _RecordCard(
          recordWithPatient: record,
          isDark: isDark,
        ),),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {

  const _DateHeader({
    required this.dateKey,
    required this.recordCount,
    required this.isFirst,
    required this.isDark,
  });
  final String dateKey;
  final int recordCount;
  final bool isFirst;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MedicalRecordConstants.paddingMedium,
        top: isFirst ? 0 : MedicalRecordConstants.paddingLarge,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: MedicalRecordConstants.iconSmall, color: AppColors.primary),
                const SizedBox(width: MedicalRecordConstants.paddingSmall),
                Text(
                  dateKey,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: MedicalRecordConstants.fontMedium,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MedicalRecordConstants.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusMedium),
            ),
            child: Text(
              '$recordCount',
              style: const TextStyle(
                fontSize: MedicalRecordConstants.fontBody,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECORD CARD
// ============================================================================

class _RecordCard extends StatelessWidget {

  const _RecordCard({
    required this.recordWithPatient,
    required this.isDark,
  });
  final MedicalRecordWithPatient recordWithPatient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final record = recordWithPatient.record;
    final patient = recordWithPatient.patient;
    final recordInfo = RecordTypeInfo.fromType(record.recordType);
    final patientName = '${patient.firstName} ${patient.lastName}';

    return Semantics(
      label: '${record.title}, ${recordInfo.label} for $patientName',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: MedicalRecordConstants.paddingMedium),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: recordInfo.color.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _navigateToDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(MedicalRecordConstants.paddingLarge),
              child: Row(
                children: [
                  _buildIcon(recordInfo),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInfo(record, recordInfo, patientName)),
                  _buildArrow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(RecordTypeInfo recordInfo) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [recordInfo.color, recordInfo.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: recordInfo.color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        recordInfo.icon,
        color: Colors.white,
        size: MedicalRecordConstants.iconXLarge,
      ),
    );
  }

  Widget _buildInfo(MedicalRecord record, RecordTypeInfo recordInfo, String patientName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: recordInfo.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusSmall),
          ),
          child: Text(
            recordInfo.label,
            style: TextStyle(
              color: recordInfo.color,
              fontSize: MedicalRecordConstants.fontSmall,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.person_outline, size: MedicalRecordConstants.iconSmall, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                patientName,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: MedicalRecordConstants.fontBody,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MedicalRecordDetailScreen(
          record: recordWithPatient.record,
          patient: recordWithPatient.patient,
        ),
      ),
    );
  }
}

// ============================================================================
// FLOATING ACTION BUTTON
// ============================================================================

class _AddRecordFAB extends StatelessWidget {

  const _AddRecordFAB({this.selectedRecordType});
  final String? selectedRecordType;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(MedicalRecordConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _addRecord(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Future<void> _addRecord(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const SelectRecordTypeScreen(),
      ),
    );
    
    if ((result ?? false) && context.mounted) {
      // Trigger rebuild by invalidating the provider
      // This is handled by the parent widget's state
    }
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {

  const _EmptyState({
    required this.hasSearchQuery, this.selectedRecordType,
  });
  final String? selectedRecordType;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recordInfo = selectedRecordType != null 
        ? RecordTypeInfo.fromType(selectedRecordType!)
        : null;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearchQuery ? Icons.search_off : Icons.folder_open,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getTitle(recordInfo),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getSubtitle(),
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(RecordTypeInfo? recordInfo) {
    if (hasSearchQuery) {
      return 'No Results Found';
    }
    if (recordInfo != null) {
      return 'No ${recordInfo.label} Records';
    }
    return 'No Medical Records';
  }

  String _getSubtitle() {
    if (hasSearchQuery) {
      return 'Try a different search term';
    }
    return 'Add medical records to get started';
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================

class _ErrorState extends StatelessWidget {

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

