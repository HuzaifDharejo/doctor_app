import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicationTemplate {
  final String name;
  final String category;
  final String dosage;
  final String frequency;
  final String duration;
  final String route;
  final String notes;

  const MedicationTemplate({
    required this.name,
    required this.category,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.route = 'Oral',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'route': route,
    'notes': notes,
  };
}

class PrescriptionTemplates {
  // Common Pakistani medications by category
  static const List<MedicationTemplate> analgesics = [
    MedicationTemplate(
      name: 'Panadol (Paracetamol)',
      category: 'Pain Relief',
      dosage: '500mg',
      frequency: 'Every 6-8 hours as needed',
      duration: '3 days',
    ),
    MedicationTemplate(
      name: 'Brufen (Ibuprofen)',
      category: 'Pain Relief',
      dosage: '400mg',
      frequency: 'Every 8 hours with food',
      duration: '5 days',
    ),
    MedicationTemplate(
      name: 'Ponstan (Mefenamic Acid)',
      category: 'Pain Relief',
      dosage: '500mg',
      frequency: 'Every 8 hours after meals',
      duration: '3 days',
    ),
    MedicationTemplate(
      name: 'Disprin (Aspirin)',
      category: 'Pain Relief',
      dosage: '300mg',
      frequency: 'Every 4-6 hours',
      duration: '3 days',
    ),
  ];

  static const List<MedicationTemplate> antibiotics = [
    MedicationTemplate(
      name: 'Amoxil (Amoxicillin)',
      category: 'Antibiotic',
      dosage: '500mg',
      frequency: 'Every 8 hours',
      duration: '7 days',
      notes: 'Complete full course',
    ),
    MedicationTemplate(
      name: 'Augmentin (Amoxicillin-Clavulanic Acid)',
      category: 'Antibiotic',
      dosage: '625mg',
      frequency: 'Every 12 hours',
      duration: '7 days',
      notes: 'Take with food',
    ),
    MedicationTemplate(
      name: 'Ciproxin (Ciprofloxacin)',
      category: 'Antibiotic',
      dosage: '500mg',
      frequency: 'Every 12 hours',
      duration: '5 days',
      notes: 'Avoid dairy products',
    ),
    MedicationTemplate(
      name: 'Azomax (Azithromycin)',
      category: 'Antibiotic',
      dosage: '500mg',
      frequency: 'Once daily',
      duration: '3 days',
      notes: 'Take 1 hour before or 2 hours after meals',
    ),
    MedicationTemplate(
      name: 'Flagyl (Metronidazole)',
      category: 'Antibiotic',
      dosage: '400mg',
      frequency: 'Every 8 hours',
      duration: '7 days',
      notes: 'Avoid alcohol',
    ),
  ];

  static const List<MedicationTemplate> antacids = [
    MedicationTemplate(
      name: 'Omeprazole',
      category: 'Antacid',
      dosage: '20mg',
      frequency: 'Once daily before breakfast',
      duration: '14 days',
    ),
    MedicationTemplate(
      name: 'Risek (Esomeprazole)',
      category: 'Antacid',
      dosage: '40mg',
      frequency: 'Once daily',
      duration: '14 days',
    ),
    MedicationTemplate(
      name: 'Gaviscon',
      category: 'Antacid',
      dosage: '10-20ml',
      frequency: 'After meals and at bedtime',
      duration: '7 days',
    ),
  ];

  static const List<MedicationTemplate> antihistamines = [
    MedicationTemplate(
      name: 'Loratadine',
      category: 'Antihistamine',
      dosage: '10mg',
      frequency: 'Once daily',
      duration: '7 days',
    ),
    MedicationTemplate(
      name: 'Cetrizine',
      category: 'Antihistamine',
      dosage: '10mg',
      frequency: 'Once daily at bedtime',
      duration: '7 days',
      notes: 'May cause drowsiness',
    ),
    MedicationTemplate(
      name: 'Avil (Pheniramine)',
      category: 'Antihistamine',
      dosage: '25mg',
      frequency: 'Every 8 hours',
      duration: '5 days',
    ),
  ];

  static const List<MedicationTemplate> antidiabetics = [
    MedicationTemplate(
      name: 'Glucophage (Metformin)',
      category: 'Diabetes',
      dosage: '500mg',
      frequency: 'Twice daily with meals',
      duration: '30 days',
      notes: 'Take with food to reduce stomach upset',
    ),
    MedicationTemplate(
      name: 'Gliclazide',
      category: 'Diabetes',
      dosage: '80mg',
      frequency: 'Once daily with breakfast',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Glibenclamide',
      category: 'Diabetes',
      dosage: '5mg',
      frequency: 'Once daily before breakfast',
      duration: '30 days',
    ),
  ];

  static const List<MedicationTemplate> antihypertensives = [
    MedicationTemplate(
      name: 'Amlodipine',
      category: 'Hypertension',
      dosage: '5mg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Atenolol',
      category: 'Hypertension',
      dosage: '50mg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Losartan',
      category: 'Hypertension',
      dosage: '50mg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Lisinopril',
      category: 'Hypertension',
      dosage: '10mg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
  ];

  static const List<MedicationTemplate> coughMedications = [
    MedicationTemplate(
      name: 'Phensedyl',
      category: 'Cough',
      dosage: '5-10ml',
      frequency: 'Every 6-8 hours',
      duration: '5 days',
    ),
    MedicationTemplate(
      name: 'Benylin',
      category: 'Cough',
      dosage: '5ml',
      frequency: 'Every 4-6 hours',
      duration: '5 days',
    ),
    MedicationTemplate(
      name: 'Dextromethorpan',
      category: 'Cough',
      dosage: '10-20mg',
      frequency: 'Every 4 hours',
      duration: '5 days',
    ),
  ];

  static const List<MedicationTemplate> vitamins = [
    MedicationTemplate(
      name: 'Vitamin D3',
      category: 'Vitamin',
      dosage: '1000 IU',
      frequency: 'Once daily with meal',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Vitamin B12',
      category: 'Vitamin',
      dosage: '500mcg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Folic Acid',
      category: 'Vitamin',
      dosage: '5mg',
      frequency: 'Once daily',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Iron + Folic Acid',
      category: 'Vitamin',
      dosage: '1 tablet',
      frequency: 'Once daily after meal',
      duration: '30 days',
    ),
    MedicationTemplate(
      name: 'Calcium + Vitamin D',
      category: 'Vitamin',
      dosage: '1 tablet',
      frequency: 'Twice daily',
      duration: '30 days',
    ),
  ];

  static List<MedicationTemplate> getAllTemplates() {
    return [
      ...analgesics,
      ...antibiotics,
      ...antacids,
      ...antihistamines,
      ...antidiabetics,
      ...antihypertensives,
      ...coughMedications,
      ...vitamins,
    ];
  }

  static Map<String, List<MedicationTemplate>> getByCategory() {
    return {
      'Pain Relief': analgesics,
      'Antibiotics': antibiotics,
      'Antacids': antacids,
      'Antihistamines': antihistamines,
      'Diabetes': antidiabetics,
      'Hypertension': antihypertensives,
      'Cough': coughMedications,
      'Vitamins': vitamins,
    };
  }

  static List<MedicationTemplate> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return getAllTemplates().where((template) =>
      template.name.toLowerCase().contains(lowerQuery) ||
      template.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

class MedicationTemplateBottomSheet extends StatefulWidget {
  final Function(MedicationTemplate) onSelect;

  const MedicationTemplateBottomSheet({super.key, required this.onSelect});

  @override
  State<MedicationTemplateBottomSheet> createState() => _MedicationTemplateBottomSheetState();
}

class _MedicationTemplateBottomSheetState extends State<MedicationTemplateBottomSheet> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = PrescriptionTemplates.getByCategory();
    
    List<MedicationTemplate> displayTemplates;
    if (_searchQuery.isNotEmpty) {
      displayTemplates = PrescriptionTemplates.search(_searchQuery);
    } else if (_selectedCategory != null) {
      displayTemplates = categories[_selectedCategory] ?? [];
    } else {
      displayTemplates = [];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Text(
            'Medication Templates',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick add common medications',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search box
          TextField(
            onChanged: (value) => setState(() {
              _searchQuery = value;
              if (value.isNotEmpty) _selectedCategory = null;
            }),
            decoration: InputDecoration(
              hintText: 'Search medications...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkBackground : AppColors.background,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category chips
          if (_searchQuery.isEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.keys.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) => setState(() {
                    _selectedCategory = selected ? category : null;
                  }),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Templates list
          Expanded(
            child: displayTemplates.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty && _selectedCategory == null
                      ? 'Select a category or search'
                      : 'No medications found',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: displayTemplates.length,
                  itemBuilder: (context, index) {
                    final template = displayTemplates[index];
                    return _buildTemplateCard(template, isDark);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(MedicationTemplate template, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.medication, color: AppColors.primary),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${template.dosage} • ${template.frequency}'),
            Text(
              'Duration: ${template.duration}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: AppColors.primary),
          onPressed: () {
            widget.onSelect(template);
            Navigator.pop(context);
          },
        ),
        onTap: () {
          widget.onSelect(template);
          Navigator.pop(context);
        },
      ),
    );
  }
}
