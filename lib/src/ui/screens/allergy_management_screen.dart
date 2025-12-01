import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/allergy_management_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/allergy_filter_widget.dart';

/// Screen for managing and analyzing patient allergies
class AllergyManagementScreen extends ConsumerStatefulWidget {
  const AllergyManagementScreen({super.key});

  @override
  ConsumerState<AllergyManagementScreen> createState() =>
      _AllergyManagementScreenState();
}

class _AllergyManagementScreenState extends ConsumerState<AllergyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _allergyService = const AllergyManagementService();
  final _searchController = TextEditingController();
  List<String> _selectedFilter = [];

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergy Management'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'High-Risk Patients'),
            Tab(text: 'By Allergen'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHighRiskTab(),
          _buildByAllergenTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildHighRiskTab() {
    return FutureBuilder<DoctorDatabase>(
      future: ref.watch(doctorDbProvider.future),
      builder: (context, dbSnapshot) {
        if (!dbSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<PatientAllergyInfo>>(
          future: _allergyService.getHighRiskPatients(dbSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No high-risk patients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No patients with 3+ allergies',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }

            final patients = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patientInfo = patients[index];
                return _buildPatientAllergyCard(patientInfo);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildByAllergenTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search allergens...',
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
          child: FutureBuilder<DoctorDatabase>(
            future: ref.watch(doctorDbProvider.future),
            builder: (context, dbSnapshot) {
              if (!dbSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final query = _searchController.text;

              return FutureBuilder<List<PatientAllergyInfo>>(
                future: query.isEmpty
                    ? Future.value([])
                    : _allergyService.searchPatientsByAllergen(
                        dbSnapshot.data!,
                        query,
                      ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patients = snapshot.data ?? [];

                  if (query.isEmpty) {
                    return AllergyFilterWidget(
                      onAllergySelected: (allergen) {
                        setState(() {
                          _searchController.text = allergen;
                        });
                      },
                      onFilterApplied: (allergens) {
                        setState(() {
                          _selectedFilter = allergens;
                        });
                      },
                    );
                  }

                  if (patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No patients found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'with allergen "$query"',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientAllergyCard(patients[index]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<DoctorDatabase>(
      future: ref.watch(doctorDbProvider.future),
      builder: (context, dbSnapshot) {
        if (!dbSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<AllergenStatistics>(
          future: _allergyService.getAllergenStatistics(dbSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final stats = snapshot.data!;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Statistics cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Patients with Allergies',
                        value: stats.totalPatientsWithAllergies.toString(),
                        icon: Icons.person_outline,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Multi-Allergen Patients',
                        value: stats.patientsWithMultipleAllergies.toString(),
                        icon: Icons.warning_outlined,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Unique Allergens',
                        value: stats.totalUniqueAllergens.toString(),
                        icon: Icons.category_outlined,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Allergy Prevalence',
                        value: '${(stats.allergyPrevalence * 100).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Most common allergens
                Text(
                  'Most Common Allergens',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.mostCommonAllergens.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final allergen = stats.mostCommonAllergens[index];
                      final maxCount = stats.mostCommonAllergens.first.count;
                      final percentage = (allergen.count / maxCount * 100).toInt();

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    allergen.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${allergen.count} patients',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAllergyCard(PatientAllergyInfo patientInfo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      patientInfo.riskColor.withValues(alpha: 0.2),
                  child: Text(
                    patientInfo.initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: patientInfo.riskColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientInfo.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${patientInfo.allergyCount} allergies',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: patientInfo.riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    patientInfo.riskLevel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: patientInfo.riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: patientInfo.allergens.map((allergen) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    allergen,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

