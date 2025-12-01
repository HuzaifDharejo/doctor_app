import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/allergy_management_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Allergy filter and search widget for finding patients with specific allergies
class AllergyFilterWidget extends ConsumerStatefulWidget {
  const AllergyFilterWidget({
    required this.onAllergySelected,
    required this.onFilterApplied,
    super.key,
  });

  final Function(String allergen) onAllergySelected;
  final Function(List<String> selectedAllergies) onFilterApplied;

  @override
  ConsumerState<AllergyFilterWidget> createState() => _AllergyFilterWidgetState();
}

class _AllergyFilterWidgetState extends ConsumerState<AllergyFilterWidget> {
  late AllergyManagementService _allergyService;
  List<AllergenInfo> _allergens = [];
  List<String> _selectedAllergies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _allergyService = const AllergyManagementService();
    _loadAllergens();
  }

  Future<void> _loadAllergens() async {
    setState(() => _isLoading = true);
    try {
      final db = await ref.read(doctorDbProvider.future);
      final allergens = await _allergyService.getAllAllergens(db);
      setState(() {
        _allergens = allergens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading allergens: $e');
    }
  }

  void _toggleAllergy(String allergen) {
    setState(() {
      if (_selectedAllergies.contains(allergen)) {
        _selectedAllergies.remove(allergen);
      } else {
        _selectedAllergies.add(allergen);
      }
    });
    widget.onFilterApplied(_selectedAllergies);
  }

  void _clearFilters() {
    setState(() => _selectedAllergies.clear());
    widget.onFilterApplied([]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_allergens.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No allergies found in system',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Allergen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_selectedAllergies.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  ),
                ),
            ],
          ),
        ),
        // Selected allergens display
        if (_selectedAllergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedAllergies.map((allergen) {
                return Chip(
                  label: Text(allergen),
                  onDeleted: () => _toggleAllergy(allergen),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        // Allergen list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergens.map((allergen) {
              final isSelected = _selectedAllergies.contains(allergen.name);
              return FilterChip(
                label: Text(allergen.name),
                selected: isSelected,
                onSelected: (_) => _toggleAllergy(allergen.name),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// High-risk patients display showing allergies
class HighRiskAllergiesCard extends ConsumerWidget {
  const HighRiskAllergiesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DoctorDatabase>(
      future: ref.watch(doctorDbProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<PatientAllergyInfo>>(
          future: const AllergyManagementService()
              .getHighRiskPatients(snapshot.data!),
          builder: (context, allergySnapshot) {
            if (!allergySnapshot.hasData || allergySnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final highRiskPatients = allergySnapshot.data!.take(5).toList();

            return Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.red.withValues(alpha: 0.05),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'High-Risk Patients (Multiple Allergies)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: highRiskPatients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final patientInfo = highRiskPatients[index];
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      patientInfo.riskColor.withValues(alpha: 0.2),
                                  child: Text(
                                    patientInfo.initials,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: patientInfo.riskColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientInfo.fullName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${patientInfo.allergyCount} allergies',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: patientInfo.riskColor
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    patientInfo.riskLevel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: patientInfo.riskColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: patientInfo.allergens
                                  .take(3)
                                  .map((allergen) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    allergen,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (patientInfo.allergens.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+${patientInfo.allergens.length - 3} more',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

