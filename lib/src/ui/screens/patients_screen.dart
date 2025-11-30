import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/patient_card.dart';
import 'add_patient_screen.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  String _searchQuery = '';
  String _filterRisk = 'All';
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    
    // Invalidate the provider to force a refresh
    ref.invalidate(doctorDbProvider);
    
    // Wait for a short delay to show the refresh animation
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Search and Filter
            _buildSearchAndFilter(context),
            
            // Patient List
            Expanded(
              child: dbAsync.when(
                data: (db) => _buildPatientList(context, db),
                loading: () => const LoadingState(),
                error: (err, stack) => ErrorState.generic(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(doctorDbProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GradientFAB(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AddPatientScreen()),
        ),
        heroTag: 'patients_fab',
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = AppBreakpoint.isCompact(context.screenWidth);
    
    return AppHeader(
      title: AppStrings.patients,
      subtitle: AppStrings.managePatients,
      showBackButton: true,
      trailing: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          color: AppColors.primary,
          size: isCompact ? AppIconSize.sm : AppIconSize.md,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final isDark = context.isDarkMode;
    final isCompact = AppBreakpoint.isCompact(context.screenWidth);
    final padding = isCompact ? AppSpacing.sm : AppSpacing.lg;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // Search Bar
          AppSearchBar(
            hintText: AppStrings.searchPatients,
            value: _searchQuery,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () => setState(() => _searchQuery = ''),
          ),
          SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.md),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [AppStrings.all, AppStrings.lowRisk, 'Medium', AppStrings.highRisk].map((filter) {
                final isSelected = _filterRisk == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: FilterChip(
                    label: Text(filter, style: TextStyle(fontSize: isCompact ? AppFontSize.xxs : AppFontSize.xs)),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _filterRisk = filter),
                    backgroundColor: context.colorScheme.surface,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: isCompact ? AppFontSize.xxs : AppFontSize.xs,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.xxs : AppSpacing.xs, vertical: isCompact ? AppSpacing.xxs : AppSpacing.xxs),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
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

  Widget _buildPatientList(BuildContext context, DoctorDatabase db) {
    final isCompact = AppBreakpoint.isCompact(context.screenWidth);
    final isDark = context.isDarkMode;
    
    return FutureBuilder<List<Patient>>(
      future: db.getAllPatients(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Show shimmer loading
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.sm : AppSpacing.lg),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: isCompact ? AppSpacing.xs : AppSpacing.sm),
              child: PatientCardShimmer(isCompact: isCompact),
            ),
          );
        }
        
        var patients = snapshot.data!;
        
        // Filter by search
        if (_searchQuery.isNotEmpty) {
          patients = patients.where((p) {
            final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
            return fullName.contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        // Filter by risk
        if (_filterRisk != AppStrings.all) {
          patients = patients.where((p) {
            switch (_filterRisk) {
              case 'Low Risk':
                return p.riskLevel <= 2;
              case 'Medium':
                return p.riskLevel > 2 && p.riskLevel <= 4;
              case 'High Risk':
                return p.riskLevel > 4;
              default:
                return true;
            }
          }).toList();
        }
        
        if (patients.isEmpty) {
          return EmptyState.patients(
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const AddPatientScreen()),
            ),
          );
        }
        
        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          displacement: 20,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.sm : AppSpacing.lg),
            itemCount: patients.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: isCompact ? AppSpacing.xs : AppSpacing.sm),
              child: PatientCard(
                patient: patients[index],
                index: index,
                heroTagPrefix: 'patients',
              ),
            ),
          ),
        );
      },
    );
  }
}
