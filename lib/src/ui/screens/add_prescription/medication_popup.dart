import 'package:flutter/material.dart';
import '../../../services/suggestions_service.dart';
import '../../../services/prescription_templates.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// Data model for a medication entry
class MedicationData {
  String name;
  String dosage;
  String frequency;
  String duration;
  String timing;
  String instructions;

  MedicationData({
    this.name = '',
    this.dosage = '',
    this.frequency = 'OD',
    this.duration = '',
    this.timing = 'After Food',
    this.instructions = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'timing': timing,
    'instructions': instructions,
  };

  factory MedicationData.fromJson(Map<String, dynamic> json) => MedicationData(
    name: (json['name'] as String?) ?? '',
    dosage: (json['dosage'] as String?) ?? '',
    frequency: (json['frequency'] as String?) ?? 'OD',
    duration: (json['duration'] as String?) ?? '',
    timing: (json['timing'] as String?) ?? 'After Food',
    instructions: (json['instructions'] as String?) ?? '',
  );

  MedicationData copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? timing,
    String? instructions,
  }) => MedicationData(
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    frequency: frequency ?? this.frequency,
    duration: duration ?? this.duration,
    timing: timing ?? this.timing,
    instructions: instructions ?? this.instructions,
  );

  bool get isValid => name.isNotEmpty;
}

/// Full-screen medication management popup
class MedicationManagerPopup extends StatefulWidget {
  const MedicationManagerPopup({
    super.key,
    required this.medications,
    required this.onSave,
    this.patientAllergies = '',
  });

  final List<MedicationData> medications;
  final void Function(List<MedicationData>) onSave;
  final String patientAllergies;

  @override
  State<MedicationManagerPopup> createState() => _MedicationManagerPopupState();
}

class _MedicationManagerPopupState extends State<MedicationManagerPopup> with SingleTickerProviderStateMixin {
  late List<MedicationData> _medications;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _medications = widget.medications.map((m) => MedicationData(
      name: m.name,
      dosage: m.dosage,
      frequency: m.frequency,
      duration: m.duration,
      timing: m.timing,
      instructions: m.instructions,
    )).toList();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addMedication(MedicationData med) {
    setState(() {
      _medications.add(med);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} added'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeMedication(int index) {
    if (index < 0 || index >= _medications.length) return;
    final name = _medications[index].name;
    setState(() {
      _medications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name removed'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Could implement undo but keeping it simple
          },
        ),
      ),
    );
  }

  void _editMedication(int index) {
    if (index < 0 || index >= _medications.length) return;
    _showEditMedicationDialog(_medications[index], index);
  }

  void _showEditMedicationDialog(MedicationData med, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditMedicationSheet(
        medication: med,
        onSave: (updated) {
          setState(() {
            _medications[index] = updated;
          });
        },
      ),
    );
  }

  void _showAddCustomDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditMedicationSheet(
        medication: MedicationData(),
        onSave: (med) {
          if (med.isValid) {
            _addMedication(med);
          }
        },
        isNew: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Medications'),
        actions: [
          TextButton.icon(
            onPressed: () {
              widget.onSave(_medications);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 20),
            label: Text(
              'Done (${_medications.where((m) => m.isValid).length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Current'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Medications Tab
          _buildCurrentMedicationsTab(isDark, colorScheme),
          // Add New Tab
          _buildAddNewTab(isDark, colorScheme),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton.extended(
        onPressed: _showAddCustomDialog,
        icon: const Icon(Icons.add),
        label: const Text('Custom'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  Widget _buildCurrentMedicationsTab(bool isDark, ColorScheme colorScheme) {
    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No medications added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add New" tab or the + button',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _medications.removeAt(oldIndex);
          _medications.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final med = _medications[index];
        return _MedicationCard(
          key: ValueKey('med_$index'),
          medication: med,
          index: index,
          onEdit: () => _editMedication(index),
          onRemove: () => _removeMedication(index),
          isDark: isDark,
          colorScheme: colorScheme,
        );
      },
    );
  }

  Widget _buildAddNewTab(bool isDark, ColorScheme colorScheme) {
    return _MedicineSelector(
      onSelect: (name, dosage) {
        _addMedication(MedicationData(
          name: name,
          dosage: dosage.isNotEmpty ? dosage : '1 tablet',
          frequency: 'OD',
          duration: '7 days',
          timing: 'After Food',
        ));
        _tabController.animateTo(0); // Switch to current tab
      },
      onAddCustom: _showAddCustomDialog,
      isDark: isDark,
      colorScheme: colorScheme,
    );
  }
}

/// Card widget for displaying a medication entry
class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    super.key,
    required this.medication,
    required this.index,
    required this.onEdit,
    required this.onRemove,
    required this.isDark,
    required this.colorScheme,
  });

  final MedicationData medication;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
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
                          medication.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (medication.dosage.isNotEmpty)
                          Text(
                            medication.dosage,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tags row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(medication.frequency, const Color(0xFF6366F1)),
                  _buildTag(medication.timing, const Color(0xFF10B981)),
                  if (medication.duration.isNotEmpty)
                    _buildTag(medication.duration, const Color(0xFF8B5CF6)),
                ],
              ),
              if (medication.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  medication.instructions,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Medicine selector grid/list
class _MedicineSelector extends StatefulWidget {
  const _MedicineSelector({
    required this.onSelect,
    required this.onAddCustom,
    required this.isDark,
    required this.colorScheme,
  });

  final void Function(String name, String dosage) onSelect;
  final VoidCallback onAddCustom;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  State<_MedicineSelector> createState() => _MedicineSelectorState();
}

class _MedicineSelectorState extends State<_MedicineSelector> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const Map<String, List<Map<String, String>>> _medicineDatabase = {
    'Pain Relief': [
      {'name': 'Paracetamol', 'dosage': '500mg'},
      {'name': 'Paracetamol', 'dosage': '650mg'},
      {'name': 'Ibuprofen', 'dosage': '400mg'},
      {'name': 'Diclofenac', 'dosage': '50mg'},
      {'name': 'Tramadol', 'dosage': '50mg'},
      {'name': 'Aspirin', 'dosage': '75mg'},
      {'name': 'Naproxen', 'dosage': '500mg'},
      {'name': 'Aceclofenac', 'dosage': '100mg'},
    ],
    'Antibiotics': [
      {'name': 'Amoxicillin', 'dosage': '500mg'},
      {'name': 'Azithromycin', 'dosage': '500mg'},
      {'name': 'Ciprofloxacin', 'dosage': '500mg'},
      {'name': 'Cefixime', 'dosage': '200mg'},
      {'name': 'Metronidazole', 'dosage': '400mg'},
      {'name': 'Levofloxacin', 'dosage': '500mg'},
      {'name': 'Doxycycline', 'dosage': '100mg'},
      {'name': 'Augmentin', 'dosage': '625mg'},
      {'name': 'Cefuroxime', 'dosage': '500mg'},
      {'name': 'Clarithromycin', 'dosage': '500mg'},
    ],
    'Antacids & GI': [
      {'name': 'Omeprazole', 'dosage': '20mg'},
      {'name': 'Pantoprazole', 'dosage': '40mg'},
      {'name': 'Ranitidine', 'dosage': '150mg'},
      {'name': 'Domperidone', 'dosage': '10mg'},
      {'name': 'Ondansetron', 'dosage': '4mg'},
      {'name': 'Sucralfate', 'dosage': '1g'},
      {'name': 'Esomeprazole', 'dosage': '40mg'},
      {'name': 'Rabeprazole', 'dosage': '20mg'},
    ],
    'Antihistamines': [
      {'name': 'Cetirizine', 'dosage': '10mg'},
      {'name': 'Loratadine', 'dosage': '10mg'},
      {'name': 'Fexofenadine', 'dosage': '120mg'},
      {'name': 'Chlorpheniramine', 'dosage': '4mg'},
      {'name': 'Montelukast', 'dosage': '10mg'},
      {'name': 'Levocetirizine', 'dosage': '5mg'},
    ],
    'Diabetes': [
      {'name': 'Metformin', 'dosage': '500mg'},
      {'name': 'Metformin', 'dosage': '1000mg'},
      {'name': 'Glimepiride', 'dosage': '1mg'},
      {'name': 'Glimepiride', 'dosage': '2mg'},
      {'name': 'Sitagliptin', 'dosage': '100mg'},
      {'name': 'Empagliflozin', 'dosage': '10mg'},
      {'name': 'Vildagliptin', 'dosage': '50mg'},
      {'name': 'Gliclazide', 'dosage': '80mg'},
    ],
    'Cardiovascular': [
      {'name': 'Amlodipine', 'dosage': '5mg'},
      {'name': 'Amlodipine', 'dosage': '10mg'},
      {'name': 'Losartan', 'dosage': '50mg'},
      {'name': 'Telmisartan', 'dosage': '40mg'},
      {'name': 'Atorvastatin', 'dosage': '10mg'},
      {'name': 'Atorvastatin', 'dosage': '20mg'},
      {'name': 'Clopidogrel', 'dosage': '75mg'},
      {'name': 'Metoprolol', 'dosage': '25mg'},
      {'name': 'Ramipril', 'dosage': '5mg'},
      {'name': 'Rosuvastatin', 'dosage': '10mg'},
    ],
    'Vitamins & Supplements': [
      {'name': 'Vitamin D3', 'dosage': '60000IU'},
      {'name': 'Vitamin B12', 'dosage': '1500mcg'},
      {'name': 'Vitamin C', 'dosage': '500mg'},
      {'name': 'Calcium + D3', 'dosage': '500mg'},
      {'name': 'Iron + Folic Acid', 'dosage': ''},
      {'name': 'Multivitamin', 'dosage': ''},
      {'name': 'Zinc', 'dosage': '50mg'},
      {'name': 'B-Complex', 'dosage': ''},
    ],
    'Respiratory': [
      {'name': 'Salbutamol', 'dosage': '4mg'},
      {'name': 'Salbutamol Inhaler', 'dosage': '100mcg'},
      {'name': 'Budesonide Inhaler', 'dosage': '200mcg'},
      {'name': 'Montelukast', 'dosage': '10mg'},
      {'name': 'Theophylline', 'dosage': '300mg'},
      {'name': 'Ambroxol', 'dosage': '30mg'},
      {'name': 'Dextromethorphan', 'dosage': '10mg'},
    ],
    'Steroids': [
      {'name': 'Prednisolone', 'dosage': '5mg'},
      {'name': 'Prednisolone', 'dosage': '10mg'},
      {'name': 'Methylprednisolone', 'dosage': '4mg'},
      {'name': 'Dexamethasone', 'dosage': '0.5mg'},
      {'name': 'Hydrocortisone', 'dosage': '10mg'},
    ],
    'Muscle Relaxants': [
      {'name': 'Thiocolchicoside', 'dosage': '4mg'},
      {'name': 'Tizanidine', 'dosage': '2mg'},
      {'name': 'Cyclobenzaprine', 'dosage': '5mg'},
      {'name': 'Chlorzoxazone', 'dosage': '500mg'},
    ],
  };

  List<Map<String, String>> get _filteredMedicines {
    List<Map<String, String>> medicines = [];

    if (_selectedCategory == 'All') {
      for (final category in _medicineDatabase.values) {
        medicines.addAll(category);
      }
    } else {
      medicines = _medicineDatabase[_selectedCategory] ?? [];
    }

    if (_searchQuery.isEmpty) {
      return medicines;
    }

    final query = _searchQuery.toLowerCase();
    return medicines.where((med) {
      final name = med['name']?.toLowerCase() ?? '';
      final dosage = med['dosage']?.toLowerCase() ?? '';
      return name.contains(query) || dosage.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._medicineDatabase.keys];

    return Column(
      children: [
        // Search and filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Category chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                        selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFFF59E0B),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? const Color(0xFFF59E0B)
                              : (widget.isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Add Custom button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: widget.onAddCustom,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note, color: widget.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add Custom Medicine',
                    style: TextStyle(
                      color: widget.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Medicine grid
        Expanded(
          child: _filteredMedicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty ? 'Select a category' : 'No medicines found',
                        style: TextStyle(
                          color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filteredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = _filteredMedicines[index];
                    final name = medicine['name'] ?? '';
                    final dosage = medicine['dosage'] ?? '';
                    final displayName = dosage.isNotEmpty ? '$name $dosage' : name;

                    return InkWell(
                      onTap: () => widget.onSelect(displayName, '1 tablet'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.medication, color: Color(0xFFF59E0B), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark ? Colors.white : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.add_circle_outline,
                              color: const Color(0xFF10B981),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Bottom sheet for editing a medication
class _EditMedicationSheet extends StatefulWidget {
  const _EditMedicationSheet({
    required this.medication,
    required this.onSave,
    this.isNew = false,
  });

  final MedicationData medication;
  final void Function(MedicationData) onSave;
  final bool isNew;

  @override
  State<_EditMedicationSheet> createState() => _EditMedicationSheetState();
}

class _EditMedicationSheetState extends State<_EditMedicationSheet> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _durationController;
  late TextEditingController _instructionsController;
  late String _frequency;
  late String _timing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication.name);
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _durationController = TextEditingController(text: widget.medication.duration);
    _instructionsController = TextEditingController(text: widget.medication.instructions);
    _frequency = widget.medication.frequency;
    _timing = widget.medication.timing;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine name is required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSave(MedicationData(
      name: _nameController.text,
      dosage: _dosageController.text,
      frequency: _frequency,
      duration: _durationController.text,
      timing: _timing,
      instructions: _instructionsController.text,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isNew ? 'Add Medicine' : 'Edit Medicine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Medicine name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name *',
                hintText: 'e.g., Paracetamol 500mg',
                prefixIcon: const Icon(Icons.medication),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            // Dosage and Frequency row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      hintText: '1 tablet',
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    items: ['OD', 'BD', 'TDS', 'QID', 'SOS', 'HS', 'AC', 'PC', 'Q4H', 'Q6H', 'Q8H', 'STAT']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Duration
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration',
                hintText: '7 days',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            // Duration quick picks
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['3 days', '5 days', '7 days', '10 days', '14 days', '1 month'].map((d) =>
                InkWell(
                  onTap: () => setState(() => _durationController.text = d),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(d, style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            // Timing
            Text(
              'Timing',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Before Food', 'After Food', 'With Food', 'Empty Stomach', 'At Bedtime'].map((t) {
                final isSelected = _timing == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _timing = t);
                  },
                  selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF10B981),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Instructions
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                labelText: 'Special Instructions',
                hintText: 'e.g., Take with warm water',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(widget.isNew ? Icons.add : Icons.save),
                label: Text(widget.isNew ? 'Add Medicine' : 'Save Changes'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
