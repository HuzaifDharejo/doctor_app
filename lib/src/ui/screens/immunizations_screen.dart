import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../extensions/drift_extensions.dart';
import '../../models/immunization.dart';
import '../../providers/db_provider.dart';
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
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
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
                                'Immunizations',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vaccine records & schedule',
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
                Tab(text: 'All Vaccines'),
                Tab(text: 'Due'),
                Tab(text: 'Schedule'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllVaccinesTab(),
            _buildDueVaccinesTab(),
            _buildScheduleTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddImmunizationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Record Vaccine'),
        backgroundColor: const Color(0xFF10B981),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule['age'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (schedule['vaccines'] as List<String>).map((vaccine) {
                    return Chip(
                      label: Text(
                        vaccine,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.grey.withValues(alpha: 0.1),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.vaccines,
            color: Color(0xFF10B981),
            size: 24,
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
            fontSize: 12,
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
        radius: 16,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        child: Text(
          '${record.doseNumber ?? 1}',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            )
          : null,
      trailing: record.nextDueDate != null
          ? Chip(
              label: Text(
                'Next: ${_formatDate(record.nextDueDate!)}',
                style: const TextStyle(fontSize: 10),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isOverdue ? Colors.red : Colors.orange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOverdue ? Icons.warning : Icons.schedule,
            color: isOverdue ? Colors.red : Colors.orange,
            size: 24,
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
            const SizedBox(height: 4),
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
                  fontSize: 12,
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
            size: 64,
            color: iconColor ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vaccines,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          immunization.vaccineName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (immunization.doseNumber != null)
                          Text(
                            'Dose ${immunization.doseNumber}',
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
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
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Record Immunization',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: vaccineController,
                        decoration: const InputDecoration(
                          labelText: 'Vaccine Name *',
                          hintText: 'e.g., MMR, DTaP, Influenza',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: lotController,
                        decoration: const InputDecoration(
                          labelText: 'Lot Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: siteController,
                        decoration: const InputDecoration(
                          labelText: 'Administration Site',
                          hintText: 'e.g., Left arm, Right thigh',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
