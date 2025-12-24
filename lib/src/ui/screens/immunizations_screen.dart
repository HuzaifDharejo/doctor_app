import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/drift_extensions.dart';
import '../../services/immunization_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient immunization records
class ImmunizationsScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const ImmunizationsScreen({super.key, this.patientId});

  @override
  ConsumerState<ImmunizationsScreen> createState() => _ImmunizationsScreenState();
}

class _ImmunizationsScreenState extends ConsumerState<ImmunizationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _immunizationService = ImmunizationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.vaccines,
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
                                'Immunizations',
                                style: TextStyle(
                                  fontSize: AppFontSize.xxxl,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Vaccine records & schedule',
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
            // Tab Bar
            _buildTabBar(isDark),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllVaccinesTab(),
                  _buildDueVaccinesTab(),
                  _buildScheduleTab(),
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
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddImmunizationDialog(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Record Vaccine',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
        labelColor: const Color(0xFF10B981),
        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        indicator: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: -AppSpacing.sm),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(AppRadius.md),
        tabs: [
          _buildImmunizationTab('All Vaccines', Icons.vaccines_rounded),
          _buildImmunizationTab('Due', Icons.notifications_active_rounded),
          _buildImmunizationTab('Schedule', Icons.calendar_today_rounded),
        ],
      ),
    );
  }

  Widget _buildImmunizationTab(String label, IconData icon) {
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

  Widget _buildAllVaccinesTab() {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    return FutureBuilder<List<ImmunizationData>>(
      future: _immunizationService.getImmunizationsForPatient(widget.patientId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No immunization records', 'Record a vaccine to get started');
        }

        final immunizations = snapshot.data!;
        // Group by vaccine name
        final grouped = <String, List<ImmunizationData>>{};
        for (final imm in immunizations) {
          grouped.putIfAbsent(imm.vaccineName, () => []).add(imm);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final vaccineName = grouped.keys.elementAt(index);
              final records = grouped[vaccineName]!;
              return _buildVaccineGroupCard(vaccineName, records);
            },
          ),
        );
      },
    );
  }

  Widget _buildDueVaccinesTab() {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    return FutureBuilder<List<ImmunizationData>>(
      future: _immunizationService.getDueImmunizations(widget.patientId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'All vaccines up to date! 🎉',
            'No vaccines are currently due',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        }

        final dueVaccines = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: dueVaccines.length,
            itemBuilder: (context, index) {
              return _buildDueVaccineCard(dueVaccines[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Standard vaccine schedule
    final schedules = [
      {'age': 'Birth', 'vaccines': ['Hepatitis B (1st dose)']},
      {'age': '2 months', 'vaccines': ['DTaP', 'Hib', 'IPV', 'PCV13', 'RV', 'HepB (2nd)']},
      {'age': '4 months', 'vaccines': ['DTaP', 'Hib', 'IPV', 'PCV13', 'RV']},
      {'age': '6 months', 'vaccines': ['DTaP', 'Hib', 'PCV13', 'RV', 'HepB (3rd)', 'Flu']},
      {'age': '12-15 months', 'vaccines': ['MMR', 'Varicella', 'Hib', 'PCV13', 'HepA']},
      {'age': '15-18 months', 'vaccines': ['DTaP']},
      {'age': '4-6 years', 'vaccines': ['DTaP', 'IPV', 'MMR', 'Varicella']},
      {'age': '11-12 years', 'vaccines': ['Tdap', 'HPV', 'MenACWY']},
      {'age': '16 years', 'vaccines': ['MenACWY booster']},
      {'age': 'Adult (yearly)', 'vaccines': ['Influenza']},
      {'age': 'Adult (65+)', 'vaccines': ['Pneumococcal', 'Shingles']},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          color: isDark ? AppColors.darkSurface : Colors.white,
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        schedule['age'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppFontSize.md,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: (schedule['vaccines'] as List<String>).map((vaccine) {
                    final icon = _getVaccineIcon(vaccine);
                    return Chip(
                      avatar: Icon(
                        icon,
                        size: 16,
                        color: const Color(0xFF10B981),
                      ),
                      label: Text(
                        vaccine,
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      side: BorderSide(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getVaccineIcon(String vaccineName) {
    final lower = vaccineName.toLowerCase();
    if (lower.contains('hepatitis') || lower.contains('hepb') || lower.contains('hepa')) {
      return Icons.bloodtype_rounded;
    }
    if (lower.contains('dtap') || lower.contains('tdap')) {
      return Icons.shield_rounded;
    }
    if (lower.contains('mmr')) {
      return Icons.healing_rounded;
    }
    if (lower.contains('varicella') || lower.contains('chickenpox')) {
      return Icons.bug_report_rounded;
    }
    if (lower.contains('hib')) {
      return Icons.coronavirus_rounded;
    }
    if (lower.contains('ipv') || lower.contains('polio')) {
      return Icons.accessibility_new_rounded;
    }
    if (lower.contains('pcv') || lower.contains('pneumococcal')) {
      return Icons.air_rounded;
    }
    if (lower.contains('rv') || lower.contains('rotavirus')) {
      return Icons.favorite_rounded;
    }
    if (lower.contains('flu') || lower.contains('influenza')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('hpv')) {
      return Icons.female_rounded;
    }
    if (lower.contains('menacwy') || lower.contains('meningococcal')) {
      return Icons.psychology_rounded;
    }
    if (lower.contains('shingles') || lower.contains('zoster')) {
      return Icons.warning_rounded;
    }
    // Default icon for vaccines
    return Icons.vaccines_rounded;
  }

  Widget _buildVaccineGroupCard(String vaccineName, List<ImmunizationData> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestRecord = records.first;
    final model = _immunizationService.toModel(latestRecord);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.vaccines,
            color: Color(0xFF10B981),
            size: AppIconSize.md,
          ),
        ),
        title: Text(
          vaccineName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${records.length} dose(s) recorded',
          style: TextStyle(
            fontSize: AppFontSize.sm,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        children: records.map((record) => _buildDoseItem(record)).toList(),
      ),
    );
  }

  Widget _buildDoseItem(ImmunizationData record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: CircleAvatar(
        radius: AppSpacing.lg,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        child: Text(
          '${record.doseNumber ?? 1}',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: AppFontSize.sm,
          ),
        ),
      ),
      title: Text(
        _formatDate(record.dateAdministered),
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: record.lotNumber != null
          ? Text(
              'Lot: ${record.lotNumber}',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            )
          : null,
      trailing: record.nextDueDate != null
          ? Chip(
              label: Text(
                'Next: ${_formatDate(record.nextDueDate!)}',
                style: const TextStyle(fontSize: AppFontSize.xs),
              ),
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
            )
          : null,
      onTap: () => _showImmunizationDetails(record),
    );
  }

  Widget _buildDueVaccineCard(ImmunizationData immunization) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = immunization.nextDueDate != null && 
        immunization.nextDueDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: isOverdue ? Colors.red.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: (isOverdue ? Colors.red : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            color: isOverdue ? Colors.red : Colors.orange,
            size: AppIconSize.md,
          ),
        ),
        title: Text(
          immunization.vaccineName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              isOverdue 
                  ? 'Overdue since ${_formatDate(immunization.nextDueDate!)}'
                  : 'Due: ${_formatDate(immunization.nextDueDate!)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (immunization.doseNumber != null)
              Text(
                'Dose ${(immunization.doseNumber ?? 0) + 1}',
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _recordDose(immunization),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
          ),
          child: const Text('Record'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {IconData? icon, Color? iconColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.vaccines,
            size: AppIconSize.xxl,
            color: iconColor ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
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
    return _buildEmptyState(
      'Select a patient',
      'Choose a patient to view immunization records',
      icon: Icons.person_search,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImmunizationDetails(ImmunizationData immunization) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                    child: const Icon(
                      Icons.vaccines,
                      color: Color(0xFF10B981),
                      size: AppIconSize.lg,
                    ),
                  ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              immunization.vaccineName,
                              style: const TextStyle(
                                fontSize: AppFontSize.xxxl,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (immunization.doseNumber != null)
                              Text(
                                'Dose ${immunization.doseNumber}',
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
                  const SizedBox(height: AppSpacing.xxl),
              _buildDetailRow('Date Administered', _formatDate(immunization.dateAdministered)),
              if (immunization.lotNumber != null)
                _buildDetailRow('Lot Number', immunization.lotNumber!),
              if (immunization.manufacturer != null)
                _buildDetailRow('Manufacturer', immunization.manufacturer!),
              if (immunization.administrationSite != null)
                _buildDetailRow('Site', immunization.administrationSite!),
              if (immunization.administeredBy != null)
                _buildDetailRow('Administered By', immunization.administeredBy!),
              if (immunization.nextDueDate != null)
                _buildDetailRow('Next Due', _formatDate(immunization.nextDueDate!)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.lg,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _recordDose(ImmunizationData immunization) {
    _showAddImmunizationDialog(context, prefillVaccine: immunization.vaccineName);
  }

  void _showAddImmunizationDialog(BuildContext context, {String? prefillVaccine}) {
    final vaccineController = TextEditingController(text: prefillVaccine);
    final lotController = TextEditingController();
    final manufacturerController = TextEditingController();
    final siteController = TextEditingController();
    final doseController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now();

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
                      const Text(
                        'Record Immunization',
                        style: TextStyle(
                          fontSize: AppFontSize.xxxl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: vaccineController,
                        decoration: const InputDecoration(
                          labelText: 'Vaccine Name *',
                          hintText: 'e.g., MMR, DTaP, Influenza',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: doseController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Dose Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setModalState(() => selectedDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_formatDate(selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: lotController,
                        decoration: const InputDecoration(
                          labelText: 'Lot Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: siteController,
                        decoration: const InputDecoration(
                          labelText: 'Administration Site',
                          hintText: 'e.g., Left arm, Right thigh',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (vaccineController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter vaccine name')),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a patient first')),
                              );
                              return;
                            }

                            await _immunizationService.recordImmunization(
                              patientId: widget.patientId!,
                              vaccineName: vaccineController.text,
                              dateAdministered: selectedDate,
                              doseNumber: int.tryParse(doseController.text) ?? 1,
                              lotNumber: lotController.text.isNotEmpty ? lotController.text : null,
                              manufacturer: manufacturerController.text.isNotEmpty ? manufacturerController.text : null,
                              administrationSite: siteController.text.isNotEmpty ? siteController.text : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Immunization recorded successfully')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                          child: const Text('Record Immunization'),
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
