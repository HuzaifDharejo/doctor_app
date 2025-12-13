import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'medication_theme.dart';

/// Comprehensive medicine database with categories for quick selection
class MedicineDatabase {
  static const Map<String, List<Map<String, String>>> medicines = {
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
    'Psychiatric': [
      {'name': 'Escitalopram', 'dosage': '10mg'},
      {'name': 'Sertraline', 'dosage': '50mg'},
      {'name': 'Fluoxetine', 'dosage': '20mg'},
      {'name': 'Alprazolam', 'dosage': '0.25mg'},
      {'name': 'Clonazepam', 'dosage': '0.5mg'},
      {'name': 'Amitriptyline', 'dosage': '10mg'},
    ],
    'Thyroid': [
      {'name': 'Levothyroxine', 'dosage': '25mcg'},
      {'name': 'Levothyroxine', 'dosage': '50mcg'},
      {'name': 'Levothyroxine', 'dosage': '75mcg'},
      {'name': 'Levothyroxine', 'dosage': '100mcg'},
    ],
  };

  /// Get all category names
  static List<String> get categories => medicines.keys.toList();
  
  /// Get medicines for a specific category
  static List<Map<String, String>> getByCategory(String category) {
    return medicines[category] ?? [];
  }
  
  /// Get all medicines flattened
  static List<Map<String, String>> get all {
    final list = <Map<String, String>>[];
    for (final category in medicines.values) {
      list.addAll(category);
    }
    return list;
  }
  
  /// Search medicines by name
  static List<Map<String, String>> search(String query, {String? category}) {
    final lowerQuery = query.toLowerCase();
    
    List<Map<String, String>> source;
    if (category != null && category != 'All') {
      source = medicines[category] ?? [];
    } else {
      source = all;
    }
    
    if (query.isEmpty) return source;
    
    return source.where((med) {
      final name = (med['name'] ?? '').toLowerCase();
      final dosage = (med['dosage'] ?? '').toLowerCase();
      return name.contains(lowerQuery) || dosage.contains(lowerQuery);
    }).toList();
  }
}

/// Medicine selector grid with search and categories
class MedicineSelectorGrid extends StatefulWidget {
  const MedicineSelectorGrid({
    super.key,
    required this.onSelect,
    this.onAddCustom,
    this.showAddCustomButton = true,
    this.multiSelect = false,
    this.selectedMedicines,
    this.onMultiSelectChanged,
  });

  final void Function(String name, String dosage) onSelect;
  final VoidCallback? onAddCustom;
  final bool showAddCustomButton;
  
  /// Enable multi-selection mode
  final bool multiSelect;
  
  /// Currently selected medicines (for multi-select mode)
  final Set<String>? selectedMedicines;
  
  /// Callback when multi-selection changes
  final ValueChanged<Set<String>>? onMultiSelectChanged;

  @override
  State<MedicineSelectorGrid> createState() => _MedicineSelectorGridState();
}

class _MedicineSelectorGridState extends State<MedicineSelectorGrid> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selectedMedicines ?? {};
  }
  
  @override
  void didUpdateWidget(MedicineSelectorGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMedicines != null) {
      _localSelected = widget.selectedMedicines!;
    }
  }

  List<Map<String, String>> get _filteredMedicines {
    return MedicineDatabase.search(_searchQuery, category: _selectedCategory);
  }
  
  void _toggleSelection(String medicineName) {
    setState(() {
      if (_localSelected.contains(medicineName)) {
        _localSelected.remove(medicineName);
      } else {
        _localSelected.add(medicineName);
      }
    });
    widget.onMultiSelectChanged?.call(Set.from(_localSelected));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['All', ...MedicineDatabase.categories];

    return Column(
      children: [
        _buildSearchAndFilters(isDark, categories),
        if (widget.showAddCustomButton)
          _buildAddCustomButton(isDark),
        const SizedBox(height: 12),
        Expanded(child: _buildMedicineGrid(isDark)),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark, List<String> categories) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : MedColors.primary.withValues(alpha: 0.2),
              ),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: MedColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search, color: MedColors.primary),
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
                        gradient: isSelected ? MedColors.primaryGradient : null,
                        color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey[700]),
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
    );
  }

  Widget _buildAddCustomButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MedColors.primary.withValues(alpha: 0.15),
              MedColors.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MedColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onAddCustom,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: MedColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: MedColors.primary.withValues(alpha: 0.3),
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
                            color: MedColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter medicine details manually',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MedColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: MedColors.primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineGrid(bool isDark) {
    if (_filteredMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MedColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 40,
                color: MedColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Select a category' : 'No medicines found',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredMedicines.length,
      itemBuilder: (context, index) {
        final medicine = _filteredMedicines[index];
        final name = medicine['name'] ?? '';
        final dosage = medicine['dosage'] ?? '';
        final displayName = dosage.isNotEmpty ? '$name $dosage' : name;
        final isSelected = widget.multiSelect && _localSelected.contains(displayName);

        return _MedicineGridItem(
          displayName: displayName,
          isDark: isDark,
          isSelected: isSelected,
          showCheckbox: widget.multiSelect,
          onTap: () {
            if (widget.multiSelect) {
              _toggleSelection(displayName);
            } else {
              widget.onSelect(displayName, '1 tablet');
            }
          },
        );
      },
    );
  }
}

class _MedicineGridItem extends StatelessWidget {
  const _MedicineGridItem({
    required this.displayName,
    required this.isDark,
    required this.onTap,
    this.isSelected = false,
    this.showCheckbox = false,
  });

  final String displayName;
  final bool isDark;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? MedColors.primary.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? MedColors.primary 
                : (isDark ? Colors.white.withValues(alpha: 0.1) : MedColors.primary.withValues(alpha: 0.15)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: isSelected 
                  ? MedColors.primary.withValues(alpha: 0.15)
                  : MedColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            if (showCheckbox) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: isSelected ? MedColors.primaryGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected ? null : Border.all(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MedColors.primary.withValues(alpha: 0.15),
                      MedColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medication, color: MedColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? MedColors.primary
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!showCheckbox)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: MedColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: MedColors.success,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
