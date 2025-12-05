import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/encounter_provider.dart';
import '../../theme/app_theme.dart';

/// Common ICD-10 codes for psychiatric practice
/// This provides quick access to frequently used diagnoses
class ICD10Codes {
  static const List<ICD10Code> psychiatricCodes = [
    // Mood Disorders
    ICD10Code('F32.0', 'Major depressive disorder, single episode, mild'),
    ICD10Code('F32.1', 'Major depressive disorder, single episode, moderate'),
    ICD10Code('F32.2', 'Major depressive disorder, single episode, severe'),
    ICD10Code('F33.0', 'Major depressive disorder, recurrent, mild'),
    ICD10Code('F33.1', 'Major depressive disorder, recurrent, moderate'),
    ICD10Code('F33.2', 'Major depressive disorder, recurrent, severe'),
    ICD10Code('F31.0', 'Bipolar disorder, current episode hypomanic'),
    ICD10Code('F31.1', 'Bipolar disorder, current episode manic'),
    ICD10Code('F31.3', 'Bipolar disorder, current episode depressed, mild'),
    ICD10Code('F31.4', 'Bipolar disorder, current episode depressed, moderate'),
    ICD10Code('F34.1', 'Dysthymic disorder'),
    
    // Anxiety Disorders
    ICD10Code('F41.0', 'Panic disorder'),
    ICD10Code('F41.1', 'Generalized anxiety disorder'),
    ICD10Code('F40.10', 'Social anxiety disorder'),
    ICD10Code('F40.00', 'Agoraphobia'),
    ICD10Code('F42.2', 'Obsessive-compulsive disorder, mixed'),
    ICD10Code('F43.10', 'Post-traumatic stress disorder'),
    ICD10Code('F43.0', 'Acute stress reaction'),
    ICD10Code('F43.20', 'Adjustment disorder, unspecified'),
    ICD10Code('F43.21', 'Adjustment disorder with depressed mood'),
    ICD10Code('F43.22', 'Adjustment disorder with anxiety'),
    ICD10Code('F43.23', 'Adjustment disorder with mixed anxiety and depressed mood'),
    
    // Psychotic Disorders
    ICD10Code('F20.0', 'Paranoid schizophrenia'),
    ICD10Code('F20.1', 'Disorganized schizophrenia'),
    ICD10Code('F20.9', 'Schizophrenia, unspecified'),
    ICD10Code('F25.0', 'Schizoaffective disorder, bipolar type'),
    ICD10Code('F25.1', 'Schizoaffective disorder, depressive type'),
    ICD10Code('F22', 'Delusional disorder'),
    ICD10Code('F23', 'Brief psychotic disorder'),
    
    // ADHD
    ICD10Code('F90.0', 'ADHD, predominantly inattentive type'),
    ICD10Code('F90.1', 'ADHD, predominantly hyperactive type'),
    ICD10Code('F90.2', 'ADHD, combined type'),
    ICD10Code('F90.9', 'ADHD, unspecified'),
    
    // Substance Use
    ICD10Code('F10.10', 'Alcohol use disorder, mild'),
    ICD10Code('F10.20', 'Alcohol use disorder, moderate'),
    ICD10Code('F11.10', 'Opioid use disorder, mild'),
    ICD10Code('F11.20', 'Opioid use disorder, moderate'),
    ICD10Code('F12.10', 'Cannabis use disorder, mild'),
    ICD10Code('F12.20', 'Cannabis use disorder, moderate'),
    ICD10Code('F14.10', 'Cocaine use disorder, mild'),
    ICD10Code('F14.20', 'Cocaine use disorder, moderate'),
    ICD10Code('F15.10', 'Stimulant use disorder, mild'),
    ICD10Code('F15.20', 'Stimulant use disorder, moderate'),
    
    // Personality Disorders
    ICD10Code('F60.0', 'Paranoid personality disorder'),
    ICD10Code('F60.1', 'Schizoid personality disorder'),
    ICD10Code('F60.2', 'Antisocial personality disorder'),
    ICD10Code('F60.3', 'Borderline personality disorder'),
    ICD10Code('F60.4', 'Histrionic personality disorder'),
    ICD10Code('F60.5', 'Obsessive-compulsive personality disorder'),
    ICD10Code('F60.6', 'Avoidant personality disorder'),
    ICD10Code('F60.7', 'Dependent personality disorder'),
    ICD10Code('F60.81', 'Narcissistic personality disorder'),
    
    // Eating Disorders
    ICD10Code('F50.00', 'Anorexia nervosa, unspecified'),
    ICD10Code('F50.01', 'Anorexia nervosa, restricting type'),
    ICD10Code('F50.02', 'Anorexia nervosa, binge eating/purging type'),
    ICD10Code('F50.2', 'Bulimia nervosa'),
    ICD10Code('F50.81', 'Binge eating disorder'),
    
    // Sleep Disorders
    ICD10Code('F51.01', 'Primary insomnia'),
    ICD10Code('F51.02', 'Adjustment insomnia'),
    ICD10Code('F51.11', 'Primary hypersomnia'),
    ICD10Code('G47.00', 'Insomnia, unspecified'),
    
    // Other
    ICD10Code('F45.1', 'Somatic symptom disorder'),
    ICD10Code('F44.9', 'Dissociative disorder, unspecified'),
    ICD10Code('F48.1', 'Depersonalization-derealization disorder'),
    ICD10Code('F99', 'Mental disorder, not otherwise specified'),
  ];

  static const List<ICD10Code> medicalCodes = [
    // Common Medical Conditions
    ICD10Code('I10', 'Essential hypertension'),
    ICD10Code('E11.9', 'Type 2 diabetes mellitus without complications'),
    ICD10Code('E78.5', 'Hyperlipidemia, unspecified'),
    ICD10Code('J06.9', 'Acute upper respiratory infection'),
    ICD10Code('M54.5', 'Low back pain'),
    ICD10Code('R51.9', 'Headache'),
    ICD10Code('K21.0', 'GERD with esophagitis'),
    ICD10Code('E03.9', 'Hypothyroidism, unspecified'),
    ICD10Code('G43.909', 'Migraine, unspecified'),
    ICD10Code('J45.909', 'Asthma, unspecified'),
  ];

  static List<ICD10Code> get allCodes => [...psychiatricCodes, ...medicalCodes];

  static List<ICD10Code> search(String query) {
    if (query.isEmpty) return psychiatricCodes;
    final lowerQuery = query.toLowerCase();
    return allCodes.where((code) {
      return code.code.toLowerCase().contains(lowerQuery) ||
          code.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

/// Represents an ICD-10 diagnosis code
class ICD10Code {
  final String code;
  final String description;

  const ICD10Code(this.code, this.description);
}

/// Widget for picking/searching diagnoses
class DiagnosisPicker extends ConsumerStatefulWidget {
  const DiagnosisPicker({
    super.key,
    required this.patientId,
    this.encounterId,
    this.onDiagnosisSelected,
    this.onDiagnosisAdded,
    this.selectedDiagnoses = const [],
  });

  final int patientId;
  final int? encounterId;
  final void Function(Diagnose diagnosis)? onDiagnosisSelected;
  final void Function(ICD10Code code, bool isPrimary)? onDiagnosisAdded;
  final List<Diagnose> selectedDiagnoses;

  @override
  ConsumerState<DiagnosisPicker> createState() => _DiagnosisPickerState();
}

class _DiagnosisPickerState extends ConsumerState<DiagnosisPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<ICD10Code> _searchResults = ICD10Codes.psychiatricCodes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchResults = ICD10Codes.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final existingDiagnoses = ref.watch(patientDiagnosesProvider(widget.patientId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'ICD-10 Codes'),
              Tab(text: 'Patient History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildICD10List(),
                existingDiagnoses.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (diagnoses) => _buildPatientDiagnosesList(diagnoses),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_information_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Diagnosis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Search ICD-10 codes or select from history',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search by code or description...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildICD10List() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'No matching codes found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showCustomDiagnosisDialog(),
              child: const Text('Add custom diagnosis'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final code = _searchResults[index];
        final isSelected = widget.selectedDiagnoses.any(
          (d) => d.icdCode == code.code,
        );

        return _buildICD10Tile(code, isSelected);
      },
    );
  }

  Widget _buildICD10Tile(ICD10Code code, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.success.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.success : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCodeColor(code.code).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code.code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getCodeColor(code.code),
            ),
          ),
        ),
        title: Text(
          code.description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () => _showAddDiagnosisDialog(code),
              ),
        onTap: isSelected ? null : () => _showAddDiagnosisDialog(code),
      ),
    );
  }

  Widget _buildPatientDiagnosesList(List<Diagnose> diagnoses) {
    if (diagnoses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'No diagnosis history',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This patient has no recorded diagnoses yet',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    // Group by status
    final active = diagnoses.where((d) => d.diagnosisStatus == 'active').toList();
    final resolved = diagnoses.where((d) => d.diagnosisStatus == 'resolved').toList();
    final chronic = diagnoses.where((d) => d.diagnosisStatus == 'chronic').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _buildSectionHeader('Active', AppColors.primary, active.length),
          ...active.map((d) => _buildDiagnosisTile(d)),
        ],
        if (chronic.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Chronic', AppColors.warning, chronic.length),
          ...chronic.map((d) => _buildDiagnosisTile(d)),
        ],
        if (resolved.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('History', AppColors.textSecondary, resolved.length),
          ...resolved.map((d) => _buildDiagnosisTile(d)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTile(Diagnose diagnosis) {
    final isAlreadyLinked = widget.selectedDiagnoses.any((d) => d.id == diagnosis.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAlreadyLinked ? AppColors.success.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlreadyLinked ? AppColors.success : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(diagnosis.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              _getCategoryIcon(diagnosis.category),
              size: 20,
              color: _getCategoryColor(diagnosis.category),
            ),
          ),
        ),
        title: Row(
          children: [
            if (diagnosis.isPrimary)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'P',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                diagnosis.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: diagnosis.icdCode.isNotEmpty
            ? Text(
                'ICD-10: ${diagnosis.icdCode}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: isAlreadyLinked
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () {
                  widget.onDiagnosisSelected?.call(diagnosis);
                  Navigator.of(context).pop(diagnosis);
                },
              ),
        onTap: isAlreadyLinked
            ? null
            : () {
                widget.onDiagnosisSelected?.call(diagnosis);
                Navigator.of(context).pop(diagnosis);
              },
      ),
    );
  }

  Color _getCodeColor(String code) {
    if (code.startsWith('F3')) return const Color(0xFF6366F1); // Mood
    if (code.startsWith('F4')) return const Color(0xFF14B8A6); // Anxiety
    if (code.startsWith('F2')) return const Color(0xFF8B5CF6); // Psychotic
    if (code.startsWith('F9')) return const Color(0xFFF59E0B); // ADHD
    if (code.startsWith('F1')) return const Color(0xFFEF4444); // Substance
    if (code.startsWith('F6')) return const Color(0xFFEC4899); // Personality
    if (code.startsWith('F5')) return const Color(0xFF10B981); // Eating/Sleep
    return AppColors.textSecondary;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'psychiatric':
        return AppColors.primary;
      case 'medical':
        return AppColors.success;
      case 'substance':
        return AppColors.warning;
      case 'developmental':
        return AppColors.info;
      case 'neurological':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'psychiatric':
        return Icons.psychology_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'substance':
        return Icons.local_pharmacy_rounded;
      case 'developmental':
        return Icons.child_care_rounded;
      case 'neurological':
        return Icons.emoji_objects_rounded;
      default:
        return Icons.medical_information_rounded;
    }
  }

  void _showAddDiagnosisDialog(ICD10Code code) {
    bool isPrimary = false;
    String severity = 'moderate';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Diagnosis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code.code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        code.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (v) => setDialogState(() => isPrimary = v ?? false),
                  title: const Text('Primary Diagnosis'),
                  subtitle: const Text('Mark as the main condition being treated'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Severity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'mild', label: Text('Mild')),
                    ButtonSegment(value: 'moderate', label: Text('Moderate')),
                    ButtonSegment(value: 'severe', label: Text('Severe')),
                  ],
                  selected: {severity},
                  onSelectionChanged: (selected) {
                    setDialogState(() => severity = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Additional notes about this diagnosis...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onDiagnosisAdded?.call(code, isPrimary);
                Navigator.of(context).pop();
                Navigator.of(this.context).pop({'code': code, 'isPrimary': isPrimary, 'severity': severity, 'notes': notesController.text});
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDiagnosisDialog() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Custom Diagnosis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'ICD-10 Code (optional)',
                    hintText: 'e.g., F32.1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter diagnosis description...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (v) => setDialogState(() => isPrimary = v ?? false),
                  title: const Text('Primary Diagnosis'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descController.text.isNotEmpty) {
                  final code = ICD10Code(codeController.text, descController.text);
                  widget.onDiagnosisAdded?.call(code, isPrimary);
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pop({'code': code, 'isPrimary': isPrimary});
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show diagnosis picker as a modal bottom sheet
Future<dynamic> showDiagnosisPicker({
  required BuildContext context,
  required int patientId,
  int? encounterId,
  List<Diagnose> selectedDiagnoses = const [],
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DiagnosisPicker(
          patientId: patientId,
          encounterId: encounterId,
          selectedDiagnoses: selectedDiagnoses,
        ),
      ),
    ),
  );
}
