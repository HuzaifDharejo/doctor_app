import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/persistent_allergy_warning_banner.dart';
import 'components/medication_models.dart';
import 'components/medication_theme.dart';

// Re-export MedicationData for backward compatibility
export 'components/medication_models.dart' show MedicationData;

// Use MedColors from medication_theme.dart, keep _MedColors as internal alias
typedef _MedColors = MedColors;

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [_MedColors.primary.withValues(alpha: 0.1), _MedColors.secondary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.close, size: 20, color: isDark ? Colors.white : Colors.grey[700]),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_MedColors.primary, _MedColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medication_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Medications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () {
                widget.onSave(_medications);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _MedColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_medications.where((m) => m.isValid).length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _MedColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [_MedColors.primary, _MedColors.secondary],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, size: 16),
                      SizedBox(width: 6),
                      Flexible(child: Text('Current', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 16),
                      SizedBox(width: 6),
                      Flexible(child: Text('Add', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      floatingActionButton: _tabController.index == 0 ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_MedColors.primary, _MedColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _MedColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAddCustomDialog,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Custom',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildCurrentMedicationsTab(bool isDark, ColorScheme colorScheme) {
    if (_medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _MedColors.primary.withValues(alpha: 0.1),
                    _MedColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 48,
                color: _MedColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No medications added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
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
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _MedColors.primary,
                side: const BorderSide(color: _MedColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Allergy warning banner at top (if allergies exist)
        if (widget.patientAllergies.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: PersistentAllergyWarningBanner(
              allergies: widget.patientAllergies,
              compact: true,
            ),
          ),
        ],
        // Medications list
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.all(context.responsivePadding),
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
          ),
        ),
      ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : _MedColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: _MedColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _MedColors.primary.withValues(alpha: 0.15),
                          _MedColors.secondary.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _MedColors.primary,
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
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 20,
                      ),
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
                  _buildTag(medication.frequency, _MedColors.accent),
                  _buildTag(medication.timing, _MedColors.success),
                  if (medication.duration.isNotEmpty)
                    _buildTag(medication.duration, _MedColors.secondary),
                ],
              ),
              if (medication.instructions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _MedColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: _MedColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medication.instructions,
                          style: TextStyle(
                            fontSize: 12,
                            color: _MedColors.info,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: _MedColors.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : _MedColors.primary.withValues(alpha: 0.2),
                  ),
                  boxShadow: widget.isDark ? null : [
                    BoxShadow(
                      color: _MedColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: Icon(Icons.search, color: _MedColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Category chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = category),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected 
                                ? const LinearGradient(colors: [_MedColors.primary, _MedColors.secondary])
                                : null,
                            color: isSelected ? null : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (widget.isDark ? Colors.white70 : Colors.grey[700]),
                            ),
                          ),
                        ),
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
          padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _MedColors.primary.withValues(alpha: 0.15),
                  _MedColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _MedColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onAddCustom,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(context.responsivePadding),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_MedColors.primary, _MedColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _MedColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Custom Medicine',
                              style: TextStyle(
                                color: _MedColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter medicine details manually',
                              style: TextStyle(
                                color: widget.isDark ? Colors.white54 : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _MedColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: _MedColors.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Medicine grid
        Expanded(
          child: _filteredMedicines.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.responsivePadding),
                      decoration: BoxDecoration(
                        color: _MedColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        size: 40,
                        color: _MedColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ? 'Select a category' : 'No medicines found',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    padding: EdgeInsets.all(context.responsivePadding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.responsive(
                        compact: 2,
                        medium: 3,
                        expanded: 4,
                      ),
                      childAspectRatio: context.responsive(
                        compact: 2.1,
                        medium: 2.3,
                        expanded: 2.5,
                      ),
                      crossAxisSpacing: context.responsiveItemSpacing,
                      mainAxisSpacing: context.responsiveItemSpacing,
                    ),
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      final name = medicine['name'] ?? '';
                      final dosage = medicine['dosage'] ?? '';
                      final displayName = dosage.isNotEmpty ? '$name $dosage' : name;

                      return InkWell(
                        onTap: () => widget.onSelect(displayName, '1 tablet'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : _MedColors.primary.withValues(alpha: 0.15),
                            ),
                            boxShadow: widget.isDark ? null : [
                              BoxShadow(
                                color: _MedColors.primary.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _MedColors.primary.withValues(alpha: 0.15),
                                      _MedColors.secondary.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.medication, color: _MedColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10),
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
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _MedColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: _MedColors.success,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsivePadding),
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
                  color: isDark ? AppColors.darkDivider : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_MedColors.primary, _MedColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isNew ? 'Add Medicine' : 'Edit Medicine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.isNew ? 'Enter medication details' : 'Modify medication details',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close, size: 18, color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Medicine name
            _buildInputLabel('Medicine Name', isRequired: true),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: _buildInputDecoration(
                hintText: 'e.g., Paracetamol 500mg',
                prefixIcon: Icons.medication,
                isDark: isDark,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            // Dosage and Frequency row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Dosage'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dosageController,
                        decoration: _buildInputDecoration(
                          hintText: '1 tablet',
                          prefixIcon: Icons.straighten,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Frequency'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: _buildInputDecoration(
                          isDark: isDark,
                        ),
                        items: ['OD', 'BD', 'TDS', 'QID', 'SOS', 'HS', 'AC', 'PC', 'Q4H', 'Q6H', 'Q8H', 'STAT']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (v) => setState(() => _frequency = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Duration
            _buildInputLabel('Duration'),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              decoration: _buildInputDecoration(
                hintText: '7 days',
                prefixIcon: Icons.calendar_today,
                isDark: isDark,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _durationController.text == d 
                          ? _MedColors.primary.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(20),
                      border: _durationController.text == d 
                          ? Border.all(color: _MedColors.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Text(
                      d, 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w500,
                        color: _durationController.text == d 
                            ? _MedColors.primary 
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 20),
            // Timing
            _buildInputLabel('Timing'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Before Food', 'After Food', 'With Food', 'Empty Stomach', 'At Bedtime'].map((t) {
                final isSelected = _timing == t;
                return InkWell(
                  onTap: () => setState(() => _timing = t),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                          ? const LinearGradient(colors: [_MedColors.success, Color(0xFF059669)])
                          : null,
                      color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected 
                                ? Colors.white 
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Instructions
            _buildInputLabel('Special Instructions'),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              decoration: _buildInputDecoration(
                hintText: 'e.g., Take with warm water',
                prefixIcon: Icons.notes,
                isDark: isDark,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(widget.isNew ? Icons.add : Icons.save, size: 20),
                label: Text(
                  widget.isNew ? 'Add Medicine' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _MedColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _MedColors.primary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
  
  InputDecoration _buildInputDecoration({
    String? hintText,
    IconData? prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: _MedColors.primary, size: 20) 
          : null,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : _MedColors.primary.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MedColors.primary.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : _MedColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _MedColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
