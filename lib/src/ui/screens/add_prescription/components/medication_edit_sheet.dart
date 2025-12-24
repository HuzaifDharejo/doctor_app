import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'medication_models.dart';
import 'medication_selectors.dart';
import 'medication_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Bottom sheet for editing medication details
class EditMedicationSheet extends StatefulWidget {
  const EditMedicationSheet({
    super.key,
    required this.medication,
    required this.onSave,
    this.isNew = false,
  });

  final MedicationData medication;
  final void Function(MedicationData) onSave;
  final bool isNew;

  @override
  State<EditMedicationSheet> createState() => _EditMedicationSheetState();
}

class _EditMedicationSheetState extends State<EditMedicationSheet> {
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
            _buildDragHandle(isDark),
            const SizedBox(height: 20),
            _buildHeader(isDark),
            const SizedBox(height: 28),
            _buildNameField(isDark),
            const SizedBox(height: 20),
            _buildDosageAndFrequencyRow(isDark),
            const SizedBox(height: 20),
            _buildDurationField(isDark),
            const SizedBox(height: 12),
            DurationQuickPicks(
              currentValue: _durationController.text,
              onSelected: (value) => setState(() => _durationController.text = value),
            ),
            const SizedBox(height: 20),
            const MedicationInputLabel(label: 'Timing'),
            const SizedBox(height: 10),
            TimingSelector(
              selectedValue: _timing,
              onChanged: (value) => setState(() => _timing = value),
            ),
            const SizedBox(height: 20),
            _buildInstructionsField(isDark),
            const SizedBox(height: 28),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkDivider : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: MedColors.primaryGradient,
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
    );
  }

  Widget _buildNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MedicationInputLabel(label: 'Medicine Name', isRequired: true),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: MedicationInputDecoration.build(
            hintText: 'e.g., Paracetamol 500mg',
            prefixIcon: Icons.medication,
            isDark: isDark,
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildDosageAndFrequencyRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicationInputLabel(label: 'Dosage'),
              const SizedBox(height: 8),
              TextField(
                controller: _dosageController,
                decoration: MedicationInputDecoration.build(
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
              const MedicationInputLabel(label: 'Frequency'),
              const SizedBox(height: 8),
              FrequencyDropdown(
                value: _frequency,
                onChanged: (value) => setState(() => _frequency = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MedicationInputLabel(label: 'Duration'),
        const SizedBox(height: 8),
        TextField(
          controller: _durationController,
          decoration: MedicationInputDecoration.build(
            hintText: '7 days',
            prefixIcon: Icons.calendar_today,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MedicationInputLabel(label: 'Special Instructions'),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionsController,
          decoration: MedicationInputDecoration.build(
            hintText: 'e.g., Take with warm water',
            prefixIcon: Icons.notes,
            isDark: isDark,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _save,
        icon: Icon(widget.isNew ? Icons.add : Icons.save, size: 20),
        label: Text(
          widget.isNew ? 'Add Medicine' : 'Save Changes',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: MedColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Shows the medication edit sheet as a modal bottom sheet
Future<void> showMedicationEditSheet({
  required BuildContext context,
  required MedicationData medication,
  required void Function(MedicationData) onSave,
  bool isNew = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditMedicationSheet(
      medication: medication,
      onSave: onSave,
      isNew: isNew,
    ),
  );
}
