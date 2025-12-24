/// Lab Order Sheet Components
/// 
/// Bottom sheet widgets for creating lab orders and entering results.

import 'package:flutter/material.dart';
import 'lab_models.dart';
import 'lab_theme.dart';
import 'lab_selectors.dart';
import 'lab_database.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Show create lab order sheet
Future<LabTestData?> showCreateLabOrderSheet(
  BuildContext context, {
  int? patientId,
}) async {
  return showModalBottomSheet<LabTestData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CreateLabOrderSheet(patientId: patientId),
  );
}

/// Show enter results sheet
Future<Map<String, dynamic>?> showEnterResultsSheet(
  BuildContext context, {
  required LabTestData order,
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EnterResultsSheet(order: order),
  );
}

/// Bottom sheet for creating a new lab order
class CreateLabOrderSheet extends StatefulWidget {
  const CreateLabOrderSheet({
    super.key,
    this.patientId,
    this.initialTestName,
    this.onSave,
  });

  final int? patientId;
  final String? initialTestName;
  final ValueChanged<LabTestData>? onSave;

  @override
  State<CreateLabOrderSheet> createState() => _CreateLabOrderSheetState();
}

class _CreateLabOrderSheetState extends State<CreateLabOrderSheet> {
  final _testNameController = TextEditingController();
  final _testCodeController = TextEditingController();
  final _labController = TextEditingController();
  final _indicationController = TextEditingController();
  final _notesController = TextEditingController();

  LabPriority _selectedPriority = LabPriority.routine;
  LabSpecimenType _selectedSpecimen = LabSpecimenType.blood;
  String _selectedCategory = 'Quick Panels';
  bool _showPanels = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTestName != null) {
      _testNameController.text = widget.initialTestName!;
    }
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testCodeController.dispose();
    _labController.dispose();
    _indicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['Quick Panels', ...LabTestDatabase.categoryNames];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: LabContainerStyle.bottomSheet(isDark: isDark),
        padding: EdgeInsets.all(context.responsivePadding),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
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
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Quick Fill Templates Section
              _buildTemplatesSection(categories, isDark),
              const SizedBox(height: 24),

              // Form Fields
              _buildFormFields(isDark),
              const SizedBox(height: 24),

              // Create Button
              LabGradientButton(
                onPressed: _handleSave,
                label: 'Create Order',
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: LabContainerStyle.iconContainer(gradient: false),
          child: const Icon(
            Icons.science_rounded,
            color: LabColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Lab Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                ),
              ),
              Text(
                'Select a test or enter details',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesSection(List<String> categories, bool isDark) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: LabContainerStyle.section(isDark: isDark, color: LabColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: LabColors.primary),
              const SizedBox(width: 8),
              Text(
                'Quick Fill Templates',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View toggle
          LabViewToggle(
            showPanels: _showPanels,
            onToggle: (value) => setState(() {
              _showPanels = value;
              if (value) _selectedCategory = 'Quick Panels';
            }),
          ),
          const SizedBox(height: 14),

          // Category selector (for individual tests)
          if (!_showPanels) ...[
            LabCategorySelector(
              selected: _selectedCategory == 'Quick Panels' ? null : _selectedCategory,
              onChanged: (cat) => setState(() {
                _selectedCategory = cat ?? 'Quick Panels';
              }),
              categories: categories.where((c) => c != 'Quick Panels').toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Templates
          if (_showPanels)
            _buildQuickPanels(isDark)
          else
            _buildCategoryTests(isDark),
        ],
      ),
    );
  }

  Widget _buildQuickPanels(bool isDark) {
    final panels = LabTestDatabase.quickPanels;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: panels.map((panel) {
        return ActionChip(
          avatar: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: LabColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPanelIcon(panel.name),
              size: 14,
              color: LabColors.primary,
            ),
          ),
          label: Text(
            panel.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? LabColors.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () => _showPanelDetails(panel),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryTests(bool isDark) {
    final tests = LabTestDatabase.getByCategory(_selectedCategory);
    if (tests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Text(
            'Select a category to see tests',
            style: TextStyle(
              color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tests.map((test) {
        return ActionChip(
          label: Text(
            test.name.length > 25 ? '${test.name.substring(0, 22)}...' : test.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
            ),
          ),
          backgroundColor: isDark ? LabColors.darkBackground : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () {
            setState(() {
              _testNameController.text = test.name;
              _testCodeController.text = test.testCode ?? '';
              _selectedSpecimen = LabSpecimenType.fromValue(test.specimenType);
              _indicationController.text = test.clinicalIndication ?? '';
              _selectedPriority = LabPriority.fromValue(test.urgency);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildFormFields(bool isDark) {
    return Column(
      children: [
        // Test Name
        _FormField(
          controller: _testNameController,
          label: 'Test Name *',
          hint: 'Enter test name',
          icon: Icons.biotech_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Test Code and Specimen Row
        Row(
          children: [
            Expanded(
              child: _FormField(
                controller: _testCodeController,
                label: 'Test Code',
                hint: 'Optional',
                icon: Icons.qr_code_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                value: _selectedSpecimen.value,
                label: 'Specimen',
                icon: Icons.water_drop_rounded,
                items: LabSpecimenType.allValues,
                onChanged: (value) => setState(() {
                  _selectedSpecimen = LabSpecimenType.fromValue(value!);
                }),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Urgency and Lab Row
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                value: _selectedPriority.value,
                label: 'Urgency',
                icon: Icons.priority_high_rounded,
                items: LabPriority.values.map((p) => p.value).toList(),
                onChanged: (value) => setState(() {
                  _selectedPriority = LabPriority.fromValue(value!);
                }),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormField(
                controller: _labController,
                label: 'Laboratory',
                hint: 'Optional',
                icon: Icons.business_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Clinical Indication
        _FormField(
          controller: _indicationController,
          label: 'Clinical Indication',
          hint: 'Reason for ordering',
          icon: Icons.medical_information_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Notes
        _FormField(
          controller: _notesController,
          label: 'Notes',
          hint: 'Additional instructions',
          icon: Icons.note_rounded,
          isDark: isDark,
          maxLines: 2,
        ),
      ],
    );
  }

  void _showPanelDetails(LabTestPanel panel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? LabColors.darkSurface : Colors.white,
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: LabContainerStyle.iconContainer(),
                    child: Icon(
                      _getPanelIcon(panel.name),
                      color: LabColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      panel.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: LabContainerStyle.section(isDark: isDark),
                child: Text(
                  panel.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tests Header
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, size: 18, color: LabColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tests in this panel (${panel.testCount})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tests List
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: panel.tests.map((test) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded, 
                              size: 16, 
                              color: LabColors.completed,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                test.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LabGradientButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, panel); // Return panel
                      },
                      label: 'Order All (${panel.testCount})',
                      icon: Icons.add_rounded,
                      expanded: true,
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

  void _handleSave() {
    if (_testNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter test name'),
            ],
          ),
          backgroundColor: LabColors.cancelled,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final order = LabTestData(
      name: _testNameController.text,
      testCode: _testCodeController.text.isNotEmpty ? _testCodeController.text : null,
      specimenType: _selectedSpecimen,
      priority: _selectedPriority,
      labName: _labController.text.isNotEmpty ? _labController.text : null,
      clinicalIndication: _indicationController.text.isNotEmpty 
          ? _indicationController.text 
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      orderDate: DateTime.now(),
      status: LabOrderStatus.ordered,
    );

    if (widget.onSave != null) {
      widget.onSave!(order);
    }
    Navigator.pop(context, order);
  }

  IconData _getPanelIcon(String panelName) {
    final lower = panelName.toLowerCase();
    if (lower.contains('diabetic')) return Icons.monitor_heart;
    if (lower.contains('cardiac')) return Icons.favorite;
    if (lower.contains('thyroid')) return Icons.biotech;
    if (lower.contains('anemia')) return Icons.bloodtype;
    if (lower.contains('liver')) return Icons.medical_services;
    if (lower.contains('operative') || lower.contains('surgery')) return Icons.local_hospital;
    if (lower.contains('pregnancy')) return Icons.pregnant_woman;
    if (lower.contains('fever')) return Icons.thermostat;
    if (lower.contains('arthritis')) return Icons.accessibility_new;
    if (lower.contains('routine') || lower.contains('checkup')) return Icons.health_and_safety;
    return Icons.science;
  }
}

/// Bottom sheet for entering lab results
class EnterResultsSheet extends StatefulWidget {
  const EnterResultsSheet({
    super.key,
    required this.order,
    this.onSave,
  });

  final LabTestData order;
  final ValueChanged<Map<String, dynamic>>? onSave;

  @override
  State<EnterResultsSheet> createState() => _EnterResultsSheetState();
}

class _EnterResultsSheetState extends State<EnterResultsSheet> {
  final _resultController = TextEditingController();
  bool _isAbnormal = false;

  @override
  void dispose() {
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: LabContainerStyle.bottomSheet(isDark: isDark),
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: LabContainerStyle.iconContainer(),
                  child: const Icon(
                    Icons.add_chart_rounded,
                    color: LabColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.order.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Result Input
            Container(
              decoration: LabContainerStyle.formField(isDark: isDark),
              child: TextField(
                controller: _resultController,
                maxLines: 5,
                style: TextStyle(
                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                ),
                decoration: LabInputDecoration.build(
                  label: 'Result Summary *',
                  hint: 'Enter the lab results...',
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Abnormal Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isAbnormal 
                    ? LabColors.abnormal.withValues(alpha: 0.1)
                    : LabContainerStyle.formField(isDark: isDark).color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isAbnormal 
                      ? LabColors.abnormal.withValues(alpha: 0.3)
                      : (isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  'Abnormal Results',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isAbnormal 
                        ? LabColors.abnormal
                        : (isDark ? LabColors.darkTextPrimary : LabColors.textPrimary),
                  ),
                ),
                subtitle: Text(
                  'Mark if results are outside normal range',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                  ),
                ),
                value: _isAbnormal,
                onChanged: (value) => setState(() => _isAbnormal = value),
                activeColor: LabColors.abnormal,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            LabGradientButton(
              onPressed: _handleSave,
              label: 'Save Results',
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_resultController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter results'),
            ],
          ),
          backgroundColor: LabColors.cancelled,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final result = {
      'result': _resultController.text,
      'isAbnormal': _isAbnormal,
      'resultDate': DateTime.now().toIso8601String(),
    };

    if (widget.onSave != null) {
      widget.onSave!(result);
    }
    Navigator.pop(context, result);
  }
}

// ===================== Private form widgets =====================

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LabContainerStyle.formField(isDark: isDark),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
        ),
        decoration: LabInputDecoration.build(
          label: label,
          hint: hint,
          prefixIcon: icon,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  final String value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LabContainerStyle.formField(isDark: isDark),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDark ? LabColors.darkSurface : Colors.white,
        style: TextStyle(
          color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: LabColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items.map((s) => 
          DropdownMenuItem(
            value: s, 
            child: Text(
              s[0].toUpperCase() + s.substring(1),
              style: TextStyle(
                color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
              ),
            ),
          ),
        ).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
