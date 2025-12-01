import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/drug_reference_service.dart';
import '../widgets/drug_reference_widgets.dart';

/// Main medical reference screen
class MedicalReferenceScreen extends ConsumerStatefulWidget {
  const MedicalReferenceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicalReferenceScreen> createState() =>
      _MedicalReferenceScreenState();
}

class _MedicalReferenceScreenState
    extends ConsumerState<MedicalReferenceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<DrugInfo> _selectedDrugs = [];

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

  void _removeDrug(String drugId) {
    setState(() {
      _selectedDrugs.removeWhere((drug) => drug.id == drugId);
    });
  }

  void _clearAllDrugs() {
    setState(() {
      _selectedDrugs.clear();
    });
  }

  Future<void> _showInteractionDialog() async {
    if (_selectedDrugs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 drugs to check interactions'),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => InteractionCheckerDialog(
        drugs: _selectedDrugs,
        onClose: () {
          // Refresh if needed
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Reference'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.medication_outlined),
              text: 'Drugs',
            ),
            Tab(
              icon: Icon(Icons.warning_outlined),
              text: 'Interactions',
            ),
            Tab(
              icon: Icon(Icons.info_outlined),
              text: 'Warnings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDrugsTab(),
          _buildInteractionsTab(),
          _buildWarningsTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 1: Drugs Tab
  // ============================================================================

  Widget _buildDrugsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug search widget
          DrugSearchWidget(
            onDrugSelected: (drug) {
              setState(() {
                if (!_selectedDrugs.any((d) => d.id == drug.id)) {
                  _selectedDrugs.add(drug);
                }
              });
            },
            selectedDrugs: _selectedDrugs,
            placeholder: 'Search drug name or generic name...',
            maxSelections: 10,
          ),

          // Drug details if selected
          if (_selectedDrugs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drug Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_selectedDrugs.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAllDrugs,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedDrugs.length,
              itemBuilder: (context, index) {
                final drug = _selectedDrugs[index];
                return _buildDrugCard(drug, index);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrugCard(DrugInfo drug, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    drug.genericName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeDrug(drug.id),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Drug Class', drug.drugClass),
                _buildInfoSection('Mechanism', drug.mechanism),
                _buildInfoSection('Dosage', '${drug.dosage} ${drug.frequency}'),
                const SizedBox(height: 12),
                _buildListSection('Indications', drug.indications),
                const SizedBox(height: 12),
                _buildListSection('Side Effects', drug.sideEffects),
                if (drug.contraindications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Contraindications',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...drug.contraindications.map(
                    (contra) => Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contra.condition,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contra.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ============================================================================
  // Tab 2: Interactions Tab
  // ============================================================================

  Widget _buildInteractionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outlined,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select 2 or more drugs to check for interactions',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Drug selection summary
          if (_selectedDrugs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Drugs',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedDrugs
                      .map(
                        (drug) => Chip(
                          label: Text(drug.name),
                          backgroundColor:
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                          labelStyle: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showInteractionDialog,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Check Interactions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No drugs selected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 3: Warnings Tab
  // ============================================================================

  Widget _buildWarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedDrugs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a drug to view FDA warnings',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedDrugs.length,
              itemBuilder: (context, index) {
                final drug = _selectedDrugs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 24),
                    Text(
                      drug.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    DrugWarningsPanel(
                      drugId: drug.id,
                      drugName: drug.name,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

