import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../extensions/drift_extensions.dart';
import '../../services/family_history_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing patient family medical history
class FamilyHistoryScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const FamilyHistoryScreen({super.key, this.patientId});

  @override
  ConsumerState<FamilyHistoryScreen> createState() => _FamilyHistoryScreenState();
}

class _FamilyHistoryScreenState extends ConsumerState<FamilyHistoryScreen> {
  final _familyHistoryService = FamilyHistoryService();
  String _selectedRelationship = 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
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
                              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.family_restroom,
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
                                'Family History',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hereditary conditions & risk factors',
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
          ),
          if (widget.patientId != null) ...[
            SliverToBoxAdapter(
              child: _buildRiskSummaryCard(),
            ),
            SliverToBoxAdapter(
              child: _buildFilterChips(),
            ),
            _buildFamilyHistoryList(),
          ] else
            SliverFillRemaining(
              child: _buildSelectPatientState(),
            ),
        ],
      ),
      floatingActionButton: widget.patientId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFamilyHistoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
              backgroundColor: const Color(0xFFF59E0B),
            )
          : null,
    );
  }

  Widget _buildRiskSummaryCard() {
    if (widget.patientId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _familyHistoryService.getHereditaryRiskAssessment(widget.patientId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final riskData = snapshot.data!;
        final riskConditions = riskData['risk_conditions'] as List<String>? ?? [];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (riskConditions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hereditary Risk Factors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: riskConditions.map((condition) {
                  return Chip(
                    label: Text(
                      condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.red[800],
                      ),
                    ),
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relationships = ['all', 'parent', 'sibling', 'grandparent', 'uncle_aunt', 'child'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: relationships.map((relationship) {
          final isSelected = _selectedRelationship == relationship;
          final label = relationship == 'all' 
              ? 'All' 
              : relationship.replaceAll('_', '/').split(' ').map((w) => 
                  w[0].toUpperCase() + w.substring(1)).join(' ');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFFF59E0B),
              onSelected: (selected) {
                setState(() => _selectedRelationship = relationship);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFamilyHistoryList() {
    return FutureBuilder<List<FamilyHistoryData>>(
      future: _fetchFamilyHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        final entries = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildFamilyHistoryCard(entries[index]);
            },
            childCount: entries.length,
          ),
        );
      },
    );
  }

  Future<List<FamilyHistoryData>> _fetchFamilyHistory() async {
    if (widget.patientId == null) return [];
    
    if (_selectedRelationship == 'all') {
      return _familyHistoryService.getFamilyHistoryForPatient(widget.patientId!);
    }
    
    return _familyHistoryService.getFamilyHistoryByRelationship(
      widget.patientId!,
      _selectedRelationship,
    );
  }

  Widget _buildFamilyHistoryCard(FamilyHistoryData entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _familyHistoryService.toModel(entry);
    final relationshipIcon = _getRelationshipIcon(entry.relationship);
    final isDeceased = entry.isDeceased ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      relationshipIcon,
                      color: const Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.relationship.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            if (isDeceased) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Deceased',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (entry.relativeAge != null || entry.ageAtDeath != null)
                          Text(
                            isDeceased && entry.ageAtDeath != null
                                ? 'Age at death: ${entry.ageAtDeath}'
                                : 'Age: ${entry.relativeAge}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (model.isHighRisk)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[400],
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.condition,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              if (entry.ageAtOnset != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Onset at age ${entry.ageAtOnset}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.notes!,
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

  IconData _getRelationshipIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'mother':
      case 'father':
      case 'parent':
        return Icons.person;
      case 'sibling':
      case 'brother':
      case 'sister':
        return Icons.people;
      case 'grandmother':
      case 'grandfather':
      case 'grandparent':
        return Icons.elderly;
      case 'uncle':
      case 'aunt':
      case 'uncle_aunt':
        return Icons.family_restroom;
      case 'child':
      case 'son':
      case 'daughter':
        return Icons.child_care;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No family history recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add family medical history entries',
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
          const SizedBox(height: 8),
          Text(
            'Choose a patient to view family history',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(FamilyHistoryData entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _familyHistoryService.toModel(entry);

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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRelationshipIcon(entry.relationship),
                      color: const Color(0xFFF59E0B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.relationship.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          entry.condition,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (model.isHighRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'High Risk',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (entry.ageAtOnset != null)
                _buildDetailRow('Age at Onset', '${entry.ageAtOnset} years'),
              if (entry.relativeAge != null)
                _buildDetailRow('Current Age', '${entry.relativeAge} years'),
              if (entry.isDeceased == true) ...[
                _buildDetailRow('Status', 'Deceased'),
                if (entry.ageAtDeath != null)
                  _buildDetailRow('Age at Death', '${entry.ageAtDeath} years'),
                if (entry.causeOfDeath != null)
                  _buildDetailRow('Cause of Death', entry.causeOfDeath!),
              ],
              if (entry.notes != null && entry.notes!.isNotEmpty)
                _buildDetailRow('Notes', entry.notes!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(entry.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDialog(entry);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
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
            width: 120,
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this family history entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _familyHistoryService.deleteFamilyHistoryEntry(id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entry deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(FamilyHistoryData entry) {
    _showAddFamilyHistoryDialog(context, editEntry: entry);
  }

  void _showAddFamilyHistoryDialog(BuildContext context, {FamilyHistoryData? editEntry}) {
    final conditionController = TextEditingController(text: editEntry?.condition);
    final notesController = TextEditingController(text: editEntry?.notes);
    final ageOnsetController = TextEditingController(
      text: editEntry?.ageAtOnset?.toString(),
    );
    final relativeAgeController = TextEditingController(
      text: editEntry?.relativeAge?.toString(),
    );
    String selectedRelationship = editEntry?.relationship ?? 'mother';
    bool isDeceased = editEntry?.isDeceased ?? false;

    final relationships = [
      'mother', 'father', 'sibling', 'grandmother', 'grandfather',
      'uncle', 'aunt', 'child', 'other'
    ];

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
                        editEntry != null ? 'Edit Family History' : 'Add Family History',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedRelationship,
                        decoration: const InputDecoration(
                          labelText: 'Relationship *',
                          border: OutlineInputBorder(),
                        ),
                        items: relationships.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r[0].toUpperCase() + r.substring(1)),
                        )).toList(),
                        onChanged: (value) {
                          setModalState(() => selectedRelationship = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: conditionController,
                        decoration: const InputDecoration(
                          labelText: 'Condition *',
                          hintText: 'e.g., Diabetes, Heart Disease, Cancer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ageOnsetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age at Onset',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: relativeAgeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Relative\'s Age',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Deceased'),
                        value: isDeceased,
                        onChanged: (value) {
                          setModalState(() => isDeceased = value);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
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
                            if (conditionController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter condition')),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a patient first')),
                              );
                              return;
                            }

                            if (editEntry != null) {
                              await _familyHistoryService.updateFamilyHistoryEntry(
                                id: editEntry.id,
                                condition: conditionController.text,
                                relationship: selectedRelationship,
                                ageAtOnset: int.tryParse(ageOnsetController.text),
                                relativeAge: int.tryParse(relativeAgeController.text),
                                isDeceased: isDeceased,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            } else {
                              await _familyHistoryService.addFamilyHistoryEntry(
                                patientId: widget.patientId!,
                                condition: conditionController.text,
                                relationship: selectedRelationship,
                                ageAtOnset: int.tryParse(ageOnsetController.text),
                                relativeAge: int.tryParse(relativeAgeController.text),
                                isDeceased: isDeceased,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(editEntry != null 
                                      ? 'Entry updated successfully' 
                                      : 'Entry added successfully'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(editEntry != null ? 'Update Entry' : 'Add Entry'),
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
